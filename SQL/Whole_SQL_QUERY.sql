Create database churniq_analytics;
Use churniq_analytics;

Select Database();

USE churniq_analytics;

SELECT COUNT(*) AS total_customers
FROM customers;

SELECT COUNT(*) AS monthly_records
FROM monthly_behavior;

SELECT COUNT(*) AS churn_labels
FROM customer_churn_target;

show tables;
# Customer Churn Analysis
SELECT
    c.plan,
    COUNT(*) AS total_customers,
    SUM(t.churn_next_month) AS churned_customers,
    COUNT(*) - SUM(t.churn_next_month) AS retained_customers,
    ROUND(
        SUM(t.churn_next_month) * 100.0 / COUNT(*),
        2
    ) AS churn_rate_pct
FROM customers AS c
JOIN customer_churn_target AS t
    ON c.customer_id = t.customer_id
GROUP BY c.plan
ORDER BY churn_rate_pct DESC;

# Calculate monthly revenue

SELECT
    month,
    ROUND(SUM(current_mrr), 2) AS total_current_mrr,
    ROUND(SUM(previous_mrr), 2) AS total_previous_mrr,
    ROUND(
        (SUM(current_mrr) - SUM(previous_mrr))
        * 100.0 / SUM(previous_mrr),
        2
    ) AS mrr_change_pct
FROM monthly_behavior
GROUP BY month
ORDER BY month;

# Monthly Customer Engagement Analysis

SELECT
    month,
    ROUND(AVG(active_users), 2) AS avg_active_users,
    ROUND(AVG(login_count), 2) AS avg_login_count,
    ROUND(AVG(support_tickets), 2) AS avg_support_tickets
FROM monthly_behavior
GROUP BY month
ORDER BY month;

# Customer Churn Risk Analysis


SELECT
    c.customer_id,
    c.plan,
    c.mrr,
    b.active_users,
    b.login_count,
    b.support_tickets,
    t.churn_next_month
FROM customers AS c
JOIN customer_churn_target AS t
    ON c.customer_id = t.customer_id
JOIN monthly_behavior AS b
    ON c.customer_id = b.customer_id
WHERE t.churn_next_month = 1
ORDER BY b.login_count ASC
LIMIT 20;

# Churn Rate by subscription plan
SELECT
    c.plan,
    COUNT(*) AS total_customers,
    SUM(t.churn_next_month) AS churned_customers,
    ROUND(
        SUM(t.churn_next_month) * 100.0 / COUNT(*),
        2
    ) AS churn_rate_pct,
    ROUND(AVG(c.mrr), 2) AS avg_mrr
FROM customers AS c
JOIN customer_churn_target AS t
    ON c.customer_id = t.customer_id
GROUP BY c.plan
ORDER BY churn_rate_pct DESC;

# Monthly Churn Analysis

SELECT
    mb.month,
    COUNT(DISTINCT mb.customer_id) AS total_customers,
    SUM(ct.churn_next_month) AS churned_customers,
    ROUND(
        SUM(ct.churn_next_month) * 100.0
        / COUNT(DISTINCT mb.customer_id),
        2
    ) AS churn_rate_pct
FROM monthly_behavior AS mb
JOIN customer_churn_target AS ct
    ON mb.customer_id = ct.customer_id
GROUP BY mb.month
ORDER BY mb.month;

# Customer-Level Revenue Analysis

SELECT
    c.plan,
    COUNT(*) AS total_customers,
    ROUND(SUM(c.mrr), 2) AS total_mrr,
    ROUND(AVG(c.mrr), 2) AS avg_mrr,
    ROUND(
        SUM(c.mrr) * 100.0 /
        (SELECT SUM(mrr) FROM customers),
        2
    ) AS revenue_contribution_pct
FROM customers AS c
GROUP BY c.plan
ORDER BY total_mrr DESC;

# Customer Engagement by subscription plan
SELECT
    c.plan,
    COUNT(DISTINCT mb.customer_id) AS total_customers,
    ROUND(AVG(mb.active_users), 2) AS avg_active_users,
    ROUND(AVG(mb.login_count), 2) AS avg_login_count,
    ROUND(AVG(mb.support_tickets), 2) AS avg_support_tickets
FROM customers AS c
JOIN monthly_behavior AS mb
    ON c.customer_id = mb.customer_id
GROUP BY c.plan
ORDER BY avg_login_count DESC;

# Churn analysis by customer plan and engagement 
USE churniq_analytics;

SELECT
    c.plan,
    t.churn_next_month,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    ROUND(AVG(mb.active_users), 2) AS avg_active_users,
    ROUND(AVG(mb.login_count), 2) AS avg_login_count,
    ROUND(AVG(mb.support_tickets), 2) AS avg_support_tickets,
    ROUND(AVG(mb.current_mrr), 2) AS avg_mrr
FROM customers AS c
JOIN customer_churn_target AS t
    ON c.customer_id = t.customer_id
JOIN monthly_behavior AS mb
    ON c.customer_id = mb.customer_id
GROUP BY
    c.plan,
    t.churn_next_month
ORDER BY
    c.plan,
    t.churn_next_month;

# Identify High-Value Churn labeled customers
SELECT
    c.customer_id,
    c.plan,
    c.mrr,
    mb.active_users,
    mb.login_count,
    mb.support_tickets
FROM customers AS c
JOIN customer_churn_target AS t
    ON c.customer_id = t.customer_id
JOIN monthly_behavior AS mb
    ON c.customer_id = mb.customer_id
WHERE t.churn_next_month = 1
ORDER BY c.mrr DESC
LIMIT 20;

# Monthly MRR Trend
USE churniq_analytics;

SELECT
    month,
    ROUND(SUM(current_mrr), 2) AS total_mrr,
    ROUND(SUM(previous_mrr), 2) AS previous_mrr,
    ROUND(
        (SUM(current_mrr) - SUM(previous_mrr))
        * 100.0 / NULLIF(SUM(previous_mrr), 0),
        2
    ) AS mrr_change_pct
FROM monthly_behavior
GROUP BY month
ORDER BY month;

# DATA QUALITY check 
## Custoomer count
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM customers;
## Duplicates
SELECT
    customer_id,
    COUNT(*) AS occurrences
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;
## Missing values
SELECT
    SUM(customer_id IS NULL) AS missing_customer_id,
    SUM(plan IS NULL) AS missing_plan,
    SUM(mrr IS NULL) AS missing_mrr
FROM customers;
## Monthly behaviour record
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT month) AS unique_months
FROM monthly_behavior;
## DUplicate customer-month
SELECT
    customer_id,
    month,
    COUNT(*) AS occurrences
FROM monthly_behavior
GROUP BY customer_id, month
HAVING COUNT(*) > 1;

## ADVANCED SQL
# Case When
USE churniq_analytics;

SELECT
    customer_id,
    plan,
    mrr,
    CASE
        WHEN mrr >= 1000 THEN 'High Revenue'
        WHEN mrr >= 500 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_segment
FROM customers
ORDER BY mrr DESC;

## CTE- Churn Rate by plan
USE churniq_analytics;

WITH plan_summary AS (
    SELECT
        c.plan,
        COUNT(*) AS total_customers,
        SUM(t.churn_next_month) AS churned_customers
    FROM customers AS c
    JOIN customer_churn_target AS t
        ON c.customer_id = t.customer_id
    GROUP BY c.plan
)
SELECT
    plan,
    total_customers,
    churned_customers,
    ROUND(
        churned_customers * 100.0 / total_customers,
        2
    ) AS churn_rate_pct
FROM plan_summary
ORDER BY churn_rate_pct DESC;

# WINDOW FUNCTION
USE churniq_analytics;

SELECT
    customer_id,
    plan,
    mrr,
    RANK() OVER (ORDER BY mrr DESC) AS mrr_rank
FROM customers
ORDER BY mrr_rank
LIMIT 20;

# Final SQL VALIDATION 
## Row COunt
SELECT 'customers' AS table_name, COUNT(*) AS total_rows FROM customers
UNION ALL
SELECT 'monthly_behavior', COUNT(*) FROM monthly_behavior
UNION ALL
SELECT 'customer_churn_target', COUNT(*) FROM customer_churn_target;
## Churn Totals
SELECT
    churn_next_month,
    COUNT(*) AS customer_count
FROM customer_churn_target
GROUP BY churn_next_month;
## PLAN LEVEL CHURN RATES 
SELECT
    c.plan,
    COUNT(*) AS total_customers,
    SUM(t.churn_next_month) AS churned_customers,
    ROUND(100.0 * SUM(t.churn_next_month) / COUNT(*), 2) AS churn_rate_pct
FROM customers c
JOIN customer_churn_target t
    ON c.customer_id = t.customer_id
GROUP BY c.plan
ORDER BY churn_rate_pct DESC;