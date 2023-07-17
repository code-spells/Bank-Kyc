
async function main() {
  const KycContract = await ethers.getContractFactory("Kyc");
  const kyc = await KycContract.deploy();
  console.log("Contract object:", kyc);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });

