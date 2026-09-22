## ADDED Requirements

### Requirement: Shopping cart entity model

The system SHALL maintain a shopping cart as a stateful session object containing a collection of cart items, each identified by an itemId and tracked with a quantity and unit cost.

#### Scenario: Cart stores items with quantities

- **GIVEN** an empty shopping cart
- **WHEN** an item with itemId "ITEM-001" and unitCost 10.50 is added with quantity 3
- **THEN** the cart contains one item with quantity 3 and unit cost 10.50

### Requirement: Cart item entity

A CartItem entity SHALL store individual line items within a shopping cart, holding references to: item identifier, product identifier, category, product name, item attribute, quantity, and unit cost.

#### Scenario: CartItem contains all required fields

- **GIVEN** a CartItem for itemId "ITEM-001"
- **WHEN** the CartItem is created with productId "PROD-001", category "FISH", name "Angelfish", attribute "Small", quantity 2, unitCost 10.50
- **THEN** all seven fields are accessible: getItemId(), getProductId(), getCategory(), getName(), getAttribute(), getQuantity(), getUnitCost()

### Requirement: Add item to cart

The system SHALL provide an addItem operation that adds an item to the shopping cart. When an item is added without an explicit quantity, the default quantity SHALL be 1. The operation accepts an itemId as a parameter.

#### Scenario: Item is added with default quantity

- **GIVEN** an empty shopping cart
- **WHEN** addItem("ITEM-001") is called
- **THEN** the item is added to the cart with quantity 1

#### Scenario: Item is added with explicit quantity

- **GIVEN** an empty shopping cart
- **WHEN** addItem("ITEM-001", 5) is called
- **THEN** the item is added to the cart with quantity 5

### Requirement: Delete item from cart

The system SHALL provide a deleteItem operation that removes an item from the shopping cart. The operation accepts an itemId as a parameter.

#### Scenario: Item is removed from cart

- **GIVEN** a cart containing an item with itemId "ITEM-001"
- **WHEN** deleteItem("ITEM-001") is called
- **THEN** the item is removed from the cart

### Requirement: Update cart item quantity

The system SHALL provide an updateItemQuantity operation that updates the quantity of an item in the shopping cart. The operation accepts an itemId and a new quantity value. If the new quantity is less than or equal to 0, the item SHALL be removed from the cart. If the new quantity is greater than 0, the item SHALL be stored with the new quantity.

#### Scenario: Item quantity is updated to positive value

- **GIVEN** a cart containing an item with itemId "ITEM-001" and current quantity 3
- **WHEN** updateItemQuantity("ITEM-001", 5) is called
- **THEN** the item quantity is updated to 5

#### Scenario: Item is removed when quantity is set to zero

- **GIVEN** a cart containing an item with itemId "ITEM-001" and current quantity 3
- **WHEN** updateItemQuantity("ITEM-001", 0) is called
- **THEN** the item is removed from the cart

#### Scenario: Item is removed when quantity is set to negative

- **GIVEN** a cart containing an item with itemId "ITEM-001" and current quantity 3
- **WHEN** updateItemQuantity("ITEM-001", -1) is called
- **THEN** the item is removed from the cart

### Requirement: Retrieve cart items

The system SHALL provide a getItems operation that returns a collection of all CartItem objects currently in the shopping cart. Each CartItem contains the itemId, productId, category, name, attribute, quantity, and unitCost. The cart SHALL resolve item metadata from the catalog component.

#### Scenario: Cart returns all items with current metadata

- **GIVEN** a cart containing two items: ITEM-001 (quantity 2) and ITEM-002 (quantity 1)
- **WHEN** getItems() is called
- **THEN** a collection of two CartItem objects is returned, each with itemId, productId, category, name, attribute, quantity, and unitCost populated from the catalog

### Requirement: Get cart item count

The system SHALL provide a getCount operation that returns an Integer representing the number of unique items currently in the shopping cart.

#### Scenario: Cart count reflects number of unique items

- **GIVEN** a cart containing three distinct items
- **WHEN** getCount() is called
- **THEN** the method returns Integer(3)

#### Scenario: Empty cart returns zero count

- **GIVEN** an empty shopping cart
- **WHEN** getCount() is called
- **THEN** the method returns Integer(0)

### Requirement: Calculate cart subtotal

The system SHALL provide a getSubTotal operation that returns a Double representing the sum of all cart item line totals. Each line total is calculated as unit cost × quantity. If the cart is empty or null, the operation SHALL return null.

#### Scenario: Subtotal is sum of item line totals

- **GIVEN** a cart containing two items: ITEM-001 (quantity 2, unitCost 10.50) and ITEM-002 (quantity 3, unitCost 5.00)
- **WHEN** getSubTotal() is called
- **THEN** the method returns Double(36.00): (2 _ 10.50) + (3 _ 5.00)

#### Scenario: Empty cart subtotal returns null

- **GIVEN** an empty shopping cart
- **WHEN** getSubTotal() is called
- **THEN** the method returns null

### Requirement: Clear shopping cart

The system SHALL provide an empty operation that removes all items from the shopping cart. This operation takes no parameters and clears the cart state.

#### Scenario: All items removed from cart

- **GIVEN** a cart containing three items
- **WHEN** empty() is called
- **THEN** the cart contains zero items

### Requirement: Set cart locale

The system SHALL support setting a locale for the shopping cart, defaulting to Locale.US. The locale is used when retrieving item details from the catalog component. The setLocale operation accepts a Locale parameter.

#### Scenario: Locale is set for catalog lookups

- **GIVEN** a shopping cart with default locale Locale.US
- **WHEN** setLocale(Locale("en_GB")) is called
- **THEN** subsequent getItems() calls retrieve item details for the en_GB locale

### Requirement: Calculate line item total cost

The system SHALL calculate the total cost of a cart item as the product of its unit cost and quantity. GIVEN a cart item with unitCost=10.50 and quantity=3, WHEN getTotalCost is called, THEN the result SHALL be 31.50.

#### Scenario: Line item total is quantity times unit cost

- **GIVEN** a CartItem with unitCost 10.50 and quantity 3
- **WHEN** getTotalCost() is called
- **THEN** the method returns 31.50 (3 \* 10.50)

### Requirement: Validate cart not empty before order

The system SHALL validate that the shopping cart is not empty before allowing order placement. If an order is attempted with an empty cart, the system SHALL throw ShoppingCartEmptyOrderException with the message "Shopping cart is empty".

#### Scenario: Order validation fails for empty cart

- **GIVEN** an empty shopping cart
- **WHEN** an order placement is attempted
- **THEN** ShoppingCartEmptyOrderException is thrown with message "Shopping cart is empty"

### Requirement: Shopping cart screen display

The system SHALL display a shopping cart screen that lists all cart items with their product attributes, name, quantity, and unit cost. The screen SHALL display the cart subtotal in currency format. When the cart is empty, the screen SHALL display "Your Shopping Cart is Empty." The screen SHALL provide a form to update item quantities and an "Update Cart" submit button. Each item SHALL have a "Remove" link.

#### Scenario: Cart screen displays items and controls

- **GIVEN** a shopping cart with two items
- **WHEN** the cart screen is rendered
- **THEN** the screen displays: each item with attribute, name, quantity input field (named itemQuantity\_<itemId>), unit cost in currency format, a "Remove" link for each item, an "Update Cart" submit button, and the subtotal in currency format

#### Scenario: Cart screen displays empty message

- **GIVEN** an empty shopping cart
- **WHEN** the cart screen is rendered
- **THEN** the screen displays "Your Shopping Cart is Empty."

### Requirement: Cart workflow operations

The shopping cart workflow SHALL support the following actions: ADD_ITEM, DELETE_ITEM, UPDATE_ITEMS (multiple), and EMPTY. The UPDATE_ITEMS action SHALL accept a map of itemId to quantity pairs, where quantity of zero or negative removes the item.

#### Scenario: Workflow events are processed

- **GIVEN** a shopping cart and events for ADD_ITEM, DELETE_ITEM, UPDATE_ITEMS
- **WHEN** each event is processed by the cart action
- **THEN** the corresponding cart method (addItem, deleteItem, updateItemQuantity) is invoked

### Requirement: Stateful session bean implementation

The shopping cart SHALL be implemented as a Stateful Session EJB, maintaining state across multiple method calls within the same session.

#### Scenario: Cart maintains state across requests

- **GIVEN** a stateful session bean for shopping cart
- **WHEN** addItem(), getCount(), addItem(), getCount() are called in sequence
- **THEN** the cart state is preserved: first getCount() returns 1, second getCount() returns 2

### Requirement: Container-managed transactions

All cart mutation operations (addItem, deleteItem, updateItemQuantity, empty, setLocale, getItems, getCount, getSubTotal) SHALL run within a container-managed transaction with transaction attribute "Required".

#### Scenario: Operations run within Required transaction

- **GIVEN** a cart operation that modifies cart state
- **WHEN** addItem() or updateItemQuantity() is called
- **THEN** the operation executes within a Required transaction, with automatic rollback on exception

### Requirement: Cart authorization

All methods on ShoppingCartEJB SHALL be accessible without role-based authorization checks. Access control is unchecked for all methods.

#### Scenario: Any caller can access cart methods

- **GIVEN** any caller without specific roles
- **WHEN** any cart method is invoked
- **THEN** no authorization checks prevent access; the method executes
