const { ethers } = require("hardhat");

async function main() {
  const [owner, institucion] = await ethers.getSigners();

  // Desplegar contrato
  const VeriCert = await ethers.getContractFactory("VeriCert");
  const vericert = await VeriCert.deploy();
  await vericert.deployed();

  // Autorizar institución
  await vericert.autorizarInstitucion(institucion.address);

  // Emitir certificado
  const tx = await vericert.connect(institucion).emitirCertificado(
    "Título en Desarrollo de Software",
    "Juan Pérez"
  );
  const receipt = await tx.wait();
  const certificadoId = receipt.events[0].args.certificadoId;

  // Verificar certificado
  const cert = await vericert.verificarCertificado(certificadoId);
  console.log("Certificado:", cert);

  // Revocar certificado
  await vericert.connect(institucion).revocarCertificado(certificadoId);

  // Verificar nuevamente
  const cert2 = await vericert.verificarCertificado(certificadoId);
  console.log("Certificado tras revocación:", cert2);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
