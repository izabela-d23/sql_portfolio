--Queried using postgresql
--Working on multiple tables

-- Which languages are official languages, and which ones are unofficial in Canada?
SELECT c.country_name AS country, l.name AS language, official
FROM countries AS c
INNER JOIN languages AS l
USING (code) -- Match using the code column
WHERE country_name = 'Canada'; 

-- Find all the countries that speak a Spanish language
SELECT c.country_name AS country, l.name AS language
FROM countries AS c
INNER JOIN languages AS l
USING(code) -- Match using the code column
WHERE l.name = 'Spanish';

-- Create populations table
CREATE TABLE populations (
    pop_id INTEGER PRIMARY KEY,
    country_code CHAR(3) NOT NULL,
    year INTEGER NOT NULL,
    fertility_rate NUMERIC(5,3),
    life_expectancy NUMERIC(10,4),
    size BIGINT,
    CONSTRAINT year_check CHECK (year >= 1900 AND year <= 2100),
    CONSTRAINT fertility_rate_check CHECK (fertility_rate >= 0),
    CONSTRAINT life_expectancy_check CHECK (life_expectancy >= 0),
    CONSTRAINT size_check CHECK (size >= 0)
);

SELECT *
FROM populations
LIMIT 10;


CREATE TABLE economies (
    econ_id INTEGER PRIMARY KEY,
    code CHAR(3),
    year INTEGER,
    income_group VARCHAR(50),
    gdp_percapita DECIMAL(10,3),
    gross_savings DECIMAL(10,3),
    inflation_rate DECIMAL(10,3),
    total_investment DECIMAL(10,3),
    unemployment_rate DECIMAL(10,3),
    exports DECIMAL(10,3),
    imports DECIMAL(10,3)
);

-- The relationship between fertility and unemployment rates
SELECT c.country_name, e.year, p.fertility_rate, e.unemployment_rate
FROM countries AS c
INNER JOIN populations AS p
ON c.code = p.country_code
INNER JOIN economies AS e --Join the economies
ON c.code = e.code
	AND p.year = e.year; -- additional joining condition

CREATE TABLE cities (
    name VARCHAR(100),
    country_code CHAR(3),
    city_proper_pop INTEGER,
    metroarea_pop INTEGER,
    urbanarea_pop INTEGER
);

--Let's see records where a country is present in both tables (Inner Join)
SELECT 
    c1.name AS city,
    code,
    c2.country_name AS country,
    region,
    city_proper_pop
FROM cities AS c1
INNER JOIN countries AS c2
ON c1.country_code = c2.code
ORDER BY code DESC;

/*Let's see all countries in the cities table, whether or not they have a match 
in the countries table (Left Join).*/
SELECT 
    c1.name AS city, 
    code, 
    c2.country_name AS country,
    region, 
    city_proper_pop
FROM cities AS c1
LEFT JOIN countries AS c2
ON c1.country_code = c2.code
ORDER BY code DESC;
