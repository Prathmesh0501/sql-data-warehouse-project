/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.
*/
-- ====================================================================
-- Checking 'silver.crm_cust_info'
-- ====================================================================
-- Checking for NULL values or Duplicates in Primary key

SELECT 
cst_id,
COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for unwnated spaces

SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

-- checking for data consistency

SELECT DISTINCT cst_martial_status
FROM silver.crm_cust_info

-- ====================================================================
-- Checking 'silver.crm_prd_info'
-- ====================================================================
--Check for Null values or Duplicates in primary key

SELECT
prd_info,
COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_info
HAVING COUNT(*) > 1 OR prd_info IS NULL

--check for unwanted spaces

SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

--check for NULL or Negative Numbers

SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- Data consistency

SELECT DISTINCT(prd_line)
FROM silver.crm_prd_info

--Checking for Invalid Date Orders
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt <= prd_start_dt

-- ====================================================================
-- Checking 'silver.crm_sales_details'
-- ====================================================================

-- checking for invlaid date orders
SELECT * 
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_ship_dt

-- checking data consistency between sales, quantity and price

SELECT
sls_sales,
sls_quantity,
sls_price 
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price 
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <=0  OR sls_quantity <=0 OR sls_price <=0
ORDER BY sls_sales,sls_quantity,sls_price

-- ====================================================================
-- Checking 'silver.erp_cust_az12'
-- ====================================================================

-- Identify out of range dates

SELECT DISTINCT
bdate
FROm silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()

-- check on Data consistency

SELECT DISTINCT gen
FROM silver.erp_cust_az12

-- ====================================================================
-- Checking 'silver.erp_loc_a101'
-- ====================================================================
--check for data consistency
	
SELECT DISTINCT cntry
FROM silver.erp_loc_a101

-- ====================================================================
-- Checking 'silver.erp_px_cat_g1v21'
-- ====================================================================

-- check for unwanted sapaces

SELECT * 
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

--Data Consistency

SELECT DISTINCT
maintenance 
FROM silver.erp_px_cat_g1v2











