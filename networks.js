require('dotenv').config();

const HDWalletProvider = require('@truffle/hdwallet-provider');
const infuraProjectId = process.env.INFURA_PROJECT_ID;

module.exports = {
  networks: {
    development: {
      protocol: 'http',
      host: '0.0.0.0',
      port: 8545,
      gas: 5000000,
      gasPrice: 5e9,
      networkId: '*',
    },
    ropsten: {
      provider: () => new HDWalletProvider(process.env.PrivateKey, "https://ropsten.infura.io/v3/" + infuraProjectId),
      networkId: 3,       // Ropsten's id
    },
    mainnet: {
      provider: () => new HDWalletProvider(process.env.PrivateKey, "https://mainnet.infura.io/v3/" + infuraProjectId),
      networkId: 1,       // Ropsten's id
    },
    rinkeby: {
      provider: () => new HDWalletProvider(process.env.PrivateKey, "https://rinkeby.infura.io/v3/" + infuraProjectId),
      networkId: 4,       // Rinkeby's id
    },
    kovan: {
      provider: () => new HDWalletProvider(process.env.PrivateKey, "https://kovan.infura.io/v3/" + infuraProjectId),
      networkId: 42,       // Kovan's id
    },
  },
};