async function main() {
  const VeriCert = await ethers.getContractFactory("VeriCert");
  const vericert = await VeriCert.deploy();
  await vericert.waitForDeployment();
  console.log("VeriCert desplegado en:", await vericert.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
