## 1. User Entity and Storage

- [ ] 1.1 Define User entity with userName (primary key, max 25 chars) and password fields
- [ ] 1.2 Implement UserEJB as CMP 2.x entity bean with userName and password CMP fields
- [ ] 1.3 Implement UserLocal entity interface with getter/setter methods
- [ ] 1.4 Implement UserLocalHome home interface for entity creation and lookup

## 2. User Input Validation

- [ ] 2.1 Implement username length validation (max 25 characters)
- [ ] 2.2 Implement username character validation (reject '%' and '\*' characters)
- [ ] 2.3 Implement password length validation with configurable maximum
- [ ] 2.4 Raise CreateException with descriptive messages for all validation failures

## 3. Authentication Core Logic

- [ ] 3.1 Implement SignOnEJB stateless session bean for authentication operations
- [ ] 3.2 Implement authenticate(String userName, String password) method
- [ ] 3.3 Implement createUser(String userName, String password) method with validation
- [ ] 3.4 Implement password comparison via UserEJB.matchPassword() using String.equals()

## 4. Sign-On Filter Implementation

- [ ] 4.1 Implement SignOnFilter servlet filter for authentication interception
- [ ] 4.2 Implement doFilter() method to check j_signon session attribute
- [ ] 4.3 Implement protected resource matching against configured patterns
- [ ] 4.4 Implement validateSignOn() method for form credential processing
- [ ] 4.5 Implement session attribute management (j_signon_username, j_signon)
- [ ] 4.6 Implement redirect logic for unauthenticated protected resource access

## 5. Configuration Management

- [ ] 5.1 Implement signon-config.xml declarative configuration file
- [ ] 5.2 Define protected resources with URL patterns in security-constraint elements
- [ ] 5.3 Define signon-form-login-page configuration (signon.screen)
- [ ] 5.4 Define signon-form-error-page configuration (signon_error.screen)
- [ ] 5.5 Implement SignOnDAO for parsing signon-config.xml

## 6. Sign-On Form UI

- [ ] 6.1 Implement signon.jsp form with title "Sign In"
- [ ] 6.2 Implement j_username input field (text, size 15)
- [ ] 6.3 Implement j_password input field (password type, size 15)
- [ ] 6.4 Implement j_remember_username checkbox for username persistence
- [ ] 6.5 Implement form POST to j_signon_check action

## 7. Remember Username Feature

- [ ] 7.1 Implement cookie creation logic for remembered username
- [ ] 7.2 Set cookie name to "bp_signon"
- [ ] 7.3 Set cookie MaxAge to 2678400 seconds (30 days)
- [ ] 7.4 Implement cookie clearing when "remember username" is not selected
- [ ] 7.5 Implement JSP logic to pre-populate username field from cookie if present

## 8. Session Management

- [ ] 8.1 Implement session attribute "j_signon_username" for authenticated username storage
- [ ] 8.2 Implement session attribute "j_signon" as Boolean for authentication state
- [ ] 8.3 Implement session attribute "j_signon_original_url" for redirect target storage
- [ ] 8.4 Implement session attribute cleanup and refresh on authentication

## 9. Authentication Workflow

- [ ] 9.1 Implement validateSignOn() credential extraction from form parameters
- [ ] 9.2 Implement SignOnEJB.authenticate() invocation from filter
- [ ] 9.3 Implement session attribute population on successful authentication
- [ ] 9.4 Implement redirect to original URL after successful sign-on
- [ ] 9.5 Implement redirect to error page on authentication failure

## 10. Protected Resource Access Control

- [ ] 10.1 Implement URL pattern matching against configured protected resources
- [ ] 10.2 Implement forwarding to sign-on page for unauthenticated protected access
- [ ] 10.3 Implement original URL storage before redirecting to sign-on form
- [ ] 10.4 Implement pass-through for unprotected resources

## 11. Error Pages

- [ ] 11.1 Implement signon_error.screen page for failed authentication
- [ ] 11.2 Display descriptive error message on signon_error page
- [ ] 11.3 Implement link to retry sign-on form from error page

## 12. EJB Transaction Management

- [ ] 12.1 Configure SignOnEJB.authenticate() with Required transaction attribute
- [ ] 12.2 Configure SignOnEJB.createUser() with Required transaction attribute
- [ ] 12.3 Configure UserEJB.ejbCreate() with Required transaction attribute
- [ ] 12.4 Implement transaction rollback on validation failure
