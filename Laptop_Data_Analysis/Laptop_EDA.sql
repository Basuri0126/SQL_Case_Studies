-- 1. head-> tail-> sample
 
-- 2. fon numerical cols
-- ->number summary(count, min, max, mean, std,41,42,43) -missing values
-- -> outliers
-- -> horizontal/vertical histograms

-- 3. for categorical cols 
-- value counts -> pie chart
-- missing value

-- 4. numerical numerical
-- side by side 8 numbe 
-- scatterplot 
-- correlation

-- 5. categorical-categorical
-- contigency table -> stacked bar chart

-- 6. numerical- categorical
-- -> compare distribution across categories

-- 8. missing value treatment 
-- 9. feature engineering

-- ppi
-- price_bracket

-- 10. one hot encoding
-- ############################################################################################################

-- 1. head-> tail-> sample
SELECT * FROM laptopdata
ORDER BY `index` LIMIT 5;

SELECT * FROM laptopdata
ORDER BY `index` DESC LIMIT 5;

SELECT * FROM laptopdata
ORDER BY rand() LIMIT 5;

-- for numerical columns like Price*******************
SELECT COUNT(Price) OVER(),
MIN(Price) OVER(),
MAX(Price) OVER(),
AVG(Price) OVER(),
STD(Price) OVER(),
PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY Price) OVER() AS 'Q1',
PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY Price) OVER() AS 'Median',
PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY Price) OVER() AS 'Q3'
FROM laptopdata
ORDER BY `index` LIMIT 1;

-- missing value
SELECT COUNT(Price)
FROM laptopdata
WHERE Price IS NULL;

-- outliers
SELECT * FROM (SELECT *,
PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY Price) OVER() AS 'Q1',
PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY Price) OVER() AS 'Q3'
FROM laptopdata) t
WHERE t.Price < t.Q1 - (1.5*(t.Q3 - t.Q1)) OR
t.Price > t.Q3 + (1.5*(t.Q3 - t.Q1));

-- -> horizontal/vertical histograms
SELECT buckets, REPEAT('*',COUNT(*)) as 'count'
FROM 
(SELECT Price,
CASE 
	WHEN Price BETWEEN 0 AND 25000 THEN '0-25K'
    WHEN Price BETWEEN 25001 AND 50000 THEN '25K - 50k'
    WHEN Price BETWEEN 50001 AND 75000 THEN '50K - 75K'
    WHEN Price BETWEEN 75001 AND 100000 THEN '75K - 100K'
    ELSE '>100K'
END  AS 'buckets'
FROM laptopdata) t
GROUP BY t.buckets;

-- . *************************************************
SELECT Company, COUNT(*) 
FROM laptopdata
GROUP BY Company;


-- 5. categorical-categorical
-- contigency table -> stacked bar chart
SELECT Company,
SUM(CASE WHEN Touchscreen = 0 THEN 1 ELSE 0 END) AS 'Touchscreen_no',
SUM(CASE WHEN Touchscreen = 1 THEN 1 ELSE 0 END) AS 'Touchscreen_yes'
FROM laptopdata
GROUP BY Company;

SELECT  Company,
SUM(CASE WHEN Cpu_brand = 'Intel' THEN 1 ELSE 0 END) AS 'Intel',
SUM(CASE WHEN Cpu_brand = 'AMD' THEN 1 ELSE 0 END) AS 'Intel',
SUM(CASE WHEN Cpu_brand = 'Samsung' THEN 1 ELSE 0 END) AS 'Samsung'
FROM laptopdata
GROUP BY Company;

SELECT * FROM laptopdata;

-- categorical Numerical Bivrate analysis
SELECT Company,
MIN(Price),
MAX(Price),AVG(Price), STD(Price)
FROM laptopdata
GROUP BY Company;

-- missing values
-- thus my data have no data value lets create sime null value in price 
-- and then learn how i fill these values

 UPDATE laptopdata
 SET Price = NULL
 WHERE `index` IN (789, 456,1111,1200);

-- 1. Replace null value with mean of Column
UPDATE laptopdata 
SET Price = (SELECT AVG(Price) FROM (SELECT * FROM laptopdata) AS t2
WHERE t2.Price IS NOT NULL);

-- replace missing values with mean price of corresponding company
UPDATE laptopdata l1
SET Price = (SELECT AVG(Price) FROM(SELECT * FROM laptopdata l2 WHERE l1.Company = l2.Company) AS T) 
WHERE Price IS NULL;

-- CORRESSPONDING company + processor
SELECT * FROM laptopdata
WHERE Price IS  NULL;

-- Feature Engineering************************************
SELECT * FROM laptopdata;

ALTER TABLE laptopdata
ADD COLUMN ppi INTEGER;

SELECT 
ROUND(SQRT(Resolution_width*Resolution_width + Resolution_height*Resolution_height)/Inches)
FROM laptopdata;

UPDATE laptopdata
SET ppi = (ROUND(SQRT(Resolution_width*Resolution_width + Resolution_height*Resolution_height)/Inches));

SELECT * FROM laptopdata;

-- ADD NEW COLUMN scren_size
SELECT *,
CASE 
	 WHEN Inches < 14 THEN 'small'
	 WHEN Inches >= 14 AND Inches < 17 THEN 'medium'
	 ELSE 'large'
END AS 'BUCKET'
FROM laptopdata;

ALTER TABLE laptopdata
ADD COLUMN screen_size VARCHAR(255) AFTER Inches;

UPDATE laptopdata
SET screen_size = CASE 
	 WHEN Inches < 14 THEN 'small'
	 WHEN Inches >= 14 AND Inches < 17 THEN 'medium'
	 ELSE 'large'
END;

SELECT * FROM laptopdata;

SELECT screen_size, AVG(Price)
FROM laptopdata
GROUP BY screen_size;

-- one hot encoding******************************
 
SELECT DISTINCT Gpu_brand 
FROM laptopdata;

SELECT  gpu_brand,
CASE WHEN Gpu_brand = 'Nvidia' THEN 1 ELSE 0 END AS 'nvidia',
CASE WHEN Gpu_brand = 'Intel' THEN 1 ELSE 0 END AS 'INTEL',
CASE WHEN Gpu_brand = 'AMD' THEN 1 ELSE 0 END AS 'amd',
CASE WHEN Gpu_brand = 'ARM' THEN 1 ELSE 0 END AS 'arm'
FROM laptopdata;