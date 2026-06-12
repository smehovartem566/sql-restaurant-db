USE restaurant;
GO

DECLARE @StartDate DATE = '2025-05-01'; -- Начальная дата периода
DECLARE @EndDate DATE = '2025-05-30';   -- Конечная дата периода

-- Выручка по каждой категории
SELECT
    dc.category_name AS Категория,
    SUM(oi.quantity * d.price) AS Выручка,
    SUM(oi.quantity) AS Количество,
    ROUND(SUM(oi.quantity * d.price) * 100.0 / NULLIF(SUM(SUM(oi.quantity * d.price)) OVER(), 0), 2) AS "Процент от общей выручки"
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
JOIN 
    DishCategories dc ON d.category_id = dc.category_id
WHERE
	b.bill_date BETWEEN @StartDate AND @EndDate
     AND b.payment_status = 2
GROUP BY
    dc.category_name
ORDER BY
    Выручка DESC;