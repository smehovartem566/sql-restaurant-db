USE restaurant;
GO

DECLARE @TableNumber INT = 3; -- Номер столика для поиска
DECLARE @OrderStatus INT = 2; -- Статус заказа (2-Завершен)

-- Информации о заказах у столика
SELECT
    o.order_id AS 'ID заказа',
    t.table_id AS 'Номер столика',
    CONCAT(c.first_name, ' ', c.last_name) AS 'Клиент',
    o.order_date AS 'Дата и время заказа',
    d.dish_name AS 'Блюдо',
    oi.quantity AS 'Количество',
    d.price AS 'Цена за единицу',
    (d.price * oi.quantity) AS 'Сумма',
    oi.special_requests AS 'Особые пожелания',
    CONCAT(e.first_name, ' ', e.last_name) AS 'Официант',
    os.name AS 'Статус заказа'
FROM 
    Orders o
JOIN 
    Tables t ON o.table_id = t.table_id
JOIN 
    Clients c ON o.client_id = c.client_id
JOIN
    OrderItems oi ON o.order_id = oi.order_id
JOIN 
    Dishes d ON oi.dish_id = d.dish_id
JOIN
    Employees e ON o.employee_id = e.employee_id
JOIN
    OrderStatuses os ON o.status = os.id
WHERE
    t.table_id = @TableNumber
    AND o.status = @OrderStatus
ORDER BY 
    o.order_date DESC;