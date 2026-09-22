# Order Placement - Design Document

## Overview

The order placement system provides the workflow for customers to create purchase orders from their shopping cart. Orders are modeled as PurchaseOrder EJB entities with container-managed persistence, containing order metadata, billing/shipping information, credit card details, and a collection of line items. Order creation is a two-phase lifecycle (ejbCreate/ejbPostCreate) that atomically creates related entities and establishes relationships within a single transaction.

## Architecture

### Order Placement Flow

1. **Order Submission**: Web action collects billing address, shipping address, credit card, and shopping cart items
2. **Validation**: Shopping cart must not be empty
3. **Order Creation**: OrderEJBAction creates PurchaseOrder entity via PurchaseOrderEJB.create()
4. **Async Transmission**: OrderEJBAction converts order to XML and sends via AsyncSender
5. **Confirmation**: Order completion screen displays with order ID and customer email

### PurchaseOrder Entity (CMP 2.x)

**Primary Fields:**

- poId (String): Unique order identifier; generated via UniqueIdGenerator with seed "1001"
- poUserId (String): Associated user ID
- poEmailId (String): Customer email address
- poDate (long): Order creation timestamp in milliseconds
- poLocale (String): Customer locale preference; defaults to "en_US"
- poValue (float): Total order price

**Container-Managed Relationships:**

- contactInfo (ContactInfo): Shipping/billing address information; unidirectional; cascade-delete
- creditCard (CreditCard): Payment card details; unidirectional; cascade-delete
- lineItems (Collection of LineItem): Order line items; one-to-many; minimum one required; cascade-delete

### LineItem Entity (CMP 2.x)

**Fields:**

- categoryId (String): Product category identifier
- productId (String): Product identifier
- itemId (String): Item identifier
- lineNumber (String): Sequential line number (0-based)
- quantity (int): Ordered quantity
- unitPrice (float): Unit price at time of order
- quantityShipped (int): Fulfilled quantity; initialized to 0

### ContactInfo Entity (CMP 2.x)

**Fields:**

- givenName (String): First name
- familyName (String): Last name
- email (String): Email address
- telephone (String): Phone number
- address (Address entity relationship): Postal address

### CreditCard Entity (CMP 2.x)

**Fields:**

- cardNumber (String): Credit card number
- cardType (String): Card type (VISA, MASTERCARD, etc.)
- expiryDate (String): Expiry date

### Address Entity (CMP 2.x)

**Fields:**

- streetName1 (String): Primary street line
- streetName2 (String): Secondary street line
- city (String): City name
- state (String): State/province
- zipCode (String): ZIP/postal code
- country (String): Country

### Two-Phase Entity Creation

**Phase 1 (ejbCreate):**

- Receives PurchaseOrder value object
- Sets all CMP fields (poId, poUserId, poEmailId, poDate, poLocale, poValue)

**Phase 2 (ejbPostCreate):**

- Uses ServiceLocator to obtain local homes for ContactInfo, CreditCard, LineItem
- Creates ContactInfo entity from purchaseOrder.getShippingInfo()
- Creates CreditCard entity from purchaseOrder.getCreditCard()
- Iterates over purchaseOrder.getLineItems() and creates LineItem entities
- Establishes all CMR relationships via setContactInfo(), setCreditCard(), addLineItem()

**Transaction Semantics:**

- create() method has trans-attribute: Required
- Entire ejbCreate/ejbPostCreate executes within single transaction
- Any failure triggers rollback; no partial state persists

### Order Total Calculation

- Formula: SUM(unitPrice × quantity) for each line item
- unitPrice retrieved as float from CartItem
- Accumulates into totalCost variable during cart iteration
- Set on PurchaseOrder via setTotalPrice()

### XML Serialization

**DTD Schema (PurchaseOrder.dtd):**

```
<!ELEMENT PurchaseOrder (OrderId, UserId, EmailId, OrderDate, ShippingInfo, BillingInfo, TotalPrice, CreditCard, LineItem+)>
<!ATTLIST PurchaseOrder locale CDATA "en_US">
```

**Element Constraints:**

- OrderId: required, single
- UserId: required, single
- EmailId: required, single
- OrderDate: required, single; format yyyy-MM-dd
- ShippingInfo: required, single; contains ContactInfo
- BillingInfo: required, single; contains ContactInfo
- TotalPrice: required, single
- CreditCard: required, single
- LineItem: one-or-more required

**Validation:**

- VALIDATING = true constant enables DTD validation
- PurchaseOrder.fromXML() throws XMLDocumentException on validation failure
- DTD PUBLIC_ID: "-//Sun Microsystems, Inc. - J2EE Blueprints Group//DTD PurchaseOrder 1.1//EN"

### Order Processing Components

**OrderEJBAction** (stateful session bean action):

- Entry point for order.do web action
- Retrieves unique ID via UniqueIdGenerator.getUniqueId("1001")
- Gets user ID from ShoppingClientFacade
- Retrieves shopping cart items and iterates to create LineItem collection
- Calculates total cost as sum of (cost × quantity)
- Creates PurchaseOrder via PurchaseOrderEJB.create()
- Converts order to XML and sends via AsyncSenderLocal.sendAMessage()
- Returns OrderEventResponse with email and order ID
- Clears cart via cart.empty()

**OrderEventResponse**:

- Value object returned to web tier
- Carries email and orderIdString
- Routed to order_complete.screen via mappings.xml

**Finder Method - findPOBetweenDates**:

- EJB-QL: SELECT OBJECT(a) From PurchaseOrder a WHERE a.poDate BETWEEN ?1 AND ?2
- Returns Collection of PurchaseOrder entities
- Supports administrative reporting and date-range queries

## Access Control

- All PurchaseOrder methods: <unchecked/> permission
- All ContactInfo methods: <unchecked/> permission
- All Address methods: <unchecked/> permission
- All CreditCard methods: <unchecked/> permission
- All LineItem methods: <unchecked/> permission
- No role-based authorization

## Transaction Model

**Container-Managed Transactions:**

- All methods have trans-attribute: Required
- Covers: all getters/setters, create, remove, finder methods
- Enforces isolation and atomicity
- Automatic rollback on exception

## Error Handling

- **ShoppingCartEmptyOrderException**: Thrown if cart has no items; mapped to cart_empty_order_error.screen
- **XMLDocumentException**: Thrown on DTD validation failure; caught and printed in error handler
- **CreateException**: Thrown on entity creation failure; caught during async sender lookup
- **ServiceLocatorException**: Thrown on JNDI lookup failure; caught and printed

## Legacy Implementation Notes

- EJB 2.x stateless session bean (OrderEJBAction) with event dispatch pattern
- Struts action mapping via Mappings.xml
- ServiceLocator pattern for JNDI lookups
- Value objects (PurchaseOrder, LineItem, ContactInfo, CreditCard, Address) for data transfer
- XML serialization via toXML()/fromXML() methods with DTD validation
- Async order transmission via JMS (AsyncSender component)
- Container provides connection pooling for all entity creation operations
