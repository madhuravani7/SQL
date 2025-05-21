SELECT *
FROM PortfolioProject..NashvilleHousing

--standarizing the sale date:
--USING convert to date we can convert it to just data and remove the timestamp that is extra.
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject..NashvilleHousing

--updating it with the new format, and i realised it didn't work
UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

--I did alter table instead.
--add column name and data type and populate it using the derived value from saledate
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)


--looking at property address
SELECT *
FROM PortfolioProject..NashvilleHousing
--where PropertyAddress is null
order by ParcelID

--There are some NUll values in the property address. Ordering by ParcelID, one ything is clear that there are some parcel IDs that are same and have same address.
--Joining this table with itself to resolve the issue where same parcel Ids share same property address, so we can populate the null values in this case.
--using isnull checks if the column is null and if its null we can populate with our required data, here it is b.address

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, isnull(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
 On a.ParcelID = b.ParcelID
 AND a.UniqueID <> b.UniqueID
where a.PropertyAddress is Null

UPDATE a
SET PropertyAddress = isnull(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
 On a.ParcelID = b.ParcelID
 AND a.UniqueID <> b.UniqueID
where a.PropertyAddress is Null

--Breaking out address into individual columns (Address, City, State)
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing 

--using substring to achieve this
--and yeah am getting , included so i subtracted - 1 from the charindex
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) - 1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',' , PropertyAddress) + 1, LEN(PropertyAddress)) as City

FROM PortfolioProject..NashvilleHousing 

--we can't seperate values in a column without creating a new column for it. Alter the table and then update it.

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) - 1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',' , PropertyAddress) + 1, LEN(PropertyAddress))

SELECT *
FROM PortfolioProject..NashvilleHousing 

--OwnerAddress
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing 

--Here am to split the owner address similar to property address but not with substring. There is PARSENAME and this does work backwards which i felt its kinds 
--weird. Also, it looks for period '.'. when learning javascript to i cane across parse that looks for ',' to convert it to javascript object. 
--First am replacing ',' with '.' and then working with the address

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject..NashvilleHousing 

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


--change Y and N to Yes and No . Doing distinct its clear that there are 4 distinct rows Y, N, Yes and No
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
Group by SoldAsVacant

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = 'No'
where SoldAsVacant = 'N'

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = 'Yes'
where SoldAsVacant = 'Y'

--Actually we could also use CASE statement to achieve this
SELECT SoldAsVacant,
  CASE
  when SoldAsVacant = 'Y' THEN 'Yes'
  when SoldAsVacant = 'Y' THEN 'Yes'
  ELSE SoldAsVacant
  END
FROM PortfolioProject..NashvilleHousing

--Removing duplicates
SELECT *
FROM PortfolioProject..NashvilleHousing

--where it might have same address, parcelid,saleprice, legalreference, bascially same order entered twice. To get hold of that, make a column named Row_number 
--and parition by those above and order by their unique id
--row_number is a built function that gives bigint

with CTE_RowNum AS (
SELECT *, 
   row_number() OVER (
   PARTITION BY ParcelID,
                PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY 
				   UniqueID
				   ) row_num
FROM PortfolioProject..NashvilleHousing

)
SELECT *
FROM CTE_RowNum
where row_num > 1
--Order by PropertyAddress
-- now delete them all those that have row_num > 1 which means they are duplicates.

select * 
FROM PortfolioProject..NashvilleHousing

--altering the table by dropping some useless columns. Should always triple check when deleting since i can't undo it once done.
--more like cleaning data
ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN SaleDate