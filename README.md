# Pharmaceutical Supply Integrity Contract

A comprehensive blockchain-based solution for pharmaceutical supply chain management, ensuring end-to-end transparency, traceability, and quality control using Stacks smart contracts built with Clarity.

## 🔍 Overview

This project implements two critical smart contracts to address pharmaceutical industry challenges:

1. **Distribution Tracking Contract**: Manages the complete chain of custody for pharmaceutical products
2. **Manufacturing Verification Contract**: Handles quality control verification and manufacturing compliance

The system provides immutable, transparent tracking of pharmaceutical products from manufacturing through distribution to end consumers, ensuring regulatory compliance and preventing counterfeit drugs from entering the supply chain.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 Stacks Blockchain                       │
├─────────────────────────────────────────────────────────┤
│  Distribution Tracking    │  Manufacturing Verification │
│                          │                             │
│  • Chain of Custody      │  • Production Records       │
│  • Transfer Tracking     │  • Quality Control          │
│  • Shipment Management   │  • Batch Verification       │
│  • Custody Verification  │  • Compliance Monitoring    │
└─────────────────────────────────────────────────────────┘
```

## ✨ Key Features

### Distribution Tracking Contract
- **Chain of Custody Management**: Complete immutable tracking of product movement
- **Multi-Party Authorization**: Secure authentication for distributors, wholesalers, and pharmacies
- **Shipment Creation & Tracking**: Comprehensive batch management with unique identifiers
- **Transfer Authorization**: Principal-based secure custody transfers
- **Real-time Queries**: Instant access to current custodian and full transfer history
- **Compliance Verification**: Built-in verification system for regulatory requirements

### Manufacturing Verification Contract
- **Manufacturer Registry**: Secure registration and management of authorized manufacturers
- **Production Documentation**: Immutable batch production records with comprehensive metadata
- **Quality Control System**: Auditor-verified quality assessments with scoring
- **GMP Compliance**: Good Manufacturing Practice certificate tracking and validation
- **Batch Certification**: Automated certification based on quality thresholds
- **Statistical Analytics**: Real-time manufacturing performance and compliance metrics

## 🛠️ Technology Stack

- **Blockchain Platform**: Stacks (Bitcoin Layer 2)
- **Smart Contract Language**: Clarity
- **Development Framework**: Clarinet
- **Testing**: Clarinet built-in testing suite
- **Version Control**: Git with GitHub integration

## 📋 Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) (v16 or later)
- [Git](https://git-scm.com/)
- [GitHub CLI](https://cli.github.com/) (optional, for deployment)

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/fatimaabubakarlokogoma/pharmaceutical-supply-integrity-contract.git
cd pharmaceutical-supply-integrity-contract
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Validate Contracts
```bash
clarinet check
```

### 4. Run Tests
```bash
npm test
```

### 5. Deploy Locally
```bash
clarinet integrate
```

## 📖 Usage Examples

### Distribution Tracking Workflow

```clarity
;; Register supply chain participants
(contract-call? .distribution-tracking register-distributor)
(contract-call? .distribution-tracking register-wholesaler 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(contract-call? .distribution-tracking register-pharmacy 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

;; Create and track pharmaceutical shipments
(contract-call? .distribution-tracking create-shipment 
    "BATCH-2024-001" 
    u5000 
    "Aspirin 500mg" 
    'ST1MANUFACTURER... 
    "2026-12-31" 
    'ST2DISTRIBUTOR...)

;; Transfer custody between supply chain entities
(contract-call? .distribution-tracking transfer-custody 
    "BATCH-2024-001" 
    'ST3WHOLESALER...)

;; Query current custodian
(contract-call? .distribution-tracking get-current-custodian "BATCH-2024-001")
```

### Manufacturing Verification Workflow

```clarity
;; Register manufacturing ecosystem participants
(contract-call? .manufacturing-verification register-manufacturer 
    'ST1MANUFACTURER... 
    "PharmaCorp LLC" 
    "MFG-LIC-2024-001")

(contract-call? .manufacturing-verification register-auditor 'ST4AUDITOR...)

;; Record production batch with comprehensive metadata
(contract-call? .manufacturing-verification record-production-batch
    "BATCH-2024-001"
    "DRUG-ASP-500"
    "2024-09-01"
    "LOT-240901-001"
    "2026-08-31"
    u10000
    0x1234567890abcdef1234567890abcdef12345678
    "Manufacturing Facility A")

;; Add quality control assessment
(contract-call? .manufacturing-verification add-qc-record
    "BATCH-2024-001"
    true
    "All quality parameters within specified limits"
    "pH: 7.2, Purity: 99.8%, Dissolution: 95%"
    u92
    0x9876543210fedcba9876543210fedcba98765432)

;; Certify batch based on quality scores
(contract-call? .manufacturing-verification certify-batch "BATCH-2024-001")
```

## 🔐 Security Features

- **Principal-Based Authentication**: All operations require proper Stacks principal authorization
- **Role-Based Access Control**: Different permission levels for manufacturers, distributors, and auditors
- **Immutable Data Storage**: All critical supply chain data permanently recorded on blockchain
- **Input Validation**: Comprehensive parameter validation and error handling
- **Event Logging**: Detailed event emission for off-chain monitoring and compliance

## 📊 Compliance & Regulatory Support

### FDA Drug Supply Chain Security Act (DSCSA)
- Complete product traceability from manufacturer to dispenser
- Verification of trading partner authorization
- Product identification and authentication
- Suspect and illegitimate product detection

### Good Manufacturing Practice (GMP)
- Certificate tracking and validation
- Quality control documentation
- Batch record maintenance
- Audit trail preservation

### International Standards
- ICH Q10 Quality System compliance
- ISO 9001 quality management alignment
- WHO Good Distribution Practice support

## 🧪 Testing

The project includes comprehensive test suites for both contracts:

```bash
# Run all tests
npm test

# Test specific contracts
clarinet test tests/distribution-tracking.test.ts
clarinet test tests/manufacturing-verification.test.ts

# Generate coverage report
npm run test:coverage
```

## 🚀 Deployment

### Local Deployment (Devnet)
```bash
clarinet deploy --devnet
```

### Testnet Deployment
```bash
clarinet deploy --testnet
```

### Mainnet Deployment
```bash
clarinet deploy --mainnet
```

## 📚 API Documentation

### Distribution Tracking Contract Functions

#### Public Functions
- `register-distributor()`: Register distributor principal
- `register-wholesaler(principal)`: Register wholesaler principal
- `register-pharmacy(principal)`: Register pharmacy principal
- `create-shipment(...)`: Create new pharmaceutical shipment
- `transfer-custody(batch-id, new-custodian)`: Transfer batch custody
- `mark-batch-verified(batch-id)`: Mark batch as compliance verified

#### Read-Only Functions
- `get-batch-info(batch-id)`: Retrieve batch information
- `get-current-custodian(batch-id)`: Get current batch custodian
- `get-custody-chain(batch-id)`: Get complete transfer history
- `get-batch-stats(batch-id)`: Get batch statistics

### Manufacturing Verification Contract Functions

#### Public Functions
- `register-manufacturer(principal, name, license)`: Register manufacturer
- `register-auditor(principal)`: Register quality auditor
- `record-production-batch(...)`: Record new production batch
- `add-qc-record(...)`: Add quality control assessment
- `certify-batch(batch-id)`: Certify batch quality

#### Read-Only Functions
- `get-production-batch(batch-id)`: Get production batch details
- `get-qc-record(batch-id, auditor)`: Get quality control record
- `is-batch-certified(batch-id)`: Check batch certification status
- `get-batch-compliance-score(batch-id)`: Get compliance score

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/enhancement`)
3. Commit changes (`git commit -am 'Add new feature'`)
4. Push to branch (`git push origin feature/enhancement`)
5. Create Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support, please:
- Open an issue on GitHub
- Review the [Clarinet documentation](https://docs.hiro.so/clarinet)
- Check the [Stacks documentation](https://docs.stacks.co/)

## 🙏 Acknowledgments

- [Stacks Foundation](https://stacks.org/) for blockchain infrastructure
- [Hiro](https://www.hiro.so/) for Clarinet development tools
- Pharmaceutical industry stakeholders for requirements guidance

---

**⚠️ Important Notice**: This software is provided for development and testing purposes. Production deployment in pharmaceutical supply chains requires thorough security audits, regulatory compliance validation, and proper risk assessment.
