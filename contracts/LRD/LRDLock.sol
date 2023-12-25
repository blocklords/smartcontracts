// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LRDLock is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct PlayerParams {
        uint256 amount;
        uint256 importTime;
        uint256 importType;
    }
    address public verifier;
    address public lrd;
    address[] public playerList;
    bool public gameStatus;
    uint256[] public importTypes;

    mapping(address => PlayerParams) public player;
    mapping(address => uint256) public nonce;

    event ImportLrd(address indexed owner, uint256 indexed amount, uint256 importType, bool redeposit, uint256 time);
    event ExportLrd(address indexed owner, uint256 indexed amount, uint256 time);
    event ChangeVerifier(address indexed verifier, uint256 indexed time);
    event ChangeToken(address indexed token, uint256 indexed time);

    constructor(address _verifier, address _token) {
        require(_verifier != address(0), "Lrd: Address error");
        require(_token != address(0), "Lrd: Address error");

        // Add importType slices for the seconds of 0 days, 1 week, 1 month, 6 months, 1 year, and 4 years, respectively
        importTypes = [0, 86400 * 7, 86400 * 30, 86400 * 180, 86400 * 365, 86400 * 365 * 4];

        verifier = _verifier;
        lrd = _token;
        gameStatus = true;
    }

    function importLrd(uint256 _amount, uint256 _importType, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(gameStatus, "Lrd: The game is paused, cannot import");
        require(_importType > 0 && (_importType < importTypes.length),      "Lrd: The lock time type is wrong");
        require(_amount > 0,          "Lrd: Amount to import should be greater than 0");
        PlayerParams storage params = player[msg.sender];

        {
            bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
            bytes32 message         = keccak256(abi.encodePacked(_amount, _importType, msg.sender, address(this), block.chainid, nonce[msg.sender]));
            bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
            address recover         = ecrecover(hash, _v, _r, _s);

            require(recover == verifier, "Lrd: Verification failed about importLrd");
        }

        // First save LRD, add importTime to playerParams, add player wallet to playerList slice
        if (checkTime(params)) {
            playerList.push(msg.sender);
            params.importTime = block.timestamp;
        }else {
            require(importTypes[_importType] >= importTypes[params.importType], "Lrd:Not less than the first import");  // If the LRD is not stored for the first time, the import time cannot be less than the previous import time
        }

        IERC20 _token = IERC20(lrd);
        require(_token.balanceOf(msg.sender) >= _amount, "Lrd: Not enough token to import");
        _token.safeTransferFrom(msg.sender, address(this), _amount);

        params.amount += _amount;
        params.importType = _importType;
        nonce[msg.sender]++;

        emit ImportLrd(msg.sender, _amount, _importType, checkTime(params), block.timestamp);
    }

    function exportLrd(uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(_amount > 0,          "Lrd: Amount to import should be greater than 0");

        PlayerParams storage params = player[msg.sender];
        require(params.amount >= _amount, "Lrd: Never imported that many tokens");
        require(checkTime(params), "Lrd: The lock time is not up");

         {
            bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
            bytes32 message         = keccak256(abi.encodePacked(_amount, msg.sender, address(this), block.chainid, nonce[msg.sender]));
            bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
            address recover         = ecrecover(hash, _v, _r, _s);

            require(recover == verifier, "Lrd: Verification failed about exportLrd");
        }

        IERC20 _token = IERC20(lrd);
        require(_token.balanceOf(address(this)) >= _amount, "Lrd: There is not enough balance to export");
        _token.safeTransfer(msg.sender, params.amount);

        params.amount = 0;
        params.importTime = 0;
        params.importType = 0;
        nonce[msg.sender]++;

        emit ExportLrd(msg.sender, _amount, block.timestamp);

    }

    // Verify player deposit time
    function checkTime(PlayerParams storage params) view private returns(bool){
        if((block.timestamp - params.importTime) > importTypes[params.importType]){
            return true;
        }
        return false;
    }
    
    // Get a list of player addresses
    function getPlayerList() public view returns (address[] memory) {
        return playerList;
    }

    // Get player count
    function getPlayerCount() public view returns (uint256) {
        return playerList.length;
    }
    
    // Change the checkout wallet
    function changeVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "Lrd: Address error");

        verifier = _verifier;

        emit ChangeVerifier(_verifier, block.timestamp);
    }

    // Change import token address
    function changeToken(address _token) external onlyOwner {
        require(_token != address(0), "Lrd: Address error");

        lrd = _token;

        emit ChangeToken(_token, block.timestamp);
    }

    // Pause game and player can ont import token
    function pauseGame() external onlyOwner {
        require(gameStatus, "Lrd: The game has been paused, don't pause it again");
        gameStatus = false;
    }

    // Resume game and player can ont import token
    function resumeGame() external onlyOwner {
        require(!gameStatus, "Lrd: The game has begun");
        gameStatus = true;
    }

    // Change the time for the specified type of import
    function updateImportTypes(uint256 _index, uint256 _newSeconds) external onlyOwner {
        require(_index < importTypes.length, "Lrd: Index out of bounds");
        importTypes[_index] = _newSeconds;
    }

    // Add the import time type
    function addImportTypes(uint256 _newSeconds) external onlyOwner {
        importTypes.push(_newSeconds);
    }

}