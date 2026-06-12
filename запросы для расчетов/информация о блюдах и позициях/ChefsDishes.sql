USE restaurant;
-- Информация о конкретной позиции заказа
DECLARE @OrderId INT = 3; -- ид позиции заказа
SELECT 
    OrderItems.order_item_id 'ид позиции', 
    Dishes.dish_name 'блюдо', 
    OrderItems.quantity 'количество', 
    Dishes.price 'цена за единицу',
    (Dishes.price * OrderItems.quantity) 'общая стоимость',
    Employees.employee_id 'ид повара', 
    Employees.first_name 'имя', 
    Employees.last_name 'фамилия', 
    post.name 'должность', 
    Employees.rank 'разряд', 
    Employees.salary 'оклад', 
    Employees.hire_date 'дата устройства', 
    Employees.phone_number 'номер телефона' 
FROM 
    Employees
JOIN 
    post ON Employees.position = post.id
JOIN 
    DishAssignments ON DishAssignments.chef_id = Employees.employee_id
JOIN 
    OrderItems ON DishAssignments.order_item_id = OrderItems.order_item_id
JOIN 
    Dishes ON OrderItems.dish_id = Dishes.dish_id
WHERE 
    DishAssignments.order_item_id = @OrderId;