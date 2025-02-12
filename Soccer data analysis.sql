------------PART 1: Matches analysis----------------------------------------
--Identify matches played between FC Schalke 04 and FC Bayern Munich 
SELECT 
	t.team_long_name AS home_team,
	COUNT(m.id) AS total_matches
FROM matches AS m
JOIN team AS t
	ON m.hometeam_id = t.team_api_id
WHERE m.country_id = 7809 -- Germany country id (from 'countries' table)
AND t.team_long_name IN ('FC Schalke 04', 'FC Bayern Munich')
GROUP BY t.team_long_name;

--List of matches played between Real Madrid and FC Barcelona
SELECT 
    date,
    CASE 
        WHEN hometeam_id = 8634 THEN 'FC Barcelona' 
        ELSE 'Real Madrid CF' 
    	END AS home,
    CASE 
        WHEN awayteam_id = 8634 THEN 'FC Barcelona' 
        ELSE 'Real Madrid CF' 
    END AS away,
    CASE 
        WHEN home_goal > away_goal AND hometeam_id = 8634 THEN 'Barcelona win!'
        WHEN home_goal > away_goal THEN 'Real Madrid win!'
        WHEN home_goal < away_goal AND awayteam_id = 8634 THEN 'Barcelona win!'
        WHEN home_goal < away_goal THEN 'Real Madrid win!'
        ELSE 'Tie!' 
    END AS outcome
FROM matches
WHERE hometeam_id IN (8634, 8633) AND awayteam_id IN (8634, 8633);

--The highest total number of goals in each season, overall, and during July across all seasons
SELECT
	season,
    MAX(home_goal + away_goal) AS max_goals,
   (SELECT MAX(home_goal + away_goal) FROM matches) AS overall_max_goals,
	MAX(home_goal + away_goal) FILTER (WHERE EXTRACT(MONTH FROM date) = 7) AS july_max_goals
FROM matches
GROUP BY season;

-----------PART 2: Analysis of the selected season-------------------------
--List of matches in the 2011/2012 season where Barcelona was the home team
SELECT 
	m.date,
	t.team_long_name AS opponent,
	CASE WHEN m.home_goal > m.away_goal THEN 'Barcelona win!'
        WHEN m.home_goal < m.away_goal THEN 'Barcelona loss :(' 
        ELSE 'Tie' END AS outcome 
FROM matches AS m
LEFT JOIN team AS t 
	ON m.awayteam_id = t.team_api_id
WHERE m.hometeam_id = 8634
	AND m.season = '2011/2012'
ORDER BY m.date;

-- Select matches where Barcelona was the away team
SELECT  
	m.date,
	t.team_long_name AS opponent,
	CASE WHEN m.home_goal < m.away_goal THEN 'Barcelona win!'
        WHEN m.home_goal > m.away_goal THEN 'Barcelona loss :(' 
        ELSE 'Tie' END AS outcome
FROM matches AS m
LEFT JOIN team AS t 
ON m.hometeam_id = t.team_api_id
WHERE m.awayteam_id = 8634
	AND m.season = '2011/2012'
ORDER BY m.date;;

-------------------------PART 3: Team Analysis-------------------------------------------
--List of matches won by Italy's Bologna team
SELECT season, date, home_goal, away_goal
FROM matches
WHERE CASE WHEN hometeam_id = 9857 AND home_goal > away_goal THEN 'Bologna Win'
		WHEN awayteam_id = 9857 AND away_goal > home_goal THEN 'Bologna Win' 
		END IS NOT NULL;	

/*Games played by Legia Warszawa and comparing their individual game performance to the overall
 average for season*/
SELECT
	date,
	season,
	home_goal,
	away_goal,
	CASE WHEN hometeam_id = 8673 THEN 'home' 
		 ELSE 'away' END AS warsaw_location, 
	-- The average number of home and away goals for the season
    AVG(home_goal) OVER(PARTITION BY season) AS season_homeavg,
    AVG(away_goal) OVER(PARTITION BY season) AS season_awayavg
FROM matches
WHERE 
	hometeam_id = 8673 
    OR awayteam_id = 8673
ORDER BY (home_goal + away_goal) DESC;

/*Average number home and away goals scored Legia Warszawa partitioned by the month in 
each season*/
SELECT 
	date,
	season,
	home_goal,
	away_goal,
	CASE WHEN hometeam_id = 8673 THEN 'home' 
         ELSE 'away' END AS warsaw_location,
	-- Calculate average goals partitioned by season and month
    AVG(home_goal) OVER(PARTITION BY season, 
         	EXTRACT(month FROM date)) AS season_mo_home,
    AVG(away_goal) OVER(PARTITION BY season, 
            EXTRACT(month FROM date)) AS season_mo_away
FROM matches
WHERE 
	hometeam_id = 8673
    OR awayteam_id = 8673
ORDER BY (home_goal + away_goal) DESC;


----------------PART 4: LEAGUE STATISTICS---------------------------------------------------
--Number of matches played in each country each season

SELECT 
    c.name AS country,
    m.season,
    COUNT(m.id) AS total_matches
FROM countries AS c
LEFT JOIN matches AS m
    ON c.id = m.country_id
GROUP BY c.name, m.season
ORDER BY c.name, m.season;

--Total number of matches won by the home team in each country each season
SELECT 
    c.name AS country,
    m.season,
    COUNT(*) AS total_matches,
    SUM(CASE WHEN m.home_goal > m.away_goal THEN 1 ELSE 0 END) AS home_wins,
    ROUND(100.0 * SUM(CASE WHEN m.home_goal > m.away_goal THEN 1 ELSE 0 END) / COUNT(*), 2) AS home_win_percentage
FROM countries AS c
LEFT JOIN matches AS m
    ON c.id = m.country_id
GROUP BY c.name, m.season
ORDER BY c.name, m.season;

--Number of wins, losses, and ties in each country
SELECT c.name AS country,
	COUNT(m.id) AS total_matches,
	COUNT(CASE WHEN m.home_goal > m.away_goal THEN m.id END) AS wins,
	COUNT(CASE WHEN m.home_goal < m.away_goal THEN m.id END) AS losses,
	COUNT(CASE WHEN m.home_goal = m.away_goal THEN m.id END) AS ties
FROM countries AS c
LEFT JOIN matches AS m
ON c.id = m.country_id
GROUP BY country
ORDER BY total_matches DESC;

--Percentage of matches ending with a tie during the 2013/2014 and 2014/2015 seasons
SELECT 
    c.name AS country,
    ROUND(AVG(CASE 
        WHEN m.season = '2013/2014' AND m.home_goal = m.away_goal THEN 1
        WHEN m.season = '2013/2014' AND m.home_goal != m.away_goal THEN 0
        ELSE NULL END), 2) AS pct_ties_2013_2014,
    ROUND(AVG(CASE 
        WHEN m.season = '2014/2015' AND m.home_goal = m.away_goal THEN 1
        WHEN m.season = '2014/2015' AND m.home_goal != m.away_goal THEN 0
        ELSE NULL END), 2) AS pct_ties_2014_2015
FROM countries AS c
LEFT JOIN matches AS m ON c.id = m.country_id
GROUP BY c.name
ORDER BY pct_ties_2014_2015 DESC;

--Difference between league goal average and overall goal average in 2013/2014 season
SELECT
	l.name AS league,
	ROUND(AVG(m.home_goal + m.away_goal),2) AS avg_goals,
	ROUND(AVG(m.home_goal + m.away_goal) - 
		(SELECT AVG(home_goal + away_goal)
		 FROM matches 
         WHERE season = '2013/2014'),2) AS diff_from_avg
FROM league AS l
LEFT JOIN matches AS m
ON l.country_id = m.country_id
WHERE season = '2013/2014'
GROUP BY l.name;

-- Does the average number of goals scored change in different stages (comparing with overall avg)?
SELECT 
	m.stage,
    ROUND(AVG(m.home_goal + m.away_goal),2) AS avg_goals,
    ROUND((SELECT AVG(home_goal + away_goal) 
           FROM matches 
           WHERE season = '2012/2013'),2) AS overall
FROM matches AS m
WHERE season = '2012/2013'
GROUP BY m.stage
ORDER BY m.stage;

--Average number of games per season in which the team scored 5 or more goals
SELECT
	c.name AS country,
	AVG(matches) AS avg_seasonal_high_scores
FROM countries AS c
LEFT JOIN (
  SELECT country_id, season,
         COUNT(id) AS matches
  FROM (
    SELECT country_id, season, id
	FROM matches
	WHERE home_goal >= 5 OR away_goal >= 5) AS inner_s
  GROUP BY country_id, season) AS outer_s
ON c.id = outer_s.country_id
GROUP BY country;

--List of countries and the number of matches in each country with more than 10 total goals
SELECT 
    l.name AS league,
    COUNT(m.id) AS match_count
FROM league AS l
LEFT JOIN matches AS m 
    ON l.country_id = m.country_id
WHERE (m.home_goal + m.away_goal) >= 10
GROUP BY l.name
ORDER BY match_count DESC;

-- The average number of goals scored overall in a league
SELECT 
    l.name AS league,
    ROUND(AVG(m.home_goal + m.away_goal), 2) AS avg_goals,
    RANK() OVER(ORDER BY AVG(m.home_goal + m.away_goal) DESC) AS league_rank
FROM league AS l
LEFT JOIN matches AS m 
    ON l.country_id = m.country_id 
WHERE m.season = '2011/2012'
GROUP BY l.name
ORDER BY league_rank;

----------------------PART 5: More Advanced Analysis------------------------------------------------
--Matches with scores that are extreme outliers for each country (above 3 times the average score)
WITH avg_goals AS (
    SELECT country_id, 
           AVG(home_goal + away_goal) * 3 AS threshold
    FROM matches
    GROUP BY country_id
)
SELECT 
	m.country_id,
    m.date,
    m.home_goal, 
    m.away_goal
FROM matches AS m
JOIN avg_goals AS a 
ON m.country_id = a.country_id
WHERE (m.home_goal + m.away_goal) > a.threshold;;

--What was the highest scoring match for each country, in each season?
SELECT 
	main.country_id,
	c.name AS country,
    main.season,
    main.date,
    main.home_goal,
    main.away_goal
FROM matches AS main
JOIN countries AS c
    ON main.country_id = c.id
WHERE -- Filter for matches with the highest number of goals scored
	(home_goal + away_goal) = 
     (SELECT MAX(sub.home_goal + sub.away_goal)
      FROM matches AS sub
      WHERE main.country_id = sub.country_id
      	AND main.season = sub.season);

/*Running total and Moving Average of goals scored by the FC Utrecht when they were 
the home team during the 2011/2012 season. */
SELECT 
	date,
	home_goal,
	away_goal,
    SUM(home_goal) OVER(ORDER BY date 
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
    AVG(home_goal) OVER(ORDER BY date 
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_avg
FROM matches
WHERE 
	hometeam_id = 9908 
	AND season = '2011/2012';
