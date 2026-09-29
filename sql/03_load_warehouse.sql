BEGIN;

INSERT INTO dw.dim_country (country_name)
SELECT country_name
FROM (
    SELECT BTRIM(customer_country) AS country_name FROM raw.sale_source
    UNION
    SELECT BTRIM(seller_country) FROM raw.sale_source
    UNION
    SELECT BTRIM(store_country) FROM raw.sale_source
    UNION
    SELECT BTRIM(supplier_country) FROM raw.sale_source
) AS countries
WHERE country_name <> ''
ORDER BY country_name;

INSERT INTO dw.dim_pet (pet_type, pet_name, breed)
SELECT DISTINCT
    BTRIM(customer_pet_type),
    BTRIM(customer_pet_name),
    BTRIM(customer_pet_breed)
FROM raw.sale_source
ORDER BY 1, 2, 3;

INSERT INTO dw.dim_product_category (category_name)
SELECT DISTINCT BTRIM(product_category)
FROM raw.sale_source
WHERE NULLIF(BTRIM(product_category), '') IS NOT NULL
ORDER BY 1;

INSERT INTO dw.dim_pet_category (category_name)
SELECT DISTINCT BTRIM(pet_category)
FROM raw.sale_source
WHERE NULLIF(BTRIM(pet_category), '') IS NOT NULL
ORDER BY 1;

INSERT INTO dw.dim_brand (brand_name)
SELECT DISTINCT BTRIM(product_brand)
FROM raw.sale_source
WHERE NULLIF(BTRIM(product_brand), '') IS NOT NULL
ORDER BY 1;

INSERT INTO dw.dim_location (city_name, state_name, country_id)
SELECT DISTINCT location.city_name, location.state_name, location.country_id
FROM (
    SELECT
        NULLIF(BTRIM(source.store_city), '') AS city_name,
        NULLIF(BTRIM(source.store_state), '') AS state_name,
        country.country_id
    FROM raw.sale_source AS source
    JOIN dw.dim_country AS country
      ON country.country_name = BTRIM(source.store_country)
    UNION
    SELECT
        NULLIF(BTRIM(source.supplier_city), ''),
        NULL::text,
        country.country_id
    FROM raw.sale_source AS source
    JOIN dw.dim_country AS country
      ON country.country_name = BTRIM(source.supplier_country)
) AS location
WHERE location.city_name IS NOT NULL
ORDER BY location.country_id, location.city_name, location.state_name NULLS FIRST;

INSERT INTO dw.dim_customer (
    first_name, last_name, age, email, postal_code, country_id, pet_id
)
SELECT DISTINCT
    BTRIM(source.customer_first_name),
    BTRIM(source.customer_last_name),
    BTRIM(source.customer_age)::smallint,
    BTRIM(source.customer_email),
    NULLIF(BTRIM(source.customer_postal_code), ''),
    country.country_id,
    pet.pet_id
FROM raw.sale_source AS source
JOIN dw.dim_country AS country
  ON country.country_name = BTRIM(source.customer_country)
JOIN dw.dim_pet AS pet
  ON pet.pet_type = BTRIM(source.customer_pet_type)
 AND pet.pet_name = BTRIM(source.customer_pet_name)
 AND pet.breed = BTRIM(source.customer_pet_breed)
ORDER BY 4;

INSERT INTO dw.dim_seller (
    first_name, last_name, email, postal_code, country_id
)
SELECT DISTINCT
    BTRIM(source.seller_first_name),
    BTRIM(source.seller_last_name),
    BTRIM(source.seller_email),
    NULLIF(BTRIM(source.seller_postal_code), ''),
    country.country_id
FROM raw.sale_source AS source
JOIN dw.dim_country AS country
  ON country.country_name = BTRIM(source.seller_country)
ORDER BY 3;

INSERT INTO dw.dim_store (store_name, phone, email, location_id)
SELECT DISTINCT
    BTRIM(source.store_name),
    BTRIM(source.store_phone),
    BTRIM(source.store_email),
    location.location_id
FROM raw.sale_source AS source
JOIN dw.dim_country AS country
  ON country.country_name = BTRIM(source.store_country)
JOIN dw.dim_location AS location
  ON location.country_id = country.country_id
 AND location.city_name = BTRIM(source.store_city)
 AND location.state_name IS NOT DISTINCT FROM NULLIF(BTRIM(source.store_state), '')
ORDER BY 3;

INSERT INTO dw.dim_supplier (
    supplier_name, contact_name, email, phone, street_address, location_id
)
SELECT DISTINCT
    BTRIM(source.supplier_name),
    BTRIM(source.supplier_contact),
    BTRIM(source.supplier_email),
    BTRIM(source.supplier_phone),
    BTRIM(source.supplier_address),
    location.location_id
FROM raw.sale_source AS source
JOIN dw.dim_country AS country
  ON country.country_name = BTRIM(source.supplier_country)
JOIN dw.dim_location AS location
  ON location.country_id = country.country_id
 AND location.city_name = BTRIM(source.supplier_city)
 AND location.state_name IS NULL
ORDER BY 3;

INSERT INTO dw.dim_date (
    date_id, calendar_date, calendar_year, calendar_quarter,
    calendar_month, day_of_month, iso_week, iso_day_of_week, is_weekend
)
SELECT
    TO_CHAR(sale_day, 'YYYYMMDD')::integer,
    sale_day,
    EXTRACT(YEAR FROM sale_day)::smallint,
    EXTRACT(QUARTER FROM sale_day)::smallint,
    EXTRACT(MONTH FROM sale_day)::smallint,
    EXTRACT(DAY FROM sale_day)::smallint,
    EXTRACT(WEEK FROM sale_day)::smallint,
    EXTRACT(ISODOW FROM sale_day)::smallint,
    EXTRACT(ISODOW FROM sale_day) IN (6, 7)
FROM (
    SELECT DISTINCT TO_DATE(BTRIM(sale_date), 'MM/DD/YYYY') AS sale_day
    FROM raw.sale_source
) AS dates
ORDER BY sale_day;

-- The sample has no stable product SKU. Keep a one-to-one source-row mapping
-- so facts retain the product attributes attached to each imported sale.
INSERT INTO dw.dim_product (
    source_row_id, product_name, product_category_id, pet_category_id,
    brand_id, supplier_id, unit_price, stock_quantity, weight, color, size,
    material, description, rating, review_count, release_date, expiry_date
)
SELECT
    source.source_row_id,
    BTRIM(source.product_name),
    product_category.product_category_id,
    pet_category.pet_category_id,
    brand.brand_id,
    supplier.supplier_id,
    BTRIM(source.product_price)::numeric(10, 2),
    BTRIM(source.product_quantity)::integer,
    BTRIM(source.product_weight)::numeric(8, 2),
    BTRIM(source.product_color),
    BTRIM(source.product_size),
    BTRIM(source.product_material),
    BTRIM(source.product_description),
    BTRIM(source.product_rating)::numeric(2, 1),
    BTRIM(source.product_reviews)::integer,
    TO_DATE(BTRIM(source.product_release_date), 'MM/DD/YYYY'),
    TO_DATE(BTRIM(source.product_expiry_date), 'MM/DD/YYYY')
FROM raw.sale_source AS source
JOIN dw.dim_product_category AS product_category
  ON product_category.category_name = BTRIM(source.product_category)
JOIN dw.dim_pet_category AS pet_category
  ON pet_category.category_name = BTRIM(source.pet_category)
JOIN dw.dim_brand AS brand
  ON brand.brand_name = BTRIM(source.product_brand)
JOIN dw.dim_supplier AS supplier
  ON supplier.email = BTRIM(source.supplier_email)
ORDER BY source.source_row_id;

INSERT INTO dw.fact_sales (
    source_row_id, sale_id, date_id, customer_id, seller_id,
    product_id, store_id, quantity, total_amount
)
SELECT
    source.source_row_id,
    BTRIM(source.id)::integer,
    TO_CHAR(TO_DATE(BTRIM(source.sale_date), 'MM/DD/YYYY'), 'YYYYMMDD')::integer,
    customer.customer_id,
    seller.seller_id,
    product.product_id,
    store.store_id,
    BTRIM(source.sale_quantity)::integer,
    BTRIM(source.sale_total_price)::numeric(12, 2)
FROM raw.sale_source AS source
JOIN dw.dim_customer AS customer
  ON customer.email = BTRIM(source.customer_email)
JOIN dw.dim_seller AS seller
  ON seller.email = BTRIM(source.seller_email)
JOIN dw.dim_product AS product
  ON product.source_row_id = source.source_row_id
JOIN dw.dim_store AS store
  ON store.email = BTRIM(source.store_email)
ORDER BY source.source_row_id;

COMMIT;
