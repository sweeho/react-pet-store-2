# Product Catalog - Specification Proposal

## Summary

This specification extracts the product catalog capability from the legacy Java Pet Store application. The system provides multi-locale, paginated access to hierarchical product data (categories, products, inventory items) through a stateless session bean facade that delegates to a data access layer. Catalog operations are read-only and support full-text search across product and item descriptions.

## Problem Statement

The legacy catalog system distributes data access logic across action beans, EJB session beans, and a data access object layer. The contracts governing entity creation, pagination semantics, search behavior, locale filtering, and transaction management are implicit in code and configuration rather than explicitly stated. This specification captures the catalog contracts so the capability can be rebuilt with clear behavioral boundaries and verifiable acceptance criteria.

## Solution Overview

Product catalog consists of:

- **Category Entity**: id, name, locale-specific description
- **Product Entity**: id, name, locale-specific description
- **Item Entity**: itemId, productId, productName, category, five optional attributes, imageLocation, description, listPrice, unitCost
- **Page Container**: immutable result collection with pagination state (start index, hasNext flag)
- **CatalogEJB**: Stateless session bean exposing seven read-only methods
- **GenericCatalogDAO**: Data access layer executing parameterized SQL queries
- **Multi-Locale Support**: All queries filtered by locale parameter
- **Pagination**: Absolute row positioning with configurable page size
- **Full-Text Search**: Keyword tokenization with OR logic across multiple fields

## Key Behavioral Requirements

### Entities

**Category** persists id, name, and locale-specific description. Categories organize products hierarchically.

**Product** represents product types within a category, persisting id, name, and locale-specific description.

**Item** represents specific inventory stock keeping units (SKUs), capturing:

- Unique identifier (itemId)
- Parent product reference (productId) and cached product name
- Category assignment for sorting
- Optional attributes: five string fields indexed 1-5
- Commercial data: listPrice (retail) and unitCost (procurement)
- Asset reference: imageLocation (path to product image)
- Locale-specific description (defaults to "none")

**Page** wraps result collections with pagination state:

- List of entities (Category, Product, or Item)
- Start index (0-based position in result set)
- hasNext flag (whether more results exist beyond current page)
- Navigation helpers: getStartOfNextPage(), getStartOfPreviousPage()

### Service Interface

**CatalogEJB** exposes seven methods:

1. getCategory(categoryID, locale) - Single category by ID, null if not found
2. getCategories(start, count, locale) - Paginated categories ordered by name
3. getProduct(productID, locale) - Single product by ID, null if not found
4. getProducts(categoryID, start, count, locale) - Paginated products in category
5. getItem(itemID, locale) - Single item by ID with all fields, null if not found
6. getItems(productID, start, count, locale) - Paginated items in product
7. searchItems(query, start, count, locale) - Full-text search with keyword tokenization

### Pagination

All list-returning methods accept start (0-based index) and count (page size) parameters. The result set is queried via:

1. resultSet.absolute(start + 1) to position cursor at requested row
2. Loop fetching up to count rows: `while ((hasNext = resultSet.next()) && (--count > 0))`
3. Return Page(results, start, hasNext) where hasNext indicates more results exist

If start < 0 or positioning fails (start beyond result set), return Page.EMPTY_PAGE.

### Search Behavior

searchItems(query) tokenizes the input by whitespace into keywords. Empty queries return EMPTY_PAGE. For each keyword, the SQL WHERE clause includes OR conditions matching product name, category ID, or item description via case-insensitive LIKE wildcards. Results are paginated identically to getItems().

### Multi-Locale

All queries accept a Locale parameter and filter WHERE locale = ?. Queries join base entities (category, product, item tables) with locale-specific detail tables (\_details tables) on locale. Results are ordered and filtered per the requested locale.

### Transaction Model

All methods execute within Required transaction context (container-managed). The container:

- Creates a new transaction if none exists
- Joins existing transaction if present
- Commits on successful return
- Rolls back on any exception

No explicit transaction code; semantics are declarative via ejb-jar.xml.

### Authorization

All methods are unchecked for authorization. Any caller (authenticated or unauthenticated) may invoke any method without role-based restrictions.

### Error Handling

Single-entity queries (getCategory, getProduct, getItem) return null if not found. List queries (getCategories, getProducts, getItems, searchItems) return EMPTY_PAGE if:

- Start position is invalid (< 0 or beyond result set bounds)
- Search keywords are empty
- No results match the query

DAO exceptions (SQLException) are caught and wrapped in EJBException with original message preserved.

## Implementation Scope

Includes:

- ✓ Category, Product, Item, Page entity models
- ✓ Seven query methods (get/search)
- ✓ Pagination with absolute row positioning
- ✓ Full-text search with OR-based keyword matching
- ✓ Multi-locale filtering and sorting
- ✓ GenericCatalogDAO implementation
- ✓ CatalogEJB stateless session bean
- ✓ Container-managed transactions (Required)
- ✓ Unchecked authorization (no role-based access)
- ✓ SQL query externalization (CatalogDAOSQL.xml)
- ✓ JNDI DataSource and ServiceLocator patterns

Excludes:

- Product data modification (no insert/update/delete)
- Category hierarchy/parent-child relationships
- Item inventory depletion or stock level tracking
- Pricing rules, promotions, or discount calculations
- Product recommendations or personalization
- Review, rating, or recommendation systems
- Product filtering by attributes
- Faceted search or advanced query options
- Caching of frequently accessed products
- Bulk operations (batch insert/update)
- Async indexing for search

## Implementation Considerations

### Entity Persistence

Categories, products, and items are persisted in a relational database with locale-specific details stored in separate tables. The schema enforces multi-locale through table joins and locale filtering.

### DAO Factory Pattern

CatalogDAOFactory retrieves DAO implementation class and database type from JNDI env-entry values (CatalogDAOClass, CatalogDAODatabase) at runtime, instantiating the appropriate DAO implementation dynamically. This allows deployment-time DAO selection without code changes.

### ResultSet Positioning

Pagination relies on ResultSet.TYPE_SCROLL_INSENSITIVE and ResultSet.absolute() for direct row access. This requires the driver to support scrollable result sets. Forward-only result sets would require alternative pagination strategies (offset queries, cursor keyset algorithms).

### SQL Externalization

SQL statements are externalized to XML configuration (CatalogDAOSQL.xml) separate from Java code. The buildSQLStatement() method constructs parameterized PreparedStatement from declarative fragments, supporting VARIABLE occurrence patterns for dynamic query construction (e.g., OR-based search with variable keyword count).

### Keyword Search

Search tokenizes by whitespace via StringTokenizer. Single whitespace characters act as delimiters; keywords are matched case-insensitively via LIKE wildcards. Empty queries and single-whitespace queries both produce empty keyword sets and return EMPTY_PAGE. No phrase search, exact matching, or proximity operators are supported.

### Null Handling

Single-entity queries return null for not-found cases. List queries never return null; they return empty Page or Page.EMPTY_PAGE. This asymmetry is intentional: single entities may legitimately not exist; empty lists are valid results.

## Success Criteria

Implementation is successful when:

1. Category entity persists id, name, description with getters and constructor
2. Product entity persists id, name, description with getters and constructor
3. Item entity persists all 13 fields with proper constructor ordering
4. Page entity wraps results with start, hasNext, and navigation helpers
5. getCategory() returns Category or null by categoryID and locale
6. getCategories() returns paginated Categories ordered by name
7. getProduct() returns Product or null by productID and locale
8. getProducts() returns paginated Products in category ordered by name
9. getItem() returns Item or null by itemID and locale with all fields populated
10. getItems() returns paginated Items in product
11. searchItems() tokenizes query by whitespace and returns matching items with OR logic
12. All list methods support pagination via start index and count
13. All methods accept Locale parameter and filter results per locale
14. Invalid start positions return EMPTY_PAGE (not exception)
15. Empty search queries return EMPTY_PAGE
16. CatalogEJB methods execute within Required transaction context
17. All methods unchecked for authorization
18. DAO exceptions wrapped in EJBException preserving message
19. All acceptance criteria scenarios pass without behavioral regression

## Assumptions and Constraints

- Database provides scrollable result sets (ResultSet.TYPE_SCROLL_INSENSITIVE)
- Locale parameter is valid string per java.util.Locale (e.g., "en_US", "fr_FR")
- Product names, descriptions, and item attributes are plain strings (no special markup)
- Search matches are case-insensitive LIKE patterns (no exact match or stemming)
- Pagination uses 0-based indexing (start=0 for first page)
- Page size (count) may be user-specified; no maximum imposed by catalog
- Item image location is a path string; image asset exists or is handled by client
- listPrice and unitCost are double-precision floating point (no BigDecimal)
- Categories and products are not deleted during catalog operation (no cascading deletes)
- Locale parameter is consistent across database schema and application code

## Open Questions for Business Clarification

1. Should pagination support cursor-based navigation (keyset pagination) as alternative to absolute positioning?
2. Should search support phrase matching or proximity operators beyond OR logic?
3. Should item attributes be strictly typed or enumerated (e.g., attribute types)?
4. Should pagination include total count of results or continue with hasNext-only state?
5. Should search results be ranked by relevance or sorted alphabetically?
6. Should category hierarchy support parent-child relationships or remain flat?
7. Should item pricing support dual-currency values or multi-currency display?
8. Should search support filters by category, attribute values, or price range?
9. Should deleted categories/products be soft-deleted or cascaded from database?
10. Should pagination be exposed differently (e.g., cursor strings) for API consumption?
