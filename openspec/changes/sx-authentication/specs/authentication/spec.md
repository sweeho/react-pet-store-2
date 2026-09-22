## ADDED Requirements

### Requirement: User entity representation

The system SHALL represent users as discrete entities with a unique username (primary key, max 25 characters) and password field for authentication.

#### Scenario: User entity with credentials

- **GIVEN** the authentication system initializes
- **WHEN** a user entity is created
- **THEN** the user has a unique username (max 25 chars) and encrypted/stored password

### Requirement: Username length validation

The system SHALL reject user account creation when the username exceeds 25 characters in length. A CreateException error message SHALL indicate the maximum allowed length.

#### Scenario: Username too long

- **GIVEN** a user creation request with username "this_username_is_too_long_for_the_system"
- **WHEN** the system validates the input
- **THEN** a CreateException is raised with message indicating 25-character limit

### Requirement: Username character validation

The system SHALL reject user account creation when the username contains the special characters '%' (percent) or '\*' (asterisk). A CreateException error message SHALL indicate that these characters are not allowed.

#### Scenario: Username contains prohibited characters

- **GIVEN** a user creation request with username "user%name" or "user\*name"
- **WHEN** the system validates the input
- **THEN** a CreateException is raised with message "User Id cannot have '%' or '\*' characters"

### Requirement: Password length validation

The system SHALL enforce a maximum password length constraint during user creation, rejecting passwords that exceed the configured maximum. The maximum is defined via UserLocal.MAX_PASSWD_LENGTH.

#### Scenario: Password exceeds maximum length

- **GIVEN** a user creation request with an excessively long password
- **WHEN** the system validates the password length
- **THEN** a CreateException is raised with message indicating the maximum password length

### Requirement: User authentication

The system SHALL authenticate a user by validating the supplied password against the stored password for a given username. Authentication returns false if the user is not found or the password does not match.

#### Scenario: User logs in with valid credentials

- **GIVEN** a user "testuser" with password "secret123"
- **WHEN** SignOnEJB.authenticate("testuser", "secret123") is called
- **THEN** the method returns true

#### Scenario: User logs in with invalid password

- **GIVEN** a user "testuser" with password "secret123"
- **WHEN** SignOnEJB.authenticate("testuser", "wrongpassword") is called
- **THEN** the method returns false

#### Scenario: Authentication attempt for non-existent user

- **GIVEN** no user exists with username "unknown"
- **WHEN** SignOnEJB.authenticate("unknown", "anypassword") is called
- **THEN** the method returns false (FinderException is caught)

### Requirement: User account creation

The system SHALL create a new user account with a provided username and password through the SignOnEJB.createUser() method, validating all constraints.

#### Scenario: New user is created successfully

- **GIVEN** a new username "newuser" and password "newpass123"
- **WHEN** SignOnEJB.createUser("newuser", "newpass123") is called
- **THEN** a new UserEJB entity is created and persisted with a Required transaction

### Requirement: Sign-on form interface

The system SHALL provide a form-based sign-on interface with username and password input fields named "j_username" and "j_password", submitting via POST to the "j_signon_check" action.

#### Scenario: Sign-on form is displayed

- **GIVEN** an unauthenticated user accessing a protected resource
- **WHEN** the user is redirected to the sign-on page
- **THEN** an HTML form is displayed with j_username and j_password input fields posting to j_signon_check

### Requirement: Username persistence in session

The system SHALL store the authenticated username in the HTTP session using the "j_signon_username" session attribute after successful authentication, making it available for reference by other components.

#### Scenario: Username stored in session after login

- **GIVEN** a user successfully authenticates with username "testuser"
- **WHEN** SignOnFilter processes the successful authentication
- **THEN** session.getAttribute("j_signon_username") returns "testuser"

### Requirement: Authentication state in session

The system SHALL maintain user authentication state in the HTTP session using a Boolean attribute keyed by "j_signon", authorizing access to protected resources only when this attribute is true.

#### Scenario: Authenticated user session state

- **GIVEN** a user successfully authenticated
- **WHEN** SignOnFilter checks the authentication state
- **THEN** session.getAttribute("j_signon") returns true

#### Scenario: Unauthenticated user is denied access

- **GIVEN** a request to a protected resource with j_signon = false or null
- **WHEN** SignOnFilter evaluates access
- **THEN** the request is denied and the user is redirected to sign-on form

### Requirement: Protected resource configuration

The system SHALL define protected resources via URL pattern matching declared in the signon-config.xml file. Each protected resource maps a URL pattern to a resource name and optional role-based access control list.

#### Scenario: Protected resource matches configured pattern

- **GIVEN** signon-config.xml defines a protected resource with URL pattern "customer.screen"
- **WHEN** a user accesses "customer.screen" without authentication
- **THEN** SignOnFilter matches the pattern and redirects to the sign-on form

### Requirement: Sign-on page configuration

The system SHALL declare the sign-on form page and error page URLs in configuration (signon.screen and signon_error.screen), allowing these pages to be referenced by the sign-on filter without hardcoding.

#### Scenario: Sign-on form page is loaded from configuration

- **GIVEN** signon-config.xml contains signon-form-login-page = "signon.screen"
- **WHEN** SignOnFilter initializes
- **THEN** it loads the sign-on page URL and uses it to forward unauthenticated requests

### Requirement: Authentication workflow with form submission

The system SHALL process user sign-on by validating credentials submitted via the j_signon_check URL, invoking SignOnEJB.authenticate(), and upon successful authentication, storing the username in the session attribute "j_signon_username" and setting "j_signon" to true, then redirecting to the original requested URL.

#### Scenario: User submits sign-on form successfully

- **GIVEN** a user submits the sign-on form with correct username and password
- **WHEN** SignOnFilter.validateSignOn() processes the POST to j_signon_check
- **THEN** authentication succeeds, session attributes are set, and user is redirected to the original URL

#### Scenario: User submits sign-on form with invalid credentials

- **GIVEN** a user submits the sign-on form with incorrect password
- **WHEN** SignOnFilter.validateSignOn() processes the POST to j_signon_check
- **THEN** authentication fails and user is redirected to signon_error.screen

### Requirement: Protected resource access check

When a user requests a protected resource URL, the SignOnFilter SHALL check if the user is signed on by verifying the j_signon session attribute is true. If the user is not signed on, the filter SHALL redirect to the sign-on page, storing the original URL in the session for post-login redirect.

#### Scenario: Unauthenticated access to protected resource

- **GIVEN** a user with j_signon = false or null accesses "customer.do"
- **WHEN** SignOnFilter.doFilter() evaluates the request
- **THEN** the original URL "customer.do" is stored in session.getAttribute("j_signon_original_url") and the request is forwarded to the sign-on form

### Requirement: Post-login redirect

The system SHALL redirect authenticated users to their originally requested URL after successful sign-on. The original URL SHALL be stored in the "j_signon_original_url" session attribute before redirecting to the sign-on form.

#### Scenario: User is redirected to original URL after login

- **GIVEN** a user accessed "customer.screen", was redirected to sign-on form, and successfully authenticated
- **WHEN** SignOnFilter.validateSignOn() completes successful authentication
- **THEN** the user is redirected to "customer.screen" via session.getAttribute("j_signon_original_url")

### Requirement: Authentication failure redirect

The system SHALL redirect users to the configured sign-on error page when authentication fails (username not found or password mismatch). The error page URL is configured in signon-config.xml.

#### Scenario: User sees error page on failed authentication

- **GIVEN** authentication fails due to wrong password
- **WHEN** SignOnFilter.validateSignOn() detects authentication failure
- **THEN** user is redirected to signon_error.screen as configured in signon-config.xml

### Requirement: Remember username cookie

The system SHALL optionally store the username in a browser cookie named "bp_signon" when the user checks the "remember username" checkbox during sign-on. The cookie SHALL expire after 30 days (2,678,400 seconds) if not cleared sooner.

#### Scenario: User selects remember username

- **GIVEN** user checks "Remember My User Name" checkbox and submits sign-on form
- **WHEN** SignOnFilter.validateSignOn() processes successful authentication
- **THEN** a cookie "bp_signon" is set with the username value and MaxAge = 2678400

#### Scenario: User unchecks remember username

- **GIVEN** the remember username checkbox is not checked
- **WHEN** SignOnFilter.validateSignOn() processes form submission
- **THEN** any existing "bp_signon" cookie is cleared (MaxAge = 0)

### Requirement: Pre-populate username from cookie

The system SHALL pre-populate the username field on the sign-on form with the value from the "bp_signon" cookie if present and non-empty.

#### Scenario: Sign-on form shows remembered username

- **GIVEN** a browser with valid "bp_signon" cookie = "saveduser"
- **WHEN** the sign-on form (signon.jsp) is rendered
- **THEN** the j_username input field is populated with "saveduser"

### Requirement: Protected resource declaration

The system SHALL protect access to specific application screens and actions that require authentication, including customer profile screen (customer.screen), customer action (customer.do), order entry screen (enter_order_information.screen), and sign-on welcome screen (signon_welcome.screen).

#### Scenario: Protected resource list is enforced

- **GIVEN** signon-config.xml declares four protected resources with URL patterns
- **WHEN** SignOnFilter checks a request URL against protected resources
- **THEN** URLs matching the declared patterns require authentication
