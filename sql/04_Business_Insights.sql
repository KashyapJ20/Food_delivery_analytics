

--  total_amount is used for all revenue.
-- line_total is used only for item/category-level menu metrics.
USE food_delivery_db;

-- ================= REVENUE =================
-- Total orders, total revenue, average order value
SELECT COUNT(*) AS total_orders, 
		FORMAT(SUM(total_amount),0) AS total_revenue,
		ROUND(AVG(total_amount),2) AS avg_order_value
FROM orders WHERE status='Delivered';

--  Monthly revenue trend + running total (window function)
SELECT order_month, monthly_revenue,
	SUM(monthly_revenue) OVER (ORDER BY order_month) AS running_total
FROM (
    SELECT DATE_FORMAT(order_time,'%Y-%m') AS order_month,
	SUM(total_amount) AS monthly_revenue
    FROM orders WHERE status='Delivered'
    GROUP BY order_month
) x
ORDER BY order_month;

-- Revenue by city
SELECT r.city, SUM(o.total_amount) AS revenue, COUNT(*) AS orders
FROM orders o JOIN restaurants r ON o.restaurant_id=r.restaurant_id
WHERE o.status='Delivered'
GROUP BY r.city ORDER BY revenue DESC;

--  Revenue by cuisine
SELECT r.cuisine, SUM(o.total_amount) AS revenue, COUNT(*) AS orders
FROM orders o JOIN restaurants r ON o.restaurant_id=r.restaurant_id
WHERE o.status='Delivered'
GROUP BY r.cuisine ORDER BY revenue DESC;

--  Revenue by restaurant (top 20)
SELECT r.restaurant_name, r.city, r.cuisine, SUM(o.total_amount) AS revenue
FROM orders o JOIN restaurants r ON o.restaurant_id=r.restaurant_id
WHERE o.status='Delivered'
GROUP BY r.restaurant_id, r.restaurant_name, r.city, r.cuisine
ORDER BY revenue DESC LIMIT 20;

--  Revenue contribution % per restaurant (window function)
SELECT restaurant_name, revenue,
       ROUND(100.0*revenue/SUM(revenue) OVER (),2) AS pct_of_total_revenue
FROM (
    SELECT r.restaurant_name, SUM(o.total_amount) AS revenue
    FROM orders o JOIN restaurants r ON o.restaurant_id=r.restaurant_id
    WHERE o.status='Delivered'
    GROUP BY r.restaurant_id, r.restaurant_name
) t
ORDER BY revenue DESC LIMIT 15;


-- ================= CUSTOMERS =================

-- Number of customers per city
SELECT city, COUNT(*) AS customer_count
FROM customers GROUP BY city ORDER BY customer_count DESC;

--  Repeat customers (2+ delivered orders)
SELECT COUNT(*) AS repeat_customers FROM (
    SELECT customer_id FROM orders WHERE status='Delivered'
    GROUP BY customer_id HAVING COUNT(*) > 1
) t;

--  Repeat vs one-time customer split
SELECT CASE WHEN order_count > 1 THEN 'Repeat' ELSE 'One-time' END AS customer_type,
       COUNT(*) AS customers
FROM (
    SELECT customer_id, COUNT(*) AS order_count
    FROM orders WHERE status='Delivered' GROUP BY customer_id
) t
GROUP BY customer_type;

-- Customer segmentation by spend (CTE)
WITH spend AS (
    SELECT customer_id, SUM(total_amount) AS total_spend, COUNT(*) AS orders
    FROM orders WHERE status='Delivered' GROUP BY customer_id
)
SELECT
    CASE WHEN total_spend>=5000 THEN 'High Value'
         WHEN total_spend>=2000 THEN 'Mid Value'
         ELSE 'Low Value' END AS segment,
    COUNT(*) AS customers, ROUND(AVG(total_spend),2) AS avg_spend,
    ROUND(AVG(orders),2) AS avg_orders
FROM spend GROUP BY segment ORDER BY avg_spend DESC;

-- Top 20 customers by lifetime spend
SELECT c.customer_id, c.city, c.loyalty_tier,
       SUM(o.total_amount) AS lifetime_spend, COUNT(*) AS orders
FROM customers c JOIN orders o ON c.customer_id=o.customer_id
WHERE o.status='Delivered'
GROUP BY c.customer_id, c.city, c.loyalty_tier
ORDER BY lifetime_spend DESC LIMIT 20;

-- Average order value overall and by loyalty tier
SELECT 'Overall' AS grp, ROUND(AVG(total_amount),2) AS avg_order_value
FROM orders WHERE status='Delivered'
UNION ALL
SELECT c.loyalty_tier, ROUND(AVG(o.total_amount),2)
FROM orders o JOIN customers c ON o.customer_id=c.customer_id
WHERE o.status='Delivered' GROUP BY c.loyalty_tier;

--  Revenue share % by loyalty tier (window function)
SELECT loyalty_tier, tier_revenue,
       ROUND(100.0*tier_revenue/SUM(tier_revenue) OVER (),2) AS pct_of_total_revenue
FROM (
    SELECT c.loyalty_tier, SUM(o.total_amount) AS tier_revenue
    FROM customers c JOIN orders o ON c.customer_id=o.customer_id
    WHERE o.status='Delivered' GROUP BY c.loyalty_tier
) t
ORDER BY tier_revenue DESC;

-- Retention indicator: avg active months for repeat customers
SELECT ROUND(AVG(TIMESTAMPDIFF(MONTH, first_order, last_order)),2) AS avg_active_months
FROM (
    SELECT customer_id, MIN(order_time) AS first_order, MAX(order_time) AS last_order
    FROM orders WHERE status='Delivered' GROUP BY customer_id
    HAVING COUNT(*) > 1
) t;

-- ================= RESTAURANTS =================

--  Number of restaurants per cuisine
SELECT cuisine, COUNT(*) AS restaurant_count
FROM restaurants GROUP BY cuisine ORDER BY restaurant_count DESC;

--  Top 10 performing restaurants by revenue
SELECT r.restaurant_name, r.cuisine, r.city, r.rating, SUM(o.total_amount) AS revenue
FROM orders o JOIN restaurants r ON o.restaurant_id=r.restaurant_id
WHERE o.status='Delivered'
GROUP BY r.restaurant_id, r.restaurant_name, r.cuisine, r.city, r.rating
ORDER BY revenue DESC LIMIT 10;

--  Bottom 10 performing restaurants by revenue (includes zero-revenue)
SELECT r.restaurant_name, r.cuisine, r.city, r.rating,
       COALESCE(SUM(o.total_amount),0) AS revenue
FROM restaurants r
LEFT JOIN orders o ON o.restaurant_id=r.restaurant_id AND o.status='Delivered'
GROUP BY r.restaurant_id, r.restaurant_name, r.cuisine, r.city, r.rating
ORDER BY revenue ASC LIMIT 10;

-- Average rating overall and by cuisine
SELECT 'Overall' AS grp, ROUND(AVG(rating),2) AS avg_rating FROM restaurants
UNION ALL
SELECT cuisine, ROUND(AVG(rating),2) FROM restaurants GROUP BY cuisine
ORDER BY avg_rating DESC;

-- Top 3 restaurants per city by revenue (window function RANK)
SELECT * FROM (
    SELECT r.city, r.restaurant_name, SUM(o.total_amount) AS revenue,
           RANK() OVER (PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) AS city_rank
    FROM orders o JOIN restaurants r ON o.restaurant_id=r.restaurant_id
    WHERE o.status='Delivered'
    GROUP BY r.city, r.restaurant_id, r.restaurant_name
) ranked
WHERE city_rank <= 3
ORDER BY city, city_rank;

--  Cancellation rate by cuisine
SELECT r.cuisine, COUNT(*) AS total_orders,
       SUM(CASE WHEN o.status='Cancelled' THEN 1 ELSE 0 END) AS cancelled,
       ROUND(100.0*SUM(CASE WHEN o.status='Cancelled' THEN 1 ELSE 0 END)/COUNT(*),2) AS cancel_rate_pct
FROM orders o JOIN restaurants r ON o.restaurant_id=r.restaurant_id
GROUP BY r.cuisine ORDER BY cancel_rate_pct DESC;

-- Does restaurant rating band relate to cancellation rate?
SELECT
    CASE WHEN r.rating>=4.5 THEN '4.5-5.0'
         WHEN r.rating>=4.0 THEN '4.0-4.49'
         WHEN r.rating>=3.5 THEN '3.5-3.99'
         ELSE 'Below 3.5' END AS rating_band,
    COUNT(*) AS total_orders,
    ROUND(100.0*SUM(CASE WHEN o.status='Cancelled' THEN 1 ELSE 0 END)/COUNT(*),2) AS cancel_rate_pct
FROM orders o JOIN restaurants r ON o.restaurant_id=r.restaurant_id
GROUP BY rating_band ORDER BY rating_band DESC;

-- ================= ORDERS =================

-- Peak ordering hours
SELECT HOUR(order_time) AS hour_of_day, COUNT(*) AS orders
FROM orders GROUP BY hour_of_day ORDER BY orders DESC;

-- Weekend vs weekday orders
SELECT CASE WHEN DAYOFWEEK(order_time) IN (1,7) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
       COUNT(*) AS orders, SUM(total_amount) AS revenue,
       ROUND(AVG(total_amount),2) AS avg_order_value
FROM orders WHERE status='Delivered'
GROUP BY day_type;

--  Average delivery time overall and by city
SELECT 'Overall' AS grp, ROUND(AVG(delivery_duration),1) AS avg_minutes
FROM orders WHERE status='Delivered'
UNION ALL
SELECT r.city, ROUND(AVG(o.delivery_duration),1)
FROM orders o JOIN restaurants r ON o.restaurant_id=r.restaurant_id
WHERE o.status='Delivered' GROUP BY r.city
ORDER BY avg_minutes;

-- Customers with repeat orders at the same restaurant
SELECT o.customer_id, o.restaurant_id, r.restaurant_name, COUNT(*) AS repeat_orders
FROM orders o join restaurants r on o.restaurant_id = r.restaurant_id
WHERE status='Delivered'
GROUP BY customer_id, restaurant_id,restaurant_name
HAVING COUNT(*) > 1
ORDER BY repeat_orders DESC LIMIT 20;

-- ================= MENU =================

--  Best-selling items by quantity sold
SELECT mi.item_name, mi.category, r.restaurant_name,
       SUM(oi.quantity) AS units_sold, SUM(oi.line_total) AS item_revenue
FROM order_items oi
JOIN menu_items mi ON oi.item_id=mi.item_id
JOIN restaurants r ON mi.restaurant_id=r.restaurant_id
GROUP BY mi.item_id, mi.item_name, mi.category, r.restaurant_name
ORDER BY units_sold DESC LIMIT 15;

-- Category performance
SELECT mi.category, SUM(oi.quantity) AS units_sold, SUM(oi.line_total) AS revenue,
       COUNT(DISTINCT oi.order_id) AS orders_containing
FROM order_items oi JOIN menu_items mi ON oi.item_id=mi.item_id
GROUP BY mi.category ORDER BY revenue DESC;

-- Popular cuisines by order volume
SELECT r.cuisine, COUNT(*) AS orders, SUM(o.total_amount) AS revenue
FROM orders o JOIN restaurants r ON o.restaurant_id=r.restaurant_id
WHERE o.status='Delivered'
GROUP BY r.cuisine ORDER BY orders DESC;

-- ================= PAYMENTS =================

--  Payment method trends with % share (window function)
SELECT payment_method, COUNT(*) AS orders,
       ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (),2) AS pct,
       SUM(total_amount) AS revenue
FROM orders WHERE status='Delivered'
GROUP BY payment_method ORDER BY orders DESC;

-- Payment method by city
SELECT r.city, o.payment_method, COUNT(*) AS orders
FROM orders o JOIN restaurants r ON o.restaurant_id=r.restaurant_id
WHERE o.status='Delivered'
GROUP BY r.city, o.payment_method ORDER BY r.city, orders DESC;

-- Payment method by customer loyalty segment
SELECT c.loyalty_tier, o.payment_method, COUNT(*) AS orders
FROM orders o JOIN customers c ON o.customer_id=c.customer_id
WHERE o.status='Delivered'
GROUP BY c.loyalty_tier, o.payment_method ORDER BY c.loyalty_tier, orders DESC;
