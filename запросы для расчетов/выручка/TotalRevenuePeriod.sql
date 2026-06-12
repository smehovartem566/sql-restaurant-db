USE restaurant;
GO
DECLARE @StartDate DATE = '2025-05-01'; -- Начальная дата периода
DECLARE @EndDate DATE = '2025-05-30';   -- Конечная дата периода
-- Общая выручка за заданный период
SELECT
    CONVERT(VARCHAR, @StartDate, 104) + ' - ' + CONVERT(VARCHAR, @EndDate, 104) AS Период,
    COUNT(DISTINCT b.bill_id) AS 'Количество чеков',
    SUM(oi.quantity * d.price) AS 'Общая выручка',
    SUM(oi.quantity) AS 'Количество проданных блюд',
    Round(AVG(oi.quantity * d.price), 2) AS 'Средний чек'
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
    b.bill_date BETWEEN @StartDate AND @EndDate
    AND b.payment_status = 2; -- Только оплаченные чеки