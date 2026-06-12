Use restaurant;
-- »зменение цены блюда по iD
UPDATE Dishes
SET price = 300.00   -- ”кажите новую цену
WHERE dish_id = 3;    -- ”кажите ID блюда