const { ethers } = require("hardhat");

async function main() {
  const [owner, institucion] = await ethers.getSigners();

  // Desplegar contrato
  const VeriCert = await ethers.getContractFactory("VeriCert");
  const vericert = await VeriCert.deploy();
  await vericert.waitForDeployment();

  // Autorizar institución
  await vericert.autorizarInstitucion(institucion.address);

  // Emitir certificado
  const tx = await vericert.connect(institucion).emitirCertificado(
    "Título en Desarrollo de Software",
    "Juan Pérez"
  );
  const receipt = await tx.wait();

  // Decodificar el evento CertificadoEmitido usando la interfaz del contrato
  const iface = vericert.interface;
  let certificadoId;
  for (const log of receipt.logs) {
    try {
      const parsed = iface.parseLog(log);
      if (parsed.name === "CertificadoEmitido") {
        certificadoId = parsed.args.certificadoId;
        break;
      }
    } catch (e) {
      // No es un log de este contrato, continuar
      continue;
    }
  }

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
