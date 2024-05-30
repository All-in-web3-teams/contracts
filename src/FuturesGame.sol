// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {Meme} from "./Meme.sol";
import "./SafeMath.sol";

error FuturesGame__TransferFromFailed();
error FuturesGame__UpKeepNotneed(uint timePast, uint256 balance);

/**
 * @title 期货游戏合约
 * @author XL
 * @notice
 *   期货合约。用于发币方向参与者发放MEME币，相当于以游戏形式完成MEME币的空投
 *  流程：
 *      1、发币方希望空投时，调用该合约，在合约中放入希望空投的一定数额的MEME币(这里没有设最低数额限制)。
 *              以发币方调用该合约的时间为游戏初始时间（startTime）、指定时间间隔
 *              合约调用chainlink DataFeed获取该时间ETH（也可以换成别的USDT或者LINK）市价
 *      2、玩家参与时质押0.001ETH（这里使用测试币）竞猜ETH在未来一段时间内ETH为跌还是涨。
 *      3、游戏结束时合约再次调用chainlink DataFeed获取ETH市价，与开始时间的市价比较判断玩家输赢。
 *      4、向赢家均分ETH。
 *      5、赢家均分70%的MEME币，输家均分30%的MEME币。
 *
 */

contract FuturesGame is AutomationCompatibleInterface {
    using SafeMath for uint256;

    Meme private i_meme;
    address private immutable i_owner;
    uint256 private immutable i_memeBounty; //准备空投的meme数量
    uint256 private immutable i_interval; // 时间间隔
    uint256 private s_startTimeStamp; //开始时间

    AggregatorV3Interface private s_PriceFeed; //喂价返回结果
    uint256 private start_price; // 初始价格
    uint256 private end_price; //最终价格
    uint256 private EthBanlance; //合约收到的玩家质押的ETH总额

    enum Futures {
        UP,
        DOWN
    }
    Futures private endResults;
    address payable[] private s_players;
    uint256 public constant STAKE_AMOUNT = 0.001 ether; // 玩家参与时质押的金额
    // 收集玩家的押注
    address payable[] private playerBetsUP;
    address payable[] private playerBetsDown;
    uint256 private i_winnerCounts;
    uint256 private i_loserCounts;

    // priceFeedAddress chainlink喂价地址
    constructor(
        address priceFeedAddress,
        uint256 _interval,
        address _Meme,
        uint256 _MemeBounty
    ) payable {
        i_owner = msg.sender; // i_owner为合约的创建者（发币方）
        i_meme = Meme(_Meme);
        i_memeBounty = _MemeBounty;
        i_interval = _interval;
        s_PriceFeed = AggregatorV3Interface(priceFeedAddress);
        start_price = getPrice(s_PriceFeed);
        s_startTimeStamp = block.timestamp;
        require(
            i_meme.transferFrom(msg.sender, address(this), i_memeBounty),
            "Transfer failed"
        );
    }

    /**
     * AutomationCompatibleInterface
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded = ((block.timestamp - s_startTimeStamp) > i_interval &&
            playerBetsUP.length > 0 &&
            playerBetsDown.length > 0 &&
            address(this).balance > 0);
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert FuturesGame__UpKeepNotneed(
                block.timestamp - s_startTimeStamp,
                address(this).balance
            );
        }

        // get endPrice
        end_price = getPrice(s_PriceFeed);
        // 根据结果判断输赢
        if (end_price > start_price) {
            endResults = Futures.UP;
            i_winnerCounts = playerBetsUP.length;
            i_loserCounts = playerBetsDown.length;
        } else {
            endResults = Futures.DOWN;
            i_winnerCounts = playerBetsDown.length;
            i_loserCounts = playerBetsUP.length;
        }
        // 为赢家分配ETH
        DistributeEthForWinner(endResults);
        // 分配MEME
        DistributeMEME(endResults);
    }

    // 为赢家分配ETH
    function DistributeEthForWinner(Futures _endResults) public {
        address payable[] memory winner;
        if (_endResults == Futures.UP) {
            winner = playerBetsUP;
        } else {
            winner = playerBetsDown;
        }
        EthBanlance = getBalance();
        uint256 amountPerMember = EthBanlance / i_winnerCounts;
        uint256 remainder = EthBanlance % i_winnerCounts;
        for (uint256 i = 0; i < i_winnerCounts; i++) {
            payable(winner[i]).transfer(amountPerMember);
        }
        // 没有除尽的ETH给第一个赢家
        if (remainder > 0) {
            payable(winner[0]).transfer(remainder);
        }
    }

    // 分发MEME
    function DistributeMEME(Futures _endResults) public {
        address payable[] memory winner;
        address payable[] memory loser;
        if (_endResults == Futures.UP) {
            winner = playerBetsUP;
            loser = playerBetsDown;
        } else {
            winner = playerBetsDown;
            loser = playerBetsUP;
        }
        // 计算 给赢家 的 70%
        uint256 winnerMEME = i_memeBounty.mul(70).div(100);
        uint256 winnerPerMember = winnerMEME / i_winnerCounts;
        uint256 winnerRemainder = winnerMEME % i_winnerCounts;
        for (uint256 i = 0; i < i_winnerCounts; i++) {
            i_meme.transferFrom(address(this), winner[i], winnerPerMember);
        }
        // 没有除尽的给第一个赢家
        if (winnerRemainder > 0) {
            i_meme.transferFrom(address(this), winner[0], winnerRemainder);
        }

        // 计算 给输家 的 30%
        uint256 loserMEME = i_memeBounty - winnerMEME;
        uint256 loserPerMember = loserMEME / i_loserCounts;
        uint256 loserRemainder = loserMEME % i_loserCounts;
        for (uint256 i = 0; i < i_loserCounts; i++) {
            i_meme.transferFrom(address(this), loser[i], loserPerMember);
        }
        // 没有除尽的给第一个
        if (loserRemainder > 0) {
            i_meme.transferFrom(address(this), loser[0], loserRemainder);
        }
    }

    // 玩家加入游戏，下注（涨或跌），并付0.001个以太币
    function enterFuturesGame(Futures bet) external payable {
        require(
            msg.value == STAKE_AMOUNT,
            "You must send exactly specified amount ETH"
        );
        if (bet == Futures.UP) {
            playerBetsUP.push(payable(msg.sender));
        } else {
            playerBetsDown.push(payable(msg.sender));
        }
        // s_players.push(payable(msg.sender));
    }

    /**
     * get 函数
     */
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getMemeBounty() public view returns (uint256) {
        return i_memeBounty;
    }

    function getResults() public view returns (Futures) {
        return endResults;
    }

    // function getPlayers() external view returns (address payable[] memory) {
    //     return s_players;
    // }

    function getWinnerPlayers()
        external
        view
        returns (address payable[] memory)
    {
        if (endResults == Futures.UP) return playerBetsUP;
        else return playerBetsDown;
    }

    function getLoserPlayers()
        external
        view
        returns (address payable[] memory)
    {
        if (endResults == Futures.DOWN) return playerBetsUP;
        else return playerBetsDown;
    }

    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
        // or (Both will do the same thing)
        // return uint256(answer * 1e10); // 1* 10 ** 10 == 10000000000
    }

    // 返回当前合约持有的ETH数量
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
