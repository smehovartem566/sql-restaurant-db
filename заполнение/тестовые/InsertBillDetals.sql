USE restaurant;
GO

-- Заполнение деталий чеков
INSERT INTO BillDetails (bill_id, order_item_id, price_per_unit)
SELECT b.bill_id, oi.order_item_id, d.price
FROM Bills b
JOIN Orders o ON b.order_id = o.order_id
JOIN OrderItems oi ON o.order_id = oi.order_id
JOIN Dishes d ON oi.dish_id = d.dish_id
WHERE NOT EXISTS (
    SELECT 1 
    FROM BillDetails bd 
    WHERE bd.bill_id = b.bill_id 
    AND bd.order_item_id = oi.order_item_id
);