require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
	solidity: "0.8.17",
	networks: {
		mantle: {
			chainId: 5001,
			url: "https://rpc.testnet.mantle.xyz",
			accounts: [process.env.PRIVATE_KEY],
		},
	},
};
