
USE food_delivery_db;

-- Orders are frequently filtered/grouped by these columns
CREATE INDEX idx_orders_status        ON orders(status);
CREATE INDEX idx_orders_order_time    ON orders(order_time);
CREATE INDEX idx_orders_customer      ON orders(customer_id);
CREATE INDEX idx_orders_restaurant    ON orders(restaurant_id);

-- Customers frequently sliced by city and loyalty tier
CREATE INDEX idx_customers_city       ON customers(city);
CREATE INDEX idx_customers_tier       ON customers(loyalty_tier);

-- Restaurants frequently sliced by cuisine and city
CREATE INDEX idx_restaurants_cuisine  ON restaurants(cuisine);
CREATE INDEX idx_restaurants_city     ON restaurants(city);

-- Menu items frequently grouped by category
CREATE INDEX idx_menu_category        ON menu_items(category);

-- order_items.item_id already indexed via FK, but order_id lookups
-- benefit from the composite PK; add item_id-first index for
-- "best selling items" queries that group by item across all orders
CREATE INDEX idx_oi_item              ON order_items(item_id);

