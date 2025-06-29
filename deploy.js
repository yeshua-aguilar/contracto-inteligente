async function main() {
  const VeriCert = await ethers.getContractFactory("VeriCert");
  const vericert = await VeriCert.deploy();
  await vericert.deployed();
  console.log("VeriCert desplegado en:", vericert.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
