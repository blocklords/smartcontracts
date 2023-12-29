// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LRDLock is Ownable, ReentrancyGuard {

    using SafeMath  for uint256;
    using SafeERC20 for IERC20;

    struct PlayerParams {
        uint256 amount;
        uint256 importTime;
        uint256 importType;
    }

    struct UserData {
        uint256 amount;      // The amount deposited this time
        uint256 importTime;  // The time of thie deposit
        uint256 totalAmount; // Total deposits (as of current deposits)
        uint256 endTime;     // Maturity time
        uint256 importType;  // The type of this deposit
    }

    bool      public gameStatus;
    address   public verifier;
    address   public lrd;
    address[] public playerList;
    uint256[] public importTypes;
    uint256   public totalAmount;
    uint256   public activeUsers;

    mapping(address => PlayerParams) public player;
    mapping(address => UserData[]) public usersData;
    mapping(address => bool) public addressExists;
    mapping(address => uint256) public nonce;

    event ImportLrd(address indexed owner, uint256 indexed amount, uint256 importType, bool redeposit, uint256 time);
    event ExportLrd(address indexed owner, uint256 indexed amount, uint256 time);
    event ChangeVerifier(address indexed verifier, uint256 indexed time);
    event ChangeToken(address indexed token, uint256 indexed time);
    event PauseGame(bool indexed gameStatus, uint256 indexed time);
    event ResumeGame(bool indexed gameStatus, uint256 indexed time);
    event UpdateImportTypes(uint256 indexed index, uint256 indexed duration, uint256 indexed time);
    event AddImportTypes(uint256 indexed duration, uint256 indexed time);

    constructor(address _verifier, address _token) {
        require(_verifier != address(0), "Lrd: Address error");
        require(_token    != address(0), "Lrd: Address error");

        verifier    = _verifier;
        lrd         = _token;
        gameStatus  = true;

        // Add importType slices for the seconds of 0 days, 1 week, 1 month, 6 months, 1 year, and 4 years, respectively
        importTypes = [0, 86400 * 7, 86400 * 30, 86400 * 180, 86400 * 365, 86400 * 365 * 4];
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
            params.importTime = block.timestamp;
        }else {
            require(importTypes[_importType] >= importTypes[params.importType], "Lrd:Not less than the first import");  // If the LRD is not stored for the first time, the import time cannot be less than the previous import time
        }

        if(!addressExists[msg.sender]){
            playerList.push(msg.sender);
            addressExists[msg.sender] = true;
            activeUsers              += 1;
        }

        IERC20 _token = IERC20(lrd);
        require(_token.balanceOf(msg.sender) >= _amount, "Lrd: Not enough token to import");

        uint256 amountBefore = _token.balanceOf(address(this));
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 amountAfter = _token.balanceOf(address(this));
        require(amountAfter - amountBefore >= _amount, "Lrd: import LRD err");

        params.amount    += _amount;
        params.importType = _importType;
        totalAmount      += _amount;

        // Push in current wallet pledge information for easy back-end calculation of returns
        UserData memory userData;
        userData.amount      = _amount;
        userData.importTime  = block.timestamp;
        userData.totalAmount = params.amount;
        userData.endTime     = params.importTime + importTypes[_importType];
        userData.importType  = _importType;
        usersData[msg.sender].push(userData);

        nonce[msg.sender]++;

        emit ImportLrd(msg.sender, _amount, _importType, checkTime(params), block.timestamp);
    }

    function exportLrd(uint8 _v, bytes32 _r, bytes32 _s) external nonReentrant {
        PlayerParams storage params = player[msg.sender];

        require(checkTime(params), "Lrd: The lock time is not up");

         {
            bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
            bytes32 message         = keccak256(abi.encodePacked(params.amount, msg.sender, address(this), block.chainid, nonce[msg.sender]));
            bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
            address recover         = ecrecover(hash, _v, _r, _s);

            require(recover == verifier, "Lrd: Verification failed about exportLrd");
        }

        IERC20 _token = IERC20(lrd);
        require(_token.balanceOf(address(this)) >= params.amount, "Lrd: There is not enough balance to export");
        _token.safeTransfer(msg.sender, params.amount);

        totalAmount              -= params.amount;
        params.amount             = 0;
        params.importTime         = 0;
        params.importType         = 0;
        addressExists[msg.sender] = false;
        activeUsers              -= 1;
        nonce[msg.sender]++;
        delete usersData[msg.sender];

        removeFromPlayerList(msg.sender);

        emit ExportLrd(msg.sender, params.amount, block.timestamp);

    }

    // Verify player deposit time
    function checkTime(PlayerParams storage params) view internal returns(bool){
        if((block.timestamp - params.importTime) > importTypes[params.importType]){
            return true;
        }
        return false;
    }

    // Get all player import information
    function getAllUserInfo() external view returns (string memory) {
        uint256 userCount = playerList.length;
        string memory result;

        for (uint256 i = 0; i < userCount; i++) {
            address userAddress = playerList[i];
            UserData[] storage user = usersData[userAddress];

            result = string(abi.encodePacked(result, userAddressToString(userAddress), ":"));

            for (uint256 j = 0; j < user.length; j++) {
                result = string(abi.encodePacked(result, depositDetailToString(user[j])));

                if (j < user.length - 1) {
                    result = string(abi.encodePacked(result, ";"));
                }
            }

            if (i < userCount - 1) {
                result = string(abi.encodePacked(result, "@@"));
            }
        }

        return result;
    }

    // Converts the user address to a string
    function userAddressToString(address _address) public pure returns (string memory) {
        uint256 addressUint = uint256(uint160(_address));
        return toString(addressUint);
    }

    // Convert DepositDetail to a string
    function depositDetailToString(UserData memory _detail) internal pure returns (string memory) {
        string memory amountStr = toString(_detail.amount);
        string memory importTimeStr = toString(_detail.importTime);
        string memory importTypeStr = toString(_detail.importType);
        string memory totalAmountStr = toString(_detail.totalAmount);
        string memory endTimeStr = toString(_detail.endTime);

        return string(abi.encodePacked(amountStr, ",", importTimeStr, ",", importTypeStr, ",", totalAmountStr, ",", endTimeStr));
}

    // Convert bytes32 to a string
    function toString(uint256 _data) internal pure returns (string memory) {
        if (_data == 0) {
            return "0";
        }

        uint256 temp = _data;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (_data != 0) {
            digits        -= 1;
            buffer[digits] = bytes1(uint8(48 + _data % 10));
            _data         /= 10;
        }

        return string(buffer);
    }
    
    // Removes an address from the player list
    function removeFromPlayerList(address _player) internal {
        int256 playerIndex = -1;
        for (uint256 i = 0; i < playerList.length; i++) {
            if (playerList[i] == _player) {
                playerIndex = int256(i);
                break;
            }
        }

        if (playerIndex != -1) {
            playerList[uint256(playerIndex)] = playerList[playerList.length - 1];
            playerList.pop();
        }
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
        
        emit PauseGame(gameStatus, block.timestamp);
    }

    // Resume game and player can ont import token
    function resumeGame() external onlyOwner {
        require(!gameStatus, "Lrd: The game has begun");
        gameStatus = true;

        emit ResumeGame(gameStatus, block.timestamp);
    }

    // Change the time for the specified type of import
    function updateImportTypes(uint256 _index, uint256 _newSeconds) external onlyOwner {
        require(_index < importTypes.length, "Lrd: Index out of bounds");
        require(_newSeconds > 0, "Lrd: The import time cannot be less than 0");
        importTypes[_index] = _newSeconds;
        
        emit UpdateImportTypes(_index, _newSeconds, block.timestamp);
    }

    // Add the import time type
    function addImportTypes(uint256 _newSeconds) external onlyOwner {
        require(_newSeconds > 0, "Lrd: The import time cannot be less than 0");
        importTypes.push(_newSeconds);
        
        emit AddImportTypes(_newSeconds, block.timestamp);
    }

}