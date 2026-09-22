# React Pet Store 2 Migration

_PRD v9 · approved 2026-09-22 · by sweeho@gmail.com. Published from the Design Workbench — edit it there, not here._

## Summary

React Pet Store is an online pet shop where customers find and purchase pets, orders are reviewed and approved based on risk rules, inventory is coordinated with suppliers, and status updates are delivered via email at every stage. The system comprises four independent applications: a customer-facing storefront, an order processing center, an administrative review interface, and a supplier inventory application.

The architecture is deliberately asynchronous — no customer waits for approval, stock matching, or supplier coordination. A customer submits an order and receives a confirmation immediately; the Order Processing Centre routes it through review and fulfillment workflows in the background, with email keeping the customer informed at each transition.

This specification captures what the existing Java Pet Store 1.3.2 system does, extracted from its source code and documentation. It serves as a baseline for modernization to React and contemporary web standards.

## Context

The Java Pet Store is a reference implementation that has shaped Java web application architecture for two decades. It demonstrates patterns for:

- Separating consumer, admin, and supplier workflows with role-specific interfaces
- Asynchronous order processing without losing durability
- Multi-locale content management at the catalogue level
- Scaling approval workflows independently from customer ordering

The system currently runs on J2EE/EJB technologies (Struts, entity beans, JDBC) with three tiers of deployment. This migration modernizes the runtime to React + Vite frontend with Nitro backend, while preserving the four-application architecture and the asynchronous patterns that allow the system to stay responsive even when downstream components (review queue, supplier) are slow.

## Goals

1. Provide customers a fast, responsive shopping experience where they can browse, search, add to cart, and order without signing in until checkout — no friction before purchase.

2. Hold high-value orders ($500+) for human review while auto-approving lower-value orders, so review effort scales with business risk rather than transaction volume.

3. Complete orders automatically as soon as all items are in stock, with no additional human intervention needed once approved.

4. Keep customers informed at every status change — pending review, approval, denial, or completion — via email, so they need not visit the site to check progress.

5. Serve the storefront in three languages (English, Japanese, Chinese) with translated catalogue content, not just interface labels, so customers shop in their own language.

6. Give administrators visibility into sales performance by category and date range, with no export or multi-dimensional analysis needed.

7. Keep the system resilient to delays in any component: the approval queue, the supplier inventory system, or email delivery should never block customers from ordering.

## Non-goals

- Real payment processing: Card details are stored and displayed but never authorized or charged.
- Customer order history: The confirmation number is the only record provided to the customer.
- Shipment tracking: Completion is the final status; there is nothing after it.
- Returns, refunds, or cancellations: Orders cannot be modified once submitted.
- Customer-facing stock levels: Availability is checked after ordering, never shown beforehand.
- Self-service password reset: No recovery path exists for a lost password.
- Multiple suppliers or sourcing logic: One supplier fills all orders.
- Mobile or responsive design: The UI is built for desktop widths.

## Users

Three distinct user roles, each with a separate interface and no functional overlap:

### Shopper

Browses the catalogue, searches for specific pets, manages their shopping cart and account, and places orders. Willing to create an account to complete a purchase but unwilling to create one just to look. Works entirely in the storefront web application. Can only view and modify their own account data. Depends on email for all order status updates after checkout.

### Administrator

Reviews orders flagged for approval (those $500 and above) and decides whether the store honors them. Works in batches, staging multiple decisions before committing them together. Can also view sales reports by category and date range. Works in a desktop admin application. Cannot create, edit, or delete any data — only approve or deny pending orders and query reports.

### Supplier Staff

Maintains current inventory quantities in the supplier system. Their inventory updates trigger the Order Processing Centre to re-evaluate approved orders that were waiting on stock, and complete any that can now be filled. Works in the supplier web application. Receives no customer information, only line items needing fulfillment.

Administrator and supplier sessions are mutually exclusive in one browser: a person holding both roles must sign out of one before using the other.

## User journeys

### Shopper: Browse and purchase without signing in

1. **Home** — Customer enters storefront and sees category image map.
2. **Category listing** — Customer selects a category (Birds, Cats, Dogs, Fish, or Reptiles) and sees products in that category.
3. **Product listing** — Customer selects a product (e.g., Bulldog) and sees items within it (e.g., Male Adult Bulldog, Female Adult Bulldog).
4. **Item detail** — Customer views a specific item with image, description, list price, and customer price.
5. **Add to cart** — Customer adds item to cart; cart quantity updates if item already present.
6. **Shopping cart** — Customer reviews items, adjusts quantities, and reviews subtotal.
7. **Checkout** — Customer is prompted to sign in or create an account, then fills checkout form with billing and shipping addresses (pre-filled from account if available).
8. **Order confirmation** — Customer receives order number and confirmation email address on screen.
9. Email notification (background) — Customer receives email confirming order submission.

### Shopper: Search for a pet

1. **Home or any page** — Customer enters one or more keywords in the banner search box.
2. **Search results** — Results show matching items with description, price, and add-to-cart action.
3. **Add to cart** — Customer adds item directly from results.
4. **Shopping cart** — Customer proceeds to checkout.

### Shopper: Manage account

1. **Account overview** — Customer views contact details, card on file, and profile preferences.
2. **Edit account** — Customer changes contact, card (not username), and preferences (language, favorite category, MyList and pet tips toggles).
3. **Change language** — Customer clicks flag icon to switch language for the session, or saves preference to account.

### Administrator: Review pending orders

1. **Admin client opens** — Admin application launches via Java Web Start and displays pending order queue.
2. **Process Pending Orders tab** — Shows all orders $500 or more waiting for decision.
3. **Select and decide** — Admin clicks a row, selects Approved or Denied from the Status cell, and repeats for as many orders as needed.
4. **Commit** — Admin clicks Commit to send all decisions to the server at once.
5. Email notification (background) — Each approved order triggers fulfillment; each denied order cancels the transaction.

### Administrator: View sales by category

1. **Admin client, Sales tab** — Admin navigates to sales reporting.
2. **Set date range** — Admin enters Start Date and End Date (format validated per locale).
3. **Pie Chart tab** — Shows each category's percentage of total sales.
4. **Bar Chart tab** — Shows order count per category for volume comparison.

### Supplier: Update inventory and release backlog

1. **Supplier app** — Supplier staff signs in and selects Display Inventory.
2. **Inventory table** — Lists every item with current quantity, a New Quantity input, and an Update checkbox.
3. **Edit quantities** — Staff enters new quantities and checks the Update checkbox for each row to be changed.
4. **Submit** — Only checked rows are saved; unchecked rows are ignored.
5. Background processing — OPC re-evaluates all approved orders against new stock and completes any that can now be fulfilled.
6. Email notification — Customers receive emails for any orders that transitioned to Completed.

## Capability map

- **Product catalog** — Product master data management, category hierarchy, search, and read-only access patterns for storefront.
- **Shopping cart** — Shopping cart state management, item addition/removal, quantity tracking, and session persistence.
- **Order placement** — Order creation, validation, line-item assembly, and checkout workflow.
- **Payment processing** — Credit card storage, validation, and storage (no real authorization or charging).
- **Customer management** — Customer account creation, profile data, contact information, and preferences.
- **Authentication & authorization** — User login, session management, role-based access control, and sign-on.
- **Order fulfillment** — Order state machine, processing workflows, supplier coordination, and status tracking.
- **Supplier management** — Supplier portal, PO management, inventory coordination, and B2B inventory updates.
- **Notifications & messaging** — Email alerts, asynchronous message delivery, and event-driven notification.
- **Admin operations** — System administration interface, order review queues, and sales reporting.
- **Multi-locale support** — Content translation, language switching, locale-specific formatting and preferences.

## Screens

### Storefront screens

1. **Home** — Category image map and introduction to shopping.
2. **Category listing** — List of products within a selected category, with paging.
3. **Product listing** — List of items within a selected product, with paging.
4. **Item detail** — Full item page with image, description, prices, and add-to-cart.
5. **Search results** — List of items matching search keywords, with paging that preserves keywords.
6. **Shopping cart** — Current items with quantities, subtotal, and checkout button.
7. **Sign in** — Returning customer sign-in and new account creation form.
8. **Create/edit account** — Capture and edit contact, card, and profile preferences.
9. **Checkout** — Billing and shipping address form, pre-filled from account.
10. **Order confirmation** — Order number and confirmation email address.
11. **Account overview** — Read-only view of contact, card, and preferences.

### Administrator screens

1. **Admin — order review** — Pending orders table (sortable by order number, customer, date, amount, status) and decided orders table.
2. **Admin — sales reporting** — Pie chart and bar chart of sales by category, driven by start and end date inputs.

### Supplier screens

1. **Supplier — inventory** — Table of all items with current quantity, new quantity input, and per-row update checkbox.

## Constraints and assumptions

### Constraints

- Approval threshold is a single fixed value ($500) applied to order total, not per line or per category, and not configurable at deploy time.
- Admin client is a desktop application launched via Java Web Start; requires a Java runtime and cannot be used from unmanaged machines.
- Admin and supplier applications cannot both be signed in to the same browser session; a person holding both roles must sign out and back in.
- The UI layout is fixed-width for desktop; no responsive mobile design.
- Catalogue reference data is fixed at five categories (Birds, Cats, Dogs, Fish, Reptiles); adding a category requires content and image-map changes.
- A second approval threshold exists in the code ($50,000) but has no behavior attached; all review effectively happens at the $500 level.

### Assumptions

- One supplier fills every order; there is no sourcing decision or multiple-supplier logic.
- Every item has a single price in a single currency, formatted per locale but never converted.
- Customers accept email as the only post-order status channel.
- Administrators work through approval queues in batches rather than one order at a time.
- Recorded inventory is accurate because supplier staff maintain it; there is no reconciliation against physical stock.
- The catalogue is small enough that five categories fit in a sidebar and a five-way image map.

### Explicitly stubbed (not production-ready)

These features are implemented as placeholders and must be built for real before production use:

- **Payment processing** — Card details are captured and stored; no authorization, no charge, and no decline path.
- **Shipping** — No carrier, no rates, no tracking; "Completed" means the supplier said so.
- **Tax** — Never calculated; order total is the sum of line items.
- **Fraud and credit checks** — The $500 rule is the entire risk model.
- **Stock reservation** — Nothing is held at order time, so concurrent orders for the same item are both accepted and resolved only later in whatever order the OPC processes them.

## Open questions

1. Should the approval threshold remain a single order-total rule, or become a rule set that can also consider customer age, destination, and item category?

2. Should back-ordered orders (Approved but waiting on stock) become a distinct status, or remain Approved with a separate stock indicator?

3. How long may an approved order wait on stock before it is escalated, cancelled, or automatically denied?

4. Should customers see availability or stock levels before ordering, given that this couples the storefront to supplier data, which the current design deliberately avoids?

5. Should the admin review interface remain a desktop application, or move to the browser?

6. Should prices be locale-specific, or remain one global price formatted per locale?

7. Who owns reconciling recorded inventory against physical stock, and how often?

8. Should customers be able to cancel or refund orders, and if so, at what order statuses?

Questions 1 and 2 are worth settling first — both change the order lifecycle, and the rest can be built on top of whatever they decide.

## Sources

- **design/sources/markdown/java-pet-store-1-3-2-product-requirements-document/extracted.md** — Java Pet Store 1.3.2 PRD, functional and non-functional requirements, data model, assumptions, constraints, open questions.
- **design/sources/markdown/java-pet-store-1-3-2-user-manual/extracted.md** — User manual covering storefront, admin, and supplier workflows, screen descriptions, error handling, and reference material.
- **design/sources/html/java-pet-store-screen-mockups/extracted.md** — Screen mockup list and layout specifications for all three applications.
- **legacy-analysis/discovery/report.md** — Discovery report on Java Pet Store 1.3.2 architecture, component breakdown, patterns, and risk assessment.
- **legacy-analysis/discovery/capabilities.csv** — Extracted capability list mapping system components to functional areas.
