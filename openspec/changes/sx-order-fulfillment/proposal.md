# Order Fulfillment - Specification Proposal

## Summary

This specification extracts the order fulfillment workflow capability from the legacy Java Pet Store application. The system manages orders through an asynchronous state machine that tracks orders from placement through approval, shipment, and completion. Fulfillment is coordinated via message-driven beans that process purchase orders, approvals, and invoices, updating a persistent Manager entity that holds the authoritative order state.

## Problem Statement

The legacy fulfillment system distributes order workflow state and transitions across multiple message-driven beans (PurchaseOrderMDB, OrderApprovalMDB, InvoiceMDB) with ad-hoc state management. Order status is persisted in a Manager entity, but the rules governing state transitions, re-processing guards, and completion logic are scattered across bean implementations and helper classes. The automatic approval logic uses hard-coded thresholds with unclear production applicability. This specification captures the workflow contracts so the capability can be reliably rebuilt in a modern architecture.

## Solution Overview

Order fulfillment consists of:

- **Manager Entity (ManagerEJB)**: CMP entity bean persisting orderId and status
- **ProcessManager Session Bean**: Stateless wrapper providing workflow operations (create, update, query status)
- **OrderStatusNames**: Constants defining five states (PENDING, APPROVED, DENIED, SHIPPED_PART, COMPLETED)
- **Message-Driven Beans**: PurchaseOrderMDB, OrderApprovalMDB, InvoiceMDB coordinating workflow via asynchronous messages
- **Automatic Approval Logic**: Locale-specific price thresholds in PurchaseOrderMDB
- **State Transition Guards**: Prevention of re-processing already-transitioned orders
- **Fulfillment Tracking**: Integration with line item quantityShipped to determine completion

## Key Behavioral Requirements

### Workflow States and Transitions

Five states with documented paths:

- PENDING (initial state) → APPROVED → SHIPPED_PART → COMPLETED
- PENDING → DENIED (rejection path)

Orders begin in PENDING when received, transition through approval and shipment states, and reach terminal states (DENIED or COMPLETED).

### Automatic Approval

Orders below locale-specific thresholds skip manual approval:

- **US orders < $500**: auto-approved
- **Japan orders < ¥50000**: auto-approved
- **Other cases**: require manual approval

Source code indicates this is a demo feature; production applicability is uncertain.

### Status Transition Guards

Only PENDING orders may be transitioned to APPROVED or DENIED. This prevents double-processing from idempotent message redelivery and ensures orders cannot be re-approved after initial processing.

### Partial Shipment Support

Orders track fulfillment via line item quantityShipped:

- APPROVED → SHIPPED_PART: when partial shipment received
- SHIPPED_PART → COMPLETED: when all line items fully shipped
- Order completion determined by: all lineItems where quantity == quantityShipped

### Transaction Boundaries

All status operations execute within container-managed transactions with Required attribute, ensuring atomicity and isolation.

## Implementation Scope

Includes:

- ✓ ManagerEJB CMP entity with orderId and status
- ✓ ProcessManagerEJB stateless session bean facade
- ✓ Five status states and documented transitions
- ✓ Automatic approval for small orders
- ✓ Status transition guards
- ✓ Query orders by status
- ✓ Transactional isolation
- ✓ Public access (no role-based restrictions)
- ✓ Integration with message-driven beans (PurchaseOrderMDB, OrderApprovalMDB, InvoiceMDB)

Excludes:

- Order cancellation after approval
- Manual status override (non-standard transitions)
- Custom notification or event publishing
- Advanced fulfillment scenarios (dropship, backorder, substitution)
- Multi-order grouping or batch fulfillment
- Performance optimization (caching, query tuning)

## Implementation Considerations

### Entity Persistence

Manager is persisted via CMP 2.x; no application-managed SQL. The orderId primary key ensures single access point for status updates. No relationships to other entities; integration is via external references (PurchaseOrder orderId cross-reference).

### Message-Driven Coordination

Three MDBs coordinate fulfillment:

1. **PurchaseOrderMDB**: Initializes workflow with PENDING, applies automatic approval
2. **OrderApprovalMDB**: Transitions from PENDING to APPROVED/DENIED
3. **InvoiceMDB**: Transitions to SHIPPED_PART/COMPLETED based on line item completion

No direct invocation; all interaction is message-based. Asynchronous processing provides loose coupling.

### Fulfillment Completion Logic

Order completion (quantity == quantityShipped for all line items) is determined by PurchaseOrderHelper.processInvoice(), which exists in the purchase order component, not order fulfillment. The fulfillment component accepts the boolean result and records state accordingly. This split responsibility should be documented.

### Automatic Approval Thresholds

Hard-coded values (500 USD, 50000 JPY) with no configuration or test. Source comment indicates demo-only purpose. Production applicability requires business validation.

### JNDI Access

All EJB lookups use ServiceLocator pattern with JNDI names. Local interfaces only; no remote or web service access.

## Success Criteria

Implementation is successful when:

1. Manager entity persists orderId and status with CMP 2.x
2. Orders begin in PENDING status when created
3. Status transitions follow documented paths (PENDING→APPROVED→SHIPPED_PART→COMPLETED or PENDING→DENIED)
4. Re-processing protection: APPROVED/DENIED/COMPLETED orders reject status change attempts
5. Automatic approval: US orders <$500 auto-approved; Japan orders <¥50000 auto-approved
6. Manual approval: large orders and other locales require admin decision
7. getOrdersByStatus returns all orders matching a given status
8. All status operations execute within Required transactions
9. Public access allowed without role-based restrictions
10. Line item fulfillment determines SHIPPED_PART vs. COMPLETED transitions
11. Message-driven beans coordinate workflow via asynchronous messages
12. All acceptance criteria scenarios pass without behavioral regression

## Assumptions and Constraints

- Order fulfillment is a state machine; no complex conditional logic beyond simple transitions
- Locale comparison uses Java Locale.US and Locale.JAPAN; other locales default to manual approval
- Automatic approval thresholds are static; no dynamic configuration
- Message delivery is idempotent; status guards prevent duplicate processing
- No external approval systems or workflow engines; ProcessManager is the source of truth
- Status values are strings, not enums; validation via OrderStatusNames constants
- No change log or audit trail of status transitions
- Concurrent updates to same order are not a documented scenario; Required transactions provide isolation

## Open Questions for Business Clarification

1. Are automatic approval thresholds still in use in production, or are they demo-only scaffolding?
2. What currency do the thresholds assume (USD for US locale, JPY for Japan locale)?
3. Should orders in DENIED state be queryable or archived?
4. Are there business requirements for status change notifications or audit logging?
5. Should manual approval include a reason or comment field?
