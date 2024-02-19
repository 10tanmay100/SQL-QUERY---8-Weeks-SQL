show tables;
-- How many pizzas were ordered?
select count(customer_orders.pizza_id) as ordered_pizzas from customer_orders inner join runner_orders
on (runner_orders.order_id=customer_orders.order_id) inner join pizza_names
on (pizza_names.pizza_id=customer_orders.pizza_id);
-- How many unique customer orders were made?
select count(distinct(customer_id)) as unique_customers from 
customer_orders inner join pizza_names
on (pizza_names.pizza_id=customer_orders.pizza_id);
-- How many successful orders were delivered by each runner?

select count(distinct(runner_orders.order_id)) as successful_orders from runners  inner join runner_orders
on (runners.runner_id=runner_orders.runner_id) inner join
customer_orders on (customer_orders.order_id=runner_orders.order_id) inner join
pizza_names on (pizza_names.pizza_id=customer_orders.pizza_id)
where cancellation not in ('Restaurant Cancellation','Customer Cancellation');

-- How many of each type of pizza was delivered?
select * from pizza_toppings;


-- How many Vegetarian and Meatlovers were ordered by each customer?
select pizza_name,count(pizza_name) as delivered from(
select customer_orders.order_id,customer_orders.customer_id,pizza_name from runner_orders inner join customer_orders on (runner_orders.order_id=customer_orders.order_id) inner join pizza_names 
on (pizza_names.pizza_id=customer_orders.pizza_id)
where cancellation not in ('Restaurant Cancellation','Customer Cancellation')) as t1
group by 1;

-- What was the maximum number of pizzas delivered in a single order?
with cte1 as (
select customer_orders.order_id,count(customer_orders.pizza_id) as pizzas_ordered from pizza_names inner join customer_orders 
on(pizza_names.pizza_id=customer_orders.pizza_id) inner join runner_orders 
on (runner_orders.order_id=customer_orders.order_id)
where cancellation not in ('Restaurant Cancellation','Customer Cancellation')
group by 1)
select order_id,pizzas_ordered from cte1
where pizzas_ordered=(select max(pizzas_ordered) from cte1);

-- For each customer, how many delivered pizzas had at least 1 change 
-- and how many had no changes?
select customer_id,sum(at_least_one) as at_least_one, sum(no_change) as no_change from (
with parent_cte as (
with global_cte as (
with cte1 as 
(
select order_id,count(*) as at_least_one from customer_orders
group by 1
having at_least_one>1),
cte2 as 
(select order_id,count(*) no_change from customer_orders
group by 1
having no_change=1),
cte3 as 
(select order_id from customer_orders)
select cte3.order_id,at_least_one,no_change from cte3 left join cte2 on (cte2.order_id=cte3.order_id) left join
cte1 on (cte1.order_id=cte3.order_id))
select customer_id,customer_orders.order_id,ifnull(at_least_one,0) as at_least_one,ifnull(no_change,0) as no_change from global_cte
inner join customer_orders on (customer_orders.order_id=global_cte.order_id) inner join runner_orders
on (runner_orders.order_id=customer_orders.order_id)
where cancellation not in ('Restaurant Cancellation','Customer Cancellation'))
select * from parent_cte
group by 1,2,3,4) as t1
group by 1;

-- How many pizzas were delivered that had both exclusions and extras?
SELECT 
    COUNT(customer_orders.pizza_id) AS pizzas_extras_exclusions
FROM
    customer_orders
        INNER JOIN
    runner_orders ON (runner_orders.order_id = customer_orders.order_id)
        INNER JOIN
    pizza_names ON (pizza_names.pizza_id = customer_orders.pizza_id)
WHERE
    (exclusions != '' AND extras != '')
        AND (exclusions != 'null'
        AND extras != 'null');

-- What was the total volume of pizzas ordered for each hour of the day?
SELECT 
    DATE_FORMAT(order_time, '%Y-%m-%d %H:00:00') AS hour_of_day,
    COUNT(*) AS total_pizza_volume
FROM
    customer_orders inner join pizza_names on(pizza_names.pizza_id=customer_orders.pizza_id)
    inner join runner_orders on (runner_orders.order_id=customer_orders.order_id)
GROUP BY DATE_FORMAT(order_time, '%Y-%m-%d %H:00:00')
ORDER BY hour_of_day;

-- What was the volume of orders for each day of the week?
SELECT 
    dayofweek(order_time) AS week_,
    COUNT(*) AS total_pizza_volume
FROM
    customer_orders inner join pizza_names on(pizza_names.pizza_id=customer_orders.pizza_id)
    inner join runner_orders on (runner_orders.order_id=customer_orders.order_id)
GROUP BY dayofweek(order_time)
ORDER BY week_;
