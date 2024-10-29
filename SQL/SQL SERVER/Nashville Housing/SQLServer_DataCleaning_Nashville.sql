-- Data Cleaning Nashville Housing (SQL Server)

SELECT TOP 100 *
FROM [dbo].[Nashville Housing];


--------------------------------------------------------------------------------------------------------------------
-- 1. Standardize the Data
-- Standardize Date Format

SELECT SaleDate, CONVERT(date, SaleDate)
FROM [dbo].[Nashville Housing];

UPDATE [dbo].[Nashville Housing]
SET SaleDate = CONVERT(date, SaleDate);

ALTER TABLE [dbo].[Nashville Housing]
ALTER COLUMN SaleDate date;



--------------------------------------------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Address, City, State)
-- PropertyAddress
SELECT PropertyAddress
FROM [dbo].[Nashville Housing];

SELECT PropertyAddress, SUBSTRING(PropertyAddress, 1,CHARINDEX(',',PropertyAddress)-1) SplitPropertyAddress
, SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1,LEN(PropertyAddress)) SplitPropertyCity
FROM [dbo].[Nashville Housing];

ALTER TABLE [dbo].[Nashville Housing]
ADD  SplitPropertyAddress nvarchar(255);

UPDATE [dbo].[Nashville Housing]
SET SplitPropertyAddress = SUBSTRING(PropertyAddress, 1,CHARINDEX(',',PropertyAddress)-1);

ALTER TABLE [dbo].[Nashville Housing]
ADD  SplitPropertyCity nvarchar(255);

UPDATE [dbo].[Nashville Housing]
SET SplitPropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1,LEN(PropertyAddress));



-- OwnerAddress
SELECT OwnerAddress
, PARSENAME(REPLACE(OwnerAddress,',','.'),3)
, PARSENAME(REPLACE(OwnerAddress,',','.'),2)
, PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM [dbo].[Nashville Housing];

ALTER TABLE [dbo].[Nashville Housing]
ADD  SplitOwnerAddress nvarchar(255);

UPDATE [dbo].[Nashville Housing]
SET SplitOwnerAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3);

ALTER TABLE [dbo].[Nashville Housing]
ADD  SplitOwnerCity nvarchar(255);

UPDATE [dbo].[Nashville Housing]
SET SplitOwnerCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2);

ALTER TABLE [dbo].[Nashville Housing]
ADD  SplitOwnerState nvarchar(255);

UPDATE [dbo].[Nashville Housing]
SET SplitOwnerState = PARSENAME(REPLACE(OwnerAddress,',','.'),1);


--------------------------------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM [dbo].[Nashville Housing]
GROUP BY SoldAsVacant;

SELECT DISTINCT *
FROM (
SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END change_yes_no
FROM [dbo].[Nashville Housing]) AS check_yes_no;

UPDATE [dbo].[Nashville Housing]
SET SoldAsVacant = CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END


--------------------------------------------------------------------------------------------------------------------
-- 2. Null and blank values
-- Populate Property Address Data

SELECT *
FROM [dbo].[Nashville Housing]
WHERE PropertyAddress IS NULL;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM [dbo].[Nashville Housing] a
JOIN [dbo].[Nashville Housing] b
ON a.ParcelID = b.ParcelID
WHERE b.PropertyAddress IS NOT NULL AND a.PropertyAddress IS NULL;

UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM [dbo].[Nashville Housing] a
JOIN [dbo].[Nashville Housing] b
ON a.ParcelID = b.ParcelID
WHERE b.PropertyAddress IS NOT NULL AND a.PropertyAddress IS NULL;



-- Populate OwnerName Data

SELECT *
FROM [dbo].[Nashville Housing]
WHERE OwnerName IS NULL;

SELECT a.SplitOwnerAddress, a.OwnerName, b.SplitOwnerAddress, b.OwnerName
FROM [dbo].[Nashville Housing] a
JOIN [dbo].[Nashville Housing] b
ON a.SplitOwnerAddress = b.SplitOwnerAddress
WHERE a.OwnerName IS NULL AND b.OwnerName IS NOT NULL;

UPDATE a
SET a.OwnerName = b.OwnerName
FROM [dbo].[Nashville Housing] a
JOIN [dbo].[Nashville Housing] b
ON a.SplitOwnerAddress = b.SplitOwnerAddress
WHERE a.OwnerName IS NULL AND b.OwnerName IS NOT NULL


--------------------------------------------------------------------------------------------------------------------
-- 3. Remove Duplicates
-- Remove Duplicates

SELECT TOP 100 *
FROM [dbo].[Nashville Housing];

WITH cte_row_num AS (
SELECT *, ROW_NUMBER() OVER (
					PARTITION BY ParcelID,
								PropertyAddress,
								SaleDate,
								SalePrice,
								LegalReference,
								SoldAsVacant
									ORDER BY UniqueID
							) row_num
FROM [dbo].[Nashville Housing]
)

SELECT *
FROM cte_row_num
WHERE row_num > 1;

WITH cte_row_num AS (
SELECT *, ROW_NUMBER() OVER (
					PARTITION BY ParcelID,
								PropertyAddress,
								SaleDate,
								SalePrice,
								LegalReference,
								SoldAsVacant
									ORDER BY UniqueID
							) row_num
FROM [dbo].[Nashville Housing]
)

DELETE
FROM cte_row_num
WHERE row_num > 1;



--------------------------------------------------------------------------------------------------------------------
-- 4. Remove columns
-- Delete Unused Columns

SELECT TOP 100 *
FROM [dbo].[Nashville Housing];

ALTER TABLE [dbo].[Nashville Housing]
DROP COLUMN PropertyAddress, OwnerAddress;
