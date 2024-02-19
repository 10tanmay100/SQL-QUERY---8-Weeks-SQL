create database week1;
use week1;

CREATE TABLE sales (
  `customerid` VARCHAR(1),
  `order_date` DATE,
  `product_id` INTEGER
);

INSERT INTO sales
  (`customerid`, `order_date`, `product_id`)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  `product_id` INTEGER,
  `product_name` VARCHAR(5),
  `price` INTEGER
);

INSERT INTO menu
  (`product_id`, `product_name`, `price`)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  `customerid` VARCHAR(1),
  `join_date` DATE
);

INSERT INTO members
  (`customerid`, `join_date`)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


show tables;
select * from members;
-- What is the total amount each customer spent at the restaurant?
SELECT 
    customerid, SUM(price) AS total_spent
FROM
    (SELECT 
        sales.customerid,
            order_date,
            sales.product_id,
            price
    FROM
        sales
    INNER JOIN menu ON (menu.product_id = sales.product_id)) AS t1
GROUP BY 1;

-- How many days has each customer visited the restaurant?
SELECT 
    customerid, COUNT(*) AS visited_days
FROM
    (SELECT 
        customerid, order_date
    FROM
        sales
    GROUP BY 1 , 2) AS t1
GROUP BY 1;

-- What was the first item from the menu purchased by each customer?
select sales.customerid,
first_value(product_name) over(partition by customerid order by order_date) as first_dish from sales
inner join menu on (menu.product_id=sales.product_id);

-- What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
    product_name, COUNT(*) AS purchase_times
FROM
    (SELECT 
        customerid, sales.product_id, product_name
    FROM
        sales
    INNER JOIN menu ON (sales.product_id = menu.product_id)) AS t1
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- Which item was the most popular for each customer?
with cte1 as (
select *, dense_rank() over (partition by customerid order by purchase_times desc) as rank_food from (
select customerid,product_name,
count(*) as purchase_times from sales inner join menu on (menu.product_id=sales.product_id)
group by 1,2) as t1)
select customerid,product_name,purchase_times from cte1 where rank_food=1;

-- Which item was purchased first by the customer after they became a member?
with cte2 as (
with cte1 as (
SELECT 
    sales.customerid, order_date, product_name 
FROM
    members
        INNER JOIN
    sales ON (sales.customerid = members.customerid)
        INNER JOIN
    menu ON (menu.product_id = sales.product_id)
WHERE
    sales.order_date >= members.join_date)
select *, first_value(product_name) over(partition by customerid order by order_date) as first_purchased_product from cte1)
select customerid,first_purchased_product from cte2
group by 1,2;

-- What is the total items and amount spent for each member before they became a member?
with cte1 as (
SELECT 
    sales.customerid, order_date, product_name , price
FROM
    members
        INNER JOIN
    sales ON (sales.customerid = members.customerid)
        INNER JOIN
    menu ON (menu.product_id = sales.product_id)
WHERE
    sales.order_date < members.join_date)
select customerid,count(*) as total_items,sum(price) as total_spend from cte1
group by 1;

-- If each $1 spent equates to 10 points and sushi has a 2x 
-- points multiplier - how many points would each customer have?
with cte1 as (
select customerid, product_name, 
if (product_name="sushi",2,1)*10 as points 
from (
select sales.customerid,product_name from members inner join sales on 
(sales.customerid=members.customerid)
inner join menu on (menu.product_id=sales.product_id)) as t1)
select customerid,sum(points) as total_points from cte1
group by 1;

-- In the first week after a customer joins the program 
-- (including their join date) they earn 2x points on all items, not just sushi - 
-- how many points do customer A and B have at the end of January?
with cte1 as (
select *,if(product_name="sushi",2,if(join_date>=order_date and order_date<=one_week_addon,2,1)) as points 
from (
select sales.customerid,join_date,order_date,date_add(order_date,interval 1 week) as one_week_addon,
product_name from members inner join sales on (sales.customerid=members.customerid)
inner join menu on (menu.product_id=sales.product_id)) as t1
where month(order_date)=1)
select customerid,sum(points)*10 as points from cte1
group by 1;


