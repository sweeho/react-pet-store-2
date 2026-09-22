# Product Catalog - Design Document

## Overview

The product catalog system provides multi-locale, paginated access to hierarchical product data organized by categories, products, and inventory items. The system exposes a stateless session bean interface that delegates to a data access layer, abstracting SQL query execution and result mapping into model objects.

## Architecture

### Data Model

#### Category Entity

- **id** (String): Unique category identifier (e.g., "FISH", "BIRDS", "REPTILES")
- **name** (String): Localized category display name
- **description** (String): Localized category description

Represented by `com.sun.j2ee.blueprints.catalog.model.Category` with three-argument constructor and getter methods.

#### Product Entity

- **id** (String): Unique product identifier within a category
- **name** (String): Localized product name
- **description** (String): Localized product description

Represented by `com.sun.j2ee.blueprints.catalog.model.Product` with three-argument constructor and getter methods.

#### Item Entity

- **itemId** (String): Unique item identifier
- **productId** (String): Reference to parent product
- **productName** (String): Cached product name at time of retrieval
- **category** (String): Reference to category (for sorting/filtering)
- **imageLocation** (String): Path to item image asset
- **description** (String): Localized item description (defaults to "none")
- **attribute1 through attribute5** (String): Optional descriptive attributes (e.g., color, size, habitat)
- **listPrice** (double): Retail price for the item
- **unitCost** (double): Cost to purchase/stock the item

Represented by `com.sun.j2ee.blueprints.catalog.model.Item` with 13-argument constructor. Supports getAttribute() for default access (returns attribute1) and getAttribute(int index) for 1-based indexed access (1-5 for attributes, default fallback to attribute1).

#### Page Model

- **objects** (List): Immutable collection of entities (Category, Product, Item)
- **start** (int): Zero-based start index for current page
- **hasNext** (boolean): Flag indicating whether more results exist beyond current page

Provides navigation helpers:

- `isNextPageAvailable()`: Returns hasNext flag
- `isPreviousPageAvailable()`: Returns start > 0
- `getStartOfNextPage()`: Returns start + objects.size()
- `getStartOfPreviousPage()`: Returns Math.max(start - objects.size(), 0)
- `getList()`: Returns the result objects
- `EMPTY_PAGE`: Constant empty page for invalid requests

### EJB Service Layer

#### CatalogEJB (Stateless Session Bean)

Declared in ejb-jar.xml with:

- **session-type**: Stateless
- **transaction-type**: Container (CMT)
- **Local interface**: CatalogLocal
- **All methods**: transaction-attribute Required, method-permission unchecked

Methods delegate to underlying DAO (GenericCatalogDAO) via service locator pattern, wrapping CatalogDAOSysException in EJBException.

**Public Methods:**

1. `Category getCategory(String categoryID, Locale locale)`
2. `Page getCategories(int start, int count, Locale locale)`
3. `Product getProduct(String productID, Locale locale)`
4. `Page getProducts(String categoryID, int start, int count, Locale locale)`
5. `Item getItem(String itemID, Locale locale)`
6. `Page getItems(String productID, int start, int count, Locale locale)`
7. `Page searchItems(String searchQuery, int start, int count, Locale locale)`

### Data Access Layer

#### GenericCatalogDAO

Implements CatalogDAO interface with SQL execution delegated through prepared statements built from declarative SQL statements defined in CatalogDAOSQL.xml.

**Query Methods:**

- **GET_CATEGORY**: Joins category and category_details tables, filtered by locale and catid
- **GET_CATEGORIES**: Retrieves all categories for a locale, ordered by name
- **GET_PRODUCT**: Joins product and product_details, filtered by locale and productid
- **GET_PRODUCTS**: Retrieves products in a category, filtered by locale, ordered by name
- **GET_ITEM**: Joins item, item_details, product_details, product tables; retrieves all 12 item fields
- **GET_ITEMS**: Retrieves items for a product, filtered by locale
- **SEARCH_ITEMS**: Full-text search across product name, category ID, and item description using OR logic

**Pagination Logic:**

All list-returning methods follow identical pattern:

1. Execute query via buildSQLStatement() to create parameterized PreparedStatement
2. Check if start >= 0
3. Call resultSet.absolute(start + 1) to position cursor
4. If positioning succeeds, loop up to count rows: `while ((hasNext = resultSet.next()) && (--count > 0))`
5. Collect results in ArrayList and wrap in Page(results, start, hasNext)
6. If positioning fails or start < 0, return Page.EMPTY_PAGE

**Null Handling:**

- getCategory(), getProduct(), getItem() return null if resultSet.first() returns false
- getCategories(), getProducts(), getItems(), searchItems() return Page.EMPTY_PAGE if positioning fails

**Search Logic:**

searchItems() tokenizes query string by whitespace into keywords via StringTokenizer:

1. If keywordSet.isEmpty(), return Page.EMPTY_PAGE immediately
2. For each keyword, create 3 parameter wildcards: "%keyword%"
3. Construct OR-based WHERE clause: `(lower(name) like ? or lower(catid) like ? or lower(description) like ?) or (next keyword patterns)`
4. Apply standard pagination on result set

### SQL Schema Integration

**Tables:**

- **category**: catid (PK), locale column for multi-locale support
- **category_details**: catid (FK), locale (PK composite), name, descn
- **product**: productid (PK), catid (FK)
- **product_details**: productid (FK), locale (PK composite), name, descn
- **item**: itemid (PK), productid (FK)
- **item_details**: itemid (FK), locale (PK composite), image, descn, attr1-5

**Multi-Locale Strategy:**

Locale-specific content (\_details tables) joined to base entities via catid/productid/itemid and locale parameter. All queries filter WHERE locale = ? as first condition.

### Transaction Model

**Container-Managed Transactions:**

All CatalogEJB methods declare trans-attribute=Required in ejb-jar.xml. Container automatically:

- Creates new transaction if one doesn't exist
- Joins existing transaction if one does
- Commits on successful return
- Rolls back on exception

No explicit transaction code in application; semantics are declarative.

### Authorization Model

All CatalogEJB methods are declared with unchecked permission in ejb-jar.xml:

```xml
<method-permission>
  <unchecked/>
  <method>
    <ejb-name>CatalogEJB</ejb-name>
    <method-name>*</method-name>
  </method>
</method-permission>
```

No role-based access control; any caller may invoke any method.

### Error Handling

- CatalogDAO methods throw CatalogDAOSysException on SQLException
- CatalogEJB catches CatalogDAOSysException and wraps in EJBException with original message
- No application-specific exception hierarchy; all errors mapped to EJBException
- Search with empty query returns EMPTY_PAGE rather than throwing exception
- Invalid pagination (start >= total results) returns EMPTY_PAGE rather than exception

### Configuration

DAO implementation class and database type configured via JNDI env-entry values in ejb-jar.xml:

- param/CatalogDAOClass: DAO implementation class name
- param/CatalogDAODatabase: Database type identifier

GenericCatalogDAO.getDAO() factory pattern retrieves these values and instantiates appropriate DAO implementation dynamically.

## User Interface

No screen records were extracted for this capability; its user interface is unspecified.

## Legacy Implementation Notes

- EJB 2.x container-managed persistence (if entity beans were used)
- J2EE connection pooling via JNDI DataSource
- Service Locator pattern for EJB home lookups
- ResultSet TYPE_SCROLL_INSENSITIVE for absolute() positioning
- ResultSet CONCUR_READ_ONLY for read-only operations
- SQL statements externalized to XML configuration (CatalogDAOSQL.xml)
- Declarative transactions via ejb-jar.xml (no programmatic TransactionManager)
