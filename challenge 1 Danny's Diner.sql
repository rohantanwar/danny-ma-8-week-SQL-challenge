INSERT INTO sales
  ("customer_id", "order_date", "product_id")
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
 
 select * from menu;

 CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');

  
CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');




-- Q1. What is the total amount each customer spent at the restaurant?

  select s.customer_id,  sum(m.price) as 'Total Bill'
  from sales s 
  inner join menu m
  on s.product_id = m.product_id
  group by s.customer_id;
  


-- Q2. How many days has each customer visited the restaurant?

select customer_id, count(distinct(order_date)) as 'No. of Days Visited'
from sales
group by customer_id;





--Q3. What was the first item from the menu purchased by each customer?
 
  with ordered_sale_cte as 
  (select s.customer_id,s.order_date, m.product_name,
  dense_rank() over (partition by s.customer_id order by s.order_date) as 'Rank'
  from sales s
  join menu m
  on s.product_id = m.product_id)
  select customer_id, product_name
  from ordered_sale_cte
  where rank = 1
  group by customer_id, product_name; 




-- Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select  top 1(count(s.product_id)) as 'most_ordered_product', m.product_name
from sales s
join menu m
on s.product_id = m.product_id
group by m.product_name
order by 'most_ordered_product' desc;



-- Q5. Which item was the most popular for each customer?


 with fav_item_cte as 
  (select s.customer_id, m.product_name, count(s.product_id) as 'order_count',
  dense_rank() over (partition by s.customer_id order by count(s.product_id)desc) as 'Rank'
  from sales s
  join menu m
  on s.product_id = m.product_id group by s.customer_id,  m.product_name)
  select customer_id, product_name,order_count
  from fav_item_cte
  where rank = 1; 


 -- Q6. Which item was purchased first by the customer after they became a member?


WITH member_sales_cte AS 
(
 SELECT s.customer_id, m.join_date, s.order_date,   s.product_id,
         DENSE_RANK() OVER(PARTITION BY s.customer_id
  ORDER BY s.order_date) AS rank
     FROM sales AS s
 JOIN members AS m
  ON s.customer_id = m.customer_id
 WHERE s.order_date >= m.join_date)
 SELECT s.customer_id, s.order_date, m2.product_name 
FROM member_sales_cte AS s
JOIN menu AS m2
 ON s.product_id = m2.product_id
WHERE rank = 1;



-- Q7. Which item was purchased just before the customer became a member?

with last_order_cte as
(
select s.customer_id, mb.join_date, s.order_date, s.product_id,
DENSE_RANK() over (partition by s.customer_id order by s.order_date desc) as rank
from sales s
join members mb
on s.customer_id = mb.customer_id
where s.order_date < mb.join_date)
select s.customer_id, s.order_date, m.product_name
from last_order_cte s
join menu m
on s.product_id = m.product_id
where rank = 1;



-- Q8 What is the total items and amount spent for each member before they became a member?

select s.customer_id, count(distinct(s.product_id)) as 'Total Items', sum(m.price) as 'Amount Spent'
from sales s
join menu m 
on s.product_id = m.product_id
join members mb 
on s.customer_id = mb.customer_id
where  s.order_date < mb.join_date
group by s.customer_id;



-- Q9. If each $1 spent equates to  10 points and sushi has a 2x points multiplier - how many points would each customer have?

with points_cte as
 (
select *, 
case
  when product_id = 1 then price * 20
  else price * 10
  end as points
 from menu
 )
 select s.customer_id, sum(p.points) as 'Total Points'
 from points_cte p 
 join sales s
 on s.product_id = p.product_id
 group by s.customer_id;


 --Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?
 
 
with dates_cte as
(
select *, 
  DATEADD(DAY, 6, join_date) as valid_date, 
  EOMONTH('2021-01-31') as last_date
 from members as m
)
select d.customer_id, s.order_date, d.join_date, 
 d.valid_date, d.last_date, m.product_name, m.price,
 SUM(case
  when m.product_name = 'sushi' then 2 * 10 * m.price
  when s.order_date BETWEEN d.join_date AND d.valid_date then 2 * 10 * m.price
  else 10 * m.price
  end) as points
from dates_cte as d
join sales as s
 ON d.customer_id = s.customer_id
join menu as m
 on s.product_id = m.product_id
where s.order_date < d.last_date
group by d.customer_id, s.order_date, d.join_date, d.valid_date, d.last_date, m.product_name, m.price;