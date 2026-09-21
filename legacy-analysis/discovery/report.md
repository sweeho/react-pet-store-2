# PetStore J2EE Application - Discovery Report

## SX-0001 Spec Extraction Stage

### Executive Summary

This is a reference-implementation J2EE PetStore application (v1.3.2) built on Struts/JSP/EJB technologies. The application consists of a three-tier architecture with user-facing web applications, business logic components as EJB session/entity beans, and a database layer.

**Total Size:** ~53,700 LOC across 283 Java files and 98 JSP files  
**Primary Language:** Java (J2EE/EJB)  
**Architecture Style:** Classical J2EE monolith with service-oriented components  
**Framework Stack:** Struts web framework, EJB 2.0 entity and session beans, custom WAF (Web Application Framework)

---

## Application Structure

### Applications (Web Tier - User-Facing)

#### 1. **PetStore** (`apps/petstore/`)

- **LOC:** 5,640 Java + template/JSP files
- **Screens:** 67 JSP screens
- **Purpose:** Main consumer-facing e-commerce application
- **Key Responsibilities:**
  - Product catalog browsing
  - Shopping cart management
  - Order checkout
  - User account management
  - Multi-locale support (en_US, ja_JP, zh_CN)
- **Dependencies:** Catalog, Cart, Order, Customer, SignOn, Address, ContactInfo, CreditCard components
- **Risk Level:** High (directly visible to end users, business-critical paths)

#### 2. **Admin** (`apps/admin/`)

- **LOC:** 4,746 Java
- **Screens:** 4 JSP screens
- **Purpose:** Administrative backend interface
- **Key Responsibilities:**
  - Inventory/catalog management (presumed)
  - System administration functions
- **Risk Level:** Medium (restricted access, admin-only)

#### 3. **OPC** (`apps/opc/`)

- **LOC:** 3,145 Java
- **Screens:** 1 JSP screen
- **Purpose:** Order Processing Center (specialized workflow)
- **Risk Level:** Low-Medium (specialized, limited user base)

#### 4. **Supplier** (`apps/supplier/`)

- **LOC:** 2,260 Java
- **Screens:** 7 JSP screens
- **Purpose:** Supplier/partner portal
- **Key Responsibilities:**
  - Supplier order management
  - Inventory visibility
- **Dependencies:** SupplierPO, LineItem, ContactInfo, Address
- **Risk Level:** Medium (B2B-facing, partner-critical)

### Infrastructure & Framework

#### **WAF** (Web Application Framework) (`waf/`)

- **LOC:** 5,590 Java
- **Purpose:** Shared web infrastructure and utility framework
- **Key Components:**
  - MainServlet (front controller pattern)
  - TemplateServlet (view rendering)
  - Controller base classes
  - Support for locales, screen definitions, navigation
- **Used By:** All web applications
- **Risk Level:** High (single point of failure for all web apps; affects all screens/actions)

### Components (Business Logic Tier - EJB Session/Entity Beans)

#### Core Business Services

| Component          | LOC   | Scope   | Risk   | Purpose                                      |
| ------------------ | ----- | ------- | ------ | -------------------------------------------- |
| **catalog**        | 2,521 | Session | High   | Product master data, search, categories      |
| **signon**         | 1,047 | Session | High   | Authentication & user management             |
| **purchaseorder**  | 949   | Session | High   | Order creation, validation, state machine    |
| **processmanager** | 785   | Session | Medium | Order/workflow state machine orchestration   |
| **supplierpo**     | 759   | Session | Medium | Supplier PO handling, B2B workflows          |
| **customer**       | 724   | Session | High   | Customer profile, preferences, relationships |
| **servicelocator** | 658   | Utility | Low    | JNDI/EJB service lookup pattern              |

#### Supporting Data Access

| Component            | LOC        | Scope   | Risk   | Purpose                                 |
| -------------------- | ---------- | ------- | ------ | --------------------------------------- |
| **creditcard**       | 368        | Entity  | High   | Payment method storage & validation     |
| **cart**             | 494        | Session | High   | Shopping cart state & operations        |
| **lineitem**         | 477        | Entity  | Medium | Order/cart line items                   |
| **contactinfo**      | 498        | Entity  | Medium | Contact information (addresses, phones) |
| **address**          | 438        | Entity  | Medium | Address storage & validation            |
| **customer.account** | (embedded) | Entity  | High   | Customer account ledger                 |
| **customer.profile** | (embedded) | Entity  | Medium | Customer profile extensions             |

#### Support Services

| Component          | LOC   | Scope   | Risk   | Purpose                                |
| ------------------ | ----- | ------- | ------ | -------------------------------------- |
| **asyncsender**    | 263   | Session | Low    | Asynchronous message delivery (JMS)    |
| **mailer**         | 593   | Session | Low    | Email notification sending             |
| **xmldocuments**   | 1,932 | Utility | Medium | XML document handling & transformation |
| **uidgen**         | 360   | Session | Low    | Unique ID generation (database-backed) |
| **encodingfilter** | 80    | Servlet | Low    | Character encoding enforcement (UTF-8) |

---

## Architectural Patterns Identified

### 1. **Three-Tier Monolith**

- **Presentation:** JSP + Struts-style actions
- **Business Logic:** EJB session beans (stateless and stateful)
- **Data Access:** EJB entity beans + direct JDBC (Fast Lane Reader pattern)
- **Database:** Cloudscape (Derby) reference implementation; Oracle capable

### 2. **Controller/Action Pattern**

- Front controller (MainServlet) dispatches to action classes
- Separate action classes for EJB-tier and HTML/web-tier logic
- No Struts framework detected; custom WAF-based routing

### 3. **Service Locator Pattern**

- Dedicated `servicelocator` component for JNDI lookups
- EJB references registered in web.xml and ejb-jar.xml

### 4. **Entity Bean Usage**

- Traditional CMP (Container-Managed Persistence) entities
- Key entities: User, Customer, Account, Profile, CreditCard, Address, ContactInfo, LineItem, etc.

### 5. **Asynchronous Processing**

- JMS integration via AsyncSender
- Decouples long-running operations (mailer, notifications)

### 6. **Multi-Locale Support**

- TemplateServlet handles i18n
- Screen definitions per locale (en_US, ja_JP, zh_CN)
- Configuration-driven templating

---

## Data Flow (High Level)

```
Browser → MainServlet (.do routes) → HTML Action → EJB Session Bean → EJB Entity Beans + JDBC → Database
                                    ↓
                          Template Servlet (.screen rendering)
                                    ↓
                              JSP + Template fragments
```

**Fast Lane Reader:** Web tier (PetStore app) can read Catalog directly via JDBC (CatalogDAO) for read-heavy browsing operations, bypassing EJB for performance.

---

## Cross-Module Dependencies

### Critical Dependencies (Bidirectional)

**Customer Ecosystem:**

- PetStore app → Customer (session) → Account, Profile, Address, ContactInfo (entities)
- PetStore app → ContactInfo → Address (nested dependency)

**Order Ecosystem:**

- PetStore app → Cart (session) → Catalog (lookup items)
- PetStore app → Order (session, via ShoppingController) → PurchaseOrder → CreditCard, Address, ContactInfo
- Supplier app → SupplierPO → LineItem, Address, ContactInfo

**Authentication:**

- All apps → SignOn → User (entity)

**Support Services:**

- Any component → UniqueIdGenerator (for sequential IDs)
- Any component → AsyncSender (JMS delivery)

### Circular Dependencies (Potential Concerns)

- **ProcessManager** manages state but depends on Customer, Order, etc. (acceptable; orchestrator pattern)
- **XMLDocuments** may serialize/deserialize any entity (low coupling)

---

## Exclusions & Out-of-Scope

The following are noted as **NOT YET EXTRACTED**:

1. **Database Schema Details** — PopulateSQL.xml defines DDL but will require mapping to business rules
2. **Validation Rules** — Likely embedded in JSP/Java; no declarative validation.xml found
3. **Business Rules** — Thresholds, approval workflows, rounding logic mostly in Java code
4. **Workflow State Machines** — ProcessManager implies states; details in code
5. **Error Handling Conventions** — Message keys suggest error semantics; mapping TBD
6. **Performance/Caching Strategies** — May exist in Fast Lane or session state; not yet analyzed
7. **Security/Authorization** — SignOn component exists; role-based access control (RBAC) details unknown
8. **Integration Points** — AsyncSender and JMS integration noted but endpoints not yet traced

---

## Key Findings & Flags

### High-Risk Areas (Require Careful Extraction)

1. **Order Processing (`PurchaseOrder`, `ProcessManager`)** — Financial transactions; strict requirements expected.
2. **Customer Data** — Privacy-sensitive; compliance rules likely encoded.
3. **CreditCard Handling** — Payment card security; PCI DSS implications.
4. **Catalog (Fast Lane Pattern)** — Dual-path access (EJB + JDBC); consistency rules may exist.
5. **Multi-Locale Rendering** — Locale-specific rules; screen definitions differ by locale.

### Medium-Risk Areas

1. **Supplier Portal** — B2B workflows; SLA/approval rules.
2. **XMLDocuments** — Custom serialization; potential for undocumented transformations.
3. **Admin Interface** — Likely contains business-critical management functions.

### Low-Risk Areas (Good Candidates for Early Extraction)

1. **UniqueIdGenerator** — Stateless, well-scoped.
2. **EncodingFilter** — Simple UTF-8 conversion.
3. **MailerService** — Isolated notification logic.
4. **AddressValidation** — Self-contained, reusable.

---

## Modularity Assessment

**Strengths:**

- Clean separation of concerns (web vs. business vs. data tiers)
- Well-named EJB components; purposes are clear from names
- Service locator pattern reduces coupling
- Stateless session beans promote scalability

**Weaknesses:**

- Heavy use of entity beans (maintenance burden; legacy pattern)
- Custom WAF instead of standard framework (Struts, Spring) adds complexity
- JSP scriptlets likely contain business logic (mixed concerns)
- Fast Lane pattern for Catalog suggests ad-hoc optimization (maintenance debt)
- No visible separation between public API and internal implementation

---

## Next Steps (Extraction Phases)

### Phase 1 (Low Risk, High Clarity)

- UniqueIdGenerator
- EncodingFilter
- MailerService
- AddressData & AddressValidation

### Phase 2 (Medium Risk, Clear Scope)

- Catalog (product master; beware Fast Lane)
- Cart (shopping cart state)
- SignOn (authentication)
- Customer (profile management)

### Phase 3 (High Risk, Requires Deep Analysis)

- PurchaseOrder (order processing; financial)
- ProcessManager (workflow orchestration)
- CreditCard (payment; PCI implications)
- SupplierPO (B2B workflows)

### Phase 4 (Integration & Cross-Cutting)

- XMLDocuments (serialization strategy)
- AsyncSender (event/message handling)
- Multi-locale rules (screen definitions)
- Admin operations (tbd)

---

## Caveats & Open Questions

1. **Struts vs. Custom WAF** — Is there a struts-config.xml? Custom routing via MainServlet?
2. **Transaction Semantics** — EJB transaction attributes on entity beans? Boundaries unknown.
3. **Error Handling** — Are error codes/messages standardized? Mapping unknown.
4. **Caching Policy** — Any EJB object cache or query cache rules?
5. **Vendor Lock-in** — Cloudscape/Derby-specific DDL? Oracle branch exists but untested.
6. **Batch Processes** — Are there scheduled jobs (Quartz, etc.)? Not yet identified.
7. **Legacy Compatibility** — Any deprecated patterns still in use?

---

## Metadata

- **Source Version:** PetStore 1.3.2 (Sun Microsystems reference implementation)
- **Extraction Date:** 2026-09-21
- **Analysis Scope:** Complete directory tree survey
- **Confidence:** High for structure; Medium for business logic details (requires code dive)
