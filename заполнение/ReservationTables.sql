USE restaurant;
GO

-- Бронирование столика
INSERT INTO TableReservations (table_id, client_id, reservation_date, start_time, end_time, notes)
VALUES
--номер столика, id клиента, дата брони, время начала, время завершения, примечния
(2, 1, '2025.04.15', '18:00', '20:00', 'День рождение');