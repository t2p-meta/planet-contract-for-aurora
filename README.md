# The 2nd Planet Smart Contracts

> This contract base on fingerchar from 2022-02-10

- truffle compile
- node scripts/deploy.js
- node scripts/operator.js


## Usage

### Install dependent packages


```bash
cd planet-contract
yarn
```

- compile contracts

```bash
npm install truffle -g  
truffle compile 
```

----
### Configuration

You can use the truffle script to deploy, or you can use the deployment script we have written. Here we only talk about using the script to deploy the contract.

The deployment script is in the migrations folder,

### Configuration Tempalte

> at scripts/config

```js
const path = require('path')
const envfile = path.resolve(__dirname, '../../', 'envs/.env')
const DEPLOY_ENV = loadEnv()

// Aurora Testnet
module.exports = {
  privateKey: DEPLOY_ENV.PRIVATE_KEY,
  apiUrl: 'https://aurora-testnet.infura.io/v3/' + DEPLOY_ENV.INFURA_PROJECT_KEY,
  chainId: 4,
  NFTName: 'Same NFT',
  BoxNFTName: 'SNFT',
  miner: '',
  beneficiary: '',
  buyerFeeSigner: '',
}

function loadEnv() {
  const result = require('dotenv').config({ path: envfile, encoding: 'utf8' })

  if (result.error) {
    throw result.error
  }
  const envParsed = result.parsed || {}
  if (!envParsed.PRIVATE_KEY)
    throw new Error('Required PRIVATE_KEY in ENV File')

  return envParsed
}

```
### AURORA Testnet Network Contact Address

RPC: https://testnet.aurora.dev
Channel id: 1313161555
Explorer Address: e.g. https://testnet.aurorascan.dev/address/0x32665EF0F715Da3e87e3Df00AB21CF59bBC43752
Explorer tx: e.g. https://testnet.aurorascan.dev/tx/0x45dd1cb1354a6b3882018e78cf07febcab9e60d08769c68a380a7c89e2006fe3


####  1.Main Contract

```json
{
  "NFT721": {
    "address": "0x32665EF0F715Da3e87e3Df00AB21CF59bBC43752"
  },
  "NFT1155": {
    "address": "0x83a57E66551947102e12d3aD9e50a4ac5677A0a6"
  },
  "transferProxy": {
    "address": "0xC0a5270b7AB89f538dFeE21Ba7b38AB63FFB003B"
  },
  "transferProxyForDeprecated": {
    "address": "0xeABeBB32e123b95E6d3Daa0d02a58B89d357B3e3"
  },
  "erc20TransferProxy": {
    "address": "0xF6dB0635C7EB842C4112bdD2d814fE4fdA382dE8"
  },
  "exchangeState": {
    "address": "0xc516DD8d993274CdEdaB01D61745C42A7eCB379A"
  },
  "exchangeOrderHolder": {
    "address": "0x6A5Acc119B405aA4DC0b92163F51B72B598D0521"
  },
  "exchange": {
    "address": "0xd829329781FA7E1e678aFdA80680eA6De5487908",
    "transferProxyTx": "0x45dd1cb1354a6b3882018e78cf07febcab9e60d08769c68a380a7c89e2006fe3",
    "transferProxyForDeprecatedTx": "0x4f447b4896f717d923d0d5736b82383c1c79d434c389a7bff93763aef40d3ec2",
    "erc20TransferProxyTx": "0x53aa87712d76891cdc3f1eb4f4c28fae2b53be266d7f754144ff5caca4cb02c8",
    "exchangeStateTx": "0x115aee534c47bafd24a5d3fb04432493c1140572ad8ef870d154eabd03a7c2d1"
  },
  "blindState": {
    "address": "0xfE108De21563563a4148bA2Bd5a457C87c58D36C"
  },
  "copyERC721": {
    "address": "0x3288A27a431b3a052451F73Df25490c9f6A59987"
  },
  "blindBox": {
    "address": "0x09cb91e30fA29450af4fd641760C5b06e63aB993",
    "transferProxyTx": "0xa403ab63f67e8e667ac3549cf17db122183f66967570a2b398794dd1c57fd90e",
    "transferProxyForDeprecatedTx": "0x69abf9921363002e62201267dec4236e1e55601e56a77c3b6f0bea7a6c84e7f5",
    "erc20TransferProxyTx": "0x47ab1bd6a8a60ece56ccc9811bad34b680658bdb5fa46ed06a3ee192b1ddfd76",
    "blindStateTx": "0xeb154351616b7e82fc83c3e975ef9933bf2e6d405813cf468b5839d59032dda7",
    "copyERC721Tx": "0x20a7d0acefb4ff229328a854b78fb6a03c4cffa31f7c0c4580a3c69d5a52c852"
  },
  "auctionState": {
    "address": "0x076314379d64eE388d3cd4eB857C332474861B4F"
  },
  "auctionExchange": {
    "address": "0xda94eF09421Cf7EEA0e4C8b2F7A3dc9351c8dCf9",
    "transferProxyTx": "0xa5ef6505f1ba27f18e3868e57bb844e42742c03a72c8bae41345a658c9fcf70f",
    "transferProxyForDeprecatedTx": "0x4032ca021b1a5d895de1d65572db9d30c733a0cba090cca46911a162efab0c49",
    "erc20TransferProxyTx": "0x7fada81b438eeb5442ad73af207c86275d6ffac76530e594898153047421656e",
    "auctionStateTx": "0xa848e4672cf5e4411ebcfe584fd5165c203274c7205af75fe05740063b60f1e7"
  }
}
```
#### 2.blindBox NFT721contract
```json
{
  "NFT721": {
    "address": "0x2D123Cb9297123357Eaa3eF9Cc80E17D2c342335"
  }
}
```
####  3.Equipment, cards, keys, passport, land NFT721 contract, air drop contract
```json
{
  "CardMerge721": "0xe744553218e7051dadEde0B20097e5843E874b5B",
  "DropsNFT721": "0xc58bE7Ad435AB3e1CdBA5AF5f55913a80C7713b5",
  "erc20TransferProxyTx": "0x726baa2689cbf1d51695286c359b2666562a14459c96b4c53007c940b2cd64f4"
}
```
####  4.ERC-20 token
```json
{
  "Token": {
    "address": "0x03E59D1d2363504929a84D9CC60D6605D3C5F44A"
  }
}
```

