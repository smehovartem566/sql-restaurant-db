use restaurant;
GO

-- “риггер проверки доступа столика перед бронированием
CREATE TRIGGER tr_CheckTableAvailability
ON TableReservations
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    -- ѕроверка
    INSERT INTO TableReservations (table_id, client_id, reservation_date, start_time, end_time, status, notes)
    SELECT i.table_id, i.client_id, i.reservation_date, i.start_time, i.end_time, i.status, i.notes
    FROM inserted i
    WHERE NOT EXISTS (
        SELECT 1 FROM TableReservations tr
        WHERE tr.table_id = i.table_id
        AND tr.reservation_date = i.reservation_date
        AND tr.status = 1
        AND (
            (i.start_time < tr.end_time AND i.end_time > tr.start_time)
        )
    );
    
    -- ≈сли есть брони, которые не были добавлены из-за недоступности стола
    IF @@ROWCOUNT < (SELECT COUNT(*) FROM inserted)
    BEGIN
        RAISERROR('Ќекоторые столики уже забронированы на указанное врем€.', 16, 1);
    END
END;