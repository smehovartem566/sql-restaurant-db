USE restaurant;
-- Меню
SELECT 
    dish_id AS 'ид блюда',
    dish_name AS название,
    DishCategories.category_name AS категория,
    description AS описание,
    price AS цена,
    preparation_time AS 'время приготовления'
FROM 
    Dishes,
    DishCategories
WHERE 
    Dishes.category_id = DishCategories.category_id
    AND is_active = 1;
