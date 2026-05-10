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

CREATE TABLE car_shop.brands ( /*создаем таблицу брендов, с наименованием и страной производства бренда*/
  brand_id SERIAL PRIMARY KEY, /*задаем уникальность*/
  brand_name VARCHAR(50) UNIQUE NOT NULL, /*строки переменной длины, максимум 50, уникальны и не могут быть пустыми*/
  origin VARCHAR(50) /*строки переменной длины, максимум 50*/
);

CREATE TABLE car_shop.cars ( /*создаем таблицу автомобилей, где будет указан brand_id, модель и марка автомобиля, расход авто и прайс*/
  car_id SERIAL PRIMARY KEY, /*задаем уникальность*/
  brand_id INT REFERENCES car_shop.brands(brand_id), /*данные берем из связи с таблицей brands по столбцу brand_id*/
  gasoline_consumption DECIMAL, /*данные по расходу и цене авто указываем в формате чисел с заданной точностью*/
  price DECIMAL NOT NULL
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
  car_id INT REFERENCES car_shop.cars(car_id), /*данный столбец получаем из взаимосвязи с таблицей cars, задаем формат INT целые числа*/
  customer_id INT REFERENCES car_shop.customers(customer_id), /*данные столбец получаем из взаимосвязи с таблицей customers*/
  sale_date DATE NOT NULL, /*дата продажи в формате даты без времени, пустой быть не может*/
  discount NUMERIC(10, 2) DEFAULT 0 /*число с заданной точностью, максимально 10 символов, 2 знака после запятой и по умолчанию задаем 0*/
);

CREATE TABLE car_shop.car_colors (  /*создаем таблицу взаимосвязи цвета и автомобиля*/
  car_id INT REFERENCES car_shop.cars(car_id) ON DELETE CASCADE, /*задаем формат целых числел и берем данные из таблицы cars по полю car_id*/
  color_id INT REFERENCES car_shop.colors(color_id) ON DELETE CASCADE, /*задаем формат целых числел и берем данные из таблицы colors по полю color_id*/
  PRIMARY KEY (car_id, color_id) /*оба значения уникальны*/
); /*Добавлено ON DELETE CASCADE. Если машина или цвет удаляются, записи в этой таблице исчезают автоматически.*/




-- Все таблицы созданы. Можно приступить к заполнению данных в таблицах.
INSERT INTO car_shop.brands (brand_name, origin) /*заполняем таблицу брендов*/
SELECT DISTINCT /*отсеиваем дубликаты*/
    split_part(auto, ',', 1) as brand_name, /*так как в сырых данных в поле auto сразу указаны марка, модель и номер авто, а нам нужно вычленить марку и модель, используем split_part*/
    brand_origin as origin 
FROM raw_data.sales;  /*схема и таблица, из которой берем сырые данные*/


INSERT INTO car_shop.colors (color_name) /*заполняем таблицу цветов*/
SELECT DISTINCT split_part(auto, ',', 2) /*отсеиваем дубликаты*/
/*применяем функцию split_part и берем вторую часть после запятой, где содержится цвет*/
FROM raw_data.sales; /*схема и таблица, из которой берем сырые данные*/


INSERT INTO car_shop.cars (brand_id, gasoline_consumption, price) /*заполняем таблицу автомобилей*/
SELECT DISTINCT /*отсеиваем дубликаты*/
    b.brand_id, 
    s.gasoline_consumption,
    s.price
FROM raw_data.sales s /*схема и таблица, из которой берем сырые данные*/
JOIN car_shop.brands b ON b.brand_name = split_part(s.auto, ',', 1); 
/*объедиянем raw_data.sales с таблицей car_shop.brands по полю brand_name и первой части столбца auto, где содержатся марка и модель авто*/


INSERT INTO car_shop.customers (person_name, phone) /*заполняем таблицу покупателей*/
SELECT DISTINCT person_name, phone /*отсеиваем дубликаты и тянем данные из таблицы raw_data.sales*/
FROM raw_data.sales;


INSERT INTO car_shop.sales (car_id, customer_id, sale_date, discount) /*заполняем таблицу продаж*/
SELECT
    c.car_id, 
    cust.customer_id, /*покупателей берем из таблицы customers*/
    r.date, /*дату и дисконты берем из таблицы raw_data.sales*/
    r.discount
FROM raw_data.sales r
JOIN car_shop.customers cust ON r.person_name = cust.person_name /*объединяем таблицу raw_data.sales и car_shop.customers по полю person_name*/
JOIN car_shop.cars c ON r.price = c.price; /*объединяем таблицу raw_data.sales и car_shop.cars по полю price*/


INSERT INTO car_shop.car_colors (car_id, color_id) /*заполняем таблицу взаимосвязи цвета и авто*/
SELECT
    c.car_id,
    col.color_id
FROM raw_data.sales r /*схема и таблица, из которой берем сырые данные*/
JOIN car_shop.colors col ON split_part(r.auto, ',', 2) = col.color_name /*объединяем таблицу raw_data.sales и car_shop.colors по полю auto, взяв вторую часть после запятой, где содержится цвет авто*/
JOIN car_shop.cars c ON r.price = c.price; /*объединяем таблицу raw_data.sales и car_shop.cars по полю price*/



-- Этап 2. Создание выборок

---- Задание 1. Напишите запрос, который выведет процент моделей машин, у которых нет параметра `gasoline_consumption`.
SELECT 
COUNT(CASE WHEN gasoline_consumption IS NULL THEN 1 END) * 100.0 / COUNT(*) AS null_gasoline_consumption 
FROM car_shop.cars; /*указываем псевдоним, когда gasoline_consumption пустое, то присваиваем значение 1*/
/*далее нам нужно посчитать по формуле процент NULL от общего количества и вывести число в новой таблице*/


---- Задание 2. Напишите запрос, который покажет название бренда и среднюю цену его автомобилей в разбивке по всем годам с учётом скидки.
SELECT
b.brand_name,
EXTRACT(YEAR FROM s.sale_date) AS year, /*выделяем год в отдельную таблицу year*/
ROUND(AVG(c.price * (1 - s.discount / 100.0)), 2) AS price_avg /*функция AVG считает среднюю цену авто с учетом скидки*/
FROM car_shop.brands b /*объединяем таблицу brands с таблицами cars, sales по общим полям*/
JOIN car_shop.cars c ON b.brand_id = c.brand_id
JOIN car_shop.sales s ON c.car_id = s.car_id
GROUP BY b.brand_name, year /*группируем по имени и году, год в порядке возрастания*/
ORDER BY b.brand_name ASC, year ASC;


---- Задание 3. Посчитайте среднюю цену всех автомобилей с разбивкой по месяцам в 2022 году с учётом скидки.
SELECT
  EXTRACT(MONTH FROM s.sale_date) AS month, /*с помощью EXTRACT выделяем месяц и год в графе с датой продажи*/
  EXTRACT(YEAR FROM s.sale_date) AS year,
  ROUND(AVG(c.price * (1 - s.discount / 100.0)), 2) AS price_avg /*AVG считаем среднюю цену продажи с учетом скидки и ROUND округляем до двух знаков после запятой*/
FROM car_shop.sales s
JOIN car_shop.cars c ON s.car_id = c.car_id /*объединяем таблицы sales и cars по полю car_id*/
WHERE EXTRACT(YEAR FROM s.sale_date) = 2022 /*где указаны данные за 2022 год*/
GROUP BY month, year /*группируем по месяцу и году в алфавитном порядке*/
ORDER BY month ASC;


---- Задание 4. Напишите запрос, который выведет список купленных машин у каждого пользователя.
SELECT 
    c.person_name AS person, /*фио пользователя берем из таблицы customers*/
    STRING_AGG(b.brand_name, ', ') AS cars /*объединяем имена брендов через запятую после агрегации*/
FROM car_shop.customers c
JOIN car_shop.sales s ON c.customer_id = s.customer_id /*объединяем три таблицы по общим столбцам*/
JOIN car_shop.cars ca ON s.car_id = ca.car_id
JOIN car_shop.brands b ON ca.brand_id = b.brand_id 
GROUP BY c.person_name /*группируем по имени, в алфовитном порядке*/
ORDER BY c.person_name ASC;

---- Задание 5. Напишите запрос, который вернёт самую большую и самую маленькую цену продажи автомобиля с разбивкой по стране без учёта скидки. 
SELECT 
    b.origin AS brand_origin, /*выбираем страну производства из таблицы brands*/
    MAX(c.price) AS price_max, /*выбираем max/min значение цены из таблицы cars*/
    MIN(c.price) AS price_min
FROM car_shop.brands b
JOIN car_shop.cars c ON b.brand_id = c.brand_id /*объединяем таблицы brands и cars по общему полю brand_id*/
GROUP BY b.origin;  /*группируем по стране*/

---- Задание 6. Напишите запрос, который покажет количество всех пользователей из США.
SELECT COUNT(*) AS persons_from_usa /*выбрать всех пользователей из таблицы customers*/
FROM car_shop.customers  /*и дать название новое таблице*/
WHERE phone LIKE '+1%';  /*указать условие по номеру телефона*/



