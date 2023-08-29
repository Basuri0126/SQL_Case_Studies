SELECT * FROM uncleaned_laptop.laptopdata;

-- create backup ************************
CREATE TABLE laptopdata_backup LIKE laptopdata;

INSERT INTO laptopdata_backup
SELECT * FROM laptopdata;

-- check memory consumption ****************
SELECT DATA_LENGTH/1024 FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'uncleaned_laptop'
AND TABLE_NAME = 'laptopdata';

SELECT * FROM laptopdata;

-- Drop Non important column
ALTER TABLE laptopdata DROP COLUMN `Unnamed: 0`;

-- add a column index 
ALTER TABLE laptopdata
ADD COLUMN `index` INT UNIQUE AUTO_INCREMENT;

SELECT * FROM laptopdata;

-- Drop null values rows *************************
DELETE FROM laptopdata
WHERE `index` IN (
SELECT * FROM (SELECT `index` FROM laptopdata
WHERE Company IS NULL AND TypeName IS NULL AND Inches IS NULL
AND ScreenResolution IS NULL AND `Cpu` IS NULL AND Ram IS NULL
AND `Memory` IS NULL AND Gpu IS NULL AND OpSys IS NULL AND
WEIGHT IS NULL AND Price IS NULL) T);

-- drop duplicates ******************************************
DELETE FROM laptopdata
WHERE `index` NOT IN (
SELECT * FROM 
(SELECT MIN(`index`) FROM laptopdata
GROUP BY Company, TypeName, Inches, ScreenResolution, `Cpu`, Ram,
`Memory`, Gpu, OpSys, Weight, Price) t);

-- Another way to delete duplicates 
-- DELETE d1
-- FROM laptopdata d1
-- LEFT JOIN (
--     SELECT MIN(`index`) 
--     FROM laptopdata
--     GROUP BY Company, TypeName, Inches, ScreenResolution, `Cpu`, Ram,
-- `Memory`, Gpu, OpSys, Weight, Price
-- ) d2 ON d1.index = d2.index
-- WHERE d2.index IS NULL;


-- DELETE FROM laptopdata
-- WHERE `index` IN (
-- SELECT `index` FROM(
-- SELECT *,
-- ROW_NUMBER() OVER(PARTITION BY Company, Typename, ScreenResolution, `Cpu`, 
-- Ram,`Memory`, Gpu, Inches, OpSys, Weight, Price ORDER BY `index`) AS 'row_num'
-- FROM laptopdata) t
-- WHERE t.row_num > 1) ;


-- change Inches datatype
ALTER TABLE laptopdata MODIFY COLUMN Inches DECIMAL(10,1);

SELECT COUNT(*) FROM laptopdata;
 
-- remove 'GB' from Ram and change datatype as well

-- UPDATE laptopdata l1
-- SET Ram = (SELECT REPLACE(Ram,'GB','') FROM laptopdata l2 WHERE l2.index = l1.index);

UPDATE laptopdata AS ld1
JOIN laptopdata AS ld2 ON ld1.index = ld2.index
SET ld1.Ram = REPLACE(ld2.Ram, 'GB', '');

ALTER TABLE laptopdata MODIFY COLUMN Ram INT;

-- check memory consumption after this changes
SELECT DATA_LENGTH/1024 FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'uncleaned_laptop'
AND TABLE_NAME = 'laptopdata';

-- remove 'KG' from weight and change data type as well
-- UPDATE laptopdata l1
-- SET Weight = (SELECT REPLACE(Weight,'kg','') 
--            FROM laptopdata l2 WHERE l2.index = l1.index);

-- Identify rows with non-numeric characters
SELECT *
FROM laptopdata
GROUP BY Weight;
-- there is '?' sign in weight column

-- Update the non-numeric values to NULL
UPDATE laptopdata
SET Weight = NULL
WHERE Weight = '?';

-- Modify the column data type
ALTER TABLE laptopdata
MODIFY COLUMN Weight DECIMAL(10, 2);

-- Round price Column and change datatype also
SELECT Round(Price) FROM test_delete;

UPDATE test_delete AS d1
JOIN test_delete AS d2 ON d1.index = d2.index
SET d1.Price = Round(d2.Price);

UPDATE laptopdata d1
SET d1.Price = (SELECT * FROM (SELECT ROUND(d2.price) FROM test_delete d2 WHERE d1.index = d2.index) t);

ALTER TABLE laptopdata MODIFY COLUMN Price INT;


--  change OpSys column value 
SELECT OpSys, 
CASE
    WHEN OpSys LIKE '%Window%' THEN 'window'
    WHEN OpSys LIKE '%Mac%' THEN 'macos'
    WHEN OpSys LIKE 'No OS' THEN 'N/A'
    WHEN OpSys LIKE '%Linux%' THEN 'linux'
    WHEN OpSys LIKE '%Chrome%' THEN 'chromeOS'
    ELSE 'others'
END AS ''
FROM laptopdata;

UPDATE laptopdata
SET OpSys = CASE
    WHEN OpSys LIKE '%Window%' THEN 'window'
    WHEN OpSys LIKE '%Mac%' THEN 'macos'
    WHEN OpSys LIKE 'No OS' THEN 'N/A'
    WHEN OpSys LIKE '%Linux%' THEN 'linux'
    WHEN OpSys LIKE '%Chrome%' THEN 'chromeOS'
    ELSE 'others'
END;

SELECT * FROM laptopdata;

-- Add Gpu_brand column***************
-- Add Gpu_name Column ***************
ALTER TABLE laptopdata
ADD COLUMN gpu_brand VARCHAR(255) AFTER Gpu,
ADD COLUMN gpu_name VARCHAR(255) AFTER gpu_brand;

UPDATE  laptopdata
SET Gpu_brand = SUBSTRING_INDEX(Gpu, ' ', 1);

UPDATE laptops l1
SET gpu_name = (SELECT REPLACE(Gpu,gpu_brand,'') 
				FROM laptops l2 WHERE l2.index = l1.index);

SELECT REPLACE(Gpu, Gpu_brand, '') FROM laptopdata;
UPDATE  laptopdata
SET Gpu_name = REPLACE(Gpu, Gpu_brand, '');

SELECT * FROM laptopdata;
ALTER TABLE laptopdata
DROP COLUMN Gpu;

-- cleaning and make usefull column from CPU column************************************
ALTER TABLE laptopdata
ADD COLUMN Cpu_brand VARCHAR(255) AFTER Cpu,
ADD COLUMN Cpu_name VARCHAR(255) AFTER Cpu_brand,
ADD COLUMN Cpu_speed VARCHAR(255) AFTER Cpu_name;

-- add cpu_brand column **********************
SELECT 
SUBSTRING_INDEX(Cpu, ' ', 1) 
FROM laptopdata;

UPDATE laptopdata
SET Cpu_brand = SUBSTRING_INDEX(Cpu, ' ', 1);

-- add cpu_speed column **********************
SELECT 
CAST(REPLACE(SUBSTRING_INDEX(Cpu, ' ', -1), 'GHz', '') AS DECIMAL(10, 2))
FROM laptopdata;

UPDATE laptopdata
SET Cpu_speed = CAST(REPLACE(SUBSTRING_INDEX(Cpu, ' ', -1), 'GHz', '') AS DECIMAL(10, 2));

-- add cpu_name column **********************
SELECT Cpu,
REPLACE((REPLACE(Cpu, Cpu_brand, '')), SUBSTRING_INDEX(Cpu, ' ', -1), '')
FROM laptopdata;

UPDATE laptopdata
SET Cpu_name = REPLACE((REPLACE(Cpu, Cpu_brand, '')), SUBSTRING_INDEX(Cpu, ' ', -1), '');

-- drop cpu column
ALTER TABLE laptopdata 
DROP COLUMN Cpu;

SELECT * FROM laptopdata;

-- resolution column *******************
SELECT SUBSTRING_INDEX((SUBSTRING_INDEX(ScreenResolution, ' ', -1)), 'x', 1),
SUBSTRING_INDEX((SUBSTRING_INDEX(ScreenResolution, ' ', -1)), 'x', -1)
FROM laptopdata;

-- add column width and height of resolution ***********************************************
ALTER TABLE laptopdata
ADD COLUMN Resolution_width INT AFTER  ScreenResolution,
ADD COLUMN Resolution_height INT AFTER  Resolution_width;

UPDATE laptopdata
SET Resolution_width = SUBSTRING_INDEX((SUBSTRING_INDEX(ScreenResolution, ' ', -1)), 'x', 1);

UPDATE laptopdata
SET Resolution_height = SUBSTRING_INDEX((SUBSTRING_INDEX(ScreenResolution, ' ', -1)), 'x', -1);

-- add touch screen column******************
ALTER TABLE laptopdata
ADD COLUMN Touchscreen INT AFTER Resolution_height;

SELECT ScreenResolution 
FROM laptopdata
WHERE ScreenResolution LIKE '%Touchscreen%';

UPDATE laptopdata
SET Touchscreen = ScreenResolution LIKE '%Touch%';

-- add ips column *************
ALTER TABLE laptopdata
ADD COLUMN IPS_panel INT AFTER Resolution_height;

UPDATE laptopdata
SET IPS_panel = ScreenResolution LIKE '%IPS%';

ALTER TABLE laptopdata
DROP COLUMN ScreenResolution;

SELECT 
SUBSTRING_INDEX((TRIM(Cpu_name)), ' ', 2)
FROM laptopdata
GROUP BY SUBSTRING_INDEX((TRIM(Cpu_name)), ' ', 2);

UPDATE laptopdata
SET Cpu_name = SUBSTRING_INDEX((TRIM(Cpu_name)), ' ', 2);

SELECT Memory FROM laptopdata;

ALTER TABLE laptopdata
ADD COLUMN Memory_type VARCHAR(255) AFTER Memory,
ADD COLUMN Primary_storage VARCHAR(255) AFTER Memory_type,
ADD COLUMN secondary_storage  VARCHAR(255) AFTER Primary_storage;

SELECT Memory,
CASE
	WHEN Memory LIKE '%SSD%' AND Memory LIKE '%SSD%' THEN 'HYBRID'
    WHEN Memory LIKE '%SDD%' THEN 'SDD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
    ELSE NULL
END AS 'memory_type'
FROM laptopdata;

UPDATE laptopdata
SET Memory_type = CASE
	WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%SSD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
    WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    ELSE NULL
END;

SELECT Memory, 
REGEXP_SUBSTR(SUBSTRING_INDEX(Memory, '+', 1), '[0-9]+'),
REGEXP_SUBSTR(CASE WHEN Memory LIKE '%+%' THEN SUBSTRING_INDEX(Memory, '+', -1) ELSE 0 END,'[0-9]+')
FROM laptopdata;

UPDATE  laptopdata
SET Primary_storage = REGEXP_SUBSTR(SUBSTRING_INDEX(Memory, '+', 1), '[0-9]+'),
Secondary_storage = REGEXP_SUBSTR(CASE WHEN Memory LIKE '%+%' THEN SUBSTRING_INDEX(Memory, '+', -1) ELSE 0 END,'[0-9]+');

SELECT Primary_storage, 
CASE WHEN Primary_storage <= 2 THEN Primary_storage * 1024 ELSE Primary_storage END,
CASE WHEN Secondary_storage <= 2 THEN secondary_storage * 1024 ELSE Secondary_storage END as 'p'
FROM laptopdata;

UPDATE laptopdata
SET Primary_storage = CASE WHEN Primary_storage <= 2 THEN Primary_storage * 1024 ELSE Primary_storage END,
Secondary_storage = CASE WHEN Secondary_storage <= 2 THEN secondary_storage * 1024 ELSE Secondary_storage END;

ALTER TABLE laptopdata
DROP COLUMN Memory;


select * from laptopdata;

-- ****************************************************END*******************************************************







 