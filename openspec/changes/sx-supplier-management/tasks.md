## 1. Authentication and Authorization

- [ ] 1.1 Configure form-based login in web.xml with login page /login.jsp and error page /error.jsp
- [ ] 1.2 Implement login.jsp with j_username and j_password input fields
- [ ] 1.3 Implement j_security_check servlet endpoint
- [ ] 1.4 Declare security-constraint in web.xml restricting /RcvrRequestProcessor to administrator role
- [ ] 1.5 Implement role-based access check in JSP: request.isUserInRole("administrator")
- [ ] 1.6 Display "You are not authorised to update the status of orders" message for unauthorized users
- [ ] 1.7 Configure session timeout to 54 minutes in web.xml session-config

## 2. Inventory Entity Model

- [ ] 2.1 Implement InventoryEJB as CMP 2.x entity bean with itemId (String, PK) and quantity (int)
- [ ] 2.2 Declare InventoryEJB in ejb-jar.xml with persistence-type Container
- [ ] 2.3 Implement abstract getter and setter methods: getItemId(), setItemId(), getQuantity(), setQuantity()
- [ ] 2.4 Implement reduceQuantity(int quantity) method subtracting quantity from current value
- [ ] 2.5 Declare InventoryLocalHome interface with findAllInventoryItems() and findByPrimaryKey() finders
- [ ] 2.6 Implement finder methods in ejb-jar.xml <query> elements

## 3. Inventory Display Portal

- [ ] 3.1 Create DisplayInventoryBean JSP backing bean with getInventory() method
- [ ] 3.2 Implement getInventory() using ServiceLocator to retrieve InventoryLocalHome
- [ ] 3.3 Call findAllInventoryItems() to fetch all inventory items
- [ ] 3.4 Create displayinventory.jsp JSP page with JSP useBean directive
- [ ] 3.5 Implement inventory table with columns: Item ID, Existing Quantity
- [ ] 3.6 Iterate items via <c:forEach> and display itemId and quantity
- [ ] 3.7 Add New Quantity input field with name="qty\_<itemId>"
- [ ] 3.8 Add Update checkbox with name="item\_<itemId>"
- [ ] 3.9 Implement form action=RcvrRequestProcessor method=POST
- [ ] 3.10 Add hidden field currentScreen=updateinventory
- [ ] 3.11 Add Update button to submit form
- [ ] 3.12 Wrap entire form in isUserInRole("administrator") check

## 4. Inventory Update Processing

- [ ] 4.1 Implement RcvrRequestProcessor servlet extending HttpServlet
- [ ] 4.2 Implement doPost() to extract currentScreen parameter
- [ ] 4.3 For currentScreen=updateinventory: call updateInventory(), processPendingPO(), sendInvoices()
- [ ] 4.4 Implement updateInventory() method iterating request parameters
- [ ] 4.5 For each parameter starting with "item*": extract itemId and corresponding qty*<itemId> value
- [ ] 4.6 Parse quantity as Integer and validate quantity >= 0
- [ ] 4.7 For valid quantities: look up InventoryLocal via findByPrimaryKey and call setQuantity()
- [ ] 4.8 Wrap updateInventory/processPendingPO/sendInvoices in UserTransaction.begin()/commit()
- [ ] 4.9 Handle NumberFormatException in quantity parsing (skip invalid value)

## 5. Purchase Order Message Reception

- [ ] 5.1 Implement SupplierOrderMDB as message-driven bean
- [ ] 5.2 Configure MDB to listen to PO queue via deployment descriptor
- [ ] 5.3 Implement onMessage(Message msg) casting to TextMessage
- [ ] 5.4 Extract XML text from TextMessage via getText()
- [ ] 5.5 Call OrderFulfillmentFacadeEJB.processPO(xmlText)
- [ ] 5.6 On successful return: call doTransition() with returned invoice XML
- [ ] 5.7 Handle CreateException, XMLDocumentException with error logging

## 6. XML to Entity Conversion

- [ ] 6.1 Implement TPASupplierOrderXDE XML deserializer
- [ ] 6.2 Parse PO XML to extract order fields: poId, status, line items
- [ ] 6.3 Create SupplierOrder object with parsed data
- [ ] 6.4 Return SupplierOrder value object to OrderFulfillmentFacadeEJB

## 7. Purchase Order Persistence

- [ ] 7.1 Implement SupplierOrderLocal CMP entity with poId (PK), poStatus, lineItems
- [ ] 7.2 Implement SupplierOrderLocalHome interface with create(SupplierOrder) and findOrdersByStatus(status) finder
- [ ] 7.3 In OrderFulfillmentFacadeEJB.processPO(): create SupplierOrder entity before fulfillment attempt
- [ ] 7.4 Set initial status to PENDING on creation
- [ ] 7.5 Implement OrderStatusNames constants: PENDING, COMPLETED

## 8. Inventory Checking and Reduction

- [ ] 8.1 Implement checkInventory(LineItemLocal item) method in OrderFulfillmentFacadeEJB
- [ ] 8.2 Look up InventoryLocal via inventoryHome.findByPrimaryKey(item.getItemId())
- [ ] 8.3 Compare inv.getQuantity() >= item.getQuantity()
- [ ] 8.4 If insufficient: return false (item not fulfilled)
- [ ] 8.5 If sufficient: call inv.reduceQuantity(item.getQuantity()) and return true
- [ ] 8.6 Catch FinderException (item not found): return false

## 9. Order Fulfillment Processing

- [ ] 9.1 Implement processAnOrder(SupplierOrderLocal po) method
- [ ] 9.2 Initialize boolean allItemsAvailable=true, boolean invoiceRequired=false
- [ ] 9.3 Get line items collection via po.getLineItems()
- [ ] 9.4 Iterate line items:
- [ ] 9.5 Skip if li.getQuantityShipped() == li.getQuantity() (already fulfilled)
- [ ] 9.6 Call checkInventory(li): if false, set allItemsAvailable=false, continue
- [ ] 9.7 If checkInventory returns true: call li.setQuantityShipped(li.getQuantity())
- [ ] 9.8 Set invoiceRequired=true
- [ ] 9.9 After iteration: if allItemsAvailable, call po.setPoStatus(OrderStatusNames.COMPLETED)
- [ ] 9.10 If invoiceRequired: call createInvoice(po, items) and return invoice XML
- [ ] 9.11 Else: return null

## 10. Order Status Management

- [ ] 10.1 Define OrderStatusNames constants: PENDING, COMPLETED
- [ ] 10.2 Implement setPoStatus(String status) on SupplierOrderLocal
- [ ] 10.3 Mark orders as COMPLETED only when allItemsAvailable flag is true
- [ ] 10.4 Ensure PENDING status set on initial order creation

## 11. Invoice Generation

- [ ] 11.1 Implement createInvoice(SupplierOrderLocal po, Collection items) method
- [ ] 11.2 Generate invoice XML from order and line item data
- [ ] 11.3 Return invoice XML as String
- [ ] 11.4 Handle XMLDocumentException if XML generation fails (return null)

## 12. Pending Order Reprocessing

- [ ] 12.1 Implement processPendingPO() method in OrderFulfillmentFacadeEJB
- [ ] 12.2 Query for orders with status=PENDING via findOrdersByStatus(OrderStatusNames.PENDING)
- [ ] 12.3 Iterate returned orders collection
- [ ] 12.4 Call processAnOrder(order) for each pending order
- [ ] 12.5 Collect returned invoices (non-null) into ArrayList
- [ ] 12.6 Return ArrayList of invoices to caller (RcvrRequestProcessor)

## 13. Invoice Transmission

- [ ] 13.1 Implement SupplierOrderTD (TransitionDelegate) with setup() and doTransition(TransitionInfo) methods
- [ ] 13.2 In setup(): look up TopicConnectionFactory and Topic from JNDI
- [ ] 13.3 Create TopicSender instance
- [ ] 13.4 Implement TopicSender.sendMessage(String xmlInvoice) method
- [ ] 13.5 Create TopicConnection via factory.createTopicConnection()
- [ ] 13.6 Create TopicSession with AUTO_ACKNOWLEDGE
- [ ] 13.7 Create TopicPublisher for topic
- [ ] 13.8 Create TextMessage via session.createTextMessage()
- [ ] 13.9 Set message text to invoice XML
- [ ] 13.10 Publish message via publisher.publish(jmsMsg)
- [ ] 13.11 Handle JMSException with error logging

## 14. Portal Request Handling

- [ ] 14.1 Implement RcvrRequestProcessor.doPost() entry point
- [ ] 14.2 Extract currentScreen parameter
- [ ] 14.3 If currentScreen=updateinventory: begin UserTransaction
- [ ] 14.4 Call updateInventory(req) to process form parameters
- [ ] 14.5 Call processPendingPO() to fulfill pending orders
- [ ] 14.6 Call sendInvoices(invoices) to publish returned invoices
- [ ] 14.7 Commit UserTransaction
- [ ] 14.8 Handle exception: rollback transaction and display error

## 15. Integration and Configuration

- [ ] 15.1 Configure SupplierOrderMDB as message listener in ejb-jar.xml
- [ ] 15.2 Set JMS queue destination for order reception
- [ ] 15.3 Configure JNDI names for InventoryLocalHome, SupplierOrderLocalHome
- [ ] 15.4 Configure JNDI names for TopicConnectionFactory and INVOICE_MDB_TOPIC
- [ ] 15.5 Declare all methods in transaction descriptors with Required attribute
- [ ] 15.6 Configure method permissions for all EJB methods

## 16. Testing and Validation

- [ ] 16.1 Test form-based login with valid credentials
- [ ] 16.2 Test unauthorized access to inventory update page
- [ ] 16.3 Test inventory display lists all items
- [ ] 16.4 Test inventory quantity update with valid value
- [ ] 16.5 Test negative quantity rejection
- [ ] 16.6 Test unchecked item not updated
- [ ] 16.7 Test PO message reception and XML conversion
- [ ] 16.8 Test inventory checking with sufficient inventory
- [ ] 16.9 Test inventory checking with insufficient inventory
- [ ] 16.10 Test inventory reduction and item shipment atomicity
- [ ] 16.11 Test order completion when all items available
- [ ] 16.12 Test order remains PENDING with partial fulfillment
- [ ] 16.13 Test pending order persistence and retry
- [ ] 16.14 Test invoice generation and JMS publication
- [ ] 16.15 Test session timeout enforcement
