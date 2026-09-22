## 1. Mail Entity Model

- [ ] 1.1 Implement Mail class with three fields: address, subject, content (all Strings)
- [ ] 1.2 Implement Mail constructor accepting all three fields in order
- [ ] 1.3 Implement Mail getter methods: getAddress(), getSubject(), getContent()
- [ ] 1.4 Implement Mail.fromXML(String) static method with DTD validation enabled
- [ ] 1.5 Implement Mail.toXML() method returning XML representation
- [ ] 1.6 Implement XMLDocumentException throwing on schema validation failure
- [ ] 1.7 Set Mail.VALIDATING = true constant for all deserialization paths

## 2. MailerMDB Implementation

- [ ] 2.1 Implement MailerMDB as message-driven bean implementing MessageDrivenBean and MessageListener
- [ ] 2.2 Declare MailerMDB in ejb-jar.xml with message-driven-destination type=Queue
- [ ] 2.3 Implement onMessage(Message msg) method to process TextMessage
- [ ] 2.4 Cast incoming Message to TextMessage and extract text via getText()
- [ ] 2.5 Call Mail.fromXML() to deserialize message text
- [ ] 2.6 Extract address, subject, content from Mail object
- [ ] 2.7 Call MailHelper.createAndSendMail() with extracted fields and locale
- [ ] 2.8 Implement try-catch blocks for MailerAppException, XMLDocumentException, JMSException
- [ ] 2.9 Catch MailerAppException with empty body (silent failure, no re-throw)
- [ ] 2.10 Catch XMLDocumentException and JMSException; wrap in EJBException and throw

## 3. MailHelper Implementation

- [ ] 3.1 Implement MailHelper.createAndSendMail(emailAddress, subject, content, locale) method
- [ ] 3.2 Perform InitialContext lookup for Mail Session at "java:comp/env/mail/MailSession"
- [ ] 3.3 Create MimeMessage from looked-up Session
- [ ] 3.4 Call msg.setFrom() with no arguments (uses server default)
- [ ] 3.5 Parse recipient address via InternetAddress.parse(emailAddress, false)
- [ ] 3.6 Set recipients via msg.setRecipients(Message.RecipientType.TO, ...)
- [ ] 3.7 Set message subject via msg.setSubject(subject)
- [ ] 3.8 Create ByteArrayDataSource with content, "text/html" content type
- [ ] 3.9 Encode content as UTF-8 in ByteArrayDataSource constructor
- [ ] 3.10 Attach DataHandler to message with ByteArrayDataSource
- [ ] 3.11 Set X-Mailer header: msg.setHeader("X-Mailer", "JavaMailer")
- [ ] 3.12 Set Sent-Date header: msg.setSentDate(new Date())
- [ ] 3.13 Send message via Transport.send(msg)
- [ ] 3.14 Throw MailerAppException on Session lookup failure or SMTP error

## 4. JavaMail Configuration

- [ ] 4.1 Declare mail/MailSession resource-ref in MailerMDB ejb-jar.xml
- [ ] 4.2 Set resource ref-type to javax.mail.Session
- [ ] 4.3 Set resource res-auth to Container
- [ ] 4.4 Set resource res-sharing-scope to Shareable

## 5. MailerMDB EJB Configuration

- [ ] 5.1 Declare MailerMDB message-driven-destination with destination-type=javax.jms.Queue
- [ ] 5.2 Declare MailerMDB transaction-type=Container
- [ ] 5.3 Add container-transaction for onMessage() method with trans-attribute=Required
- [ ] 5.4 Declare method-params type javax.jms.Message for onMessage signature
- [ ] 5.5 Declare unchecked method-permission for MailerMDB (method-name=\*)

## 6. AsyncSenderEJB Implementation

- [ ] 6.1 Implement AsyncSenderEJB as stateless session bean implementing SessionBean interface
- [ ] 6.2 Declare AsyncSenderEJB in ejb-jar.xml with session-type=Stateless
- [ ] 6.3 Declare AsyncSenderEJB transaction-type=Container
- [ ] 6.4 Implement sendAMessage(String msg) method
- [ ] 6.5 Obtain QueueConnectionFactory from JNDI at "java:comp/env/jms/QueueConnectionFactory"
- [ ] 6.6 Obtain Queue from JNDI at "java:comp/env/jms/AsyncSenderQueue"
- [ ] 6.7 Create QueueConnection from factory via createQueueConnection()
- [ ] 6.8 Create QueueSession from connection (transacted=true, acknowledgeMode=0)
- [ ] 6.9 Create QueueSender from session for the queue
- [ ] 6.10 Create TextMessage via session.createTextMessage()
- [ ] 6.11 Set message text via jmsMsg.setText(msg)
- [ ] 6.12 Send message via qSender.send(jmsMsg)
- [ ] 6.13 Wrap exceptions in EJBException and throw
- [ ] 6.14 Close QueueConnection in finally block unconditionally

## 7. AsyncSenderEJB EJB Configuration

- [ ] 7.1 Declare jms/QueueConnectionFactory resource-ref in AsyncSenderEJB ejb-jar.xml
- [ ] 7.2 Set resource ref-type to javax.jms.QueueConnectionFactory
- [ ] 7.3 Set resource res-auth to Container
- [ ] 7.4 Declare jms/AsyncSenderQueue resource-env-ref in ejb-jar.xml
- [ ] 7.5 Set resource-env-ref-type to javax.jms.Queue
- [ ] 7.6 Add container-transaction for sendAMessage(String) with trans-attribute=Required
- [ ] 7.7 Declare method-params type java.lang.String for sendAMessage signature
- [ ] 7.8 Declare unchecked method-permission for AsyncSenderEJB (method-name=\*)

## 8. XML Processing and Validation

- [ ] 8.1 Ensure Mail DTD schema defines exact structure: Mail > (Address, Subject, Content)
- [ ] 8.2 Implement XML validation via XMLDocumentUtils with VALIDATING=true
- [ ] 8.3 Throw XMLDocumentException on DTD validation failure
- [ ] 8.4 Ensure Mail.fromXML() never returns a partially-constructed Mail object
- [ ] 8.5 Test XML deserialization with valid and invalid XML documents

## 9. Integration and Cross-Component Testing

- [ ] 9.1 Test MailerMDB receiving TextMessage from queue
- [ ] 9.2 Test Mail.fromXML() deserialization and validation
- [ ] 9.3 Test MailHelper.createAndSendMail() with valid email address
- [ ] 9.4 Test Mail Session lookup via JNDI
- [ ] 9.5 Test email transmission via JavaMail Transport
- [ ] 9.6 Test AsyncSenderEJB.sendAMessage() queuing messages
- [ ] 9.7 Test queue connection cleanup in finally block
- [ ] 9.8 Test MailerAppException silent failure (message discarded, no redelivery)
- [ ] 9.9 Test XMLDocumentException redelivery (EJBException thrown)
- [ ] 9.10 Test JMSException redelivery (EJBException thrown)

## 10. Error Handling and Edge Cases

- [ ] 10.1 Test Mail Session unavailability; verify MailerAppException caught and silently ignored
- [ ] 10.2 Test malformed XML; verify XMLDocumentException thrown and message redelivered
- [ ] 10.3 Test JMS transport error; verify EJBException thrown and message redelivered
- [ ] 10.4 Test recipient address parsing with non-RFC-compliant addresses (strict=false)
- [ ] 10.5 Test UTF-8 encoding with Unicode characters in email content
- [ ] 10.6 Test empty or null email fields; verify validation or appropriate error
- [ ] 10.7 Test very large email content; verify no buffer overflows or truncation

## 11. Transaction Management

- [ ] 11.1 Verify MailerMDB.onMessage() executes with Required transaction attribute
- [ ] 11.2 Verify AsyncSenderEJB.sendAMessage() executes with Required transaction attribute
- [ ] 11.3 Test transaction rollback on XMLDocumentException
- [ ] 11.4 Test transaction rollback on JMSException
- [ ] 11.5 Test transaction commit on successful email send
- [ ] 11.6 Test silent failure (MailerAppException) does not rollback transaction

## 12. Email Header and Encoding Verification

- [ ] 12.1 Verify X-Mailer header set to "JavaMailer" on all outgoing messages
- [ ] 12.2 Verify Sent-Date header set to current timestamp on all outgoing messages
- [ ] 12.3 Verify content-type header is "text/html"
- [ ] 12.4 Verify content encoding is UTF-8
- [ ] 12.5 Test email transmission with various character sets (ASCII, Latin-1, Unicode)
