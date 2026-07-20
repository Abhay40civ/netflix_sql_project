#             Netflix Movies and TV Shows Analysis using MySQL
<img width="2000" height="540" alt="image" src="https://github.com/user-attachments/assets/1509e0e2-b4c3-4285-a061-42803fa9591c" />

# Netflix Data Analysis Using MySQL

## Project Overview
This project analyzes the Netflix Movies and TV Shows dataset from Kaggle using MySQL. The objective is to answer business-related questions and extract meaningful insights using SQL. The project demonstrates practical SQL skills such as data filtering, aggregation, grouping, Common Table Expressions (CTEs), and window functions.

## Dataset Information
- **Dataset:** Netflix Movies & TV Shows
- **Source:** Kaggle
- **Total Records:** 101
- **Database:** MySQL

## Tools & Technologies
- MySQL Workbench
- SQL
- Git & GitHub

## Database Creation
```sql
CREATE DATABASE Netflix;
```
## Table Creation
```sql
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
```

## Exploratory Data Analysis (EDA)

Before solving the business problems, basic exploratory queries were performed to understand the dataset:

- Display all records from the dataset.
```sql
SELECT 
    *
FROM
    netflix_info;
```
- Count the total number of records.
```sql
SELECT 
    COUNT(show_id)
FROM
    netflix_info;
```

## Business Questions

1. Count the number of Movies and Shows respectively
```sql
SELECT 
    type, COUNT(show_id) as total_count
FROM
    netflix_info
GROUP BY type;
```
2.Find year it takes to be added after release
```sql
SELECT 
    title,
    release_year,
    YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) AS year_added,
    (YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) - release_year) AS acquisition_lag_years
FROM
    netflix_info
WHERE
    date_added IS NOT NULL;
```
3. Find the most common common rating for movies and shows
```sql
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
```
4. Find year with maximum release of movies and shows
```sql
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
```
5. Find the top 5 countries with most content on netflix
```sql
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
```
6. Identify the longest movie
```sql
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
```
7. Which Genres dominated Netflix the most
```sql
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
```
8. Which directors consistently contribute to Netflix
```sql
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
```
9. Find content added in the last 5 years
```sql
SELECT 
    YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) AS year_added,
    COUNT(*) AS total_titles
FROM
    netflix_info
WHERE
    STR_TO_DATE(date_added, '%M %d, %Y') >= DATE_SUB(CURDATE(), INTERVAL 5 YEAR)
GROUP BY year_added
ORDER BY year_added;
```
10. List all Tv shows with more than 3 seasons
```sql
SELECT 
    *
FROM
    netflix_info
WHERE
    type = 'TV Show'
        AND SUBSTRING_INDEX(duration, ',', 1) > 3;
```
11. Count the content released in each genre in each year
```sql
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
```
12. Find each year and the average numbers of content release in india on netflix, return top 5 year with highest avg content release
```sql
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
```
13. Find the growth of content each year
```sql
SELECT 
    type,
    YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) AS year_of_feature,
    COUNT(*) AS total_content_per_year
FROM
    netflix_info
GROUP BY type , year_of_feature
ORDER BY year_of_feature ASC
```
14. Popular actors in the content
```sql
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
```
15.Count content released after 2020 
```sql
SELECT 
    COUNT(*) AS total_titles
FROM
    netflix_info
WHERE
    release_year > 2020;
```


> **Note:** The SQL queries for database creation, table creation, exploratory analysis, and all business questions are available in `sql/netflix_analysis.sql`.

## SQL Concepts Used
- SELECT
- WHERE
- GROUP BY
- ORDER BY
- HAVING
- Aggregate Functions
- CASE Statements
- String Functions
- Date Functions
- Common Table Expressions (CTEs)
- Window Functions

## Project Structure

```text
Netflix-SQL-Project/
│
├── dataset/
│   └── netflix.csv
│
├── sql/
│   └── netflix_analysis.sql
│
└── README.md
```

## How to Run
1. Download the dataset from Kaggle.
2. Create the database and table in MySQL.
3. Import the dataset into the `netflix` table.
4. Execute the queries in `sql/netflix_analysis.sql`.
5. Review the outputs to gain insights from the data.

## Learning Outcomes
- Practiced SQL using a real-world dataset.
- Applied SQL to solve business-oriented problems.
- Improved skills in data cleaning, exploration, and analysis.
- Gained experience with CTEs, window functions, and aggregate functions.
- Learned how to organize a professional SQL project for GitHub.

## Author

**Abhay Kumar**  
Final Year B.Tech, Civil Engineering  
VNIT Nagpur

## License
This project is created for educational and portfolio purposes.
