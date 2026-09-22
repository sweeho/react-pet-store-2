# AGENTS.md: Guidance for Rebuild

## Overview

This document provides guidance for implementing the ten capabilities extracted from the Java Pet Store 1.3.2 legacy application. The capabilities are specified in OpenSpec format under `openspec/changes/sx-<capability>/` with detailed requirements, acceptance criteria, and screen definitions.

## Technology Stack

The rebuild MUST use the pinned stack defined in `ARCHITECTURE.md`:

- **Frontend**: React SPA with Vite (NOT Next.js, NOT server-side rendering)
- **Routing**: `vite-plugin-pages` (file-based) + `react-router`
- **Backend**: Nitro (H3) with file-based routes (NOT Express, NOT custom HTTP)
- **Database**: SQLite via better-sqlite3 + Drizzle ORM (NOT Prisma, NOT remote DB)
- **Styling**: Tailwind CSS (CSS-first; NO tailwind.config.ts)
- **UI Components**: Radix primitives + shadcn/ui patterns
- **Icons**: lucide-react / @heroicons/react
- **Testing**: Vitest + Testing Library (unit/integration), Playwright (E2E)
- **Auto-imports**: `unplugin-auto-import` for React and router APIs

**Validation**: Each design decision MUST be measured against this pinned stack. A design that reaches for different tools is wrong for this project, not a valid alternative.

## Extracted Artifacts (Read-Only Evidence)

Three files document the LEGACY SYSTEM as it exists — they are evidence, not build targets:

- **`api/openapi.yaml`**: API contract extracted from EJB method signatures, servlet handlers, and flow definitions. This is what the legacy system exposes; areas where this disagrees with a delta spec MUST be resolved by following the delta spec.
- **`architecture/erd.mermaid`**: Entity-relationship diagram showing database schema. Where this conflicts with a capability spec, the spec wins.
- **`architecture/schema.sql`**: SQL DDL extracted from CMP entity bean declarations and database configuration. Describes what exists; does NOT prescribe how to rebuild.

These three CARRY A DISCLAIMER: they describe the legacy system, not what to build. A capability delta spec is authoritative where they conflict.

## Capability Order and Dependencies

Capabilities have logical dependency ordering — earlier capabilities are prerequites for later ones:

1. **authentication** (no dependencies)
   - Form-based login, session management, user validation
   - User entity with username/password
   - Foundation for all protected resources

2. **customer-management** (depends: authentication)
   - Customer contact information form
   - Address persistence (billing, shipping)
   - State/country dropdown lists

3. **product-catalog** (no dependencies)
   - Multi-locale hierarchical catalog (Category → Product → Item)
   - Paginated browsing and full-text search
   - Read-only operations via stateless session bean facade

4. **shopping-cart** (depends: product-catalog)
   - Stateful session bean maintaining HashMap of quantities
   - Real-time pricing integration via CatalogHelper
   - Cart display screen with update/remove controls

5. **order-placement** (depends: shopping-cart, customer-management, authentication)
   - Two-phase EJB lifecycle creating PurchaseOrder entity
   - Relates ContactInfo, CreditCard, LineItem entities
   - Order total calculation (SUM of line items)
   - XML serialization for async transmission

6. **order-fulfillment** (depends: order-placement)
   - Message-driven bean receiving orders via JMS
   - Session bean facade checking inventory, reducing stock
   - Order status transitions (PENDING → COMPLETED/DENIED)
   - Invoice generation and JMS publication

7. **payment-processing** (depends: order-placement)
   - Credit card validation and persistence
   - Payment authorization via external gateway
   - Declined card handling and transaction logging

8. **notifications** (depends: order-placement, order-fulfillment)
   - Email template selection based on locale
   - Async JMS delivery for order confirmations and shipment notices
   - Mailer component with persistence

9. **supplier-management** (depends: order-fulfillment)
   - Supplier portal with form-based login
   - Inventory entity and update portal
   - Pending order reprocessing after inventory updates
   - Invoice transmission to order processing center

10. **admin-operations** (depends: authentication, order-fulfillment)
    - Admin console with home screen and Java Web Start launcher
    - Rich client with tabbed interface
    - Order management (view, approve, deny) with sortable tables
    - Sales analytics (revenue, order count charts)

## Key Architectural Patterns

### Entity Lifecycle (Two-Phase Creation)

PurchaseOrder and related entities follow the EJB 2.x two-phase pattern:

1. **ejbCreate()**: Set all CMP fields (container persists to DB)
2. **ejbPostCreate()**: Create child entities (ContactInfo, CreditCard, LineItem) and establish relationships

This pattern MUST be replicated in the rebuild to ensure atomic creation of entire order graph.

### Pagination Semantics

Result sets use **absolute row positioning** via resultSet.absolute(startRow + 1):

1. Position cursor at requested row
2. Loop fetching up to count rows (checking hasNext after each)
3. Return Page(results, start, hasNext=more rows exist)

If start < 0 or positioning fails, return EMPTY_PAGE. Do NOT implement cursor-based or offset pagination.

### Message-Driven Async Processing

Orders and notifications flow through JMS queues and topics. Do NOT block on these operations. Queue messages for async processing and return immediately to client.

## Testing Strategy

### Unit Tests (Vitest)

- Entity model tests: CartItem, Page, ContactInfo
- Validation logic: username format, card validation, quantity checks
- Calculation logic: order totals, cart subtotals

### Integration Tests (Vitest + Testing Library)

- EJB facade methods and database operations
- Transaction semantics and atomicity
- JMS integration

### E2E Tests (Playwright)

- User workflows: Browse → Cart → Checkout → Confirmation
- Admin workflows: Login → Manage Orders
- Error paths: Invalid login, empty cart, payment decline

## Known Constraints

1. Pagination: If start is negative or beyond result set, return EMPTY_PAGE
2. Empty search: Empty query returns EMPTY_PAGE
3. Inventory shortage: Order remains PENDING (no BACKORDER status)
4. Session-based cart: No cross-session sharing
5. Email failures: Fire-and-forget model; no automatic retry

Detailed guidance available in the AGENTS.md and specification files for each capability.
