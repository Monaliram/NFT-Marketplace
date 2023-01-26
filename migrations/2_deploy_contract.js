var myNFT = artifacts.require("./myNFT.sol");
var NftMarketplace = artifacts.require("./NftMarketplace.sol")

module.exports = async function (deployer) {
    await deployer.deploy(NftMarketplace);
    const marketplace = await NftMarketplace.deployed();
    await deployer.deploy(myNFT, marketplace.address);
    console.log(marketplace.address)
};