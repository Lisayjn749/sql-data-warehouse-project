exec silver.load_silver;

create or alter procedure silver.load_silver as
begin
	truncate table silver.crm_cust_info;
	print '>> Inserting Data Into: silver.crm_cust_info';
	insert into silver.crm_cust_info(
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_material_status,
		cst_gndr,
		cst_create_date)
	select 
		cst_id, 
		cst_key, 
		trim(cst_firstname) as cst_firstname, 
		trim(cst_lastname) as cst_lastname, 
		case when upper(trim(cst_material_status)) = 'S' then 'Single' 
			 when upper(trim(cst_material_status)) = 'M' then 'Married'
			 else 'n/a'
		end cst_material_status, 
		case when upper(trim(cst_gndr)) = 'F' then 'Female' 
			 when upper(trim(cst_gndr)) = 'M' then 'Male'
			 else 'n/a'
		end cst_gndr,
		cst_create_date
	from (
		select * , row_number() over (partition by cst_id order by cst_create_date desc) as flag_last
		from bronze.crm_cust_info
		where cst_id is not null
	)t
	where flag_last = 1

	truncate table silver.crm_prd_info;
	insert into silver.crm_prd_info (
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
	)
	select 
	prd_id,
	replace(substring(prd_key, 1, 5), '-', '_') cat_id,
	substring(prd_key, 7, len(prd_key)) prd_key, 
	prd_nm,
	isnull(prd_cost, 0) prd_cost,
	case upper(trim(prd_line)) 
		 when 'M' then 'Mountain' 
		 when 'R' then 'Road'
		 when 'S' then 'Other Sales'
		 when 'T' then 'Touring'
		 else 'n/a'
	end prd_line,
	cast(prd_start_dt as date) prd_start_dt,
	cast(lead(prd_start_dt) over (partition by prd_key order by prd_start_dt)-1 as date) prd_end_dt
	from bronze.crm_prd_info

	truncate table silver.crm_sales_details;
	insert into silver.crm_sales_details(
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
	select
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		case 
			when sls_order_dt = 0 or len(sls_order_dt) != 8 then null
			else cast(cast(sls_order_dt as nvarchar) as date)
		end sls_order_dt,
		case 
			when sls_order_dt = 0 or len(sls_ship_dt) != 8 then null
			else cast(cast(sls_ship_dt as nvarchar) as date)
		end sls_ship_date,
		case 
			when sls_order_dt = 0 or len(sls_due_dt) != 8 then null
			else cast(cast(sls_due_dt as nvarchar) as date)
		end sls_due_dt,
		case when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * ABS(sls_price)
			then sls_quantity * abs(sls_price)
			else sls_sales 
		end sls_sales,
		sls_quantity,
		case when sls_price is null or sls_price <= 0 
			then sls_sales / nullif(sls_quantity, 0)
			else sls_price
		end sls_price
	from bronze.crm_sales_details

	truncate table silver.erp_cust_az12;
	insert into silver.erp_cust_az12(
		cid,
		bdate,
		gen
	)
	select 
	case when cid like 'NAS%' then substring(cid, 4, len(cid))
		else cid
	end cid,
	case when bdate > getdate() then null
		else bdate
	end bdate,
	case when upper(trim(gen)) in ('F', 'FEMALE') then 'Female'
		when upper(trim(gen)) in ('M', 'MALE') then 'Male'
		else 'n/a'
	end gen
	from bronze.erp_cust_az12

	truncate table silver.erp_loc_a101;
	insert into silver.erp_loc_a101(
	cid,
	cntry
	)
	select 
	replace(cid, '-', '') cid,
	case when trim(cntry) = 'DE' then 'Germany'
		when trim(cntry) in ('US', 'USA') then 'United States'
		when trim(cntry) = ''  or cntry is null then 'n/a'
		else trim(cntry)
	end cntry
	from bronze.erp_loc_a101

	truncate table silver.erp_px_cat_g1v2;
	insert into silver.erp_px_cat_g1v2 (
	id,
	cat,
	subcat,
	maintenance)
	select 
	id,
	cat,
	subcat,
	maintenance
	from bronze.erp_px_cat_g1v2
end 
