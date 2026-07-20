-- Netflix Project 
CREATE DATABASE Netflix;

USE netflix;

-- Table Creation 
DROP TABLE IF EXISTS netflix_info;
CREATE TABLE netflix_info
(
	show_id	VARCHAR(20),
	type VARCHAR(10),
	title VARCHAR(150),
	director VARCHAR(250),	
	cast VARCHAR(1000),
	country	VARCHAR(150),
	date_added VARCHAR(50),
	release_year INT,
	rating VARCHAR(10),
	duration VARCHAR(20),
	listed_in VARCHAR(50),	
	description VARCHAR(300)
);

-- Display all records from the dataset.

SELECT 
    *
FROM
    netflix_info;

-- Count the total number of records.

SELECT 
    COUNT(show_id)
FROM
    netflix_info;

-- Count the number of Movies and Shows respectively

SELECT 
    type, COUNT(show_id) as total_count
FROM
    netflix_info
GROUP BY type;

-- Find year it takes to be added after release

SELECT 
    title,
    release_year,
    YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) AS year_added,
    (YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) - release_year) AS acquisition_lag_years
FROM
    netflix_info
WHERE
    date_added IS NOT NULL;

-- Find the most common common rating for movies and shows

SELECT
	 n.type, 
	 n.rating 
FROM(
SELECT
	type, 
	rating, 
	RANK() OVER (PARTITION BY type ORDER BY COUNT(*) DESC) AS ranking 
FROM netflix_info 
GROUP BY type, rating 
) AS n
WHERE
 ranking = 1; 
 
-- Find year with maximum release of movies and shows

SELECT 
	e.type,
	e.release_year,
    e.count_per_year
FROM
(SELECT 
    type, 
    release_year,
    count(*) as count_per_year,
    RANK() OVER (PARTITION BY type ORDER BY COUNT(*) DESC) AS ranking
FROM
    netflix_info
GROUP BY type,release_year
) AS e
WHERE 
	ranking = 1;

-- Find the top 5 countries with most content on netflix 

SELECT 
	c.type,
	c.country,
    c.count_per_country
FROM(
SELECT 
	type, 
	country,
    count(*) as count_per_country,
	ROW_NUMBER() OVER(PARTITION BY TYPE ORDER BY COUNT(*) DESC ) AS ranking
FROM 
	netflix_info
WHERE country IS NOT NULL AND country != ''
GROUP BY type, country
) as c
WHERE ranking <= 5
ORDER BY type, ranking ;

-- Identify the longest movie 

SELECT 
    *
FROM
    netflix_info
WHERE
    type = 'Movie'
        AND duration = (SELECT 
            MAX(duration)
        FROM
            netflix_info);

-- Which Genres dominated Netflix the most

WITH RECURSIVE genre_split AS (
    SELECT
        show_id,
        TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,
        CASE
            WHEN listed_in LIKE '%,%'
            THEN SUBSTRING(listed_in,
                           LENGTH(SUBSTRING_INDEX(listed_in, ',', 1)) + 2)
            ELSE NULL
        END AS remaining
    FROM netflix_info

    UNION ALL

    SELECT
        show_id,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)) AS genre,
        CASE
            WHEN remaining LIKE '%,%'
            THEN SUBSTRING(remaining,
                           LENGTH(SUBSTRING_INDEX(remaining, ',', 1)) + 2)
            ELSE NULL
        END
    FROM genre_split
    WHERE remaining IS NOT NULL
)

SELECT
    genre,
    COUNT(*) AS total_titles
FROM genre_split
GROUP BY genre
ORDER BY total_titles DESC;

-- Which directors consistently contribute to Netflix

WITH RECURSIVE director_split AS (
    SELECT
        show_id,
        TRIM(SUBSTRING_INDEX(director, ',', 1)) AS director,
        CASE
            WHEN director LIKE '%,%'
            THEN SUBSTRING(
                    director,
                    LENGTH(SUBSTRING_INDEX(director, ',', 1)) + 2
                 )
            ELSE NULL
        END AS remaining
    FROM netflix_info
    WHERE director IS NOT NULL 
	AND TRIM(director) <> ''

    UNION ALL
    
    SELECT
        show_id,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)),
        CASE
            WHEN remaining LIKE '%,%'
            THEN SUBSTRING(
                    remaining,
                    LENGTH(SUBSTRING_INDEX(remaining, ',', 1)) + 2
                 )
            ELSE NULL
        END
    FROM director_split
    WHERE remaining IS NOT NULL
)

SELECT
    director,
    COUNT(*) AS total_titles
FROM director_split
WHERE director IS NOT NULL 
GROUP BY director
ORDER BY total_titles DESC
LIMIT 10;

-- Find content added in the last 5 years 

SELECT 
    YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) AS year_added,
    COUNT(*) AS total_titles
FROM
    netflix_info
WHERE
    STR_TO_DATE(date_added, '%M %d, %Y') >= DATE_SUB(CURDATE(), INTERVAL 5 YEAR)
GROUP BY year_added
ORDER BY year_added;

-- List all Tv shows with more than 3 seasons 

SELECT 
    *
FROM
    netflix_info
WHERE
    type = 'TV Show'
        AND SUBSTRING_INDEX(duration, ',', 1) > 3;
        
-- Count the content released in each genre in each year

WITH RECURSIVE genre_split AS (

    SELECT
        show_id,
        release_year,
        TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,
        CASE
            WHEN listed_in LIKE '%,%'
            THEN SUBSTRING(
                    listed_in,
                    LENGTH(SUBSTRING_INDEX(listed_in, ',', 1)) + 2
                 )
            ELSE NULL
        END AS remaining
    FROM netflix_info

    UNION ALL

    SELECT
        show_id,
        release_year,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)) AS genre,
        CASE
            WHEN remaining LIKE '%,%'
            THEN SUBSTRING(
                    remaining,
                    LENGTH(SUBSTRING_INDEX(remaining, ',', 1)) + 2
                 )
            ELSE NULL
        END
    FROM genre_split
    WHERE remaining IS NOT NULL
)

SELECT
    genre,
    release_year,
    COUNT(*) AS total_titles
FROM genre_split
GROUP BY genre, release_year
ORDER BY genre, release_year;

-- Find each year and the average numbers of content release in india on netflix,
-- return top 5 year with highest avg content release

SELECT 
    YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) AS year_added,
    COUNT(*) AS yearly_content,
    ROUND(COUNT(*) * 100.0 / (SELECT 
                    COUNT(*)
                FROM
                    netflix_info
                WHERE
                    country LIKE '%India%'),
            2) AS avg_content_per_year
FROM
    netflix_info
WHERE
    country LIKE '%India%'
GROUP BY year_added
ORDER BY avg_content_per_year DESC
LIMIT 5;

-- Find the growth of content each year

SELECT 
    type,
    YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) AS year_of_feature,
    COUNT(*) AS total_content_per_year
FROM
    netflix_info
GROUP BY type , year_of_feature
ORDER BY year_of_feature ASC

-- Popular actors in the content
 
 WITH RECURSIVE actor_split AS (
    SELECT
        show_id,
        TRIM(SUBSTRING_INDEX(cast, ',', 1)) AS actor_name,
        TRIM(SUBSTRING(
            cast,
            LENGTH(SUBSTRING_INDEX(cast, ',', 1)) + 2
        )) AS remaining
    FROM netflix_info
    WHERE cast IS NOT NULL
      AND cast <> ''

    UNION ALL

    SELECT
        show_id,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)),
        TRIM(SUBSTRING(
            remaining,
            LENGTH(SUBSTRING_INDEX(remaining, ',', 1)) + 2
        ))
    FROM actor_split
    WHERE remaining <> ''
)

SELECT
    actor_name AS Actor,
    COUNT(*) AS Total_Titles
FROM actor_split
GROUP BY actor_name
ORDER BY Total_Titles DESC
LIMIT 10;

-- Count content released after 2020

SELECT 
    COUNT(*) AS total_titles
FROM
    netflix_info
WHERE
    release_year > 2020;



