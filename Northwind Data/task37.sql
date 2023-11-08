-- 1. Rank Employee in terms of revenue generation. Show employee id, first name, revenue, and rank
SELECT t3.EmployeeID, t3.FirstName, SUM(t4.UnitPrice * t4.Quantity) AS 'revenue',
RANK() OVER(ORDER BY SUM(t4.UnitPrice * t4.Quantity) DESC) AS EmpRank 
FROM 
(SELECT t1.EmployeeID, t1.FirstName, t2.OrderID FROM northwind.nw_employees t1
JOIN nw_orders t2
ON t1.EmployeeID = t2.EmployeeID) t3
JOIN nw_order_details t4
ON t3.OrderID = t4.OrderID
GROUP BY t3.EmployeeID, t3.FirstName;

-- 2. Show All products cumulative sum of units sold each month.

SELECT t3.ProductID, MONTH(t1.OrderDate) AS 'Month',
SUM(t2.Quantity) AS 'QuantitySum',
sum(SUM(t2.Quantity)) OVER(PARTITION BY t3.ProductID ORDER BY MONTH(t1.OrderDate) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS 'CUMSUM'

FROM nw_orders t1
JOIN nw_order_details t2
ON t1.orderID = t2.OrderID
JOIN nw_products t3
ON t3.ProductID = t3.ProductID
GROUP BY t3.ProductID, MONTH(t1.OrderDate);

-- 3.Show Percentage of total revenue by each suppliers
SELECT s.SupplierID, SUM(od.UnitPrice*od.Quantity) AS 'Revenue', 
ROUND(SUM(od.UnitPrice*od.Quantity)/SUM(SUM(od.UnitPrice*od.Quantity)) OVER() *100,2) AS 'PercentofTotal'
FROM nw_suppliers s
JOIN nw_products p
ON s.SupplierID = p.SupplierID
JOIN nw_order_details od
ON p.ProductID = od.ProductID
GROUP BY s.SupplierID 
ORDER BY Revenue DESC;

-- 4: Show Percentage of total orders by each suppliers
SELECT s.SupplierID, s.ContactName,
COUNT(DISTINCT(od.OrderID)) AS 'Number_of_Order',
ROUND(COUNT(DISTINCT(od.OrderID))/SUM(COUNT(DISTINCT(od.OrderID))) OVER() * 100,2) AS 'PCT_of_Total'
FROM nw_suppliers s
JOIN nw_products p
ON s.SupplierID = p.SupplierID
JOIN nw_order_details od
ON od.ProductID = p.ProductID
GROUP BY s.SupplierID
ORDER BY NUmber_of_Order DESC;

-- 5.  Show All Products Year Wise report of totalQuantity sold, percentage change from last year.
SELECT p.ProductID,p.ProductName AS 'product_name', YEAR(o.OrderDate) AS 'Year',
SUM(od.Quantity) AS 'Total_Quantity',
((SUM(od.Quantity) - LAG(SUM(od.Quantity)) OVER(PARTITION BY ProductID ORDER BY ProductID, YEAR(o.OrderDate)))/
LAG(SUM(od.Quantity)) OVER(PARTITION BY ProductID ORDER BY ProductID, YEAR(o.OrderDate))) * 100 AS 'Percent_change'
FROM nw_orders o
JOIN nw_order_details od
ON o.OrderID = od.OrderID
JOIN nw_products p
ON p.ProductID = od.ProductID
GROUP BY p.ProductID, YEAR(o.OrderDate);

-- 6.  for each condition, what is the average satisfaction level of drugs that are "On Label" vs "Off Label"?

-- THIS query is coorect also but i have done this with window function also let see we can this or not (:
SELECT  `Condition`, Indication,
AVG(Satisfaction)
FROM drug
GROUP BY `Condition`, indication;

WITH temp AS (
SELECT `Condition`, Indication, Satisfaction,
ROUND(AVG(Satisfaction) OVER(PARTITION BY `Condition`, Indication ORDER BY Satisfaction 
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING), 2) AS 'AVG_Satisfaction',
DENSE_RANK() OVER(PARTITION BY `Condition`, Indication ORDER BY Satisfaction) AS 'rank'
FROM drug
)

SELECT `Condition`, Indication, AVG_Satisfaction 
FROM temp
WHERE `rank` = 1;

-- 6. For each drug type (RX, OTC, RX/OTC), what is the average ease of use and satisfaction level of drugs 
--    with a price above the median for their type?
WITH temp AS (
SELECT Type,
AVG(EaseOfUse) OVER(PARTITION BY Type) AS 'avg_EaseOfuse',
AVG(Satisfaction) OVER(PARTITION BY Type) AS 'avg_satisfaction'
FROM(
SELECT Type, Price, EaseOfUse, Satisfaction,
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Price) OVER (PARTITION BY Type) AS 'median_price'
FROM drug
WHERE Type IN ('RX', 'OTC', 'RX/OTC')
) AS sub_query
WHERE Price > median_price)

SELECT * FROM temp
GROUP BY Type;

-- 7.  What is the cumulative distribution of EaseOfUse ratings for each drug type (RX, OTC, RX/OTC)? 
--     Show the results in descending order by drug type and cumulative distribution. 
--     (Use the built-in method and the manual method by calculating on your own. 
--     For the manual method, use the "ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW" 
--     and see if you get the same results as the built-in method.)

SELECT Type, EaseOfUse,
COUNT(*) OVER(PARTITION BY Type ORDER BY EaseOfuse ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 1.0/
COUNT(*) OVER(PARTITION BY Type) AS 'cummulative_dist', -- manual method
CUME_DIST() OVER(PARTITION BY Type ORDER BY EaseOfUse) AS 'perentile_score' -- built_in_method 
FROM drug
WHERE `Type` IN  ('RX', 'OTC', 'RX/OTC')
ORDER BY Type, cummulative_dist DESC;

-- 9.  What is the median satisfaction level for each medical condition? 
--     Show the results in descending order by median satisfaction level. 
--     (Don't repeat the same rows of your result.)

SELECT * FROM (SELECT `Condition`,
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Satisfaction) OVER(PARTITION BY `Condition`) AS 'median_satisfaction'
FROM drug) T
GROUP BY T.Condition
ORDER BY median_satisfaction DESC;

-- 10.  What is the running average of the price of drugs for each medical condition? 
--      Show the results in ascending order by medical condition and drug name.

-- in question there is no mention how much running average is calculated so i consider 5
SELECT `Condition`,drug, Price,
AVG(Price) OVER(PARTITION BY `Condition` ORDER BY drug ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS 'running_avg_price'
FROM drug
ORDER BY `Condition`, drug;

-- 11.  What is the percentage change in the number of reviews for each drug between the previous rows and 
--      the current row? Show the results in descending order by percentage change.

SELECT `Condition`, drug, Reviews,
(Reviews - LAG(Reviews) OVER (PARTITION BY `Condition`, drug ORDER BY Reviews DESC)) * 100/
LAG(drug.Reviews) OVER (
        PARTITION BY drug.Condition, Drug
        ORDER BY Reviews DESC
    )  as 'pct'
FROM drug
ORDER BY pct DESC ;


-- 12.  What is the percentage of total satisfaction level for each drug type (RX, OTC, RX/OTC)? 
--      Show the results in descending order by drug type and percentage of total satisfaction.
SELECT * FROM (SELECT Type,
ROUND((SUM(Satisfaction) OVER(PARTITION BY Type)*100)/SUM(Satisfaction) OVER(),2) AS 'pct_total'
FROM drug
WHERE Type IN ('RX', 'OTC', 'RX/OTC')
ORDER BY Type DESC, pct_total DESC
) T
GROUP BY Type;

-- 13. What is the cumulative sum of effective ratings for each medical condition and drug form combination? 
--     Show the results in ascending order by medical condition, drug form and the name of the drug.
 SELECT `Condition`,Drug , Form, Effective, 
 SUM(Effective) OVER(PARTITION BY `Condition`, Form ORDER BY Drug
 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
 FROM drug
 ORDER BY `Condition`, Form, Drug;
 
 -- 14. What is the rank of the average ease of use for each drug type (RX, OTC, RX/OTC)? 
 --     Show the results in descending order by rank and drug type.
 SELECT Type, 
 AVG(EaseOfUse) AS 'avg_easeofuse',
 RANK() OVER(ORDER BY AVG(EaseOfUse) DESC) AS 'rank'
 FROM drug
 WHERE Type IN ('RX', 'OTC', 'RX/OTC')
 GROUP BY Type
 ORDER BY `rank`, Type;
 
 -- 15.  For each condition, what is the average effectiveness of the top 3 most reviewed drugs?
 SELECT * FROM(
 SELECT  `Condition`, Drug,
 ROUND(AVG(Effective),2) AS 'avg_effective',
 ROW_NUMBER() OVER(PARTITION BY `Condition` ORDER BY SUM(Reviews) DESC) AS 'rank'
 FROM drug
 GROUP BY `Condition`, Drug) t
 WHERE `rank` < 4 
 ORDER BY `Condition`, `rank`;
 
-- alternate solution
SELECT * FROM (
SELECT `Condition`, Drug, ROUND(Reviews,2) AS 'REVIEWS',  
AVG(Effective) OVER(PARTITION BY `Condition`, Drug ORDER BY Reviews DESC) AS avg_effective,
ROW_NUMBER() OVER(PARTITION BY `Condition` ORDER BY Reviews) AS 'rank'
FROM drug) AS t
WHERE `rank` < 4;

