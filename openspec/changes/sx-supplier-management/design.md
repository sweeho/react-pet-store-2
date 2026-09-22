# Supplier Management - Design Document

## Overview

The supplier management system manages inventory and fulfills purchase orders from the order processing center. Suppliers receive purchase orders via JMS messages, check inventory availability, reduce inventory quantities when items can be shipped, create invoices, and send them back via JMS. Administrators can manually update inventory quantities via a web portal, which triggers fulfillment of pending orders.

## Architecture

### Components

#### Authentication & Authorization

- Form-based login via j_security_check servlet
- Role-based access control: administrator role required for inventory operations
- Session timeout: 54 minutes

#### Inventory Management

- **InventoryEJB**: CMP entity bean with itemId (primary key, String) and quantity (int)
- **InventoryLocalHome**: findAllInventoryItems(), findByPrimaryKey() finder methods
- **reduceQuantity()**: Atomic inventory reduction method

#### Purchase Order Processing

- **SupplierOrderMDB**: Message-driven bean receiving PO XML from JMS queue
- **SupplierOrder Entity**: CMP entity storing PO data including status (PENDING, COMPLETED)
- **OrderFulfillmentFacadeEJB**: Session bean handling fulfillment logic
  - processPO(String poXmlDoc): Main entry point for MDB, converts XML to entity
  - processAnOrder(SupplierOrderLocal): Processes line items, checks inventory, creates invoices
  - processPendingPO(): Finds and reprocesses all PENDING orders
  - checkInventory(LineItemLocal): Checks and reduces inventory
  - createInvoice(): Creates invoice XML for shipped items

#### Order Receipt Portal

- **RcvrRequestProcessor**: Servlet handling inventory updates and order receipt
- **DisplayInventoryBean**: JSP backing bean for inventory display
- **displayinventory.jsp**: Web form for inventory updates with checkboxes and quantity fields

#### Invoice Integration

- **SupplierOrderTD** (TransitionDelegate): Publishes invoices to JMS Topic
- **TopicSender**: Creates JMS TopicConnection, publishes TextMessage with invoice XML
- Destination: INVOICE_MDB_TOPIC

### Workflows

#### Purchase Order Reception and Fulfillment

1. SupplierOrderMDB receives TextMessage with PO XML
2. Calls OrderFulfillmentFacadeEJB.processPO(xmlText)
3. XML converted to SupplierOrder via TPASupplierOrderXDE
4. SupplierOrder entity persisted (status: PENDING)
5. processAnOrder() iterates line items:
   - Checks inventory via checkInventory()
   - If sufficient: reduces inventory, marks item shipped
   - If insufficient: sets allItemsAvailable=false, continues
6. If allItemsAvailable=true: sets order status to COMPLETED
7. If invoiceRequired: creates invoice XML
8. SupplierOrderTD.doTransition() publishes invoice to JMS Topic

#### Inventory Update and Pending Order Reprocessing

1. Administrator accesses displayinventory.jsp
2. Displays all inventory items via findAllInventoryItems()
3. Administrator updates quantities and checks checkboxes
4. Submits form to RcvrRequestProcessor with currentScreen=updateinventory
5. updateInventory() parses form parameters:
   - Looks for "item\_<itemId>" checkbox
   - Gets "qty\_<itemId>" quantity value
   - Validates quantity >= 0
   - Calls setQuantity() on InventoryEJB
6. processPendingPO() called after inventory updates:
   - Finds all orders with status PENDING
   - Calls processAnOrder() on each
   - Collects generated invoices
7. sendInvoices() publishes each invoice to JMS Topic
8. Transaction commits atomically

### Data Model

#### InventoryEJB

- itemId (String, PK)
- quantity (int)
- Methods: getItemId(), getQuantity(), setQuantity(), reduceQuantity(int)

#### SupplierOrderLocal

- poId (String, PK)
- poStatus (String): PENDING, COMPLETED
- lineItems (Collection of LineItemLocal)
- Methods: getPoStatus(), setPoStatus(), getLineItems()

#### LineItemLocal

- quantity (int): ordered quantity
- quantityShipped (int): shipped quantity
- itemId (String): reference to inventory item
- Methods: getQuantity(), setQuantity(), getQuantityShipped(), setQuantityShipped(), getItemId()

### Error Handling

- CatalogException: Caught in checkInventory(), returns false
- FinderException: Caught in checkInventory() when item not found, returns false
- XMLDocumentException: Caught in processPO(), null invoice returned
- NumberFormatException: Caught in RcvrRequestProcessor quantity parsing, update skipped

### Integration Points

- **Inbound**: JMS Queue for PO reception (SupplierOrderMDB listener)
- **Outbound**: JMS Topic for invoice publication (INVOICE_MDB_TOPIC)
- **Authentication**: Servlet container form-based login
- **Service Locator**: JNDI lookups for EJB homes and JMS resources

## Transaction Model

- **Required transactions**: All EJB methods (processPO, processAnOrder, checkInventory, etc.)
- **User transaction**: RcvrRequestProcessor.doPost() wraps inventory update and order processing in UserTransaction.begin()/commit()
- Atomicity: Inventory reduction and line item shipment within single transaction
- Rollback: On exception, entire transaction rolled back

## User Interface

**displayinventory.jsp** displays:

- Table with columns: Item ID, Existing Quantity, New Quantity input, Update checkbox
- Form method: POST to RcvrRequestProcessor
- Hidden field: currentScreen=updateinventory
- Authorization: Only displayed if user has administrator role

## Legacy Implementation Notes

- EJB 2.x entity beans with CMP
- Stateless session bean facade pattern
- Message-driven bean for asynchronous order processing
- JNDI-based resource lookup
- XML serialization for order and invoice data
- JMS Topic/Queue for inter-system communication
- Form-based servlet authentication
