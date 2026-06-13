-- Этап 1. Создание и заполнение БД

create schema if not exists raw_data; /*создаем схему, при условии, что ее нет*/

create table raw_data.sales( /*создаем таблицу в схеме и заливаем сырые данные*/
id INT PRIMARY KEY, /*задаем уникальность данных*/
auto VARCHAR,  /*строки переменной длины*/
gasoline_consumption DECIMAL,  /*число с заданной точностью, так как это расход автомобиля*/
price DECIMAL,  /*цена автомобиля тоже с заданной точностью*/
date DATE, /*дата без времени*/
person_name VARCHAR,
phone VARCHAR,
discout DECIMAL, /*дисконт с заданной точностью*/
brand_origin VARCHAR
);

\copy raw_data.sales FROM 'C:\Temp\cars.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL 'null'); 
/*через git bash заливаем данные в созданную таблицу*/

create schema if not exists car_shop; /*создаем схему car_shop где будет обрабатывать сырые данные*/


create table car_shop.countries (/*создаем таблицу стран-производителей авто*/
country_id SERIAL PRIMARY KEY, /*задаем уникальность*/
country_name VARCHAR(50) UNIQUE); /*строки переменной длины, максимум 50, уникальны*/


CREATE TABLE car_shop.brands (/*создаем таблицу брендов*/
  brand_id SERIAL PRIMARY KEY, /*задаем уникальность*/
  brand_name VARCHAR(50) UNIQUE NOT NULL, /*строки переменной длины, максимум 50, уникальны и не могут быть пустыми*/
  country_id INT REFERENCES car_shop.countries (country_id)/*данные берем из связи с таблицей countries по столбцу country_id*/
);

CREATE TABLE car_shop.models (/*создаем таблицу моделей автомобилей*/
  model_id SERIAL PRIMARY KEY, /*задаем уникальность*/
  model_name VARCHAR(50) NOT NULL,
  brand_id INT REFERENCES car_shop.brands (brand_id), /*данные берем из связи с таблицей brands по столбцу brand_id*/
  gasoline_consumption DECIMAL /*данные по расходу и цене авто указываем в формате чисел с заданной точностью*/
);

CREATE TABLE car_shop.colors ( /*создаем таблицу цветов авто*/
  color_id SERIAL PRIMARY KEY, /*задаем уникальность*/
  color_name VARCHAR(30) UNIQUE NOT NULL  /*цвет должен быть уникальным и не может быть пустым, максимально 30 символов*/
);

CREATE TABLE car_shop.customers ( /*создаем таблицу покупателей*/
  customer_id SERIAL PRIMARY KEY, /*задаем уникальность*/
  person_name VARCHAR(100) NOT NULL, /*фио покупателя, максимально 100 символов и не может быть пустым*/
  phone VARCHAR(50) NOT NULL /*телефон покупателя также пустым быть не может, максимально 50 символов*/
);

CREATE TABLE car_shop.sales (  /*создаем таблицу продаж*/
  sale_id SERIAL PRIMARY KEY, /*задаем уникальность*/
  model_id INT REFERENCES car_shop.models(model_id), /*данный столбец получаем из взаимосвязи с таблицей models*/
  color_id INT REFERENCES car_shop.colors(color_id), /*данный столбец получаем из взаимосвязи с таблицей colors*/
  customer_id INT REFERENCES car_shop.customers(customer_id), /*данные столбец получаем из взаимосвязи с таблицей customers*/
  price DECIMAL NOT NULL,
  sale_date DATE NOT NULL, /*дата продажи в формате даты без времени, пустой быть не может*/
  discount NUMERIC(10, 2) DEFAULT 0 /*число с заданной точностью, максимально 10 символов, 2 знака после запятой и по умолчанию задаем 0*/
);



-- Все таблицы созданы. Можно приступить к заполнению данных в таблицах.
INSERT INTO car_shop.countries (country_name) /*заполняем таблицу стран*/
SELECT DISTINCT brand_origin /*отсеиваем дубликаты*/
FROM raw_data.sales; /*схема и таблица, из которой берем сырые данные*/ 


INSERT INTO car_shop.brands (brand_name, country_id) /*заполняем таблицу брендов*/
SELECT DISTINCT /*отсеиваем дубликаты*/
    split_part(s.auto, ' ', 1), /*так как в сырых данных в поле auto сразу указаны марка, модель и номер авто, а нам нужно вычленить марку, используем split_part*/
    c.country_id 
FROM raw_data.sales s /*схема и таблица, из которой берем сырые данные*/
LEFT JOIN car_shop.countries c ON s.brand_origin=c.country_name;  /*объединяем с таблицей countries*/


INSERT INTO car_shop.models (model_name, brand_id, gasoline_consumption) /*заполняем таблицу моделей*/
SELECT DISTINCT /*отсеиваем дубликаты*/
    regexp_replace(s.auto, '^\S+\s+(.+?),\s*.*$', '\1'), /*так как в сырых данных в поле auto сразу указаны марка, модель и номер авто, а нам нужно вычленить модель, используем regexp_replace*/
    b.brand_id,
    s.gasoline_consumption
FROM raw_data.sales s
JOIN car_shop.brands b ON b.brand_name = split_part(s.auto, ' ', 1); 
    

INSERT INTO car_shop.colors (color_name) /*заполняем таблицу цветов*/
SELECT DISTINCT split_part(auto, ',', 2) /*отсеиваем дубликаты*/
/*применяем функцию split_part и берем вторую часть после запятой, где содержится цвет*/
FROM raw_data.sales; /*схема и таблица, из которой берем сырые данные*/


INSERT INTO car_shop.customers (person_name, phone) /*заполняем таблицу покупателей*/
SELECT DISTINCT person_name, phone /*отсеиваем дубликаты и тянем данные из таблицы raw_data.sales*/
FROM raw_data.sales;


INSERT INTO car_shop.sales (model_id, color_id, customer_id, price, sale_date, discount) /*заполняем таблицу продаж*/
SELECT
    m.model_id,  /*берем из таблицы models*/
    c.color_id, /*берем из таблицы colors*/
    cust.customer_id, /*покупателей берем из таблицы customers*/
    r.price,
    r.date, /*цену, дату и дисконты берем из таблицы raw_data.sales*/
    r.discount
FROM raw_data.sales r
JOIN car_shop.models m ON m.model_name = regexp_replace(r.auto, '^\S+\s+(.+?),\s*.*$', '\1')
JOIN car_shop.colors c ON c.color_name = split_part(r.auto, ',', 2)
JOIN car_shop.customers cust ON cust.phone = r.phone; 




-- Этап 2. Создание выборок

---- Задание 1. Напишите запрос, который выведет процент моделей машин, у которых нет параметра `gasoline_consumption`.
SELECT 
COUNT(CASE WHEN gasoline_consumption IS NULL THEN 1 END) * 100.0 / COUNT(*) AS null_gasoline_consumption 
FROM car_shop.models; /*указываем псевдоним, когда gasoline_consumption пустое, то присваиваем значение 1*/
/*далее нам нужно посчитать по формуле процент NULL от общего количества и вывести число в новой таблице*/


---- Задание 2. Напишите запрос, который покажет название бренда и среднюю цену его автомобилей в разбивке по всем годам с учётом скидки.
SELECT
b.brand_name,
EXTRACT(YEAR FROM s.sale_date) AS year, /*выделяем год в отдельную таблицу year*/
ROUND(AVG(s.price),2) AS price_avg /*функция AVG считает среднюю цену авто с учетом скидки*/
FROM car_shop.brands b /*объединяем таблицу brands с таблицами models, sales по общим полям*/
JOIN car_shop.models m ON b.brand_id = m.brand_id
JOIN car_shop.sales s ON m.model_id = s.model_id
GROUP BY b.brand_name, year /*группируем по имени и году, год в порядке возрастания*/
ORDER BY b.brand_name ASC, year ASC;


---- Задание 3. Посчитайте среднюю цену всех автомобилей с разбивкой по месяцам в 2022 году с учётом скидки.
SELECT
  EXTRACT(MONTH FROM sale_date) AS month, /*с помощью EXTRACT выделяем месяц и год в графе с датой продажи*/
  EXTRACT(YEAR FROM sale_date) AS year,
  ROUND(AVG(s.price),2) AS price_avg /*AVG считаем среднюю цену продажи с учетом скидки и ROUND округляем до двух знаков после запятой*/
FROM car_shop.sales
WHERE EXTRACT(YEAR FROM sale_date) = 2022 /*где указаны данные за 2022 год*/
GROUP BY month, year /*группируем по месяцу и году в алфавитном порядке*/
ORDER BY month ASC;


---- Задание 4. Напишите запрос, который выведет список купленных машин у каждого пользователя.
SELECT 
    c.person_name AS person, /*фио пользователя берем из таблицы customers*/
    STRING_AGG(b.brand_name || ' ' || m.model_name, ', ') AS cars /*объединяем имена брендов и модели после агрегации*/
FROM car_shop.customers c
JOIN car_shop.sales s ON c.customer_id = s.customer_id /*объединяем три таблицы по общим столбцам*/
JOIN car_shop.models m ON s.model_id = m.model_id
JOIN car_shop.brands b ON m.brand_id = b.brand_id 
GROUP BY c.person_name /*группируем по имени, в алфовитном порядке*/
ORDER BY c.person_name ASC;

---- Задание 5. Напишите запрос, который вернёт самую большую и самую маленькую цену продажи автомобиля с разбивкой по стране без учёта скидки. 
SELECT 
    co.country_name AS brand_origin, /*выбираем страну производства из таблицы brands*/
    MAX(CASE WHEN s.discount < 1 THEN s.price / (1 - s.discount) ELSE NULL END) AS price_max, /*выбираем max/min значение цены из таблицы cars*/
    MIN(CASE WHEN s.discount < 1 THEN s.price / (1 - s.discount) ELSE NULL END) AS price_min
FROM car_shop.sales s
JOIN car_shop.models m ON s.model_id = m.model_id
JOIN car_shop.brands b ON m.brand_id = b.brand_id
JOIN car_shop.countries co ON b.country_id = co.country_id 
GROUP BY co.country_name;  /*группируем по стране*/

---- Задание 6. Напишите запрос, который покажет количество всех пользователей из США.
SELECT COUNT(*) AS persons_from_usa /*выбрать всех пользователей из таблицы customers*/
FROM car_shop.customers  /*и дать название новое таблице*/
WHERE phone LIKE '+1%';  /*указать условие по номеру телефона*/



