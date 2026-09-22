## ADDED Requirements

### Requirement: Category entity structure

The system SHALL represent catalog categories as discrete entities with unique identifier (id), display name, and locale-specific description.

#### Scenario: Category data is persisted and retrieved

- **GIVEN** a category with id "FISH", name "Fish", and description "Saltwater and Freshwater Fish"
- **WHEN** the category is stored and retrieved via getCategory("FISH", locale)
- **THEN** the id, name, and description are persisted and returned

### Requirement: Product entity structure

The system SHALL represent products as discrete entities within categories, with unique identifier (id), display name, and locale-specific description.

#### Scenario: Product data is persisted within a category

- **GIVEN** a product with id "PROD-001", name "Angelfish", and description "Beautiful Angelfish"
- **WHEN** the product is stored and retrieved via getProduct("PROD-001", locale)
- **THEN** the id, name, and description are persisted and returned

### Requirement: Item entity structure

The system SHALL represent inventory items with unique identifier (itemId), parent product reference, optional attributes (attribute1-5), pricing (listPrice, unitCost), image reference, and description.

#### Scenario: Item data with all attributes is persisted

- **GIVEN** an item with itemId "ITEM-001", productId "PROD-001", productName "Angelfish", category "FISH", five attributes, imageLocation path, description, listPrice 29.50, and unitCost 14.75
- **WHEN** the item is stored and retrieved via getItem("ITEM-001", locale)
- **THEN** all fields are persisted and returned with values intact

### Requirement: Page result structure

The system SHALL represent result pages as immutable collections containing an item list, start index, and pagination state (hasNext flag).

#### Scenario: Page contains pagination state for navigation

- **GIVEN** a result set with 25 items and more items available beyond the page
- **WHEN** the results are wrapped in a Page with start=0 and hasNext=true
- **THEN** the Page object returns the list via getList(), start position via getStartOfNextPage() as 25, and previous page available as false

### Requirement: Single category retrieval

The system SHALL support retrieving a single category by category ID and locale, returning the category object or null if not found.

#### Scenario: Category is retrieved by ID

- **GIVEN** a stored category with id "FISH" in locale "en_US"
- **WHEN** getCategory("FISH", locale) is called
- **THEN** the Category object is returned with matching id, name, and description

#### Scenario: Non-existent category returns null

- **GIVEN** a request for category id "NONEXIST" in locale "en_US"
- **WHEN** getCategory("NONEXIST", locale) is called
- **THEN** null is returned

### Requirement: Paginated category listing

The system SHALL support retrieving a paginated list of categories with configurable start position and page count, ordered alphabetically by name, with pagination state indicating whether more categories exist.

#### Scenario: Categories are returned in paginated form

- **GIVEN** a catalog with 50 categories
- **WHEN** getCategories(start=0, count=10, locale) is called
- **THEN** a Page is returned containing up to 10 categories ordered by name, with hasNext=true indicating more categories exist

#### Scenario: Last page of categories has hasNext false

- **GIVEN** a catalog with 50 categories
- **WHEN** getCategories(start=40, count=10, locale) is called
- **THEN** a Page is returned containing the final 10 categories with hasNext=false

### Requirement: Single product retrieval

The system SHALL support retrieving a single product by product ID and locale, returning the product object or null if not found.

#### Scenario: Product is retrieved by ID

- **GIVEN** a stored product with id "PROD-001" in locale "en_US"
- **WHEN** getProduct("PROD-001", locale) is called
- **THEN** the Product object is returned with matching id, name, and description

### Requirement: Paginated product listing

The system SHALL support retrieving a paginated list of products within a specific category with configurable start position and page count, ordered alphabetically by name, with pagination state indicating whether more products exist.

#### Scenario: Products are returned paginated by category

- **GIVEN** a category "FISH" with 30 products
- **WHEN** getProducts("FISH", start=0, count=5, locale) is called
- **THEN** a Page is returned containing up to 5 products ordered by name with hasNext=true

### Requirement: Single item retrieval

The system SHALL support retrieving a single item by item ID and locale, returning all item attributes including category, product ID, product name, pricing, image location, and five optional attributes, or null if not found.

#### Scenario: Item is retrieved with all attributes

- **GIVEN** a stored item with itemId "ITEM-001"
- **WHEN** getItem("ITEM-001", locale) is called
- **THEN** the Item object is returned with all fields populated: category, productId, productName, attributes 1-5, itemId, imageLocation, description, listPrice, and unitCost

### Requirement: Paginated item listing

The system SHALL support retrieving a paginated list of items within a specific product with configurable start position and page count, with pagination state indicating whether more items exist.

#### Scenario: Items are returned paginated by product

- **GIVEN** a product "PROD-001" with 15 items
- **WHEN** getItems("PROD-001", start=0, count=5, locale) is called
- **THEN** a Page is returned containing up to 5 items with hasNext=true

### Requirement: Item search by keyword

The system SHALL support full-text search of items by keyword query, tokenizing the input by whitespace into keywords and matching against item name, category ID, and description fields using OR logic (match ANY keyword). Results SHALL be paginated with configurable start position and page count.

#### Scenario: Search returns items matching any keyword

- **GIVEN** a search query "Angelfish Tropical" with 20 matching items
- **WHEN** searchItems("Angelfish Tropical", start=0, count=5, locale) is called
- **THEN** a Page is returned containing up to 5 items matching either "Angelfish" OR "Tropical" with hasNext=true

#### Scenario: Empty search query returns empty page

- **GIVEN** a search query with no whitespace-separated tokens (empty or whitespace only)
- **WHEN** searchItems(emptyQuery, start=0, count=5, locale) is called
- **THEN** an empty Page (EMPTY_PAGE) is returned

### Requirement: Locale-aware data retrieval

All catalog operations (getCategory, getCategories, getProduct, getProducts, getItem, getItems, searchItems) SHALL accept a Locale parameter for locale-specific filtering and result ordering.

#### Scenario: Operations filter results by locale

- **GIVEN** categories in both "en_US" and "fr_FR" locales
- **WHEN** getCategories(start=0, count=10, Locale("en_US")) is called
- **THEN** results are filtered to only "en_US" locale categories

### Requirement: Pagination by absolute row positioning

Pagination SHALL be based on absolute row positioning in the result set. If the requested start position is invalid (start < 0 or beyond result set bounds), the operation SHALL return EMPTY_PAGE.

#### Scenario: Invalid start position returns empty page

- **GIVEN** a result set with 20 items and a request for start=50
- **WHEN** getItems(productID, start=50, count=10, locale) is called
- **THEN** EMPTY_PAGE is returned

### Requirement: Item attribute access

Item attributes (attribute1 through attribute5) SHALL be optional string fields supporting 1-based indexed access. Access without index SHALL return attribute1 (default).

#### Scenario: Item attributes are accessed by index

- **GIVEN** an Item with attribute1="Red", attribute2="Large", attribute3="Saltwater"
- **WHEN** getAttribute(2) is called
- **THEN** "Large" is returned

#### Scenario: Item default attribute access returns attribute1

- **GIVEN** an Item with attribute1="Red", attribute2="Large"
- **WHEN** getAttribute() is called without index
- **THEN** "Red" is returned

### Requirement: Catalog EJB transaction model

The Catalog EJB SHALL be a stateless session bean with container-managed transactions. All methods (getCategory, getCategories, getProduct, getProducts, getItem, getItems, searchItems) SHALL have transaction attribute Required, executing all operations within a single transaction.

#### Scenario: Methods execute in required transaction context

- **GIVEN** a call to getCategory(categoryID, locale)
- **WHEN** the method executes
- **THEN** the operation executes within a Required transaction context, rolling back any changes if an exception occurs

### Requirement: Catalog authorization

All Catalog EJB methods SHALL be unchecked for authorization (no role-based access control). Any user or system may invoke all methods.

#### Scenario: Methods are accessible without authorization

- **GIVEN** any caller (authenticated or unauthenticated, with or without roles)
- **WHEN** any Catalog EJB method is invoked
- **THEN** no authorization checks prevent access; the method executes

### Requirement: Read-only catalog operations

All catalog data access operations SHALL be read-only. No insert, update, or delete operations SHALL be provided through the Catalog EJB or DAO interfaces.

#### Scenario: Only read operations are available

- **GIVEN** the Catalog EJB interface
- **WHEN** all available methods are inspected
- **THEN** all methods are named get* or search*, indicating read-only access
