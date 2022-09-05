// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../security/SecureContract.sol";

contract AccountHodler is Initializable, SecureContract {
    using SafeERC20 for IERC20;
    address public importExportManager;

    constructor() SecureContract(true, false) {
    }


    function initialize(address _securityCaller) public initializer {
        importExportManager = msg.sender;
        securityCaller = _securityCaller;
    }

    function exportNft(address nft, address owner, uint nftId) external {
        require(msg.sender == importExportManager, "not allowed");

        require(IERC721(nft).ownerOf(nftId) == address(this), "Not in the contract");
        IERC721(nft).safeTransferFrom(address(this), owner, nftId);
    }

    function exportToken(address token, address owner, address feeReceiver, uint amount, uint fee) external {
        require(msg.sender == importExportManager, "not allowed");

        IERC20(token).safeTransfer(owner, amount);
        IERC20(token).safeTransfer(feeReceiver, fee);
    }

    function unsafeExportNft(address nft, uint nftId, address owner) external {
        require(msg.sender == importExportManager, "not allowed");

        require(IERC721(nft).ownerOf(nftId) == address(this), "Not in the contract");
        IERC721(nft).transferFrom(address(this), owner, nftId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}