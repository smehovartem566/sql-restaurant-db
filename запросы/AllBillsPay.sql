USE restaurant;
-- Обновляем все чеки на статус "Оплачено"
UPDATE Bills
SET payment_status = 2  -- 2 = Оплачено
WHERE payment_status = 1; -- 1 = Ожидается оплата