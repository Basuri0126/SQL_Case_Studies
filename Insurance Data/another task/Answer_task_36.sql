-- 1************************************
SELECT * FROM (SELECT PatientID, claim, 
RANK() OVER(ORDER BY claim DESC) AS'top_5_claim'
FROM task.insurance_data) t
WHERE t.top_5_claim < 6 ;

-- 1***************************
SELECT *,
DENSE_RANK() OVER(ORDER BY claim DESC) AS 'top_claim'
FROM insurance_data LIMIT 5;

-- 2 #################################
SELECT PatientID,children,  avg_claim FROM (SELECT PatientID, children, ROW_NUMBER() OVER(PARTITION BY children) AS 'row_no',
AVG(claim) OVER(PARTITION BY children ORDER BY children) AS 'avg_claim'
FROM insurance_data) t
WHERE t.row_no = 1;


-- 3 **********************************
SELECT region, max_claim, min_claim FROM(SELECT *,
ROW_NUMBER() OVER(PARTITION BY region ORDER BY region) AS 'rank', 
MAX(claim) OVER(PARTITION BY region ORDER BY region) AS 'max_claim',
MIN(claim) OVER(PARTITION BY region ORDER BY region) As 'min_claim'
FROM insurance_data) t
WHERE t.rank = 1;

-- 4 *********************************
SELECT *,
SUM(claim) over(PARTITION BY age ORDER BY age) 
FROM insurance_data;


-- 5 ***********************************
SELECT *,
claim  - FIRST_VALUE(claim) OVER() AS 'diff'
FROM insurance_data;

-- 6 **************************************
SELECT *, claim - AVG(claim) OVER(PARTITION BY children)
FROM insurance_data ;

-- 7 *************************************
SELECT ROW_NUMBER() OVER() AS 'rank',
REGION,max_bmi
FROM(
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY region ORDER BY t.max_bmi DESC) AS 'rank'
FROM (SELECT region,
MAX(bmi) OVER(PARTITION BY region ORDER BY region) AS 'max_bmi'
FROM insurance_data) t) T2
WHERE T2.rank = 1;

-- 8 **************************************
SELECT *,
claim - FIRST_VALUE(claim) OVER(PARTITION BY region ORDER BY region) AS 'max_bmi'
FROM insurance_data;


-- 9 **************************************
SELECT *, claim,
(claim - MAX(claim) OVER(PARTITION BY smoker, region )) AS 'claim_diff'
FROM insurance_data
ORDER BY claim_diff DESC;

-- 10 ####################################
SELECT bmi, 
MAX(bmi) OVER(ORDER BY age ROWS BETWEEN 1 FOLLOWING AND 3 FOLLOWING )
FROM insurance_data;

-- 11 ***************************************
SELECT *, 
AVG(claim) OVER(ORDER BY claim ROWS BETWEEN 1 PRECEDING AND CURRENT ROW)
FROM insurance_data;

-- 12#####################################
WITH filtered_data AS(
SELECT * FROM insurance_data
WHERE diabetic = 'No' AND bmi BETWEEN 25 AND 30)

SELECT region,first_claim , gender,age 
FROM(SELECT *, 
FIRST_VALUE(claim) OVER(PARTITION BY region,gender ORDER BY age ASC) As 'first_claim',
ROW_NUMBER() OVER(PARTITION BY region,gender ORDER BY age ASC) AS 'rank'
FROM filtered_data) t
WHERE  t.rank = 1
 
 