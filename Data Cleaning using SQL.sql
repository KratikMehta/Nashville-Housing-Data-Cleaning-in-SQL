SELECT *
FROM NashvilleHousing


/* Standardize Date Format */
ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate)

SELECT SaleDate, SaleDateConverted
FROM NashvilleHousing


/* Populate Property Address data */
SELECT
    nh1.ParcelID,
    nh1.PropertyAddress,
    nh2.ParcelID,
    nh2.PropertyAddress,
    ISNULL(nh1.PropertyAddress, nh2.PropertyAddress)
FROM NashvilleHousing nh1
    JOIN NashvilleHousing nh2
    ON nh1.ParcelID = nh2.ParcelID AND nh1.[UniqueID ] <> nh2.[UniqueID ]
WHERE nh1.PropertyAddress IS NULL

UPDATE nh1
SET PropertyAddress = ISNULL(nh1.PropertyAddress, nh2.PropertyAddress)
FROM NashvilleHousing nh1
    JOIN NashvilleHousing nh2
    ON nh1.ParcelID = nh2.ParcelID AND nh1.[UniqueID ] <> nh2.[UniqueID ]
WHERE nh1.PropertyAddress IS NULL


/* Splitting Address into Individual columns (Address, City, State) */
-- PropertyAddress
SELECT
    TRIM(SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)) AS Address,
    TRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))) AS City
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255),
    PropertySplitCity NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertySplitAddress = TRIM(SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)),
    PropertySplitCity = TRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)))


-- OwnerAddress
SELECT
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255),
    OwnerSplitCity NVARCHAR(255),
    OwnerSplitState NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


/* Change Y and N to Yes and No in "Sold and Vacant" field */
SELECT
    SoldAsVacant,
    CASE 
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE 
                        WHEN SoldAsVacant = 'Y' THEN 'Yes'
                        WHEN SoldAsVacant = 'N' THEN 'No'
                        ELSE SoldAsVacant
                   END


/* Remove Duplicates */
WITH
    RowNumCTE
    AS
    (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY ParcelID,
                                            PropertyAddress,
                                            SalePrice,
                                            SaleDate,
                                            LegalReference
                                    ORDER BY UniqueID) AS row_num
        FROM NashvilleHousing
    )
DELETE
FROM RowNumCTE
WHERE row_num > 1


/* Delete Unused Columns */
ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate