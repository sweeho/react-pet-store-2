# Order Placement - Specification Proposal

## Summary

This specification extracts the order placement capability from the legacy Java Pet Store application. The system implements the workflow for customers to create purchase orders from shopping carts, modeled as PurchaseOrder EJB entities with container-managed persistence. Order creation is a two-phase lifecycle that atomically establishes relationships with shipping/billing contacts, payment cards, and line items within a single transaction.

## Problem Statement

The legacy order placement system distributes order creation logic across action beans, entity lifecycle methods, and helper classes. The contracts governing entity creation, relationship management, price calculation, and XML serialization are implicit in code rather than explicitly stated. This specification captures the order placement workflow so the capability can be rebuilt with clear contracts and verifiable behavior.

## Solution Overview

Order placement consists of:

- **PurchaseOrder Entity**: CMP 2.x entity with order metadata, relationships to ContactInfo, CreditCard, and LineItems
- **LineItem Entity**: CMP entity capturing ordered product, quantity, unit price, and fulfillment tracking
- **ContactInfo/Address Entities**: CMP entities for shipping/billing information
- **CreditCard Entity**: CMP entity persisting payment card details
- **OrderEJBAction**: Stateful session bean action implementing order workflow (cart to entity conversion)
- **XML Serialization**: PurchaseOrder.toXML()/fromXML() with DTD validation
- **Async Transmission**: Order XML sent via AsyncSender component
- **Finder Methods**: Date-range query for administrative reporting

## Key Behavioral Requirements

### Order Workflow

Order placement is initiated by user submission with:

- Items from shopping cart (category, product, item, unit cost, quantity)
- Billing address (given name, family name, email, phone, postal address)
- Shipping address (given name, family name, email, phone, postal address)
- Credit card (card number, type, expiry date)

Result is a PurchaseOrder entity with:

- Unique order ID (generated via UniqueIdGenerator seed "1001")
- User ID and email
- Current timestamp
- Customer locale (default "en_US")
- Total price calculated as SUM(unitPrice × quantity) per cart item
- Associated ContactInfo (billing, shipping), CreditCard, and LineItem entities

### Entity Lifecycle

PurchaseOrder creation uses two-phase EJB lifecycle:

1. **ejbCreate()**: Sets all CMP fields from value object
2. **ejbPostCreate()**: Creates and relates ContactInfo, CreditCard, LineItem entities

Both phases execute atomically in a single Required transaction; any failure rolls back entire order.

### Line Item Creation

For each cart item:

- Create LineItem with categoryId, productId, itemId from cart item
- Assign sequential line number starting from 0
- Capture unit price as float from cart item
- Initialize quantityShipped to 0

### Validation

- Cart must not be empty (throws ShoppingCartEmptyOrderException)
- Order date set to current system time
- Locale defaults to "en_US" if not specified
- XML deserialization validates against DTD schema

### Async Transmission

After order creation, order is serialized to XML and sent via AsyncSender message queue for downstream fulfillment processing.

### Confirmation

Order completion screen displays with order ID and customer email address.

## Implementation Scope

Includes:

- ✓ PurchaseOrder CMP entity with order metadata
- ✓ LineItem, ContactInfo, CreditCard, Address CMP entities
- ✓ Container-managed relationships with cascade-delete semantics
- ✓ Two-phase order creation lifecycle (ejbCreate/ejbPostCreate)
- ✓ OrderEJBAction workflow (cart to entity conversion)
- ✓ Unique ID generation via UniqueIdGenerator
- ✓ Order total price calculation
- ✓ Shopping cart clearance
- ✓ XML serialization with DTD validation
- ✓ Async order transmission via AsyncSender
- ✓ Order completion screen
- ✓ Date-range finder method
- ✓ Transaction management (Required attribute on all operations)
- ✓ Access control (unchecked permission on all methods)

Excludes:

- Order modification/amendment after placement
- Order cancellation
- Partial payment or payment plan support
- Promotional codes or discount logic
- Tax calculation
- Shipping cost estimation
- Inventory checks or reservations
- Multi-currency support beyond locale
- Order versioning or audit trail

## Implementation Considerations

### Entity Persistence

PurchaseOrder and related entities use EJB 2.x container-managed persistence. All fields are persisted to database; container handles object-relational mapping and connection management.

### Transaction Model

- create() method has Required transaction attribute
- Both ejbCreate and ejbPostCreate execute in same transaction
- Any exception causes automatic rollback and no partial persistence
- All getter/setter methods also use Required transaction attribute

### Unique ID Generation

Order IDs are generated via UniqueIdGenerator EJB with fixed seed value "1001". The seed purpose (counter prefix, namespace identifier, etc.) is not documented in source code.

### Price Calculation

Total price is computed as a simple sum during cart iteration. No rounding, tax, discount, or surcharge logic is applied at this level. Unit cost is parsed as Java float; potential floating-point precision issues are not addressed in specifications.

### XML Schema

PurchaseOrder.dtd enforces element cardinality (LineItem+) and default locale attribute ("en_US"). DTD validation is strict (VALIDATING=true); malformed or non-conforming XML throws XMLDocumentException.

### Error Handling

- ShoppingCartEmptyOrderException: Caught by mappings.xml, routed to error screen
- XMLDocumentException: Caught during async transmission; error printed but order persisted
- CreateException, ServiceLocatorException: Caught; errors printed; may leave partial state if not handled carefully

### JNDI and ServiceLocator

All EJB lookups use ServiceLocator pattern. JNDI names are hardcoded via JNDINames constants. No fallback or retry logic visible in specifications.

## Success Criteria

Implementation is successful when:

1. Orders are created from shopping cart with all required fields (user ID, email, addresses, card, items)
2. Empty cart is rejected with ShoppingCartEmptyOrderException
3. Order ID is unique (generated via UniqueIdGenerator)
4. Order total price = SUM(unitPrice × quantity) for all cart items
5. LineItems are created with sequential line numbers (0, 1, 2, ...)
6. quantityShipped initialized to 0 for all line items
7. PurchaseOrder entity persists with poId, poUserId, poEmailId, poDate, poLocale, poValue
8. ContactInfo entities created for shipping and billing
9. CreditCard entity created and related to PurchaseOrder
10. LineItem entities created and related to PurchaseOrder
11. All entity relationships are cascade-delete (PO deletion removes related entities)
12. Order creation atomic: all entities created or none (transaction rollback)
13. Shopping cart cleared after order
14. Order serialized to XML and transmitted via AsyncSender
15. Order completion screen displays with order ID and email
16. XML deserialization validates against PurchaseOrder.dtd
17. Invalid XML rejected with XMLDocumentException
18. All operations execute within Required transaction context
19. All methods accessible without role-based authorization
20. Date-range finder returns correct orders matching date criteria
21. All acceptance criteria scenarios pass without behavioral regression

## Assumptions and Constraints

- Order placement is stateless from user perspective (no draft/edit/submit workflow; direct submission)
- Unit price is immutable after order creation (no price adjustments)
- Shopping cart items are converted one-to-one to line items (no grouping, bundling, or merging)
- Customer can place multiple orders (no order-per-customer limit)
- Order ID is string (not numeric); uniqueness enforced by UniqueIdGenerator
- ContactInfo is not reused across orders (fresh entity created each time)
- XML serialization uses fixed DTD (no schema versioning or compatibility logic)
- Async transmission is fire-and-forget (no retry, no acknowledgment)
- Locale is stored as string (Locale.toString() format) not as separate language/country fields
- quantityShipped is tracking field for fulfillment; not updated during order creation

## Open Questions for Business Clarification

1. Should order placement support adding new addresses (billing/shipping) or only selecting from existing customer addresses?
2. Is the unique ID seed "1001" configurable, or hardcoded?
3. Should order confirmation be sent via email immediately upon creation?
4. What should happen if AsyncSender fails to transmit the order?
5. Are orders created for credit card validation, or are payment cards assumed to be pre-validated?
6. Should orders support multiple line items for the same product (different quantities added separately)?
7. Are there business rules around minimum/maximum order totals?
