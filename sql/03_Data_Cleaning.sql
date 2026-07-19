-- NULL CHECKS — every NOT NULL column, defensively re-checked
SELECT 'customers' AS tbl,
    SUM(customer_id IS NULL) AS null_customer_id,
    SUM(city IS NULL) AS null_city,
    SUM(signup_date IS NULL) AS null_signup_date,
    SUM(loyalty_tier IS NULL) AS null_loyalty_tier,
    SUM(preferred_payment_method IS NULL) AS null_payment
FROM customers;

SELECT 'restaurants' AS tbl,
    SUM(restaurant_id IS NULL) AS null_id,
    SUM(restaurant_name IS NULL) AS null_name,
    SUM(cuisine IS NULL) AS null_cuisine,
    SUM(city IS NULL) AS null_city,
    SUM(rating IS NULL) AS null_rating
FROM restaurants;

SELECT 'menu_items' AS tbl,
    SUM(item_id IS NULL) AS null_item_id,
    SUM(restaurant_id IS NULL) AS null_restaurant_id,
    SUM(price IS NULL) AS null_price
FROM menu_items;

SELECT 'orders' AS tbl,
    SUM(order_id IS NULL) AS null_order_id,
    SUM(customer_id IS NULL) AS null_customer_id,
    SUM(restaurant_id IS NULL) AS null_restaurant_id,
    SUM(order_time IS NULL) AS null_order_time,
    SUM(delivery_time IS NULL) AS null_delivery_time,
    SUM(status IS NULL) AS null_status,
    SUM(total_amount IS NULL) AS null_total_amount
FROM orders;

SELECT 'order_items' AS tbl,
    SUM(order_id IS NULL) AS null_order_id,
    SUM(item_id IS NULL) AS null_item_id,
    SUM(quantity IS NULL) AS null_qty,
    SUM(line_total IS NULL) AS null_line_total
FROM order_items;

SELECT 'customers'    AS table_name, COUNT(*) AS row_count, 10000 AS expected FROM customers
UNION ALL
SELECT 'restaurants',                COUNT(*),              200   FROM restaurants
UNION ALL
SELECT 'menu_items',                 COUNT(*),              1200  FROM menu_items
UNION ALL
SELECT 'orders',                     COUNT(*),              30000 FROM orders
UNION ALL
SELECT 'order_items',                COUNT(*),              74887 FROM order_items;

-- DUPLICATE CHECKS
SELECT customer_id, COUNT(*) FROM customers GROUP BY customer_id HAVING COUNT(*) > 1;
SELECT restaurant_id, COUNT(*) FROM restaurants GROUP BY restaurant_id HAVING COUNT(*) > 1;
SELECT item_id, COUNT(*) FROM menu_items GROUP BY item_id HAVING COUNT(*) > 1;
SELECT order_id, COUNT(*) FROM orders GROUP BY order_id HAVING COUNT(*) > 1;
SELECT order_id, item_id, COUNT(*) FROM order_items GROUP BY order_id, item_id HAVING COUNT(*) > 1;

SELECT * FROM orders WHERE total_amount <= 0;
SELECT * FROM menu_items WHERE price <= 0;
SELECT * FROM order_items WHERE quantity <= 0;


