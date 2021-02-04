// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

import './interfaces/IArthswapV1Pair.sol';
import './interfaces/IArthswapV1ERC20.sol';
import './interfaces/IArthswapV1Factory.sol';

import './interfaces/IUniswapV2Migrator.sol';
import './interfaces/V1/IUniswapV1Factory.sol';
import './interfaces/V1/IUniswapV1Exchange.sol';
import './interfaces/IUniswapV2Router01.sol';
import './interfaces/IERC20.sol';

contract UniswapV2Migrator is IUniswapV2Migrator {
    IArthswapV1ERC20 immutable token;
    IUniswapV2Router01 immutable router;
    IArthswapV1Factory immutable factory;

    constructor(address _factory, address _router) {
        router = IUniswapV2Router01(_router);
        factory = IArthswapV1Factory(_factory);
    }

    // Needs to accept ETH from any v1 exchange and the router.
    // Ideally this could be enforced, as in the router,
    // but it's not possible because it requires a call to the v1 factory,
    // which takes too much gas.
    receive() external payable {}

    function migratePair(
        address token0,
        address token1,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external override {
        uint256 liquidity = token.balanceOf(msg.sender);

        // NOTE: has to be approved from frontend.
        require(token.transferFrom(msg.sender, address(this), liquidity), 'Migrator: transfer from failed');

        (uint256 amountA, uint256 amountB) = router.removeLiquidity(token0, token1, liquidity, 1, 1, uint256(-1));

        TransferHelper.safeApprove(token, address(router), amountA);
        TransferHelper.safeApprove(token, address(router), amountB);

        (uint256 amountAAdded, uint256 amountBAdded, ) =
            router.addLiquidity(token0, token1, amountA, amountB, 1, 1, to, deadline);

        if (amountA > amountAAdded) {
            // Be a good blockchain citizen, reset allowance to 0.
            TransferHelper.safeApprove(token0, address(router), 0);

            TransferHelper.safeTransfer(token0, msg.sender, amountA - amountAAdded);
        }

        if (amountB > amountBAdded) {
            // Be a good blockchain citizen, reset allowance to 0.
            TransferHelper.safeApprove(token1, address(router), 0);

            TransferHelper.safeTransfer(token1, msg.sender, amountB - amountBAdded);
        }
    }
}
