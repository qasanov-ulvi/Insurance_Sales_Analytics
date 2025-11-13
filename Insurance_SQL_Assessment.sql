-- Pasha Insurance Data Analytics Assessment (Final Version)
-- Author: Ulvi Hasanov
-- Database: MySQL / PostgreSQL Compatible
-- Note: Claim Ratio = SUM(approved_amount) / SUM(premium_amount)
--       Renewal Rate = Renewed / Expired

-- =====================
-- 1. Monthly Premium and Approved Claims by Insurance Type
-- =====================
SELECT
    DATE_FORMAT(p.start_date, '%Y-%m') AS month,
    p.insurance_type,
    SUM(p.premium_amount) AS total_premium,
    SUM(c.approved_amount) AS total_approved_claims
FROM policies p
LEFT JOIN claims c ON p.policy_id = c.policy_id
GROUP BY DATE_FORMAT(p.start_date, '%Y-%m'), p.insurance_type
ORDER BY month, p.insurance_type;

-- =====================
-- 2. Claim Ratio by Insurance Type (Approved-based)
-- =====================
SELECT
    p.insurance_type,
    SUM(c.approved_amount) / SUM(p.premium_amount) AS claim_ratio
FROM policies p
LEFT JOIN claims c ON p.policy_id = c.policy_id
GROUP BY p.insurance_type
ORDER BY claim_ratio DESC;

-- =====================
-- 3. High-Risk Customers (Approved Claims > 80% of Premium, Last 12 Months)
-- =====================
SELECT
    cu.customer_id,
    cu.full_name,
    cu.region,
    SUM(p.premium_amount) AS total_premium,
    SUM(c.approved_amount) AS total_approved,
    SUM(c.approved_amount) / SUM(p.premium_amount) AS loss_ratio
FROM customers cu
JOIN policies p ON cu.customer_id = p.customer_id
LEFT JOIN claims c ON p.policy_id = c.policy_id
WHERE p.start_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY cu.customer_id, cu.full_name, cu.region
HAVING SUM(c.approved_amount) / SUM(p.premium_amount) > 0.8
ORDER BY loss_ratio DESC;

-- =====================
-- 4. Regional Risk Segmentation (Claim Frequency & Severity)
-- =====================
SELECT
    cu.region,
    COUNT(c.claim_id) / COUNT(DISTINCT p.policy_id) AS claim_frequency,
    AVG(c.approved_amount) AS avg_claim_severity
FROM customers cu
JOIN policies p ON cu.customer_id = p.customer_id
LEFT JOIN claims c ON p.policy_id = c.policy_id
GROUP BY cu.region
ORDER BY claim_frequency DESC;

-- =====================
-- 5. Early Claims (Within 30 Days of Policy Start)
-- =====================
SELECT
    c.claim_id,
    p.policy_id,
    cu.full_name,
    p.insurance_type,
    DATEDIFF(c.claim_date, p.start_date) AS days_after_start,
    c.claim_amount,
    c.approved_amount
FROM claims c
JOIN policies p ON c.policy_id = p.policy_id
JOIN customers cu ON p.customer_id = cu.customer_id
WHERE DATEDIFF(c.claim_date, p.start_date) <= 30
ORDER BY days_after_start;

-- =====================
-- 6. Renewal Rate per Month (Renewed / Expired)
-- =====================
SELECT
    DATE_FORMAT(p.end_date, '%Y-%m') AS month,
    SUM(CASE WHEN p.status = 'Renewed' THEN 1 ELSE 0 END) AS renewed_count,
    SUM(CASE WHEN p.status = 'Expired' THEN 1 ELSE 0 END) AS expired_count,
    SUM(CASE WHEN p.status = 'Renewed' THEN 1 ELSE 0 END) /
    NULLIF(SUM(CASE WHEN p.status = 'Expired' THEN 1 ELSE 0 END), 0) AS renewal_rate
FROM policies p
GROUP BY DATE_FORMAT(p.end_date, '%Y-%m')
ORDER BY month;

-- =====================
-- 7. Broker Ranking by Approved Claim Ratio (Min 20 Policies)
-- =====================
SELECT
    p.broker_name,
    COUNT(DISTINCT p.policy_id) AS policy_count,
    SUM(c.approved_amount) / SUM(p.premium_amount) AS avg_claim_ratio
FROM policies p
LEFT JOIN claims c ON p.policy_id = c.policy_id
WHERE p.channel = 'broker'
GROUP BY p.broker_name
HAVING COUNT(DISTINCT p.policy_id) > 20
ORDER BY avg_claim_ratio ASC;

-- =====================
-- 8. Profitability by Gender and Insurance Type
-- =====================
SELECT
    cu.gender,
    p.insurance_type,
    AVG(p.premium_amount) AS avg_premium,
    SUM(c.approved_amount) / SUM(p.premium_amount) AS claim_ratio
FROM customers cu
JOIN policies p ON cu.customer_id = p.customer_id
LEFT JOIN claims c ON p.policy_id = c.policy_id
GROUP BY cu.gender, p.insurance_type
ORDER BY cu.gender, claim_ratio DESC;

-- =====================
-- 9. Top 10 Customers by Total Approved Claim Amount
-- =====================
SELECT
    cu.customer_id,
    cu.full_name,
    cu.region,
    COUNT(DISTINCT p.policy_id) AS policy_count,
    AVG(p.premium_amount) AS avg_premium,
    SUM(c.approved_amount) AS total_approved_claims
FROM customers cu
JOIN policies p ON cu.customer_id = p.customer_id
JOIN claims c ON p.policy_id = c.policy_id
GROUP BY cu.customer_id, cu.full_name, cu.region
ORDER BY total_approved_claims DESC
LIMIT 10;

-- =====================
-- 10. Policies with No or Late Payments
-- =====================
SELECT
    p.policy_id,
    cu.full_name,
    p.start_date,
    MAX(pay.payment_date) AS last_payment_date,
    CASE
        WHEN MAX(pay.payment_date) IS NULL THEN 'No Payment'
        WHEN DATEDIFF(MAX(pay.payment_date), p.start_date) > 30 THEN 'Late Payment'
        ELSE 'On Time'
    END AS payment_status
FROM policies p
JOIN customers cu ON p.customer_id = cu.customer_id
LEFT JOIN payments pay ON p.policy_id = pay.policy_id
GROUP BY p.policy_id, cu.full_name, p.start_date
ORDER BY payment_status DESC;
