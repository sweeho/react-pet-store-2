# Customer Management - Design Document

## Overview

The customer management system maintains customer profiles, account information, contact details, and addresses using a hierarchical EJB entity model. The system automatically creates related entities when a customer or account is created, with cascade-delete ensuring data consistency when parent entities are removed.

## Data Model

### Entity Hierarchy

```
Customer (userId: String)
├── Account (status: String)
│   ├── ContactInfo (givenName, familyName, email, telephone)
│   │   └── Address (streetName1, streetName2, city, state, zipCode, country)
│   └── CreditCard (external integration)
└── Profile (preferredLanguage, favoriteCategory, myListPreference, bannerPreference)
```

### Key Entities

**Customer Entity** (CMP 2.x)

- Primary Key: userId (String)
- Relationships: Account (1:1), Profile (1:1)
- Cascade-delete on both relationships

**Account Entity** (CMP 2.x)

- CMP Field: status (String, values: "active", "disabled")
- Relationships: ContactInfo (1:1), CreditCard (1:1)
- Two creation variants: with/without entity references

**Profile Entity** (CMP 2.x)

- CMP Fields: preferredLanguage (String), favoriteCategory (String), myListPreference (boolean), bannerPreference (boolean)
- Defaults: "en_US", null, true, true
- Relationship: Customer (1:1, cascade-delete)

**ContactInfo Entity** (CMP 2.x)

- CMP Fields: givenName, familyName, email, telephone (all String)
- Relationship: Address (1:1, cascade-delete)

**Address Entity** (CMP 2.x)

- CMP Fields: streetName1, streetName2, city, state, zipCode, country (all String)
- Two-line street format (streetName1, streetName2)

## Design Patterns

### Automatic Entity Creation

When a Customer is created, ejbPostCreate automatically creates Account and Profile. When an Account is created with only status parameter, ejbPostCreate creates empty ContactInfo and CreditCard via JNDI lookups.

### JNDI Configuration

All entity references use ejb-local-ref entries in deployment descriptor:

- Customer references Account, Profile
- Account references ContactInfo, CreditCard
- ContactInfo references Address

### Cascade-Delete Semantics

All relationships declare cascade-delete, ensuring:

- Deleting Customer deletes Account and Profile
- Deleting Account deletes ContactInfo and CreditCard
- Deleting ContactInfo deletes Address

### Transaction Boundaries

All entity bean methods execute in Required transaction context (container-managed), ensuring ACID properties for entity creation, updates, and deletions.

## Integration Points

### Payment System Integration

Account maintains a reference to CreditCard entity, enabling:

- Association of customer accounts with payment instruments
- Cascade deletion when accounts are removed
- Order processing access to payment details

### EJB-QL Query

findAllCustomers query returns all customers in database creation order, enabling:

- Customer listings
- Administrative queries
- Data export operations

## Security Model

All customer entity methods are declared as "unchecked", meaning:

- No role-based access control on entity methods
- Any authenticated user can invoke customer methods
- System expects access control at application layer if needed

## Legacy Implementation Notes

- Uses CMP 2.x (Container-Managed Persistence) with EJB-QL queries
- JNDI lookups in ejbPostCreate methods for dependent entity creation
- No validation on email format or telephone number format
- favoriteCategory default is null (nullable field, no default value)
- streetName2 purpose (apt/suite vs. alternate line) not documented
- Empty ContactInfo and CreditCard entities created by default (no required fields)
