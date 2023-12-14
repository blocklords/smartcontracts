// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ImportExportLord is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public verifier;
    address public lord;

    mapping(address => uint) public player;
    mapping(address => uint256) public nonce;

    event ImportLord(address indexed owner, uint256 indexed amount, uint256 time);
    event ExportLord(address indexed owner, uint256 indexed amount, uint256 time);
    event ChangeVerifier(address indexed verifier, uint256 indexed time);
    event ChangeToken(address indexed token, uint256 indexed time);

    constructor(address _verifier, address _token) {
        require(_verifier != address(0), "Lord: Address error");
        require(_token != address(0), "Lord: Address error");
        
        verifier = _verifier;
        lord = _token;
    }

    function importLord(uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(_amount > 0,          "Lord: Amount to import should be greater than 0");

        {
            bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
            bytes32 message         = keccak256(abi.encodePacked(_amount, msg.sender, address(this), block.chainid, nonce[msg.sender]));
            bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
            address recover         = ecrecover(hash, _v, _r, _s);

            require(recover == verifier, "Lord: Verification failed about importLord");
        }
        
        IERC20 _token = IERC20(lord);
        require(_token.balanceOf(msg.sender) >= _amount, "Lord: Not enough token to import");
        _token.safeTransferFrom(msg.sender, address(this), _amount);

        player[msg.sender] += _amount;
        nonce[msg.sender]++;

        emit ImportLord(msg.sender, _amount, block.timestamp);
    }

    function exportLord(uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(_amount > 0,          "Lord: Amount to import should be greater than 0");
        require(player[msg.sender] >= _amount, "Lord: Never imported that many tokens");

         {
            bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
            bytes32 message         = keccak256(abi.encodePacked(_amount, msg.sender, address(this), block.chainid, nonce[msg.sender]));
            bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
            address recover         = ecrecover(hash, _v, _r, _s);

            require(recover == verifier, "Lord: Verification failed about exportLord");
        }

        IERC20 _token = IERC20(lord);
        require(_token.balanceOf(address(this)) >= _amount, "Lord: There is not enough balance to export");
        _token.safeTransfer(msg.sender, _amount);

        player[msg.sender] -= _amount;
        nonce[msg.sender]++;

        emit ExportLord(msg.sender, _amount, block.timestamp);

    }
    
    function changeVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "Lord: Address error");

        verifier = _verifier;

        emit ChangeVerifier(_verifier, block.timestamp);
    }

    function changeToken(address _token) external onlyOwner {
        require(_token != address(0), "Lord: Address error");

        lord = _token;

        emit ChangeToken(_token, block.timestamp);
    }
}