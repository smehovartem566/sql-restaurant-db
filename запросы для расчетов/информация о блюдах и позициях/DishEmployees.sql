USE restaurant;
GO

-- Поиск поваров, готовивших конкретное блюдо
Declare @Dish nvarchar(MAX) = 'Куриный бульон с клецками'; -- Название блюда

SELECT
    d.dish_name AS 'Блюдо',
    CONCAT(e.first_name, ' ', e.last_name) AS 'Повар',
    e.rank AS 'Разряд',
    da.assignment_time AS 'Время начала приготовления',
    da.completion_time AS 'Время окончания',
    DATEDIFF(MINUTE, da.assignment_time, da.completion_time) AS 'Время приготовления (мин)',
    o.order_date AS 'Дата заказа',
    t.table_id AS 'Номер столика'
FROM
    DishAssignments da
JOIN
    OrderItems oi ON da.order_item_id = oi.order_item_id
JOIN
    Dishes d ON oi.dish_id = d.dish_id
JOIN 
    Employees e ON da.chef_id = e.employee_id
JOIN
    Orders o ON oi.order_id = o.order_id
JOIN
    Tables t ON o.table_id = t.table_id
WHERE
    d.dish_name = @Dish  
ORDER BY
    o.order_date DESC;