--Queried using postgresql
--Working on multiple tables
--Data source: DataCamp

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

-- Create 'populations' table and import csv data
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

--Create 'economies' table and import csv data
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

--Create 'cities' table and import csv data
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

/*All countries in the cities table, whether or not they have a match 
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

--Average gross domestic product (GDP) per capita by region in 2015
SELECT region, AVG(gdp_percapita) AS avg_gdp
FROM countries AS c
LEFT JOIN economies AS e
USING(code)
WHERE year = 2015
GROUP BY region
ORDER BY avg_gdp DESC
LIMIT 10; 

--Create 'currencies' table and import csv data
CREATE TABLE currencies (
    curr_id INTEGER PRIMARY KEY,
    code CHAR(3),
    basic_unit VARCHAR(50),
    curr_code CHAR(3),
    frac_unit VARCHAR(50),
    frac_perbasic INTEGER
);

--Countries from the North America (or null) region and their currencies 
SELECT Country_name AS name, code, region, basic_unit
FROM countries
-- Join to currencies
FULL JOIN currencies 
USING (code)
WHERE region = 'North America' 
OR region IS NULL
ORDER BY region;

SELECT DISTINCT region
FROM countries;

-- Information about languages and currencies in Europe
SELECT 
    c1.country_name AS country, 
    region,
    l.name AS language,
    basic_unit, 
    frac_unit
FROM countries as c1 
FULL JOIN languages AS l 
USING(code)
FULL JOIN currencies AS c2
USING(code) 
WHERE region LIKE '%Europe';

--What are the languages presently spoken in India, Bangladesh and Pakistan?
SELECT c.country_name AS country, code,l.name AS language
FROM countries AS c
INNER JOIN languages AS l
USING (code)
WHERE c.code IN ('BGD','PAK','IND')
AND l.code in ('PAK','BAN', 'IND');

/*what languages could potentially have been spoken in either country 
over the course of their history?*/
SELECT c.country_name AS country, l.name AS language
FROM countries AS c        
CROSS JOIN languages AS l
WHERE c.code in ('BGD','PAK','IND')
	AND l.code in ('BGD','PAK','IND');

/*five countries and their respective regions with the highest/lowest life expectancy for the year 2010*/
SELECT 
    c.country_name AS country,
    region,
    life_expectancy AS life_exp
FROM countries AS c
INNER JOIN populations AS p
ON c.code = p.country_code
WHERE year = '2010'
	AND life_expectancy IS NOT NULL
ORDER BY life_expectancy DESC --change to ASC to get the lowest life_exp
LIMIT 5;

--How much the populations for each country changed from 2010 to 2015?
SELECT 
    p1.country_code, 
    p1.size AS size2010, 
    p2.size AS size2015
FROM populations AS p1
INNER JOIN populations AS p2
ON p1.country_code = p2.country_code
WHERE p1.year = 2010
    AND p1.year <> p2.year;

--combinations of country code and year from the economies and populations tables 
--(using UNION)
SELECT code, year
FROM economies
UNION
SELECT country_code, year
FROM populations
ORDER BY code, year;
