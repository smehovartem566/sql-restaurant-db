USE restaurant;
-- Создание заказа с автоматическим определением ID
DECLARE @DateBillOrder DATETIME = '2025-04-15T18:30:00'; -- Заполнить дату
DECLARE @NewOrderId INT;

-- Определяем следующий доступный ID для заказа
SELECT @NewOrderId = ISNULL(MAX(order_id), 0) + 1 FROM Orders;

-- Создаем заказ
INSERT INTO Orders(client_id, table_id, employee_id, order_date, status, notes)
VALUES
-- Заполнить Ид клиента, номер столика, ид официанта, дата из переменной, статус заказа, пожелания
(1, 1, 7, @DateBillOrder, 1, 'Без лука');

-- Получаем фактически созданный ID
SET @NewOrderId = SCOPE_IDENTITY();

-- Добавляем позиции в заказ
INSERT INTO OrderItems (order_id, dish_id, quantity, special_requests)
VALUES
-- ид заказа из переменной. Заполнить ид блюда, количество, примечания к этому блюду
(@NewOrderId, 3, 1, NULL), 
(@NewOrderId, 4, 1, 'Без сухариков'), 
(@NewOrderId, 7, 1, 'Medium rare'), 
(@NewOrderId, 16, 2, NULL);

-- Создаем чек
INSERT INTO Bills (order_id, bill_date, payment_method, payment_status)
VALUES
-- ид заказа и дата из переменной. Заполнить метод оплаты
(@NewOrderId, @DateBillOrder, 1, 1);

-- Добавляем детали чека
INSERT INTO BillDetails (bill_id, order_item_id, price_per_unit)
SELECT b.bill_id, oi.order_item_id, d.price
FROM Bills b
JOIN Orders o ON b.order_id = o.order_id
JOIN OrderItems oi ON o.order_id = oi.order_id
JOIN Dishes d ON oi.dish_id = d.dish_id
WHERE b.order_id = @NewOrderId;

-- Выводим информацию о созданном заказе
SELECT 
    @NewOrderId AS 'Созданный ID заказа',
    COUNT(*) AS 'Количество позиций',
    SUM(d.price * oi.quantity) AS 'Общая сумма'
FROM 
    OrderItems oi
JOIN 
    Dishes d ON oi.dish_id = d.dish_id
WHERE 
    oi.order_id = @NewOrderId;