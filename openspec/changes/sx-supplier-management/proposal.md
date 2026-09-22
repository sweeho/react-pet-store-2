# Supplier Management - Specification Proposal

## Summary

This specification extracts the supplier management capability from the legacy Java Pet Store application. The system manages supplier inventory and fulfills purchase orders received from the order processing center via asynchronous JMS messages. Suppliers can manually update inventory quantities through a web portal, which triggers automatic fulfillment of pending orders and invoice generation.

## Problem Statement

The legacy supplier management system distributes inventory and order fulfillment logic across message-driven beans, entity beans, session beans, and servlet controllers. The contracts governing purchase order reception, inventory checking, order status transitions, and invoice transmission are implicit in code and configuration rather than explicitly stated. This specification captures the supplier management contracts so the capability can be rebuilt with clear behavioral boundaries and verifiable acceptance criteria.

## Solution Overview

Supplier management consists of:

- **Authentication & Authorization**: Form-based login with administrator role restriction
- **Inventory Entity**: CMP entity storing item ID and quantity on hand
- **Inventory Portal**: Web form for manual inventory updates with checkbox-based selection
- **Purchase Order Reception**: Message-driven bean receiving PO XML via JMS queue
- **Order Fulfillment**: Session bean checking inventory, reducing quantities, marking items shipped
- **Order Status Management**: PENDING → COMPLETED transitions based on fulfillment success
- **Order Persistence**: Unfulfilled orders retained for retry when inventory becomes available
- **Pending Order Reprocessing**: Triggered by inventory updates to fulfill delayed orders
- **Invoice Generation**: XML invoices created for shipped items
- **Invoice Transmission**: Invoices published to JMS Topic for order processing center
- **Session Management**: 54-minute HTTP session timeout

## Key Behavioral Requirements

### Authentication and Authorization

The system uses form-based login with username and password fields (j_username, j_password). Inventory receipt and update operations are restricted to users with the administrator role. Unauthorized users receive a denial message.

### Inventory Management

InventoryEJB is a CMP entity bean with itemId (primary key, String) and quantity (int). The portal displays all inventory items in a table with Item ID, Existing Quantity, New Quantity input, and Update checkbox columns. Updates are only applied when the checkbox is checked for that item, and negative quantities are rejected.

### Purchase Order Reception

SupplierOrderMDB receives TextMessage containing PO XML from a JMS queue. The XML is converted to a SupplierOrder entity via TPASupplierOrderXDE and persisted immediately with status PENDING.

### Order Fulfillment

For each line item in an order:

1. checkInventory() verifies inv.quantity >= line_item.quantity
2. If insufficient: line item not fulfilled, processing continues
3. If sufficient: inventory reduced via reduceQuantity(), line item marked shipped
4. After processing all items: if all available, order marked COMPLETED; else remains PENDING

### Order Persistence

SupplierOrder entities are persisted before fulfillment attempts. Unfulfilled orders remain in PENDING status for retry via processPendingPO() when inventory is updated.

### Pending Order Reprocessing

When inventory is updated via the portal, processPendingPO() is called to:

1. Find all orders with status PENDING
2. Call processAnOrder() on each
3. Collect generated invoices
4. Publish invoices to JMS Topic

All operations within a single UserTransaction for atomicity.

### Invoice Generation and Transmission

createInvoice() generates XML invoice for items marked shipped. SupplierOrderTD publishes invoice XML to INVOICE_MDB_TOPIC via JMS for receipt by order processing center.

## Implementation Scope

Includes:

- ✓ Form-based authentication with j_security_check
- ✓ Role-based authorization (administrator)
- ✓ InventoryEJB CMP entity with itemId, quantity
- ✓ Inventory display and update portal
- ✓ Inventory quantity validation (>= 0)
- ✓ Purchase order XML reception via JMS
- ✓ SupplierOrder entity persistence
- ✓ Order fulfillment workflow
- ✓ Inventory checking and reduction
- ✓ Order status management (PENDING → COMPLETED)
- ✓ Pending order reprocessing
- ✓ Invoice generation and JMS publication
- ✓ Transaction management (Required, UserTransaction)
- ✓ HTTP session timeout (54 minutes)

Excludes:

- Payment processing
- Supplier credentials or profile management
- Order modification/cancellation after receipt
- Partial shipment tracking beyond quantityShipped flag
- Invoice payment/settlement
- Supplier performance metrics
- Inventory forecasting or reorder points
- Multiple warehouse support
- Product substitution or alternatives
- Return processing
- Backorder management systems
- Pricing or discount calculation

## Implementation Considerations

### Inventory Checking Logic

The checkInventory() method performs both checking and reduction atomically. If inventory is insufficient, the method returns false and no reduction occurs. This prevents overselling but means unsold items remain in inventory.

### Partial Fulfillment Semantics

The allItemsAvailable flag is set to false on first inventory miss and never reset. An order with mixed availability (first items unavailable, later items available) will have allItemsAvailable=false for the entire order, keeping it in PENDING status for retry. This implements a backorder model where all items must be shippable for the order to complete.

### Transaction Boundaries

RcvrRequestProcessor wraps updateInventory(), processPendingPO(), and sendInvoices() in a single UserTransaction. This ensures all-or-nothing semantics: if invoice publishing fails, inventory updates and order status changes are rolled back.

### JNDI and Service Locator

All EJB homes and JMS resources are retrieved via ServiceLocator pattern with JNDI lookups. JNDI names must be configured in application server deployment descriptors.

### Error Handling

- CatalogException and FinderException in checkInventory(): method returns false, order processing continues
- XMLDocumentException in processPO(): method returns null, order persists for retry
- NumberFormatException in quantity parsing: invalid value skipped, update not applied
- JMSException in invoice sending: error logged, transaction may rollback

## Success Criteria

Implementation is successful when:

1. Authentication prevents unauthorized portal access
2. Authorization restricts inventory operations to administrator role
3. Inventory entity persists itemId and quantity with finders working
4. Inventory display shows all items in table format
5. Inventory updates validate quantity >= 0 and apply only for checked items
6. PO message reception converts XML to SupplierOrder entity
7. Inventory checking prevents overselling (insufficient → skip, continue)
8. Inventory reduction and item shipment are atomic
9. Orders marked COMPLETED when all items available
10. Orders remain PENDING when any items unavailable
11. Unfulfilled orders persisted for later retry
12. Pending orders reprocessed after inventory updates
13. Invoices generated and published to JMS Topic
14. Sessions expire after 54 minutes inactivity
15. All operations execute within Required transaction contexts
16. All acceptance criteria scenarios pass

## Assumptions and Constraints

- OrderStatusNames.PENDING and COMPLETED are the only statuses modeled
- SupplierOrder persisted before fulfillment attempt, persists even if fulfillment fails
- Partial fulfillment keeps order in PENDING (no separate BACKORDER status)
- Inventory reduction is permanent (no undo for cancelled orders)
- Invoice publishing is fire-and-forget (no confirmation or retry)
- JMS is available and topic configured
- Administrator role is provided by servlet container
- Session timeout enforced by servlet container
- No inventory reservations or holds (stock available = can ship)
- No multi-warehouse or allocation logic

## Open Questions for Business Clarification

1. Should partially fulfilled orders (some items shipped, some backorder) be marked with an intermediate status?
2. Should inventory reduction be reversible if invoice publishing fails?
3. Should the system track failed invoices and retry publication?
4. Should order prioritization affect fulfillment order?
5. Should suppliers be notified of inventory updates via email or portal notification?
6. Should inventory have minimum/maximum thresholds triggering notifications?
7. Should the system support multiple suppliers or is it single-supplier?
8. Should partial shipments from a single order be allowed or bundled?
