SELECT
    (SELECT COUNT(*) FROM raw.sale_source) AS source_rows,
    (SELECT COUNT(*) FROM dw.fact_sales) AS fact_rows;

SELECT
    (SELECT COUNT(*)
     FROM raw.sale_source AS source
     LEFT JOIN dw.fact_sales AS fact USING (source_row_id)
     WHERE fact.source_row_id IS NULL) AS source_rows_without_fact,
    (SELECT COUNT(*)
     FROM dw.fact_sales AS fact
     LEFT JOIN raw.sale_source AS source USING (source_row_id)
     WHERE source.source_row_id IS NULL) AS facts_without_source;

SELECT
    COUNT(*) AS sales,
    SUM(quantity) AS items_sold,
    SUM(total_amount) AS revenue
FROM dw.fact_sales;

SELECT 'customers' AS dimension, COUNT(*) AS rows FROM dw.dim_customer
UNION ALL SELECT 'sellers', COUNT(*) FROM dw.dim_seller
UNION ALL SELECT 'products', COUNT(*) FROM dw.dim_product
UNION ALL SELECT 'stores', COUNT(*) FROM dw.dim_store
UNION ALL SELECT 'suppliers', COUNT(*) FROM dw.dim_supplier
UNION ALL SELECT 'countries', COUNT(*) FROM dw.dim_country
UNION ALL SELECT 'locations', COUNT(*) FROM dw.dim_location
ORDER BY dimension;
