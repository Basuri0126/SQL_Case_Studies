 SELECT * FROM flight.flights;
 
 -- 1.	Find the month with most number of flights
 SELECT MONTHNAME(Date_of_Journey) AS 'month', COUNT(Airline) AS 'airline_count' 
 FROM flights
 GROUP BY MONTH(Date_of_Journey)
 ORDER BY airline_count DESC LIMIT 1;
 
 -- 2.	Which week day has most costly flights
 
 SELECT DAYNAME(Date_of_Journey),
 WEEKDAY(Date_of_Journey) AS 'week_day', AVG(Price) -- week day start from 0 that is why it show 3 not 4
 FROM flights
 GROUP BY WEEKDAY(Date_of_Journey)
 ORDER BY SUM(Price) DESC LIMIT 1;
 
 -- 3.	Find number of indigo flights every month
 SELECT MONTHNAME(Date_of_Journey),
 COUNT(*)
 FROM flights
 WHERE Airline = 'indigo'
 GROUP BY MONTHNAME(Date_of_Journey)
 ORDER BY COUNT(*);

-- 4.	Find list of all flights that depart between 10AM and 2PM from Delhi to Banglore
SELECT * 
FROM flights
WHERE dep_time BETWEEN '10:00' AND '14:00'
AND `source` = 'Banglore' AND destination = 'Delhi';

-- 5.	Find the number of flights departing on weekends from Bangalore
SELECT  
 COUNT(*)
FROM flights
WHERE Source = 'Banglore'  AND
(DAYNAME(Date_of_Journey) = 'Saturday' OR DAYNAME(Date_of_Journey) = 'Sunday') ;

-- add extra column 
ALTER TABLE flights ADD COLUMN departure DATETIME;

SELECT STR_TO_DATE((CONCAT(Date_of_Journey , Dep_time)), '%Y-%m-%d %H:%i') 
FROM flights; 

UPDATE flights
SET Departure = (STR_TO_DATE((CONCAT(Date_of_Journey , Dep_time)), '%Y-%m-%d %H:%i'));

SELECT * FROM flights;


-- 6.	Calculate the arrival time for all flights by adding the duration to the departure time
ALTER TABLE flights ADD COLUMN Duration_in_min INTEGER,
ADD COLUMN arrival DATETIME;

SELECT Duration,
((SUBSTRING_INDEX((SUBSTRING_INDEX(Duration, ' ',1)), 'h',1))) * 60  +
CASE 
	WHEN Duration NOT LIKE '%m%' THEN 0
    WHEN Duration LIKE '%h%' AND Duration LIKE '%m%' THEN 
    ((SUBSTRING_INDEX((SUBSTRING_INDEX(Duration, ' ',-1)), 'm',1)))
    ELSE 0
END AS 'min'
FROM flights;

UPDATE flights
SET Duration_in_min = ((SUBSTRING_INDEX((SUBSTRING_INDEX(Duration, ' ',1)), 'h',1))) * 60  +
CASE 
	WHEN Duration NOT LIKE '%m%' THEN 0
    WHEN Duration LIKE '%h%' AND Duration LIKE '%m%' THEN 
    ((SUBSTRING_INDEX((SUBSTRING_INDEX(Duration, ' ',-1)), 'm',1)))
    ELSE 0
END ;

SELECT * FROM flights;
SELECT departure, Duration_in_min, DATE_ADD(departure, INTERVAL Duration_in_min MINUTE)
FROM flights;

UPDATE flights
SET arrival = DATE_ADD(departure, INTERVAL Duration_in_min MINUTE);

SELECT TIME(arrival) 
FROM flights;

-- 7.	Calculate the arrival date for all the flights
SELECT DATE(arrival) 
FROM flights;

-- 8.	Find the number of flights which travel on multiple dates.
SELECT 
COUNT(*)
FROM flights
WHERE DATE(departure) != DATE(arrival);

-- 9.  Calculate the average duration of flights between all city pairs. The answer
--     should In xh ym format

SELECT `Source`, Destination, ROUND(AVG(Duration_in_min),2) AS 'avg_in_min',
CONCAT(ROUND(AVG(Duration_in_min)/60), ':', ROUND(AVG(Duration_in_min))%60) AS 'avg_duration',
TIME_FORMAT(SEC_TO_TIME(AVG(Duration_in_min)*60), '%T') AS 'avg_duraiton2'
FROM flights
GROUP BY Source, Destination;

-- 10.  Find all flights which departed before midnight but arrived at their destination
--      after midnight having only 0 stops.
SELECT * FROM flights
WHERE total_stops = 'non-stop' AND
DATE(departure) < DATE(arrival);

-- 11.  Find quarter wise number of flights for each airline
SELECT QUARTER(Date_of_Journey), Airline, COUNT(*)
FROM flights
GROUP BY QUARTER(Date_of_Journey), Airline;

-- 12.  Find the longest flight distance(between cities in terms of time) in India
SELECT `Source`, Destination, Duration_in_min
FROM flights
GROUP BY `Source`, Destination
ORDER BY Duration_in_min DESC LIMIT 1;

-- 13.  Average time duration for flights that have 1 stop vs more than 1 stops

WITH temp_table AS (SELECT *,
CASE 
	WHEN total_stops = 'non-stop' THEN 'non-stop'
    ELSE 'with stop'
END AS 'temp'
FROM flights)

SELECT temp,
TIME_FORMAT(SEC_TO_TIME(AVG(duration_in_min)*60),'%kh %im') AS 'avg_duration',
AVG(price) AS 'avg_price'
FROM temp_table
GROUP BY temp;

-- 14.  Find all Air India flights in a given date range originating from Delhi
SELECT * FROM flights
WHERE Airline = 'Air India'AND
source = 'Delhi' AND
DATE(departure) BETWEEN '2019-03-01' AND '2019-03-10';

-- 15.  Find the longest flight of each airline
SELECT Airline, MAX(Duration_in_min),
TIME_FORMAT(SEC_TO_TIME(MAX(duration_in_min)*60),'%kh %im') AS 'max_duration'
FROM flights
GROUP BY Airline
ORDER BY  MAX(Duration_in_min) DESC;

-- 16. Find all the pair of cities having average time duration > 3 hours
SELECT `Source`, Destination,
TIME_FORMAT(SEC_TO_TIME(AVG(duration_in_min)*60),'%kh %im') AS 'max_duration' 
FROM flights
GROUP BY `Source` , Destination
HAVING AVG(duration_in_min) > 180;

-- 17.  Make a weekday vs time grid showing frequency of flights from Banglore and Delhi
SELECT *, 
(12AM_to_6AM+ 6AM_to_12PM+ 12PM_to_18PM+18AM_to_24PM) AS 'total'
FROM (SELECT DAYNAME(Departure),
SUM(CASE WHEN HOUR(Departure) BETWEEN 0 AND 5 THEN 1 ELSE 0 END) AS '12AM_to_6AM',
SUM(CASE WHEN HOUR(Departure) BETWEEN 5 AND 11 THEN 1 ELSE 0 END) AS '6AM_to_12PM',
SUM(CASE WHEN HOUR(Departure) BETWEEN 12 AND 17 THEN 1 ELSE 0 END) AS '12PM_to_18PM',
SUM(CASE WHEN HOUR(Departure) BETWEEN 18 AND 23 THEN 1 ELSE 0 END) AS '18AM_to_24PM'
FROM flights
WHERE `Source` = 'Banglore' AND Destination = 'Delhi'
GROUP BY DAYNAME(Departure)
ORDER BY DAYOFWEEK(Departure)) t1;

-- 18.  Make a weekday vs time grid showing avg flight price from Banglore and Delhi
SELECT *, 
(12AM_to_6AM+ 6AM_to_12PM+ 12PM_to_18PM+18AM_to_24PM) AS 'total_Price'
FROM (SELECT DAYNAME(Departure),
AVG(CASE WHEN HOUR(Departure) BETWEEN 0 AND 5 THEN Price ELSE NULL END) AS '12AM_to_6AM',
AVG(CASE WHEN HOUR(Departure) BETWEEN 5 AND 11 THEN Price ELSE NULL END) AS '6AM_to_12PM',
AVG(CASE WHEN HOUR(Departure) BETWEEN 12 AND 17 THEN Price ELSE NULL END) AS '12PM_to_18PM',
AVG(CASE WHEN HOUR(Departure) BETWEEN 18 AND 23 THEN Price ELSE NULL END) AS '18AM_to_24PM'
FROM flights
WHERE `Source` = 'Banglore' AND Destination = 'Delhi'
GROUP BY DAYNAME(Departure)
ORDER BY DAYOFWEEK(Departure)) t1