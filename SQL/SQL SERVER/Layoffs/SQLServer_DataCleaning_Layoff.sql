-- Data Cleaning SQL (SQL Server)

SELECT *
FROM layoffs;

-- Copy table to secure the original data

DROP TABLE IF EXISTS layoffs_staging;
SELECT *
INTO layoffs_staging
FROM layoffs;

SELECT *
FROM layoffs_staging;


--------------------------------------------------------------------------------------------------------------------------------------
-- 1. Remove Duplicates
-- Check duplicates
WITH duplicate_cte AS (
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions ORDER BY (SELECT NULL)) count_row
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE count_row > 1;

-- Remove the duplicates
WITH duplicate_cte AS (
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions ORDER BY (SELECT NULL)) count_row
FROM layoffs_staging
)
DELETE
FROM duplicate_cte
WHERE count_row > 1;


SELECT *
FROM layoffs_staging;


--------------------------------------------------------------------------------------------------------------------------------------
-- 2. Standardize the Data
-- Remove space in text
SELECT company, TRIM(company)
FROM layoffs_staging
ORDER BY 1;

UPDATE layoffs_staging
SET company = TRIM(company);

-- In some columns, there are values, which might be wrong typo, need updated
-- industry column
SELECT DISTINCT industry
FROM layoffs_staging
ORDER BY 1;

SELECT *
FROM layoffs_staging
WHERE industry LIKE '%crypto%';

UPDATE layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE '%crypto%';

-- country column
SELECT DISTINCT country
FROM layoffs_staging
ORDER BY 1;

SELECT DISTINCT country
FROM layoffs_staging
WHERE country LIKE '%states%';

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging
WHERE country LIKE '%states%';

UPDATE layoffs_staging
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE '%states%';

-- date column
SELECT date, TRY_CONVERT(DATE, [date], 101)
FROM layoffs_staging;

UPDATE layoffs_staging
SET date = TRY_CONVERT(DATE, [date], 101);

ALTER TABLE layoffs_staging
ALTER COLUMN date date;

SELECT *
FROM layoffs_staging;


--------------------------------------------------------------------------------------------------------------------------------------
-- 3. Null Values or blank values
-- Blank values in industry column, I'll fill it with the value which has the same company name and location
SELECT *
FROM layoffs_staging
WHERE industry IS NULL OR industry = '';

SELECT *
FROM layoffs_staging st1
LEFT JOIN layoffs_staging st2
ON st1.company = st2.company AND st1.location = st2.location
WHERE (st1.industry IS NULL OR st1.industry = '') AND st2.industry <> '';

UPDATE st1
SET st1.industry = st2.industry
FROM layoffs_staging st1
LEFT JOIN layoffs_staging st2
ON st1.company = st2.company AND st1.location = st2.location
WHERE (st1.industry IS NULL OR st1.industry = '') AND st2.industry <> '';

-- The Bally's Interactive company just has 1 record with NULL value in the industry column, so we may leave it NULL
SELECT *
FROM layoffs_staging
WHERE company LIKE '%Interactive%';

-- Check out the layoff values
-- There are a lot of NULL value in both total_laid_off and percentage_laid_off columns at the same row, I may get rid of those rows, because I believe that they don't have any meaning in my analysis with no data to use
SELECT *
FROM layoffs_staging
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging;

--------------------------------------------------------------------------------------------------------------------------------------
-- 4. Remove Any Columns
-- All columns are clean and there are no problems with them


-- The data now is good to use in later analysis
