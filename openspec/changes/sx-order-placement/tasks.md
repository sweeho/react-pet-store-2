## 1. PurchaseOrder Entity Implementation

- [ ] 1.1 Implement PurchaseOrderEJB as a CMP 2.x entity bean with abstract accessors for poId, poUserId, poEmailId, poDate, poLocale, poValue
- [ ] 1.2 Declare PurchaseOrderEJB in ejb-jar.xml with persistence-type Container and CMP version 2.x
- [ ] 1.3 Define poId as primkey-field with prim-key-class java.lang.String
- [ ] 1.4 Implement ejbCreate(PurchaseOrder purchaseOrder) to set all CMP fields from value object
- [ ] 1.5 Implement ejbPostCreate to create ContactInfo, CreditCard, and LineItem entities via local homes
- [ ] 1.6 Implement CMR setContactInfo(), setCreditCard() methods for relationship navigation
- [ ] 1.7 Implement abstract getLineItems() returning java.util.Collection

## 2. LineItem Entity Implementation

- [ ] 2.1 Implement LineItemEJB as a CMP 2.x entity bean with abstract accessors for all seven fields
- [ ] 2.2 Declare LineItemEJB in ejb-jar.xml with CMP fields: categoryId, productId, itemId, lineNumber, quantity, unitPrice, quantityShipped
- [ ] 2.3 Define primkey-field as a composite key or auto-generated ID
- [ ] 2.4 Implement ejbCreate(LineItem lineItem, int qtyShipped) to initialize quantityShipped

## 3. ContactInfo and Address Entity Implementation

- [ ] 3.1 Implement ContactInfoEJB as CMP entity with fields: givenName, familyName, email, telephone
- [ ] 3.2 Implement AddressEJB as CMP entity with six address fields (streetName1, streetName2, city, state, zipCode, country)
- [ ] 3.3 Declare ContactInfo-Address relationship in ejb-jar.xml with cascade-delete
- [ ] 3.4 Implement ejbCreate methods for both entities

## 4. CreditCard Entity Implementation

- [ ] 4.1 Implement CreditCardEJB as CMP entity with fields: cardNumber, cardType, expiryDate
- [ ] 4.2 Declare CreditCardEJB in ejb-jar.xml with appropriate CMP fields

## 5. PurchaseOrder Relationships

- [ ] 5.1 Declare PurchaseOrder-ContactInfo relationship in ejb-jar.xml (one-to-one, unidirectional, cascade-delete)
- [ ] 5.2 Declare PurchaseOrder-CreditCard relationship in ejb-jar.xml (one-to-one, unidirectional, cascade-delete)
- [ ] 5.3 Declare PurchaseOrder-LineItem relationship in ejb-jar.xml (one-to-many, unidirectional, cascade-delete, minimum one)

## 6. Order Placement Workflow

- [ ] 6.1 Implement OrderEJBAction as stateful session bean action for order.do mapping
- [ ] 6.2 Implement perform() method to retrieve shopping cart and cart items
- [ ] 6.3 Implement unique ID generation via UniqueIdGenerator.getUniqueId("1001")
- [ ] 6.4 Implement user ID retrieval via ShoppingClientFacade.getUserId()
- [ ] 6.5 Implement cart-to-lineitem conversion: iterate cart.getItems() and create LineItem objects
- [ ] 6.6 Implement order total calculation: SUM(unitPrice × quantity) for each cart item
- [ ] 6.7 Implement PurchaseOrderEJB.create(purchaseOrder) invocation
- [ ] 6.8 Implement shopping cart clearance via cart.empty()
- [ ] 6.9 Implement OrderEventResponse creation with email and order ID

## 7. Order Validation

- [ ] 7.1 Implement validation: throw ShoppingCartEmptyOrderException if cart.getItems().size() == 0
- [ ] 7.2 Implement exception mapping in mappings.xml: route to cart_empty_order_error.screen
- [ ] 7.3 Implement validation for required fields: billing address, shipping address, credit card

## 8. Asynchronous Order Transmission

- [ ] 8.1 Implement AsyncSender invocation via ServiceLocator lookup of AsyncSenderLocalHome
- [ ] 8.2 Implement AsyncSender.create() and sender.sendAMessage(purchaseOrder.toXML())
- [ ] 8.3 Implement error handling for ServiceLocatorException, XMLDocumentException, CreateException
- [ ] 8.4 Implement PurchaseOrder.toXML() serialization

## 9. XML Serialization and DTD Validation

- [ ] 9.1 Implement PurchaseOrder.fromXML(xmlString) with VALIDATING=true
- [ ] 9.2 Implement PurchaseOrder.toXML() serialization
- [ ] 9.3 Create PurchaseOrder.dtd schema defining element cardinality and attributes
- [ ] 9.4 Define DTD_PUBLIC_ID and DTD_SYSTEM_ID constants in PurchaseOrder.java
- [ ] 9.5 Implement LineItem XML serialization/deserialization
- [ ] 9.6 Implement ContactInfo XML serialization/deserialization
- [ ] 9.7 Implement CreditCard XML serialization/deserialization

## 10. Order Completion Screen

- [ ] 10.1 Implement mappings.xml url-mapping for order.do to order_complete.screen
- [ ] 10.2 Implement OrderHTMLAction to handle order.do request
- [ ] 10.3 Implement order_complete.screen JSP to display order ID and customer email

## 11. Finder Methods and Queries

- [ ] 11.1 Declare PurchaseOrderLocalHome.findPOBetweenDates(long startDate, long endDate) method
- [ ] 11.2 Implement EJB-QL query: SELECT OBJECT(a) From PurchaseOrder a WHERE a.poDate BETWEEN ?1 AND ?2
- [ ] 11.3 Declare query in ejb-jar.xml with correct parameter types

## 12. Transaction and Access Control Configuration

- [ ] 12.1 Declare container-transaction Required for all PurchaseOrderEJB methods in ejb-jar.xml
- [ ] 12.2 Declare container-transaction Required for all LineItemEJB methods
- [ ] 12.3 Declare container-transaction Required for all ContactInfoEJB methods
- [ ] 12.4 Declare container-transaction Required for all AddressEJB methods
- [ ] 12.5 Declare container-transaction Required for all CreditCardEJB methods
- [ ] 12.6 Declare method-permission unchecked for all PurchaseOrderEJB methods
- [ ] 12.7 Declare method-permission unchecked for LineItem, ContactInfo, Address, CreditCard entities

## 13. Service Locator and JNDI

- [ ] 13.1 Implement ServiceLocator pattern for EJB home lookups
- [ ] 13.2 Configure JNDI names for PurchaseOrderEJB, LineItemEJB, ContactInfoEJB, AddressEJB, CreditCardEJB
- [ ] 13.3 Implement JNDI names for AsyncSenderLocalHome and UniqueIdGeneratorLocalHome

## 14. Testing and Validation

- [ ] 14.1 Test order creation with valid cart items and delivery addresses
- [ ] 14.2 Test empty cart validation: ShoppingCartEmptyOrderException thrown
- [ ] 14.3 Test order total price calculation correctness
- [ ] 14.4 Test unique order ID generation
- [ ] 14.5 Test cart clearance after order
- [ ] 14.6 Test async transmission: XML serialization and AsyncSender invocation
- [ ] 14.7 Test XML validation: valid PurchaseOrder deserialization
- [ ] 14.8 Test XML validation: invalid PurchaseOrder rejected with XMLDocumentException
- [ ] 14.9 Test transaction atomicity: partial entity creation does not persist
- [ ] 14.10 Test date-range finder: findPOBetweenDates returns correct orders
- [ ] 14.11 Test order completion screen displays with correct data
- [ ] 14.12 Test cascade-delete: removal of PurchaseOrder deletes related entities
