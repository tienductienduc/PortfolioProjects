-- Exploratory Data Analysis (SQL Server)
SELECT *
FROM layoffs_staging;

--------------------------------------------------------------------------------------------------------------------------------------
-- Checkout the companies with highest total_laid_off and percentage_laid_off value in ONE DAY
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging;

SELECT *
FROM layoffs_staging
WHERE total_laid_off = 12000;

SELECT *
FROM layoffs_staging
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

--------------------------------------------------------------------------------------------------------------------------------------
-- Checkout the laid_off of COMPANIES of alltime
SELECT company, SUM(total_laid_off) total_laid_off_alltime
FROM layoffs_staging
GROUP BY company
ORDER BY 2 DESC;

SELECT *
FROM layoffs_staging
WHERE company = 'ByteDance'
ORDER BY date;

--------------------------------------------------------------------------------------------------------------------------------------
-- Checkout the laid_off of company's STAGE of alltime
SELECT stage, SUM(total_laid_off) total_laid_off_alltime
FROM layoffs_staging
GROUP BY stage
ORDER BY 2 DESC;

SELECT stage, AVG(percentage_laid_off) percentage_laid_off_alltime
FROM layoffs_staging
GROUP BY stage
ORDER BY 2 DESC;

--------------------------------------------------------------------------------------------------------------------------------------
-- Checkout the laid_off of INDUSTRIES of alltime
SELECT industry, SUM(total_laid_off) total_laid_off_alltime
FROM layoffs_staging
GROUP BY industry
ORDER BY 2 DESC;

SELECT industry, AVG(percentage_laid_off) percentage_laid_off_alltime
FROM layoffs_staging
GROUP BY industry
ORDER BY 2 DESC;

--------------------------------------------------------------------------------------------------------------------------------------
-- Checkout the laid_off of COUNTRIES of alltime
SELECT country, SUM(total_laid_off) total_laid_off_alltime
FROM layoffs_staging
GROUP BY country
ORDER BY 2 DESC;

--------------------------------------------------------------------------------------------------------------------------------------
-- The timeline of the data
SELECT MIN(date) min_date, MAX(date) max_date
FROM layoffs_staging;

--------------------------------------------------------------------------------------------------------------------------------------
-- Checkout the laid_off by DATE
SELECT date, SUM(total_laid_off) total_laid_off_alltime
FROM layoffs_staging
WHERE date IS NOT NULL
GROUP BY date
ORDER BY 1;

--------------------------------------------------------------------------------------------------------------------------------------
-- Checkout the laid_off by MONTH
SELECT SUBSTRING(CAST(date AS varchar),1,7) by_month, SUM(total_laid_off) total_laid_off_alltime
FROM layoffs_staging
WHERE date IS NOT NULL
GROUP BY SUBSTRING(CAST(date AS varchar),1,7)
ORDER BY 1;

--------------------------------------------------------------------------------------------------------------------------------------
-- Checkout the laid_off by YEAR
SELECT YEAR(date) by_year, SUM(total_laid_off) total_laid_off_alltime
FROM layoffs_staging
WHERE date IS NOT NULL
GROUP BY YEAR(date)
ORDER BY 2 DESC;

--------------------------------------------------------------------------------------------------------------------------------------
-- See the laid_off by month and by year
WITH month_laid_off AS (
SELECT SUBSTRING(CAST(date AS varchar),1,7) by_month, SUM(total_laid_off) month_laid_off
FROM layoffs_staging
WHERE date IS NOT NULL
GROUP BY SUBSTRING(CAST(date AS varchar),1,7)
)
SELECT *, SUM(month_laid_off) OVER (PARTITION BY substring(by_month,1,4) ORDER BY by_month) rolling_total_laid_off
FROM month_laid_off;

--------------------------------------------------------------------------------------------------------------------------------------
-- Top 5 companies have the highest laid_off employees by year
WITH company_laid_year (company, years, sum_laid_off) AS (
SELECT company, YEAR(date), SUM(total_laid_off)
FROM layoffs_staging
WHERE date IS NOT NULL
GROUP BY company, YEAR(date)),
ranking AS (
SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY sum_laid_off DESC) rank_laid
FROM company_laid_year)

SELECT *
FROM ranking
WHERE rank_laid <= 5;

--------------------------------------------------------------------------------------------------------------------------------------
-- The laid_off of the top 5 highest funds raised companies
WITH top_funds_raised (company, total_laid_off, percentage_laid_off, funds_raised_millions) AS (
SELECT company, SUM(total_laid_off), AVG(percentage_laid_off), MAX(funds_raised_millions)
FROM layoffs_staging
GROUP BY company),
ranking_funds AS (
SELECT *, DENSE_RANK() OVER (ORDER BY funds_raised_millions DESC) funds_rank
FROM top_funds_raised)
SELECT *
FROM ranking_funds
WHERE funds_rank <= 10;


--------------------------------------------------------------------------------------------------------------------------------------
-- The laid_off of the top 5 highest funds raised INDUSTRIES
	-- The funds are repeats at every rows of the same company
	-- and there are some companies changed their industries while recorded in this dataset,
	-- in order to calculate the total of each industry, I need to separate company-industry-funds information into another table, and make sure it doesn't have duplicates company values


DROP TABLE IF EXISTS #company_industry_raised;
CREATE TABLE #company_industry_raised (company varchar(50), industry varchar(50), funds_raised_millions float);

WITH cte1 AS (
SELECT company, industry, MAX(date) date
FROM layoffs_staging
GROUP BY company, industry),
cte2 AS (
SELECT company, MAX(date) date, MAX(funds_raised_millions) funds_raised_millions
FROM layoffs_staging
GROUP BY company)
INSERT INTO #company_industry_raised
SELECT cte1.company, cte1.industry, cte2.funds_raised_millions
FROM cte1
JOIN cte2
ON cte1.company = cte2.company
WHERE cte1.date = cte2.date OR cte1.date IS NULL
ORDER BY 2,1;

SELECT *
FROM #company_industry_raised;

DROP TABLE IF EXISTS #company_laid_off_raised;
CREATE TABLE #company_laid_off_raised (company varchar(50), total_laid_off int, percentage_laid_off float, funds_raised_millions float);
INSERT INTO #company_laid_off_raised
SELECT company, SUM(total_laid_off) total_laid_off, AVG(percentage_laid_off) percentage_laid_off, MAX(funds_raised_millions) funds_raised_millions
FROM layoffs_staging
GROUP BY company;

SELECT *
FROM #company_laid_off_raised;

SELECT *, DENSE_RANK() OVER (ORDER BY funds_raised_millions DESC) funds_rank
FROM (
SELECT ct2.industry, SUM(ct1.total_laid_off) total_laid_off, AVG(ct1.percentage_laid_off) percentage_laid_off, SUM(ct2.funds_raised_millions) funds_raised_millions
FROM #company_laid_off_raised ct1
JOIN #company_industry_raised ct2
ON ct1.company = ct2.company
GROUP BY ct2.industry) funds;
