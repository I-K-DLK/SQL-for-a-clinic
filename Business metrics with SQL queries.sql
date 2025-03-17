 
/*
Напишем четыре SQL запроса для расчета следующих метрик. 
Будем учитывать повышенную вероятность коллизий по агрегатам различных метрик,
например, существует несколько услуг с одинаковой доходностью в промежутке времени.
*/


/*
1) какую сумму в среднем в месяц тратит:
- пациент в возрастном диапазоне от 18 до 25 лет включительно
- пациент в возрастном диапазоне от 26 до 35 лет включительно
*/
 
with cte as (

select sum(case when p.age between 18 and 25 then s.cost else null end) as first_monthly_cost, 
	sum(case when p.age between 26 and 35 then s.cost else null end) as second_monthly_cost, 
		concat(extract(month from  v.date),'/',extract(year from v.date)) as month
from clinic.patients p 
	inner join clinic.visits v using(patientid) 
	inner join clinic.services s using(serviceid) 
group by p.patientid, extract(year from  v.date), extract(month from v.date))
 
select round(avg(first_monthly_cost),2) as "Траты пациентов 18-25 лет", 
		round(avg(second_monthly_cost),2) as "Траты пациентов 26-35 лет" 
from cte;

/*
Траты пациентов 18-25 лет|Траты пациентов 26-35 лет|
-------------------------+-------------------------+
                  5288.80|                  5547.70|
*/
-- Или так  
		
with cte as (

select sum(s.cost) as monthly_cost, p.patientid as patient, p.age as age 
from clinic.patients p 
	inner join clinic.visits v using(patientid) 
	inner join clinic.services s using(serviceid) 
group by patient, extract(year from  v.date), extract(month from v.date))
 
select '18-25 лет' as "Возраст пациента" , round(avg(monthly_cost),2) as "Среднемесячные траты" from cte where age between 18 and 25 

union all 

select '26-35 лет' as "Возраст пациента", round(avg(monthly_cost),2) as "Среднемесячные траты" from cte where age between 26 and 35;
 
/*
Возраст пациента|Среднемесячные траты|
----------------+--------------------+
18-25 лет       |             5288.80|
26-35 лет       |             5547.70|
 */ 		


/*
2) Определим месяц года в котором доход от пациентов в возрастном диапазоне 35+ самый большой
*/
with cte as(
select round(sum(s.cost)) as total_income, extract(month from v.date) as month, extract(year from v.date) as year
from clinic.patients p 
	inner join clinic.visits v using(patientid) 
	inner join clinic.services s using(serviceid) 
where p.age >= 35
group by extract(month from v.date), extract(year from v.date)
order by total_income desc)
 
select to_char(to_date (cte.month::text, 'mm'), 'month') as "Месяц", cte.year as "Год" , cte.total_income as "Доход"
from cte 
	join (select max(total_income) as max_income, cte2.year from cte cte2 group by cte2.year) cte2 
		on cte.year = cte2.year and cte.total_income = cte2.max_income
order by Год desc;

/*
Месяц    |Год |Доход |
---------+----+------+
june     |2024|334722|
september|2023|303246|
august   |2022|325232|
december |2021|325359|
january  |2020|321759|
october  |2019|315333|
*/
/*
3) Определим какая услуга обеспечивает наибольший вклад в доход за последний год
*/

with cte as(

select round(sum(s.cost)) as total_income, s.serviceid as service, extract(year from v.date) as year
from clinic.visits v
	inner join clinic.services s using(serviceid) 
--where extract(year from v.date) =  extract(year from now()) если нужен текущий год
where v.date between now() - interval '1 year' and now() -- если нужны последние 365 дней 
group by s.serviceid, extract(year from v.date)
order by total_income desc)

select service as "Услуга", total_income as "Вклад в доход"  
from cte 
where total_income = (select max(total_income) from cte as cte_2);
 
/*
Услуга|Вклад в доход|
------+-------------+
    10|       154976|
*/


/*
4) Выведем ежегодные топ-5 услуг по доходу и их доли в общем доходе за год
*/
with t1 as(

select dense_rank() over(partition by extract(year from v.date) order by count(s.serviceid) * s.cost desc) as "Ранг", 
	s.serviceid as "Услуга", count(s.serviceid)*s.cost as "Доход" , extract(year from v.date) as "Год"
from clinic.visits v
	inner join clinic.services s using(serviceid)
group by Услуга, Год
order by Ранг asc),

t2 as(
select  sum(s2.cost) as "Годовой доход" , extract(year from v2.date) as "Год"
from clinic.visits v2
	inner join clinic.services s2 using(serviceid)
group by Год
order by "Годовой доход" desc)

select Услуга, Год, round(100 * Доход / "Годовой доход",2) as "Доля, %"  
from t1 join t2 using (Год) 
where Ранг <= 5 
order by Год desc,Ранг asc;
