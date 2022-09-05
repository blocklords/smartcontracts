// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 *  @title Blocklords
 *  @author Medet Ahmetson (admin@blocklords.io)
 *  @notice MEAD token
 *  @dev Not bridged as meter.io required. Bridging and minting are the same.
 */
contract Mead is ERC20, Ownable {
    bool public bridgeAllowed = false;

    /// @notice the list of bridge addresses allowed to mint tokens.
    mapping(address => bool) public bridges;
    mapping(address => uint) public mintNonceOf;
    mapping(address => uint) public burnNonceOf;

    uint256 private constant mintId = 13;
    uint256 private constant burnId = 16;

    uint256 public limitSupply = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // Mint and Burn
    modifier onlyBridge {
        require(bridges[msg.sender]);
        _;
    }

    event AddBridge(address indexed bridge);
    event RemoveBridge(address indexed bridge);

    constructor(bool _bridgeAllowed) ERC20("MEAD", "MEAD") {
        bridgeAllowed = _bridgeAllowed;
    }

    function addBridge(address _bridge) external onlyOwner {
        require(bridgeAllowed, "no bridging");
        require(_bridge != address(0), "invalid address");
        require(!bridges[_bridge], "bridge already added");

        bridges[_bridge] = true;

        emit AddBridge(_bridge);
   }

    function removeBridge(address _bridge) external onlyOwner {
        require(bridgeAllowed, "no bridging");
        require(_bridge != address(0), "invalid address");
        require(bridges[_bridge], "bridge already removed");

        delete bridges[_bridge];

        emit RemoveBridge(_bridge);
   }

   /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s) external {
        // investor, project verification
	    bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
	    bytes32 message         = keccak256(abi.encodePacked(msg.sender, address(this), block.chainid, _amount, mintId, mintNonceOf[msg.sender]));
	    bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
	    address recover         = ecrecover(hash, _v, _r, _s);

	    require(bridges[recover], "sig");

        require(totalSupply() + _amount <= limitSupply, "exceeded mint limit");
        
        mintNonceOf[msg.sender]++;

        _mint(msg.sender, _amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     *
     * Included just to follow the standard of OpenZeppelin.
     */
    function burn(uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s) public {
        // investor, project verification
	    bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
	    bytes32 message         = keccak256(abi.encodePacked(msg.sender, address(this), block.chainid, _amount, burnId, burnNonceOf[msg.sender]));
	    bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
	    address recover         = ecrecover(hash, _v, _r, _s);

	    require(bridges[recover], "sig");

        burnNonceOf[msg.sender]++;

        _burn(msg.sender, _amount);
    }
}
