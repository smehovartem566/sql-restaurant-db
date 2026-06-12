USE restaurant;
GO

-- —мены дл€ поваров
INSERT INTO EmployeeShifts (employee_id, shift_date, start_time, end_time)
SELECT 
    e.employee_id,
    dates.shift_date,
    CASE 
        WHEN e.employee_id % 2 = 0 THEN '10:00' ELSE '14:00' 
    END as start_time,
    CASE 
        WHEN e.employee_id % 2 = 0 THEN '18:00' ELSE '22:00' 
    END as end_time
FROM Employees e
CROSS JOIN (
    SELECT DISTINCT CONVERT(DATE, order_date) as shift_date
    FROM Orders
) dates
WHERE e.position !=1 and e.position !=3 and e.position !=5
AND NOT EXISTS (
    SELECT 1 
    FROM EmployeeShifts es 
    WHERE es.employee_id = e.employee_id 
    AND es.shift_date = dates.shift_date
);



-- –аспредел€ем поваров только на новые позиции заказов
WITH AvailableChefs AS (
    SELECT 
        e.employee_id,
        es.shift_date,
        es.start_time,
        es.end_time
    FROM Employees e
    JOIN EmployeeShifts es ON e.employee_id = es.employee_id
    WHERE e.position !=1 and e.position !=3 and e.position !=5
),
NewOrderItems AS (
    SELECT 
        oi.order_item_id,
        oi.order_id,
        oi.dish_id,
        o.order_date,
        d.preparation_time
    FROM OrderItems oi
    JOIN Orders o ON oi.order_id = o.order_id
    JOIN Dishes d ON oi.dish_id = d.dish_id
    WHERE NOT EXISTS (
        SELECT 1 
        FROM DishAssignments da 
        WHERE da.order_item_id = oi.order_item_id
    )  -- “олько позиции, которые еще не распределены
)

INSERT INTO DishAssignments (order_item_id, chef_id, assignment_time, completion_time)
SELECT
    noi.order_item_id,
    (
        SELECT TOP 1 ac.employee_id
        FROM AvailableChefs ac
        WHERE 
            -- ѕовар работает в день заказа
            CONVERT(DATE, noi.order_date) = ac.shift_date
            -- ¬рем€ приготовлени€ попадает в смену
            AND DATEADD(MINUTE, noi.preparation_time, noi.order_date) BETWEEN 
                DATETIMEFROMPARTS(
                    YEAR(noi.order_date),
                    MONTH(noi.order_date),
                    DAY(noi.order_date),
                    DATEPART(HOUR, ac.start_time),
                    DATEPART(MINUTE, ac.start_time),
                    0, 0
                )
                AND 
                DATETIMEFROMPARTS(
                    YEAR(noi.order_date),
                    MONTH(noi.order_date),
                    DAY(noi.order_date),
                    DATEPART(HOUR, ac.end_time),
                    DATEPART(MINUTE, ac.end_time),
                    0, 0
                )
        -- –аспредел€ем между доступными поварами
        ORDER BY NEWID()
    ) as chef_id,
    noi.order_date as assignment_time,
    DATEADD(MINUTE, noi.preparation_time, noi.order_date) as completion_time
FROM NewOrderItems noi
WHERE EXISTS (
    SELECT 1 
    FROM AvailableChefs ac 
    WHERE CONVERT(DATE, noi.order_date) = ac.shift_date
);