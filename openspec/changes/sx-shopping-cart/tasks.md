## 1. CartItem Model

- [ ] 1.1 Implement CartItem class with seven fields: itemId, productId, category, name, attribute, quantity, unitCost
- [ ] 1.2 Implement CartItem constructor accepting all seven parameters in defined order
- [ ] 1.3 Implement CartItem getters: getItemId(), getProductId(), getCategory(), getName(), getAttribute(), getQuantity(), getUnitCost()
- [ ] 1.4 Implement CartItem.getTotalCost() returning quantity \* unitCost
- [ ] 1.5 Ensure CartItem implements Serializable interface

## 2. ShoppingCartModel Wrapper

- [ ] 2.1 Implement ShoppingCartModel class wrapping a Collection of CartItems
- [ ] 2.2 Implement getSize() returning items.size() or 0 if null
- [ ] 2.3 Implement getItems() returning iterator over items collection
- [ ] 2.4 Implement getTotalCost() summing CartItem.getTotalCost() for all items
- [ ] 2.5 Ensure ShoppingCartModel implements Serializable interface

## 3. ShoppingCart EJB Interface and Implementation

- [ ] 3.1 Define ShoppingCartLocal interface with eight public methods
- [ ] 3.2 Implement ShoppingCartLocalEJB as stateful session bean
- [ ] 3.3 Declare ShoppingCartLocalHome interface with create() method
- [ ] 3.4 Implement instance variable: HashMap<String, Integer> cart
- [ ] 3.5 Implement instance variable: Locale locale (default Locale.US)
- [ ] 3.6 Implement constructor initializing cart = new HashMap() and locale = Locale.US

## 4. Add Item Operations

- [ ] 4.1 Implement addItem(String itemID) adding item with default quantity 1
- [ ] 4.2 Implement addItem(String itemID, int qty) adding item with explicit quantity
- [ ] 4.3 Verify both overloads store itemID as key and quantity as Integer value in HashMap

## 5. Delete Item Operation

- [ ] 5.1 Implement deleteItem(String itemID) calling cart.remove(itemID)
- [ ] 5.2 Test deletion of existing and non-existing items

## 6. Update Item Quantity Operation

- [ ] 6.1 Implement updateItemQuantity(String itemID, int newQty)
- [ ] 6.2 Remove item first from cart via cart.remove(itemID)
- [ ] 6.3 Conditionally re-add only if newQty > 0: cart.put(itemID, new Integer(newQty))
- [ ] 6.4 Test removal when newQty <= 0
- [ ] 6.5 Test update when newQty > 0

## 7. Retrieve Cart Items

- [ ] 7.1 Implement getItems() creating CatalogHelper instance
- [ ] 7.2 Retrieve internal cart state via getDetails() method
- [ ] 7.3 Iterate cart HashMap entries (itemId, quantity pairs)
- [ ] 7.4 For each itemId, call catalog.getItem(itemId, locale) to fetch metadata
- [ ] 7.5 Create CartItem with resolved metadata and stored quantity
- [ ] 7.6 Catch CatalogException and log to System.out (skip item on error)
- [ ] 7.7 Collect CartItems into ArrayList and return as Collection

## 8. Cart Count Operation

- [ ] 8.1 Implement getCount() returning new Integer(cart.size())
- [ ] 8.2 Test count returns 0 for empty cart
- [ ] 8.3 Test count reflects unique item count after additions/deletions

## 9. Cart Subtotal Calculation

- [ ] 9.1 Implement getSubTotal() retrieving items via getItems()
- [ ] 9.2 Check if items collection is null and return null
- [ ] 9.3 Initialize accumulator: double ret = 0.0d
- [ ] 9.4 Iterate items and accumulate: ret += (item.getUnitCost() \* item.getQuantity())
- [ ] 9.5 Return new Double(ret) as result
- [ ] 9.6 Test subtotal calculation with multiple items
- [ ] 9.7 Test subtotal returns null for empty/null cart

## 10. Empty Cart Operation

- [ ] 10.1 Implement empty() calling cart.clear()
- [ ] 10.2 Test cart becomes empty after operation

## 11. Locale Support

- [ ] 11.1 Implement setLocale(Locale locale) storing locale in instance variable
- [ ] 11.2 Verify getItems() uses this.locale when calling catalog.getItem()
- [ ] 11.3 Test default locale is Locale.US
- [ ] 11.4 Test locale-specific catalog lookups

## 12. EJB Configuration

- [ ] 12.1 Declare ShoppingCartEJB in ejb-jar.xml with session-type=Stateful
- [ ] 12.2 Declare transaction-type=Container in ejb-jar.xml
- [ ] 12.3 Declare ShoppingCartLocal interface (local-home, local elements)
- [ ] 12.4 Declare ShoppingCartLocalHome interface (create() method)
- [ ] 12.5 Map all eight methods to container-transaction with trans-attribute=Required
- [ ] 12.6 Declare method-permission with unchecked element for ShoppingCartEJB (method-name=\*)
- [ ] 12.7 Verify all method-intf="Local" declarations
- [ ] 12.8 Verify method-params types match ShoppingCartLocal interface signatures

## 13. Transaction Management

- [ ] 13.1 Verify all container-transaction declarations are present for all eight methods
- [ ] 13.2 Test transaction rollback behavior on CatalogException
- [ ] 13.3 Test transaction atomicity: all or nothing on cart mutation
- [ ] 13.4 Test concurrent transaction isolation

## 14. Authorization and Access Control

- [ ] 14.1 Verify no role-based method-permission entries (only unchecked)
- [ ] 14.2 Verify method-name=\* applies unchecked to all methods on ShoppingCartEJB
- [ ] 14.3 Test that unauthenticated callers can invoke all methods
- [ ] 14.4 Test that callers without specific roles can invoke all methods

## 15. CartEvent and Actions

- [ ] 15.1 Implement CartEvent class with static constants: ADD_ITEM=1, DELETE_ITEM=2, UPDATE_ITEMS=3, EMPTY=4
- [ ] 15.2 Implement CartEvent constructors for single item, single item with quantity, multiple items (HashMap)
- [ ] 15.3 Implement CartHTMLAction to map HTTP parameters to CartEvent
- [ ] 15.4 Implement CartEJBAction to dispatch CartEvent to cart methods via switch statement
- [ ] 15.5 Test ADD_ITEM event calls addItem()
- [ ] 15.6 Test DELETE_ITEM event calls deleteItem()
- [ ] 15.7 Test UPDATE_ITEMS event calls updateItemQuantity() for each item

## 16. Cart Screen Display

- [ ] 16.1 Create/verify cart.jsp displays cart items and controls
- [ ] 16.2 Implement empty cart message: "Your Shopping Cart is Empty."
- [ ] 16.3 Implement populated cart display:
- [ ] 16.4 For each item: display attribute + name, quantity input (itemQuantity\_<itemId>), unit cost (currency format)
- [ ] 16.5 Implement "Remove" link for each item
- [ ] 16.6 Implement "Update Cart" submit button
- [ ] 16.7 Implement cart subtotal row in currency format
- [ ] 16.8 Implement form: action=cart.do, input type=hidden name=action value=update
- [ ] 16.9 Test empty cart state displays correct message
- [ ] 16.10 Test populated cart displays all items with controls
- [ ] 16.11 Test currency formatting of unit cost and subtotal

## 17. Empty Cart Validation for Order

- [ ] 17.1 Implement ShoppingCartEmptyOrderException class extending EventException
- [ ] 17.2 Implement OrderEJBAction validation: if (items.size() == 0) throw ShoppingCartEmptyOrderException("Shopping cart is empty")
- [ ] 17.3 Map exception to error screen via mappings.xml
- [ ] 17.4 Test exception is thrown when cart is empty at order time
- [ ] 17.5 Test exception message is "Shopping cart is empty"

## 18. Cart Clearing on Order Success

- [ ] 18.1 Verify OrderEJBAction calls cart.empty() after successful order creation
- [ ] 18.2 Test cart is cleared after order is persisted
- [ ] 18.3 Test cart.empty() removes all items

## 19. Integration with Catalog Component

- [ ] 19.1 Test CatalogHelper.getItem() is called for each cart item
- [ ] 19.2 Test catalog metadata (name, pricing, attributes) is resolved at retrieval time
- [ ] 19.3 Test locale is passed to catalog lookups
- [ ] 19.4 Test CatalogException is caught and logged
- [ ] 19.5 Test missing catalog items are skipped (item silently omitted from results)

## 20. Session Management

- [ ] 20.1 Verify cart EJB instance is stored in HTTP session
- [ ] 20.2 Verify session key binding (e.g., PetstoreKeys.CART)
- [ ] 20.3 Test cart state persists across multiple requests within session
- [ ] 20.4 Test cart is garbage collected when session expires
- [ ] 20.5 Test ${cart} expression language access in JSP

## 21. Error Handling

- [ ] 21.1 Test CatalogException handling: exception logged, item skipped
- [ ] 21.2 Test NumberFormatException in form submission: invalid quantity defaults to 0
- [ ] 21.3 Test exception propagation for database/transaction failures
- [ ] 21.4 Test cart state consistency after exceptions

## 22. Financial Calculations and Edge Cases

- [ ] 22.1 Test subtotal calculation accuracy with multiple items
- [ ] 22.2 Test line item total: getTotalCost() = quantity \* unitCost
- [ ] 22.3 Test subtotal with decimal prices (10.50, 5.00, etc.)
- [ ] 22.4 Test quantity <= 0 removes item via updateItemQuantity()
- [ ] 22.5 Test empty cart returns subtotal=null
- [ ] 22.6 Test cart.count reflects unique items (not total quantity)

## 23. State Consistency

- [ ] 23.1 Test cart state is HashMap<itemId, quantity>
- [ ] 23.2 Test prices are not stored in cart (fetched at retrieval time)
- [ ] 23.3 Test cart can handle missing catalog items gracefully
- [ ] 23.4 Test concurrent modifications within transaction
