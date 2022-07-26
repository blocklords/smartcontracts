// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 *  @title Blocklords
 *  @author Medet Ahmetson (admin@blocklords.io)
 *  @notice The LORD token
 */
contract Lord is ERC20, Ownable {
    /// @notice Set to false to stop mint/burn of token. Set to true to allow minting.
    bool public bridgeAllowed = false;

    /// @notice the list of bridge addresses allowed to mint tokens.
    mapping(address => bool) public bridges;

    // Mint and Burn
    modifier onlyBridge {
        require(bridgeAllowed && bridges[msg.sender]);
        _;
    }

    event AddBridge(address indexed bridge);
    event RemoveBridge(address indexed bridge);

    /// @param _bridgeAllowed is FALSE in the token at the original token.
    constructor(
        address _seedSale,
        address _strategicSale,
        address _privateSale,
        address _launchpads,
        address _ieo,
        address _lordsBounty,
        address _kingsBounty,
        address _dynastyIncentives,
        address _liquidity,
        address _foundationReserve,
        address _advisor,
        bool _bridgeAllowed) ERC20("BLOCKLORDS", "LORD") {
        bridgeAllowed = _bridgeAllowed;
        uint256 _million = 1000 * 1000 * 10 ** 18;
        uint256 thousand = 1000 * 10 ** 18;

        if (!_bridgeAllowed) {
            _mint(_seedSale, 8 * _million + (750 * thousand));  // 8.75% of 100 million
            _mint(_seedSale, 6 * _million + (250 * thousand));  // 8.75% of 100 million
            _mint(_privateSale, 7 * _million);  // 8.75% of 100 million
            _mint(_launchpads, 2 * _million);  // 8.75% of 100 million
            _mint(_ieo, 1 * _million);  // 8.75% of 100 million
            _mint(_lordsBounty, 25 * _million);  // 8.75% of 100 million
            _mint(_kingsBounty, 10 * _million);  // 8.75% of 100 million
            _mint(_dynastyIncentives, 15 * _million);  // 8.75% of 100 million
            _mint(_liquidity, 10 * _million);  // 8.75% of 100 million
            _mint(_foundationReserve, 10 * _million);  // 8.75% of 100 million
            _mint(_advisor, 5 * _million);  // 8.75% of 100 million

            require(_totalSupple == 100 * _million, "not a 100 million tokens");
        }
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
    function mint(address to, uint256 amount) external onlyBridge {
        require(_totalSupply.add(amount) <= limitSupply, "exceeded mint limit");
        _mint(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     *
     * Included just to follow the standard of OpenZeppelin.
     */
    function burn(uint256 amount) public {
        require(false, "Only burnFrom is allowed");
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public onlyBridge {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "burn amount exceeds allowance");

        _approve(account, _msgSender(), currentAllowance
            .sub(amount, "transfer amount exceeds allowance"));
        _burn(account, amount);
    }
}
