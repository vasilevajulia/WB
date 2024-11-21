--1.1 Группировка по возрасту как категории

SELECT city,
       age AS age_category,
       COUNT(*) AS user_count
FROM users
GROUP BY city, age
ORDER BY city, user_count DESC;

-- Группировка по возрастным диапазонам

SELECT city,
    CASE
        WHEN age BETWEEN 0 AND 20 THEN 'young'
        WHEN age BETWEEN 21 AND 49 THEN 'adult'
        WHEN age >= 50 THEN 'old'
    END AS age_category,
    COUNT(*) AS user_count
FROM users
GROUP BY city, age_category
ORDER BY city, user_count DESC;

--1.2 Средняя цена товаров по категориям

SELECT
    category,
    ROUND(CAST(AVG(price) AS NUMERIC), 2) AS avg_price
FROM products
WHERE name ILIKE '%hair%'
   OR name ILIKE '%home%'
GROUP BY category;

--2.1  "rich" и "poor"

SELECT
    seller_id,
    COUNT(DISTINCT category) AS total_categ,
    ROUND(AVG(CAST(rating AS NUMERIC)), 2) AS avg_rating,
    SUM(revenue) AS total_revenue,
    CASE
        WHEN SUM(revenue) > 50000 THEN 'rich'
        ELSE 'poor'
    END AS seller_type
FROM sellers
WHERE category != 'Bedding'
GROUP BY seller_id
HAVING COUNT(DISTINCT category) > 1;

--2.2 Месяцы регистрации и разница в сроках доставки неуспешных продавцов
--(под регистрацией подразумеваю самую раннюю дату для каждого продавца)

WITH filtered_sellers AS (
    SELECT
        seller_id,
        MIN(TO_DATE(date_reg, 'DD/MM/YYYY')) AS earliest_date,
        SUM(revenue) AS total_revenue,
        COUNT(DISTINCT category) AS category_count,
        MIN(CAST(delivery_days AS INTEGER)) AS min_delivery_days,
        MAX(CAST(delivery_days AS INTEGER)) AS max_delivery_days
    FROM sellers
    WHERE category != 'Bedding'
    GROUP BY seller_id
    HAVING COUNT(DISTINCT category) > 1 AND SUM(revenue) < 50000
),
delivery_stats AS (
    SELECT
        MAX(max_delivery_days) - MIN(min_delivery_days) AS max_delivery_difference
    FROM filtered_sellers
)
SELECT
    fs.seller_id,
    FLOOR(EXTRACT(EPOCH FROM (NOW() - fs.earliest_date)) / (30 * 24 * 60 * 60)) AS month_from_registration,
    ds.max_delivery_difference
FROM filtered_sellers fs
CROSS JOIN delivery_stats ds
ORDER BY fs.seller_id;

--2.3 Продавцы с двумя категориями товаров, зарегистрированные в 2022 году
--(под регистрацией не подразумеваю самую раннюю дату для каждого продавца)

WITH seller_categories AS (
    SELECT
        seller_id,
        STRING_AGG(category, ' — ' ORDER BY category) AS category_pair,
        SUM(revenue) AS total_revenue,
        COUNT(DISTINCT category) AS category_count
    FROM sellers
    WHERE EXTRACT(YEAR FROM TO_DATE(date_reg, 'DD/MM/YYYY')) = 2022
    GROUP BY seller_id
    HAVING COUNT(DISTINCT category) = 2 AND SUM(revenue) > 75000
)
SELECT
    seller_id,
    category_pair
FROM seller_categories
ORDER BY seller_id;
