-- Data Cleaning SQL (MySQL)

SELECT *
FROM layoffs;

-- Copy table to secure the original data

DROP TABLE IF EXISTS layoffs_staging;
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_staging;

---------------------------------------------------------------------------------------------------------------------------------------------------
-- 1. Remove Duplicates
-- Check duplicates
WITH duplicate_cte AS (
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) count_row
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE count_row > 1;

-- Remove the duplicates
-- Create another tables which have the actual count_row as the cte above, to remove the duplicates
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `count_row` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT layoffs_staging2
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) count_row
FROM layoffs_staging;

-- Check the duplicates again
SELECT *
FROM layoffs_staging2
WHERE count_row > 1;

-- Delete duplicates
DELETE
FROM layoffs_staging2
WHERE count_row > 1;

SELECT *
FROM layoffs_staging2;

---------------------------------------------------------------------------------------------------------------------------------------------------
-- 2. Standardize the Data
-- Remove space in text
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- In some columns, there are values, which might be wrong typo, need updated
-- industry column
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE '%crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE '%crypto%';

-- country column
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
WHERE country LIKE '%states%';

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE '%states%';

-- date column
SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` date;

SELECT *
FROM layoffs_staging2;

---------------------------------------------------------------------------------------------------------------------------------------------------
-- 3. Null Values or blank values
-- Blank values in industry column, I'll fill it with the value which has the same company name and location
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL OR industry = '';

SELECT *
FROM layoffs_staging2 st1
LEFT JOIN layoffs_staging2 st2
ON st1.company = st2.company AND st1.location = st2.location
WHERE (st1.industry IS NULL OR st1.industry = '') AND st2.industry <> '';

UPDATE layoffs_staging2 st1
LEFT JOIN layoffs_staging2 st2
ON st1.company = st2.company AND st1.location = st2.location
SET st1.industry = st2.industry
WHERE (st1.industry IS NULL OR st1.industry = '') AND st2.industry <> '';

-- The Bally's Interactive company just has 1 record with NULL value in the industry column, so we may leave it NULL
SELECT *
FROM layoffs_staging2
WHERE company LIKE '%Interactive%';

-- Check out the layoff values
-- There are a lot of NULL value in both total_laid_off and percentage_laid_off columns at the same row, I may get rid of those rows, because I believe that they don't have any meaning in my analysis with no data to use

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

---------------------------------------------------------------------------------------------------------------------------------------------------
-- 4. Remove Any Columns
-- Drop the count_row column
ALTER TABLE layoffs_staging2
DROP COLUMN count_row;

-- The data now is good to use in later analysis
