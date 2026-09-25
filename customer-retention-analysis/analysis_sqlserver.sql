-- ==========================
-- 1. DATABASE + TABLE SETUP
-- ==========================

CREATE DATABASE CustomerRetention;
GO
USE CustomerRetention;
GO

-- customerID: CHAR(10), fixed-length ID format confirmed from source data
-- MonthlyCharges/TotalCharges: DECIMAL(8,2), not FLOAT, to avoid rounding errors on currency
CREATE TABLE customer_retention_analysis (
    customerID CHAR(10) PRIMARY KEY,
    gender VARCHAR(6),
    SeniorCitizen INT,
    Partner VARCHAR(6),
    Dependents VARCHAR(6),
    tenure INT,
    PhoneService VARCHAR(20),
    MultipleLines VARCHAR(20),
    InternetService VARCHAR(20),
    OnlineSecurity VARCHAR(20),
    OnlineBackup VARCHAR(20),
    DeviceProtection VARCHAR(20),
    TechSupport VARCHAR(20),
    StreamingTV VARCHAR(20),
    StreamingMovies VARCHAR(20),
    Contract VARCHAR(20),
    PaperlessBilling VARCHAR(6),
    PaymentMethod VARCHAR(50),
    MonthlyCharges DECIMAL(8,2),
    TotalCharges DECIMAL(8,2),
    Churn VARCHAR(6));

-- ===============
-- 2. DATA IMPORT
-- ===============

BULK INSERT customer_retention_analysis
FROM 'D:\Projects\customer-retention-analysis\data\telco_churn_raw.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n');

-- Note: 11 rows imported with NULL TotalCharges (new customers with tenure ~0, whose lifetime billing total hadn't been calculated yet in the source data).
-- Every query below applies WHERE TotalCharges IS NOT NULL to exclude these, matching how the Python version handled the same missing data.
SELECT * FROM customer_retention_analysis;

-- ====================
-- 3. ANALYSIS QUERIES
-- ====================

-- 3.1 Churn Rate Percent by Contract
SELECT
    Contract,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS Churn_Yes,
    SUM(CASE WHEN Churn = 'No' THEN 1 ELSE 0 END) AS Churn_No,
    CAST(CAST(ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(Churn), 2) AS DECIMAL(5,2)) AS VARCHAR(10)) + '%' AS Churn_Rate_Percent
FROM customer_retention_analysis
WHERE TotalCharges IS NOT NULL
GROUP BY Contract;

-- 3.2 Churn Rate Percent by Tenure
SELECT
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS Churn_Yes,
    SUM(CASE WHEN Churn = 'No' THEN 1 ELSE 0 END) AS Churn_No,
    CAST(CAST(ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(Churn), 2) AS DECIMAL(6,2)) AS VARCHAR(10)) + '%' AS Churn_Rate_Percent,
    CASE 
        WHEN tenure BETWEEN 0 AND 6 THEN '0-6 months'
        WHEN tenure BETWEEN 7 AND 12 THEN '7-12 months'
        WHEN tenure BETWEEN 13 AND 24 THEN '13-24 months'
        WHEN tenure BETWEEN 25 AND 48 THEN '25-48 months'
        WHEN tenure BETWEEN 49 AND 72 THEN '49-72 months'
    END AS Tenure_Bucket
FROM customer_retention_analysis
WHERE TotalCharges IS NOT NULL
GROUP BY 
    CASE 
        WHEN tenure BETWEEN 0 AND 6 THEN '0-6 months'
        WHEN tenure BETWEEN 7 AND 12 THEN '7-12 months'
        WHEN tenure BETWEEN 13 AND 24 THEN '13-24 months'
        WHEN tenure BETWEEN 25 AND 48 THEN '25-48 months'
        WHEN tenure BETWEEN 49 AND 72 THEN '49-72 months'
    END
ORDER BY MIN(tenure);

-- 3.3 High-Risk Segment: Month-to-month Contract + Electronic Check + Tenure <= 12mo
SELECT
    CAST(CAST(ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(Churn), 2) AS DECIMAL(6,2)) AS VARCHAR(10)) + '%' AS Churn_Yes_Percent,
    CAST(CAST(ROUND(SUM(CASE WHEN Churn = 'No' THEN 1 ELSE 0 END) * 100.0 / COUNT(Churn), 2) AS DECIMAL(6,2)) AS VARCHAR(10)) + '%' AS Churn_No_Percent,
    COUNT(*) AS Total_Customers,
    SUM(MonthlyCharges) AS Total_Monthly_Charges
FROM customer_retention_analysis
WHERE Contract = 'Month-to-month' AND PaymentMethod = 'Electronic check' AND tenure <= 12 AND TotalCharges IS NOT NULL;

-- 3.4 Rank Churned Customers by MonthlyCharges Within Each Contract Type
SELECT
    customerID, Contract, MonthlyCharges, Churn,
    RANK() OVER (PARTITION BY Contract ORDER BY MonthlyCharges DESC) AS RankName
FROM customer_retention_analysis
WHERE Churn = 'Yes';