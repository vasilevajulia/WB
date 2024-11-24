--1.1

SELECT DISTINCT
    cn.customer_id,
    cn.name,
    o_n.wait_time
FROM (
    SELECT
        customer_id,
        (CAST(shipment_date AS timestamp) - CAST(order_date AS timestamp)) AS wait_time,
        MAX(CAST(shipment_date AS timestamp) - CAST(order_date AS timestamp)) OVER () AS global_max_wait_time
    FROM orders_new
) o_n
JOIN customers_new cn ON o_n.customer_id = cn.customer_id
WHERE o_n.wait_time = o_n.global_max_wait_time
ORDER BY cn.customer_id;


--1.2
SELECT DISTINCT
    cn.customer_id,
    cn.name,
    o_n.order_count,
    o_n.avg_shipping_days,
    o_n.total_order_amount
FROM (
    SELECT
        customer_id,
        COUNT(order_id) AS order_count,
        AVG(EXTRACT(EPOCH FROM (CAST(shipment_date AS timestamp) - CAST(order_date AS timestamp))) / 86400) AS avg_shipping_days,
        SUM(order_ammount) AS total_order_amount,
        MAX(COUNT(order_id)) OVER () AS max_order_count
    FROM orders_new
    GROUP BY customer_id
) o_n
JOIN customers_new cn ON o_n.customer_id = cn.customer_id
WHERE o_n.order_count = o_n.max_order_count
ORDER BY o_n.total_order_amount DESC;


--1.3

WITH order_details AS (
    SELECT
        customer_id,
        SUM(CASE WHEN order_status = 'Approved' AND (CAST(shipment_date AS timestamp) - CAST(order_date AS timestamp)) > INTERVAL '5 days' THEN 1 ELSE 0 END) OVER (PARTITION BY customer_id) AS delayed_count,
        SUM(CASE WHEN order_status = 'Approved' AND (CAST(shipment_date AS timestamp) - CAST(order_date AS timestamp)) > INTERVAL '5 days' THEN order_ammount ELSE 0 END) OVER (PARTITION BY customer_id) AS delayed_total,
        SUM(CASE WHEN order_status = 'Cancel' THEN 1 ELSE 0 END) OVER (PARTITION BY customer_id) AS cancelled_count,
        SUM(CASE WHEN order_status = 'Cancel' THEN order_ammount ELSE 0 END) OVER (PARTITION BY customer_id) AS cancelled_total
    FROM orders_new
)
SELECT DISTINCT cn.name, od.delayed_count, od.cancelled_count, od.cancelled_total
FROM order_details od
JOIN customers_new cn ON cn.customer_id = od.customer_id
WHERE od.delayed_count > 0 OR od.cancelled_count > 0
ORDER BY od.cancelled_total DESC;


--2.1

WITH category_sales AS (
    SELECT
        p3.product_category,
        SUM(o.order_ammount) AS total_sales
    FROM orders_2 o
    JOIN products_3 p3 ON o.product_id = p3.product_id
    GROUP BY p3.product_category
),
max_category AS (
    SELECT product_category
    FROM category_sales
    ORDER BY total_sales DESC
    LIMIT 1
),
product_sales AS (
    SELECT
        o.product_id,
        p3.product_name,
        p3.product_category,
        SUM(o.order_ammount) AS total_sales
    FROM orders_2 o
    JOIN products_3 p3 ON o.product_id = p3.product_id
    GROUP BY o.product_id, p3.product_name, p3.product_category
),
max_product_sales_per_category AS (
    SELECT
        ps.product_category,
        ps.product_name,
        ps.total_sales,
        RANK() OVER (PARTITION BY ps.product_category ORDER BY ps.total_sales DESC) AS rank
    FROM product_sales ps
)

SELECT
    cs.product_category,
    cs.total_sales AS total_sales,
    mps.product_name AS top_product_name,
    mc.product_category AS max_category
FROM category_sales cs
JOIN max_product_sales_per_category mps
    ON cs.product_category = mps.product_category
JOIN max_category mc ON TRUE
WHERE mps.rank = 1
ORDER BY cs.total_sales DESC;

