# Shopping Cart - Design Document

## Overview

The shopping cart system manages a customer's temporary collection of products selected for purchase. Implemented as a stateful session EJB, the cart maintains a HashMap of items (keyed by itemId with quantity as value), resolves item metadata from the catalog component on retrieval, and supports standard collection operations (add, remove, update, count, subtotal, clear). The cart integrates with order placement to enforce non-empty validation and automatic clearing on successful order creation.

## Architecture

### Data Model

#### ShoppingCart EJB (Stateful Session Bean)

Implemented by ShoppingCartLocalEJB with container-managed transactions. Declares ShoppingCartLocal interface with eight public methods:

- `void addItem(String itemID)` - Add item with default quantity 1
- `void addItem(String itemID, int qty)` - Add item with explicit quantity (overload)
- `void deleteItem(String itemID)` - Remove item from cart
- `void updateItemQuantity(String itemID, int newQty)` - Update or remove item
- `Collection getItems()` - Return CartItems with current catalog metadata
- `Integer getCount()` - Return unique item count
- `Double getSubTotal()` - Return sum of (unitCost × quantity)
- `void empty()` - Clear all items
- `void setLocale(Locale locale)` - Set locale for catalog lookups

**Internal state:**

- `HashMap<String, Integer> cart` - Maps itemId to quantity
- `Locale locale` - Default Locale.US

**Initialization:** Constructor creates empty HashMap, sets locale to Locale.US.

#### CartItem Model

Value object representing a line item in the cart. Fields:

- `String itemId` - Item identifier (from catalog)
- `String productId` - Parent product identifier
- `String category` - Category identifier
- `String name` - Product name (localized, from catalog)
- `String attribute` - Product attribute (e.g., color, size)
- `int quantity` - Quantity in cart (from cart state, not catalog)
- `double unitCost` - Unit cost (from catalog)

Constructor accepts all seven parameters in order. Implements `getTotalCost()` returning `quantity * unitCost`.

#### ShoppingCartModel

Wrapper value object for collections of CartItems:

- `Collection items` - List of CartItems
- `getSize()` - Returns items.size() or 0 if null
- `getItems()` - Returns iterator over items
- `getTotalCost()` - Sums all CartItem.getTotalCost()

### State Management

Cart state is stored in a HashMap where:

- **Key**: itemId (String)
- **Value**: quantity (Integer)

When getItems() is called:

1. For each (itemId, quantity) pair in HashMap
2. Call `CatalogHelper.getItem(itemId, locale)` to fetch current catalog metadata
3. Create CartItem with resolved metadata + stored quantity
4. Collect into ArrayList and return

This means **prices are never stored in cart state** — they are fetched at retrieval time, allowing real-time price updates.

### Integration with Catalog Component

When getItems() is called, it retrieves item metadata (product name, pricing, attributes) from the catalog component via CatalogHelper. If CatalogException occurs during lookup, the exception is caught and logged to System.out (item silently skipped from results, cart state inconsistency may result).

### Integration with Order Component

When OrderEJBAction attempts order creation:

1. Calls `cart.getItems()` to retrieve current items
2. Validates `items.size() != 0`, throws ShoppingCartEmptyOrderException if empty
3. Iterates items to create purchase order line items and calculate total
4. On successful order creation, calls `cart.empty()` to clear cart

### Transaction Model

**Container-Managed Transactions:**

All methods (add, delete, update, empty, get, count, subtotal, setLocale) declare trans-attribute=Required in ejb-jar.xml. Container automatically:

- Creates new transaction if one doesn't exist
- Joins existing transaction if one does
- Commits on successful return
- Rolls back on exception

No explicit transaction code in application.

### Authorization Model

All methods are declared with unchecked permission in ejb-jar.xml (method-permission with unchecked element for ShoppingCartEJB, method-name="\*"). No role-based access control.

### Session Management

The ShoppingCart EJB instance is stored in HTTP session via PetstoreComponentManager, keyed by PetstoreKeys.CART or similar. Session binding ensures:

- One cart instance per user session
- Cart state persists across multiple requests within session
- Cart is garbage collected when session expires

JSP accesses cart via `${cart}` expression language variable, which is bound to request scope by servlet action.

### Locale Support

Cart has a locale instance variable (default Locale.US). When getItems() is called, this locale is passed to CatalogHelper.getItem(itemId, locale), enabling locale-specific pricing and product descriptions.

### Error Handling

- **CatalogException in getItems()**: Caught and logged to System.out; item skipped from results (silent failure, potential inconsistency)
- **NumberFormatException in form submission**: Caught in CartHTMLAction; invalid quantity defaults to 0 (removes item)
- **ShoppingCartEmptyOrderException**: Thrown by OrderEJBAction when cart is empty at order time; mapped to error screen

### Screen Implementation

**cart.jsp** (lines 42-115):

- Detects empty state via `<c:when test="${cart.count == 0}">`
- Displays "Your Shopping Cart is Empty." if count is 0
- For populated carts:
  - Form action: "cart.do", input type="hidden" name="action" value="update"
  - Iterates items via `<c:forEach var="item" items="${cart.items}">`
  - For each item:
    - Displays attribute + name as link
    - "Remove" link (href to cart.do with action=remove)
    - Quantity input: `<input name="itemQuantity_${item.itemId}" value="${item.quantity}">`
    - Unit cost: `<fmt:formatNumber value="${item.unitCost}" type="currency" />`
  - Subtotal row: `<fmt:formatNumber value="${cart.subTotal}" type="currency" />`
  - Submit button: `<input type="submit" value="Update Cart">`

Form submission with action=update triggers CartHTMLAction to parse itemQuantity\_\* parameters and call updateItemQuantity() for each item.

### CartEvent and Actions

**CartEvent** (CartEvent.java):

- Static constants: ADD_ITEM=1, DELETE_ITEM=2, UPDATE_ITEMS=3, EMPTY=4
- Constructors:
  - `CartEvent(int actionType)` - For EMPTY
  - `CartEvent(int actionType, String itemId)` - For ADD_ITEM, DELETE_ITEM
  - `CartEvent(int actionType, String itemId, int quantity)` - For ADD_ITEM with qty
  - `CartEvent(int actionType, HashMap items)` - For UPDATE_ITEMS (multiple)

**CartHTMLAction** (Struts action):

- Maps HTTP parameters to CartEvent
- purchase action → ADD_ITEM event
- remove action → DELETE_ITEM event
- update action → parses itemQuantity\_\* parameters, creates UPDATE_ITEMS event

**CartEJBAction** (EJB action):

- Switch on CartEvent.actionType
- ADD_ITEM → cart.addItem()
- DELETE_ITEM → cart.deleteItem()
- UPDATE_ITEMS → cart.updateItemQuantity() for each item
- EMPTY → cart.empty()

## Financial Calculations

### Subtotal Calculation

```
subtotal = SUM(cart item for each item in cart: item.unitCost * item.quantity)
```

Implemented in ShoppingCartLocalEJB.getSubTotal():

```java
double ret = 0.0d;
for (Iterator it = items.iterator(); it.hasNext(); ) {
    CartItem i = (CartItem) it.next();
    ret += (i.getUnitCost() * i.getQuantity());
}
return new Double(ret);
```

No rounding, tax, or surcharges applied at cart layer. Used in cart.jsp with fmt:formatNumber for currency display.

### Line Item Total

```
line total = unitCost * quantity
```

Calculated by CartItem.getTotalCost() returning `quantity * unitCost`.

## Edge Cases and Constraints

- **Empty cart subtotal**: Returns null (not 0.0)
- **Catalog lookup failure**: Item silently skipped from getItems() result
- **Invalid quantity input**: NumberFormatException defaults to 0 (removes item)
- **Quantity <= 0**: updateItemQuantity removes item from cart
- **Session expiration**: Cart instance garbage collected
- **Concurrent requests**: Stateful EJB assumes single-threaded access per session (servlet container guarantees this)

## Legacy Implementation Notes

- EJB 2.x stateful session bean
- J2EE connection pooling via JNDI DataSource (CatalogHelper uses ServiceLocator)
- Struts MVC with action beans
- JSP with JSTL and fmt tags for currency formatting
- HashMap for internal storage (not a database)
- Exception handling relies on System.out.println for logging
