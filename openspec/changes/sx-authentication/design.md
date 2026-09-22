# Authentication - Design Document

## Overview

The authentication capability provides a form-based user sign-on system for the Pet Store application. Users create accounts with username and password credentials, then authenticate via a sign-on form to access protected resources. The system maintains authentication state in HTTP sessions and cookies, and uses EJBs for user persistence and authentication logic.

## Architecture

### User Model

The system uses a simple user entity with two fields:

- **userName** (String, primary key, max 25 characters)
- **password** (String, max length configurable via MAX_PASSWD_LENGTH)

The User entity is implemented as a CMP 2.x Entity Bean (UserEJB) with local interfaces for component-internal access.

### Authentication Components

#### UserEJB (CMP 2.x Entity Bean)

- Container-managed persistence
- Abstract methods: getUserName(), setUserName(), getPassword(), setPassword()
- Business method: matchPassword(String) for password verification
- Lifecycle method: ejbCreate(String userName, String password) for validation

#### SignOnEJB (Stateless Session Bean)

- Business methods:
  - `authenticate(String userName, String password) : boolean` — validates credentials
  - `createUser(String userName, String password) : void` — creates new user account
- Transaction attribute: Required (container-managed)
- Delegates to UserEJB via home/local interfaces

#### SignOnFilter (Servlet Filter)

- Entry point for all protected resource access
- Implements filter chain pattern for transparent authentication interception
- Maintains protected resource configuration loaded from signon-config.xml
- Session attribute management for authentication state

### Session-Based Authentication Flow

1. **Unauthenticated Request to Protected Resource**
   - SignOnFilter intercepts request
   - Checks j_signon session attribute (defaults to Boolean false)
   - If false/null and URL matches protected resource pattern, stores original URL in j_signon_original_url
   - Forwards request to configured sign-on page (signon.screen)

2. **Form Submission**
   - User enters credentials in signon.jsp form
   - Form posts to j_signon_check URL (processed by SignOnFilter)
   - SignOnFilter.validateSignOn() extracts j_username and j_password parameters

3. **Credential Validation**
   - SignOnFilter calls SignOnEJB.authenticate(userName, password)
   - SignOnEJB looks up user via UserEJB.findByPrimaryKey(userName)
   - If found, calls user.matchPassword(password) using String.equals()
   - Returns boolean result (false if user not found or password mismatches)

4. **Successful Authentication**
   - Session attribute j_signon_username is set to the userName
   - Session attribute j_signon is set to Boolean(true)
   - Optional: if "j_remember_username" parameter present, creates bp_signon cookie with username
   - Server-side redirect to j_signon_original_url (the originally requested resource)

5. **Failed Authentication**
   - Server-side redirect to configured error page (signon_error.screen)
   - No session attributes are modified
   - Error page displays message and provides link back to sign-on form

### Input Validation

All validation occurs in UserEJB.ejbCreate() during entity bean creation:

1. **Username Length Check**
   - if (userName.length() > UserLocal.MAX_USERID_LENGTH) throw CreateException
   - MAX_USERID_LENGTH = 25 (hardcoded constant)

2. **Username Character Check**
   - if (userName.contains('%') || userName.contains('\*')) throw CreateException
   - Checks using String.indexOf() != -1

3. **Password Length Check**
   - if (password.length() > UserLocal.MAX_PASSWD_LENGTH) throw CreateException
   - MAX_PASSWD_LENGTH is a constant (value not visible in code samples)

### Session Attributes

| Attribute             | Type    | Purpose                                                                       |
| --------------------- | ------- | ----------------------------------------------------------------------------- |
| j_signon              | Boolean | Authentication state flag; true = authenticated, false/null = unauthenticated |
| j_signon_username     | String  | Authenticated username for reference by other components                      |
| j_signon_original_url | String  | Original requested URL (stored before redirect to sign-on form)               |

### Configuration Model

#### signon-config.xml Structure

```xml
<signon-configuration>
  <signon-form-login-page>signon.screen</signon-form-login-page>
  <signon-form-error-page>signon_error.screen</signon-form-error-page>
  <security-constraint>
    <web-resource-collection>
      <web-resource-name>Customer Screen</web-resource-name>
      <url-pattern>customer.screen</url-pattern>
    </web-resource-collection>
  </security-constraint>
  <!-- Additional security-constraint elements for other protected resources -->
</signon-configuration>
```

#### SignOnDAO Responsibilities

- Parses signon-config.xml on filter initialization
- Extracts sign-on page and error page URLs
- Builds HashMap of protected resources keyed by URL pattern
- Provides getter methods for filter to access configuration

### Cookie-Based Username Persistence

When user checks "Remember My User Name":

- Cookie created with name "bp_signon"
- Cookie value set to the authenticated username
- Cookie MaxAge set to 2678400 seconds (30 days)
- Cookie added to HTTP response

When user unchecks "Remember My User Name":

- Existing bp_signon cookie is removed by setting MaxAge = 0

On sign-on form rendering (signon.jsp):

- JSP checks for bp_signon cookie presence using JSTL `${cookie['bp_signon']}`
- If present and non-empty, pre-populates j_username input field with cookie value
- Otherwise, j_username field defaults to empty or "j2ee"

### Form Field Mapping

| HTML Field          | Constant Name     | Usage                                          |
| ------------------- | ----------------- | ---------------------------------------------- |
| j_username          | FORM_USER_NAME    | Username input, extracted from POST parameters |
| j_password          | FORM_PASSWORD     | Password input, extracted from POST parameters |
| j_remember_username | REMEMBER_USERNAME | Checkbox for username cookie persistence       |

### Sign-On Form (signon.jsp)

- Uses waf:form custom tag library for rendering
- Form posts to j_signon_check action (intercepted by SignOnFilter)
- Displays title "Sign In"
- Contains waf:input elements for username and password
- Contains waf:checkbox element for "Remember My User Name"
- Pre-population logic using JSTL and waf:value elements

### Protected Resources

Defined in signon-config.xml with URL pattern matching:

- customer.screen (customer profile)
- customer.do (customer action handler)
- enter_order_information.screen (order entry form)
- signon_welcome.screen (authenticated welcome page)

Access to these resources requires j_signon = true; unauthenticated requests are redirected to sign-on form.

### Error Handling

#### User Creation Errors

- **USERNAME_TOO_LONG**: CreateException thrown if userName.length() > 25
- **INVALID_USERNAME_CHARS**: CreateException thrown if userName contains '%' or '\*'
- **PASSWORD_TOO_LONG**: CreateException thrown if password exceeds MAX_PASSWD_LENGTH

#### Authentication Errors

- **USER_NOT_FOUND**: FinderException caught, authenticate() returns false
- **PASSWORD_MISMATCH**: matchPassword() returns false

#### Configuration Errors

- SignOnDAO returns null if signon-config.xml not found; filter uses defaults
- Missing protected resources configuration results in all URLs being unprotected (default-allow)

### Security Considerations

1. **Password Storage**: Passwords are stored as-is (no encryption visible in legacy code); rebuild should use proper hashing
2. **Password Comparison**: String.equals() comparison is case-sensitive; legacy and rebuild must match
3. **Cookie Security**: bp_signon cookie stores plaintext username (no sensitive data, but consider HttpOnly and Secure flags)
4. **Session Timeout**: HTTP session timeout is configured separately; sign-on state survives session boundaries
5. **CSRF**: No CSRF tokens visible in legacy form; rebuild should add token validation

### Legacy Implementation Details

- **Filter Initialization**: SignOnFilter.init() loads signon-config.xml from /WEB-INF/
- **Protected Resource Lookup**: SignOnFilter maintains HashMap of ProtectedResource objects keyed by URL pattern
- **Cookie Management**: Cookies are manually constructed and added to response (no framework helpers visible)
- **Transaction Management**: EJB container manages transactions via ejb-jar.xml declarative configuration
- **User Lookup**: FindByPrimaryKey exception handling is used for "user not found" cases
- **Filter Chain**: SignOnFilter calls chain.doFilter() to allow request to proceed if authenticated or unprotected

### Integration Points

- Depends on UserEJB for user entity persistence and lookup
- Depends on SignOnEJB for authentication business logic
- Integrates with servlet container for session management
- Uses HTTP cookies for optional username persistence
- Reads configuration from external signon-config.xml file

### Known Limitations

1. **Plaintext Passwords**: Legacy stores passwords without hashing; rebuild must implement secure storage
2. **No Multi-Factor Authentication**: Only username/password supported
3. **No Account Lockout**: No protection against brute-force attacks
4. **No HTTPS Enforcement**: Form posts and cookies are not HTTPS-only in legacy
5. **No Token-Based Auth**: Only session-based; no JWT or bearer tokens
6. **Hardcoded Constants**: URL patterns and page names hardcoded in configuration and code
