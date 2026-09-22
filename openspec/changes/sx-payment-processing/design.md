# Payment Processing - Design Document

## Overview

The payment processing system manages credit card information through the CreditCardEJB entity bean. Credit cards are CMP 2.x entities persisted with PurchaseOrder entities, capturing card number, type, and expiry date. Credit cards are created as part of order placement and are cascade-deleted when orders are removed.

## Architecture

### CreditCard Entity (CMP 2.x)

**Primary Fields:**

- cardNumber (String): Credit card number; stored as-is
- cardType (String): Card type (Java Card, Duke Express, Meow Card, etc.)
- expiryDate (String): Expiry date in MM/YYYY format (slash-separated)

**Methods:**

- getCardNumber(), setCardNumber()
- getCardType(), setCardType()
- getExpiryDate(), setExpiryDate()
- getExpiryMonth(): Extracts month from expiryDate; defaults to "01" if null or no slash
- getExpiryYear(): Extracts year from expiryDate; defaults to "2010" if null or no slash
- getData(): Returns CreditCard value object with all three fields copied

**Creation Methods:**

- create(): Creates empty card
- create(String cardNumber, String cardType, String expiryDate): Creates with all fields
- create(CreditCard creditCard): Creates from value object

### CreditCard Value Object

Simple data container with three fields:

- cardNumber (String)
- cardType (String)
- expiryDate (String)

Used for data transfer between entity and callers.

### Credit Card Information Input Form

Located in create_customer.jsp (lines 127-175):

- Card Number: Text input, maxlength 30 characters, placeholder "0100-001-0001"
- Card Type: Dropdown select, options: "Java(TM) Card", "Duke Express", "Meow Club"
- Expiry Date: Two separate dropdowns
  - Month: Options 01-12
  - Year: Options 2001-2004

### PurchaseOrder and CreditCard Relationship

- One-to-one unidirectional container-managed relationship
- PurchaseOrder has one CreditCard via CMR field (setCreditCard(), getCreditCard())
- Cascade-delete: Removal of PurchaseOrder automatically deletes associated CreditCard
- Created during PurchaseOrderEJB.ejbPostCreate() via CreditCardLocalHome.create()

### Transaction Model

**Container-Managed Transactions:**

- All CreditCardEJB methods: Required transaction attribute
- All creation methods (ejbCreate): Required
- All accessor methods (getters/setters): Required

### Access Control

- All CreditCardEJB methods: <unchecked/> permission
- No role-based authorization
- Available to any caller without restrictions

## Expiry Date Parsing

**Format:** MM/YYYY (slash-separated)

**Parsing Logic:**

- getExpiryMonth(): Substring before "/" or defaults to "01"
- getExpiryYear(): Substring after "/" or defaults to "2010"
- No format validation performed

**Default Values:**

- Month: "01" (January)
- Year: "2010" (legacy default, appears to be outdated)

## Error Handling

No explicit validation documented for:

- Card number format or length (accepted as-is up to 30 characters)
- Card type enumeration enforcement
- Expiry date format
- Card number validation (Luhn algorithm, etc.)

## User Interface

The credit card form displays:

- Text input for card number (30-char limit, default "0100-001-0001")
- Dropdown for card type (three options)
- Two dropdowns for expiry month and year
- No client-side validation visible
- No server-side validation visible

## Legacy Implementation Notes

- EJB 2.x container-managed persistence (CMP)
- ServiceLocator pattern for JNDI lookups
- Value object pattern for data transfer
- Hardcoded expiry year default "2010" suggests legacy code
- Primary key class declared as java.lang.Object (container auto-generates)
- Year dropdown in form limited to 2001-2004 (outdated range)
