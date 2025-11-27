<div align="center">

# 🎯 DAgent Contractor - Cardano

### Decentralized Agent Registration & Staking Platform

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Aiken](https://img.shields.io/badge/aiken-v1.1.19-purple.svg)](https://aiken-lang.org)
[![Plutus](https://img.shields.io/badge/plutus-v3-red.svg)](https://plutus.readthedocs.io)
[![Cardano](https://img.shields.io/badge/cardano-blockchain-0033AD.svg)](https://cardano.org)

*Smart contracts for decentralized agent registration and staking on the Cardano blockchain*

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Architecture](#-architecture)
- [Getting Started](#-getting-started)
- [Contract Specifications](#-contract-specifications)
- [Development](#-development)
- [Testing](#-testing)
- [Deployment](#-deployment)
- [Contributing](#-contributing)
- [Resources](#-resources)

---

## 🌟 Overview

**DAgent Contractor** is a decentralized platform built on Cardano that enables secure agent registration and stake management. Written in [Aiken](https://aiken-lang.org), these smart contracts provide a robust foundation for managing agent relationships and token staking with full on-chain validation.

### Why DAgent?

- ✅ **Trustless Operations**: All transactions validated on-chain
- ✅ **Flexible Staking**: Support for multiple stake operations (create, transfer, pull)
- ✅ **Agent Registry**: Decentralized agent registration and management
- ✅ **Plutus V3**: Built with the latest Cardano smart contract platform
- ✅ **Type Safety**: Written in Aiken for compile-time guarantees

---

## ✨ Features

### 🔐 Staking System

- **Create Stakes**: Add new stakes linking clients to providers
- **Transfer Stakes**: Move stakes between users atomically
- **Pull Stakes**: Withdraw specific amounts from stake positions
- **Batch Operations**: Pull all stakes for a user in one transaction
- **Real-time Tracking**: Automatic total stake and count calculations
- **State Validation**: Built-in invariant checking for data integrity

### 👥 Agent Registration

- **Decentralized Registry**: On-chain agent registration
- **Immutable Records**: Tamper-proof agent information storage
- **Query Support**: Retrieve agent details and stakes on-chain

---

## 🏗️ Architecture

```
dagent-contractor-cardano/
├── validators/           # Smart contract validators
│   ├── stake/           # Staking contract
│   │   ├── stake.ak     # Main stake validator
│   │   └── stake_test.ak # Test suite
│   └── agents/          # Agent registration
│       └── agents.ak    # Agent validator
├── lib/                 # Supporting libraries
│   └── stake/
│       ├── types.ak     # Data type definitions
│       ├── transition.ak # State transition logic
│       └── check.ak     # Validation helpers
└── build/               # Compiled artifacts
```

### Contract Overview

#### Stake Contract (`validators/stake/stake.ak`)

The staking contract manages stake relationships between clients and providers:

```aiken
pub type Stake {
  client: ByteArray,      // Client address
  provider: ByteArray,    // Provider address
  amount: Int,            // Staked amount
  user_id: ByteArray,     // Unique user identifier
}
```

**Supported Actions:**
- `CreateStake` - Add new stake entry
- `TransferStake` - Move stake between users
- `PullStake` - Withdraw partial stake
- `PullAllStake` - Withdraw all user stakes
- `GetAddressStake` - Query stake by address
- `GetTotalStake` - Get total staked amount
- `GetTotalStakeCount` - Get total stake count

---

## 🚀 Getting Started

### Prerequisites

- [Aiken](https://aiken-lang.org/installation-instructions) v1.1.19 or later
- [Cardano Node](https://developers.cardano.org/docs/get-started/installing-cardano-node) (for deployment)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/d-agent/dagent-contract-cardano.git
   cd dagent-contract-cardano
   ```

2. **Build the contracts**
   ```bash
   aiken build
   ```

3. **Verify installation**
   ```bash
   aiken check
   ```

---

## 📖 Contract Specifications

### Stake Datum Structure

```aiken
pub type StakeDatum {
  stakes: List<Stake>,     // All stake records
  total_stake: Int,        // Sum of all stakes
  total_count: Int,        // Number of stakes
}
```

### State Transitions

All state transitions enforce invariants:
- Amounts must be positive
- Total stake must equal sum of individual stakes
- Total count must match list length
- Stakes cannot be duplicated

### Example Usage

**Creating a Stake:**
```aiken
CreateStake {
  client: "addr_client...",
  provider: "addr_provider...",
  amount: 1000000,  // 1 ADA (in lovelace)
  user_id: "user_123"
}
```

**Transferring Stakes:**
```aiken
TransferStake {
  from_user_id: "user_123",
  to_user_id: "user_456",
  amount: 500000  // 0.5 ADA
}
```

---

## 💻 Development

### Project Structure

Write validators in the `validators/` folder and supporting functions in the `lib/` folder using `.ak` as a file extension.

### Configuration

Edit `aiken.toml` for network configuration:

```toml
[config.default]
network_id = 41  # Testnet: 41, Mainnet: 1
```

### Building

Compile all contracts:
```bash
aiken build
```

Build artifacts will be generated in the `build/` directory.

---

## 🧪 Testing

### Running Tests

Execute all test suites:
```bash
aiken check
```

Run specific test modules:
```bash
aiken check -m stake
```

Run tests matching a pattern:
```bash
aiken check -m transfer
```

### Writing Tests

Tests are written inline using the `test` keyword:

```aiken
use stake/transition

test create_stake_increases_count() {
  let initial = StakeDatum { stakes: [], total_stake: 0, total_count: 0 }
  let result = transition.create_stake(
    initial,
    CreateStake { client: "c1", provider: "p1", amount: 100, user_id: "u1" }
  )
  result.total_count == 1
}
```

---

## 🚢 Deployment

### Generate Documentation

Create HTML documentation for the contracts:
```bash
aiken docs
```

### Blueprint Generation

After building, contract blueprints are available in:
```
build/packages/dagent-dagent-contractor-cardano/
```

### Network Deployment

1. Build for target network (configure `aiken.toml`)
2. Generate blueprint with `aiken build`
3. Submit using Cardano CLI or transaction builder
4. Reference contract hash in transactions

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`aiken check`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Standards

- Follow Aiken style guidelines
- Add tests for new functionality
- Document public functions
- Keep validators focused and minimal

---

## 📚 Resources

- [Aiken Documentation](https://aiken-lang.org) - Learn Aiken language
- [Cardano Developers](https://developers.cardano.org) - Cardano development resources
- [Plutus](https://plutus.readthedocs.io) - Plutus platform documentation
- [Aiken Standard Library](https://aiken-lang.github.io/stdlib/) - Built-in functions reference

---


<div align="center">

**Built with ❤️ using [Aiken](https://aiken-lang.org) on [Cardano](https://cardano.org)**

[Report Bug](https://github.com/d-agent/dagent-contract-cardano/issues) · [Request Feature](https://github.com/d-agent/dagent-contract-cardano/issues)

</div>
