-- Create layoffsstaging table if not exists
CREATE TABLE IF NOT EXISTS `layoffsstaging` (
  `company` TEXT,
  `location` TEXT,
  `industry` TEXT,
  `total_laid_off` INT DEFAULT NULL,
  `percentage_laid_off` TEXT,
  `date` TEXT,
  `stage` TEXT,
  `country` TEXT,
  `funds_raised_millions` INT DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insert data from layoffs table into staging table
INSERT INTO layoffsstaging 
SELECT * FROM layoffs;

-- Identify duplicate records based on company, industry, total_laid_off, and date
WITH duplicate_cte AS (
  SELECT *, 
         ROW_NUMBER() OVER (PARTITION BY company, industry, total_laid_off, `date`) AS rownum 
  FROM layoffsstaging
)
SELECT * FROM duplicate_cte WHERE rownum > 1;

-- Ensure layoffsstaging2 exists to store cleaned data
CREATE TABLE IF NOT EXISTS layoffsstaging2 LIKE layoffsstaging;

-- Insert deduplicated data by keeping only the first occurrence of duplicate records
INSERT INTO layoffsstaging2
SELECT * FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY company, industry, total_laid_off, `date`) AS rownum 
  FROM layoffsstaging
) AS temp
WHERE rownum = 1;

-- Trim any leading or trailing spaces in company names
UPDATE layoffsstaging2 
SET company = TRIM(company);

-- Standardize industry names where 'crypto' appears with variations (e.g., "crypto exchange")
UPDATE layoffsstaging2 
SET industry = 'crypto' 
WHERE LOWER(industry) LIKE 'crypto%';

-- Delete records where both total_laid_off and percentage_laid_off are NULL
DELETE FROM layoffsstaging2 
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- Replace empty industry values with NULL for consistency
UPDATE layoffsstaging2 
SET industry = NULL 
WHERE industry = '';

-- Fill missing industry values using the industry of the same company if available
UPDATE layoffsstaging2 AS t1
JOIN layoffsstaging2 AS t2 
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

-- Convert date format from text (MM/DD/YYYY) to proper DATE format
UPDATE layoffsstaging2 
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Modify column type to DATE to enforce correct data format
ALTER TABLE layoffsstaging2 
MODIFY COLUMN `date` DATE;
