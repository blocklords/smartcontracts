// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 *  @title Blocklords Onsales Lottery for getting gold pack
 *  @author Medet Ahmetson (ahmetson@zoho.com)
 *  @notice This contract is for tracking
 */
contract NftImportExport is Ownable {
    address public verifier;
    /// @notice Collector of ETH that user added.
    address public fund;

    // For testing we have multiple accounts.
    uint public lastSalesId;

    struct Sale {
        uint startTime;
        uint min;
        uint8 rounds;
        uint16 lotteryBanners;
        uint16 claimedBanners;
        uint24 duration;
        uint24 highestDuration;
    }

    mapping (uint => Sale) public sales;
    mapping (uint => mapping(uint8 => mapping(address => uint))) public bids;

    event SetVerifier(address indexed verifier);
    event SetFund(address indexed fund);
    event Start(uint indexed id);
    event Bid(uint indexed id, uint8 indexed round, address indexed bidder, uint totalBidAmount);
    event HighestClaim(uint indexed id, uint8 indexed round, address indexed bidder);
    event Withdraw(uint indexed id, uint8 indexed round, address indexed bidder);
    event Win(uint indexed id, uint8 indexed round, address indexed bidder);
    event SilverForMonster(uint indexed id, uint8 indexed round, address indexed bidder);
    event Lose(uint indexed id, uint8 indexed round, address indexed bidder);

    constructor(address _verifier, address _fund) {
        require(_verifier != address(0) && _fund != address(0), "0");
        verifier = _verifier;
        fund = _fund;

        emit SetVerifier(verifier);
        emit SetFund(fund);
    }

    modifier validSalesParams(
        uint startTime, 
        uint24 duration, 
        uint24 highestDuration,
        uint8 rounds,
        uint16 lotteryBanners) {
        require(startTime > block.timestamp, "START_TIME_NOT_FUTURE");
        require(duration > 0, "duration");
        require(highestDuration > 0, "highestDuration");
        require(duration > highestDuration, "highestDuration");
        require(rounds > 0, "rounds");
        require(lotteryBanners > 0, "lotteryBanners");
        _;
    }

    modifier validRound(uint saleId, uint8 round) {
        Sale storage sale = sales[saleId];
        require(round > 0 && round <= sale.rounds, "round");
        require(block.timestamp >= (round - 1) * sale.duration + sale.startTime, "roundStart");
        require(block.timestamp < (round) * sale.duration + sale.startTime, "roundEnd");
        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    //
    // Management functions.
    //
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Enables the nft sales.
     * @param startTime of the first round
     * @param duration of each round
     * @param highestDuration when we track the largest bidders
     * @param rounds amount that this nft sales will have
     * @param lotteryBanners amount that are distributed by gold banners
     * @param min amount of ETH that we could ask. If it's 0, then no limit.
     */
    function start(
        uint startTime, 
        uint24 duration, 
        uint24 highestDuration, 
        uint8 rounds,
        uint16 lotteryBanners,
        uint min) 
    external onlyOwner validSalesParams(startTime, duration, highestDuration, rounds, lotteryBanners) {
        lastSalesId++;

        sales[lastSalesId] = Sale(startTime, min, rounds, lotteryBanners, 0, duration, highestDuration);

        emit Start(lastSalesId);
    }

    function setVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "0");
        require(_verifier != verifier, "SAME");

        verifier = _verifier;

        emit SetVerifier(verifier);
    }

    function setFund(address _fund) external onlyOwner {
        require(_fund != address(0), "0");
        require(_fund != fund, "SAME");

        fund = _fund;

        emit SetFund(_fund);
    }

    ////////////////////////////////////////////////////////////////////////////
    //
    // User functions.
    //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Bid on sale. It can bid multiple times.
    function bid(uint saleId, uint8 round, uint8 v, bytes32 r, bytes32 s) external validRound(saleId, round) payable {
        Sale storage sale = sales[saleId];

        require(msg.value >= sale.min, "min");

        bids[saleId][round][msg.sender] += msg.value;
        uint totalBid = bids[saleId][round][msg.sender];

	    bytes32 message         = keccak256(abi.encodePacked(saleId, totalBid, block.chainid, msg.sender, round));
	    bytes32 hash            = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
	    address recover         = ecrecover(hash, v, r, s);
	    require(recover == verifier,                   "SIG");

        emit Bid(saleId, round, msg.sender, totalBid);
    }


    function highestClaim(uint saleId, uint8 round, uint8 v, bytes32 r, bytes32 s) external {
        Sale storage sale = sales[saleId];
        require(sale.startTime < block.timestamp, "NO_SALE");
        require(round > 0 && round <= sale.rounds, "round");
        require(block.timestamp > (round) * sale.highestDuration + sale.startTime, "highestDuration");
        require(bids[saleId][round][msg.sender] > 0, "NO_PARTICIPATION");
        require(proofOfServer(saleId, round, 4, v, r, s), "SIG");

        uint amount = bids[saleId][round][msg.sender];

        delete bids[saleId][round][msg.sender];

        payable(fund).transfer(amount);

        emit HighestClaim(saleId, round, msg.sender);
    }


    function win(uint saleId, uint8 round, uint8 v, bytes32 r, bytes32 s) external {
        Sale storage sale = sales[saleId];
        require(sale.startTime < block.timestamp, "NO_SALE");
        require(bidFinished(sale, round), "NOT_FINISHED");
        require(bids[saleId][round][msg.sender] > 0, "NO_PARTICIPATION");
        require(proofOfServer(saleId, round, 1, v, r, s), "SIG");

        uint amount = bids[saleId][round][msg.sender];

        delete bids[saleId][round][msg.sender];

        payable(fund).transfer(amount);

        emit Win(saleId, round, msg.sender);
    }

    function withdraw(uint saleId, uint8 round, uint8 v, bytes32 r, bytes32 s) external {
        Sale storage sale = sales[saleId];
        require(sale.startTime < block.timestamp, "NO_SALE");
        require(round > 0 && round <= sale.rounds, "round");
        require(block.timestamp > (round) * sale.highestDuration + sale.startTime, "highestDuration");
        require(!bidFinished(sale, round), "NOT_FINISHED");
        require(bids[saleId][round][msg.sender] > 0, "NO_PARTICIPATION");
        require(proofOfServer(saleId, round, 5, v, r, s), "SIG");

        uint amount = bids[saleId][round][msg.sender];

        delete bids[saleId][round][msg.sender];

        payable(msg.sender).transfer(amount);

        emit Withdraw(saleId, round, msg.sender);
    }

    /// @notice Users lost the lottery. But decided to get silver banner pack
    function silverForMonsters(uint saleId, uint8 round, uint8 v, bytes32 r, bytes32 s) external {
        Sale storage sale = sales[saleId];

        require(sale.startTime < block.timestamp,       "NO_SALE");
        require(bidFinished(sale, round), "NOT_FINISHED");
        require(bids[saleId][round][msg.sender] > 0, "NO_PARTICIPATION");
        require(proofOfServer(saleId, round, 2, v, r, s), "SIG");

        uint amount = bids[saleId][round][msg.sender];

        delete bids[saleId][round][msg.sender];

        payable(fund).transfer(amount);

        emit SilverForMonster(saleId, round, msg.sender);
    }

    ////////////////////////////////////////////////////////////////////////////
    //
    // Internal functions
    //
    ////////////////////////////////////////////////////////////////////////////

    function bidFinished(Sale storage sale, uint8 round) internal view returns(bool) {
        if (round == 0 || round > sale.rounds) {
            return false;
        }
        return block.timestamp > (round) * sale.duration + sale.startTime;
    }

    /// @param proofType is a postfix to differentiate the lottery result:
    /// 1 - win
    /// 2 - silver for monsters
    /// 3 - lose
    function proofOfServer(uint saleId, uint round, uint proofType, uint8 v, bytes32 r, bytes32 s) internal view returns(bool) {
         bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
	    bytes32 message         = keccak256(abi.encodePacked(msg.sender, saleId, block.chainid, round, proofType));               // 1 - postfix of losing
	    bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
        return ecrecover(hash, v, r, s) == verifier;
    }
}