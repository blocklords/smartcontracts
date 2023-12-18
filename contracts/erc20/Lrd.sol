// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 *  @title Blocklords
 *  @author Medet Ahmetson (admin@blocklords.io)
 *  @notice The LRD token
 */
contract LRD is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 private _million = 1000 * 1000 * 10 ** 18;
    uint256 private _thousand = 1000 * 10 ** 18;

    bool[11] public originalMints;

    /// @notice Set to false to stop mint/burn of token. Set to true to allow minting.
    bool public bridgeAllowed = false;

    uint public limitSupply = 0;

    /// @notice the list of bridge addresses allowed to mint tokens.
    mapping(address => bool) public bridges;

    // Mint and Burn
    modifier onlyBridge {
        require(bridgeAllowed && bridges[msg.sender], "not a bridge or original contract");
        _;
    }

    modifier original {
        require(!bridgeAllowed, "bridge is not allowed");
        _;
    }

    modifier onlyMultisig(address multisig) {
        require(multisig.codehash > 0, "not multisig");
        _;
    }

    event IncreaseLimitSupply(uint256 limitSupply);
    event AddBridge(address indexed bridge);
    event RemoveBridge(address indexed bridge);

    /// @param _bridgeAllowed is FALSE in the token at the original token.
    constructor(
        bool _bridgeAllowed) ERC20("BLOCKLORDS", "LRD") {
        bridgeAllowed = _bridgeAllowed;

        for (uint8 i = 0; i < 11; i++) {
            originalMints[i] = false;
        }
    }

    function mintSeedSale(address multisig) external onlyMultisig(multisig) original onlyOwner {
        require(!originalMints[0], "minted");
    
        originalMints[0] = true;

        _mint(multisig, 8 * _million + (750 * _thousand));  // 8.75%
    }

    function mintStrategicSale(address multisig) external onlyMultisig(multisig) original onlyOwner {
        require(!originalMints[1], "minted");
        originalMints[1] = true;
        _mint(multisig, 6 * _million + (250 * _thousand));  // 6.25%
    }

    function mintPrivateSale(address multisig) external onlyMultisig(multisig) original onlyOwner {
        require(!originalMints[2], "minted");
        originalMints[2] = true;
        _mint(multisig, 7 * _million);  // 7%
    }

    function mintLaunchpad(address multisig) external onlyMultisig(multisig) original onlyOwner {
        require(!originalMints[3], "minted");
        originalMints[3] = true;
        _mint(multisig, 2 * _million);  // 2%
    }

    function mintIeo(address multisig) external onlyMultisig(multisig) original onlyOwner {
        require(!originalMints[4], "minted");
        originalMints[4] = true;
        _mint(multisig, 1 * _million);  // 1%
    }

    function mintLrdsBounty(address multisig) external onlyMultisig(multisig) original onlyOwner {
        require(!originalMints[5], "minted");
        originalMints[5] = true;
        _mint(multisig, 25 * _million + (750 * _thousand));  // 25%
    }

    function mintKingsBounty(address multisig) external onlyMultisig(multisig) original onlyOwner {
        require(!originalMints[6], "minted");
        originalMints[6] = true;
        _mint(multisig, 10 * _million);  // 10%
    }

    function mintDynastyIncentives(address multisig) external onlyMultisig(multisig) original onlyOwner {
        require(!originalMints[7], "minted");
        originalMints[7] = true;
        _mint(multisig, 15 * _million);  // 15%
    }

    function mintLiquidity(address multisig) external onlyMultisig(multisig) original onlyOwner {
        require(!originalMints[8], "minted");
        originalMints[8] = true;
        _mint(multisig, 10 * _million);  // 10%
    }

    function mintFoundationReserve(address multisig) external onlyMultisig(multisig) original onlyOwner {
        require(!originalMints[9], "minted");
        originalMints[9] = true;
        _mint(multisig, 10 * _million);  // 10%
    }

    function mintAdvisors(address multisig) external onlyMultisig(multisig) original onlyOwner {
        require(!originalMints[10], "minted");
        originalMints[10] = true;
        _mint(multisig, 5 * _million);  // 5%
    }

    function increaseLimitSupply(uint256 amount) external onlyOwner {
        require(limitSupply + amount <= 100 * 1000 * 1000 * 10 ** 18, "Exceeds the max cap");
        
        limitSupply += amount;

        emit IncreaseLimitSupply(limitSupply);
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
        require(totalSupply().add(amount) <= limitSupply, "exceeded mint limit");
        _mint(to, amount);
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

        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}
