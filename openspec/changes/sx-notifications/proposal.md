# Notifications - Specification Proposal

## Summary

This specification extracts the notifications capability from the legacy Java Pet Store application. The system sends email notifications asynchronously via message-driven beans that receive messages from JMS queues, deserialize them from XML, and transmit emails using the JavaMail API.

## Problem Statement

The legacy notifications system distributes email logic across message-driven beans, XML parsing, and JavaMail helpers. The contracts governing XML structure, email transmission, error handling, and resource management are implicit in code and configuration rather than explicitly stated. This specification captures the notifications contracts so the capability can be rebuilt with clear behavioral boundaries and verifiable acceptance criteria.

## Solution Overview

Notifications capability consists of:

- **MailerMDB**: Message-driven bean receiving email TextMessages from JMS queue
- **Mail Entity**: XML-serializable value object with three fields (address, subject, content)
- **MailHelper**: Sends emails via J2EE Mail Session resource looked up from JNDI
- **AsyncSenderEJB**: Stateless session bean for queuing asynchronous messages
- **XML Deserialization**: Mail.fromXML() with DTD validation
- **Email Transmission**: JavaMail with UTF-8 encoding, text/html content type, X-Mailer header
- **Error Handling**: Silent failure for Mail Session unavailability; redelivery for parsing/transport errors
- **Transaction Management**: Container-managed transactions (Required attribute) for both MDB and sender EJB

## Key Behavioral Requirements

### Asynchronous Message Reception

MailerMDB listens to a JMS queue destination (destination-type=Queue). When a TextMessage arrives, onMessage() extracts the XML, deserializes it to a Mail object, and sends the email.

### Mail Entity Structure

Mail objects contain exactly three required String fields:

- address: email recipient address
- subject: email subject line
- content: email body text

All three fields must be present; the structure is enforced via DTD validation.

### XML Processing

Mail.fromXML() parses XML against Mail.dtd with validation enabled. Schema-invalid XML throws XMLDocumentException.

### Email Transmission

Emails are sent via MailHelper.createAndSendMail() using:

- Mail Session looked up from JNDI at "java:comp/env/mail/MailSession"
- UTF-8 content encoding
- text/html MIME content type
- X-Mailer header set to "JavaMailer"
- Sent-Date header set to current timestamp
- InternetAddress.parse(address, false) for non-strict recipient parsing

### Error Handling

- **MailerAppException** (Mail Session unavailable): Caught and silently ignored; message discarded
- **XMLDocumentException** (malformed XML): Wrapped in EJBException and thrown; container marks message for redelivery
- **JMSException** (transport error): Wrapped in EJBException and thrown; container marks message for redelivery

### Async Message Sending

AsyncSenderEJB.sendAMessage() creates a TextMessage, populates it, sends to AsyncSenderQueue, and closes the QueueConnection in a finally block for resource cleanup.

### Transaction Management

- MailerMDB.onMessage(): Container-managed transaction, Required attribute
- AsyncSenderEJB.sendAMessage(): Container-managed transaction, Required attribute

## Implementation Scope

Includes:

- ✓ Message-driven bean receiving messages from JMS queue
- ✓ Mail entity with address, subject, content fields
- ✓ XML deserialization with DTD validation
- ✓ Email transmission via JavaMail Mail Session (JNDI lookup)
- ✓ UTF-8 encoding, text/html content type
- ✓ Email headers (X-Mailer, Sent-Date)
- ✓ Non-strict recipient address parsing
- ✓ Error handling and redelivery semantics
- ✓ Container-managed transactions (Required)
- ✓ Async message sending via AsyncSenderEJB
- ✓ Queue connection management and cleanup

Excludes:

- MIME multipart messages or attachments
- Bulk email sending or batching
- Email delivery status tracking or confirmation
- Retry policies or delayed delivery
- Template-based email rendering
- Internationalized email addresses (IDN)
- DKIM or SPF signing
- Email compression or encryption
- Bounce/error handling from remote SMTP servers
- Rate limiting or throttling

## Implementation Considerations

### DTD Validation

Mail.fromXML() has VALIDATING=true hardcoded. This enforces schema validation for all incoming XML. Malformed XML causes immediate XMLDocumentException, not silent failure.

### Silent Failure Semantics

MailerAppException is silently ignored based on an inline comment in the legacy code: "ignore since user probably forgot to set up mail server". This appears to apply specifically to Mail Session configuration failures. The catch block has an empty body (throw is commented out), so the message is discarded without redelivery.

### Error Propagation

XMLDocumentException and JMSException are NOT silently ignored. These are wrapped in EJBException and thrown, causing the container to mark the message as unprocessed and schedule redelivery.

### Mail Session Lookup

The Mail Session is looked up once per sendMail() call, not cached. If lookup fails (JNDI resource not configured), it throws MailerAppException which is silently caught and ignored by MailerMDB.

### Connection Cleanup

AsyncSenderEJB.sendAMessage() uses try-finally to ensure QueueConnection.close() is called regardless of whether message sending succeeds or throws an exception. This is critical for returning connections to the pool in a high-volume scenario.

## Success Criteria

Implementation is successful when:

1. MailerMDB receives TextMessage from JMS queue
2. Mail.fromXML() deserializes XML with DTD validation
3. Emails are sent via Mail Session JNDI lookup with UTF-8 encoding
4. Outgoing emails include X-Mailer and Sent-Date headers
5. Mail Session unavailability is silently handled (message discarded)
6. Malformed XML and JMS errors trigger message redelivery
7. Both MailerMDB and AsyncSenderEJB execute with Required transaction attribute
8. Queue connections are properly closed in finally blocks
9. All acceptance criteria scenarios pass

## Assumptions and Constraints

- Mail Session is configured in application server deployment descriptor
- JMS queue destinations (mailer queue, AsyncSenderQueue) are configured
- JavaMail library is available on classpath
- UTF-8 is a supported character encoding
- X-Mailer header and Sent-Date header are not removed by transport layer
- InternetAddress.parse(address, false) accepts all intended non-standard addresses
- VALIDATING=true in Mail class is never changed
- MailerAppException wraps all Mail Session and SMTP failures
