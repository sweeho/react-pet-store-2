## 1. Category Entity Model

- [ ] 1.1 Implement Category class with id, name, description fields
- [ ] 1.2 Implement Category constructor accepting all three parameters
- [ ] 1.3 Implement Category getters: getId(), getName(), getDescription()
- [ ] 1.4 Ensure Category implements Serializable interface

## 2. Product Entity Model

- [ ] 2.1 Implement Product class with id, name, description fields
- [ ] 2.2 Implement Product constructor accepting all three parameters
- [ ] 2.3 Implement Product getters: getId(), getName(), getDescription()
- [ ] 2.4 Ensure Product implements Serializable interface

## 3. Item Entity Model

- [ ] 3.1 Implement Item class with all 13 fields: category, productId, productName, itemId, imageLocation, description, attribute1-5, listPrice, unitCost
- [ ] 3.2 Implement Item constructor with 13 parameters in defined order
- [ ] 3.3 Implement Item getters for all fields
- [ ] 3.4 Implement getAttribute() returning attribute1 (default)
- [ ] 3.5 Implement getAttribute(int index) with 1-based indexing for attributes 1-5
- [ ] 3.6 Ensure Item implements Serializable interface

## 4. Page Model

- [ ] 4.1 Implement Page class with objects (List), start (int), hasNext (boolean)
- [ ] 4.2 Implement Page constructor accepting List, start position, hasNext flag
- [ ] 4.3 Implement getList() returning immutable copy of objects list
- [ ] 4.4 Implement isNextPageAvailable() returning hasNext
- [ ] 4.5 Implement isPreviousPageAvailable() returning start > 0
- [ ] 4.6 Implement getStartOfNextPage() returning start + objects.size()
- [ ] 4.7 Implement getStartOfPreviousPage() returning Math.max(start - objects.size(), 0)
- [ ] 4.8 Implement getSize() returning objects.size()
- [ ] 4.9 Define Page.EMPTY_PAGE constant as empty list with start=0, hasNext=false
- [ ] 4.10 Ensure Page implements Serializable interface

## 5. CatalogDAO Interface

- [ ] 5.1 Define CatalogDAO interface with seven methods
- [ ] 5.2 Define Category getCategory(String categoryID, Locale locale)
- [ ] 5.3 Define Page getCategories(int start, int count, Locale locale)
- [ ] 5.4 Define Product getProduct(String productID, Locale locale)
- [ ] 5.5 Define Page getProducts(String categoryID, int start, int count, Locale locale)
- [ ] 5.6 Define Item getItem(String itemID, Locale locale)
- [ ] 5.7 Define Page getItems(String productID, int start, int count, Locale locale)
- [ ] 5.8 Define Page searchItems(String query, int start, int count, Locale locale)
- [ ] 5.9 Define CatalogDAOSysException for error handling

## 6. GenericCatalogDAO Implementation

- [ ] 6.1 Implement GenericCatalogDAO implementing CatalogDAO interface
- [ ] 6.2 Implement JNDI DataSource lookup via context.lookup()
- [ ] 6.3 Implement buildSQLStatement() method for prepared statement construction
- [ ] 6.4 Implement closeAll() method for resource cleanup

## 7. Single-Entity Query Methods

- [ ] 7.1 Implement getCategory(categoryID, locale) executing GET_CATEGORY SQL
- [ ] 7.2 Implement result mapping: new Category(catid, name, description)
- [ ] 7.3 Implement null return when resultSet.first() returns false
- [ ] 7.4 Implement getProduct(productID, locale) executing GET_PRODUCT SQL
- [ ] 7.5 Implement result mapping: new Product(productid, name, description)
- [ ] 7.6 Implement null return when resultSet.first() returns false
- [ ] 7.7 Implement getItem(itemID, locale) executing GET_ITEM SQL with 12-column extraction
- [ ] 7.8 Implement ordered column extraction matching Item constructor signature
- [ ] 7.9 Implement null return when resultSet.first() returns false

## 8. List Query Methods (Pagination)

- [ ] 8.1 Implement getCategories(start, count, locale) with pagination
- [ ] 8.2 Implement getProducts(categoryID, start, count, locale) with pagination
- [ ] 8.3 Implement getItems(productID, start, count, locale) with pagination
- [ ] 8.4 Implement pagination pattern: check start >= 0 && resultSet.absolute(start + 1)
- [ ] 8.5 Implement loop: while ((hasNext = resultSet.next()) && (--count > 0))
- [ ] 8.6 Implement Page return: new Page(results, start, hasNext)
- [ ] 8.7 Implement EMPTY_PAGE return when positioning fails
- [ ] 8.8 Verify all list methods order results alphabetically by name

## 9. Search Implementation

- [ ] 9.1 Implement searchItems(query, start, count, locale)
- [ ] 9.2 Implement StringTokenizer for whitespace-based keyword tokenization
- [ ] 9.3 Implement empty keyword check: return EMPTY_PAGE if keywordSet.isEmpty()
- [ ] 9.4 Implement parameter array construction: 1 (locale) + (keywords.length \* 3)
- [ ] 9.5 Implement wildcard pattern: "%" + keyword + "%" for each keyword
- [ ] 9.6 Implement OR-based SQL construction with variable occurrence fragments
- [ ] 9.7 Implement pagination on search results using same algorithm as getItems()

## 10. SQL Configuration

- [ ] 10.1 Create CatalogDAOSQL.xml with seven SQL statements
- [ ] 10.2 Define GET_CATEGORY statement joining category and category_details tables
- [ ] 10.3 Define GET_CATEGORIES statement with ORDER BY name
- [ ] 10.4 Define GET_PRODUCT statement joining product and product_details tables
- [ ] 10.5 Define GET_PRODUCTS statement with ORDER BY name and category filter
- [ ] 10.6 Define GET_ITEM statement joining item, item_details, product_details, product
- [ ] 10.7 Define GET_ITEMS statement joining all tables with ORDER BY name (if applicable)
- [ ] 10.8 Define SEARCH_ITEMS statement with variable occurrence fragments for keywords
- [ ] 10.9 Verify all WHERE clauses filter by locale as first condition

## 11. EJB Session Bean

- [ ] 11.1 Implement CatalogEJB stateless session bean
- [ ] 11.2 Implement ServiceLocator JNDI lookup for CatalogDAO home
- [ ] 11.3 Implement seven public methods delegating to DAO
- [ ] 11.4 Implement exception wrapping: catch CatalogDAOSysException, throw EJBException
- [ ] 11.5 Implement all methods preserving original exception message

## 12. EJB Configuration

- [ ] 12.1 Declare CatalogEJB in ejb-jar.xml with session-type=Stateless
- [ ] 12.2 Declare transaction-type=Container in ejb-jar.xml
- [ ] 12.3 Declare CatalogLocal interface (local-home, local elements)
- [ ] 12.4 Declare CatalogLocalHome interface (create() method)
- [ ] 12.5 Map all seven methods to container-transaction with trans-attribute=Required
- [ ] 12.6 Declare method-permission with unchecked element for CatalogEJB (method-name=\*)
- [ ] 12.7 Configure JNDI env-entry for CatalogDAOClass (DAO implementation)
- [ ] 12.8 Configure JNDI env-entry for CatalogDAODatabase (database type)

## 13. Transaction Management

- [ ] 13.1 Verify all container-transaction declarations match method signatures exactly
- [ ] 13.2 Verify method-intf="Local" for all method-permission entries
- [ ] 13.3 Verify method-params types match CatalogLocal interface signatures
- [ ] 13.4 Test transaction rollback behavior on exception
- [ ] 13.5 Test transaction isolation between concurrent requests

## 14. Authorization and Access Control

- [ ] 14.1 Verify no role-based method-permission entries (only unchecked)
- [ ] 14.2 Verify method-name=\* applies to all methods on CatalogEJB
- [ ] 14.3 Test that unauthenticated callers can invoke all methods
- [ ] 14.4 Test that callers without specific roles can invoke all methods

## 15. Multi-Locale Support

- [ ] 15.1 Verify all SQL queries include WHERE locale = ? as first filter condition
- [ ] 15.2 Verify all methods accept Locale parameter and convert via locale.toString()
- [ ] 15.3 Test queries with different locale values (en_US, fr_FR, etc.)
- [ ] 15.4 Test that results are correctly filtered and ordered per locale

## 16. Pagination and Result Set Navigation

- [ ] 16.1 Test valid start positions return correct page range
- [ ] 16.2 Test negative start positions return EMPTY_PAGE
- [ ] 16.3 Test start positions beyond total results return EMPTY_PAGE
- [ ] 16.4 Test hasNext flag correctly indicates more results exist
- [ ] 16.5 Test getStartOfNextPage() and getStartOfPreviousPage() calculations
- [ ] 16.6 Test empty result sets return EMPTY_PAGE

## 17. Search and Keyword Tokenization

- [ ] 17.1 Test search with single keyword
- [ ] 17.2 Test search with multiple keywords (OR logic)
- [ ] 17.3 Test search with empty query string returns EMPTY_PAGE
- [ ] 17.4 Test search with whitespace-only query returns EMPTY_PAGE
- [ ] 17.5 Test search results matched against name, category ID, and description
- [ ] 17.6 Test search pagination with valid and invalid start positions

## 18. Data Retrieval and Mapping

- [ ] 18.1 Test getCategory() returns correct name and description
- [ ] 18.2 Test getProduct() returns correct name and description
- [ ] 18.3 Test getItem() returns all 13 fields in correct order
- [ ] 18.4 Test Item attribute access: getAttribute() returns attribute1
- [ ] 18.5 Test Item attribute access: getAttribute(1-5) returns corresponding attribute
- [ ] 18.6 Test getAttribute() default case returns attribute1 for invalid indices

## 19. Null and Empty Result Handling

- [ ] 19.1 Test null return for non-existent category
- [ ] 19.2 Test null return for non-existent product
- [ ] 19.3 Test null return for non-existent item
- [ ] 19.4 Test EMPTY_PAGE return for empty category list
- [ ] 19.5 Test EMPTY_PAGE return for empty product list
- [ ] 19.6 Test EMPTY_PAGE return for empty item list

## 20. Error Handling and Exceptions

- [ ] 20.1 Test CatalogDAOSysException wrapping for SQL errors
- [ ] 20.2 Test EJBException thrown from CatalogEJB methods
- [ ] 20.3 Test exception message preservation in EJBException
- [ ] 20.4 Test resource cleanup (connection, statement, resultSet closing)
- [ ] 20.5 Test exception handling with invalid locale values
- [ ] 20.6 Test exception handling with malformed SQL parameters
