USE restaurant;

-- Список поваров
SELECT 
    employee_id AS 'ид',
    first_name AS имя,
    last_name AS фамилия,
    post.name AS должность,
    rank AS разряд,
    salary AS оклад,
    hire_date AS 'дата устройства',
    phone_number AS 'номер телефона'
FROM 
    Employees,
    post
WHERE 
    Employees.position = post.id
    AND rank > 0;