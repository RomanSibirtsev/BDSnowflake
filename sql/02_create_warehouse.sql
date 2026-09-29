CREATE SCHEMA dw;

CREATE TABLE dw.dim_country (
    country_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_name text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_pet (
    pet_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pet_type text NOT NULL,
    pet_name text NOT NULL,
    breed text NOT NULL,
    CONSTRAINT dim_pet_natural_key UNIQUE (pet_type, pet_name, breed)
);

CREATE TABLE dw.dim_customer (
    customer_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name text NOT NULL,
    last_name text NOT NULL,
    age smallint NOT NULL,
    email text NOT NULL UNIQUE,
    postal_code text,
    country_id bigint NOT NULL REFERENCES dw.dim_country(country_id),
    pet_id bigint NOT NULL REFERENCES dw.dim_pet(pet_id)
);

CREATE TABLE dw.dim_seller (
    seller_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name text NOT NULL,
    last_name text NOT NULL,
    email text NOT NULL UNIQUE,
    postal_code text,
    country_id bigint NOT NULL REFERENCES dw.dim_country(country_id)
);

CREATE TABLE dw.dim_location (
    location_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    city_name text NOT NULL,
    state_name text,
    country_id bigint NOT NULL REFERENCES dw.dim_country(country_id),
    CONSTRAINT dim_location_natural_key
        UNIQUE NULLS NOT DISTINCT (city_name, state_name, country_id)
);

CREATE TABLE dw.dim_store (
    store_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    store_name text NOT NULL,
    phone text NOT NULL,
    email text NOT NULL UNIQUE,
    location_id bigint NOT NULL REFERENCES dw.dim_location(location_id)
);

CREATE TABLE dw.dim_supplier (
    supplier_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_name text NOT NULL,
    contact_name text NOT NULL,
    email text NOT NULL UNIQUE,
    phone text NOT NULL,
    street_address text NOT NULL,
    location_id bigint NOT NULL REFERENCES dw.dim_location(location_id)
);

CREATE TABLE dw.dim_product_category (
    product_category_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_pet_category (
    pet_category_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_brand (
    brand_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    brand_name text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_date (
    date_id integer PRIMARY KEY,
    calendar_date date NOT NULL UNIQUE,
    calendar_year smallint NOT NULL,
    calendar_quarter smallint NOT NULL,
    calendar_month smallint NOT NULL,
    day_of_month smallint NOT NULL,
    iso_week smallint NOT NULL,
    iso_day_of_week smallint NOT NULL,
    is_weekend boolean NOT NULL
);

CREATE TABLE dw.dim_product (
    product_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_row_id bigint NOT NULL UNIQUE REFERENCES raw.sale_source(source_row_id),
    product_name text NOT NULL,
    product_category_id bigint NOT NULL REFERENCES dw.dim_product_category(product_category_id),
    pet_category_id bigint NOT NULL REFERENCES dw.dim_pet_category(pet_category_id),
    brand_id bigint NOT NULL REFERENCES dw.dim_brand(brand_id),
    supplier_id bigint NOT NULL REFERENCES dw.dim_supplier(supplier_id),
    unit_price numeric(10, 2) NOT NULL,
    stock_quantity integer NOT NULL,
    weight numeric(8, 2) NOT NULL,
    color text NOT NULL,
    size text NOT NULL,
    material text NOT NULL,
    description text NOT NULL,
    rating numeric(2, 1) NOT NULL,
    review_count integer NOT NULL,
    release_date date NOT NULL,
    expiry_date date NOT NULL
);

CREATE TABLE dw.fact_sales (
    source_row_id bigint PRIMARY KEY REFERENCES raw.sale_source(source_row_id),
    sale_id integer NOT NULL,
    date_id integer NOT NULL REFERENCES dw.dim_date(date_id),
    customer_id bigint NOT NULL REFERENCES dw.dim_customer(customer_id),
    seller_id bigint NOT NULL REFERENCES dw.dim_seller(seller_id),
    product_id bigint NOT NULL REFERENCES dw.dim_product(product_id),
    store_id bigint NOT NULL REFERENCES dw.dim_store(store_id),
    quantity integer NOT NULL CHECK (quantity > 0),
    total_amount numeric(12, 2) NOT NULL CHECK (total_amount >= 0)
);

CREATE INDEX fact_sales_date_idx ON dw.fact_sales(date_id);
CREATE INDEX fact_sales_customer_idx ON dw.fact_sales(customer_id);
CREATE INDEX fact_sales_seller_idx ON dw.fact_sales(seller_id);
CREATE INDEX fact_sales_product_idx ON dw.fact_sales(product_id);
CREATE INDEX fact_sales_store_idx ON dw.fact_sales(store_id);
