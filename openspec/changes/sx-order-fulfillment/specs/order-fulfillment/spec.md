## ADDED Requirements

### Requirement: Order fulfillment workflow state machine

The system SHALL manage an order fulfillment state machine with five possible states: PENDING (initial), APPROVED, DENIED, SHIPPED_PART (partial shipment), and COMPLETED (full shipment). Orders progress through states: PENDING → APPROVED → SHIPPED_PART → COMPLETED, or PENDING → DENIED for rejection.

#### Scenario: Order receives purchase and enters PENDING state

- **GIVEN** a new purchase order received from customer
- **WHEN** the purchase order is processed
- **THEN** the order workflow is initialized with status PENDING

#### Scenario: Order transitions through fulfillment states

- **GIVEN** an order in PENDING status
- **WHEN** admin approves it
- **THEN** the status transitions to APPROVED

#### Scenario: Order can be denied at PENDING state

- **GIVEN** an order in PENDING status
- **WHEN** admin denies it
- **THEN** the status transitions to DENIED and the order is removed from fulfillment workflow

### Requirement: Status transition guarding

The system SHALL only permit status transitions from PENDING to approval states (APPROVED or DENIED). Orders that are already in APPROVED, DENIED, or COMPLETED states SHALL NOT be re-processed or have their status changed by subsequent approval or invoice messages.

#### Scenario: PENDING order allows re-processing protection

- **GIVEN** an order currently in APPROVED status
- **WHEN** a subsequent approval message arrives with a different status
- **THEN** the order status is not changed and the message is skipped

#### Scenario: Only PENDING orders accept status changes

- **GIVEN** multiple orders with different statuses
- **WHEN** approval messages are processed
- **THEN** only orders in PENDING state are transitioned; others are skipped

### Requirement: Order manager entity

The system SHALL maintain an order manager entity with orderId as the primary key and status as a mutable field, persisted via container-managed persistence. Entity access SHALL be transactional with REQUIRED isolation.

#### Scenario: Manager entity persists order workflow state

- **GIVEN** a new order workflow to track
- **WHEN** a Manager entity is created with orderId and initial status
- **THEN** the entity is persisted with both fields in the database

#### Scenario: Status updates are atomic

- **GIVEN** a Manager entity in persistent storage
- **WHEN** the status is updated via getStatus/setStatus
- **THEN** the update executes within a Required container-managed transaction

### Requirement: Create order workflow manager

When a new purchase order is received, the system SHALL create a Manager entity to initiate order workflow tracking with an initial status of PENDING.

#### Scenario: Manager is created for new purchase orders

- **GIVEN** a new purchase order arriving at the system
- **WHEN** the purchase order message is processed
- **THEN** a new Manager entity is created with the order ID and status PENDING

### Requirement: Update order status

The system SHALL provide a method to update the status of an order during workflow processing, retrieving the order by orderId and setting its new status atomically.

#### Scenario: Status is updated via update method

- **GIVEN** an existing order in PENDING status
- **WHEN** updateStatus is called with the order ID and new status
- **THEN** the status is changed atomically in the persistent store

### Requirement: Retrieve order status

The system SHALL allow retrieval of the current status of a specific order by orderId, returning the status string value.

#### Scenario: Current status is retrieved

- **GIVEN** an order with orderId "PO-12345"
- **WHEN** getStatus is called with that order ID
- **THEN** the current status string (e.g., PENDING, APPROVED) is returned

### Requirement: Query orders by status

The system SHALL provide a query to retrieve all orders in a given status to support administrative reporting and order fulfillment tracking. The query result returns a collection of order identifiers and status values.

#### Scenario: Admin queries orders by status

- **GIVEN** multiple orders in various status states
- **WHEN** getOrdersByStatus(APPROVED) is called
- **THEN** a collection of all orders currently in APPROVED status is returned

### Requirement: Partial shipment tracking

The system SHALL support partial shipment of orders, allowing an order to be marked as SHIPPED_PART when only a subset of items have been fulfilled, before final completion.

#### Scenario: Order progresses from APPROVED to SHIPPED_PART

- **GIVEN** an order in APPROVED status with 5 line items
- **WHEN** an invoice arrives showing 3 items shipped and 2 pending
- **THEN** the order status transitions to SHIPPED_PART

#### Scenario: Order progresses from SHIPPED_PART to COMPLETED

- **GIVEN** an order in SHIPPED_PART status with 2 items remaining
- **WHEN** a final invoice arrives showing all remaining items shipped
- **THEN** the order status transitions to COMPLETED

### Requirement: Line item fulfillment tracking

The system SHALL track the quantity of each line item that has been shipped via a quantityShipped field, allowing partial fulfillment and determining order completion. A line item is completely fulfilled when quantity equals quantityShipped.

#### Scenario: Line item quantities are tracked

- **GIVEN** a line item with quantity 10 ordered
- **WHEN** an invoice arrives with 4 units shipped
- **THEN** the quantityShipped field is incremented to 4

#### Scenario: Order completion based on line items

- **GIVEN** an order with 3 line items all tracking quantityShipped
- **WHEN** an invoice arrives showing all line items have quantity == quantityShipped
- **THEN** the order is completely fulfilled and ready to transition to COMPLETED

### Requirement: Automatic approval for small orders

Orders below a locale-specific price threshold SHALL be automatically approved without requiring manual administrator review.

#### Scenario: Small US order is auto-approved

- **GIVEN** a purchase order in US locale with total price of 250
- **WHEN** the purchase order is received
- **THEN** the order is automatically transitioned to APPROVED status without admin intervention

#### Scenario: Large US order requires approval

- **GIVEN** a purchase order in US locale with total price of 750
- **WHEN** the purchase order is received
- **THEN** the order remains in PENDING status awaiting manual admin approval

#### Scenario: Small Japan order is auto-approved

- **GIVEN** a purchase order in Japan locale with total price of 30000
- **WHEN** the purchase order is received
- **THEN** the order is automatically transitioned to APPROVED status

#### Scenario: Large Japan order requires approval

- **GIVEN** a purchase order in Japan locale with total price of 75000
- **WHEN** the purchase order is received
- **THEN** the order remains in PENDING status awaiting manual admin approval

### Requirement: Transactional order operations

All order status reads and writes SHALL execute within transactional boundaries with isolation and atomicity guarantees. Container-managed transactions with Required propagation SHALL wrap every operation that accesses order status.

#### Scenario: All operations execute in transactions

- **GIVEN** any order workflow operation
- **WHEN** a status read or write occurs
- **THEN** the EJB container ensures execution within a Required transaction context

### Requirement: Public access to workflow operations

All processmanager methods SHALL be publicly accessible without authorization requirements, using unchecked access permission.

#### Scenario: Anyone can invoke workflow operations

- **GIVEN** any caller (authenticated or not)
- **WHEN** workflow methods are called
- **THEN** no role-based access control restrictions prevent invocation
