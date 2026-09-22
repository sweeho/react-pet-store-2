## 1. Customer Entity

- [ ] 1.1 Define Customer CMP entity bean with userId (String) primary key
- [ ] 1.2 Implement one-to-one relationships to Account and Profile with cascade-delete
- [ ] 1.3 Implement findAllCustomers query using EJB-QL
- [ ] 1.4 Implement automatic Account and Profile creation in ejbPostCreate

## 2. Account Entity

- [ ] 2.1 Define Account CMP entity bean with status field
- [ ] 2.2 Implement one-to-one relationships to ContactInfo and CreditCard with cascade-delete
- [ ] 2.3 Implement two overloaded create methods (status only, and status+entities)
- [ ] 2.4 Implement empty ContactInfo and CreditCard creation in ejbPostCreate

## 3. Profile Entity

- [ ] 3.1 Define Profile CMP entity bean with four preference fields
- [ ] 3.2 Set default values (preferredLanguage="en_US", favoriteCategory=null, myListPreference=true, bannerPreference=true)
- [ ] 3.3 Implement one-to-one relationship to Customer with cascade-delete
- [ ] 3.4 Implement getter/setter methods for all preference fields

## 4. ContactInfo Entity

- [ ] 4.1 Define ContactInfo CMP entity bean with four contact fields (givenName, familyName, email, telephone)
- [ ] 4.2 Implement one-to-one relationship to Address with cascade-delete
- [ ] 4.3 Implement empty ContactInfo creation for new accounts
- [ ] 4.4 Implement getData() method for serialization

## 5. Address Entity

- [ ] 5.1 Define Address CMP entity bean with six address fields (streetName1, streetName2, city, state, zipCode, country)
- [ ] 5.2 Implement one-to-one relationship to ContactInfo with cascade-delete
- [ ] 5.3 Implement getter/setter methods for all address fields

## 6. CreditCard Integration

- [ ] 6.1 Implement one-to-one relationship from Account to CreditCard
- [ ] 6.2 Create empty CreditCard entities for new accounts
- [ ] 6.3 Implement cascade-delete relationship
- [ ] 6.4 Add ejb-local-ref for CreditCard in deployment descriptor

## 7. Transaction Management

- [ ] 7.1 Configure all entity bean methods with Required transaction attribute
- [ ] 7.2 Ensure cascade-delete operations participate in transaction
- [ ] 7.3 Implement transaction rollback on entity creation failures

## 8. Security Configuration

- [ ] 8.1 Declare all methods as unchecked in method-permission elements
- [ ] 8.2 Remove role-based access control restrictions
- [ ] 8.3 Allow any caller to invoke customer entity methods

## 9. Relationship Configuration

- [ ] 9.1 Define all CMR relationships in deployment descriptor
- [ ] 9.2 Set up one-to-one cardinality for all relationships
- [ ] 9.3 Configure cascade-delete for dependent entities
- [ ] 9.4 Verify relationship bidirectionality where applicable

## 10. JNDI Configuration

- [ ] 10.1 Configure ejb-local-ref for Account in Customer
- [ ] 10.2 Configure ejb-local-ref for Profile in Customer
- [ ] 10.3 Configure ejb-local-ref for ContactInfo in Account
- [ ] 10.4 Configure ejb-local-ref for CreditCard in Account
- [ ] 10.5 Configure ejb-local-ref for Address in ContactInfo
