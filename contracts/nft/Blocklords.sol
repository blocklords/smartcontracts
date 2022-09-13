// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Mintable.sol";

contract Blocklords is ERC721, Mintable {
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _imx
    ) ERC721(_name, _symbol) Mintable(_owner, _imx) {}

    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
    }

    function mint(address user, uint id) external onlyMinter {
        require(!_exists(id), "minted token");
        _safeMint(user, id);
    }

    function burn(uint id) external onlyMinter {
        require(ownerOf(id) == msg.sender, "only burn your own token");
        require(_exists(id), "minted token");

        _burn(id);
    }
}