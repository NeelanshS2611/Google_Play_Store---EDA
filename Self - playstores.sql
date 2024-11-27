use google_play_store;

SELECT * from playstore;
select count(*) from playstore;

-- 1. As a market analyst for a mobile app developement company, identify most promising categories(Top 5) for launching new free apps based on their average ratings.
SELECT category from playstore
where type = 'Free'
group by category
order by avg(rating) desc
limit 5;

-- 2. Pinpoint the 3 categories that generates the most revenue from paid apps. (based on app price and its number of installations)

SELECT category , round(Avg(installs * price),2) as revenue from playstore
where type = 'Paid' 
group by category
order by revenue desc
LIMIT 3;

-- Alternate
select category, avg(revenue) as re from (SELECT category, (installs * price) as revenue from playstore
where type = 'Paid' ) as rev
group by category
order by re desc
LIMIT 3;

-- 3. calculate the percentage of apps within each category
select *, (cnt/(select count(*) from playstore))*100 as percentage from 
(SELECT category, count(app) as cnt from playstore group by category) e
order by percentage desc;

-- 4. Recommend whether the company should develope paid apps or free apps for each category based on ratings of that category

with t1 as 
(SELECT category , round(avg(rating),2) as free_rating from playstore Where type = 'Free' group by category),
t2 as (SELECT category , round(avg(rating),2) as paid_rating from playstore Where type = 'Paid' group by category)

select category, free_rating, paid_rating, 
(CASE WHEN free_rating > paid_rating then 'Free app' 
WHEN free_rating < paid_rating then 'Paid app' 
ELSE 'ANY' END) as recomendation from(
SELECT f.category, free_rating, paid_rating from t1 as f inner join t2 as p on f.category = p. category) as tvd;


-- 5. Suppose you're a database administrator your databases have been hacked and hackers are changing price of certain apps on the database, it is taking long for IT team to neutralize the hack, 
-- however you as a responsible manager don’t want your data to be changed, do some measure where the changes in price can be recorded as you can’t stop hackers from making changes.

create table price_change_tab (
app varchar(225),
old_price decimal(10,2),
new_price decimal(10,2),
operation_type varchar(225),
operation_date varchar(225))

select * from price_change_tab;

create table playstore3 AS select * from playstore;

SELECT * from playstore3;
drop trigger price_change_log

DELIMITER //
create trigger price_change_log
after update on playstore3
for each row 
begin 
	insert into price_change_tab(app, old_price, new_price, operation_type, operation_date)
    values(new.app, old.price, new.price, 'update',current_timestamp());
end;

// DELIMITER ;

set sql_safe_updates = 0;
update playstore3
set price = 40 where app = 'Infinite painter';

update playstore3
set price = 1050 where type = 'Paid' ;


select * from price_change_tab;


-- 6.	Your IT team have neutralized the threat; however, hackers have made some changes in the prices, but because of your measure you have noted the changes, 
-- now you want correct data to be inserted into the database again. (update + join)

select * from playstore3 as a inner join  price_change_tab b on a.app = b.app;-- step 1

drop trigger price_change_log; 

update playstore3 as a inner join  price_change_tab b on a.app = b.app
set a.price = b.old_price; -- update with join

-- 7. Find the correlation between two numeric factors: app ratings and the quantity of reviews.
-- correl = sum((x-x')*(y-y'))/ sqrt(sum((x-x')^2)*sum((y-y')^2))

set @x = (select round(avg(rating),2) from playstore);
set @y = (select round(avg(reviews),2) from playstore);

with t1 as
(select *, round(rat*rat,2) as sqrt_rat, round(riv*riv,2) as sqrt_riv from
(select rating, @x, round((rating - @x),2) as 'rat', reviews, @y, round((reviews-@y),2) as riv from playstore) t)

select @numerator := sum((rat*riv)), @deno_1 :=sum(sqrt_rat), @deno_2 :=sum(sqrt_riv) from t1;
select round((@numerator/sqrt(@deno_1*@deno_2)),2) as 'corelatoin';

-- 8. clean the genres column and make two genres out of it, rows that have only one genre will have other column as blank
DELIMITER //
CREATE function f_name (a varchar(200))
returns varchar(100)
deterministic
begin
	set @l = locate(';',a);
    set @s = if(@l>0,left(a,@l-1),a);
    
	return @s;
end
//DELIMITER

DELIMITER //

CREATE function l_name (a varchar(200))
returns varchar(100)
deterministic
begin 
	set @l = locate(';',a);
	set @s = if(@l=0,'',substring(a,@l+1,length(a)));customers

	return @s;
end
// DELIMITER ;

select genres, f_name(genres) as genres1, l_name(genres) as geners2 from playstore