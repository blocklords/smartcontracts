// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Lottery.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 *  @title Blocklords Onsales
 *  @author Medet Ahmetson (ahmetson@zoho.com)
 *  @notice This contract is for tracking
 */
contract Mead is Lottery {
    mapping (address => uint) public amounts;
    IERC721 old;

    event Buy(address indexed buyer, uint price, uint amount);
    event BurnOldNft(address indexed owner, uint indexed tokenId);

    constructor (address _old, address _verifier, address _fund) Lottery (_verifier, _fund) {
        old = IERC721(_old);
    }

    ////////////////////////////////////////////////////////////////////////////
    //
    // User functions.
    //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Buy a bronze silver pack.
    /// @param price is the price that user has to pay
    function buy(uint price, uint8 v, bytes32 r, bytes32 s) external payable {
        require(price > 0, "PRICE_0");
        require(msg.value == price, "INVALID_ATTACHED_ETH");

        amounts[msg.sender]++;

        // investor, level verification with claim verifier
	    bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
	    bytes32 message         = keccak256(abi.encodePacked(msg.sender, address(this), block.chainid, amounts[msg.sender]));
	    bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
	    address recover         = ecrecover(hash, v, r, s);
	    require(recover == verifier,                   "SIG");

        payable(fund).transfer(msg.value);

        emit Buy(msg.sender, msg.value, amounts[msg.sender]);
    }


    function burnOld(uint nftId) external {
        require (old.isApprovedForAll(msg.sender, address(this)) || old.getApproved(nftId) == address(this), "NOT_APPROVED");
        old.safeTransferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, nftId);

        emit BurnOldNft(msg.sender, nftId);
    }
}
