## ADDED Requirements

### Requirement: Customer entity with unique identifier

The system SHALL maintain a Customer entity with a unique userId (String) as the primary key. Each Customer record SHALL have exactly one associated Account and one associated Profile.

#### Scenario: Customer is created with userId

- **GIVEN** a new customer registration with userId "john.doe@example.com"
- **WHEN** the customer entity is created
- **THEN** an Account entity and a Profile entity are automatically created and associated with this customer

### Requirement: Account entity with status tracking

The system SHALL maintain an Account entity with a status field (String) that tracks the account state. An Account SHALL have exactly one associated ContactInfo and one associated CreditCard, each with cascade-delete semantics.

#### Scenario: Account is created with required relationships

- **GIVEN** a new account for a customer
- **WHEN** the account entity is created
- **THEN** the account has a status field and associated ContactInfo and CreditCard entities

### Requirement: Account status values

An Account SHALL support two status values: "active" and "disabled", as defined in the AccountLocalHome constants.

#### Scenario: Account is created with active status

- **GIVEN** a new account creation request
- **WHEN** the account is initialized
- **THEN** the account status is set to "active"

### Requirement: Profile entity with preference fields

The system SHALL maintain a Profile entity with four preference fields: preferredLanguage (String, default "en_US"), favoriteCategory (String, default null), myListPreference (boolean, default true), and bannerPreference (boolean, default true).

#### Scenario: Profile is created with default preferences

- **GIVEN** a new customer account creation
- **WHEN** the profile is initialized
- **THEN** preferredLanguage="en_US", favoriteCategory=null, myListPreference=true, bannerPreference=true

### Requirement: ContactInfo entity with contact fields

The system SHALL maintain a ContactInfo entity with four contact fields: givenName (String), familyName (String), email (String), and telephone (String). Each ContactInfo has exactly one associated Address and is deleted when its parent Account is deleted.

#### Scenario: ContactInfo is created for account

- **GIVEN** a new account creation
- **WHEN** the contact information entity is created
- **THEN** an empty ContactInfo is created with associated Address

### Requirement: Address entity with address fields

The system SHALL maintain an Address entity with six address fields: streetName1 (String), streetName2 (String), city (String), state (String), zipCode (String), and country (String). Each Address is deleted when its parent ContactInfo is deleted.

#### Scenario: Address is created for contact info

- **GIVEN** contact information for a customer
- **WHEN** the address entity is initialized
- **THEN** all six address fields are available for population (streetName1, streetName2, city, state, zipCode, country)

### Requirement: Two variants of Account creation

The system SHALL support two variants of Account creation: (1) creation with only a status parameter, in which case ContactInfo and CreditCard are automatically created as empty entities, and (2) creation with status, ContactInfo, and CreditCard parameters supplied as EJB references.

#### Scenario: Account is created with only status

- **GIVEN** an account creation request with only a status parameter
- **WHEN** AccountLocalHome.create(status) is called
- **THEN** an Account is created with empty ContactInfo and CreditCard entities

#### Scenario: Account is created with existing entities

- **GIVEN** existing ContactInfo and CreditCard entities
- **WHEN** AccountLocalHome.create(status, contactInfo, creditCard) is called
- **THEN** an Account is created with the provided entity references

### Requirement: Automatic Account initialization on Customer creation

When a new Customer is created, the system SHALL automatically create and associate one Account entity with status "active" and one Profile entity with default preferences.

#### Scenario: Customer creation triggers Account and Profile creation

- **GIVEN** a new customer with userId
- **WHEN** the Customer entity is created via CustomerLocalHome.create(userId)
- **THEN** an Account with status="active" and a Profile with default preferences are automatically created and associated

### Requirement: Query all customers

The system SHALL support querying for all Customer records via a findAllCustomers method on CustomerLocalHome. The method SHALL return a collection of all Customer entities ordered by their creation in the database.

#### Scenario: Retrieve all customers

- **GIVEN** multiple customers exist in the system
- **WHEN** CustomerLocalHome.findAllCustomers() is called
- **THEN** a collection of all Customer entities is returned in database creation order

### Requirement: Transaction boundaries for customer operations

All Customer, Account, Profile, ContactInfo, and Address EJB methods SHALL execute within a Required transaction context. The container SHALL create a transaction if one does not exist and join an existing transaction if one does.

#### Scenario: Customer operation executes in transaction

- **GIVEN** a call to any Customer or related entity method
- **WHEN** the method executes
- **THEN** the EJB container ensures it runs within a Required transaction

### Requirement: Unrestricted access to customer entities

All methods on Customer, Account, Profile, ContactInfo, and Address entity beans SHALL be accessible without role-based access control restrictions. Any authenticated caller (or in the absence of authentication, any caller) may invoke them.

#### Scenario: Customer entity methods are unrestricted

- **GIVEN** any caller (authenticated or not)
- **WHEN** methods are called on customer-related entities
- **THEN** no role-based access control restrictions are enforced

### Requirement: Integration with payment system via Account

The customer management system SHALL integrate with the payment-processing system through the Account entity's relationship to CreditCard. An Account entity maintains a reference to exactly one CreditCard EJB, allowing customer account records to be associated with payment instrument information.

#### Scenario: Account references CreditCard for payments

- **GIVEN** a customer account
- **WHEN** the account is used in order processing
- **THEN** the associated CreditCard entity is available for payment processing
