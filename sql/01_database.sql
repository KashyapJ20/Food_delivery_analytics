
DROP DATABASE IF EXISTS food_delivery_db;
CREATE DATABASE food_delivery_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE food_delivery_db;


CREATE TABLE customers (
    customer_id                VARCHAR(10)     NOT NULL,
    city                       VARCHAR(30)     NOT NULL,
    signup_date                DATE            NOT NULL,
    loyalty_tier               VARCHAR(10)     NOT NULL,
    preferred_payment_method   VARCHAR(15)     NOT NULL,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT chk_loyalty_tier CHECK (loyalty_tier IN ('Bronze','Silver','Gold','Platinum')),
    CONSTRAINT chk_cust_payment CHECK (preferred_payment_method IN ('UPI','Credit Card','Debit Card','Cash','Wallet'))
) ENGINE=InnoDB;

CREATE TABLE restaurants (
    restaurant_id       VARCHAR(10)     NOT NULL,
    restaurant_name     VARCHAR(50)     NOT NULL,
    cuisine             VARCHAR(20)     NOT NULL,
    city                VARCHAR(30)     NOT NULL,
    rating              DECIMAL(2,1)    NOT NULL,
    CONSTRAINT pk_restaurants PRIMARY KEY (restaurant_id),
    CONSTRAINT chk_rating CHECK (rating BETWEEN 1.0 AND 5.0)
) ENGINE=InnoDB;

CREATE TABLE menu_items (
    item_id         VARCHAR(10)     NOT NULL,
    restaurant_id   VARCHAR(10)     NOT NULL,
    item_name       VARCHAR(50)     NOT NULL,
    category        VARCHAR(20)     NOT NULL,
    price           INT             NOT NULL,
    CONSTRAINT pk_menu_items PRIMARY KEY (item_id),
    CONSTRAINT fk_menu_restaurant FOREIGN KEY (restaurant_id)
        REFERENCES restaurants(restaurant_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_price CHECK (price > 0)
) ENGINE=InnoDB;

CREATE TABLE orders (
    order_id            VARCHAR(10)     NOT NULL,
    customer_id         VARCHAR(10)     NOT NULL,
    restaurant_id       VARCHAR(10)     NOT NULL,
    order_time          DATETIME        NOT NULL,
    delivery_time       DATETIME        NOT NULL,
    status              VARCHAR(15)     NOT NULL,
    delivery_duration   INT             NOT NULL,
    payment_method      VARCHAR(15)     NOT NULL,
    total_amount        INT             NOT NULL,
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_orders_restaurant FOREIGN KEY (restaurant_id)
        REFERENCES restaurants(restaurant_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_status CHECK (status IN ('Delivered','Preparing','Cancelled')),
    CONSTRAINT chk_order_payment CHECK (payment_method IN ('UPI','Credit Card','Debit Card','Cash','Wallet')),
    CONSTRAINT chk_duration CHECK (delivery_duration > 0),
    CONSTRAINT chk_total CHECK (total_amount > 0)
) ENGINE=InnoDB;

CREATE TABLE order_items (
    order_id      VARCHAR(10)     NOT NULL,
    item_id       VARCHAR(10)     NOT NULL,
    quantity      INT             NOT NULL,
    item_price    INT             NOT NULL,
    line_total    INT             NOT NULL,
    CONSTRAINT pk_order_items PRIMARY KEY (order_id, item_id),
    CONSTRAINT fk_oi_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_oi_item FOREIGN KEY (item_id)
        REFERENCES menu_items(item_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_qty CHECK (quantity > 0),
    CONSTRAINT chk_item_price CHECK (item_price > 0)
) ENGINE=InnoDB;
