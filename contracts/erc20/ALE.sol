// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 *  @title Blocklords
 *  @author Medet Ahmetson (admin@blocklords.io)
 *  @notice ALE token
 *  @dev Not bridged as meter.io required. Bridging and minting are the same.
 */
contract ALE is ERC20, Ownable {
    using SafeMath for uint256;

    bool public bridgeAllowed = false;

    /// @notice the list of bridge addresses allowed to mint tokens.
    mapping(address => bool) public bridges;
    mapping(address => uint) public mintNonceOf;
    mapping(address => uint) public burnNonceOf;

    uint256 private constant mintId = 13;
    uint256 private constant burnId = 16;

    // Mint and Burn
    modifier onlyBridge {
        require(bridges[msg.sender]);
        _;
    }

    event AddBridge(address indexed bridge);
    event RemoveBridge(address indexed bridge);

    constructor(bool _bridgeAllowed) ERC20("ALE", "ALE") {
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
    function mint(address _to, uint256 _amount) external onlyBridge {
        require(_to != address(0) && _amount > 0, "0");
	    require(bridges[msg.sender], "sig");

        require(totalSupply().add(_amount) <= 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, "exceeded mint limit");
        
        _mint(msg.sender, _amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     *
     * Included just to follow the standard of OpenZeppelin.
     */
    function burnFrom(address account, uint256 amount) external onlyBridge {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "burn amount exceeds allowance");

        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}
