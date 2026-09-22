# Admin Operations - Design Document

## Overview

The admin operations capability provides a web-based administration interface for managing orders and viewing sales analytics. It uses form-based authentication, session management, and a rich Swing client deployed via Java Web Start for advanced administrative functions.

## Architecture

### Authentication Flow

The system uses J2EE container-managed form-based authentication with the following components:

1. **Login Page** (`login.jsp`): Form posts to `j_security_check` with `j_username` and `j_password` fields
2. **Session Management**: Sessions are managed by the servlet container with a 54-minute timeout
3. **Role Mapping**: The "administrator" logical role is mapped to physical principals via `sun-j2ee-ri.xml`

### Web API Layer

Two main servlets handle web-based administration:

1. **AdminRequestProcessor**: Handles navigation flows
   - Renders admin home page (`index.jsp`)
   - Generates JNLP files for Java Web Start deployment
   - Handles logout flow

2. **ApplRequestProcessor**: Handles rich client XML API requests
   - Parses incoming XML with Type, Status, and other elements
   - Routes requests to appropriate handlers based on Type
   - Returns XML-formatted responses
   - Validates session before processing any request

### Rich Client Deployment

The rich admin client is a Swing application deployed via Java Web Start (JNLP):

- **JNLP Generation**: The `buildJNLP()` method dynamically constructs JNLP XML with:
  - Application codebase URL from request hostname/port
  - Required JAR files (AdminApp.jar, jaxp.jar, crimson.jar)
  - Main application class (PetStoreAdminClient)
  - Runtime arguments: proxy class, hostname, port, session ID

- **Client-Server Communication**: The rich client uses HTTP POST to send XML requests to ApplRequestProcessor, passing the session ID from JNLP arguments for authentication

### XML API Protocols

#### GETORDERS Request

- **Input**: XML root with Status element
- **Processing**:
  - Extract status from XML
  - Call OPCAdminFacade.getOrdersByStatus(status)
  - Iterate over OrderDetails objects
- **Output**: XML response with TotalCount and individual Order elements containing OrderId, UserId, OrderDate, OrderAmount, OrderStatus

#### UPDATESTATUS Request

- **Input**: XML root with Order elements containing OrderId and OrderStatus
- **Processing**:
  - Parse all Order elements into ChangedOrder objects
  - Build OrderApproval message
  - Look up AsyncSender EJB via JNDI
  - Call sender.sendAMessage(orderApproval.toXML())
- **Output**: SUCCESS or ERROR response in XML

#### REVENUE Request

- **Input**: XML with Start, End, and optional ReqCategory elements
- **Processing**:
  - Parse dates in mm/dd/yyyy format to Date objects
  - Call OPCAdminFacade.getChartInfo("REVENUE", startDate, endDate, category)
  - Build XML response with Float amounts per category/item
  - Calculate running TotalSales sum
- **Output**: XML with per-category/item Float values and TotalSales

#### ORDERS Request

- **Input**: XML with Start, End, and optional ReqCategory elements
- **Processing**:
  - Parse dates in mm/dd/yyyy format to Date objects
  - Call OPCAdminFacade.getChartInfo("ORDERS", startDate, endDate, category)
  - Build XML response with Integer quantities per category/item
  - Calculate running TotalSales sum
- **Output**: XML with per-category/item Integer quantities and TotalSales

### EJB Integration

#### OPCAdminFacade (Remote Session EJB)

- Performs order and analytics queries
- Located via JNDI: `java:comp/env/ejb/OPCAdminFacadeRemote`
- Used by ApplRequestProcessor for:
  - `getOrdersByStatus(status)` → OrdersTO collection
  - `getChartInfo(type, startDate, endDate, category)` → Map of aggregated data

#### AsyncSender (Local Session EJB)

- Handles asynchronous message delivery to JMS
- Located via JNDI: `JNDINames.ASYNCSENDER_LOCAL_EJB_HOME`
- Method: `sendAMessage(xmlString)` — sends order approval XML to JMS queue
- Destination: `jms/opc/OrderApprovalQueue` (mapped in sun-j2ee-ri.xml)

### Session Handling

1. **Session Creation**: J2EE container creates session on successful form login
2. **Session Validation**: ApplRequestProcessor calls `req.getSession(false)` before processing requests
3. **Session Timeout**: Configured in web.xml as 54 minutes; container automatically expires sessions
4. **Session Invalidation**: Logout page calls `request.getSession().invalidate()` to clear session state

### Date Handling

The legacy date parsing uses a deprecated approach:

- Input format: `mm/dd/yyyy` (e.g., "01/15/2024")
- Implementation: Tokenize by "/", extract month/day/year, construct via `new Date(year-1900, month-1, day)`
- This requires the legacy java.util.Date constructor; note that `month-1` is required because Java Date uses 0-based months

### Error Handling

The legacy implementation has inconsistent error handling:

- XML parse errors return null in some methods (getOrders, getChartInfo)
- Session validation errors return explicit error XML
- Invalid request types return error XML
- Null returns from business logic methods are not always handled, which could lead to NPE

## User Interface Details

### Login Screen (login.jsp)

- Displays form title "Please sign into Java Pet Store Admin Module"
- Contains username field (j_username) defaulting to "jps_admin"
- Contains password field (j_password) defaulting to "admin"
- Submit button posts to j_security_check

### Admin Home Page (index.jsp)

- Displays page title "Java Pet Store Admin Page"
- Explains Java Web Start and rich client capabilities
- Contains form with "Launch Rich Client" button (currentScreen=manageorders)
- Contains form with "logout" button (currentScreen=logout)
- Both forms post to AdminRequestProcessor

### Rich Client - Orders View Panel

- Implements OrdersViewPanel class
- Creates JTable with TableSorter for sortable display
- Sets reorderingAllowed to false on table header
- Displays columns from GETORDERS response: OrderId, UserId, OrderDate, OrderAmount, OrderStatus
- Mouse listener on header enables sorting

### Rich Client - Orders Approval Panel

- Implements OrdersApprovePanel class
- Creates editable JTable with OrdersApproveTableModel
- Status cell contains JComboBox with options: PENDING, APPROVED, DENIED
- Three buttons for bulk operations: Approve, Deny, Commit
- Commit button submits status changes via UPDATESTATUS API

## Legacy Implementation Notes

- The admin module uses Struts-like servlet dispatching via currentScreen parameter
- Both web servlets (AdminRequestProcessor and ApplRequestProcessor) are mapped to /admin/\* URL pattern
- XML parsing uses JAXP DocumentBuilder factory
- EJB lookups use ServiceLocator pattern to cache home references
- The rich client is built with Swing and uses a Proxy pattern to communicate with the server
- Session ID is passed as a command-line argument to the rich client JNLP, not via cookie

## Security Considerations

- Credentials default to hardcoded values (jps_admin/admin) in the login form — verify if this is appropriate for production
- Session timeout of 54 minutes should be reviewed for security requirements
- XML requests must validate session before processing to prevent session hijacking
- All order status changes go through AsyncSender for audit trail and decoupling

## Integration Points

- Depends on OPCAdminFacade remote EJB for order and analytics data
- Depends on AsyncSender local EJB for async message delivery
- Integrates with JMS queue `jms/opc/OrderApprovalQueue` for order fulfillment notifications
- Uses J2EE container authentication and session management
