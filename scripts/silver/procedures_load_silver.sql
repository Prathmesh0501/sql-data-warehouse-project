/*
==================================================================================
Stored Procedures : Load Silver Layer
==================================================================================
Script Purpose :
    This scripts has stored procedeure which performs ETL(Extract, Transform, Load)
    to polpulate data in SILVER schema from bronze schema.
Actions Performed :
    Truncates the silver table before laoding the data.
    Inserts transformed and cleaned data into silver tables.
===================================================================================
Usage:
  EXCE bronze.load_broze
===================================================================================
*/
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '==================================================================='
		PRINT 'Loading the silver layer'
		PRINT '==================================================================='

		PRINT '-------------------------------------------------------------------'
		PRINT 'Loading CRM tables'
		PRINT '-------------------------------------------------------------------'

		SET @start_time = GETDATE();
		PRINT '>>Truncating table : silver.crm_cust_info' 
		TRUNCATE TABLE silver.crm_cust_info
		PRINT '>>Inserting Data into : silver.crm_cust_info' 
		INSERT INTO silver.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_gndr,
			cst_martial_status,
			cst_create_date)
		SELECT 
		cst_id,
		cst_key,
		TRIM(cst_firstname) AS cst_firstname,
		TRIM(cst_lastname) AS cst_lastname,
		CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
			WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
			ELSE 'n/a'
		END cst_gndr,
		CASE WHEN UPPER(TRIM(cst_martial_status)) = 'S' THEN 'Single'
			WHEN UPPER(TRIM(cst_martial_status)) = 'M' THEN 'Married'
			ELSE 'n/a'
		END cst_martial_status,
		cst_create_date
		FROM (
		SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag 
		FROM bronze.crm_cust_info
		WHERE cst_id IS NOT NULL
		)t WHERE flag = 1;
		SET @end_time = GETDATE();
		PRINT 'Loading Duration : '+ CAST(DATEDIFF(second ,@start_time, @end_time) AS NVARCHAR) + ' seconds';

		PRINT '-------------------------------------------------------------------'

		SET @start_time = GETDATE();
		PRINT '>>Truncating table : silver.crm_prd_info' 
		TRUNCATE TABLE silver.crm_prd_info
		PRINT '>>Inserting Data Into : silver.crm_prd_info' 
		INSERT INTO silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)

		SELECT 
			prd_info As prd_id,
			REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
			SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
			prd_nm,
			ISNULL(prd_cost,0) AS prd_cost,
			CASE UPPER(TRIM(prd_line)) 
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other sales'
				WHEN 'T' THEN 'Touring'
				ELSE 'n/a'
			END AS prd_line,
			prd_start_dt,                                     
			DATEADD(DAY, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
		FROM bronze.crm_prd_info
		SET @end_time = GETDATE();
		PRINT 'Loading Duration :' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds';

		PRINT '-------------------------------------------------------------------'

		SET @start_time = GETDATE();
		PRINT '>>Truncating table : silver.crm_sales_details' 
		TRUNCATE TABLE silver.crm_sales_details
		PRINT '>>Inserting Data into : silver.crm_sales_details' 
		INSERT INTO silver.crm_sales_details(
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
			THEN sls_quantity * ABS(sls_price)
			ELSE sls_sales
		END AS sls_sales,
		sls_quantity,
		CASE WHEN sls_price IS NULL OR sls_price <=0
			THEN sls_sales / NULLIF(sls_quantity,0)
			ELSE sls_price
		END AS sls_price
		FROM bronze.crm_sales_details
		SET @end_time = GETDATE();
		PRINT 'Loading Duration :' +CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds';

		PRINT '-------------------------------------------------------------------'

		SET @start_time = GETDATE()
		PRINT '>>Truncating table : silver.erp_cust_az12' 
		TRUNCATE TABLE silver.erp_cust_az12
		PRINT '>>Inserting Data into : silver.erp_cust_az12' 
		INSERT INTO silver.erp_cust_az12(
			cid,
			bdate,
			gen
		)
		SELECT 
		CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
			ELSE cid
		END AS cid,
		CASE WHEN bdate> GETDATE() THEN NULL
			ELSE bdate
		END AS bdate,
		CASE WHEN UPPER(TRIM(gen)) IN ('F' ,'FEMALE') THEN 'Female'
			WHEN UPPER(TRIM(gen)) IN ('M' ,'MALE') THEN 'Male' 
			ELSE 'n/a'
		END AS gen
		FROM bronze.erp_cust_az12
		SET @end_time = GETDATE();
		PRINT 'Loading Duration :' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' seconds'; 

		PRINT '-------------------------------------------------------------------'

		SET @start_time = GETDATE();
		PRINT '>>Truncating table : silver.erp_loc_a101' 
		TRUNCATE TABLE silver.erp_loc_a101
		PRINT '>>Inserting Data into : silver.erp_loc_a101' 
		INSERT INTO silver.erp_loc_a101(
			cid,
			cntry
		)
		SELECT 
		REPLACE(cid,'-','')cid,
		CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
			WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
			WHEN TRIM(cntry) = ' ' OR cntry IS NULL THEN 'n/a'
			ELSE TRIM(cntry)
		END AS cntry
		FROM bronze.erp_loc_a101
		SET @end_time = GETDATE();
		PRINT 'Loading Duration :' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+' seconds';

		PRINT '-------------------------------------------------------------------'

		SET @start_time = GETDATE();
		PRINT '>>Truncating table : silver.erp_px_cat_g1v2' 
		TRUNCATE TABLE silver.erp_px_cat_g1v2
		PRINT '>>Inserting Data into : silver.erp_px_cat_g1v2' 
		INSERT INTO silver.erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT
		id,
		cat,
		subcat,
		maintenance
		FROM bronze.erp_px_cat_g1v2
		SET @end_time = GETDATE();
		PRINT 'Loading Duration :'+CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+' seconds';

		PRINT '-------------------------------------------------------------------'

		SET @batch_end_time = GETDATE();
		PRINT 'LOADING SILVER LAYER IS COMPLETE'
		PRINT '-TOTAL LOAD DURATION ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
	END TRY
	BEGIN CATCH
			PRINT '======================================================='
			PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER'
			PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
			PRINT 'ERROR MESSAGE' + CAST(ERROR_NUMBER() AS NVARCHAR);
			PRINT 'ERROR STATE' + CAST(ERROR_STATE() AS NVARCHAR)
			PRINT '======================================================='
	END CATCH
END
