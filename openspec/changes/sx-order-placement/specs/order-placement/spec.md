## ADDED Requirements

### Requirement: Order placement workflow

The system SHALL support a two-step order placement process: (1) collection of order details (billing address, shipping address, credit card, order items from shopping cart), and (2) creation of a persistent PurchaseOrder entity with unique order ID, current timestamp, line items from cart, and calculated total price.

#### Scenario: Customer submits order with cart items

- **GIVEN** a user with items in shopping cart (each with unit cost and quantity)
- **WHEN** the user submits an order with billing address, shipping address, and credit card
- **THEN** a PurchaseOrder entity is created with unique order ID, current timestamp, user ID, email, and line items calculated from cart

#### Scenario: Order with empty cart is rejected

- **GIVEN** a user with an empty shopping cart
- **WHEN** the user attempts to submit an order
- **THEN** a ShoppingCartEmptyOrderException is thrown and no PurchaseOrder is created

### Requirement: Order completion screen display

After successful order placement, the system SHALL display an "order completed" screen confirming the order ID and customer email address.

#### Scenario: Order completed screen shows order details

- **GIVEN** a successfully created order
- **WHEN** the order processing completes
- **THEN** an order_complete.screen is displayed with the order ID and customer email

### Requirement: PurchaseOrder entity structure

The system SHALL model orders as PurchaseOrder entities persisting: order ID (unique, primary key), user ID, customer email, order date (as timestamp in milliseconds), customer locale (with default "en_US"), and total price.

#### Scenario: PurchaseOrder stores all required fields

- **GIVEN** order creation workflow
- **WHEN** a PurchaseOrder entity is created
- **THEN** all fields (poId, poUserId, poEmailId, poDate, poLocale, poValue) are persisted

### Requirement: Line item structure and creation

For each item in the shopping cart, the system SHALL create a LineItem entity capturing: category identifier, product identifier, item identifier, sequential line number (starting from 0), ordered quantity, unit price, and initialize shipped quantity to zero.

#### Scenario: Cart items are converted to line items

- **GIVEN** a shopping cart with 3 items
- **WHEN** order placement occurs
- **THEN** 3 LineItem entities are created with sequential line numbers (0, 1, 2) and shipped quantity initialized to 0

### Requirement: Order total price calculation

The system SHALL calculate order total price as the sum of (unit cost × quantity) for each line item in the cart.

#### Scenario: Total price is calculated from cart items

- **GIVEN** a cart with items: (unit cost=10.00, qty=2), (unit cost=5.00, qty=3)
- **WHEN** the order is created
- **THEN** total price is calculated as (10.00×2) + (5.00×3) = 35.00

### Requirement: Unique order ID generation

The system SHALL generate unique order IDs using the UniqueIdGenerator EJB with seed value "1001".

#### Scenario: Order receives unique ID on creation

- **GIVEN** order creation workflow
- **WHEN** uidgen.getUniqueId("1001") is invoked
- **THEN** a unique order ID string is generated and assigned

### Requirement: Shopping cart clearance after order

After successful order placement, the system SHALL clear the shopping cart to remove all items for the session.

#### Scenario: Cart is emptied after successful order

- **GIVEN** a successful order has been created
- **WHEN** order processing completes
- **THEN** cart.empty() is invoked and all items are removed from the session

### Requirement: Order async transmission

After order creation, the system SHALL transmit the order asynchronously by converting the PurchaseOrder to XML and submitting to the AsyncSender component.

#### Scenario: Order is sent via async message

- **GIVEN** a successfully created PurchaseOrder entity
- **WHEN** order processing completes
- **THEN** purchaseOrder.toXML() is called and the XML is sent via AsyncSenderLocal.sendAMessage()

### Requirement: PurchaseOrder XML validation

When PurchaseOrder is serialized to or deserialized from XML, the system SHALL validate against the PurchaseOrder DTD schema. The DTD enforces that a PurchaseOrder contains exactly one each of: OrderId, UserId, EmailId, OrderDate (yyyy-MM-dd format), ShippingInfo, BillingInfo, TotalPrice, CreditCard, and one-or-more LineItem elements. The locale attribute defaults to "en_US".

#### Scenario: Valid PurchaseOrder XML is deserialized

- **GIVEN** a valid XML document with required elements in correct order
- **WHEN** PurchaseOrder.fromXML() is called with VALIDATING=true
- **THEN** the XML is parsed and a PurchaseOrder object is created

#### Scenario: Invalid PurchaseOrder XML is rejected

- **GIVEN** an XML document missing a required element (e.g., no CreditCard)
- **WHEN** PurchaseOrder.fromXML() is called
- **THEN** an XMLDocumentException is thrown

### Requirement: ContactInfo entity for billing and shipping

ContactInfo entities SHALL persist contact details: given name, family name, email address, and telephone number. A ContactInfo entity MAY have an associated Address entity containing postal address (street names, city, state, country, ZIP code). ContactInfo is reused for both shipping and billing within a PurchaseOrder.

#### Scenario: ContactInfo is created for shipping and billing

- **GIVEN** an order with shipping and billing addresses
- **WHEN** the PurchaseOrder is created
- **THEN** two ContactInfo entities are created (one for shipping, one for billing)

### Requirement: CreditCard entity persistence

A CreditCard entity associated with a PurchaseOrder SHALL contain: card number, card type, and expiry date. The CreditCard is created and stored as part of order creation and cascade-deleted if the PurchaseOrder is removed.

#### Scenario: CreditCard is persisted with order

- **GIVEN** an order creation with credit card details
- **WHEN** PurchaseOrder is created
- **THEN** a CreditCard entity is created with cardNumber, cardType, expiryDate

### Requirement: PurchaseOrder entity relationships

A PurchaseOrder entity SHALL maintain exactly one container-managed relationship to a ContactInfo entity (shipping/billing address), exactly one relationship to a CreditCard entity, and a one-to-many relationship to LineItem entities (minimum one required). All relationships are unidirectional from PurchaseOrder. Removal of a PurchaseOrder SHALL cascade-delete all related entities.

#### Scenario: PurchaseOrder cascades deletes to related entities

- **GIVEN** a PurchaseOrder with associated ContactInfo, CreditCard, and LineItems
- **WHEN** the PurchaseOrder is removed
- **THEN** all related ContactInfo, CreditCard, and LineItem entities are cascade-deleted

### Requirement: Two-phase order creation lifecycle

When creating a PurchaseOrder, the system SHALL execute a two-phase workflow: (1) ejbCreate phase sets all CMP fields from the PurchaseOrder value object, and (2) ejbPostCreate atomically creates related entities (ContactInfo, CreditCard, LineItems) and establishes relationships. This workflow MUST occur within a single Required transaction; any failure SHALL rollback the entire transaction.

#### Scenario: Order creation is atomic across all entities

- **GIVEN** an order creation with billing/shipping info, credit card, and cart items
- **WHEN** PurchaseOrderEJB.create(purchaseOrder) is invoked
- **THEN** both ejbCreate and ejbPostCreate execute within one transaction; all related entities are created atomically or all changes are rolled back

### Requirement: Transaction management for order operations

All PurchaseOrder and related entity methods (getters, setters, finders, creation, removal) SHALL execute with EJB transaction attribute "Required", meaning the container SHALL join an existing transaction or create a new one if none exists.

#### Scenario: All order operations execute in transactions

- **GIVEN** any order workflow operation
- **WHEN** a getter, setter, finder, or lifecycle method is invoked
- **THEN** the EJB container ensures execution within a Required transaction context

### Requirement: Unrestricted access to order entities

All PurchaseOrder and related entity methods (ContactInfo, Address, CreditCard, LineItem) SHALL be accessible without role-based access control restrictions. All methods have <unchecked/> permission.

#### Scenario: Anyone can access order entities

- **GIVEN** any caller
- **WHEN** PurchaseOrder methods are invoked
- **THEN** no authorization checks prevent access; all methods are available to any caller

### Requirement: Date-range query for orders

The PurchaseOrder entity SHALL support a finder method findPOBetweenDates(long startDate, long endDate) returning a Collection of PurchaseOrder entities whose order date falls within the specified date range (inclusive).

#### Scenario: Orders are queried by date range

- **GIVEN** purchase orders with creation dates: 2026-01-01, 2026-03-15, 2026-06-30
- **WHEN** findPOBetweenDates(2026-02-01, 2026-05-31) is called
- **THEN** the order from 2026-03-15 is returned; 2026-01-01 and 2026-06-30 are excluded
