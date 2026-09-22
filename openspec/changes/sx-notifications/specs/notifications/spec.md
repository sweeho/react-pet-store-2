## ADDED Requirements

### Requirement: Asynchronous email reception via JMS

The system SHALL receive email notifications asynchronously via a message-driven bean that listens to a JMS Queue for incoming mail TextMessage objects.

#### Scenario: Email message received from JMS queue

- **GIVEN** a MailerMDB message-driven bean listening to a JMS queue destination
- **WHEN** a TextMessage arrives on the mailer queue
- **THEN** the MailerMDB onMessage() method is invoked to process the message

### Requirement: Mail entity structure

The system SHALL support Mail entity objects that contain exactly three required fields: address (email recipient address), subject (email subject line), and content (email body text), in that order. Each field SHALL be a string.

#### Scenario: Mail entity is created with required fields

- **GIVEN** a Mail object with address "user@example.com", subject "Order Confirmation", and content "Your order has been placed"
- **WHEN** the Mail object is constructed with these three fields
- **THEN** all three fields are persisted and accessible via getAddress(), getSubject(), getContent() methods

### Requirement: XML deserialization with DTD validation

The system SHALL deserialize email message XML into a Mail object by parsing the XML against a Mail DTD schema. The XML structure SHALL be validated; schema-invalid XML SHALL cause an XMLDocumentException.

#### Scenario: Valid Mail XML is deserialized

- **GIVEN** an XML string with structure `<Mail><Address>addr</Address><Subject>subj</Subject><Content>body</Content></Mail>`
- **WHEN** Mail.fromXML(xmlString) is called
- **THEN** a Mail object is returned with address, subject, and content extracted from XML elements

#### Scenario: Invalid Mail XML fails validation

- **GIVEN** an XML string missing the required Content element
- **WHEN** Mail.fromXML(xmlString) is called
- **THEN** an XMLDocumentException is thrown and no Mail object is created

### Requirement: Email sending via JavaMail Session

The system SHALL send email using the J2EE Mail Session resource looked up from JNDI at "java:comp/env/mail/MailSession". Email transmission SHALL use the SMTP transport configured in the Mail Session.

#### Scenario: Email is sent using JNDI Mail Session

- **GIVEN** a Mail entity with valid recipient address and content
- **WHEN** sendMail() is invoked with address, subject, content, and locale
- **THEN** the system looks up the Mail Session from JNDI and sends the message via JavaMail Transport.send()

### Requirement: Email content encoding

The system SHALL encode email message content as UTF-8 bytes before attaching to the MIME message. Email messages SHALL include a MIME content type of "text/html".

#### Scenario: Email content is UTF-8 encoded with HTML type

- **GIVEN** email content "Café Français" (with Unicode characters)
- **WHEN** sendMail() prepares the message for transmission
- **THEN** the content is encoded as UTF-8 bytes and attached to the MimeMessage with DataHandler using "text/html" content type

### Requirement: Email headers

The system SHALL include an "X-Mailer" header set to "JavaMailer" and a "Sent-Date" header set to the current system date and time in every outgoing email message.

#### Scenario: Email headers are set on outgoing message

- **GIVEN** an outgoing email message
- **WHEN** sendMail() prepares the MimeMessage before transmission
- **THEN** msg.setHeader("X-Mailer", "JavaMailer") and msg.setSentDate(new Date()) are called

### Requirement: Email recipient address parsing

The system SHALL parse email recipient addresses using JavaMail's InternetAddress.parse() method with strict=false, allowing non-RFC-compliant addresses to be accepted without format validation.

#### Scenario: Non-RFC-compliant address is accepted

- **GIVEN** a recipient address "user@example" (missing TLD)
- **WHEN** sendMail() is invoked with this address
- **THEN** InternetAddress.parse(address, false) accepts the address without throwing an exception

### Requirement: Mail Session unavailability handling

When the Mail Session resource is unavailable or email transmission fails due to MailerAppException, the system SHALL catch the exception and continue processing without re-throwing to the container. The message SHALL be discarded and processing SHALL advance to the next message.

#### Scenario: Mail Session unavailable is silently ignored

- **GIVEN** a Mail message in the queue when the Mail Session is not configured
- **WHEN** MailerMDB.onMessage() attempts to send the email
- **THEN** MailerAppException is caught, the message is not re-delivered, and processing continues

### Requirement: JMS and XML parsing error handling

When JMS transport errors (JMSException) or XML parsing errors (XMLDocumentException) occur during message processing, the system SHALL wrap the exception in an EJBException and throw it, causing the message to be marked unprocessed and redelivered by the container.

#### Scenario: Malformed XML causes message redelivery

- **GIVEN** a malformed XML message in the queue
- **WHEN** MailerMDB.onMessage() parses it via Mail.fromXML()
- **THEN** XMLDocumentException is caught, wrapped in EJBException, thrown, and the container marks the message for redelivery

### Requirement: Transaction management for MailerMDB

The onMessage() method of MailerMDB SHALL execute with EJB container-managed transaction attribute "Required", meaning each message processing executes within a container-managed transaction context. On exception, the transaction SHALL be rolled back.

#### Scenario: Email processing executes in transaction context

- **GIVEN** a message arriving on the mailer queue
- **WHEN** MailerMDB.onMessage() is invoked
- **THEN** the method executes within a container-managed transaction with Required attribute

### Requirement: Asynchronous message sending via AsyncSenderEJB

The system SHALL support sending asynchronous messages via a stateless session bean that creates a JMS TextMessage, populates it with message content, and sends it to the AsyncSenderQueue for asynchronous delivery.

#### Scenario: Message is queued for async delivery

- **GIVEN** a string message to be sent asynchronously
- **WHEN** AsyncSenderEJB.sendAMessage(messageString) is invoked
- **THEN** a TextMessage is created, populated with the message text, and sent to AsyncSenderQueue

### Requirement: JMS queue connection management

The system SHALL obtain a QueueConnection from the JMS QueueConnectionFactory, create a QueueSession, and send the TextMessage to the queue. The QueueConnection SHALL be explicitly closed in a finally block to ensure resource cleanup regardless of success or exception.

#### Scenario: Queue connection is properly closed after sending

- **GIVEN** an invocation of sendAMessage()
- **WHEN** the message is sent and the method exits (success or exception)
- **THEN** the QueueConnection is closed in the finally block to return the connection to the pool

### Requirement: Transaction management for AsyncSenderEJB

The sendAMessage() method of AsyncSenderEJB SHALL execute with EJB container-managed transaction attribute "Required", ensuring the message send operation participates in a transaction context and is rolled back if the transaction fails.

#### Scenario: Message sending executes in transaction context

- **GIVEN** an invocation of AsyncSenderEJB.sendAMessage()
- **WHEN** the method executes
- **THEN** it participates in a container-managed transaction with Required attribute; exceptions cause rollback
