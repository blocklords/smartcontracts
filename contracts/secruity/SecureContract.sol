// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract SecureContract {
    using SafeERC20 for IERC20;

    address public securityCaller;
    bool tokenAllowed;
    bool nftAllowed;

    constructor(bool _tokenAllowed, bool _nftAllowed) {
        securityCaller = msg.sender;
        tokenAllowed = _tokenAllowed;
        nftAllowed = _nftAllowed;
    }

    function _withdrawToken(address _token, address _to, uint _amount) internal {
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function _withdrawNft(address _token, address _to, uint _amount) internal {
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function withdrawToken(address _token, address _to, uint _amount) virtual external {
        require(tokenAllowed, "no token transfer allowed");
        require(msg.sender == securityCaller, "forbidden");
        _withdrawToken(_token, _to, _amount);
    }

    function withdrawNft(address _token, address _to, uint _nftId) virtual external {
        require(nftAllowed, "no nft transfer allowed");
        require(msg.sender == securityCaller, "forbidden");
        _withdrawNft(_token, _to, _nftId);
    }
}