--monday coffee --data analysis
SELECT * FROM City;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

--Reports & Data analysis

--First Question- Consumers count
--How many people in each city are estiomated to consume coffee, given that 25% of the population does?


SELECT
city_name,
population as original_population,
(population * 0.25)/ 1000 as coffee_consumers_in_thousands,
city_rank
FROM city
ORDER BY population DESC


--SECOND QUESTION
--What is the total revenue generated from coffee sales accross all cities in the last quater of 2023?--
SELECT
ci.city_name,
SUM(s.total)as TOTAL_REVENUE
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE
EXTRACT (YEAR FROM s.sale_date)  = 2023
AND EXTRACT (QUARTER FROM s.sale_date)  = 4
GROUP BY 1
ORDER BY 2 DESC

--QUESTION THREE
-- SALES COUNT FOR EACH PRODUCT
--How many unit of each coffee product have been sold ?

SELECT 
p.product_name,
COUNT (s.sale_id) as total_orders
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC

--QUESTION FOUR
--AVERAGE SALES AMOUNT PER CITY
--WHAT IS THE AVERAGE SALES AMOUNT PER CUSTOMER IN EACH CITY?


SELECT
ci.city_name,
SUM(s.total)as TOTAL_REVENUE,
COUNT (DISTINCT s.customer_id) as total_customer,
ROUND(SUM(s.total)::numeric/
COUNT(DISTINCT s.customer_id)::numeric, 2) as avg_sale_per_customer
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC

--QUESTION 5
--CITY POPULATION AND OFFEE CONSUMERS
--PROVIDE A LIST OF CITIES ALONG WITH THEIR POPULATIONS AND ESTIMATED COFFEE CONSUMWES

WITH city_table as
(SELECT
       City_name,
	   ROUND((population * 0.25)/1000000,2) as coffee_consumers
	   FROM city),
customers_table as
(SELECT
ci.city_name,
COUNT(DISTINCT C.CUSTOMER_ID) as unique_cx
FROM sales as s
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
)
SELECT
  customers_table.city_name,
  city_table.coffee_consumers as coffee_consumer_in_millions,
  customers_table.unique_cx
  FROM city_table
  JOIN
  customers_table
  ON city_table.city_name = customers_table.city_name

  --basically, what we did here was create two different tables using thr join and the with, then we joined them at the end to come to our final solution

--QUESTION NUMBER 6
--TOP SELLING PRODUCTS BY CITY
--EHAT ARE THE TOP 3 SELLING PRODUCTS IN EACH CITY BASED ON THE SALES VOLUME?

SELECT *
FROM 
(SELECT
 ci.city_name,
 p.product_name,
 COUNT(s.sale_id) as total_orders,
 DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT (s.sale_id)DESC)as rank
 FROM sales as s
 JOIN products as p
 ON s.product_id = p.product_id
 JOIN customers as c
 ON c.customer_id = s.customer_id
 JOIN city as ci
 ON ci.city_id =c.city_id
 GROUP BY 1,2)
 as t1
 WHERE rank <=3

 --QUESTION 7
 --CUSTOMER SEGMENTATION BY CITY
 --HOW MANY UNIQUE CUSTOMERS ARE THERE IN EACH CITY WHO HAVE PURCHASED COFFEE PRODUCTS?

 SELECT
 ci.city_name,
 COUNT(DISTINCT c.customer_id) as unique_cx
 FROM city as ci
 LEFT JOIN
 customers as c
 ON c.city_id = ci.city_id
 JOIN sales as s
 ON s.customer_id = c.customer_id
 WHERE
 s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
 GROUP BY 1

 --QUESTION 8
-- AVERAGE SALES VS RENT
--FIND EACH CITY THEIR AVERAGESALES PER CUSTOMER AND AVERAGE RENT PER CUSTOMER  

WITH city_table
as
( 
   SELECT
   ci.city_name,
   SUM(s.total) as total_revenue,
   COUNT(DISTINCT s.customer_id)as total_cx,
   ROUND(SUM(s.total)::numeric/
   COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_pr_cx
   FROM sales as s
   JOIN customers as c
   ON s.customer_id = c.customer_id
   JOIN city as ci
   ON ci.city_id = c.city_id
   GROUP BY 1
   ORDER BY 2 DESC),

   city_rent 
   as
   (SELECT
   city_name,estimated_rent
   from city)

   SELECT
   cr.city_name,
   cr.estimated_rent,
   ct.total_cx,
   ct.avg_sale_pr_cx,
   ROUND(cr.estimated_rent::numeric/
  ct.total_cx::numeric,2 ) as avg_rent_per_cx
  FROM city_rent as cr
  JOIN city_table as ct
  ON cr.city_name = ct.city_name
  ORDER BY 4 DESC
 
--QUESTION 9
--MONTHLLY SALES GROWTH
--SALES GROWTH RATE: CALCULATE THE PERCENTAGE GROWTH (OR DECLINE)IN SALES OVER DIFFERENT TIME PERIODS(MONTHLY), BY EACH CITY.
WITH
monthly_sales 
AS
(
 SELECT
 ci.city_name,
 EXTRACT(MONTH FROM sale_date)as month,
 EXTRACT (YEAR FROM sale_date) as YEAR,
 SUM(s.total) as total_sale

FROM sales as s
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1,2,3
ORDER BY 1,3,2
),
growth_ratio
as
(SELECT
city_name,
month,year,
total_sale as cr_month_sale,
LAG(total_sale,1) OVER(PARTITION BY city_name ORDER BY year, month)as last_month_sale
FROM monthly_sales)

SELECT
city_name,
month,
year,
cr_month_sale,
last_month_sale,
ROUND(
(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric* 100,2) 
as growth_ratio
FROM growth_ratio


--QUESTION 10
--MARKET POTENTIAL ANALYSIS
--IDENTIFY TOP 3 CITY BASED ON HIGHESTSALES, RETURN CITY NAME, TOTAL SALE,TOTAL RENT, TOTAL CUSTOMERS,ESTIMATED COFFEE CONSUMER


WITH city_table
as
( 
   SELECT
   ci.city_name,
   SUM(s.total) as total_revenue,
   COUNT(DISTINCT s.customer_id)as total_cx,
   ROUND(SUM(s.total)::numeric/
   COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_pr_cx
   FROM sales as s
   JOIN customers as c
   ON s.customer_id = c.customer_id
   JOIN city as ci
   ON ci.city_id = c.city_id
   GROUP BY 1
   ORDER BY 2 DESC),

   city_rent 
   as
   (SELECT
   city_name,estimated_rent,
   ROUND((population * 0.25)/1000000, 3 )as est_coffee_consumer_in_millions 
   from city)

   SELECT
   cr.city_name,
   total_revenue,
   cr.estimated_rent as total_rent,
   ct.total_cx,
   est_coffee_consumer_in_millions,
   ct.avg_sale_pr_cx,
   ROUND(cr.estimated_rent::numeric/
  ct.total_cx::numeric,2 ) as avg_rent_per_cx
  FROM city_rent as cr
  JOIN city_table as ct
  ON cr.city_name = ct.city_name
  ORDER BY 2 DESC
 

/*
--RECOMMENDATION
CITY 1: PUNE
1.THE AVERAGE RENT PER CUSTOMER IS LOW.
2.IT HAS THE HIGHEST TOTAL REVENUE.
3.AVERAGE SALE PER CUSTOMER IS HIGH TOO

CITY 2:JAIPUR
1. THE AVERAGE RENT PER CUSTOMER IS VERY LOW
2. THE AVERAGE SALE PER CUSTOMER IS HIGH
3.THE TOTAL REVENUE IS HIGH, CONSIDERING THE RENT PER CUSTOMER IS LOW

CITY 3:CHENNAI
1. IT HAS THE SECOND HIGHEST TOTAL REVENUE
2.THE ESTIMATED COFFEE CONSUMER IS HIGH TOO
3. THE AVERAGE RENT PER CUSTOMER IS STILL BELOW 500

CITY 4:DELHI
1. THE AVERAGE SALE PER CUSTOMER IS VERY HIGH
2. THE AVERANGE RENT PER CUSTOMER IS ALSO VERY LOW
3.THE ESTIMATED COFFEE CONSUMER IS VERY HIGH TO-7.7M. */.






