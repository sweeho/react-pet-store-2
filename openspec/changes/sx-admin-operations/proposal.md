# Admin Operations - Specification Proposal

## Summary

This specification extracts the admin operations capability from the legacy Java Pet Store application into a structured OpenSpec format. Admin operations provide authenticated administrators with order management and sales analytics functions through both a web interface and a Rich Desktop Client deployed via Java Web Start.

## Problem Statement

The legacy admin module implements a complex order management and analytics system with distributed components (web servlets, EJBs, rich client, JMS). This specification captures the visible behavior and contracts so the capability can be reliably rebuilt in a modern architecture without behavioral regression.

## Solution Overview

The admin operations capability consists of:

1. **Authentication Layer**: Form-based login with role-based access control and session management
2. **Web API Layer**: XML-RPC interface for rich client communication
3. **Rich Client**: Swing-based desktop application for order approval and sales analytics
4. **Business Logic Integration**: EJB connections for order queries and async messaging

## What Administrators Can Do

### Web Browser Interface

1. Log in with username and password (defaults: jps_admin/admin)
2. View admin home page
3. Launch rich client application via Java Web Start
4. Log out and clear session

### Rich Client Application

1. View orders filtered by status (PENDING, APPROVED, DENIED)
2. Sort orders by clicking column headers
3. Select orders and change status using dropdown menus
4. Bulk approve or deny selected orders with Commit button
5. View revenue analytics by date range and category
6. View order quantity analytics by date range and category

## Key Behavioral Requirements

### Authentication & Authorization

- Form-based login posting to j_security_check with j_username/j_password
- Administrator role enforcement at servlet container level
- Session timeout after 54 minutes of inactivity
- Session validation required before any rich client API request

### Order Management API

- GETORDERS: Query orders by status, return with OrderId, UserId, OrderDate, OrderAmount, OrderStatus
- UPDATESTATUS: Approve/deny pending orders, send async notification via JMS

### Analytics API

- REVENUE: Aggregate sales by category/item with floating-point amounts
- ORDERS: Aggregate order quantities by category/item with integer counts
- Both support date range filtering (mm/dd/yyyy format) and optional category filtering

### Rich Client Deployment

- Dynamically generate JNLP file containing application class, required JARs, and server connection parameters
- Pass session ID to client as JNLP argument for authentication

## Architecture Decisions

### XML-based API

The rich client communicates with the server via XML-RPC with Type-based request dispatching. This design provides:

- Clear request/response boundaries
- Version compatibility (XML is self-describing)
- Compatibility with Java serialization and legacy JAXP parsing

### Asynchronous Order Updates

Order approval decisions are sent through AsyncSender EJB and JMS queue for:

- Decoupling approval UI from order processing system
- Audit trail via message queue
- Reliability through persistent messaging

### Session-Based Authentication

Session ID is passed to rich client via JNLP arguments, not cookies. This design:

- Avoids complexities of cookie-based auth in Swing
- Aligns with HTTP session semantics
- Allows server-side session timeout enforcement

### EJB for Business Logic

OPCAdminFacade and AsyncSender are used for:

- Isolating order data access
- Leveraging container transaction management
- Maintaining separation of concerns

## Implementation Scope

The capability includes:

- ✓ Authentication and role-based access control
- ✓ Web-based admin interface (login, home page)
- ✓ Rich client deployment via JNLP
- ✓ Order query and status update APIs
- ✓ Sales analytics APIs (revenue and quantity)
- ✓ Rich client user interface (orders table, approval workflow, sales charts)
- ✓ Session management and validation
- ✓ Async order approval messaging

The capability does NOT include:

- Order fulfillment processing (handled by OPC system)
- Actual analytics calculations (delegated to OPCAdminFacade)
- JMS queue management (pre-configured)

## Implementation Considerations

### Security

- Login form defaults to jps_admin/admin — must be updated for production
- Session timeout of 54 minutes should be validated against security policies
- XML API requires session validation to prevent unauthorized access

### Date Handling

- Current implementation uses legacy Date(year-1900, month-1, day) constructor
- Input format must be mm/dd/yyyy; other formats will cause parsing errors
- Consider modernizing to java.time APIs (LocalDate, DateFormatter)

### Error Handling

- Inconsistent error handling between methods (some return null, others return error XML)
- Null returns from business methods are not always handled
- Should standardize on error XML response format

### Performance

- Rich client launches via Java Web Start — should consider caching behavior
- Order queries return full details; pagination may be needed for large datasets
- Chart aggregations may be expensive for large date ranges

## Success Criteria

The implementation is successful when:

1. All 4 screen requirements are implemented with matching UI/UX
2. All XML API request types (GETORDERS, UPDATESTATUS, REVENUE, ORDERS) work as specified
3. Authentication, authorization, and session management enforce the 54-minute timeout
4. Rich client can be launched via Java Web Start with proper connection parameters
5. Order status changes trigger async notifications to order fulfillment system
6. All test scenarios pass without behavioral regression
