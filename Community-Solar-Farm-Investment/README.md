# Community Solar Farm Investment Smart Contract

## Overview

The Community Solar Farm Investment smart contract enables fractional ownership of renewable energy projects on the Stacks blockchain. This contract allows multiple investors to pool resources and invest in solar farm projects, providing democratic access to renewable energy investments with transparent returns distribution.

## Features

### Core Functionality
- **Solar Farm Creation**: Project developers can create new solar farm investment opportunities
- **Fractional Investment**: Users can purchase shares in solar farms with flexible investment amounts
- **Portfolio Management**: Track investments across multiple solar farm projects
- **Return Distribution**: Automated calculation and distribution of investment returns
- **Withdrawal System**: Time-locked withdrawal system after project completion

### Key Benefits
- Lower barrier to entry for renewable energy investments
- Transparent blockchain-based ownership records
- Automated return calculations based on project performance
- Platform fee system for sustainable operations
- Multi-farm portfolio diversification

## Contract Architecture

### Data Structures

#### Solar Farms
```clarity
{
    owner: principal,           // Project developer
    name: string-ascii 64,      // Farm name
    location: string-ascii 64,  // Geographic location
    capacity-kwh: uint,         // Energy production capacity
    cost-per-share: uint,       // Price per ownership share
    total-shares: uint,         // Total available shares
    shares-sold: uint,          // Shares already sold
    is-active: bool,           // Farm operational status
    created-at: uint,          // Creation block height
    expected-roi: uint,        // Expected return on investment
    project-duration: uint     // Project timeline in blocks
}
```

#### Investments
```clarity
{
    shares-owned: uint,        // Number of shares owned
    investment-amount: uint,   // Total STX invested
    invested-at: uint,         // Investment block height
    total-returns: uint        // Accumulated returns
}
```

### Main Functions

#### For Project Developers
- `create-solar-farm()` - Register new solar farm projects
- `distribute-returns()` - Distribute earnings to investors
- `toggle-farm-status()` - Activate/deactivate projects

#### For Investors
- `invest-in-farm()` - Purchase shares in solar farms
- `withdraw-investment()` - Withdraw principal + returns after project completion
- `get-investment-details()` - View investment portfolio
- `calculate-investment-return()` - Calculate expected returns

#### Administrative
- `update-platform-fee()` - Adjust platform fee structure
- `get-platform-stats()` - View platform-wide statistics

## Usage Examples

### Creating a Solar Farm
```clarity
(contract-call? .solar-farm-investment create-solar-farm 
    "Sunrise Solar Farm" 
    "California, USA" 
    u500000  ;; 500,000 kWh capacity
    u1000    ;; 1000 STX per share
    u100     ;; 100 total shares
    u800     ;; 8% expected ROI
    u525600  ;; 1 year duration
)
```

### Investing in a Farm
```clarity
(contract-call? .solar-farm-investment invest-in-farm 
    u1       ;; Farm ID
    u5       ;; 5 shares
)
```

### Withdrawing Investment
```clarity
(contract-call? .solar-farm-investment withdraw-investment u1)
```

## Security Features

### Access Controls
- Owner-only functions protected with `CONTRACT_OWNER` validation
- Farm creators have administrative rights over their projects
- Investor-specific functions validate `tx-sender` permissions

### Investment Protection
- Minimum investment validation prevents zero-amount transactions
- Share availability checking prevents overselling
- Time-locked withdrawals ensure project completion
- Platform fee caps prevent excessive fees (max 10%)

### Error Handling
Comprehensive error codes for all failure scenarios:
- `ERR_NOT_AUTHORIZED` (100) - Unauthorized access attempts
- `ERR_INSUFFICIENT_FUNDS` (101) - Inadequate STX balance
- `ERR_INVALID_AMOUNT` (102) - Invalid investment amounts
- `ERR_FARM_NOT_FOUND` (103) - Non-existent farm references
- `ERR_FARM_INACTIVE` (104) - Operations on inactive farms
- `ERR_ALREADY_INVESTED` (105) - Duplicate investment attempts
- `ERR_FARM_FULL` (107) - Oversold farm shares
- `ERR_WITHDRAWAL_TOO_EARLY` (108) - Premature withdrawal attempts

## Fee Structure

The platform implements a transparent fee system:
- **Platform Fee**: 5% of investment amount (configurable)
- **Fee Distribution**: Collected fees support platform operations
- **Fee Caps**: Maximum fee rate limited to 10%

## Deployment Instructions

### Prerequisites
- Clarinet CLI installed
- Stacks wallet for deployment
- Sufficient STX for deployment costs

### Local Testing
```bash
clarinet check
clarinet test
clarinet integrate
```

### Mainnet Deployment
```bash
clarinet deploy --network=mainnet
```

## Integration Guide

### Frontend Integration
The contract provides read-only functions for frontend applications:

```javascript
// Get farm details
const farmDetails = await callReadOnlyFunction({
    contractAddress,
    contractName: 'solar-farm-investment',
    functionName: 'get-farm-details',
    functionArgs: [uintCV(farmId)]
});

// Get user portfolio
const portfolio = await callReadOnlyFunction({
    contractAddress,
    contractName: 'solar-farm-investment',
    functionName: 'get-user-portfolio',
    functionArgs: [principalCV(userAddress)]
});
```

### API Endpoints
Recommended API structure for dApp integration:
- `GET /farms` - List all solar farms
- `GET /farms/:id` - Get specific farm details
- `GET /users/:address/portfolio` - User investment portfolio
- `GET /farms/:id/investors` - Farm investor list
- `POST /farms` - Create new farm (developer only)

## Governance and Upgrades

### Current Limitations
- Single investment per user per farm
- Manual return distribution process
- Fixed project duration model

### Future Enhancements
- Multiple investments per farm per user
- Automated return distribution via oracles
- Variable return periods
- Secondary market trading
- Governance token integration

## Risk Considerations

### Technical Risks
- Smart contract bugs or vulnerabilities
- Stacks blockchain operational risks
- Oracle dependency for return calculations

### Financial Risks
- Solar farm project performance variability
- STX price volatility affecting returns
- Platform fee changes impacting returns

### Regulatory Risks
- Changes in renewable energy regulations
- Securities law compliance requirements
- Cross-border investment restrictions

## Support and Documentation

### Resources
- Contract source code: Available in this repository
- Test cases: `/tests` directory
- Integration examples: `/examples` directory
- API documentation: `/docs/api.md`

### Community
- GitHub Issues: Bug reports and feature requests
- Discord: Community discussions and support
- Documentation: Comprehensive guides and tutorials

## License

This project is licensed under the MIT License. See LICENSE file for details.

## Contributing

Contributions welcome! Please read CONTRIBUTING.md for guidelines on:
- Code style and standards
- Testing requirements
- Pull request process
- Security disclosure procedures

---

**Disclaimer**: This smart contract is for educational and development purposes. Conduct thorough testing and security audits before mainnet deployment. Cryptocurrency investments carry inherent risks.