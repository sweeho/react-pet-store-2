# Shopping Cart - Specification Proposal

## Summary

This specification extracts the shopping cart capability from the legacy Java Pet Store application. The system maintains a customer's temporary collection of selected products using a stateful session EJB. Items are stored as a HashMap with quantities, enriched with real-time pricing and metadata from the catalog component on retrieval. The cart integrates with order placement to enforce non-empty validation and provides a JSP-based user interface for viewing, updating quantities, and removing items.

## Problem Statement

The legacy shopping cart system distributes cart management logic across EJB session beans, Struts action classes, JSP views, and event/exception classes. The contracts governing item storage, catalog integration, quantity updates, error handling, and user interface behavior are implicit in code and configuration rather than explicitly stated. This specification captures the cart contracts so the capability can be rebuilt with clear behavioral boundaries and verifiable acceptance criteria.

## Solution Overview

Shopping cart consists of:

- **ShoppingCart EJB**: Stateful session bean maintaining HashMap of itemId→quantity pairs
- **CartItem Model**: Value object representing a cart line item with item metadata and quantity
- **ShoppingCartModel**: Wrapper for collections of CartItems with aggregation methods
- **Catalog Integration**: Real-time item metadata retrieval at getItems() time
- **Quantity Updates**: Supports add, delete, update, and quantity-based removal
- **Cart Count**: Returns unique item count
- **Subtotal Calculation**: Sum of (unitCost × quantity) for all items
- **Locale Support**: Cart-wide locale parameter for catalog-aware pricing
- **Cart Screen**: JSP display with empty state, item list, quantity inputs, remove links
- **Order Integration**: Empty validation before order placement, auto-clear on success
- **Transactions**: Container-managed Required transactions for all operations
- **Authorization**: Unchecked access (no role-based restrictions)

## Key Behavioral Requirements

### Cart State and Storage

Cart is a stateful session EJB maintaining a HashMap<String, Integer> where:

- **Key**: itemId (String)
- **Value**: quantity (Integer)

No other data is stored in the cart. Prices and product metadata are **never** persisted in cart state—they are fetched from the catalog component at retrieval time (getItems()).

### Item Addition

Two methods supported:

- `addItem(String itemID)` — adds item with default quantity 1
- `addItem(String itemID, int qty)` — adds item with explicit quantity

Both methods store the itemID as key and quantity as Integer value in HashMap.

### Item Removal

- `deleteItem(String itemID)` — removes item from HashMap by key

### Quantity Updates

- `updateItemQuantity(String itemID, int newQty)` — updates or removes item
  - If newQty > 0: item is stored with new quantity
  - If newQty <= 0: item is removed from cart

Implementation:

1. Remove item first: cart.remove(itemID)
2. Conditionally re-add: if (newQty > 0) cart.put(itemID, new Integer(newQty))

### Item Retrieval

- `getItems()` — returns Collection of CartItem objects

Implementation:

1. Create CatalogHelper instance
2. For each (itemId, quantity) in HashMap:
   - Call catalog.getItem(itemId, locale) to fetch current metadata
   - Create CartItem with resolved metadata + stored quantity
   - If CatalogException: log to System.out and skip item (silent failure)
3. Return ArrayList of CartItems

This means cart displays current prices, not historical prices at time of addition.

### Cart Count

- `getCount()` — returns Integer representing unique item count
- Implementation: new Integer(cart.size())
- Empty cart returns Integer(0)

### Subtotal Calculation

- `getSubTotal()` — returns Double representing sum of line totals
- Calculation: SUM(unitCost × quantity for each CartItem)
- Implementation:
  1. getItems() to fetch CartItems with current pricing
  2. Iterate items and accumulate: ret += (unitCost \* quantity)
  3. Return new Double(ret)
  4. If items is null: return null (not 0.0)

### Clear Cart

- `empty()` — removes all items and resets cart to empty state
- Implementation: cart.clear()

### Locale Support

- `setLocale(Locale locale)` — sets cart locale for catalog lookups
- Default: Locale.US
- Used by getItems() when calling catalog.getItem(itemId, locale)
- Enables locale-specific pricing and product descriptions

### Cart Validation for Order

Before order placement, OrderEJBAction validates cart:

- If cart.getItems().size() == 0: throw ShoppingCartEmptyOrderException("Shopping cart is empty")
- If cart contains items: proceed with order creation
- On successful order: call cart.empty() to clear cart

### User Interface

cart.jsp displays:

- **Empty state**: "Your Shopping Cart is Empty." when cart.count == 0
- **Item list**:
  - Table with columns: attribute+name, Remove link, quantity input, unit cost
  - For each item: `<c:forEach var="item" items="${cart.items}">`
  - Quantity input: `<input name="itemQuantity_${item.itemId}" value="${item.quantity}">`
  - Unit cost formatted as currency: `<fmt:formatNumber type="currency" />`
- **Controls**:
  - Form action: cart.do, method: POST
  - Form field: `<input type="hidden" name="action" value="update">`
  - Submit button: "Update Cart"
  - Remove link for each item (href to cart.do with action=remove)
- **Subtotal**: Currency-formatted subtotal in row
- **Locale**: fmt:setLocale set to en_US

### Actions and Events

**CartHTMLAction** (Struts action):

- purchase action → CartEvent(ADD_ITEM, itemId)
- remove action → CartEvent(DELETE_ITEM, itemId)
- update action → parse itemQuantity\_\* parameters → CartEvent(UPDATE_ITEMS, HashMap)

**CartEJBAction** (EJB action):

- Switch on event.actionType
- ADD_ITEM → cart.addItem()
- DELETE_ITEM → cart.deleteItem()
- UPDATE_ITEMS → cart.updateItemQuantity() for each item
- EMPTY → cart.empty()

**CartEvent**:

- Static constants: ADD_ITEM=1, DELETE_ITEM=2, UPDATE_ITEMS=3, EMPTY=4
- Constructors for different payloads

## Implementation Scope

Includes:

- ✓ CartItem model with seven fields and getTotalCost()
- ✓ ShoppingCartModel wrapper with aggregation methods
- ✓ ShoppingCart stateful session EJB
- ✓ Add, delete, update, empty, get operations
- ✓ Cart count and subtotal calculations
- ✓ Locale support for catalog-aware pricing
- ✓ Catalog component integration with exception handling
- ✓ Container-managed Required transactions
- ✓ Unchecked authorization
- ✓ cart.jsp user interface
- ✓ CartHTMLAction and CartEJBAction integration
- ✓ ShoppingCartEmptyOrderException for order validation
- ✓ Auto-clear on successful order placement

Excludes:

- Cart persistence to database (session-scoped only)
- Wishlist or saved carts
- Cart sharing/collaboration
- Abandoned cart recovery
- Cart expiration policies
- Promotional codes or discount logic
- Gift certificates or store credit
- Shipping cost estimation
- Tax calculation
- Payment gateway integration
- Order history or cart analytics
- Recommendation engine integration
- Cart merge on login
- Multi-currency support beyond locale

## Implementation Considerations

### Stateful Session Bean

Cart is implemented as a stateful session EJB, maintaining state across multiple method calls within a single HTTP session. The container creates one EJB instance per session and garbage collects it when the session expires. No explicit database persistence is needed for session-scoped carts.

### HashMap Storage

Cart state is a simple HashMap where keys are itemIds and values are quantities. This allows O(1) lookups and modifications. No SQL or ORM is involved.

### Real-Time Pricing

Prices are never stored in cart state. When getItems() is called, it fetches current catalog pricing for each item. This means:

- Users see current prices (not historical prices at time of addition)
- If item price changes, cart reflects new price
- If item is removed from catalog, getItems() silently skips it (exception caught and logged)

This design simplifies cache invalidation but can lead to inconsistencies (cart stored 5 units at $10; item now $15).

### Catalog Component Dependency

Cart depends on CatalogHelper (or CatalogComponent) to fetch item metadata. If catalog lookup fails (CatalogException), the item is silently skipped from results with a System.out.println() log entry. No error is raised to the user.

### Error Handling

- **CatalogException**: Caught in getItems(), logged to System.out, item skipped (silent failure)
- **NumberFormatException in form**: Caught in CartHTMLAction, invalid quantity defaults to 0 (removes item)
- **ShoppingCartEmptyOrderException**: Thrown by OrderEJBAction, mapped to error screen

### Transaction Model

All operations (add, delete, update, empty, get, count, subtotal, setLocale) execute within Required transactions. The container manages transactional semantics—no explicit transaction code in the application.

### Session Binding

The cart EJB instance is bound to the HTTP session via PetstoreComponentManager or similar mechanism, keyed by a session attribute (e.g., PetstoreKeys.CART). JSP accesses it via `${cart}` expression language variable.

### Locale Propagation

Cart has a locale instance variable. When getItems() is called, it passes this locale to CatalogHelper.getItem(itemId, locale). Locale can be set via setLocale() and defaults to Locale.US.

## Success Criteria

Implementation is successful when:

1. CartItem persists itemId, productId, category, name, attribute, quantity, unitCost
2. ShoppingCartModel wraps CartItems and provides getTotalCost()
3. ShoppingCart EJB maintains HashMap<itemId, quantity>
4. addItem() adds item with default/explicit quantity
5. deleteItem() removes item from cart
6. updateItemQuantity() updates or removes based on quantity
7. getItems() returns CartItems with current catalog metadata
8. getCount() returns unique item count
9. getSubTotal() returns sum of (unitCost × quantity)
10. empty() removes all items
11. setLocale() enables locale-specific catalog lookups
12. Cart empty validation prevents order placement
13. cart.jsp displays cart items and controls
14. Quantity updates via form submission work correctly
15. All operations execute within Required transactions
16. All methods accessible without authorization checks
17. Cart state persists across multiple requests within session
18. Catalog integration fetches real-time prices
19. CatalogException handling (silently skip item)
20. All acceptance criteria scenarios pass without behavioral regression

## Assumptions and Constraints

- Cart is session-scoped (HTTP session lifetime)
- No database persistence for cart state
- HashMap implementation (O(1) lookups)
- Prices are fetched at retrieval time (not cached in cart)
- Catalog component is available and provides getItem(itemId, locale)
- One stateful EJB instance per session (no sharing between sessions)
- Servlet container ensures single-threaded access per session
- Locale parameter is valid per java.util.Locale
- ItemId is unique identifier (no duplicate handling)
- Quantity is stored as Integer (no decimal quantities)
- Subtotal is computed as sum of line totals (no rounding or tax)
- Form submission includes itemQuantity\_<itemId> parameters

## Open Questions for Business Clarification

1. Should cart persist to database for multi-session recovery?
2. Should cart expiration timeout be shorter than session timeout?
3. Should invalid catalog lookups raise an error or silently skip items?
4. Should cart merger occur when a guest customer logs in?
5. Should cart contain historical prices (at add time) or current prices?
6. Should abandoned carts be recovered or deleted?
7. Should cart limit quantity per item (e.g., max 99)?
8. Should cart enforce inventory checks (prevent overselling)?
9. Should discount codes be applied at cart or order time?
10. Should shipping cost be estimated in cart or order?
