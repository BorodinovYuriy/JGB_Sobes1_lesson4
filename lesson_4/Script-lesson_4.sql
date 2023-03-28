
CREATE TABLE films (
	id              int4 NOT NULL GENERATED ALWAYS AS IDENTITY,
	"name"          varchar NOT NULL,
	duration_min    int4 NOT NULL,
	CONSTRAINT films_pk PRIMARY KEY (id),
	CONSTRAINT films_un UNIQUE (id)
);

CREATE TABLE schedule (
	id              int4 NOT NULL GENERATED ALWAYS AS IDENTITY,
	id_film         int4 NOT NULL,
	start_time      timestamp NOT NULL,
	price           numeric(8, 2) NOT NULL,
	CONSTRAINT schedule_pk PRIMARY KEY (id),
	CONSTRAINT schedule_un UNIQUE (id),
	CONSTRAINT schedule_fk FOREIGN KEY (id_film) REFERENCES films(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE tickets (
	id              integer NOT NULL GENERATED ALWAYS AS IDENTITY,
	schedule_id     integer NOT NULL,
	CONSTRAINT tickets_pk PRIMARY KEY (id),
	CONSTRAINT tickets_un UNIQUE (id),
	CONSTRAINT tickets_fk FOREIGN KEY (schedule_id) REFERENCES cinema.schedule(id)
);


INSERT INTO films ("name",duration_min) VALUES
	 ('Человеческая многоножка',90),
	 ('Пробуждение жизни',90),
	 ('Даун Хаус',90),
	 ('Вход в пустоту',120),
	 ('Вечное сияние чистого разума',120),
	 ('Страна приливов',90);

INSERT INTO schedule (id_film, start_time, price) values
(1, '2023-01-01 20:00:00.000', 300.50),
(1, '2023-01-01 00:00:00.000', 100.50),
(1, '2023-01-01 08:00:00.000', 300.50),
(1, '2023-01-01 12:00:00.000', 100.50),
(2, '2023-01-01 10:00:00.000', 300.50),
(2, '2023-01-01 01:00:00.000', 100.50),
(2, '2023-01-02 10:00:00.000', 300.50),
(3, '2023-01-02 20:00:00.000', 100.50),
(3, '2023-01-01 19:00:00.000', 300.50),
(3, '2023-01-01 21:00:00.000', 100.50),
(4, '2023-01-01 18:00:00.000', 300.50),
(4, '2023-01-02 20:00:00.000', 100.50),
(4, '2023-01-02 22:00:00.000', 300.50),
(5, '2023-01-01 15:00:00.000', 100.50),
(5, '2023-01-02 16:00:00.000', 300.50),
(6, '2023-01-01 14:00:00.000', 100.50),
(6, '2023-01-01 17:00:00.000', 300.50);

INSERT INTO tickets (schedule_id) VALUES(1);
INSERT INTO tickets (schedule_id) VALUES(2);
INSERT INTO tickets (schedule_id) VALUES(2);
INSERT INTO tickets (schedule_id) VALUES(3);
INSERT INTO tickets (schedule_id) VALUES(4);
INSERT INTO tickets (schedule_id) VALUES(5);
INSERT INTO tickets (schedule_id) VALUES(5);
INSERT INTO tickets (schedule_id) VALUES(6);
INSERT INTO tickets (schedule_id) VALUES(10);
INSERT INTO tickets (schedule_id) VALUES(17);
INSERT INTO tickets (schedule_id) VALUES(16);
INSERT INTO tickets (schedule_id) VALUES(15);
INSERT INTO tickets (schedule_id) VALUES(15);
INSERT INTO tickets (schedule_id) VALUES(15);
INSERT INTO tickets (schedule_id) VALUES(12);
INSERT INTO tickets (schedule_id) VALUES(11);
INSERT INTO tickets (schedule_id) VALUES(11);
INSERT INTO tickets (schedule_id) VALUES(11);
INSERT INTO tickets (schedule_id) VALUES(11);
INSERT INTO tickets (schedule_id) VALUES(10);
INSERT INTO tickets (schedule_id) VALUES(6);
INSERT INTO tickets (schedule_id) VALUES(7);
INSERT INTO tickets (schedule_id) VALUES(7);
INSERT INTO tickets (schedule_id) VALUES(7);
INSERT INTO tickets (schedule_id) VALUES(6);
INSERT INTO tickets (schedule_id) VALUES(1);
INSERT INTO tickets (schedule_id) VALUES(1);

--Сделать запросы, считающие и выводящие в понятном виде:
--ошибки в расписании (фильмы накладываются друг на друга)
--Отсортированные по возрастанию времени. 
--колонки «фильм 1», «время начала», «длительность», «фильм 2», «время начала», «длительность»;
SELECT
    m1.name AS "фильм 1",
    s1.start_time AS "время начала",
    m1.duration_min AS "длительность",
    m2.name AS "фильм 2",
    s2.start_time AS "время начала",
    m2.duration_min AS "длительность"
FROM
    schedule s1
        JOIN films m1 ON s1.id_film = m1.id
        JOIN schedule s2 ON s1.start_time < s2.start_time AND (s1.start_time + INTERVAL '1 MINUTE' * m1.duration_min) > s2.start_time
        JOIN films m2 ON s2.id_film  = m2.id
WHERE
        s1.start_time <> s2.start_time
ORDER BY
    s1.start_time;

--Перерывы 30 минут и более между фильмами — выводить по уменьшению длительности перерыва. 
--Колонки «фильм 1», «время начала», «длительность», «время начала второго фильма», «длительность перерыва»;
   
--не работает(((
SELECT
    m1.name as "фильм 1",
    s1.start_time as "время начала",
    m1.duration_min as "длительность",
    s2.start_time as "время начала второго фильма",
    EXTRACT(EPOCH FROM (s2.start_time - (s1.start_time + INTERVAL '1 hour' * m1.duration_min)))/60 as "длительность перерыва (мин)"
FROM
    schedule s1
        JOIN
    films m1
    ON
            s1.id_film = m1.id
        JOIN
    schedule s2
    ON
                s1.start_time < s2.start_time
            AND s2.start_time - (s1.start_time + INTERVAL '1 hour' * m1.duration_min) >= INTERVAL '30 minutes'
    AND s1.id < s2.id
    AND s1.id = (SELECT MAX(id) FROM schedule WHERE id < s2.id)
ORDER BY
    "длительность перерыва (мин)" DESC;

--Список фильмов, для каждого — с указанием общего числа посетителей за все время, 
--среднего числа зрителей за сеанс и 
--общей суммы сборов по каждому фильму 
--(отсортировать по убыванию прибыли). 
--Внизу таблицы должна быть строчка «итого», содержащая данные по всем фильмам сразу;
SELECT
    m.name,
    COUNT(id) AS total_visitors,
    ROUND(AVG(visitors_per_schedule), 2) AS average_visitors_per_schedule,
    SUM(revenue) AS total_revenue
FROM films m
         JOIN (
    SELECT
        s.id_film,
        s.price * COUNT(t.id) AS revenue,
        COUNT(t.id) AS visitors_per_schedule
    FROM schedule s
             LEFT JOIN tickets t ON s.id = t.schedule_id
    GROUP BY s.id_film, s.id
) AS s ON m.id = s.id_film
GROUP BY m."name" 
ORDER BY total_revenue desc
;

--Какую общую сумму заработал кинотеатр за выбранный период
SELECT SUM(schedule.price) AS "Сумма заработка"
FROM schedule
JOIN tickets ON tickets.schedule_id  = schedule.id
WHERE schedule.start_time  BETWEEN '2023-01-01' AND '2023-01-02';
   
   
--число посетителей и кассовые сборы, сгруппированные по времени начала фильма: с 9 до 15, с 15 до 18, с 18 до 21, с 21 до 00:00 (сколько посетителей пришло с 9 до 15 часов и т.д.).
SELECT
    CASE
        WHEN start_time BETWEEN '2023-01-01 09:00:01.000' AND '2023-01-01 15:00:00.000' THEN 'с 9 до 15'
        WHEN start_time BETWEEN '2023-01-01 15:00:01.000' AND '2023-01-01 18:00:00.000' THEN 'с 15 до 18'
        WHEN start_time BETWEEN '2023-01-01 18:00:01.000' AND '2023-01-01 21:00:00.000' THEN 'с 18 до 21'
        WHEN start_time BETWEEN '2023-01-01 21:00:01.000' AND '2023-01-01 00:00:00.000' THEN 'с 21 до 00'
        WHEN start_time BETWEEN '2023-01-01 00:00:01.000' AND '2023-01-01 06:00:00.000' THEN 'с 00 до 06'
        ELSE 'неизвестный интервал'
        END AS interval,
  COUNT(DISTINCT t.id) AS visitors,
  SUM(s.price) AS revenue
FROM schedule s
    JOIN tickets t ON s.id = t.schedule_id 
GROUP BY interval;


--Кол-во проданных билетов
select films.name, count(tickets.id) as "Кол-во проданных билетов"
from films
join schedule on schedule.id_film = films.id
join tickets on tickets.schedule_id = schedule.id 
where schedule.start_time between '2023-01-01' and '2023-01-02'
group by films."name" ;

