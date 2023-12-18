// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LRDLock is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public verifier;
    address public lrd;

    mapping(address => uint) public player;
    mapping(address => uint256) public nonce;

    event ImportLrd(address indexed owner, uint256 indexed amount, uint256 time);
    event ExportLrd(address indexed owner, uint256 indexed amount, uint256 time);
    event ChangeVerifier(address indexed verifier, uint256 indexed time);
    event ChangeToken(address indexed token, uint256 indexed time);

    constructor(address _verifier, address _token) {
        require(_verifier != address(0), "Lrd: Address error");
        require(_token != address(0), "Lrd: Address error");
        
        verifier = _verifier;
        lrd = _token;
    }

    function importLrd(uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(_amount > 0,          "Lrd: Amount to import should be greater than 0");

        {
            bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
            bytes32 message         = keccak256(abi.encodePacked(_amount, msg.sender, address(this), block.chainid, nonce[msg.sender]));
            bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
            address recover         = ecrecover(hash, _v, _r, _s);

            require(recover == verifier, "Lrd: Verification failed about importLrd");
        }
        
        IERC20 _token = IERC20(lrd);
        require(_token.balanceOf(msg.sender) >= _amount, "Lrd: Not enough token to import");
        _token.safeTransferFrom(msg.sender, address(this), _amount);

        player[msg.sender] += _amount;
        nonce[msg.sender]++;

        emit ImportLrd(msg.sender, _amount, block.timestamp);
    }

    function exportLrd(uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(_amount > 0,          "Lrd: Amount to import should be greater than 0");
        require(player[msg.sender] >= _amount, "Lrd: Never imported that many tokens");

         {
            bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
            bytes32 message         = keccak256(abi.encodePacked(_amount, msg.sender, address(this), block.chainid, nonce[msg.sender]));
            bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
            address recover         = ecrecover(hash, _v, _r, _s);

            require(recover == verifier, "Lrd: Verification failed about exportLrd");
        }

        IERC20 _token = IERC20(lrd);
        require(_token.balanceOf(address(this)) >= _amount, "Lrd: There is not enough balance to export");
        _token.safeTransfer(msg.sender, _amount);

        player[msg.sender] -= _amount;
        nonce[msg.sender]++;

        emit ExportLrd(msg.sender, _amount, block.timestamp);

    }
    
    function changeVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "Lrd: Address error");

        verifier = _verifier;

        emit ChangeVerifier(_verifier, block.timestamp);
    }

    function changeToken(address _token) external onlyOwner {
        require(_token != address(0), "Lrd: Address error");

        lrd = _token;

        emit ChangeToken(_token, block.timestamp);
    }
}