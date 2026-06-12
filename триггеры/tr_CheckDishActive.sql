use restaurant;
go

CREATE TRIGGER tr_CheckDishActive
ON OrderItems
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    -- Добавляем только активные блюда
    INSERT INTO OrderItems (order_id, dish_id, quantity, special_requests)
    SELECT i.order_id, i.dish_id, i.quantity, i.special_requests
    FROM inserted i
    JOIN Dishes d ON i.dish_id = d.dish_id
    WHERE d.is_active = 1;
    
    -- Если есть блюда, которые не были добавлены из-за неактивности
    IF @@ROWCOUNT < (SELECT COUNT(*) FROM inserted)
    BEGIN
        RAISERROR('Некоторые блюда не доступны в меню.', 16, 1);
    END
END;