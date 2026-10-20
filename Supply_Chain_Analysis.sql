-- ============================================================
-- SUPPLY CHAIN ANALYSIS
-- Author: Lovkesh Kumar
-- Tool: MySQL
-- Dataset file: Supply_Chain.csv
--
-- Assumptions:
-- 1. The CSV has been imported into a table named `supply_chain`.
-- 2. Column names match the dataset columns used below.
-- 3. Validate queries against your imported data before publishing findings.
-- ============================================================

-- Select your database before running this script.
-- Replace the database name if yours is different:
-- USE supply_chain_db;


-- 1. DATA OVERVIEW AND QUALITY CHECKS

SELECT * FROM supply_chain LIMIT 10;

SELECT COUNT(*) AS total_rows
FROM supply_chain;

SELECT
    COUNT(DISTINCT `Order Id`) AS unique_orders,
    COUNT(DISTINCT `Customer Id`) AS unique_customers,
    COUNT(DISTINCT `Order Item Id`) AS unique_order_items
FROM supply_chain;

-- Duplicate order-item IDs
SELECT `Order Item Id`, COUNT(*) AS row_count
FROM supply_chain
GROUP BY `Order Item Id`
HAVING COUNT(*) > 1;

-- Missing values in important fields
SELECT
    SUM(`Order Id` IS NULL) AS missing_order_id,
    SUM(`Customer Id` IS NULL) AS missing_customer_id,
    SUM(`Sales` IS NULL) AS missing_sales,
    SUM(`Order Profit Per Order` IS NULL) AS missing_profit,
    SUM(`Delivery Status` IS NULL) AS missing_delivery_status,
    SUM(`Shipping Mode` IS NULL) AS missing_shipping_mode,
    SUM(`Order Region` IS NULL) AS missing_region,
    SUM(`Category Name` IS NULL) AS missing_category
FROM supply_chain;

-- Negative or unusual numeric values
SELECT
    SUM(`Sales` < 0) AS negative_sales_rows,
    SUM(`Order Item Quantity` <= 0) AS nonpositive_quantity_rows,
    SUM(`Days for shipping (real)` < 0) AS negative_shipping_days,
    SUM(`Days for shipment (scheduled)` < 0) AS negative_scheduled_days,
    SUM(`Order Item Discount Rate` < 0 OR `Order Item Discount Rate` > 1)
        AS unusual_discount_rate_rows
FROM supply_chain;


-- 2. OVERALL BUSINESS KPIs

SELECT
    COUNT(DISTINCT `Order Id`) AS total_orders,
    COUNT(DISTINCT `Customer Id`) AS total_customers,
    SUM(`Order Item Quantity`) AS total_units_sold,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Order Profit Per Order`), 2) AS sum_profit_column,
    ROUND(SUM(`Sales`) / NULLIF(COUNT(DISTINCT `Order Id`), 0), 2)
        AS sales_per_order
FROM supply_chain;

-- Validate whether the profit field is stored per order or per order item
SELECT
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Order Profit Per Order`), 2) AS sum_profit_column,
    ROUND(100.0 * SUM(`Order Profit Per Order`) / NULLIF(SUM(`Sales`), 0), 2)
        AS calculated_margin_pct
FROM supply_chain;


-- 3. ORDER AND DELIVERY STATUS

SELECT
    `Delivery Status`,
    COUNT(*) AS order_item_rows,
    ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM supply_chain), 0), 2)
        AS row_percentage
FROM supply_chain
GROUP BY `Delivery Status`
ORDER BY order_item_rows DESC;

SELECT
    `Order Status`,
    COUNT(DISTINCT `Order Id`) AS unique_orders,
    ROUND(SUM(`Sales`), 2) AS total_sales
FROM supply_chain
GROUP BY `Order Status`
ORDER BY unique_orders DESC;

-- Late_delivery_risk is a risk flag, not necessarily observed late delivery
SELECT
    `Late_delivery_risk`,
    COUNT(*) AS order_item_rows,
    ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM supply_chain), 0), 2)
        AS row_percentage
FROM supply_chain
GROUP BY `Late_delivery_risk`
ORDER BY `Late_delivery_risk`;


-- 4. ACTUAL VS SCHEDULED SHIPPING

SELECT
    ROUND(AVG(`Days for shipping (real)`), 2) AS avg_actual_days,
    ROUND(AVG(`Days for shipment (scheduled)`), 2) AS avg_scheduled_days,
    ROUND(AVG(`Days for shipping (real)`)
        - AVG(`Days for shipment (scheduled)`), 2) AS average_day_difference
FROM supply_chain;

SELECT
    CASE
        WHEN `Days for shipping (real)` > `Days for shipment (scheduled)` THEN 'Late'
        WHEN `Days for shipping (real)` < `Days for shipment (scheduled)` THEN 'Early'
        WHEN `Days for shipping (real)` = `Days for shipment (scheduled)` THEN 'On Schedule'
        ELSE 'Unknown'
    END AS calculated_delivery_timing,
    COUNT(*) AS order_item_rows,
    ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM supply_chain), 0), 2)
        AS row_percentage
FROM supply_chain
GROUP BY calculated_delivery_timing
ORDER BY order_item_rows DESC;


-- 5. SHIPPING MODE PERFORMANCE

SELECT
    `Shipping Mode`,
    COUNT(*) AS order_item_rows,
    ROUND(AVG(`Days for shipping (real)`), 2) AS avg_actual_days,
    ROUND(AVG(`Days for shipment (scheduled)`), 2) AS avg_scheduled_days,
    ROUND(100.0 * AVG(`Late_delivery_risk`), 2) AS risk_flag_pct,
    ROUND(SUM(`Sales`), 2) AS total_sales
FROM supply_chain
GROUP BY `Shipping Mode`
ORDER BY risk_flag_pct DESC;

SELECT
    `Shipping Mode`,
    `Delivery Status`,
    COUNT(*) AS order_item_rows
FROM supply_chain
GROUP BY `Shipping Mode`, `Delivery Status`
ORDER BY `Shipping Mode`, order_item_rows DESC;


-- 6. REGION AND MARKET ANALYSIS

SELECT
    `Order Region`,
    COUNT(DISTINCT `Order Id`) AS unique_orders,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Order Profit Per Order`), 2) AS sum_profit_column,
    ROUND(AVG(`Days for shipping (real)`), 2) AS avg_shipping_days,
    ROUND(100.0 * AVG(`Late_delivery_risk`), 2) AS risk_flag_pct
FROM supply_chain
GROUP BY `Order Region`
ORDER BY total_sales DESC;

SELECT
    `Market`,
    COUNT(DISTINCT `Order Id`) AS unique_orders,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Order Profit Per Order`), 2) AS sum_profit_column
FROM supply_chain
GROUP BY `Market`
ORDER BY total_sales DESC;

SELECT
    `Order Country`,
    COUNT(DISTINCT `Order Id`) AS unique_orders,
    ROUND(SUM(`Sales`), 2) AS total_sales
FROM supply_chain
GROUP BY `Order Country`
ORDER BY total_sales DESC
LIMIT 10;


-- 7. CATEGORY, DEPARTMENT AND PRODUCT ANALYSIS

SELECT
    `Category Name`,
    SUM(`Order Item Quantity`) AS units_sold,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Order Profit Per Order`), 2) AS sum_profit_column
FROM supply_chain
GROUP BY `Category Name`
ORDER BY total_sales DESC;

SELECT
    `Department Name`,
    COUNT(DISTINCT `Order Id`) AS unique_orders,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Order Profit Per Order`), 2) AS sum_profit_column
FROM supply_chain
GROUP BY `Department Name`
ORDER BY total_sales DESC;

-- Top 10 products by sales
SELECT
    `Product Name`,
    SUM(`Order Item Quantity`) AS units_sold,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Order Profit Per Order`), 2) AS sum_profit_column
FROM supply_chain
GROUP BY `Product Name`
ORDER BY total_sales DESC
LIMIT 10;

-- 10 products with the lowest summed profit field
SELECT
    `Product Name`,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Order Profit Per Order`), 2) AS sum_profit_column
FROM supply_chain
GROUP BY `Product Name`
ORDER BY sum_profit_column ASC
LIMIT 10;


-- 8. CUSTOMER ANALYSIS

SELECT
    `Customer Segment`,
    COUNT(DISTINCT `Customer Id`) AS unique_customers,
    COUNT(DISTINCT `Order Id`) AS unique_orders,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Order Profit Per Order`), 2) AS sum_profit_column
FROM supply_chain
GROUP BY `Customer Segment`
ORDER BY total_sales DESC;

SELECT
    `Customer Id`,
    COUNT(DISTINCT `Order Id`) AS unique_orders,
    ROUND(SUM(`Sales`), 2) AS total_sales
FROM supply_chain
GROUP BY `Customer Id`
ORDER BY total_sales DESC
LIMIT 10;


-- 9. DISCOUNT ANALYSIS

SELECT
    CASE WHEN `Order Item Discount` > 0 THEN 'Discounted'
         ELSE 'No Discount'
    END AS discount_group,
    COUNT(*) AS order_item_rows,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Order Profit Per Order`), 2) AS sum_profit_column,
    ROUND(AVG(`Order Item Discount Rate`) * 100, 2) AS avg_discount_rate_pct
FROM supply_chain
GROUP BY discount_group;

SELECT
    `Category Name`,
    ROUND(AVG(`Order Item Discount Rate`) * 100, 2) AS avg_discount_rate_pct,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Order Profit Per Order`), 2) AS sum_profit_column
FROM supply_chain
GROUP BY `Category Name`
ORDER BY avg_discount_rate_pct DESC;


-- 10. MONTHLY AND YEARLY TRENDS
-- Assumes text dates like 1/31/2018 22:56.
-- If the column is already DATE/DATETIME, use it directly instead.

SELECT
    DATE_FORMAT(STR_TO_DATE(`order date (DateOrders)`, '%c/%e/%Y %H:%i'), '%Y-%m')
        AS order_month,
    COUNT(DISTINCT `Order Id`) AS unique_orders,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Order Profit Per Order`), 2) AS sum_profit_column
FROM supply_chain
GROUP BY order_month
ORDER BY order_month;

SELECT
    YEAR(STR_TO_DATE(`order date (DateOrders)`, '%c/%e/%Y %H:%i')) AS order_year,
    COUNT(DISTINCT `Order Id`) AS unique_orders,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Order Profit Per Order`), 2) AS sum_profit_column
FROM supply_chain
GROUP BY order_year
ORDER BY order_year;


-- 11. FINAL SUMMARY FOR A DASHBOARD

SELECT
    COUNT(DISTINCT `Order Id`) AS total_orders,
    COUNT(DISTINCT `Customer Id`) AS total_customers,
    SUM(`Order Item Quantity`) AS units_sold,
    ROUND(SUM(`Sales`), 2) AS total_sales,
    ROUND(SUM(`Order Profit Per Order`), 2) AS sum_profit_column,
    ROUND(AVG(`Days for shipping (real)`), 2) AS avg_actual_shipping_days,
    ROUND(AVG(`Days for shipment (scheduled)`), 2) AS avg_scheduled_shipping_days,
    ROUND(100.0 * AVG(`Late_delivery_risk`), 2) AS risk_flag_pct
FROM supply_chain;

-- End of analysis
