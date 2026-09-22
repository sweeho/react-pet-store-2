## ADDED Requirements

### Requirement: Asynchronous message-driven email processing

The system SHALL receive email notifications asynchronously via a message-driven bean that listens to a JMS Queue for incoming mail messages. Each TextMessage arriving on the queue SHALL be processed by invoking onMessage().

#### Scenario: Email message arrives on queue

- **GIVEN** a TextMessage on the mailer JMS queue
- **WHEN** the MailerMDB receives the message
- **THEN** the onMessage() method processes the message within a container-managed transaction

### Requirement: XML-based email message format

When a TextMessage arrives on the mailer queue, the system SHALL parse the message text as XML, deserialize it into a Mail object containing address, subject, and content, and send an email to the specified address.

#### Scenario: Valid XML email message is processed

- **GIVEN** a TextMessage containing valid Mail XML (Address, Subject, Content)
- **WHEN** MailerMDB.onMessage() receives the message
- **THEN** the XML is parsed and deserialized, and an email is sent to the recipient

### Requirement: Mail Session resource configuration

The system SHALL send email using the J2EE Mail Session resource looked up from JNDI at "java:comp/env/mail/MailSession".

#### Scenario: Mail Session is retrieved from JNDI

- **GIVEN** MailerMDB processing an email message
- **WHEN** sendMail() is invoked
- **THEN** MailHelper performs JNDI lookup of "java:comp/env/mail/MailSession" to obtain the configured Session

### Requirement: Email content type specification

Email messages SHALL be sent with HTML content type ("text/html").

#### Scenario: Email is sent as HTML

- **GIVEN** an email message with content
- **WHEN** the message is wrapped in a MIME message
- **THEN** the content is attached with contentType "text/html"

### Requirement: Email content encoding

Email message content SHALL be encoded as UTF-8 before being wrapped in a MIME message.

#### Scenario: Message content is UTF-8 encoded

- **GIVEN** an email with arbitrary text content
- **WHEN** the content is converted to a byte array
- **THEN** UTF-8 encoding is used

### Requirement: Mail transmission error handling

When the Mail Session is unavailable or an error occurs during email transmission, a MailerAppException SHALL be caught and silently ignored, allowing processing to continue.

#### Scenario: Mail transmission fails silently

- **GIVEN** a Mail Session that is unavailable or an error during transmission
- **WHEN** MailerMDB.onMessage() processes the message
- **THEN** the MailerAppException is caught and processing continues

### Requirement: XML and JMS error handling

XML parsing errors (XMLDocumentException) and JMS errors (JMSException) SHALL be wrapped in an EJBException and thrown, causing message processing to fail and the message to be redelivered.

#### Scenario: Malformed XML causes message redelivery

- **GIVEN** a TextMessage containing invalid XML
- **WHEN** Mail.fromXML() parses the message
- **THEN** an XMLDocumentException is caught and wrapped in an EJBException, and the message is redelivered

### Requirement: Transaction boundaries for message processing

The onMessage() method of MailerMDB SHALL execute with EJB transaction attribute "Required", meaning each message processing MUST run within a container-managed transaction.

#### Scenario: Message processing executes in transaction

- **GIVEN** a message on the mailer queue
- **WHEN** onMessage() is invoked
- **THEN** the container ensures execution within a Required transaction context

### Requirement: Mail entity structure

A Mail entity contains three required fields: address (email recipient), subject (email subject line), and content (email body text). These fields are enforced by the Mail DTD schema.

#### Scenario: Mail object is created from XML

- **GIVEN** XML containing Address, Subject, and Content elements
- **WHEN** Mail.fromXML() deserializes the XML
- **THEN** a Mail object is created with all three fields populated

### Requirement: Email headers

Email messages SHALL include a sent-date header with the current system date and time, and a custom X-Mailer header identifying the sender as "JavaMailer".

#### Scenario: Email headers are set

- **GIVEN** an email message being constructed
- **WHEN** MailHelper.createAndSendMail() builds the message
- **THEN** the sent-date header is set to the current date/time and X-Mailer="JavaMailer" is added

### Requirement: Email recipient address parsing

Email recipient addresses SHALL be parsed using JavaMail's InternetAddress.parse() method with strict=false, allowing non-standard addresses to be accepted without validation.

#### Scenario: Non-standard email address is parsed

- **GIVEN** an email recipient address that doesn't strictly conform to RFC standards
- **WHEN** MailHelper parses the address with InternetAddress.parse(emailAddress, false)
- **THEN** the address is accepted without throwing an exception

### Requirement: XML validation

Mail.fromXML() SHALL validate incoming XML against the Mail DTD schema using validating=true, causing malformed or invalid messages to throw XMLDocumentException and fail processing.

#### Scenario: Invalid XML is rejected

- **GIVEN** XML that doesn't conform to the Mail DTD schema
- **WHEN** Mail.fromXML() parses the XML with VALIDATING=true
- **THEN** an XMLDocumentException is thrown and message processing fails
