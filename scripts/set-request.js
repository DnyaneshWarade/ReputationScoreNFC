async function main() {

	const circuitId = "credentialAtomicQuerySig";

	// CredentialAtomicQuerySigValidator Mumbai address
	const validatorAddress = "0xb1e86C4c687B85520eF4fd2a0d14e81970a15aFB";

	const schemaHash = "138b98856220936dcfd1267545ececd5";

	const schemaEnd = fromLittleEndian(hexToBytes(schemaHash));

	
	const onChainQuery = {
		schema: ethers.BigNumber.from(schemaEnd),
		slotIndex: 2,
		operator: 3,
		value: [0, ...new Array(63).fill(0).map((i) => 0)],
		circuitId,
	};

	const offChainQuery = {
		schema: ethers.BigNumber.from(schemaEnd),
		slotIndex: 3,
		operator: 3,
		value: [0, ...new Array(63).fill(0).map((i) => 0)],
		circuitId,
	};

	// add the address of the contract just deployed
	const ERC721VerifierAddress = "0x439a2A7E5bf91d6dAd804873F83a528F78Ac424F";

	let erc721Verifier = await hre.ethers.getContractAt(
		"ERC721Verifier",
		ERC721VerifierAddress
	);

	const requestId = await erc721Verifier.TRANSFER_REQUEST_ID();

	try {
		const tx = await erc721Verifier.setZKPRequest(
			requestId,
			validatorAddress,
			onChainQuery
		);

		await tx.wait(1);

		console.log("Request set for onChain score");
		// await erc721Verifier.setZKPRequest(
		// 	requestId,
		// 	validatorAddress,
		// 	offChainQuery
		// );
		// console.log("Request set for offChain score");
	} catch (e) {
		console.log("error: ", e);
	}
}

function hexToBytes(hex) {
	for (var bytes = [], c = 0; c < hex.length; c += 2)
		bytes.push(parseInt(hex.substr(c, 2), 16));
	return bytes;
}

function fromLittleEndian(bytes) {
	const n256 = BigInt(256);
	let result = BigInt(0);
	let base = BigInt(1);
	bytes.forEach((byte) => {
		result += base * BigInt(byte);
		base = base * n256;
	});
	return result;
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
