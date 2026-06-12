USE restaurant;
GO

DECLARE @Dishes INT = 50; -- Количество блюд для премии
DECLARE @Bonus DECIMAL(3,2) = 1.1; -- На сколько умножить оклад 

-- Кол-во блюд на каждый день каждого повара и калькулятор премии
WITH ChefDailyStats AS (
    SELECT
        e.employee_id,
        CONCAT(e.first_name, ' ', e.last_name) AS chef_name,
        e.salary AS base_salary,
        SUM(oi.quantity) AS dishes_prepared,
        CONVERT(DATE, da.completion_time) AS work_date
    FROM
        DishAssignments da
    JOIN 
        Employees e ON da.chef_id = e.employee_id
    JOIN 
        OrderItems oi ON da.order_item_id = oi.order_item_id
    WHERE 
        e.position != 1 AND e.position != 3
        AND da.completion_time IS NOT NULL
    GROUP BY 
        e.employee_id,
        e.first_name,
        e.last_name,
        e.salary,
        CONVERT(DATE, da.completion_time)
		)
SELECT
    employee_id AS 'ID повара',
    chef_name AS 'Повар',
    base_salary AS 'Оклад',
    dishes_prepared AS 'Приготовлено блюд',
    work_date AS 'Дата',
    CASE
        WHEN dishes_prepared > @Dishes THEN base_salary * @Bonus
        ELSE base_salary
    END AS 'Зарплата с премией',
    CASE 
        WHEN dishes_prepared > @Dishes THEN 'Да'
        ELSE 'Нет'
    END AS 'Премия начислена'
FROM 
    ChefDailyStats
ORDER BY 
    work_date DESC,
    dishes_prepared DESC;