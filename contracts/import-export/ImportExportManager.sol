// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./AccountHodler.sol";
import "./../security/SecureContract.sol";

contract ImportExportManager is SecureContract {
    address public owner;
    address public verifier;
    address public feeReceiver;
    address public bundler;

    // todo add another map for supported projects
    // supported projects are tracked by project name (string).
    // strcuture of the map:
    // <project name> => <manager address>
    mapping(address => uint256) public nftExportNonce;
    mapping(address => uint256) public tokenExportNonce;
    mapping(address => bool) public supportedNfts;
    mapping(address => bool) public supportedTokens;

    // todo add another two events for adding or removing supported project
    event SupportNft(address indexed nft);
    event SupportToken(address indexed token);
    event TransferOwnership(address indexed owner);
    event ChangeVerifier(address indexed verifier);
    event ChangeFeeReceiver(address indexed feeReceiver);
    event ChangeBundler(address indexed bunderer);

    modifier onlyBundler {
        require(msg.sender == bundler);
        _;
    }

    constructor() SecureContract(true, true) {
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

    function changeFeeReceiver(address _feeReceiver) external {
        require(msg.sender == owner, "forbidden");
        require(_feeReceiver != address(0), "0");

        feeReceiver = _feeReceiver;

        emit ChangeFeeReceiver(_feeReceiver);
    }

    function changeBundler(address _bundler) external {
        require(msg.sender == owner, "forbidden");
        require(_bundler != address(0), "0");

        bundler = _bundler;

        emit ChangeBundler(bundler);
    }

    function supportNft(address _nft) external {
        require(_nft != address(0), "0 address");
        require(msg.sender == owner, "forbidden");
        require(!supportedNfts[_nft], "already supported");

        supportedNfts[_nft] = true;

        emit SupportNft(_nft);
    }

    function supportToken(address _token) external {
        require(_token != address(0), "0 address");
        require(msg.sender == owner, "forbidden");
        require(!supportedTokens[_token], "already supported");

        supportedTokens[_token] = true;

        emit SupportToken(_token);
    }

    // todo
    // add two functions
    // 1. supportProject(projectName string) 
    // this function can be called by anyone. the caller became the owner of the project name.
    // the function emits SupportProject() event.
    //
    // 2. unsupportedProject(projectName string)
    // this function can be called by the person who called supportProject() function.
    // the function emits UnsupportProject() event.

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 _salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, _salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }

    // todo everywhere where we have user (address)
    // we need to replace with project name + id (string)
    // in the requirements make sure that project name exists in the supported projects list.
    function salt(address user) internal view returns(bytes32) {
        return keccak256(abi.encodePacked(user, address(this), uint(uint160(user))));
    }

    // todo change user (address) with project name and id (string)
    function accountHodlerOf(address user) public view returns(address) {
        return computeAddress(salt(user), keccak256(type(AccountHodler).creationCode), address(this));
    } 

    // todo
    // change user parameter with project name, id
    function deploy(address accountHodler, address user) internal returns(bool) {
        address addr;
        bytes memory bytecode = type(AccountHodler).creationCode;
        bytes32 _salt = salt(user);
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)
        }
        require(addr == accountHodler, "Create2: Failed on deploy");

        return true;
    }

    // todo change msg.sender with project name + id
    /// @dev export function
    /// Export function creates the contract if it wasn't created.
    /// Then on the name of the user withdraws the token.
    function exportNft(address nft, uint nftId, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(nft != address(0), "unknown token");
        require(supportedNfts[nft], "unsupported token");

        /// Validation of quality
        /// message is generated as owner + amount + last time stamp + quality
        bytes memory _prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 _messageNoPrefix =
        keccak256(abi.encodePacked(msg.sender, nft, address(this), block.chainid, nftId, nftExportNonce[msg.sender]));
        bytes32 _message = keccak256(abi.encodePacked(_prefix, _messageNoPrefix));
        address _recover = ecrecover(_message, _v, _r, _s);

        require(_recover == verifier, "verification failed");

        nftExportNonce[msg.sender]++;

        address accountHodler = accountHodlerOf(msg.sender);

        if (address(accountHodler).codehash == 0) {
            require(deploy(accountHodler, msg.sender), "Failed to deploy the contract");
            AccountHodler(accountHodler).initialize(owner);
        }

        AccountHodler(accountHodler).exportNft(nft, msg.sender, nftId);
    }


    // todo change to[] with id[] and add project name
    function exportNft(address nft, uint8 length, address[] calldata to, uint[] calldata nftId) external onlyBundler {
        require(length > 0 && length <= 100, "length");
        require(nft != address(0), "unknown token");
        require(supportedNfts[nft], "unsupported token");

        for (uint8 i = 0; i < length; i++) {
            require(to[i] != address(0), "0");
            address accountHodler = accountHodlerOf(to[i]);

            if (address(accountHodler).codehash == 0) {
                require(deploy(accountHodler, to[i]), "Failed to deploy the contract");
                AccountHodler(accountHodler).initialize(owner);
            }

            AccountHodler(accountHodler).exportNft(nft, to[i], nftId[i]);
        }
    }

    

    // todo pass project name and id
    // todo replace msg.sender with project name and id
    function exportToken(address token, uint amount, uint fee, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(token != address(0), "unknown token");
        require(supportedTokens[token], "unsupported token");

        /// Validation of quality
        /// message is generated as owner + amount + last time stamp + quality
        bytes memory _prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 _messageNoPrefix =
        keccak256(abi.encodePacked(msg.sender, token, address(this), block.chainid, amount, fee, tokenExportNonce[msg.sender]));
        bytes32 _message = keccak256(abi.encodePacked(_prefix, _messageNoPrefix));
        address _recover = ecrecover(_message, _v, _r, _s);

        require(_recover == verifier, "verification failed");

        // project name and id
        tokenExportNonce[msg.sender]++;

        // project name and id
        address accountHodler = accountHodlerOf(msg.sender);

        if (address(accountHodler).codehash == 0) {
            require(deploy(accountHodler, msg.sender), "Failed to deploy the contract");
            AccountHodler(accountHodler).initialize(owner);
        }

        AccountHodler(accountHodler).exportToken(token, msg.sender, feeReceiver, amount, fee);
    }


    // change to[] with id[], plus add project name.
    function exportTokens(address token, uint8 length, address[] calldata to, uint[] calldata amount, uint[] calldata fee) external onlyBundler {
        require(length > 0 && length <= 100, "length");
        require(token != address(0), "unknown token");
        require(supportedTokens[token], "unsupported token");

        for (uint8 i = 0; i < length; i++) {
            require(to[i] != address(0), "0");
            address accountHodler = accountHodlerOf(to[i]);

            if (address(accountHodler).codehash == 0) {
                require(deploy(accountHodler, to[i]), "Failed to deploy the contract");
                AccountHodler(accountHodler).initialize(owner);
            }

            AccountHodler(accountHodler).exportToken(token, to[i], feeReceiver, amount[i], fee[i]);
        }
    }
}