# Authentication - Specification Proposal

## Summary

This specification extracts the authentication capability from the legacy Java Pet Store application into a structured OpenSpec format. The authentication system provides form-based user sign-on with username/password credentials, session-based authentication state, optional username persistence via cookies, and protected resource access control.

## Problem Statement

The legacy authentication system is embedded across multiple J2EE components (Servlet Filters, EJB Entity Beans, JSP Forms, XML Configuration). The behavior is distributed and not centrally documented, making it difficult to rebuild or modernize without behavioral regression. This specification captures the visible contract and requirements so the capability can be reliably implemented in a new architecture.

## Solution Overview

The authentication capability consists of:

1. **User Entity Model**: Username (primary key, max 25 chars) and password
2. **Credential Validation**: Username length, character whitelist, password length
3. **Authentication Logic**: Direct password comparison via SignOnEJB
4. **Session State Management**: Boolean authentication flag and username storage
5. **Protected Resource Configuration**: Declarative URL pattern matching
6. **Sign-On Form Interface**: HTML form with username, password, remember-me checkbox
7. **Cookie-Based Persistence**: Optional 30-day username cookie
8. **Authorization Enforcement**: Servlet filter interception and redirect logic

## Key Behavioral Requirements

### User Account Management

- Username: 1-25 characters, no '%' or '\*' characters
- Password: 1 to MAX_PASSWD_LENGTH characters (value not visible)
- New accounts created via SignOnEJB.createUser() with validation
- Users look up by username (primary key) via UserEJB entity

### Authentication Process

1. User submits username/password to j_signon_check
2. System validates via SignOnEJB.authenticate() using String.equals()
3. On success: set j_signon=true, j_signon_username={username}, redirect to original URL
4. On failure: redirect to error page, no session changes

### Session-Based Authorization

- j_signon Boolean flag authorizes access to protected resources
- j_signon_username stores authenticated username for downstream use
- j_signon_original_url stores target URL before sign-on redirect
- Session timeout handled by servlet container

### Protected Resources

Configured in signon-config.xml via URL patterns:

- Unauthenticated requests to protected URLs redirected to sign-on form
- Original URL stored in session before redirect
- Authenticated requests pass through filter chain
- Unprotected URLs always accessible

### Remember Me Feature

- Optional checkbox on sign-on form
- When checked: create bp_signon cookie, MaxAge=2678400 (30 days)
- When unchecked: clear bp_signon cookie if present
- On sign-on form display: pre-populate j_username from bp_signon if present

## Architecture Decisions

### EJB-Based User Persistence

- UserEJB as CMP 2.x entity bean for user storage
- Provides transactional guarantees and container-managed lifecycle
- SignOnEJB as stateless session bean for authentication logic
- Separation of concerns: data model vs. business logic

### Filter-Based Access Control

- Servlet filter pattern for transparent authentication interception
- Enables cross-cutting concern without modifying business logic
- Configuration-driven protected resource matching
- Clean separation between servlet layer and EJB layer

### Session-Over-Cookies for Primary Auth State

- HTTP session j_signon Boolean as authoritative authentication flag
- Session timeout managed by container (54 minutes in admin module)
- j_signon_username stored in session for request scope access
- Cookies only used for optional username persistence (not auth token)

### Configuration-Driven Protected Resources

- signon-config.xml declaratively lists protected URL patterns
- SignOnDAO parses and caches configuration
- Enables runtime changes without code modification
- Supports future role-based access control (roles field visible but unused)

## Implementation Scope

The capability includes:

- ✓ User entity with username and password
- ✓ Input validation (length, character set, password)
- ✓ User creation and password comparison
- ✓ Credential authentication via SignOnEJB
- ✓ Session attribute management (j_signon, j_signon_username)
- ✓ Protected resource configuration (signon-config.xml)
- ✓ Sign-on form with username/password fields
- ✓ "Remember username" cookie (30-day expiry)
- ✓ Protected resource access enforcement
- ✓ Post-login redirect to original URL
- ✓ Error page redirect on failed authentication

The capability does NOT include:

- Account lockout after failed attempts
- Password complexity requirements beyond length
- Multi-factor authentication
- Token-based authentication (JWT, OAuth, SAML)
- Password reset/recovery workflows
- User role or permission management

## Implementation Considerations

### Security

- **Password Storage**: Legacy stores plaintext; rebuild must use bcrypt/PBKDF2/scrypt
- **Cookie Security**: No HttpOnly or Secure flags on bp_signon cookie; should be added
- **CSRF Protection**: No CSRF tokens visible in legacy form; rebuild should add
- **HTTPS Enforcement**: Legacy doesn't enforce HTTPS; rebuild should require it
- **Session Fixation**: Legacy accepts any session ID; rebuild should regenerate on authentication

### Password Field Visibility

- Constants MAX_PASSWD_LENGTH not visible in provided code (value redacted)
- Validation code present but specific constraint unknown
- Recommendation: assume max 64-128 characters for modern password hashing

### Form Field Naming

- Field names (j_username, j_password, j_remember_username) are J2EE conventions
- Rebuild can use different names but must maintain contract for URL parameter parsing

### Cookie Age Calculation

- MaxAge = 2678400 seconds = 31 days (30.99...), not exactly 30 days
- Rebuild should preserve this value for compatibility

### Transaction Boundaries

- All authentication state changes occur within Required transactions
- Failed validation throws CreateException (implicitly rolls back transaction)
- Rebuild should preserve transactional semantics

### Error Messages

- Legacy provides descriptive messages (max length messages, invalid character message)
- Rebuild should preserve or improve error messaging

## Success Criteria

The implementation is successful when:

1. All username validation rules are enforced (length, character set)
2. All password validation rules are enforced (length constraint)
3. User creation and retrieval work with correct transaction semantics
4. Credential authentication returns correct boolean results
5. Session attributes are set/cleared correctly on successful/failed authentication
6. Protected resources are correctly identified and enforce authentication
7. Unauthenticated access redirects to sign-on form with URL preservation
8. Authenticated access redirects to original URL after login
9. Failed authentication redirects to error page without state changes
10. Remember-me cookie is created/cleared based on checkbox state
11. Sign-on form pre-populates username from cookie when present
12. All test scenarios in spec.md pass without behavioral regression
