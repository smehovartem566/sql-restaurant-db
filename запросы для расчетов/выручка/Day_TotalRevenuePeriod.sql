USE restaurant;
GO
DECLARE @StartDate DATE = '2025-04-10';
DECLARE @EndDate DATE = '2025-05-30';

-- Выручка за заданный период по дням
SELECT 
    CONVERT(VARCHAR, CAST(b.bill_date AS DATE), 104) AS Дата,
    COUNT(DISTINCT b.bill_id) AS 'Количество чеков',
    SUM(oi.quantity * d.price) AS 'Выручка за день',
    SUM(oi.quantity) AS 'Количество блюд',
    AVG(oi.quantity * d.price) AS 'Средний чек'
FROM 
    Bills b
JOIN 
    Orders o ON b.order_id = o.order_id
JOIN 
    BillDetails bd ON b.bill_id = bd.bill_id
JOIN 
    OrderItems oi ON bd.order_item_id = oi.order_item_id
JOIN 
    Dishes d ON oi.dish_id = d.dish_id
WHERE 
    CAST(b.bill_date AS DATE) BETWEEN @StartDate AND @EndDate
    AND b.payment_status = 2
GROUP BY 
    CAST(b.bill_date AS DATE)
ORDER BY 
    Дата;