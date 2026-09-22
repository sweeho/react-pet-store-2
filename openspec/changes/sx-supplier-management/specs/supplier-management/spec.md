## ADDED Requirements

### Requirement: Supplier portal authentication

The system SHALL require authentication before granting access to supplier portal functionality using form-based login with username and password fields.

#### Scenario: User authentication via login form

- **GIVEN** an unauthenticated user accessing the supplier portal
- **WHEN** the user submits username and password via the login form
- **THEN** the system authenticates the user via the servlet container's form-based login mechanism

### Requirement: Inventory administrator authorization

The system SHALL restrict inventory receipt and update operations to users in the administrator role. Unauthorized users SHALL receive a denial message when attempting to access inventory update functionality.

#### Scenario: Administrator access to inventory update

- **GIVEN** a user with administrator role
- **WHEN** the user attempts to access the inventory update page
- **THEN** the inventory update form is displayed

#### Scenario: Non-administrator denied inventory access

- **GIVEN** a user without administrator role
- **WHEN** the user attempts to access the inventory update page
- **THEN** the message "You are not authorised to update the status of orders" is displayed

### Requirement: Inventory entity persistence

The system SHALL maintain inventory records with item identifier (String, primary key) and quantity on hand (integer).

#### Scenario: Inventory item storage

- **GIVEN** an inventory entity for itemId "ITEM-001"
- **WHEN** the inventory is persisted with quantity 100
- **THEN** the system stores both itemId and quantity, retrievable via getItemId() and getQuantity()

### Requirement: Display inventory items

The system SHALL allow authorized administrators to display all inventory items with their current quantities in a table format showing Item ID and Existing Quantity columns.

#### Scenario: Inventory list displayed

- **GIVEN** a collection of inventory items
- **WHEN** an authorized administrator accesses the display inventory page
- **THEN** a table is displayed with rows for each item showing Item ID, Existing Quantity, New Quantity input field, and Update checkbox

### Requirement: Update inventory quantities

The system SHALL allow authorized administrators to update inventory quantities for items via form submission. Updates SHALL only be applied when the checkbox is checked for that item. Negative quantities SHALL be rejected and not applied.

#### Scenario: Valid inventory quantity update

- **GIVEN** an inventory item with current quantity 50 and updated quantity field value 75
- **WHEN** the administrator checks the item's checkbox and submits the form
- **THEN** the inventory quantity is updated to 75

#### Scenario: Negative quantity rejected

- **GIVEN** an inventory item and a negative quantity value -5 submitted for update
- **WHEN** the administrator submits the form
- **THEN** the quantity update is rejected and the inventory quantity remains unchanged

#### Scenario: Unchecked item not updated

- **GIVEN** an inventory item with quantity 50 and updated value 75, but the item checkbox is unchecked
- **WHEN** the administrator submits the form
- **THEN** the inventory quantity remains 50

### Requirement: Purchase order message reception

The system SHALL receive purchase orders from the order processing center via JMS queue as XML TextMessage, process them through the message-driven bean, and convert the XML to a SupplierOrder entity.

#### Scenario: PO message received and converted

- **GIVEN** a purchase order XML message in the JMS queue
- **WHEN** the SupplierOrderMDB message listener processes the message
- **THEN** the XML is converted to a SupplierOrder entity and persisted

### Requirement: Inventory availability checking

GIVEN a line item in a purchase order, WHEN attempting to fulfill the order, the system SHALL check whether inventory quantity for that item is greater than or equal to the quantity requested in the line item. If insufficient inventory exists, the line item SHALL NOT be fulfilled and processing SHALL continue to the next item.

#### Scenario: Sufficient inventory for fulfillment

- **GIVEN** a line item requesting quantity 10 and inventory contains quantity 15
- **WHEN** the fulfillment check is performed
- **THEN** the line item is marked for fulfillment and inventory is reduced

#### Scenario: Insufficient inventory skipped

- **GIVEN** a line item requesting quantity 20 and inventory contains quantity 10
- **WHEN** the fulfillment check is performed
- **THEN** the line item is not fulfilled and processing continues to other items

### Requirement: Inventory reduction and item shipment

When inventory is confirmed available for a line item, the system SHALL atomically reduce the inventory quantity by the line item quantity and mark the line item as shipped within the same transaction.

#### Scenario: Inventory reduced and item shipped

- **GIVEN** a line item with quantity 5 and available inventory of 50
- **WHEN** the fulfillment check passes
- **THEN** the inventory quantity is reduced to 45 and the line item quantityShipped is set to 5 atomically

### Requirement: Purchase order completion

When all line items in a purchase order have been processed, if all items were available and shipped, the system SHALL mark the purchase order status as COMPLETED. If any items were unavailable, the order status SHALL remain PENDING.

#### Scenario: Order completed when all items available

- **GIVEN** a purchase order with two line items and sufficient inventory for both
- **WHEN** fulfillment processing completes
- **THEN** the purchase order status is set to COMPLETED

#### Scenario: Order remains PENDING with partial fulfillment

- **GIVEN** a purchase order with two line items and insufficient inventory for one item
- **WHEN** fulfillment processing completes
- **THEN** the purchase order status remains PENDING

### Requirement: Unfulfilled order persistence

When line items cannot be fulfilled due to insufficient inventory or other error conditions, the purchase order SHALL be persisted so that fulfillment can be attempted again when inventory becomes available.

#### Scenario: Order persisted for retry

- **GIVEN** a purchase order with items that cannot be fulfilled due to insufficient inventory
- **WHEN** the fulfillment attempt fails
- **THEN** the purchase order is stored in the system with PENDING status for future fulfillment attempts

### Requirement: Pending order reprocessing

When inventory is updated via the receiver portal, the system SHALL attempt to fulfill any purchase orders that are in PENDING status by checking the newly updated inventory, creating invoices for items that can now be shipped, and sending those invoices to the order processing center via JMS.

#### Scenario: Pending orders fulfilled after inventory update

- **GIVEN** an administrator updates inventory quantities via the receiver portal
- **WHEN** the inventory update is submitted with currentScreen=updateinventory
- **THEN** the system calls processPendingPO() to retrieve all PENDING orders, attempts fulfillment, creates invoices for shippable items, and sends invoices

### Requirement: Invoice transmission

The system SHALL send invoices to the order processing center via JMS Topic when purchase orders are fulfilled and items are shipped. Invoices are sent as XML TextMessage containing invoice data.

#### Scenario: Invoice sent via JMS topic

- **GIVEN** a fulfilled purchase order with items available for shipment
- **WHEN** the invoice is generated and fulfillment completes
- **THEN** the invoice XML is published to the INVOICE_MDB_TOPIC for receipt by the order processing center

### Requirement: HTTP session timeout

The system SHALL expire HTTP sessions after 54 minutes of inactivity to ensure security of the supplier portal.

#### Scenario: Session expires after inactivity

- **GIVEN** an HTTP session with no activity for 54 minutes
- **WHEN** the session timeout period expires
- **THEN** the session is invalidated and the user must re-authenticate
