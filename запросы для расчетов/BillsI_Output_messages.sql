USE restaurant;
GO

-- Чек
DECLARE @BillID INT = 9; -- Укажите нужный ID чека здесь
DECLARE @OutputMessage NVARCHAR(MAX) = '';

-- Шапка чека
SELECT @OutputMessage = @OutputMessage + 
    'Чек №' + CAST(b.bill_id AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
    'Дата: ' + FORMAT(b.bill_date, 'dd.MM.yyyy HH:mm') + CHAR(13) + CHAR(10) +
    'Столик №' + CAST(o.table_id AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
    'Официант: ' + e.first_name + ' ' + e.last_name + CHAR(13) + CHAR(10) +
    REPLICATE('-', 30) + CHAR(13) + CHAR(10)
FROM 
    Bills b
JOIN 
    Orders o ON b.order_id = o.order_id
JOIN 
    Employees e ON o.employee_id = e.employee_id
WHERE 
    b.bill_id = @BillID;

-- Позиции чека
SELECT @OutputMessage = @OutputMessage +
    CAST(ROW_NUMBER() OVER(ORDER BY d.dish_name) AS VARCHAR(3)) + '. ' + 
    d.dish_name + CHAR(9) +
    CAST(oi.quantity AS VARCHAR(3)) + ' x ' +
    CAST(bd.price_per_unit AS VARCHAR(10)) + ' Р = ' +
    CAST((oi.quantity * bd.price_per_unit) AS VARCHAR(10)) + ' Р' +
    CASE WHEN oi.special_requests IS NOT NULL 
         THEN ' (' + oi.special_requests + ')' 
         ELSE '' END +
    CHAR(13) + CHAR(10)
FROM 
    BillDetails bd
JOIN 
    OrderItems oi ON bd.order_item_id = oi.order_item_id
JOIN 
    Dishes d ON oi.dish_id = d.dish_id
WHERE 
    bd.bill_id = @BillID
ORDER BY 
    d.dish_name;

-- Итоговая информация
SELECT @OutputMessage = @OutputMessage +
    REPLICATE('-', 30) + CHAR(13) + CHAR(10) +
    'Итого: ' + CAST(SUM(oi.quantity * bd.price_per_unit) AS VARCHAR(10)) + ' Р' + CHAR(13) + CHAR(10) +
    'Способ оплаты: ' + pm.name + CHAR(13) + CHAR(10) +
    'Статус: ' + CASE 
                    WHEN b.payment_status = 2 THEN 'Оплачено' 
                    ELSE 'Ожидается оплата' 
                 END + CHAR(13) + CHAR(10)
FROM 
    BillDetails bd
JOIN 
    OrderItems oi ON bd.order_item_id = oi.order_item_id
JOIN 
    Bills b ON bd.bill_id = b.bill_id
JOIN 
    PayMethod pm ON b.payment_method = pm.id
WHERE 
    bd.bill_id = @BillID
GROUP BY 
    pm.name, b.payment_status;

-- Выводим результат
PRINT @OutputMessage;