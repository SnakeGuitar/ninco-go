DROP DATABASE IF EXISTS Commerce;

CREATE DATABASE IF NOT EXISTS Commerce
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE Commerce;

CREATE TABLE Account
(
    account_id INT                         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    email      VARCHAR(128)                NOT NULL UNIQUE,
    password   VARCHAR(64)                 NOT NULL,
    role       ENUM ('CASHIER', 'ADMIN')   NOT NULL DEFAULT 'CASHIER',
    state      ENUM ('ACTIVE', 'INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME(6)                 NOT NULL DEFAULT NOW(6)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- Table: Store
CREATE TABLE Store
(
    store_id   INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(128) NOT NULL,
    address    VARCHAR(256) NOT NULL,
    phone      VARCHAR(15)  NOT NULL UNIQUE,
    created_at DATETIME(6)  NOT NULL DEFAULT NOW(6)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- Table: User
CREATE TABLE Employee
(
    employee_id INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    email       VARCHAR(128) NOT NULL UNIQUE,
    name        VARCHAR(64)  NOT NULL,
    last_name   VARCHAR(128) NOT NULL,
    store_id    INT          NULL     DEFAULT NULL,
    created_at  DATETIME(6)  NOT NULL DEFAULT NOW(6),
    FOREIGN KEY (email) REFERENCES Account (email) ON UPDATE CASCADE,
    FOREIGN KEY (store_id) REFERENCES Store (store_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

CREATE VIEW CompleteEmployeeView AS
SELECT A.account_id,
       E.employee_id,
       E.email,
       E.name,
       E.last_name,
       S.store_id,
       S.name as store_name,
       A.role,
       A.state,
       E.created_at
FROM Employee E
         JOIN Account A ON E.email = A.email
         LEFT JOIN Store S ON E.store_id = S.store_id;

CREATE VIEW CompleteStoreView AS
SELECT S.store_id,
       S.name,
       S.address,
       S.phone,
       S.created_at,
       (SELECT COUNT(*) FROM Employee E WHERE E.store_id = S.store_id) AS employee_count
FROM Store S;

-- Table: Access
CREATE TABLE Access
(
    access_id   INT                      NOT NULL AUTO_INCREMENT PRIMARY KEY,
    employee_id INT                      NOT NULL,
    action      ENUM ('LOGOUT', 'LOGIN') NOT NULL,
    created_at  DATETIME(6)              NOT NULL DEFAULT NOW(6),
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- Table: Product
CREATE TABLE Product
(
    product_id  INT            NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(128)   NOT NULL,
    description VARCHAR(512)   NOT NULL,
    brand       VARCHAR(64)    NOT NULL,
    price       DECIMAL(10, 2) NOT NULL,
    created_at  DATETIME(6)    NOT NULL DEFAULT NOW(6)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- Table: Invoice
CREATE TABLE Invoice
(
    invoice_id  INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    store_id    INT          NOT NULL,
    name_client VARCHAR(128) NOT NULL,
    created_at  DATETIME(6)  NOT NULL DEFAULT NOW(6),
    FOREIGN KEY (store_id) REFERENCES Store (store_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- Table: Sale
CREATE TABLE Sale
(
    sale_id     INT            NOT NULL AUTO_INCREMENT PRIMARY KEY,
    employee_id INT            NOT NULL,
    invoice_id  INT            NOT NULL,
    product_id  INT            NOT NULL,
    store_id    INT            NOT NULL,
    amount      INT            NOT NULL CHECK (amount > 0),
    price       DECIMAL(10, 2) NOT NULL,
    created_at  DATETIME(6)    NOT NULL DEFAULT NOW(6),
    FOREIGN KEY (invoice_id) REFERENCES Invoice (invoice_id),
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id),
    FOREIGN KEY (product_id) REFERENCES Product (product_id),
    FOREIGN KEY (store_id) REFERENCES Store (store_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- Table: Stock
CREATE TABLE Stock
(
    product_id INT         NOT NULL,
    store_id   INT         NOT NULL,
    quantity   INT         NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    created_at DATETIME(6) NOT NULL DEFAULT NOW(6),
    PRIMARY KEY (product_id, store_id),
    FOREIGN KEY (product_id) REFERENCES Product (product_id),
    FOREIGN KEY (store_id) REFERENCES Store (store_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

DROP VIEW IF EXISTS CompleteStockView;
CREATE VIEW CompleteStockView AS
SELECT ST.product_id,
       ST.store_id,
       quantity,
       P.name  AS product_name,
       S.name  AS store_name,
       P.price AS price,
       ST.created_at
FROM Stock ST
         JOIN Store S ON S.store_id = ST.store_id
         JOIN Product P on ST.product_id = P.product_id;

DROP VIEW IF EXISTS CompleteProductView;
CREATE VIEW CompleteProductView AS
SELECT P.product_id,
       P.name,
       P.description,
       P.brand,
       P.price,
       COALESCE(((SELECT SUM(quantity) FROM Stock S WHERE S.product_id = P.product_id)), 0) as stock,
       P.created_at
FROM Product P;

-- Table: PendingRegistrations
CREATE TABLE PendingRegistrations
(
    id         INT                       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    email      VARCHAR(128)              NOT NULL UNIQUE,
    pin        VARCHAR(10)               NOT NULL,
    expires_at DATETIME(6)               NOT NULL,
    created_at DATETIME(6)               NOT NULL DEFAULT NOW(6),
    password   TEXT                      NULL,
    role       ENUM ('CASHIER', 'ADMIN') NOT NULL DEFAULT 'CASHIER'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- Table: Session
CREATE TABLE Session
(
    token_id    VARCHAR(64) NOT NULL,
    employee_id INT         NOT NULL,
    created_at  DATETIME(6) NOT NULL DEFAULT NOW(6),
    expires_at  DATETIME(6) NOT NULL,
    PRIMARY KEY (token_id),
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

DROP USER IF EXISTS 'commerce_admin'@'localhost';
DROP ROLE IF EXISTS commerce_admin;

CREATE USER commerce_admin@localhost IDENTIFIED BY 'ADMIN_COMMERCE';
CREATE ROLE commerce_admin;
GRANT commerce_admin TO commerce_admin@localhost;
GRANT EXECUTE, SELECT, INSERT, UPDATE, DELETE ON Commerce.* TO commerce_admin;
SET DEFAULT ROLE ALL TO commerce_admin@localhost;

-- Smartphones (10 entries)
INSERT INTO Product (name, description, brand, price)
VALUES ('Galaxy S24 Ultra', 'Flagship smartphone featuring S Pen, 200MP camera, and Snapdragon 8 Gen 3 chip.',
        'Samsung', 1299.99),
       ('iPhone 16 Pro', 'High-end phone with A18 Bionic chip, 5x telephoto lens, and ProMotion display.', 'Apple',
        1199.00),
       ('Pixel 9 Pro', 'Smartphone with advanced artificial intelligence, clean Android OS, and computational camera.',
        'Google', 999.00),
       ('Xiaomi 14 Ultra', 'Phone with Leica camera system, 120W fast-charging battery, and AMOLED display.', 'Xiaomi',
        1050.50),
       ('OnePlus 12', 'Device known for great performance, fluid display, and 50W wireless charging.', 'OnePlus',
        899.99),
       ('Motorola Edge 50 Ultra', 'Smartphone with elegant design, versatile camera, and near-pure Android experience.',
        'Motorola', 750.00),
       ('Galaxy A55', 'Popular mid-range smartphone with AMOLED screen, long-lasting battery, and water resistance.',
        'Samsung', 429.99),
       ('iPhone SE (2024)', 'Compact and budget-friendly phone with a modern chip and Touch ID.', 'Apple', 499.00),
       ('Redmi Note 13 Pro', 'Great mid-range value with a 200MP camera and fast display refresh rate.', 'Xiaomi',
        350.00),
       ('Nokia G400', 'Affordable 5G phone focused on durability and battery life.', 'Nokia', 249.99);

-- Laptops and Computers (10 entries)
INSERT INTO Product (name, description, brand, price)
VALUES ('MacBook Pro M4 (14-inch)',
        'Professional laptop with M4 chip, Liquid Retina XDR display, and 18-hour battery life.', 'Apple', 2199.00),
       ('Dell XPS 13 Plus', 'Ultra-slim premium laptop with Intel Core Ultra processor and modern design.', 'Dell',
        1399.50),
       ('HP Spectre x360 14', '2-in-1 convertible laptop with OLED screen and optical pen capabilities.', 'HP',
        1250.00),
       ('Surface Laptop 6', 'Sleek Windows 11 laptop, optimized for Copilot and daily productivity.', 'Microsoft',
        999.00),
       ('Alienware m18 R2', 'Powerful gaming laptop with an 18-inch screen, RTX 4080 GPU, and high refresh rate.',
        'Dell', 2899.99),
       ('Lenovo ThinkPad X1 Carbon Gen 12',
        'Robust and lightweight business laptop with an ergonomic keyboard and advanced security.', 'Lenovo', 1750.00),
       ('ASUS ROG Zephyrus G16', 'Thin gaming laptop with excellent performance and a discreet design.', 'ASUS',
        1699.00),
       ('Acer Swift X', 'Lightweight laptop ideal for content creators with a dedicated GPU.', 'Acer', 899.00),
       ('iMac (24-inch) M3', 'All-in-one desktop computer featuring the M3 chip and an ultra-slim design.', 'Apple',
        1499.00),
       ('Dell Inspiron Desktop', 'General-purpose desktop computer for home or office use with an Core i5 CPU.', 'Dell',
        649.99);

-- Tablets (5 entries)
INSERT INTO Product (name, description, brand, price)
VALUES ('iPad Pro (M4)', 'Professional-grade tablet with M4 chip, OLED display, and Apple Pencil Pro support.', 'Apple',
        999.00),
       ('Galaxy Tab S10 Ultra', 'Large-format Android tablet with a 14.6-inch AMOLED display and S Pen included.',
        'Samsung', 1049.00),
       ('Google Pixel Tablet', 'Tablet with a charging dock that doubles as a smart home hub and speaker.', 'Google',
        499.00),
       ('Xiaomi Pad 6S Pro', 'Powerful tablet for productivity with a 144Hz screen and a high-end processor.', 'Xiaomi',
        699.99),
       ('Amazon Fire HD 10', 'Budget-friendly 10-inch tablet ideal for media consumption and Kindle reading.', 'Amazon',
        159.99);

-- Audio Accessories (8 entries)
INSERT INTO Product (name, description, brand, price)
VALUES ('AirPods Pro 3', 'Wireless earbuds with improved active noise cancellation and spatial audio.', 'Apple',
        249.00),
       ('Galaxy Buds 3 Pro', 'Samsung TWS earphones with Hi-Fi audio and ergonomic fit.', 'Samsung', 199.99),
       ('Sony WH-1000XM6', 'Industry-leading over-ear headphones with next-generation noise cancellation.', 'Sony',
        399.99),
       ('Bose QuietComfort Ultra', 'Premium over-ear headphones with best-in-class noise cancellation and Aware mode.',
        'Bose', 429.00),
       ('Jabra Elite 10', 'Comfortable earbuds optimized for calls and music with Dolby Atmos support.', 'Jabra',
        259.00),
       ('Sennheiser Momentum True Wireless 4', 'Audiophile TWS earbuds with high-resolution sound and aptX Adaptive.',
        'Sennheiser', 299.95),
       ('Echo Pop Speaker', 'Compact smart speaker with built-in Alexa.', 'Amazon', 49.99),
       ('JBL Flip 7', 'Portable, water-resistant Bluetooth speaker with powerful audio output.', 'JBL', 129.00);

-- Wearables and Gadgets (7 entries)
INSERT INTO Product (name, description, brand, price)
VALUES ('Apple Watch Series 10', 'Advanced smartwatch with new health features and a redesigned look.', 'Apple',
        399.00),
       ('Galaxy Watch 7 Classic', 'Samsung smartwatch with a rotating bezel and body composition analysis.', 'Samsung',
        349.99),
       ('Fitbit Charge 7', 'Fitness tracker with built-in GPS, sleep tracking, and health metrics.', 'Fitbit', 179.95),
       ('GoPro HERO 14 Black', 'Action camera with HyperSmooth 7.0 stabilization and 8K recording capability.', 'GoPro',
        599.00),
       ('DJI Mini 5 Pro', 'Foldable, lightweight drone with omnidirectional obstacle sensing and 4K camera.', 'DJI',
        950.00),
       ('Kindle Paperwhite (11th Gen)', 'E-reader with a 6.8-inch screen and adjustable warm light.', 'Amazon', 139.99),
       ('Meta Quest 4', 'High-performance virtual and mixed reality headset with pancake lenses.', 'Meta', 799.00);

INSERT INTO Store (name, address, phone)
VALUES ('Ninco - Midtown Manhattan', '150 W 34th St, New York, NY 10001', '2125550101'),
       ('Ninco - Williamsburg', '100 Wythe Ave, Brooklyn, NY 11249', '7185550102'),
       ('Ninco - Upper West Side', '2000 Broadway, New York, NY 10023', '2125550103'),
       ('Ninco - Flushing', '39-07 Prince St, Queens, NY 11354', '7185550104'),
       ('Ninco - Staten Island Mall', '2655 Richmond Ave, Staten Island, NY 10314', '7185550105');

-- Store IDs 1-5 correspond to the New York locations you created.

-- High Stock/Popular Items (Smartphones, Basic Accessories)
INSERT INTO Stock (product_id, store_id, quantity)
VALUES (2, 1, 150),
       (2, 2, 120),
       (2, 3, 160),
       (2, 4, 100),
       (2, 5, 90),   -- iPhone 16 Pro (ID 2)
       (1, 1, 110),
       (1, 2, 95),
       (1, 3, 105),
       (1, 4, 80),
       (1, 5, 75),   -- Galaxy S24 Ultra (ID 1)
       (6, 1, 75),
       (6, 2, 60),
       (6, 3, 80),
       (6, 4, 55),
       (6, 5, 50),   -- Motorola Edge 50 Ultra (ID 6)
       (11, 1, 60),
       (11, 2, 45),
       (11, 3, 70),
       (11, 4, 30),
       (11, 5, 40),  -- MacBook Pro M4 (ID 11)
       (21, 1, 90),
       (21, 2, 85),
       (21, 3, 100),
       (21, 4, 60),
       (21, 5, 70),  -- iPad Pro (M4) (ID 21)
       (26, 1, 200),
       (26, 2, 180),
       (26, 3, 210),
       (26, 4, 150),
       (26, 5, 160), -- AirPods Pro 3 (ID 26)
       (33, 1, 120),
       (33, 2, 100),
       (33, 3, 130),
       (33, 4, 80),
       (33, 5, 90);
-- Echo Pop Speaker (ID 33)

-- Medium Stock Items (Mid-Range Laptops, Tablets, High-End Audio)
INSERT INTO Stock (product_id, store_id, quantity)
VALUES (12, 1, 35),
       (12, 3, 40),
       (12, 5, 20), -- Dell XPS 13 Plus (ID 12) - Not in store 2 or 4
       (14, 1, 25),
       (14, 2, 30),
       (14, 3, 28),
       (14, 4, 15),
       (14, 5, 18), -- Surface Laptop 6 (ID 14)
       (18, 1, 40),
       (18, 2, 30),
       (18, 3, 45),
       (18, 4, 25),
       (18, 5, 30), -- Acer Swift X (ID 18)
       (22, 1, 25),
       (22, 2, 20),
       (22, 3, 28),
       (22, 5, 15), -- Galaxy Tab S10 Ultra (ID 22) - Not in store 4
       (28, 1, 55),
       (28, 2, 45),
       (28, 3, 60),
       (28, 4, 30),
       (28, 5, 35), -- Sony WH-1000XM6 (ID 28)
       (30, 1, 30),
       (30, 2, 25),
       (30, 3, 35),
       (30, 4, 18),
       (30, 5, 20);
-- Jabra Elite 10 (ID 30)

-- Low Stock/Specialized Items (Gaming, High-End Wearables, Drones)
INSERT INTO Stock (product_id, store_id, quantity)
VALUES (15, 1, 5),
       (15, 3, 8),  -- Alienware m18 R2 (ID 15) - Only in major Manhattan stores
       (17, 1, 10),
       (17, 2, 7),
       (17, 3, 12), -- ASUS ROG Zephyrus G16 (ID 17) - Limited distribution
       (36, 1, 20),
       (36, 3, 22),
       (36, 4, 15),
       (36, 5, 10), -- Apple Watch Series 10 (ID 36)
       (39, 1, 15),
       (39, 3, 10),
       (39, 5, 8),  -- GoPro HERO 14 Black (ID 39) - Limited to 3 stores
       (40, 1, 4),
       (40, 3, 3),  -- DJI Mini 5 Pro (ID 40) - Only in major Manhattan stores
       (37, 1, 6),
       (37, 3, 7),
       (37, 5, 4);
-- Galaxy Watch 7 Classic (ID 37) - Limited to 3 stores

-- Budget Items (High Quantity, High Turnover)
INSERT INTO Stock (product_id, store_id, quantity)
VALUES (7, 1, 180),
       (7, 2, 150),
       (7, 3, 190),
       (7, 4, 160),
       (7, 5, 140),  -- Galaxy A55 (ID 7)
       (10, 1, 100),
       (10, 2, 90),
       (10, 3, 110),
       (10, 4, 85),
       (10, 5, 75),  -- Nokia G400 (ID 10)
       (25, 1, 250),
       (25, 2, 200),
       (25, 3, 280),
       (25, 4, 220),
       (25, 5, 180), -- Amazon Fire HD 10 (ID 25)
       (35, 1, 130),
       (35, 2, 110),
       (35, 3, 140),
       (35, 4, 90),
       (35, 5, 100);
-- JBL Flip 7 (ID 35)

-- Inventory Management Example (Some products out of stock in specific locations)
INSERT INTO Stock (product_id, store_id, quantity)
VALUES (3, 1, 30),
       (3, 3, 35),
       (3, 5, 20),  -- Pixel 9 Pro (ID 3) - Out of stock in stores 2 and 4 (Brooklyn/Queens)
       (13, 2, 15),
       (13, 4, 12),
       (13, 5, 10), -- HP Spectre x360 14 (ID 13) - Out of stock in Manhattan
       (16, 1, 20),
       (16, 2, 18),
       (16, 3, 25), -- Lenovo ThinkPad X1 Carbon (ID 16) - Out of stock in stores 4 and 5
       (23, 1, 15),
       (23, 2, 10), -- Google Pixel Tablet (ID 23) - Only stocked in two locations
       (31, 1, 50),
       (31, 2, 45),
       (31, 3, 55),
       (31, 4, 30),
       (31, 5, 35), -- Sennheiser Momentum (ID 31)
       (38, 1, 30),
       (38, 2, 25),
       (38, 3, 33),
       (38, 4, 18),
       (38, 5, 20); -- Fitbit Charge 7 (ID 38)
