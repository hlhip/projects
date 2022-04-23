/*All tables should be created in your WORK schema, unless otherwise noted*/

/*Set Time Zone*/
set time_zone = '-4:00';
select now();

/*Preliminary Data Collection
select * to investigate your tables.*/
select * from ba710case.ba710_prod;
select * from ba710case.ba710_sales;
select * from ba710case.ba710_emails;

/*Investigate production dates and prices from the prod table*/
select * from ba710case.ba710_prod
   where product_type = 'scooter'
   order by base_msrp;


/***PRELIMINARY ANALYSIS***/

/*Create a new table in WORK that is a subset of the prod table
which only contains scooters.
Result should have 7 records.*/
create table work.case_scoot_names as 
   select * from ba710case.ba710_prod
   where product_type = 'scooter';
   
select * from work.case_scoot_names;

/*Use a join to combine the table above with the sales information*/
create table work.case_scoot_sales as
   select a.model, a.product_type, a.product_id,
		  b.customer_id, b.sales_transaction_date, 
          date(b.sales_transaction_date) as sale_date,
          b.sales_amount, b.channel, b.dealership_id
   from work.case_scoot_names a
   inner join ba710case.ba710_sales b
   on a.product_id = b.product_id;
      
select * from work.case_scoot_sales;

/*Create a list partition for the case_scoot_sales table on product_id. (Hint: Alter table)  
Create one partition for each product_type.  Since there are two release dates for the
Lemon model, create a partition for Lemon_2010 and a partition for Lemon_2013.
Name each partition as the product's name.*/
alter table work.case_scoot_sales
	partition by list (product_id) (
		partition Lemon_2010 values in (1),
		partition Lemon_Limited_Edition values in (2),
		partition Lemon_2013 values in (3),
		partition Blade values in (5),
		partition Bat values in (7),
		partition Bat_Limited_Edition values in (8),
		partition Lemon_Zester values in (12)
    );


/***PART 1: INVESTIGATE BAT SALES TRENDS***/  

/*Select Bat models from your table.*/
select * from work.case_scoot_sales
	partition(Bat);

/*Count the number of Bat sales from your table.*/
select count(*) as number_of_bat_sales
	from work.case_scoot_sales
    partition(Bat);

/*What is the total revenue of Bat sales?*/
select round(sum(sales_amount), 2) as bat_sales_total_revenue
	from work.case_scoot_sales
    partition(Bat);

/*When was most recent Bat sale?*/
select max(sale_date) as most_recent_bat_sales
	from work.case_scoot_sales
    partition(Bat);

/*Summarize the number of sales (count) and sales total (sum of amount) by date
   for each product.
Create a table in your WORK schema that contains one record for each date & product id 
   combination.
Include model, product_id, sale_date, a column for count of sales, 
   and a column for sum of sales*/
create table work.case_scoot_sales_daily as
	select model, product_id, sale_date, count(*) as daily_sales_count, 
		round(sum(sales_amount), 2) as daily_sales
		from work.case_scoot_sales
		group by sale_date, product_id
		order by sale_date;

select * from work.case_scoot_sales_daily;


/***Bat Sales Analysis*********************************/

/*Now quantify the sales trends. Create columns for cumulative sales, total sales 
   for the past 7 days, and percentage increase in cumulative sales compared to 7 
   days prior using the following steps:*/

/*CUMULATIVE SALES
   Create a table that is a subset of the table above including all columns, 
   but only include Bat scooters.   Create a new column that contains the 
   cumulative sales amount (one row per date).
Hint: Window Functions, Over*/
create table work.case_bat_sales_analysis_1 as
	select *, round(sum(daily_sales) over(order by sale_date), 2) as cumulative_sales
		from work.case_scoot_sales_daily
		where product_id = 7;

select * from work.case_bat_sales_analysis_1;

/*SALES PAST 7 DAYS
   Add a column to the table created above (or create a new table with an additional
   column) that computes a running total of sales for the previous 7 days.
   (i.e., for each record the new column should contain the sum of sales for 
   the current date plus the sales for the preceeding 6 records).*/
create table work.case_bat_sales_analysis_2 as
	select *,  round(sum(daily_sales) over(order by sale_date  
		rows between 6 preceding and current row), 2) as cumu_sales_7_days
        from work.case_bat_sales_analysis_1;
        
select * from work.case_bat_sales_analysis_2;

/*GROWTH IN CUMULATIVE SALES OVER THE PAST WEEK
   Add a column to the table created above (or create a new table with an additional 
   column) that computes the cumulative sales growth in the past week as a percentage change
   of cumulative sales (current record) compared to the cumulative sales from the 
   same day of the previous week (seven records above).  
(Formula: (Current Cumulative Sales - Cumulative Sales 7 Days Ago) / Cumulative Sales 7 Days Ago
(Hint: Use the lag function.)*/
create table work.case_bat_sales_analysis_final as
	select *, round((cumulative_sales - lag(cumulative_sales, 7) over()) / 
		lag(cumulative_sales, 7) over() * 100, 2) as pct_weekly_increase_cumu_sales
        from work.case_bat_sales_analysis_2
        order by sale_date;
        
select * from work.case_bat_sales_analysis_final;

/*When Part 2 is released tomorrow, please include a screenshot of your results grid
   for your final Bat Sales Analysis Table*/

/*Question: On what date does the cumulative weekly sales growth drop below 10%?
Answer: The cumulative weekly sales growth drops below 10% on 2016-12-06, which was 9.93%.*/
select min(sale_date)
	from work.case_bat_sales_analysis_final
    where pct_weekly_increase_cumu_sales < 10;
    
/*Question: How many days since the launch date did it take for cumulative sales growth
to drop below 10%?
Answer: It took 57 days since the launch date for the cumulative sales growth to drop below 10%.*/
select datediff((select min(sale_date)
				from work.case_bat_sales_analysis_final
				where pct_weekly_increase_cumu_sales < 10),
		production_start_date) as number_of_days
	from work.case_scoot_names
    where product_id = 7;


/***Bat Limited Edition Sales Analysis*********************************/

/*Is the launch timing (October) a potential cause for the drop?
Replicate the Bat Sales Analysis for the Bat Limited Edition.
As above, complete the steps to calculate CUMULATIVE SALES, SALES PAST 7 DAYS,
and CUMULATIVE SALES GROWTH IN PAST WEEK*/
/*CUMULATIVE SALES (Bat Limited Edition)*/
create table work.case_batltd_sales_analysis_1 as
	select *, round(sum(daily_sales) over(order by sale_date), 2) as cumulative_sales
		from work.case_scoot_sales_daily
		where product_id = 8;

select * from work.case_batltd_sales_analysis_1;

/*SALES PAST 7 DAYS (Bat Limited Edition)*/
create table work.case_batltd_sales_analysis_2 as
	select *,  round(sum(daily_sales) over(order by sale_date  
		rows between 6 preceding and current row), 2) as cumu_sales_7_days
        from work.case_batltd_sales_analysis_1;
        
select * from work.case_batltd_sales_analysis_2;

/*GROWTH IN CUMULATIVE SALES OVER THE PAST WEEK (Bat Limited Edition)*/
create table work.case_batltd_sales_analysis_final as
	select *, round((cumulative_sales - lag(cumulative_sales, 7) over()) / 
		lag(cumulative_sales, 7) over() * 100, 2) as pct_weekly_increase_cumu_sales
        from work.case_batltd_sales_analysis_2
        order by sale_date;
        
select * from work.case_batltd_sales_analysis_final;

/*When Part 2 is released tomorrow, please include a screenshot of your results grid
   for your final Bat Limited Edition Sales Analysis Table*/

/*Question: On what date does the cumulative weekly sales growth drop below 10%?
Answer: The cumulative weekly sales growth drops below 10% on 2017-04-29, which was 8.38%.*/   
select min(sale_date)
	from work.case_batltd_sales_analysis_final
    where pct_weekly_increase_cumu_sales < 10;

/*Question: How many days since the launch date did it take for cumulative sales growth
to drop below 10%?
Answer: It took 73 days since the launch date for the cumulative sales growth to drop below 10%.*/                               
select datediff((select min(sale_date)
				from work.case_batltd_sales_analysis_final
				where pct_weekly_increase_cumu_sales < 10),
		production_start_date) as number_of_days
	from work.case_scoot_names
	where product_id = 8;

/*Question: Is there a difference in the behavior in cumulative sales growth
between the Bat edition and either the Bat Limited edition? (Make a statement comparing
the growth statistics.)
Answer: When comparing the cumulative sales growth on the second week since the launch date of both editions, 
Bat edition was 1.54 times higher than Bat Limited edition. However, for the cumulative sales growth to drop below 10%, 
Bat Limited edition took longer duration, which was 73 days in comparison to Bat edition, which was 57 days. 
Despite the higher overall units sold, Bat edition’s cumulative sales growth dropped below 10% earlier than Bat Limited edition. 
This could due to the lower selling price per unit for Bat edition, which was $100 lesser than Bat Limited edition.*/


/***Lemon 2013 Sales Analysis*********************************/
/*The Bat Limited was at a higher price point than the Bat.
Let's take a look at the 2013 Lemon model, since it's also a similar price point.  
Replicate the Bat Sales Analysis for the 2013 Lemon scooter.
As above, complete the steps to calculate CUMULATIVE SALES, SALES PAST 7 DAYS,
and CUMULATIVE SALES GROWTH IN PAST WEEK*/
/*CUMULATIVE SALES (Lemon 2013)*/
create table work.case_lemon2013_sales_analysis_1 as
	select *, round(sum(daily_sales) over(order by sale_date), 2) as cumulative_sales
		from work.case_scoot_sales_daily
		where product_id = 3;

select * from work.case_lemon2013_sales_analysis_1;

/*SALES PAST 7 DAYS (Lemon 2013)*/
create table work.case_lemon2013_sales_analysis_2 as
	select *,  round(sum(daily_sales) over(order by sale_date  
		rows between 6 preceding and current row), 2) as cumu_sales_7_days
        from work.case_lemon2013_sales_analysis_1;
        
select * from work.case_lemon2013_sales_analysis_2;

/*GROWTH IN CUMULATIVE SALES OVER THE PAST WEEK (Lemon 2013)*/
create table work.case_lemon2013_sales_analysis_final as
	select *, round((cumulative_sales - lag(cumulative_sales, 7) over()) / 
		lag(cumulative_sales, 7) over() * 100, 2) as pct_weekly_increase_cumu_sales
        from work.case_lemon2013_sales_analysis_2
        order by sale_date;
        
select * from work.case_lemon2013_sales_analysis_final;

/*When Part 2 is released tomorrow, please include a screenshot of your results grid
   for your final 2013 Lemon Sales Analysis Table*/

/*Question: On what date does the cumulative weekly sales growth drop below 10%?
Answer: The cumulative weekly sales growth drops below 10% on 2013-07-01, which was 9.3%.*/   
select min(sale_date)
	from work.case_lemon2013_sales_analysis_final
    where pct_weekly_increase_cumu_sales < 10;

/*Question: How many days since the launch date did it take for cumulative sales growth
to drop below 10%?
Answer: It took 61 days since the launch date for the cumulative sales growth to drop below 10%.*/                               
select datediff((select min(sale_date)
				from work.case_lemon2013_sales_analysis_final
				where pct_weekly_increase_cumu_sales < 10),
		production_start_date) as number_of_days
	from work.case_scoot_names
	where product_id = 3;

/*Question: Is there a difference in the behavior in cumulative sales growth
between the Bat edition and the 2013 Lemon edition?  (Make a statement comparing
the growth statistics.)
Answer: When comparing the cumulative sales growth on the second week since the launch date of both editions, 
2013 Lemon edition was 1.33 times higher than Bat edition. Meanwhile, for the cumulative sales growth to drop below 10%, 
2013 Lemon edition took slightly more days, which was 61 days in comparison to Bat edition, which was 57 days. 
This could due to the lower selling price per unit for 2013 Lemon edition, which was $100 lesser than Bat edition that 
attract more customers.*/


/***PART 2: MARKETING ANALYSIS***/

/*General Email & Sales Prep*/

/*Create a table called WORK.CASE_SALES_EMAIL that contains all of the email data
as well as both the sales_transaction_date and the product_id from sales.
Please use the WORK.CASE_SCOOT_SALES table to capture the sales information.*/
create table work.case_sales_email as
	select a.sales_transaction_date, a.product_id, b.*
		from work.case_scoot_sales a
		inner join ba710case.ba710_emails b
		on a.customer_id = b.customer_id;
        
select * from work.case_sales_email;
   
/*Create two separate indexes for product_id and sent_date on the newly created
   WORK.CASE_SALES_EMAIL table.*/
create index idx_product_id on work.case_sales_email (product_id);
create index idx_sent_date on work.case_sales_email (sent_date);


/***Product email analysis****/
/*Bat emails 30 days prior to purchase
   Create a view of the previous table that:
   - contains only emails for the Bat scooter
   - contains only emails sent 30 days prior to the purchase date*/
create view work.case_bat_sales_email as
	select * from work.case_sales_email
		where product_id = 7 and 
		sent_date < sales_transaction_date and
		datediff(sales_transaction_date, sent_date) <= 30;

select * from work.case_bat_sales_email;

/*Filter emails*/
/*There appear to be a number of general promotional emails not 
specifically related to the Bat scooter.  Create a new view from the 
view created above that removes emails that have the following text
in their subject.

Remove emails containing:
Black Friday
25% off all EVs
It's a Christmas Miracle!
A New Year, And Some New EVs*/
create view work.case_bat_sales_email_new as
	select * from work.case_bat_sales_email
		where email_subject not like '%Black Friday%' and
		email_subject not like '%25% off all EVs%' and
		email_subject not like '%It''s a Christmas Miracle!%' and
		email_subject not like '%A New Year, And Some New EVs%';

select * from work.case_bat_sales_email_new;

/*Question: How many rows are left in the relevant emails view.*/
/*Code:*/
select count(*) as total_email
	from work.case_bat_sales_email_new;
/*Answer: 407*/

/*Question: How many emails were opened (opened='t')?*/
/*Code:*/
select count(*) as total_email_opened
	from work.case_bat_sales_email_new
	where opened = 't';
/*Answer: 100*/

/*Question: What percentage of relevant emails (the view above) are opened?*/
/*Code:*/
select round((select count(*) from work.case_bat_sales_email_new
		where opened = 't') / count(*) * 100, 2) as total_email_opened_perc
	from work.case_bat_sales_email_new;
/*Answer: 24.57%*/ 


/***Purchase email analysis***/
/*Question: How many distinct customers made a purchase (CASE_SCOOT_SALES)?*/
/*Code:*/
select count(distinct(customer_id)) as total_cust
	from work.case_scoot_sales
    where product_id = 7;
/*Answer: 6659*/

/*Question: What is the percentage of distinct customers made a purchase after 
    receiving an email?*/
/*Code:*/
select round((select count(distinct(customer_id)) from work.case_bat_sales_email_new
		where sent_date < sales_transaction_date and bounced = 'f') / 
        count(distinct(customer_id)) * 100, 2) as total_cust_pur_rec_email_perc
	from work.case_scoot_sales
    where product_id = 7;
/*Answer: 6.01%*/
        
/*Question: What is the percentage of distinct customers that made a purchase 
    after opening an email?*/
/*Code:*/
select round((select count(distinct(customer_id)) from work.case_bat_sales_email_new
		where sent_date < sales_transaction_date and opened = 't') / 
        count(distinct(customer_id)) * 100, 2) as total_cust_pur_open_email_perc
	from work.case_scoot_sales
    where product_id = 7;
/*Answer: 1.5%*/


/*****LEMON 2013*****/
/*Complete a comparitive analysis for the Lemon 2013 scooter.  
Irrelevant/general subjects are:
25% off all EVs
Like a Bat out of Heaven
Save the Planet
An Electric Car
We cut you a deal
Black Friday. Green Cars.
Zoom 
 
/***Product email analysis****/
/*Lemon emails 30 days prior to purchase
   Create a view that:
   - contains only emails for the Lemon 2013 scooter
   - contains only emails sent 30 days prior to the purchase date*/
create view work.case_lemon2013_sales_email as
	select * from work.case_sales_email
		where product_id = 3 and 
		sent_date < sales_transaction_date and
		datediff(sales_transaction_date, sent_date) <= 30;
        
select * from work.case_lemon2013_sales_email;

/*Filter emails*/
/*There appear to be a number of general promotional emails not 
specifically related to the Lemon scooter.  Create a new view from the 
view created above that removes emails that have the following text
in their subject.

Remove emails containing:
25% off all EVs
Like a Bat out of Heaven
Save the Planet
An Electric Car
We cut you a deal
Black Friday. Green Cars.
Zoom */
create view work.case_lemon2013_sales_email_new as
	select * from work.case_lemon2013_sales_email
		where email_subject not like '%25% off all EVs%' and
		email_subject not like '%Like a Bat out of Heaven%' and
		email_subject not like '%Save the Planet%' and
		email_subject not like '%An Electric Car%' and
        email_subject not like '%We cut you a deal%' and
        email_subject not like '%Black Friday. Green Cars.%' and
        email_subject not like '%Zoom%';
        
select * from work.case_lemon2013_sales_email_new;

/*Question: How many rows are left in the relevant emails view.*/
/*Code:*/
select count(*) as total_email
	from work.case_lemon2013_sales_email_new;
/*Answer: 514*/

/*Question: How many emails were opened (opened='t')?*/
/*Code:*/
select count(*) as total_email_opened
	from work.case_lemon2013_sales_email_new
	where opened = 't';
/*Answer: 129*/

/*Question: What percentage of relevant emails (the view above) are opened?*/
/*Code:*/
select round((select count(*) from work.case_lemon2013_sales_email_new
		where opened = 't') / count(*) * 100, 2) as total_email_opened_perc
	from work.case_lemon2013_sales_email_new; 
/*Answer: 25.1%*/


/***Purchase email analysis***/
/*Question: How many distinct customers made a purchase (CASE_SCOOT_SALES)?*/
/*Code:*/
select count(distinct(customer_id)) as total_cust
	from work.case_scoot_sales
    where product_id = 3;
/*Answer: 13854*/

/*Question: What is the percentage of distinct customers made a purchase after 
    receiving an email?*/
/*Code:*/
select round((select count(distinct(customer_id)) from work.case_lemon2013_sales_email_new
		where sent_date < sales_transaction_date and bounced = 'f') / 
        count(distinct(customer_id)) * 100, 2) as total_cust_pur_rec_email_perc
	from work.case_scoot_sales
    where product_id = 3;
/*Answer: 3.66%*/

/*Question: What is the percentage of distinct customers that made a purchase 
    after opening an email?*/
/*Code:*/
select round((select count(distinct(customer_id)) from work.case_lemon2013_sales_email_new
		where sent_date < sales_transaction_date and opened = 't') / 
        count(distinct(customer_id)) * 100, 2) as total_cust_pur_open_email_perc
	from work.case_scoot_sales
    where product_id = 3;
/*Answer: 0.92%*/