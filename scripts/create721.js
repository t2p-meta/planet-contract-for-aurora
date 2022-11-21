var Web3 = require('web3')
var config = require('./config.js')
var utils = require('./utils.js')
const HDWalletProvider = require('@truffle/hdwallet-provider')

const provider = new HDWalletProvider({
  privateKeys: [config.privateKey],
  providerOrUrl: config.apiUrl,
  chainId: config.chainId,
})
const web3 = new Web3(provider)

const truffle_contract = require('@truffle/contract')

function getContract(abi_name) {
  var abi = require(abi_name)
  var contract = truffle_contract(abi)
  contract.setProvider(web3.currentProvider)
  return contract
}

async function createBox721(miner) {
  var contract = getContract('../build/contracts/Finger721.json')
  try {
    return await contract.new(
      config.BoxNFTName,
      config.BoxNFTName,
      miner,
      config.beneficiary,
      'ipfs:/',
      'ipfs:/',
      { from: provider.addresses[0] }
    )
  } catch (e) {
    return { error: e.message }
  }
}

async function create() {
  var address = provider.addresses[0].toLocaleLowerCase()
  var filename = './' + address + '_' + config.chainId + '.json'
  var data = await utils.readJsonFile(filename)
  if (!data.copyERC721) {
    console.log('copyERC721 not deploy')
    process.exit()
  }
  var copyERC721 = data.copyERC721.address

  filename = './' + address + '_' + config.chainId + '_NFTBox.json'
  data = await utils.readJsonFile(filename)
  console.log('data', data)
  console.log('start create...')

  var result = null
  if (!data.Box721) {
    console.log('create Box721...')
    result = await createBox721(copyERC721)
    if (result.error) {
      console.log('create NFT721 error', result.error)
      process.exit()
    }
    console.log('create NFT721 address:', result.address)
    data.NFT721 = {
      address: result.address,
    }
    await utils.writeJsonFile(filename, data)
  }

  process.exit()
}

create()
