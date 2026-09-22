-- EXTRACTED FROM LEGACY SOURCE — evidence of what exists, not a build target. Where this disagrees with a capability delta spec, the delta spec wins.

-- Catalog Base Tables

CREATE TABLE category (
    catid VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE category_details (
    catid VARCHAR(255) NOT NULL,
    locale VARCHAR(16) NOT NULL,
    descn VARCHAR(2000),
    PRIMARY KEY (catid, locale),
    FOREIGN KEY (catid) REFERENCES category(catid)
);

CREATE TABLE product (
    productid VARCHAR(255) PRIMARY KEY,
    catid VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    FOREIGN KEY (catid) REFERENCES category(catid)
);

CREATE TABLE product_details (
    productid VARCHAR(255) NOT NULL,
    locale VARCHAR(16) NOT NULL,
    descn VARCHAR(2000),
    PRIMARY KEY (productid, locale),
    FOREIGN KEY (productid) REFERENCES product(productid)
);

CREATE TABLE item (
    itemid VARCHAR(255) PRIMARY KEY,
    productid VARCHAR(255) NOT NULL,
    productname VARCHAR(255),
    category VARCHAR(255),
    description VARCHAR(2000),
    attribute1 VARCHAR(255),
    attribute2 VARCHAR(255),
    attribute3 VARCHAR(255),
    attribute4 VARCHAR(255),
    attribute5 VARCHAR(255),
    imagelocation VARCHAR(2000),
    listprice DOUBLE,
    unitcost DOUBLE,
    FOREIGN KEY (productid) REFERENCES product(productid),
    FOREIGN KEY (category) REFERENCES category(catid)
);

CREATE TABLE item_details (
    itemid VARCHAR(255) NOT NULL,
    locale VARCHAR(16) NOT NULL,
    descn VARCHAR(2000),
    PRIMARY KEY (itemid, locale),
    FOREIGN KEY (itemid) REFERENCES item(itemid)
);

-- Order Data Model

CREATE TABLE purchaseorder (
    poid VARCHAR(255) PRIMARY KEY,
    pouserid VARCHAR(255) NOT NULL,
    poemailid VARCHAR(255) NOT NULL,
    podate BIGINT NOT NULL,
    polocale VARCHAR(16) DEFAULT 'en_US',
    povalue FLOAT
);

CREATE TABLE contactinfo (
    contactid VARCHAR(255) PRIMARY KEY,
    givenname VARCHAR(255) NOT NULL,
    familyname VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    telephone VARCHAR(20)
);

CREATE TABLE address (
    addressid VARCHAR(255) PRIMARY KEY,
    contactid VARCHAR(255) NOT NULL,
    street1 VARCHAR(255),
    street2 VARCHAR(255),
    city VARCHAR(255) NOT NULL,
    stateprovince VARCHAR(255) NOT NULL,
    postalcode VARCHAR(20) NOT NULL,
    country VARCHAR(255) NOT NULL,
    FOREIGN KEY (contactid) REFERENCES contactinfo(contactid) ON DELETE CASCADE
);

CREATE TABLE creditcard (
    cardid VARCHAR(255) PRIMARY KEY,
    poid VARCHAR(255) NOT NULL,
    cardnumber VARCHAR(255) NOT NULL,
    cardtype VARCHAR(50),
    expirydate VARCHAR(7),
    FOREIGN KEY (poid) REFERENCES purchaseorder(poid) ON DELETE CASCADE
);

CREATE TABLE lineitem (
    linenumber VARCHAR(255) PRIMARY KEY,
    poid VARCHAR(255) NOT NULL,
    categoryid VARCHAR(255),
    productid VARCHAR(255),
    itemid VARCHAR(255),
    quantity INT NOT NULL,
    unitprice FLOAT NOT NULL,
    quantityshipped INT DEFAULT 0,
    FOREIGN KEY (poid) REFERENCES purchaseorder(poid) ON DELETE CASCADE,
    FOREIGN KEY (categoryid) REFERENCES category(catid),
    FOREIGN KEY (productid) REFERENCES product(productid),
    FOREIGN KEY (itemid) REFERENCES item(itemid)
);

-- Supplier Order Model

CREATE TABLE supplierorder (
    poid VARCHAR(255) PRIMARY KEY,
    podate BIGINT,
    postatus VARCHAR(50)
);

-- Authentication Model

CREATE TABLE users (
    username VARCHAR(25) PRIMARY KEY,
    password VARCHAR(255) NOT NULL,
    CONSTRAINT username_len CHECK (LENGTH(username) >= 1 AND LENGTH(username) <= 25),
    CONSTRAINT username_chars CHECK (username NOT LIKE '%[%*]%')
);

-- Counter for Unique ID Generation

CREATE TABLE counter (
    name VARCHAR(255) PRIMARY KEY,
    value BIGINT NOT NULL DEFAULT 1
);

-- Session and Page Management Tables

CREATE TABLE pagetable (
    page_name VARCHAR(255) NOT NULL,
    locale VARCHAR(16) NOT NULL,
    template VARCHAR(2000),
    PRIMARY KEY (page_name, locale)
);

CREATE TABLE urlmapping (
    url VARCHAR(2000) PRIMARY KEY,
    screen VARCHAR(255) NOT NULL,
    isaction BOOLEAN DEFAULT FALSE,
    useflowhandler BOOLEAN DEFAULT FALSE,
    webactionclass VARCHAR(2000),
    ejbactionclass VARCHAR(2000),
    flowhandler VARCHAR(2000),
    requiressignin BOOLEAN DEFAULT FALSE
);

-- Indexes for Performance

CREATE INDEX idx_product_catid ON product(catid);
CREATE INDEX idx_item_productid ON item(productid);
CREATE INDEX idx_item_category ON item(category);
CREATE INDEX idx_category_details_locale ON category_details(locale);
CREATE INDEX idx_product_details_locale ON product_details(locale);
CREATE INDEX idx_item_details_locale ON item_details(locale);
CREATE INDEX idx_lineitem_poid ON lineitem(poid);
CREATE INDEX idx_lineitem_itemid ON lineitem(itemid);
CREATE INDEX idx_address_contactid ON address(contactid);
CREATE INDEX idx_creditcard_poid ON creditcard(poid);
CREATE INDEX idx_purchaseorder_pouserid ON purchaseorder(pouserid);
CREATE INDEX idx_purchaseorder_podate ON purchaseorder(podate);
CREATE INDEX idx_supplierorder_postatus ON supplierorder(postatus);

-- Stored Procedures/Functions for Common Queries

-- Search items by keyword (supports OR logic with tokenization)
-- Queries on: product name, category id, item description
-- Parameters: searchTerm (keyword), locale, startRow, pageSize

-- Pagination query helper
-- Uses: resultSet.absolute(startRow + 1), while resultSet.next() and count check
-- Returns: Page object with items, start index, hasNext flag
