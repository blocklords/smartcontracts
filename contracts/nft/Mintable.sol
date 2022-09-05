// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMintable.sol";
import "./utils/Minting.sol";

abstract contract Mintable is Ownable, IMintable {
    address public imx;

    mapping(address => bool) public minters;
    mapping(address => bool) public burners;
    mapping(uint256 => bytes) public blueprints;

    event SetMinter(address indexed minter);
    event UnsetMinter(address indexed minter);
    event AssetMinted(address to, uint256 id, bytes blueprint);

    constructor(address _owner, address _imx) {
        imx = _imx;
        minters[_owner] = true;
        burners[msg.sender] = true;
        require(_owner != address(0), "Owner must not be empty");
        transferOwnership(_owner);
    }


    modifier onlyMinter() {
        require(minters[msg.sender], "Function can only be called by approved accounts");
        _;
    }

    modifier onlyImxOrMinter() {
        require(minters[msg.sender] || msg.sender == imx, "Function can only be called by approved accounts or imx");
        _;
    }


    function setMinter(address _minter) onlyOwner {
        require(!minters[_minter], "already set");

        minters[_minter] = true;

        emit SetMinter(_minter);
    }

    function unsetMinter(address _minter) onlyOwner {
        require(minters[_minter], "not set");

        delete minters[_minter];

        emit UnsetMinter(_minter);
    }

    function mintFor(
        address user,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external override onlyImxOrMinter {
        require(quantity == 1, "Mintable: invalid quantity");
        (uint256 id, bytes memory blueprint) = Minting.split(mintingBlob);
        _mintFor(user, id, blueprint);
        blueprints[id] = blueprint;
        emit AssetMinted(user, id, blueprint);
    }

    function mint(address user, uint id) external onlyMiner {
        require(!exists(id), "minted token");
        _safeMint(user, id);
    }

    function burn(id) external onlyMinter {
        require(ownerOf(id) == msg.sender, "only burn your own token");
        require(exists(id), "minted token");

        _burn(id);
    }

    function _mintFor(
        address to,
        uint256 id,
        bytes memory blueprint
    ) internal virtual;
}