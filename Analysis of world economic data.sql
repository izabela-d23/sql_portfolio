--Queried using postgresql
--Working on multiple tables
--Data source: DataCamp

-- Create 'populations' table
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
--Create 'economies' table 
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
--Create 'cities' table 
CREATE TABLE cities (
    name VARCHAR(100),
    country_code CHAR(3),
    city_proper_pop INTEGER,
    metroarea_pop INTEGER,
    urbanarea_pop INTEGER
);
--Create 'economies_2015' and 'economies_2019' tables
CREATE TABLE economies_2015 (
code VARCHAR(3),
year INTEGER,
income_group VARCHAR(50),
gross_savings FLOAT
);
CREATE TABLE economies_2019 (
code VARCHAR(3),
year INTEGER,
income_group VARCHAR(50),
gross_savings FLOAT
);

--Create 'currencies' table 
CREATE TABLE currencies (
    curr_id INTEGER PRIMARY KEY,
    code CHAR(3),
    basic_unit VARCHAR(50),
    curr_code CHAR(3),
    frac_unit VARCHAR(50),
    frac_perbasic INTEGER
);

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

-- The relationship between fertility and unemployment rates
SELECT c.country_name, e.year, p.fertility_rate, e.unemployment_rate
FROM countries AS c
INNER JOIN populations AS p
ON c.code = p.country_code
INNER JOIN economies AS e --Join the economies
ON c.code = e.code
AND p.year = e.year; -- additional joining condition

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

--Countries from the North America (or null) region and their currencies 
SELECT Country_name AS name, code, region, basic_unit
FROM countries
FULL JOIN currencies 
USING (code)
WHERE region = 'North America' 
OR region IS NULL
ORDER BY region;

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

/*five countries and their respective regions with the highest/lowest life expectancy
for the year 2010*/
SELECT 
    c.country_name AS country,
    region,
    life_expectancy AS life_exp
FROM countries AS c
INNER JOIN populations AS p
ON c.code = p.country_code
WHERE year = '2010'
AND life_expectancy IS NOT NULL
ORDER BY life_expectancy DESC --ASC  --change to ASC to get the lowest life_exp
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

-- Return all cities with the same name as a country
SELECT country_name
FROM countries
INTERSECT
SELECT name
FROM cities;

--Return all cities that do not have the same names as their countries
SELECT name
FROM cities
EXCEPT
SELECT country_name
FROM countries
ORDER BY name;

--Combine all fields from economies_2015 and economies_2019
SELECT *
FROM economies_2015
UNION --Set operation
SELECT *
FROM economies_2019
ORDER BY code, year;

/*all records from economies_2019 where gross_savings in the economies_2015 table were below
global average*/
WITH avg_gross_savings AS(
SELECT AVG(gross_savings) AS avg_savings
FROM economies_2015
)
SELECT *
FROM economies_2019
WHERE code IN
(SELECT code
FROM economies_2015, avg_gross_savings
WHERE gross_savings < avg_gross_savings.avg_savings
);

--Identifying languages spoken in the Eastern Africa
SELECT DISTINCT name
FROM languages
WHERE code IN
(SELECT code
FROM countries
WHERE region = 'Eastern Africa')
ORDER BY name;

--Records from 2015 with life_expectancy is 1.10 times higher than average
SELECT *
FROM populations
WHERE year = 2015
AND life_expectancy > 1.10 *
(SELECT AVG(life_expectancy)
FROM populations
WHERE year = 2015);

--Select capital cities in order of largest to smallest population
SELECT name, country_code, urbanarea_pop
FROM cities
WHERE name IN
(SELECT capital
FROM countries)
ORDER BY urbanarea_pop DESC;

-- Find top five countries with the most cities
/*SELECT countries.country_name AS country, COUNT(*) AS cities_num
FROM countries
LEFT JOIN cities
ON countries.code = cities.country_code
GROUP BY countries.country_name
ORDER BY cities_num DESC, country ASC
LIMIT 5;*/

-- Find top five countries with the most cities - shorter query
SELECT
(SELECT COUNT(*)
FROM cities
WHERE cities.country_code = countries.code) AS cities_num
FROM countries
ORDER BY cities_num DESC, country_name ASC
LIMIT 5;

--Number of languages spoken for each country
SELECT local_name, lang_num
FROM countries,
(SELECT code, COUNT(*) AS lang_num
FROM languages
GROUP BY code) AS sub
WHERE countries.code = sub.code
ORDER BY lang_num DESC;

--Inflation and unemployment rate for Monarchy countries in 2015
SELECT code, inflation_rate, unemployment_rate
FROM economies
WHERE year = 2015
AND code IN
(SELECT code
FROM countries
WHERE gov_form LIKE '%Monarchy%')
ORDER BY inflation_rate;

/*Top 10 capital cities in Europe and the Americas by city_perc,
[percentage of the total population in the wider metro area]*/
SELECT	name,
	country_code,
	city_proper_pop,
	metroarea_pop,
	(city_proper_pop / metroarea_pop * 100) AS city_perc
FROM cities
WHERE name IN  -- Use subquery to filter city name
(SELECT capital
FROM countries
WHERE continent = 'Europe'
OR continent LIKE '%America')
AND metroarea_pop IS NOT NULL
ORDER BY city_perc DESC
LIMIT 10;
