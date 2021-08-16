// Test with:
// GAS_PRICE=0 BLOCK_NUMBER=12612689 npx hardhat run mainnetDeployment/balancerPoolDeployment.js --config hardhat.config.mainnet-fork.js

const { WeightedPool2TokensFactory } = require("./ABIs/WeightedPool2TokensFactory.js")
const { WeightedPool2Tokens } = require("./ABIs/WeightedPool2Tokens.js")
const { IVault } = require("./ABIs/IVault.js")
const { ERC20 } = require("./ABIs/ERC20.js")
// here integrate the ocean protocol   script .
const { OCEAN: OCEAN_ABI } = require("./ABIs/OCEAN.js")
const { ChainlinkAggregatorV3Interface } = require("./ABIs/ChainlinkAggregatorV3Interface.js")
const toBigNum = ethers.BigNumber.from
const { TestHelper: th, TimeValues: timeVals } = require("../utils/testHelpers.js")
const { dec } = th
// Addresses are the same on all networks

const VAULT = '0xBA12222222228d8Ba445958a75a0704d566BF2C8';

const WEIGHTED_POOL_FACTORY = '0x8E9aa87E45e92bad84D5F8DD1bff34Fb92637dE9';
const ORACLE_POOL_FACTORY = '0xA5bf2ddF098bb0Ef6d120C98217dD6B141c74EE0';

const DELEGATE_OWNER = '0xBA1BA1ba1BA1bA1bA1Ba1BA1ba1BA1bA1ba1ba1B';

// Mainnet addresses; adjust for testnets

const OCEAN = '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2';
const LUSD = '0x5f98805A4E8be255a32880FDeC7F6728C6568bA0';
const CHAINLINK_ETHUSD_PROXY = '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419';

const tokens = [LUSD, OCEAN];
const weights = [toBigNum(dec(4, 17)), toBigNum(dec(6, 17))];

const NAME = 'OCEAN/LUSD Pool';
const SYMBOL = '60WETH-40LUSD';
const swapFeePercentage = toBigNum(dec(5, 15)); // 0.5%

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

const INITIAL_FUNDING = toBigNum(dec(5, 22)); // $50k

async function main() {
  // Uncomment for testing:
  /*
  const impersonateAddress = "0x787EfF01c9FdC1918d1AA6eeFf089B191e2922E4"
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [ impersonateAddress ]
  })
  const deployerWallet = await ethers.provider.getSigner(impersonateAddress)
  const deployerWalletAddress = impersonateAddress
  */

  const deployerWallet = (await ethers.getSigners())[0]
  const deployerWalletAddress = deployerWallet.address

  const factory = new ethers.Contract(
    ORACLE_POOL_FACTORY,
    WeightedPool2TokensFactory.abi,
    deployerWallet
  );
  const vault = new ethers.Contract(
    VAULT,
    IVault.abi,
    deployerWallet
  );

  const chainlinkProxy = new ethers.Contract(
    CHAINLINK_ETHUSD_PROXY,
    ChainlinkAggregatorV3Interface,
    deployerWallet
  )

  // ZERO_ADDRESS owner means fixed swap fees
  // DELEGATE_OWNER grants permission to governance for dynamic fee management
  // Any other address lets that address directly set the fees
  const oracleEnabled = true;
  const tx1 = await factory.create(
    NAME, SYMBOL, tokens, weights,
    swapFeePercentage, oracleEnabled,
    DELEGATE_OWNER
  );
  const receipt1 = await tx1.wait();

  // We need to get the new pool address out of the PoolCreated event
  // (Or just grab it from Etherscan)
  const events = receipt1.events.filter((e) => e.event === 'PoolCreated');
  const poolAddress = events[0].args.pool;

  // We're going to need the PoolId later, so ask the contract for it
  const pool = new ethers.Contract(
    poolAddress,
    WeightedPool2Tokens.abi,
    deployerWallet
  );
  const poolId = await pool.getPoolId();

  // Get latest price
  const chainlinkPrice = await chainlinkProxy.latestAnswer();
  // chainlink price has only 8 decimals
  const eth_price = chainlinkPrice.mul(toBigNum(dec(1, 10)));
  th.logBN('ETH price', eth_price)
  // Tokens must be in the same order
  // Values must be decimal-normalized!
  const weth_balance = INITIAL_FUNDING.mul(weights[1]).div(eth_price);
  const lusd_balance = INITIAL_FUNDING.mul(weights[0]).div(toBigNum(dec(1, 18)));
  const initialBalances = [lusd_balance, weth_balance];
  th.logBN('Initial LUSD', lusd_balance)
  th.logBN('Initial OCEAN', weth_balance)

  const JOIN_KIND_INIT = 0;

  // Construct magic userData
  const initUserData =
        ethers.utils.defaultAbiCoder.encode(['uint256', 'uint256[]'],
                                            [JOIN_KIND_INIT, initialBalances]);
  const joinPoolRequest = {
    assets: tokens,
    maxAmountsIn: initialBalances,
    userData: initUserData,
    fromInternalBalance: false
  }

  // Caller is "you". joinPool takes a sender (source of initialBalances)
  // And a receiver (where BPT are sent). Normally, both are the caller.
  // If you have a User Balance of any of these tokens, you can set
  // fromInternalBalance to true, and fund a pool with no token transfers
  // (well, except for the BPT out)

  // Need to approve the Vault to transfer the tokens!
  const ocean = new ethers.Contract(
    OCEAN,
    WETH_ABI.abi,
    deployerWallet
  )
  th.logBN('ocean balance: ', await ocean.balanceOf(deployerWalletAddress))
  const currentWethBalance = await ocean.balanceOf(deployerWalletAddress)
  if (currentWethBalance.lt(weth_balance)) {
    const txDepositWeth = await ocean.deposit({ value: weth_balance.sub(currentWethBalance) });
    await txDepositWeth.wait()
  }
  th.logBN('ocean balance: ', await ocean.balanceOf(deployerWalletAddress))
  const txApproveWeth = await ocean.approve(VAULT, weth_balance);
  await txApproveWeth.wait()
  const lusd = new ethers.Contract(
    LUSD,
    ERC20.abi,
    deployerWallet
  )
  const txApproveLusd = await lusd.approve(VAULT, lusd_balance);
  await txApproveLusd.wait()

  // joins and exits are done on the Vault, not the pool
  const tx2 = await vault.joinPool(poolId, deployerWalletAddress, deployerWalletAddress, joinPoolRequest);
  // You can wait for it like this, or just print the tx hash and monitor
  const receipt2 = await tx2.wait();
  console.log('Final tx status:', receipt2.status)
  th.logBN('Pool BPT tokens', await pool.totalSupply())
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
