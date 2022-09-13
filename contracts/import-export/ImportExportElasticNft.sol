// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./../nft/Blocklords.sol";
import "./AccountHodler.sol";
import "./../security/SecureContract.sol";

contract ImportExportElasticNft is SecureContract {
    address public nft;
    address public owner;
    address public verifier;
    address public feeReceiver;
    address public bundler;

    mapping(address => uint) public nftExportNonce;

    event TransferOwnership(address indexed owner);
    event ChangeVerifier(address indexed verifier);
    event ChangeFeeReceiver(address indexed feeReceiver);
    event ChangeBundler(address indexed bunderer);

    // Mint and Burn
    modifier onlyBundler {
        require(msg.sender == bundler);
        _;
    }

    constructor(address _nft) SecureContract(true, true) {
        nft = _nft;
        owner = msg.sender;
        verifier = msg.sender;
    }

    function transferOwnership(address _owner) external {
        require(msg.sender == owner, "forbidden");
        require(_owner != address(0), "0");
        owner = _owner;

        emit TransferOwnership(owner);
    }

    function changeVerifier(address _verifier) external {
        require(msg.sender == owner, "forbidden");
        require(_verifier != address(0), "0");

        verifier = _verifier;

        emit ChangeVerifier(verifier);
    }

    function changeBundler(address _bundler) external {
        require(msg.sender == owner, "forbidden");
        require(_bundler != address(0), "0");

        bundler = _bundler;

        emit ChangeBundler(bundler);
    }

    function changeFeeReceiver(address _feeReceiver) external {
        require(msg.sender == owner, "forbidden");
        feeReceiver = _feeReceiver;

        emit ChangeFeeReceiver(_feeReceiver);
    }

    function importNft(uint nftId) external {
        Blocklords(nft).safeTransferFrom(msg.sender, address(this), nftId);
        Blocklords(nft).burn(nftId);
    }

    /// @dev export function
    /// Export function creates the contract if it wasn't created.
    /// Then on the name of the user withdraws the token.
    function exportNft(uint nftId, uint8 _v, bytes32 _r, bytes32 _s) external {

        /// Validation of quality
        /// message is generated as owner + amount + last time stamp + quality
        bytes memory _prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 _messageNoPrefix =
        keccak256(abi.encodePacked(msg.sender, address(this), block.chainid, nftId, nftExportNonce[msg.sender]));
        bytes32 _message = keccak256(abi.encodePacked(_prefix, _messageNoPrefix));
        address _recover = ecrecover(_message, _v, _r, _s);

        require(_recover == verifier, "verification failed");

        nftExportNonce[msg.sender]++;

        Blocklords(nft).mint(msg.sender, nftId);
    }


    function exportNfts(uint8 length, uint[] calldata nftId, address[] calldata to) external onlyBundler {
        require(length > 0 && length <= 100, "exceeds the limit");
    
        for (uint8 i = 0; i < length; i++) {
            Blocklords(nft).mint(to[i], nftId[i]);
        }
    }
}