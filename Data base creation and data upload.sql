/*
Создадим прототип SQL базы данных с таблицами международной частной клиники, которая существует много лет:

1) Patients(patientId, age)
2) Visits(visitId, patientId, serviceId, date)
3) Services(serviceId, cost)
*/
 
-- создадим новую схему clinic

create schema clinic; 

-- создадим таблицы patients, visits и services
 
-- 1) patients

drop table if exists clinic.patients;
 
create table clinic.patients(
patientId int primary key,
age int
);

-- 2) visits

drop table if exists clinic.visits;
 
create table clinic.visits(
visitId int primary key,
patientId int references clinic.patients(patientid),
serviceId int,
date date
);
 
-- 3) services

drop table if exists clinic.services;
 
create table clinic.services(
serviceId int primary key,
cost decimal
);
  

-- Загрузим данные в тaблицы  
-- Создадим 1000 пациентов 
-- Зададим возраст пациентов от 20 до 80 лет

insert into clinic.patients values(

generate_series(1,1000), floor(random()*(80-20+1))+20);


-- Загрузим в каталог услуг 50 различных id c ценами от 500 до 10000

insert into clinic.services values(

generate_series(1,50), floor(random()*(10000-500+1))+500);


-- Загрузим в таблицу данные о 4000 посещений за последние 5 лет (c 1 октября 2019)
 
insert into clinic.visits values(
generate_series(1,4000), floor(random()*(1000))+1, floor(random()*(50))+1, (timestamp '2019-10-01' + random() * (now() -
                   timestamp '2019-10-01'))::date);
 
 
-- Проверим корректность загрузки данных

select * from clinic.patients limit 10;
/*
patientid|age|
---------+---+
        1| 75|
        2| 43|
        3| 33|
        4| 62|
        5| 30|
        6| 79|
        7| 33|
        8| 37|
        9| 39|
       10| 20|
*/

select * from clinic.services limit 10;
/*
serviceid|cost|
---------+----+
        1|4507|
        2|4118|
        3|3911|
        4|8336|
        5|8687|
        6|3619|
        7|1532|
        8|6158|
        9|5915|
       10|9686| 
*/

select * from clinic.visits limit 10;

/*
visitid|patientid|serviceid|date      |
-------+---------+---------+----------+
      1|      349|       44|2024-09-07|
      2|       53|       47|2019-10-09|
      3|       98|        2|2022-06-09|
      4|      911|       42|2023-08-08|
      5|      659|       17|2020-12-31|
      6|      116|       22|2023-08-28|
      7|      912|       30|2022-04-18|
      8|      323|       31|2021-10-27|
      9|      938|       23|2023-08-06|
     10|      177|       31|2024-06-19| 
*/
 
 
