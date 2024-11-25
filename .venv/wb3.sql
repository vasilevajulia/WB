--1.самая высокая зарплата в отделе (без оконных функций)
SELECT
    s.first_name,
    s.last_name,
    s.salary,
    s.industry,
    s.first_name || ' ' || s.last_name AS name_highest_sal
FROM Salary s
WHERE s.salary = (
    SELECT MAX(salary)
    FROM Salary
    WHERE industry = s.industry
)
ORDER BY s.industry;

--самая высокая зарплата в отделе (с оконными функциями)
WITH ranked_salaries AS (
    SELECT
        first_name,
        last_name,
        salary,
        industry,
        FIRST_VALUE(salary) OVER (PARTITION BY industry ORDER BY salary DESC) AS highest_salary
    FROM Salary
)
SELECT
    first_name,
    last_name,
    salary,
    industry,
    first_name || ' ' || last_name AS name_highest_sal
FROM ranked_salaries
WHERE salary = highest_salary
ORDER BY industry;

--самая низкая зарплата в отделе (без оконных функций)
SELECT
    s.first_name,
    s.last_name,
    s.salary,
    s.industry,
    s.first_name || ' ' || s.last_name AS name_lowest_sal
FROM Salary s
WHERE s.salary = (
    SELECT MIN(salary)
    FROM Salary
    WHERE industry = s.industry
)
ORDER BY s.industry;

--самая низкая зарплата в отделе (с оконными функциями)
WITH ranked_salaries AS (
    SELECT
        first_name,
        last_name,
        salary,
        industry,
        FIRST_VALUE(salary) OVER (PARTITION BY industry ORDER BY salary ASC) AS lowest_salary
    FROM Salary
)
SELECT
    first_name,
    last_name,
    salary,
    industry,
    first_name || ' ' || last_name AS name_lowest_sal
FROM ranked_salaries
WHERE salary = lowest_salary
ORDER BY industry;

--2.1
SELECT DISTINCT
    s.SHOPNUMBER,
    sh.CITY,
    sh.ADDRESS,
    SUM(s.QTY) OVER (PARTITION BY s.SHOPNUMBER) AS SUM_QTY,
    SUM(s.QTY * g.PRICE) OVER (PARTITION BY s.SHOPNUMBER) AS SUM_QTY_PRICE
FROM SALES s
JOIN SHOPS sh ON s.SHOPNUMBER = sh.SHOPNUMBER
JOIN GOODS g ON s.ID_GOOD = g.ID_GOOD
WHERE TO_DATE(s.DATE, 'DD.MM.YYYY') = TO_DATE('02.01.2016', 'DD.MM.YYYY')
ORDER BY s.SHOPNUMBER;

--2.2
WITH sales_per_date AS (
    SELECT
        s.DATE AS DATE_,
        sh.CITY,
        SUM(s.QTY * g.PRICE) AS SUM_SALES
    FROM SALES s
    JOIN SHOPS sh ON s.SHOPNUMBER = sh.SHOPNUMBER
    JOIN GOODS g ON s.ID_GOOD = g.ID_GOOD
    WHERE g.CATEGORY = 'ЧИСТОТА'
    GROUP BY s.DATE, sh.CITY
),
total_sales_per_date AS (
    SELECT
        DATE_,
        SUM(SUM_SALES) AS TOTAL_SALES
    FROM sales_per_date
    GROUP BY DATE_
)
SELECT
    spd.DATE_,
    spd.CITY,
    spd.SUM_SALES / tspd.TOTAL_SALES AS SUM_SALES_REL
FROM sales_per_date spd
JOIN total_sales_per_date tspd ON spd.DATE_ = tspd.DATE_
ORDER BY spd.DATE_, spd.CITY;

--2.3
WITH ranked_sales AS (
    SELECT
        s.DATE AS DATE_,
        s.SHOPNUMBER,
        s.ID_GOOD,
        SUM(s.QTY) AS TOTAL_QTY,
        RANK() OVER (PARTITION BY s.DATE, s.SHOPNUMBER ORDER BY SUM(s.QTY) DESC) AS RANK
    FROM SALES s
    GROUP BY s.DATE, s.SHOPNUMBER, s.ID_GOOD
)
SELECT
    rs.DATE_,
    rs.SHOPNUMBER,
    rs.ID_GOOD
FROM ranked_sales rs
WHERE rs.RANK <= 3
ORDER BY rs.DATE_, rs.SHOPNUMBER, rs.RANK;

--2.4
WITH daily_sales AS (
    SELECT
        s.DATE AS DATE,
        s.SHOPNUMBER,
        g.CATEGORY,
        SUM(s.QTY * g.PRICE) AS TOTAL_SALES
    FROM SALES s
    JOIN SHOPS sh ON s.SHOPNUMBER = sh.SHOPNUMBER
    JOIN GOODS g ON s.ID_GOOD = g.ID_GOOD
    WHERE sh.CITY = 'СПб'
    GROUP BY s.DATE, s.SHOPNUMBER, g.CATEGORY
)
SELECT
    ds.DATE,
    ds.SHOPNUMBER,
    ds.CATEGORY,
    LAG(ds.TOTAL_SALES, 1) OVER (PARTITION BY ds.SHOPNUMBER, ds.CATEGORY ORDER BY ds.DATE) AS PREV_SALES
FROM daily_sales ds
ORDER BY ds.DATE, ds.SHOPNUMBER, ds.CATEGORY;

--3.
CREATE TABLE query (
    searchid SERIAL PRIMARY KEY,
    year INT,
    month INT,
    day INT,
    userid INT,
    ts BIGINT,
    devicetype VARCHAR(50),
    deviceid VARCHAR(50),
    query VARCHAR(255)
);

INSERT INTO query (year, month, day, userid, ts, devicetype, deviceid, query)
VALUES
(2024, 11, 25, 1, 1700900000, 'android', 'device_1', 'к'),
(2024, 11, 25, 1, 1700900300, 'android', 'device_1', 'куп'),
(2024, 11, 25, 1, 1700900700, 'android', 'device_1', 'купить'),
(2024, 11, 25, 1, 1700901200, 'android', 'device_1', 'купить платье'),
(2024, 11, 25, 2, 1700900200, 'ios', 'device_2', 'п'),
(2024, 11, 25, 2, 1700900600, 'ios', 'device_2', 'по'),
(2024, 11, 25, 2, 1700900800, 'ios', 'device_2', 'подушка'),
(2024, 11, 25, 3, 1700900000, 'android', 'device_3', 'м'),
(2024, 11, 25, 3, 1700900200, 'android', 'device_3', 'моб'),
(2024, 11, 25, 3, 1700900400, 'android', 'device_3', 'мобильный'),
(2024, 11, 25, 3, 1700900900, 'android', 'device_3', 'мобильный тел'),
(2024, 11, 25, 3, 1700901500, 'android', 'device_3', 'мобильный телефон'),
(2024, 11, 25, 4, 1700900500, 'android', 'device_4', 'ко'),
(2024, 11, 25, 4, 1700900700, 'android', 'device_4', 'костюм'),
(2024, 11, 25, 4, 1700901000, 'android', 'device_4', 'костюм о'),
(2024, 11, 25, 4, 1700901600, 'android', 'device_4', 'костюм офисный'),
(2024, 11, 25, 4, 1700900500, 'ios', 'device_4', 'пом'),
(2024, 11, 25, 4, 1700900800, 'ios', 'device_4', 'помада'),
(2024, 11, 25, 4, 1700901100, 'ios', 'device_4', 'помада крас'),
(2024, 11, 25, 4, 1700901400, 'ios', 'device_4', 'помада красная');

WITH query_analysis AS (
    SELECT
        *,
        LEAD(query) OVER (PARTITION BY userid, devicetype, deviceid ORDER BY ts) AS next_query,
        LEAD(ts) OVER (PARTITION BY userid, devicetype, deviceid ORDER BY ts) AS next_ts,
        ts - LAG(ts) OVER (PARTITION BY userid, devicetype, deviceid ORDER BY ts) AS time_diff_prev,
        LEAD(ts) OVER (PARTITION BY userid, devicetype, deviceid ORDER BY ts) - ts AS time_diff_next
    FROM query
),
is_final_calculation AS (
    SELECT
        year,
        month,
        day,
        userid,
        ts,
        devicetype,
        deviceid,
        query,
        next_query,
        CASE
            WHEN next_ts IS NULL THEN 1
            WHEN time_diff_next > 180 THEN 1
            WHEN time_diff_next > 60 AND CHAR_LENGTH(next_query) < CHAR_LENGTH(query) THEN 2
            ELSE 0
        END AS is_final
    FROM query_analysis
)
SELECT
    year,
    month,
    day,
    userid,
    ts,
    devicetype,
    deviceid,
    query,
    next_query,
    is_final
FROM is_final_calculation
WHERE devicetype = 'android' AND is_final IN (1, 2)
  AND year = 2024 AND month = 11 AND day = 25
ORDER BY ts;
