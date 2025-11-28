-- ФІНАЛЬНИЙ ПРОЄКТ

-- ЗАВДАННЯ 1. Створення бази та завантаження даних

CREATE DATABASE IF NOT EXISTS pandemic;
USE pandemic;

-- Дані CSV імпортуються вручну:
-- Правий клік на схемі "pandemic" → Table Data Import Wizard
-- Назва таблиці після імпорту: infectious_cases

-- ЗАВДАННЯ 2. Нормалізація таблиці до 3НФ

-- 1) Створення довідника сутностей (Entity + Code)
DROP TABLE IF EXISTS entities;

CREATE TABLE entities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entity_name VARCHAR(255) NOT NULL,
    entity_code VARCHAR(50)
);

-- 2) Заповнення довідника унікальними значеннями
INSERT INTO entities (entity_name, entity_code)
SELECT DISTINCT Entity, Code
FROM infectious_cases;

-- 3) Створення нормалізованої факт-таблиці
DROP TABLE IF EXISTS infectious_facts;

CREATE TABLE infectious_facts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entity_id INT NOT NULL,
    year INT,
    number_rabies DECIMAL(15,6),
    number_malaria DECIMAL(15,6),
    number_smallpox DECIMAL(15,6),
    CONSTRAINT fk_facts_entity FOREIGN KEY (entity_id) REFERENCES entities(id)
);

-- 4) Перенесення даних із сирої таблиці у нормалізовану

INSERT INTO infectious_facts (
    entity_id,
    year,
    number_rabies,
    number_malaria,
    number_smallpox
)
SELECT
    e.id,
    ic.Year,
    CAST(NULLIF(ic.Number_rabies,  '') AS DECIMAL(15,6)),
    CAST(NULLIF(ic.Number_malaria, '') AS DECIMAL(15,6)),
    CAST(NULLIF(ic.Number_smallpox,'') AS DECIMAL(15,6))
FROM infectious_cases AS ic
JOIN entities AS e
  ON ic.Entity = e.entity_name
 AND ic.Code   = e.entity_code;

-- Перевірка кількості завантажених рядків (вимога ментора)
SELECT COUNT(*) AS total_loaded_rows FROM infectious_cases;
SELECT COUNT(*) AS total_normalized_rows FROM infectious_facts;

-- ЗАВДАННЯ 3. Аналіз Number_rabies

SELECT 
    e.entity_name,
    e.entity_code,
    AVG(f.number_rabies) AS avg_rabies,
    MIN(f.number_rabies) AS min_rabies,
    MAX(f.number_rabies) AS max_rabies,
    SUM(f.number_rabies) AS sum_rabies
FROM infectious_facts AS f
JOIN entities AS e
    ON f.entity_id = e.id
WHERE f.number_rabies IS NOT NULL
GROUP BY e.entity_name, e.entity_code
ORDER BY avg_rabies DESC
LIMIT 10;

-- ЗАВДАННЯ 4. Побудова колонки «різниця в роках»

SELECT
    year,
    DATE(CONCAT(year, '-01-01')) AS year_start_date,
    CURDATE() AS today_date,
    TIMESTAMPDIFF(
        YEAR,
        DATE(CONCAT(year, '-01-01')),
        CURDATE()
    ) AS years_difference
FROM infectious_facts
LIMIT 20;

-- ЗАВДАННЯ 5. Створення власної SQL-функції

DROP FUNCTION IF EXISTS years_since;

DELIMITER $$

CREATE FUNCTION years_since(year_input INT)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(
        YEAR,
        DATE(CONCAT(year_input, '-01-01')),
        CURDATE()
    );
END$$

DELIMITER ;

-- Використання функції на даних
SELECT
    year,
    years_since(year) AS years_passed
FROM infectious_facts
LIMIT 20;
