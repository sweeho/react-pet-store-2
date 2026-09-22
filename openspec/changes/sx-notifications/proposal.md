# Notifications - Specification Proposal

## Summary

This specification extracts the email notifications capability from the legacy Java Pet Store application. The system processes asynchronous email delivery requests via a message-driven bean that receives XML-formatted messages from a JMS queue, validates them against a DTD schema, and sends emails via a configured Mail Session.

## Problem Statement

The legacy notification system uses EJB 2.x message-driven beans, JNDI resource lookups, and XML/DTD validation in an ad-hoc manner. The message formats, error handling, and transmission rules are scattered across multiple files and lifecycle methods. This specification captures the contracts so the capability can be reliably rebuilt.

## Solution Overview

Email notifications consist of:

- **MailerMDB**: Message-driven bean listening to JMS queue
- **Mail**: Entity representing email message structure (address, subject, content)
- **MailHelper**: Utility for constructing and sending email via JavaMail
- **DTD schema**: XML validation for incoming messages
- **Error handling**: Differential treatment (silent ignore vs. redelivery)

## Key Behavioral Requirements

### Message Processing

- Asynchronous reception via message-driven bean
- XML deserialization with DTD validation
- Transaction-wrapped processing with automatic redelivery on errors

### Email Transmission

- Content type: HTML
- Encoding: UTF-8
- Headers: sent-date (current time), X-Mailer ("JavaMailer")
- Recipient parsing: non-strict RFC compliance

### Error Handling

- Mail Session unavailable: silently ignore, continue processing
- Invalid XML or JMS errors: wrap in EJBException, trigger redelivery

## Implementation Scope

Includes:

- ✓ Message-driven bean for async processing
- ✓ XML message deserialization
- ✓ Mail entity with address/subject/content
- ✓ Email transmission via JavaMail
- ✓ DTD validation
- ✓ Error handling and redelivery
- ✓ Transaction management

Excludes:

- Rich email templates (HTML markup beyond text)
- Email attachments
- Multiple recipient support (only single TO address)
- SMTP authentication/TLS configuration
- Email scheduling/retry limits
- Notification preferences/opt-out

## Implementation Considerations

### Mail Session Configuration

- Container-managed resource via JNDI
- Default FROM address handled by mail server config
- Connection pooling managed by container

### Error Resilience

- Mail transmission failures result in silent discard (no redelivery)
- XML/JMS errors cause message redelivery (via exception wrapping)
- Design assumes mail server configuration is responsible for retries

### DTD Validation

- Incoming XML must conform to Mail schema
- Non-conforming messages cause exception and redelivery
- Validation is strict and enforced

## Success Criteria

Implementation is successful when:

1. MailerMDB receives and processes TextMessages from JMS queue
2. XML messages are validated against Mail DTD schema
3. Valid messages are deserialized to Mail objects
4. Emails are sent with HTML content type and UTF-8 encoding
5. Emails include sent-date and X-Mailer headers
6. Email addresses are parsed non-strictly
7. Mail transmission failures are silently ignored
8. XML/JMS errors trigger message redelivery
9. All processing occurs within Required transaction context
10. All test scenarios pass without behavioral regression
