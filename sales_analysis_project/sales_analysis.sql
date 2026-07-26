create database sales_analysis;
use sales_analysis;
select * from sales_data limit 10;

-- Which countries generate highest sales but low profit?
select country,
round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit
from sales_data
group by country
having sum(sales) > 100000
order by total_profit;

-- Which are our top 10 most profitable products, and how much total revenue did they bring in?
select product_name, 
round(sum(sales),2) as total_revenue,
round(sum(profit),2) as total_profit
from sales_data
group by product_name
order by total_profit desc
limit 10;

-- Which sub categories of products are currently running at net loss?
select sub_category,
round(sum(sales),2) as total_revenue,
round(sum(profit),2) as total_profit
from sales_data
group by sub_category
having total_profit<0
order by total_profit;

-- Which category gives the highest profit margin?
select category,
round(sum(sales),2) as total_revenue,
round(sum(profit),2) as total_profit,
round(sum(profit)/sum(sales)*100,2) as profit_margin_percent
from sales_data
group by category
order by profit_margin_percent desc;

-- Which shipping mode is the most profitable?
select ship_mode,
round(sum(profit),2) as total_profit
from sales_data
group by ship_mode
order by total_profit desc;

-- Who are the top 5 highest-spending customers in each distinct market?
with ranked_customers as
(
select market,customer_id,customer_name,
round(sum(sales),2) as total_spend,
dense_rank() over (partition by market order by sum(sales) desc) as customer_rank
from sales_data
group by market,customer_id,customer_name
)
select market,customer_id,customer_name,total_spend
from ranked_customers
where customer_rank<=5;

-- What is the average shipping duration for each ship mode?
select ship_mode,
count(order_id) as total_orders,
round(avg(shipping_days),2) as average_shipping_duration
from sales_data
group by ship_mode
order by average_shipping_duration desc;

-- What is the average shipping time by market?
select market,
count(order_id) as total_orders,
round(avg(shipping_days),2) as average_shipping_time
from sales_data
group by market
order by average_shipping_time desc;

-- Best selling product in each sub-category
with rankingproducts as
(select product_name,
sub_category,
round(sum(sales),2) as total_sales,
row_number() over (partition by sub_category order by sum(sales) desc) as product_rank
from sales_data
group by product_name,sub_category
)
select product_name,
sub_category,
total_sales
from rankingproducts
where product_rank=1;


-- monthly sales and profit ,Month over month(MoM) growth
WITH monthly_totals AS (
    SELECT 
        year, 
        EXTRACT(MONTH FROM order_date) AS month, 
        ROUND(SUM(sales), 2) AS total_revenue, 
        ROUND(SUM(profit), 2) AS total_profit 
    FROM sales_data 
    GROUP BY year, EXTRACT(MONTH FROM order_date)
)
select year,month,
total_revenue,
total_profit,
round((total_profit/nullif(total_revenue,0))*100,2) as profit_margin,
round(
((total_revenue-lag(total_revenue,1) over (order by year,month))
/nullif(lag(total_revenue, 1) over (order by year, month), 0)) * 100,
2
) as revenue_mom_growth_percent,
round(
((total_profit-lag(total_profit,1) over (order by year,month))
/nullif(lag(total_profit, 1) over (order by year, month), 0)) * 100,
2
) as profit_mom_growth_percent
from monthly_totals
where year=2014
order by year,month;

-- Year-over-year sales growth
WITH yearly_totals AS (
    SELECT 
        year, 
        ROUND(SUM(sales), 2) AS total_revenue, 
        ROUND(SUM(profit), 2) AS total_profit 
    FROM sales_data 
    GROUP BY year
)
select year,
total_revenue,
total_profit,
round((total_profit/nullif(total_revenue,0))*100,2) as profit_margin,
round(
((total_revenue-lag(total_revenue) over (order by year))
/nullif(lag(total_revenue) over (order by year), 0)) * 100,
2
) as revenue_yoy_growth_percent,
round(
((total_profit-lag(total_profit) over (order by year))
/nullif(lag(total_profit) over (order by year), 0)) * 100,
2
) as profit_yoy_growth_percent
from yearly_totals
order by year;

--  Which products receive highest average discount?
select product_name,
round(avg(discount),2) as average_discount
from sales_data
group by product_name
order by average_discount desc
limit 10;

-- Who are the top most loyal(repeat) customers in each market?
with customer_order_counts as
(
select market,
customer_id,
max(customer_name) as customer_name,
count(distinct order_id) as total_orders,
round(sum(sales),2) as total_spend,
row_number() over (partition by market order by count(distinct order_id) desc,sum(sales) desc ) as customer_rank
from sales_data
group by market,customer_id
having count(distinct order_id)>1
)
select market,
customer_id,
customer_name,
total_orders,
total_spend
from customer_order_counts
where customer_rank<=3
order by market asc,total_orders desc;

-- Highest revenue city in each country
with city_sales as 
(
select city,country,
round(sum(sales),2) as total_revenue,
row_number() over (partition by country order by sum(sales) desc) as rank_no
from sales_data
group by country,city
)
select country,city,total_revenue
from city_sales
where rank_no=1
order by total_revenue desc;

-- profit contribution by region
select region,
round(sum(profit),2) as total_profit,
round(sum(profit)*100/(select sum(profit) from sales_data),2) as profit_percent
from sales_data
group by region
order by total_profit desc;


-- order priority analysis
SELECT order_priority,
       COUNT(*) AS orders,
       ROUND(SUM(sales),2) AS total_sales,
       ROUND(SUM(profit),2) AS total_profit,
       round(sum(profit)*100/(select sum(profit) from sales_data),2) as profit_percent,
       round(sum(sales)/count(*),2) as average_sales_per_order
FROM sales_data
GROUP BY order_priority
ORDER BY total_sales DESC;




