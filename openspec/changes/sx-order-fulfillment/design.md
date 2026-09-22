# Order Fulfillment - Design Document

## Overview

The order fulfillment system manages the workflow lifecycle of customer orders through a state machine model, tracking orders as they progress from placement through approval and shipment to completion. The system coordinates between order placement, approval processes, invoice processing, and fulfillment tracking via asynchronous message-driven components and a persistent order manager entity.

## Architecture

### Order Manager Entity (ManagerEJB)

- CMP 2.x entity bean with Container-Managed Persistence
- Primary key: orderId (String)
- Mutable field: status (String)
- Transactional access with Required isolation level
- Local interface only (ManagerLocal, ManagerLocalHome)
- Abstract getter/setter pattern enforced by container

### Workflow State Machine

Five states with documented transitions:

```
PENDING → APPROVED → SHIPPED_PART → COMPLETED
   ↓
DENIED (terminal)
```

**State Meanings:**

- **PENDING**: Order received, awaiting approval decision
- **APPROVED**: Order approved for fulfillment; supplier orders may be generated
- **SHIPPED_PART**: Partial shipment received; more items outstanding
- **COMPLETED**: Full shipment received; order fulfillment complete
- **DENIED**: Order rejected; workflow terminates

### Message-Driven Components

**PurchaseOrderMDB** (inbound: PurchaseOrder queue)

- Receives new purchase orders in XML format
- Creates PurchaseOrder entity
- Initializes Manager workflow with PENDING status
- Implements automatic approval logic for small orders
- Publishes OrderApproval messages for approved orders

**OrderApprovalMDB** (inbound: OrderApproval queue)

- Receives admin approval/denial decisions
- Guards against re-processing via status check (PENDING only)
- Updates Manager status to APPROVED or DENIED
- Generates supplier orders for approved orders
- Publishes approval notifications

**InvoiceMDB** (inbound: Invoice queue)

- Receives invoice messages from suppliers
- Determines fulfillment status via PurchaseOrderHelper.processInvoice()
- Transitions APPROVED orders to SHIPPED_PART or COMPLETED based on line item completion
- Publishes order completion notifications

### ProcessManager Session Bean

- Stateless Session Bean with local interface
- Wraps Manager entity operations
- Methods: createManager, updateStatus, getStatus, getOrdersByStatus
- Provides administrative query capability

### Order Completion Logic

Order completion is determined by line-item fulfillment tracking:

- Each LineItem has quantity (ordered) and quantityShipped (received)
- Order is complete when all line items satisfy: quantity == quantityShipped
- Logic implemented in PurchaseOrderHelper.processInvoice() (external to this component)
- Manager entity records the state; fulfillment logic is in purchase order component

### Automatic Approval Thresholds

Price thresholds by locale (hardcoded):

- **US Locale**: orders < $500 are auto-approved
- **Japan Locale**: orders < ¥50000 are auto-approved
- **Other locales**: require manual approval

Implemented in PurchaseOrderMDB.canIApprove(). Note: Source code comment indicates this is a demo-only feature; production applicability requires verification.

### JNDI Integration

- ProcessManager and Manager EJBs accessed via JNDI lookup
- ServiceLocator pattern used by MDB components
- Local interface only (no remote or web service exposure)

### Transaction Model

- All operations use container-managed transactions with Required attribute
- Creates new transaction if none exists; joins existing transaction if one exists
- Ensures ACID guarantees for status reads and writes
- Prevents concurrent modification issues

## Data Model

### Manager Entity

```
Manager {
  orderId: String (primary key)
  status: String (PENDING | APPROVED | DENIED | SHIPPED_PART | COMPLETED)
}
```

### Integration with External Entities

Manager has no direct relationships but is referenced by:

- PurchaseOrder: one-to-one via orderId
- LineItem: accessed indirectly through PurchaseOrder
- ChangedOrder (XML value object): carries orderId and requested status

## User Interface

No screen records were extracted for this capability; its user interface is unspecified.

## Legacy Implementation Notes

- Uses EJB 2.x stateless session and CMP entity patterns
- Asynchronous processing via JMS message-driven beans
- ServiceLocator pattern for JNDI lookups
- Static status constants (OrderStatusNames class) enforce valid values
- XML-based message format for inter-component communication
- No lifecycle or onMessage logging visible in specifications
- Guards against idempotent message redelivery via status checks
- Automatic approval feature includes demo-only caveat in source

## Error Handling

- No explicit error handling documented in order-fulfillment records
- Parent components (PurchaseOrderMDB, OrderApprovalMDB, InvoiceMDB) handle XML parsing and finder exceptions
- Message-driven bean transaction model provides implicit rollback on exceptions

## Performance and Scalability

- CMP entity bean persistence delegates to container
- EJB-QL query for getOrdersByStatus allows efficient retrieval
- Single-threaded access per order via orderId primary key
- No caching or query optimization visible in specifications
