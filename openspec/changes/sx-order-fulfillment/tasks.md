## 1. Order Manager Entity Implementation

- [ ] 1.1 Implement ManagerEJB as a CMP 2.x entity bean with abstract orderId and status fields
- [ ] 1.2 Declare ManagerEJB in ejb-jar.xml with persistence-type Container and CMP version 2.x
- [ ] 1.3 Define orderId as primkey-field with prim-key-class java.lang.String
- [ ] 1.4 Implement ejbCreate(orderId, status) method initializing both fields
- [ ] 1.5 Implement abstract getter/setter pairs for orderId and status
- [ ] 1.6 Define local home interface ManagerLocalHome with create and finder methods
- [ ] 1.7 Define local interface ManagerLocal for component access

## 2. Order Status Workflow

- [ ] 2.1 Define OrderStatusNames class with five static final String constants: PENDING, APPROVED, DENIED, SHIPPED_PART, COMPLETED
- [ ] 2.2 Document state machine transitions in OrderStatusNames javadoc
- [ ] 2.3 Implement createManager operation to initialize workflow with PENDING status
- [ ] 2.4 Implement updateStatus operation to atomically transition order status
- [ ] 2.5 Implement getStatus operation to retrieve current order status
- [ ] 2.6 Implement status transition guard logic to prevent re-processing non-PENDING orders
- [ ] 2.7 Add javadoc explaining each status constant and its meaning

## 3. Query and Reporting Operations

- [ ] 3.1 Implement findOrdersByStatus(status) CMP query in ejb-jar.xml using EJB-QL
- [ ] 3.2 Define EJB-QL query: SELECT DISTINCT OBJECT(a) FROM Manager a WHERE a.status = ?1
- [ ] 3.3 Implement getOrdersByStatus wrapper in ProcessManagerEJB session bean
- [ ] 3.4 Ensure query execution with Required transaction attribute
- [ ] 3.5 Verify query returns Collection of ManagerLocal objects

## 4. ProcessManager Session Bean

- [ ] 4.1 Implement ProcessManagerEJB as stateless session bean with local interface
- [ ] 4.2 Define ProcessManagerLocal and ProcessManagerLocalHome interfaces
- [ ] 4.3 Implement JNDI reference to ManagerEJB via ejb-local-ref
- [ ] 4.4 Implement createManager(orderId, status) business method
- [ ] 4.5 Implement updateStatus(orderId, status) business method
- [ ] 4.6 Implement getStatus(orderId) business method
- [ ] 4.7 Implement getOrdersByStatus(status) business method

## 5. Transaction Management

- [ ] 5.1 Declare all ManagerEJB methods with container-transaction Required
- [ ] 5.2 Declare all ProcessManagerEJB methods with container-transaction Required
- [ ] 5.3 Include method-permission unchecked for all public operations
- [ ] 5.4 Verify Required attribute applies to: create, remove, getStatus, setStatus, findByPrimaryKey, findOrdersByStatus
- [ ] 5.5 Verify transaction declarations in ejb-jar.xml assembly descriptor

## 6. Integration with Message-Driven Beans

- [ ] 6.1 Implement PurchaseOrderMDB to receive purchase order messages
- [ ] 6.2 Implement PurchaseOrderMDB.doWork() to call createManager(orderId, PENDING)
- [ ] 6.3 Implement automatic approval logic in PurchaseOrderMDB.canIApprove()
- [ ] 6.4 Implement OrderApprovalMDB to receive approval/denial messages
- [ ] 6.5 Implement OrderApprovalMDB.doWork() to check status and call updateStatus
- [ ] 6.6 Implement status guard: skip orders not in PENDING status
- [ ] 6.7 Implement InvoiceMDB to receive invoice messages
- [ ] 6.8 Implement InvoiceMDB.doWork() to transition to SHIPPED_PART or COMPLETED

## 7. Automatic Approval Logic

- [ ] 7.1 Implement PurchaseOrderMDB.canIApprove(purchaseOrder) method
- [ ] 7.2 Implement US locale check: approve if totalPrice < 500
- [ ] 7.3 Implement Japan locale check: approve if totalPrice < 50000
- [ ] 7.4 Implement default behavior: return false for other locales or threshold exceeding
- [ ] 7.5 Document auto-approval thresholds and currency assumptions
- [ ] 7.6 Add comment noting demo-only nature if applicable

## 8. JNDI Lookup and Service Location

- [ ] 8.1 Implement ServiceLocator pattern for EJB lookups
- [ ] 8.2 Implement JNDI names for ProcessManagerEJB and ManagerEJB
- [ ] 8.3 Implement ProcessManagerMDB.ejbCreate() to look up ProcessManagerLocalHome
- [ ] 8.4 Implement OrderApprovalMDB.ejbCreate() to look up ProcessManagerLocalHome
- [ ] 8.5 Implement InvoiceMDB.ejbCreate() to look up ProcessManagerLocalHome

## 9. Line Item Fulfillment Integration

- [ ] 9.1 Implement connection between order status and line item quantityShipped
- [ ] 9.2 Implement PurchaseOrderHelper.processInvoice() to determine order completion
- [ ] 9.3 Implement logic: order complete when all items have quantity == quantityShipped
- [ ] 9.4 Implement InvoiceMDB to call processInvoice and receive boolean orderDone
- [ ] 9.5 Implement transition logic: COMPLETED if orderDone, else SHIPPED_PART

## 10. XML Serialization and Deserialization

- [ ] 10.1 Implement PurchaseOrder.fromXML() to parse and validate purchase order XML
- [ ] 10.2 Implement OrderApproval.fromXML() to parse approval/denial messages
- [ ] 10.3 Implement Invoice.fromXML() to parse invoice messages and line item quantities
- [ ] 10.4 Implement ChangedOrder value object to carry orderId and requested status
- [ ] 10.5 Implement XML schema validation (DTD or XSD) for each message type

## 11. Testing and Validation

- [ ] 11.1 Test order creation and PENDING status initialization
- [ ] 11.2 Test status transitions PENDING → APPROVED → SHIPPED_PART → COMPLETED
- [ ] 11.3 Test denial path PENDING → DENIED
- [ ] 11.4 Test re-processing protection: APPROVED order rejects approval message
- [ ] 11.5 Test automatic approval for orders below US threshold
- [ ] 11.6 Test automatic approval for orders below Japan threshold
- [ ] 11.7 Test manual approval requirement for large orders
- [ ] 11.8 Test getOrdersByStatus returns all orders in given state
- [ ] 11.9 Test transaction atomicity for concurrent status updates
- [ ] 11.10 Test line item fulfillment completion logic
- [ ] 11.11 Test partial shipment tracking with quantityShipped

## 12. Documentation and Configuration

- [ ] 12.1 Document OrderStatusNames constants and state machine in javadoc
- [ ] 12.2 Document automatic approval thresholds and locale-specific behavior
- [ ] 12.3 Document container-transaction requirements
- [ ] 12.4 Document JNDI names and lookup patterns
- [ ] 12.5 Create assembly descriptor configuration examples
- [ ] 12.6 Document ProcessManager session bean interface contract
