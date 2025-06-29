// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VeriCert
 * @dev Este contrato inteligente permite a instituciones autorizadas emitir, revocar y verificar credenciales digitales.
 * Se alinea con el concepto del prototipo "VeriCert", enfocado en la robustez de la lógica on-chain[cite: 3, 6].
 * El despliegue y la gestión se realizan a través de una cuenta de administrador (propietario)[cite: 8].
 */
contract VeriCert {

    // ==================================================================
    // Estructuras de Datos
    // ==================================================================

    /**
     * @dev Representa una credencial o certificado digital.
     * Contiene la información esencial que se almacena de forma inmutable en la blockchain.
     */
    struct Certificado {
        bytes32 id;                  // ID único del certificado
        address institucionEmisora;  // Dirección de la institución que lo emitió
        string nombreCertificado;    // Ej: "Título en Desarrollo de Software"
        string nombreDestinatario;   // Nombre de la persona que recibe el certificado
        uint256 fechaEmision;        // Timestamp de la emisión
        bool revocado;               // Estado de revocación
    }

    // ==================================================================
    // Variables de Estado
    // ==================================================================

    address public owner; // La cuenta que despliega y gestiona el contrato[cite: 8].

    mapping(bytes32 => Certificado) public certificados; // Mapeo de ID de certificado a su estructura.
    mapping(address => bool) public institucionesAutorizadas; // Mapeo para validar instituciones.

    // ==================================================================
    // Eventos
    // ==================================================================

    event CertificadoEmitido(
        bytes32 indexed certificadoId,
        address indexed institucionEmisora,
        string nombreDestinatario
    );

    event CertificadoRevocado(
        bytes32 indexed certificadoId,
        address indexed institucionEmisora
    );

    event InstitucionAutorizada(address indexed institucion);
    event InstitucionRevocada(address indexed institucion);

    // ==================================================================
    // Modificadores
    // ==================================================================

    /**
     * @dev Restringe la ejecución de una función solo al propietario del contrato.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Error: Solo el propietario puede realizar esta accion.");
        _;
    }

    /**
     * @dev Restringe la ejecución de una función solo a las instituciones autorizadas.
     */
    modifier onlyInstitucionAutorizada() {
        require(institucionesAutorizadas[msg.sender], "Error: Su direccion no corresponde a una institucion autorizada.");
        _;
    }

    // ==================================================================
    // Constructor
    // ==================================================================

    /**
     * @dev Se ejecuta una sola vez al desplegar el contrato en la red (ej. Testnet Sepolia)[cite: 8].
     * Establece al desplegador como el 'owner' del contrato.
     */
    constructor() {
        owner = msg.sender;
    }

    // ==================================================================
    // Funciones de Gestión (Solo para el Owner)
    // ==================================================================

    /**
     * @dev Permite al 'owner' autorizar a una nueva institución para emitir certificados.
     * @param _institucion La dirección de la billetera de la institución a autorizar.
     */
    function autorizarInstitucion(address _institucion) public onlyOwner {
        require(_institucion != address(0), "Error: La direccion de la institucion no puede ser la direccion cero.");
        institucionesAutorizadas[_institucion] = true;
        emit InstitucionAutorizada(_institucion);
    }

    /**
     * @dev Permite al 'owner' revocar la autorización de una institución.
     * @param _institucion La dirección de la billetera de la institución a revocar.
     */
    function revocarAutorizacion(address _institucion) public onlyOwner {
        require(institucionesAutorizadas[_institucion], "Error: La institucion no esta actualmente autorizada.");
        institucionesAutorizadas[_institucion] = false;
        emit InstitucionRevocada(_institucion);
    }

    // ==================================================================
    // Lógica de Negocio de VeriCert (Funciones Principales)
    // ==================================================================

    /**
     * @notice Emite un nuevo certificado digital en la blockchain[cite: 8].
     * @dev Solo puede ser llamada por una institución autorizada. Genera un ID único.
     * @param _nombreCertificado El nombre del título o credencial.
     * @param _nombreDestinatario El nombre completo del profesional.
     * @return El ID único del certificado generado.
     */
    function emitirCertificado(
        string memory _nombreCertificado,
        string memory _nombreDestinatario
    ) public onlyInstitucionAutorizada returns (bytes32) {
        // Generar un ID único para el certificado
        bytes32 certificadoId = keccak256(
            abi.encodePacked(
                block.timestamp,
                msg.sender,
                _nombreCertificado,
                _nombreDestinatario
            )
        );

        // Almacenar el nuevo certificado
        certificados[certificadoId] = Certificado({
            id: certificadoId,
            institucionEmisora: msg.sender,
            nombreCertificado: _nombreCertificado,
            nombreDestinatario: _nombreDestinatario,
            fechaEmision: block.timestamp,
            revocado: false
        });

        // Emitir el evento correspondiente
        emit CertificadoEmitido(certificadoId, msg.sender, _nombreDestinatario);

        return certificadoId;
    }

    /**
     * @notice Revoca un certificado existente[cite: 8].
     * @dev Solo la institución que emitió el certificado puede revocarlo.
     * @param _certificadoId El ID del certificado a revocar.
     */
    function revocarCertificado(bytes32 _certificadoId) public {
        Certificado storage cert = certificados[_certificadoId];
        require(cert.institucionEmisora != address(0), "Error: El certificado no existe.");
        require(msg.sender == cert.institucionEmisora, "Error: No tiene permiso para revocar este certificado.");
        require(!cert.revocado, "Error: El certificado ya ha sido revocado previamente.");

        cert.revocado = true;
        emit CertificadoRevocado(_certificadoId, msg.sender);
    }

    /**
     * @notice Verifica la validez y los detalles de un certificado[cite: 8].
     * @dev Es una función de lectura `view`, no genera costos de gas (más allá de la llamada).
     * @param _certificadoId El ID del certificado a verificar.
     * @return Los detalles completos del certificado.
     */
    function verificarCertificado(bytes32 _certificadoId)
        public
        view
        returns (
            bytes32 id,
            address institucionEmisora,
            string memory nombreCertificado,
            string memory nombreDestinatario,
            uint256 fechaEmision,
            bool esValido
        )
    {
        Certificado storage cert = certificados[_certificadoId];
        require(cert.institucionEmisora != address(0), "Error: El certificado con este ID no fue encontrado.");

        return (
            cert.id,
            cert.institucionEmisora,
            cert.nombreCertificado,
            cert.nombreDestinatario,
            cert.fechaEmision,
            !cert.revocado // Un certificado es válido si NO está revocado.
        );
    }
}