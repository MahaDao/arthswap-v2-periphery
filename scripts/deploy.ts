import { network, ethers } from 'hardhat';


async function main() {
  // Fetch the provider.
  const { provider } = ethers;

  const estimateGasPrice = await provider.getGasPrice();
  const gasPrice = estimateGasPrice.mul(3).div(2);
  console.log(`Gas Price: ${ethers.utils.formatUnits(gasPrice, 'gwei')} gwei`);

  // Fetch the wallet accounts.
  const [operator,] = await ethers.getSigners();


  // Fetch contract factories.
  const UniswapV2Router02 = await ethers.getContractFactory('UniswapV2Router02');


  // Deploy new treasury.

  const params = [
    '0x26f9Bd6af98a56D34bA49ce0B0359658Eecd77bE', // factory
    '0xc778417E063141139Fce010982780140Aa0cD5Ab' // weth
  ]

  const factory = await UniswapV2Router02.connect(operator).deploy(...params);

  console.log(` operator is ${operator.address}`)
  console.log(` router at address ${factory.address}`)
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
