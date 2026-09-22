# Notifications - Design Document

## Overview

The notifications system provides asynchronous email delivery via message-driven bean (MDB) that listens to a JMS queue, processes XML-formatted email messages, and sends them via Java Mail Session.

## Architecture

### Message-Driven Bean (MailerMDB)

- Implements MessageListener interface
- Listens to JMS Queue for TextMessages
- Executes onMessage() within Required transaction
- Processes emails asynchronously without blocking callers

### Email Processing Flow

1. TextMessage arrives on mailer queue
2. MailerMDB.onMessage() is invoked by container
3. XML text is extracted from message
4. Mail.fromXML() deserializes into Mail object with DTD validation
5. MailHelper.createAndSendMail() sends email via Mail Session

### Error Handling Strategy

- **MailerAppException** (mail transmission failures): caught and silently ignored
- **XMLDocumentException** (invalid XML): wrapped in EJBException, message redelivered
- **JMSException** (JMS errors): wrapped in EJBException, message redelivered

### Mail Entity Structure

```
Mail {
  address: String   // email recipient
  subject: String   // email subject
  content: String   // email body (HTML text)
}
```

Enforced by Mail.dtd schema:

```xml
<!ELEMENT Mail (Address, Subject, Content)>
<!ELEMENT Address (#PCDATA)>
<!ELEMENT Subject (#PCDATA)>
<!ELEMENT Content (#PCDATA)>
```

### Email Transmission Details

- Content type: text/html (hardcoded)
- Encoding: UTF-8
- Sent-date: current system date/time
- X-Mailer header: "JavaMailer"
- Recipient parsing: InternetAddress.parse(address, strict=false)

### JNDI Configuration

- Mail Session resource-ref: "mail/MailSession"
- JNDI lookup path: "java:comp/env/mail/MailSession"
- Container-managed resource

### Transaction Model

- Each message processing within Required transaction context
- Failed processing (XML/JMS errors) triggers automatic rollback and redelivery
- Mail transmission failures cause silent ignoring (processing continues)

## User Interface

No screen records were extracted for this capability; its user interface is unspecified.

## Legacy Implementation Notes

- Uses EJB 2.x message-driven bean pattern
- JNDI lookups in MailHelper via InitialContext
- DTD validation via XML parser (VALIDATING=true constant)
- JavaMail API for SMTP transmission
- ByteArrayDataSource for message content wrapping
