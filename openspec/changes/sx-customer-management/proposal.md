# Customer Management - Specification Proposal

## Summary

This specification extracts the customer management capability from the legacy Java Pet Store application into a structured OpenSpec format. The capability provides a hierarchical EJB entity model for managing customers, accounts, profiles, contact information, and addresses with automatic cascade-delete semantics.

## Problem Statement

The legacy customer management system uses container-managed EJB entities with complex interdependencies and automatic creation workflows. The relationships, cascade-delete behavior, and initialization patterns are declared across multiple configuration files and EJB lifecycle methods. This specification captures these contracts so the capability can be reliably rebuilt.

## Solution Overview

Customer management consists of five primary entities arranged in a hierarchy:

- **Customer**: Root entity with unique userId
- **Account**: Per-customer account with status and related payment/contact entities
- **Profile**: Per-customer preferences (language, favorite category, UI preferences)
- **ContactInfo**: Account contact information (name, email, phone)
- **Address**: Contact address with two street lines plus city/state/zip/country

All relationships support cascade-delete, and dependent entities are automatically created when parents are created.

## Key Behavioral Requirements

### Automatic Entity Relationships

- Customer creation automatically creates one Account (status="active") and one Profile (with defaults)
- Account creation can use two variants: status-only (creates empty ContactInfo/CreditCard), or with entity references
- All relationships are one-to-one with cascade-delete

### Entity State

- Account status: "active" or "disabled"
- Profile defaults: preferredLanguage="en_US", favoriteCategory=null, myListPreference=true, bannerPreference=true
- ContactInfo: givenName, familyName, email, telephone
- Address: streetName1, streetName2, city, state, zipCode, country

### Query Support

- findAllCustomers returns all customers in database creation order

### Integration

- Account references CreditCard for payment processing
- All entities execute in Required transaction context
- No role-based access control (all methods unchecked)

## Implementation Scope

Includes:

- ✓ Customer entity with automatic Account/Profile creation
- ✓ Account entity with two creation variants
- ✓ Profile entity with default preferences
- ✓ ContactInfo and Address entities with cascade-delete
- ✓ CreditCard integration via Account relationship
- ✓ EJB-QL findAllCustomers query
- ✓ Transaction boundaries (Required)
- ✓ Unrestricted access control

Excludes:

- Address entity validation (formats, country codes)
- Email/phone format validation
- Category enumeration or validation
- Customer update/delete workflows
- Preference modification workflows

## Implementation Considerations

### Data Validation

- Email and telephone fields have no format validation in legacy
- Address street fields purpose (apartment number vs. alternate line) undocumented
- favoriteCategory allows null but no validation on valid category values

### Empty Entity Handling

- Default Account creation creates empty ContactInfo and CreditCard
- Unclear if empty entities represent valid state or must be populated

### Transaction Semantics

- Container manages transactions for all entity methods
- Cascade-delete operations participate in parent transaction
- Failed entity creation triggers rollback (via CreateException)

## Success Criteria

Implementation is successful when:

1. Customer entity supports userId as primary key with Account/Profile relationships
2. Account entity supports two creation variants with automatic ContactInfo/CreditCard
3. Profile entity initialized with documented default values
4. ContactInfo and Address entities created with cascade-delete
5. CreditCard integration via Account relationship works
6. findAllCustomers query returns all customers
7. All entity methods execute in Required transaction
8. No role-based access control restrictions apply
9. All relationships maintain cascade-delete semantics
10. All test scenarios in spec.md pass
