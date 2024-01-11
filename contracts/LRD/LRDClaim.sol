// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LRDClaim is Ownable, ReentrancyGuard {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct VerifierParams {
        address verifier;              //verifier address
        bool    statu;                 //verification state. when true, it can be exchanged for lord coins
        uint256 cdTime;                //CD time
        uint256 maxWithdrawNum;        //the maximum number of conversions in the CD time
        uint256 totalWithdrawAmount;   //maximum total exchange amount
    }

    struct VerifierDatas {
        uint256 upDateTime;         //the last withdraw time allowed
        uint256 withdrawAmount;     //this verifier addresses the total amount of withdraw
        uint256 withdrawNum;        //CD time, the number of withdraw  
    }

    struct CDParams {
        uint256 cdTime;                  //CD time
        uint256 maxCdWithdrawAmount;     //the maximum amount of conversions in the CD time
        uint256 maxTotalWithdrawAmount;  //maximum total exchange amount
    }

    struct PlayerDatas {
        uint256 upDateTime;              //the last withdraw time
        uint256 cdWithdrawAmount;        //this wallet allows the total amount of money to be withdrawn at CD time
        uint256 totalWithdrawAmount;     //the total amount allowed to withdraw from this wallet
    }

    address public lrd;
    uint256 private verifierKey;

    address public bank;    //transfer token

    mapping(address => uint256) public nonce;
    mapping(uint256 => VerifierParams) public verifierParams;
    mapping(address => VerifierDatas) public verifierData;
    mapping(address => PlayerDatas) public player;

    CDParams public cDParams;

    event ChangeVerifier(uint256 verifierKey, address indexed verifier, uint256 cdTime, uint256 maxWithdrawNum, uint256 totalWithdrawAmount,uint256 indexed time);
    event AddVerifier(uint256 verifierKey, address indexed verifier, uint256 cdTime, uint256 maxWithdrawNum, uint256 totalWithdrawAmount,uint256 indexed time);
    event ChangeBank(address indexed bank, uint256 indexed time);
    event ExchangeLrd(address indexed owner, uint256 indexed amount, uint256 time);
    event ChangeCDParams(uint256 indexed CDTime, uint256 indexed MaxCdWithdrawAmount, uint256 indexed MaxTotalWithdrawAmount, uint256 time);

    constructor(address _verifier, address _token, address _bank) {
        require(_verifier != address(0), "Lrd: Address error");
        require(_token != address(0), "Lrd: Address error");
        require(_bank != address(0), "Lrd: Address error");

        verifierKey++;

        VerifierParams storage params = verifierParams[verifierKey];

        params.verifier            = _verifier; 
        params.statu               = true;
        params.cdTime              = 3600 * 24;
        params.totalWithdrawAmount = 10000 * 10 ** 18;
        params.maxWithdrawNum      = 1000;

        
        cDParams.cdTime                 = 3600 * 24;
        cDParams.maxCdWithdrawAmount    = 10 * 10 ** 18;
        cDParams.maxTotalWithdrawAmount = 1000 * 10 ** 18;

        bank = _bank;
        lrd  = _token;
    }

    // Can be exchanged for LRD
    function exchangeLrd(uint256 _verifierKey, uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s) external nonReentrant {
        require(_amount > 0,          "Lrd: Amount to exchange should be greater than 0");

        VerifierParams storage params = verifierParams[_verifierKey];
        require(params.statu, "Lrd: This verifier address is not available");
        require(checkVerifierCDTime(_verifierKey, _amount), "Lrd: The amount or number of withdrawals is max");
        require(checkPlayerCanExchange(_amount), "Lrd: The maximum quantity has been exchange");

         {
            bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
            bytes32 message         = keccak256(abi.encodePacked(_verifierKey, _amount, msg.sender, address(this), block.chainid, nonce[msg.sender]));
            bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
            address recover         = ecrecover(hash, _v, _r, _s);

            require(recover == params.verifier, "Lrd: Verification failed about exchangeLrd");
        }


        IERC20 _token = IERC20(lrd);
        require(_token.balanceOf(bank) >= _amount, "Lrd: There is not enough balance to export");
        _token.safeTransferFrom(bank, msg.sender, _amount);

        VerifierDatas storage data = verifierData[params.verifier];

        data.withdrawAmount += _amount;
        data.withdrawNum ++;
        nonce[msg.sender]++;
        
        PlayerDatas storage playerData = player[msg.sender];

        if(block.timestamp - playerData.upDateTime > cDParams.cdTime) {
            playerData.upDateTime       = block.timestamp;
            playerData.cdWithdrawAmount = _amount;
        } else {
            playerData.cdWithdrawAmount += _amount;
        }

        playerData.totalWithdrawAmount += _amount;

        emit ExchangeLrd(msg.sender, _amount, block.timestamp);
    }

    function checkVerifierCDTime(uint256 _verifierKey, uint256 _amount) private returns(bool) {
        VerifierParams storage params = verifierParams[_verifierKey];
        VerifierDatas storage data = verifierData[params.verifier];

        if((data.withdrawAmount + _amount) > params.totalWithdrawAmount) {
            return false;
        }

        //After CD time, data reset
        if((block.timestamp - data.upDateTime) >= params.cdTime) {
            data.upDateTime  = block.timestamp;
            data.withdrawNum = 0;
            return true;
        }
        
        if(data.withdrawNum < params.maxWithdrawNum) {
            return true;
        }

        return false;
    }

    // Check if players can exchange LRD
    function checkPlayerCanExchange(uint256 _amount) private view returns(bool){
        PlayerDatas storage playerData = player[msg.sender];
        
        if(playerData.totalWithdrawAmount + _amount > cDParams.maxTotalWithdrawAmount || _amount > cDParams.maxCdWithdrawAmount) {
            return false;
        }

        if(block.timestamp - playerData.upDateTime < cDParams.cdTime) {
            return(playerData.cdWithdrawAmount + _amount <= cDParams.maxCdWithdrawAmount);
        }

        return true;
    }
    
    function changeVerifier(uint256 _verifierKey, address _verifier, bool _statu, uint256 _cdTime, uint256 _maxWithdrawNum, uint256 _totalWithdrawAmount) external onlyOwner {
        require(_verifier != address(0), "Lrd: Address error");
        require(_totalWithdrawAmount > 0,  "Lrd: Amount to import should be greater than 0");
        VerifierParams storage params = verifierParams[_verifierKey];
        require(params.verifier != address(0), "Lrd: This verifier key does not exist");

        params.verifier = _verifier; 
        params.statu = _statu;
        params.cdTime = _cdTime;
        params.maxWithdrawNum = _maxWithdrawNum;
        params.totalWithdrawAmount = _totalWithdrawAmount;

        emit ChangeVerifier(_verifierKey, _verifier, _cdTime, _maxWithdrawNum, _totalWithdrawAmount, block.timestamp);
    }
    
    function changeCDParams (uint256 _cdTime, uint256 _maxCdWithdrawAmount, uint256 _maxTotalWithdrawAmount) external onlyOwner {
        require(_cdTime > 0 , "Lrd: CD time should be greater than 0");
        require(_maxCdWithdrawAmount > 0 , "Lrd: CD time, withdraw amount must be greater than 0");
        require(_maxTotalWithdrawAmount > 0,  "Lrd: Amount to withdraw should be greater than 0");

        cDParams.cdTime = _cdTime;
        cDParams.maxCdWithdrawAmount = _maxCdWithdrawAmount;
        cDParams.maxTotalWithdrawAmount = _maxTotalWithdrawAmount;

        emit ChangeCDParams(_cdTime, _maxCdWithdrawAmount, _maxTotalWithdrawAmount, block.timestamp);
    }
    
    // Add a wallet with a verified signature
    function addVerifier(address _verifier, uint256 _cdTime, uint256 _maxWithdrawNum, uint256 _totalWithdrawAmount) external onlyOwner {
        require(_verifier != address(0), "Lrd: Address error");
        require(_totalWithdrawAmount > 0,  "Lrd: Amount to import should be greater than 0");

        verifierKey++;
        VerifierParams storage params = verifierParams[verifierKey];

        params.verifier = _verifier; 
        params.statu = true;
        params.cdTime = _cdTime;
        params.totalWithdrawAmount = _totalWithdrawAmount;
        params.maxWithdrawNum = _maxWithdrawNum;

        emit AddVerifier(verifierKey, _verifier, _cdTime, _maxWithdrawNum, _totalWithdrawAmount, block.timestamp);
    }

    // Change the bank wallet that issues LRD
    function changeBank(address _bank) external onlyOwner {
        require(_bank != address(0), "Lrd: Address error");

        bank = _bank;

        emit ChangeBank(_bank, block.timestamp);
    }
}