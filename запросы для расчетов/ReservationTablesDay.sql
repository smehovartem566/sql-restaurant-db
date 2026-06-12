USE restaurant;
GO

DECLARE @SearchDate DATE = '2025-05-01'; -- Укажите нужную дату

-- Информации о бронированиях на указанную дату
SELECT 
    tr.reservation_id AS 'ID брони',
    t.table_id AS 'Номер столика',
    t.capacity AS 'Вместимость',
    t.location AS 'Расположение',
    CONCAT(c.first_name, ' ', c.last_name) AS 'Клиент',
    c.phone_number AS 'Телефон',
    tr.reservation_date AS 'Дата брони',
    tr.start_time AS 'Время начала',
    tr.end_time AS 'Время окончания',
    DATEDIFF(MINUTE, tr.start_time, tr.end_time) AS 'Длительность (мин)',
    ts.name AS 'Статус брони',
    tr.notes AS 'Примечания'
FROM 
    TableReservations tr
JOIN 
    Tables t ON tr.table_id = t.table_id
JOIN 
    Clients c ON tr.client_id = c.client_id
JOIN 
    TableStatuses ts ON tr.status = ts.id
WHERE 
    tr.reservation_date = @SearchDate
    AND tr.status = 1
ORDER BY 
    t.table_id, tr.start_time;