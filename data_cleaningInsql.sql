-- Cleaning Data in SQL Queries

SELECT *
FROM nashville_info;

-- Standardize Date Format

SELECT SaleDate, STR_TO_DATE(SaleDate, '%M %e, %Y') AS ConvertedDate
FROM nashville_info;

UPDATE nashville_info 
SET SaleDate = STR_TO_DATE(SaleDate, '%M %e, %Y');


-- Populate Property Address Data 

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b. PropertyAddress, COALESCE(NULLIF(a.PropertyAddress, ''), b.PropertyAddress)
FROM nashville_info a 
JOIN nashville_info b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress = '';


UPDATE nashville_info a
JOIN nashville_info b 
ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = COALESCE(NULLIF(a.PropertyAddress, ''), b.PropertyAddress)
WHERE a.PropertyAddress = '';

-- Breaking out address into individual Columns

SELECT PropertyAddress
FROM nashville_info;

SELECT
SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1) AS City
FROM nashville_info;

ALTER TABLE nashville_info
ADD PropertyAddressCorrect Nvarchar(255);

UPDATE nashville_info
SET PropertyAddressCorrect = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1); 

ALTER TABLE nashville_info
ADD City Nvarchar(255);

UPDATE nashville_info
SET City = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1);


-- Owner  Address

SELECT 
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 1), ',', -1) AS Address,
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS City,
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 3), ',', -1) AS State
FROM nashville_info;

ALTER TABLE nashville_info
ADD OwnerAddressCorrect Nvarchar(255);

UPDATE nashville_info
SET OwnerAddressCorrect = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 1), ',', -1); 

ALTER TABLE nashville_info
ADD OwnerCity Nvarchar(255);

UPDATE nashville_info
SET OwnerCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

ALTER TABLE nashville_info
ADD OwnerState Nvarchar(255);

UPDATE nashville_info
SET OwnerState = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 3), ',', -1);


-- Change Y and N to Yes and No in "Sold as Vacant" field 

SELECT SoldAsVacant,
CASE	
	WHEN SoldAsVacant = 'Y' THEN 'Yes' 
    WHEN SoldAsVacant = 'N' THEN 'No' 
    ELSE SoldAsVacant
    END
FROM nashville_info;

UPDATE nashville_info
SET SoldAsVacant = 
CASE	
	WHEN SoldAsVacant = 'Y' THEN 'Yes' 
    WHEN SoldAsVacant = 'N' THEN 'No' 
    ELSE SoldAsVacant
    END;

SELECT distinct(SoldAsVacant), count(SoldAsVacant)
FROM nashville_info
GROUP BY SoldAsVacant;

-- Remove Duplicates

WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID,
                         PropertyAddress,
                         SalePrice,
                         SaleDate,
                         LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM nashville_info
)

SELECT *,
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;


-- WARNING! DO NOT DELETE DATA FROM THE DBA, THIS IS EDUCATIONAL PURPOSE ONLY

DELETE n
FROM nashville_info n
JOIN (
    SELECT UniqueID,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID,
                            PropertyAddress,
                            SalePrice,
                            SaleDate,
                            LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM nashville_info
) AS RowNumCTE ON n.UniqueID = RowNumCTE.UniqueID
WHERE RowNumCTE.row_num > 1;


-- Delete Unused columns

SELECT *
FROM nashville_info;

ALTER TABLE nashville_info
DROP COLUMN PropertyAddress,
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN SaleDate