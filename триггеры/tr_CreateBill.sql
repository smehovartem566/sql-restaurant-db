USE restaurant;
GO

CREATE TRIGGER tr_CreateBill
ON Orders
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Создаем чеки для новых заказов со статусом "Завершен" (INSERT)
    INSERT INTO Bills (order_id, bill_date, payment_method, payment_status)
    SELECT 
        i.order_id,
        i.order_date, -- Используем дату из заказа
        1, -- Способ оплаты поумолчанию
        1  -- Статус оплаты поумолчанию
    FROM inserted i
    LEFT JOIN Bills b ON i.order_id = b.order_id
    WHERE i.status = 2 -- Завершен
    AND b.order_id IS NULL -- Еще нет чека
    AND NOT EXISTS (SELECT 1 FROM deleted);
    
    -- Чеки для заказов, которые перешли в статус "Завершен" (UPDATE)
    INSERT INTO Bills (order_id, bill_date, payment_method, payment_status)
    SELECT 
        i.order_id,
        i.order_date, -- Используем дату из заказа
        1, -- Способ оплаты поумолчанию
        1  -- Статус оплаты поумолчанию
    FROM inserted i
    JOIN deleted d ON i.order_id = d.order_id
    LEFT JOIN Bills b ON i.order_id = b.order_id
    WHERE i.status = 2 -- Новый статус "Завершен"
    AND d.status <> 2 -- Старый статус не "Завершен"
    AND b.order_id IS NULL; -- Еще нет чека
END;