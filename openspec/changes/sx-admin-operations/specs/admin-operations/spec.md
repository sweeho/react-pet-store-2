## ADDED Requirements

### Requirement: Form-based authentication for administrators

The system SHALL authenticate administrators via FORM-based login requiring username and password credentials. The form SHALL post to the "j_security_check" endpoint using field names "j_username" and "j_password".

#### Scenario: Admin logs in with credentials

- **GIVEN** an unauthenticated user accessing the admin application
- **WHEN** the user enters username and password and submits the login form
- **THEN** the form posts to j_security_check with the j_username and j_password fields

### Requirement: Administrator role enforcement

The system SHALL enforce role-based access control requiring the "administrator" role to access the AdminRequestProcessor servlet at /AdminRequestProcessor. Unauthenticated or non-administrator users SHALL be denied access.

#### Scenario: Non-admin user attempts to access admin servlet

- **GIVEN** a user without administrator role
- **WHEN** the user attempts to access /AdminRequestProcessor
- **THEN** the servlet container SHALL deny access

#### Scenario: Admin user accesses admin servlet

- **GIVEN** an authenticated user with administrator role
- **WHEN** the user requests /AdminRequestProcessor
- **THEN** the servlet SHALL process the request

### Requirement: Administrator role mapping

The system SHALL map the "administrator" logical role to physical principals (user "jps_admin") and groups ("administrator_group") at runtime via configuration.

#### Scenario: Role mapping applies at runtime

- **GIVEN** a user "jps_admin" authenticated via form login
- **WHEN** the user requests a protected resource
- **THEN** the system SHALL recognize the user as having the "administrator" role

### Requirement: Session timeout enforcement

The system SHALL enforce a session timeout of 54 minutes. Admin sessions SHALL be automatically invalidated after 54 minutes of inactivity.

#### Scenario: Session expires after 54 minutes

- **GIVEN** an authenticated admin session
- **WHEN** 54 minutes of inactivity have elapsed
- **THEN** the session SHALL be terminated by the container

### Requirement: Session invalidation on logout

The system SHALL invalidate the admin user's session when the logout action is triggered. The session.invalidate() method SHALL be called and the user SHALL be redirected to the index page.

#### Scenario: Admin logs out

- **GIVEN** an authenticated admin user
- **WHEN** the user clicks the logout button
- **THEN** the session SHALL be invalidated and the user SHALL see the index page

### Requirement: XML-based API for querying orders

The system SHALL provide an XML-based API for the rich client to query orders by status. Requests SHALL include a Status element, and the response SHALL include total count and individual order details (OrderId, UserId, OrderDate, OrderAmount, OrderStatus).

#### Scenario: Admin requests orders by status

- **GIVEN** a rich admin client with a valid session
- **WHEN** the client sends a GETORDERS XML request with a Status element
- **THEN** the system SHALL return an XML response containing TotalCount and Order elements with OrderId, UserId, OrderDate, OrderAmount, and OrderStatus

### Requirement: Session validation for API requests

The system SHALL validate that an active HTTP session exists for all API requests. If the session has timed out or does not exist, the system SHALL return an error response with message "Session Timed Out; Please exit and login as admin from the login page".

#### Scenario: API request without valid session

- **GIVEN** a rich client attempting to send a request without a valid session
- **WHEN** the ApplRequestProcessor receives the request
- **THEN** it SHALL return the session timeout error message

### Requirement: Order status update via XML API

The system SHALL support updating order status via XML API. The request SHALL include Order elements with OrderId and OrderStatus, and the system SHALL update the order status asynchronously via AsyncSender EJB after receiving the status updates.

#### Scenario: Admin approves or denies pending orders

- **GIVEN** a rich client with pending orders displayed
- **WHEN** the admin changes order status to APPROVED or DENIED and clicks Commit
- **THEN** the system SHALL send the status updates to AsyncSender for asynchronous processing

### Requirement: Chart analytics API with request types

The system SHALL provide a chart information API that accepts request type (REVENUE or ORDERS), start date, end date, and optional category, then returns aggregated data with totals. For REVENUE requests, the response SHALL include Float amounts per category/item with TotalSales sum. For ORDERS requests, the response SHALL include Integer quantity counts per category/item with TotalSales sum.

#### Scenario: Admin requests revenue data

- **GIVEN** a rich client requesting revenue analytics
- **WHEN** the client sends a REVENUE request with Start, End, and optional ReqCategory elements
- **THEN** the system SHALL return an XML response with per-category/item Float amounts and TotalSales sum

#### Scenario: Admin requests order quantity data

- **GIVEN** a rich client requesting order quantity analytics
- **WHEN** the client sends an ORDERS request with Start, End, and optional ReqCategory elements
- **THEN** the system SHALL return an XML response with per-category/item Integer quantities and TotalSales sum

### Requirement: Date parsing for analytics requests

The system SHALL parse date parameters in mm/dd/yyyy format for chart analytics. Each date string SHALL be tokenized by "/" to extract month, day, and year components, then converted to a Date object.

#### Scenario: Chart request includes date range

- **GIVEN** a chart analytics request with Start="01/15/2024" and End="12/31/2024"
- **WHEN** the system processes the request
- **THEN** the dates SHALL be parsed and used to filter the analytics data

### Requirement: OPCAdminFacade EJB reference

The system SHALL reference OPCAdminFacade remote EJB for order and analytics operations. The EJB home interface SHALL be located via JNDI lookup of "java:comp/env/ejb/OPCAdminFacadeRemote" and instantiated via home.create().

#### Scenario: System instantiates OPC admin facade

- **GIVEN** the admin application initializing
- **WHEN** business logic needs to query orders or analytics
- **THEN** the system SHALL look up OPCAdminFacade via JNDI and create an EJB instance

### Requirement: AsyncSender EJB reference

The system SHALL reference AsyncSender local EJB for asynchronous message delivery of order approval decisions. The EJB home interface SHALL be located via JNDI lookup using the appropriate constant name.

#### Scenario: System sends order approval messages

- **GIVEN** an order status update that needs async notification
- **WHEN** the system needs to notify the order processing system
- **THEN** it SHALL look up AsyncSender via JNDI and create a local EJB instance

### Requirement: Asynchronous message delivery to JMS

The system SHALL send order approval messages asynchronously to a JMS queue (jms/opc/OrderApprovalQueue) via the AsyncSender EJB. Order approval decisions SHALL be serialized as XML via OrderApproval.toXML() and passed to AsyncSender.sendAMessage().

#### Scenario: Order approval is queued for processing

- **GIVEN** an admin has updated order status
- **WHEN** the AsyncSender EJB processes the order approval
- **THEN** the order approval XML SHALL be sent to the JMS queue for async processing

### Requirement: Java Web Start (JNLP) deployment

The system SHALL support deployment of a rich admin client via Java Web Start (JNLP). When a user requests to launch the rich client via the "manageorders" screen, the system SHALL dynamically generate and serve a JNLP file containing the admin client application class, required JAR resources, and server connection parameters (hostname, port, session ID).

#### Scenario: Admin launches rich client via Java Web Start

- **GIVEN** an authenticated admin on the admin home page
- **WHEN** the admin clicks "Launch Rich Client"
- **THEN** the system SHALL generate a JNLP file with PetStoreAdminClient, required JARs, and server connection details

### Requirement: Admin login screen

The system SHALL present a login form with fields for username and password. The form SHALL default to username "jps_admin" and password "admin". The form SHALL submit to j_security_check using POST method.

#### Scenario: Admin views login page

- **GIVEN** an unauthenticated user accessing the admin application
- **WHEN** the user navigates to /login.jsp
- **THEN** the system SHALL display a form with username and password fields defaulting to "jps_admin" and "admin"

### Requirement: Admin home page

The admin home page (index.jsp) SHALL be displayed after successful authentication. The page SHALL provide navigation buttons for (1) launching a rich client via Java Web Start with currentScreen parameter "manageorders" and (2) logging out.

#### Scenario: Authenticated admin sees home page

- **GIVEN** an admin user who has successfully logged in
- **WHEN** the user is redirected to the admin home page
- **THEN** the page SHALL display a "Launch Rich Client" button and a "logout" button

### Requirement: Orders view with sortable table

The orders view in the rich client SHALL display pending orders in a sortable table. The table SHALL include columns for OrderId, UserId, OrderDate, OrderAmount, and OrderStatus. Users SHALL be able to sort the table by clicking on column headers.

#### Scenario: Admin views orders in sortable table

- **GIVEN** the rich client's Orders view is displayed
- **WHEN** the system retrieves orders via GETORDERS API
- **THEN** the orders SHALL be displayed in a table with OrderId, UserId, OrderDate, OrderAmount, and OrderStatus columns, and column headers SHALL be clickable for sorting

### Requirement: Orders approval view

The orders approval view in the rich client SHALL display pending orders in a table with editable status cells. Users SHALL be able to change order status to APPROVED or DENIED via a dropdown menu in each order's status cell. The interface SHALL provide Approve and Deny buttons for bulk operations on selected orders. A Commit button SHALL submit all status changes to the server.

#### Scenario: Admin approves pending orders

- **GIVEN** the Orders Approval tab in the rich client
- **WHEN** the admin selects orders and changes their status using the dropdown menus
- **THEN** the admin SHALL be able to click Approve or Deny buttons, and a Commit button SHALL send the changes to the server via UPDATESTATUS API

### Requirement: XML-based RPC API for rich client

The system SHALL support an XML-based RPC API for the rich admin client. The ApplRequestProcessor servlet SHALL accept XML POST requests, parse the Type element to determine request type (GETORDERS, UPDATESTATUS, REVENUE, or ORDERS), invoke corresponding business logic, and return XML-formatted responses.

#### Scenario: Rich client sends XML request

- **GIVEN** the rich admin client connected to the server
- **WHEN** the client sends an XML POST request with a Type element
- **THEN** the system SHALL parse the Type, invoke the appropriate handler (getOrders, updateOrders, or getChartInfo), and return an XML response
