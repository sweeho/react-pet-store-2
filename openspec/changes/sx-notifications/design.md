# Notifications - Design Document

## Overview

The notifications capability sends asynchronous email messages via two distinct JMS-based flows: a MailerMDB that receives email TextMessages and transmits them via JavaMail, and an AsyncSenderEJB that queues messages for async delivery. Both components are enterprise beans with container-managed transactions.

## Architecture

### Components

#### Message-Driven Email Processor

- **MailerMDB**: Message-driven bean (destination-type=Queue) that receives TextMessage objects
- **Mail**: XML-serializable value object with three fields (address, subject, content)
- **MailHelper**: Helper class that sends emails via JavaMail Mail Session (JNDI lookup)
- **ByteArrayDataSource**: MIME data source that encodes content as UTF-8 bytes

#### Asynchronous Message Sender

- **AsyncSenderEJB**: Stateless session bean with sendAMessage(String) method
- **QueueConnection**: Obtained from QueueConnectionFactory JNDI resource
- **QueueSession**: Created from QueueConnection
- **TextMessage**: JMS message type containing the async message text

### Workflows

#### Email Transmission Workflow

1. TextMessage arrives on MailerMDB queue destination
2. MailerMDB.onMessage() is invoked by container
3. TextMessage text is extracted via getText()
4. Mail.fromXML() deserializes XML with DTD validation
5. Mail fields (address, subject, content) are extracted
6. MailHelper.createAndSendMail() is called with extracted fields and locale
7. Mail Session is looked up from JNDI at "java:comp/env/mail/MailSession"
8. MimeMessage is created with UTF-8-encoded content
9. X-Mailer header set to "JavaMailer"
10. Sent-Date header set to current timestamp
11. Recipient address is parsed via InternetAddress.parse(address, false)
12. Email is sent via Transport.send(msg)
13. Exception handling:
    - MailerAppException (Session unavailable): Caught, silently ignored, message discarded
    - XMLDocumentException (malformed XML): Wrapped in EJBException, thrown for redelivery
    - JMSException (transport error): Wrapped in EJBException, thrown for redelivery

#### Async Message Sending Workflow

1. AsyncSenderEJB.sendAMessage(messageString) is invoked
2. QueueConnectionFactory is looked up from JNDI
3. QueueConnection is created from factory
4. QueueSession is created from connection (true = transacted, 0 = auto-ack)
5. QueueSender is obtained for AsyncSenderQueue
6. TextMessage is created via session.createTextMessage()
7. Message text is set via jmsMsg.setText(msg)
8. Message is sent via qSender.send(jmsMsg)
9. Exceptions are caught and wrapped in EJBException
10. QueueConnection is closed in finally block to return to pool

### Data Model

#### Mail Entity

- address: String (email recipient address)
- subject: String (email subject line)
- content: String (email body text)

All three fields required; no nulls allowed. Serializable to/from XML.

#### Mail XML Structure

```xml
<Mail>
  <Address>recipient@example.com</Address>
  <Subject>Subject Line</Subject>
  <Content>Email body content in HTML format</Content>
</Mail>
```

DTD validation enforced; schema-invalid XML causes XMLDocumentException.

### Configuration

#### JNDI Resources

- `java:comp/env/mail/MailSession`: javax.mail.Session (Mail Session resource)
- `java:comp/env/jms/QueueConnectionFactory`: javax.jms.QueueConnectionFactory
- `java:comp/env/jms/AsyncSenderQueue`: javax.jms.Queue

#### JMS Destinations

- Mailer Queue: Message-driven destination for MailerMDB (destination-type=Queue)
- AsyncSenderQueue: Destination for async messages (javax.jms.Queue)

#### Transaction Attributes

- MailerMDB.onMessage(): Container-managed, trans-attribute=Required
- AsyncSenderEJB.sendAMessage(): Container-managed, trans-attribute=Required

### Error Handling

**Silent Failure (MailerAppException)**

- Occurs when Mail Session is unavailable or SMTP transmission fails
- Caught in onMessage() catch block with empty body
- Message is not re-thrown; processing continues
- Message is discarded (not redelivered)
- Rationale (from inline comment): "user probably forgot to set up mail server"

**Fatal Failure (XMLDocumentException, JMSException)**

- Schema validation failures or JMS transport errors
- Wrapped in EJBException and thrown from onMessage()
- Container marks message as unprocessed
- Message redelivered by JMS provider

**Exception Handling in AsyncSenderEJB**

- Any exception during queue operations is caught and wrapped in EJBException
- Thrown to caller; message sending attempt fails atomically

### Threading and Concurrency

- MailerMDB: Container manages pooling; multiple instances may process messages concurrently
- AsyncSenderEJB: Stateless; container manages instance pooling and thread safety
- Queue connections are not shared; each sendAMessage() call creates its own connection (closed in finally)

### Performance Considerations

- Mail Session lookup occurs on every sendMail() call (not cached)
- Queue connections are created/closed per message (connection pooling managed by factory)
- Message parsing/XML deserialization happens in transaction context
- Email transmission (SMTP) may be I/O-bound; consider mail server configuration for throughput

### Locale Support

Mail content is transmitted as-is; no translation or locale-specific rendering is performed by the notification system. Locale parameter is passed to MailHelper but used only for logging/debugging. Email templates (if any) are constructed by the caller and passed as content.

## User Interface

No screen records were extracted for this capability; the notifications system has no user-facing user interface. Notification dispatch is initiated programmatically by other capabilities (order placement, order fulfillment) that queue Mail messages to the mailer JMS queue or invoke AsyncSenderEJB.sendAMessage() directly.

## Legacy Implementation Notes

- EJB 2.x message-driven beans with JMS Queue destination-type
- JavaMail API for SMTP transmission
- XML serialization with DTD validation
- Container-managed transactions (JTA)
- JNDI resource lookups for Mail Session and JMS resources
- Stateless session bean for async message sending
