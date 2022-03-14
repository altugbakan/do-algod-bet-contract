// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Bet {
    AggregatorV3Interface public immutable priceFeed;
    IERC20 public immutable betToken;
    uint256 public immutable betAmount;
    uint256 public immutable betEndTime;
    uint256 public betStartPrice;
    address public longBetter;
    address public shortBetter;
    bool public betStarted;

    bool private longBet;
    bool private shortBet;
    uint256 private decimals;

    event Winner(address indexed winner);

    constructor(
        address _priceFeed,
        address _betToken,
        uint256 _betAmount,
        uint256 _betEndTime
    ) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        betToken = IERC20(_betToken);
        betAmount = _betAmount;
        betEndTime = _betEndTime;
        decimals = priceFeed.decimals();
    }

    function betLong() public {
        require(!longBet, "Already bet long.");
        longBet = true;
        longBetter = msg.sender;
        betToken.transferFrom(msg.sender, address(this), betAmount);
        betStarted = shortBet;
        startBet();
    }

    function betShort() public {
        require(!shortBet, "Already bet short.");
        shortBet = true;
        shortBetter = msg.sender;
        betToken.transferFrom(msg.sender, address(this), betAmount);
        betStarted = longBet;
        startBet();
    }

    function withdrawLong() public {
        require(!betStarted, "Bet has started.");
        require(msg.sender == longBetter, "Invalid long better.");
        betToken.transfer(msg.sender, betAmount);
        longBet = false;
    }

    function withdrawShort() public {
        require(!betStarted, "Bet has started.");
        require(msg.sender == shortBetter, "Invalid short better.");
        betToken.transfer(msg.sender, betAmount);
        shortBet = false;
    }

    function setWinner() public {
        require(betStarted, "Bet has not started.");
        require(block.timestamp > betEndTime, "Bet has not finished.");
        if (getAveragePrice() < betStartPrice) {
            betToken.transfer(shortBetter, 2 * betAmount);
            emit Winner(shortBetter);
        } else {
            betToken.transfer(longBetter, 2 * betAmount);
            emit Winner(longBetter);
        }
        selfdestruct(payable(msg.sender));
    }

    function getAveragePrice() private view returns (uint256) {
        uint256 count = 1;
        uint256 totalPrice;
        uint256 timestamp;
        uint80 roundId;
        (totalPrice, roundId) = getLatestPrice();

        uint256 price;
        (price, timestamp) = getPrice(--roundId);
        while ((betEndTime - timestamp) < 24 hours) {
            totalPrice += price;
            ++count;
            (price, timestamp) = getPrice(--roundId);
        }

        return (totalPrice / count);
    }

    function startBet() private {
        (betStartPrice, ) = getLatestPrice();
    }

    // returns the price in wei (10^18)
    function getLatestPrice()
        private
        view
        returns (uint256 price, uint80 roundId)
    {
        int256 priceRaw;
        (roundId, priceRaw, , , ) = priceFeed.latestRoundData();
        return (uint256(priceRaw) * 10**(18 - decimals), roundId);
    }

    // returns the price in wei (10^18)
    function getPrice(uint80 roundId)
        private
        view
        returns (uint256 price, uint256 timestamp)
    {
        int256 priceRaw;
        (, priceRaw, , timestamp, ) = priceFeed.latestRoundData();
        return (uint256(priceRaw) * 10**(18 - decimals), timestamp);
    }
}
