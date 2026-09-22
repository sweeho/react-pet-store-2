## ADDED Requirements

### Requirement: Credit card entity structure

The system SHALL persist credit card information as an entity with three attributes: card number (stored as String), card type (stored as String), and expiry date (stored as String in slash-separated format MM/YYYY).

#### Scenario: Credit card data is persisted

- **GIVEN** a credit card with number "0100-001-0001", type "Duke Express", expiry "12/2025"
- **WHEN** the credit card entity is created via CreditCardEJB
- **THEN** all three attributes are stored and retrievable via getData()

### Requirement: Credit card creation

The system SHALL support three methods of creating a credit card entity: (1) with no parameters (empty card), (2) with three parameters (cardNumber, cardType, expiryDate), and (3) with a CreditCard value object.

#### Scenario: Credit card is created with all parameters

- **GIVEN** card parameters: number "0100-001-0001", type "Duke Express", expiry "12/2025"
- **WHEN** CreditCardLocalHome.create(cardNumber, cardType, expiryDate) is called
- **THEN** a CreditCard entity is created with all three fields populated

#### Scenario: Credit card is created from value object

- **GIVEN** a CreditCard value object with all fields set
- **WHEN** CreditCardLocalHome.create(creditCardObject) is called
- **THEN** the entity is created with fields copied from the object

### Requirement: Expiry date parsing

The system SHALL parse the expiryDate field (slash-separated MM/YYYY) to extract month and year components. When expiryDate is null or contains no slash, getExpiryMonth() SHALL return "01" and getExpiryYear() SHALL return "2010".

#### Scenario: Expiry date is parsed correctly

- **GIVEN** expiryDate "12/2025"
- **WHEN** getExpiryMonth() and getExpiryYear() are called
- **THEN** getExpiryMonth() returns "12" and getExpiryYear() returns "2025"

#### Scenario: Null expiry date uses defaults

- **GIVEN** expiryDate is null
- **WHEN** getExpiryMonth() and getExpiryYear() are called
- **THEN** getExpiryMonth() returns "01" and getExpiryYear() returns "2010"

### Requirement: Credit card data retrieval

The system SHALL provide a getData() method that retrieves all credit card attributes (cardNumber, cardType, expiryDate) and returns them as a CreditCard value object.

#### Scenario: All card data is retrieved

- **GIVEN** a CreditCard entity with stored data
- **WHEN** getData() is called
- **THEN** a CreditCard value object is returned with cardNumber, cardType, and expiryDate populated

### Requirement: Credit card accessors

The system SHALL provide getter and setter methods for cardNumber, cardType, and expiryDate attributes. All accessor operations SHALL be transactional with Required transaction attribute.

#### Scenario: Card properties are readable and writable

- **GIVEN** a CreditCard entity
- **WHEN** setCardNumber(), setCardType(), setExpiryDate() are called to update values
- **THEN** the values are persisted and getCardNumber(), getCardType(), getExpiryDate() return the updated values

### Requirement: Credit card authorization

The system SHALL grant unrestricted access to all CreditCardEJB methods. All methods are marked with unchecked security permission.

#### Scenario: Anyone can access credit card methods

- **GIVEN** any caller
- **WHEN** CreditCard methods are invoked
- **THEN** no authorization checks prevent access; all methods are available without role-based restrictions

### Requirement: Credit card information input form

The system SHALL present a credit card information input form containing: cardNumber (text input accepting up to 30 characters), cardType (dropdown selection from enumerated values), and expiryDate (separate month dropdown [01-12] and year dropdown).

#### Scenario: Credit card form displays input controls

- **GIVEN** a customer creation form
- **WHEN** the credit card section is rendered
- **THEN** the form shows: a cardNumber text field (maxlength 30), a cardType dropdown with options (Java Card, Duke Express, Meow Card), and separate month (01-12) and year (2001-2004) dropdowns for expiry

### Requirement: Purchase order and credit card association

The system SHALL establish a one-to-one container-managed relationship between a PurchaseOrder and a CreditCard. When a PurchaseOrder is created, a CreditCard entity SHALL be created and associated with it via the setCreditCard() method. If the PurchaseOrder is removed, the associated CreditCard SHALL be cascade-deleted.

#### Scenario: Credit card is created and associated with order

- **GIVEN** a PurchaseOrder creation with credit card details
- **WHEN** the order is created via PurchaseOrderEJB.create()
- **THEN** a CreditCard entity is created and associated via setCreditCard()

#### Scenario: Credit card is deleted when order is removed

- **GIVEN** a PurchaseOrder with an associated CreditCard
- **WHEN** the PurchaseOrder is deleted
- **THEN** the associated CreditCard is cascade-deleted
