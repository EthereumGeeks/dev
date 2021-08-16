require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-ethers");
// require("@nomiclabs/hardhat-etherscan");
require("solidity-coverage");
require("hardhat-gas-reporter");
require("hardhat-contract-sizer");
const accounts = require("./hardhatAccountsList2k.js");
const {Wallet} = require("@ethersproject/wallet");
const accountsList = accounts.accountsList
// params for the dev deployment 
const deployerAccount = process.env.DEPLOYER_PRIVATE_KEY || Wallet.createRandom().privateKey;
const devChainRichAccount = "0x4d5db4107d237df6a3d58ee5f70ae63d73d7658d4026f2eefd2f204c81682cb7";

// reference from the lib-ethers , for creating the  dev enviornment EOA wallets .
let  numberOfAccounts = 0;
const generateRandomAccounts = (numberOfAccounts) => {
    const accounts = new Array<String>(numberOfAccounts);
  
    for (let i = 0; i < numberOfAccounts; ++i) {
      accounts[i] = Wallet.createRandom().privateKey;
    }
  
}
const numAccounts = 100;




const fs = require('fs')
const getSecret = (secretKey, defaultValue='') => {
    const SECRETS_FILE = "./secrets.js"
    let secret = defaultValue
    if (fs.existsSync(SECRETS_FILE)) {
        const { secrets } = require(SECRETS_FILE)
        if (secrets[secretKey]) { secret = secrets[secretKey] }
    }

    return secret
}
const alchemyUrl = () => {
    return `https://eth-mainnet.alchemyapi.io/v2/${getSecret('alchemyAPIKey')}`
}

const alchemyUrlRinkeby = () => {
    return `https://eth-rinkeby.alchemyapi.io/v2/${getSecret('alchemyAPIKeyRinkeby')}`
}


const devUrl = () => {
    return `http://localhost:8545`
}

module.exports = {
    paths: {
        // contracts: "./contracts",
        // artifacts: "./artifacts"
    },
    solidity: {
        compilers: [
            {
                version: "0.4.23",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 100
                    }
                }
            },
            {
                version: "0.5.17",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 100
                    }
                }
            },
            {
                version: "0.6.11",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 100
                    }
                }
            },
        ]
    },
    networks: {
        hardhat: {
            accounts: accountsList,
            gas: 10000000,  // tx gas limit
            blockGasLimit: 12500000, 
            gasPrice: 20000000000,
        },
        mainnet: {
            url: alchemyUrl(),
            gasPrice: 150000000000,
            accounts: [
                getSecret('DEPLOYER_PRIVATEKEY', '0x60ddfe7f579ab6867cbe7a2dc03853dc141d7a4ab6dbefc0dae2d2b1bd4e487f'),
                getSecret('ACCOUNT2_PRIVATEKEY', '0x3ec7cedbafd0cb9ec05bf9f7ccfa1e8b42b3e3a02c75addfccbfeb328d1b383b')
            ]
        },
        rinkeby: {
            url: alchemyUrlRinkeby(),
            gas: 10000000,  // tx gas limit
            accounts: [getSecret('RINKEBY_DEPLOYER_PRIVATEKEY', '0x60ddfe7f579ab6867cbe7a2dc03853dc141d7a4ab6dbefc0dae2d2b1bd4e487f')]
        },
        dev: {
            
            url: devUrl(),
            gas: 100000000 ,
            accounts: [deployerAccount, devChainRichAccount, ...generateRandomAccounts(numAccounts - 2)]


        }
    
    
    },
    etherscan: {
        apiKey: getSecret("ETHERSCAN_API_KEY")
    },
    mocha: { timeout: 12000000 },
    rpc: {
        host: "localhost",
        port: 8545
    },
    gasReporter: {
        enabled: (process.env.REPORT_GAS) ? true : false
    }, 

    contractSizer: {
        alphaSort: true,
        runOnCompile: true,
        disambiguatePaths: false,
      }
};
