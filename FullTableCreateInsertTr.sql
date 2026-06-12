Create Database restaurant;
Go
Use restaurant;

-- Таблица клиентов
CREATE TABLE Clients (
    client_id INT PRIMARY KEY IDENTITY(1,1),
    first_name NVARCHAR(50) NOT NULL,
    last_name NVARCHAR(50) NOT NULL,
    phone_number NVARCHAR(20)
);

-- Таблица столиков
CREATE TABLE Tables (
    table_id INT PRIMARY KEY IDENTITY(1,1),
    capacity INT NOT NULL,
    location NVARCHAR(100)
);

-- Таблица категорий блюд
CREATE TABLE DishCategories (
    category_id INT PRIMARY KEY IDENTITY(1,1),
    category_name NVARCHAR(50) NOT NULL
);

-- Меню
CREATE TABLE Dishes (
    dish_id INT PRIMARY KEY IDENTITY(1,1),
    dish_name NVARCHAR(100) NOT NULL,
    category_id INT FOREIGN KEY REFERENCES DishCategories(category_id),
    description NVARCHAR(255),
    price DECIMAL(10, 2) NOT NULL,
    preparation_time INT, -- в минутах
    is_active BIT DEFAULT 1
);

-- Таблица должностей
CREATE TABLE post (
    id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(20) NOT NULL UNIQUE
);
INSERT INTO post VALUES
('официант'),
('повар'),
('хостер'),
('су-шеф'),
('Бармен');

-- Таблица сотрудников
CREATE TABLE Employees (
    employee_id INT PRIMARY KEY IDENTITY(1,1),
    first_name NVARCHAR(50) NOT NULL,
    last_name NVARCHAR(50) NOT NULL,
    position INT FOREIGN KEY REFERENCES post(id) default 1,
 rank INT NOT NULL, -- разряд повара, если 0, то не повар
    salary DECIMAL(10, 2) NOT NULL, --оклад
    hire_date DATE NOT NULL,
    phone_number NVARCHAR(20)
);

-- Таблица статусов заказов
CREATE TABLE OrderStatuses (
    id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(20) NOT NULL UNIQUE
);
INSERT INTO OrderStatuses VALUES
('Готовится'),
('Завершен');

-- Таблица заказов
CREATE TABLE Orders (
    order_id INT PRIMARY KEY IDENTITY(1,1),
    client_id INT FOREIGN KEY REFERENCES Clients(client_id),
 table_id INT FOREIGN KEY REFERENCES Tables(table_id),
    employee_id INT FOREIGN KEY REFERENCES Employees(employee_id),
    order_date DATETIME NOT NULL DEFAULT GETDATE(),
    status INT FOREIGN KEY REFERENCES OrderStatuses(id) default 1,
    notes NVARCHAR(255)
);

-- Таблица позиций в заказе
CREATE TABLE OrderItems (
    order_item_id INT PRIMARY KEY IDENTITY(1,1),
    order_id INT FOREIGN KEY REFERENCES Orders(order_id),
    dish_id INT FOREIGN KEY REFERENCES Dishes(dish_id),
    quantity INT NOT NULL DEFAULT 1,
    special_requests NVARCHAR(255),
);

-- Таблица назначения поваров на блюда
CREATE TABLE DishAssignments (
    assignment_id INT PRIMARY KEY IDENTITY(1,1),
    order_item_id INT FOREIGN KEY REFERENCES OrderItems(order_item_id),
    chef_id INT FOREIGN KEY REFERENCES Employees(employee_id),
    assignment_time DATETIME NOT NULL DEFAULT GETDATE(),
    completion_time DATETIME
);

-- Таблица способов оплаты
CREATE TABLE PayMethod (
    id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(20) NOT NULL UNIQUE
);
INSERT INTO PayMethod VALUES
('Наличными'),
('Картой');

-- Таблица статусов оплаты чека
CREATE TABLE BillsStatuses (
    id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(20) NOT NULL UNIQUE
);
INSERT INTO BillsStatuses VALUES
('Ожидается'),
('Оплачен');

-- Таблица чеков
CREATE TABLE Bills (
    bill_id INT PRIMARY KEY IDENTITY(1,1),
    order_id INT FOREIGN KEY REFERENCES Orders(order_id),
    bill_date DATETIME NOT NULL DEFAULT GETDATE(),
    payment_method INT FOREIGN KEY REFERENCES PayMethod(id),
    payment_status INT FOREIGN KEY REFERENCES BillsStatuses(id)
);

-- Таблица создания чеков
CREATE TABLE BillDetails (
    bill_detail_id INT PRIMARY KEY IDENTITY(1,1),
    bill_id INT FOREIGN KEY REFERENCES Bills(bill_id),
    order_item_id INT FOREIGN KEY REFERENCES OrderItems(order_item_id),
    price_per_unit DECIMAL(10, 2) NOT NULL
);

-- Таблица статусов брони стола
CREATE TABLE TableStatuses (
    id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(20) NOT NULL UNIQUE
);
INSERT INTO TableStatuses VALUES
('Подтверждена'),
('Завершена');

-- Таблица бронирования столиков
CREATE TABLE TableReservations (
    reservation_id INT PRIMARY KEY IDENTITY(1,1),
    table_id INT FOREIGN KEY REFERENCES Tables(table_id),
    client_id INT FOREIGN KEY REFERENCES Clients(client_id),
    reservation_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status INT FOREIGN KEY REFERENCES TableStatuses(id) DEFAULT 1,
    notes NVARCHAR(255)
);

-- Таблица смен сотрудников
CREATE TABLE EmployeeShifts (
    shift_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT FOREIGN KEY REFERENCES Employees(employee_id),
    shift_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL
);


-- Триггеры
-- Чеки для завершенных заказов
GO

CREATE TRIGGER tr_CreateBill
ON Orders
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Создаем чеки для новых заказов со статусом "Завершен" (INSERT)
    INSERT INTO Bills (order_id, bill_date, payment_method, payment_status)
    SELECT 
        i.order_id,
        i.order_date, -- Используем дату из заказа
        1, -- Способ оплаты поумолчанию
        1  -- Статус оплаты поумолчанию
    FROM inserted i
    LEFT JOIN Bills b ON i.order_id = b.order_id
    WHERE i.status = 2 -- Завершен
    AND b.order_id IS NULL -- Еще нет чека
    AND NOT EXISTS (SELECT 1 FROM deleted);
    
    -- Чеки для заказов, которые перешли в статус "Завершен" (UPDATE)
    INSERT INTO Bills (order_id, bill_date, payment_method, payment_status)
    SELECT 
        i.order_id,
        i.order_date, -- Используем дату из заказа
        1, -- Способ оплаты поумолчанию
        1  -- Статус оплаты поумолчанию
    FROM inserted i
    JOIN deleted d ON i.order_id = d.order_id
    LEFT JOIN Bills b ON i.order_id = b.order_id
    WHERE i.status = 2 -- Новый статус "Завершен"
    AND d.status <> 2 -- Старый статус не "Завершен"
    AND b.order_id IS NULL; -- Еще нет чека
END;


-- Проверка что при заказе блюдо доступно
GO

CREATE TRIGGER tr_CheckDishActive
ON OrderItems
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    -- Добавляем только активные блюда
    INSERT INTO OrderItems (order_id, dish_id, quantity, special_requests)
    SELECT i.order_id, i.dish_id, i.quantity, i.special_requests
    FROM inserted i
    JOIN Dishes d ON i.dish_id = d.dish_id
    WHERE d.is_active = 1;
    
    -- Если есть блюда, которые не были добавлены из-за неактивности
    IF @@ROWCOUNT < (SELECT COUNT(*) FROM inserted)
    BEGIN
        RAISERROR('Некоторые блюда не доступны в меню.', 16, 1);
    END
END;


GO

-- Триггер проверки доступа столика перед бронированием
CREATE TRIGGER tr_CheckTableAvailability
ON TableReservations
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    -- Проверка
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
    
    -- Если есть брони, которые не были добавлены из-за недоступности стола
    IF @@ROWCOUNT < (SELECT COUNT(*) FROM inserted)
    BEGIN
        RAISERROR('Некоторые столики уже забронированы на указанное время.', 16, 1);
    END
END;


-- Заполнение всех таблиц
GO

-- Категории
INSERT INTO DishCategories (category_name)
VALUES 
('Супы'),
('Салаты'),
('Горячие закуски'),
('Холодные закуски'),
('Мясные блюда'),
('Рыбные блюда'),
('Птица'),
('Гарниры'),
('Десерты'),
('Напитки алкогольные'),
('Напитки безалкогольные'),
('Фирменные блюда'),
('Детское меню');

-- Меню
INSERT INTO Dishes (dish_name, category_id, description, price, preparation_time, is_active)
VALUES
-- Супы
('Борщ украинский', 1, 'Классический борщ с говядиной, салом и пампушками', 350.00, 40, 1),
('Томатный суп с морепродуктами', 1, 'Ароматный суп с креветками, мидиями и базиликом', 420.00, 30, 1),
('Грибной крем-суп с трюфелем', 1, 'Нежный суп из лесных грибов с трюфельным маслом', 380.00, 25, 1),
('Солянка сборная мясная', 1, 'Густой суп с тремя видами мяса, оливками и лимоном', 370.00, 35, 1),
('Куриный бульон с клецками', 1, 'Ароматный бульон с домашними клецками и зеленью', 290.00, 30, 1),

-- Салаты
('Цезарь с креветками', 2, 'Листья романо, тигровые креветки, пармезан и соус цезарь', 480.00, 15, 1),
('Салат с уткой и гранатом', 2, 'Утка-гриль, руккола, кедровые орехи, гранатовый соус', 520.00, 20, 1),
('Греческий с тунцом', 2, 'Свежие овощи, тунец-гриль, фета, оливковое масло', 450.00, 15, 1),
('Теплый салат с телятиной', 2, 'Нежная телятина, шампиньоны, спаржа, кунжут', 490.00, 20, 1),
('Страчателла', 2, 'Свежий сыр страчателла, помидоры черри, базилик', 390.00, 10, 1),
('Винегрет с морскими гребешками', 2, 'Классический винегрет с добавлением обжаренных гребешков', 410.00, 20, 1),

-- Горячие закуски
('Камчатские крабы в сливочном соусе', 3, 'Нежное мясо краба с соусом из белого вина и сливок', 680.00, 25, 1),
('Жульен из грибов с трюфелем', 3, 'Шампиньоны и лесные грибы в сливочном соусе под сырной корочкой', 320.00, 20, 1),
('Мидии в томатно-чесночном соусе', 3, 'Свежие мидии с чесноком, томатами и базиликом', 450.00, 15, 1),
('Тар-тар из говядины', 3, 'Премиальная говядина с каперсами, луком и перепелиным желтком', 520.00, 15, 1),

-- Холодные закуски
('Ассорти из сыров', 4, 'Подборка европейских сыров с орехами и медом', 580.00, 10, 1),
('Карпаччо из лосося', 4, 'Тонкие ломтики лосося с соусом из лимона и укропа', 490.00, 10, 1),
('Брускетта с трюфельной пастой', 4, 'Хрустящие тосты с трюфельным паштетом и рукколой', 320.00, 10, 1),
('Овощной тартар с авокадо', 4, 'Свежие овощи и авокадо с цитрусовой заправкой', 290.00, 10, 1),

-- Мясные блюда
('Томленая телячья щека', 5, 'Медленное приготовление с красным вином и розмарином', 780.00, 50, 1),
('Стейк Рибай 400г', 5, 'Мраморная говядина высшего сорта', 1200.00, 25, 1),
('Медальоны из ягненка', 5, 'Нежные медальоны с мятным желе и овощами гриль', 850.00, 30, 1),
('Утка конфи с апельсиновым соусом', 5, 'Утка медленного приготовления с цитрусовым соусом', 720.00, 40, 1),
('Ребра BBQ', 5, 'Свиные ребра в фирменном соусе барбекю', 680.00, 45, 1),
('Фуа-гра с ягодным соусом', 5, 'Нежная фуа-гра с бальзамическим соусом', 950.00, 20, 1),

-- Рыбные блюда
('Дорадо на гриле', 6, 'Свежая дорадо с лимоном и травами', 890.00, 20, 1),
('Лосось под корочкой из зелени', 6, 'Филе лосося с хрустящей травяной корочкой', 750.00, 25, 1),
('Сибас в солевой шубке', 6, 'Приготовление в соляной корочке с розмарином', 920.00, 30, 1),
('Креветки в кокосовом карри', 6, 'Крупные тигровые креветки в азиатском соусе', 780.00, 20, 1),
('Микс из морепродуктов', 6, 'Креветки, мидии, кальмары в чесночном соусе', 850.00, 25, 1),

-- Птица
('Утиная грудка с вишневым соусом', 7, 'Утка средней прожарки с кисло-сладким соусом', 690.00, 30, 1),
('Цыпленок табака', 7, 'Традиционное грузинское блюдо с чесночным соусом', 580.00, 40, 1),
('Фазан в винном соусе', 7, 'Нежное мясо фазана с лесными грибами', 950.00, 45, 1),

-- Гарниры
('Трюфельное пюре', 8, 'Нежное картофельное пюре с трюфельным маслом', 220.00, 15, 1),
('Овощи гриль с хумусом', 8, 'Сезонные овощи с домашним хумусом', 190.00, 10, 1),
('Гречка с лесными грибами', 8, 'Ароматная гречка с шампиньонами и луком', 180.00, 15, 1),
('Картофель дюшес', 8, 'Воздушный картофель с сыром и зеленью', 210.00, 20, 1),
('Аспарагус с пармезаном', 8, 'Спаржа с сыром пармезан и бальзамиком', 250.00, 10, 1),

-- Десерты
('Тирамису классический', 9, 'Кофейный десерт с маскарпоне и савоярди', 350.00, 10, 1),
('Шоколадный фондан с малиной', 9, 'Теплый шоколадный кекс с жидкой серединкой', 380.00, 15, 1),
('Чизкейк Нью-Йорк', 9, 'Классический чизкейк с ягодным соусом', 320.00, 10, 1),
('Крем-брюле с ванилью', 9, 'Нежный крем с хрустящей карамельной корочкой', 290.00, 10, 1),
('Яблочный тарт-татен', 9, 'Теплый яблочный пирог с ванильным мороженым', 340.00, 20, 1),
('Меренговый рулет с лимонным курдом', 9, 'Воздушный десерт с кисло-сладкой начинкой', 360.00, 15, 1),

-- Алкогольные напитки
('Вино красное "Chateau Margaux"', 10, 'Франция, Бордо, 2015 год', 4500.00, 1, 1),
('Вино белое "Cloudy Bay"', 10, 'Новая Зеландия, Совиньон Блан, 2020', 3800.00, 1, 1),
('Виски Macallan 12 лет', 10, 'Шотландия, выдержка в бочках из-под хереса', 1200.00, 1, 1),
('Коктейль "Мохито"', 10, 'Белый ром, лайм, мята, содовая', 450.00, 5, 1),

-- Безалкогольные напитки 
('Лимонад домашний', 11, 'Свежий лимон, мята, имбирь', 220.00, 5, 1),
('Смузи из манго и маракуйи', 11, 'Фруктовый микс с йогуртом', 280.00, 5, 1),
('Чай матча латте', 11, 'Японский зеленый чай с молоком', 250.00, 5, 1),
('Кофе эспрессо', 11, 'Итальянский эспрессо 30мл', 180.00, 5, 1),

-- Фирменные блюда
('Фирменный стейк "Шеф"', 12, 'Отборная говядина с трюфельным соусом и овощным рататуем', 1500.00, 30, 1),
('Дегустационный сет морепродуктов', 12, 'Ассорти из лучших морепродуктов с соусами', 2200.00, 40, 1),
('Шоколадный сюрприз', 12, 'Фирменный десерт с жидкой шоколадной начинкой', 500.00, 20, 1),

-- Детское меню
('Куриные наггетсы', 13, 'С картофелем фри и овощами', 320.00, 15, 1),
('Мини-пицца', 13, 'С курицей и овощами', 290.00, 20, 1),
('Блинчики с вареньем', 13, 'Тонкие блинчики с домашним вареньем', 250.00, 10, 1);

-- Заполнение таблицы клиентов
INSERT INTO Clients (first_name, last_name, phone_number)
VALUES
('Иван', 'Петров', '+79161234567'),
('Елена', 'Смирнова', '+79162345678'),
('Алексей', 'Кузнецов', '+79163456789'),
('Ольга', 'Васильева', '+79164567890'),
('Дмитрий', 'Попов', '+79165678901'),
('Анна', 'Соколова', '+79166789012'),
('Сергей', 'Михайлов', '+79167890123'),
('Мария', 'Новикова', '+79168901234'),
('Андрей', 'Федоров', '+79169012345'),
('Наталья', 'Морозова', '+79160123456'),
('Александра', 'Ковалева', '+79161112233'),
('Максим', 'Лебедев', '+79162223344'),
('Елизавета', 'Соловьева', '+79163334455'),
('Артем', 'Козлов', '+79164445566'),
('Валерия', 'Новикова', '+79165556677'),
('Денис', 'Морозов', '+79166667788'),
('Ангелина', 'Павлова', '+79167778899'),
('Кирилл', 'Семенов', '+79168889900'),
('Виктория', 'Волкова', '+79169990011'),
('Никита', 'Алексеев', '+79161001011');

-- Заполнение таблицы столиков
INSERT INTO Tables (capacity, location)
VALUES
(2, 'У окна'),
(2, 'В углу'),
(4, 'Центр зала'),
(4, 'У окна'),
(6, 'VIP зона'),
(6, 'Центр зала'),
(8, 'VIP зона'),
(10, 'Отдельный зал'),
(12, 'Отдельный зал'),
(2, 'Барная стойка'),
(2, 'Терраса'),
(4, 'Терраса'),
(2, 'VIP зона'),
(4, 'Барная стойка'),
(6, 'Летняя веранда'),
(8, 'Отдельный кабинет'),
(10, 'Банкетный зал'),
(12, 'Банкетный зал');

-- Заполнение таблицы сотрудников
INSERT INTO Employees (first_name, last_name, position, rank, salary, hire_date, phone_number)
VALUES
-- Повара (разряд от 1 до 5)
('Александр', 'Иванов', 2, 5, 800, '2020-01-15', '+79161112233'),
('Екатерина', 'Семенова', 2, 4, 650, '2021-03-22', '+79162223344'),
('Михаил', 'Петров', 2, 3, 550, '2022-05-10', '+79163334455'),
('Ольга', 'Николаева', 2, 2, 450, '2023-02-18', '+79164445566'),

-- Су-шеф (разряд 5)
('Геннадий', 'Павлов', 4, 5, 900, '2019-04-12', '+79161001011'),

-- Официанты (разряд 0)
('Анна', 'Козлова', 1, 0, 350, '2022-01-10', '+79166667788'),
('Денис', 'Белов', 1, 0, 350, '2022-06-15', '+79167778899'),
('Виктория', 'Медведева', 1, 0, 370, '2021-11-20', '+79168889900'),

-- Хостер (разряд 0)
('Алина', 'Степанова', 3, 0, 400, '2020-09-05', '+79169990011'),

-- Бармен (разряд 0)
('Роман', 'Киселев', 5, 0, 380, '2022-08-25', '+79162112131');

GO

-- Бронирования столиков
INSERT INTO TableReservations (table_id, client_id, reservation_date, start_time, end_time, status, notes)
VALUES
(1, 1, '2025-05-01', '12:00', '14:00', 1, 'Обед'),
(2, 2, '2025-05-01', '13:00', '15:00', 1, 'Деловая встреча'),
(3, 3, '2025-05-01', '18:00', '20:00', 1, 'День рождения'),
(4, 4, '2025-05-02', '12:00', '14:00', 1, 'Бизнес-ланч'),
(5, 5, '2025-05-02', '19:00', '21:00', 1, 'Семейный ужин'),
(6, 6, '2025-05-03', '12:00', '14:00', 1, 'Обед с клиентом'),
(7, 7, '2025-05-03', '18:00', '20:00', 1, 'Юбилей'),
(8, 8, '2025-05-04', '12:00', '14:00', 1, 'Переговоры'),
(9, 9, '2025-05-04', '19:00', '21:00', 1, 'Романтический ужин'),
(10, 10, '2025-05-05', '12:00', '14:00', 1, 'Бизнес-встреча'),
(1, 11, '2025-05-05', '18:00', '20:00', 1, 'День рождения'),
(2, 12, '2025-05-06', '12:00', '14:00', 1, 'Обед'),
(3, 13, '2025-05-06', '19:00', '21:00', 1, 'Корпоратив'),
(4, 14, '2025-05-07', '12:00', '14:00', 1, 'Деловая встреча'),
(5, 15, '2025-05-07', '18:00', '20:00', 1, 'Семейный праздник'),
(6, 16, '2025-05-08', '12:00', '14:00', 1, 'Бизнес-ланч'),
(7, 17, '2025-05-08', '19:00', '21:00', 1, 'День рождения'),
(8, 18, '2025-05-09', '12:00', '14:00', 1, 'Обед с партнерами'),
(9, 19, '2025-05-09', '18:00', '20:00', 1, 'Встреча друзей'),
(10, 20, '2025-05-10', '12:00', '14:00', 1, 'Деловой обед');

-- Заказы
INSERT INTO Orders (client_id, table_id, employee_id, order_date, status, notes)
VALUES
(1, 1, 6, '2025-05-01T12:30:00', 2, 'Без лука'),
(2, 2, 6, '2025-05-01T13:15:00', 2, 'Детское меню'),
(3, 3, 7, '2025-05-01T18:30:00', 2, NULL),
(1, 1, 6, '2025-05-01T13:00:00', 2, NULL),
(2, 2, 7, '2025-05-01T14:00:00', 2, NULL),

(4, 4, 7, '2025-05-02T12:15:00', 2, NULL),
(5, 5, 8, '2025-05-02T19:30:00', 2, 'Детский стульчик'),
(4, 4, 6, '2025-05-02T13:00:00', 2, NULL),
(5, 5, 7, '2025-05-02T20:00:00', 2, 'Вегетарианское меню'),
(4, 4, 8, '2025-05-02T13:30:00', 2, 'Без глютена'),

(6, 6, 6, '2025-05-03T12:45:00', 2, 'Деловой обед'),
(7, 7, 7, '2025-05-03T18:45:00', 2, 'Шампанское'),
(6, 6, 8, '2025-05-03T13:15:00', 2, NULL),
(7, 7, 6, '2025-05-03T19:15:00', 2, 'Цветы на стол'),
(6, 6, 7, '2025-05-03T13:45:00', 2, 'Счет отдельно'),

(8, 8, 7, '2025-05-04T12:30:00', 2, 'Аллергия на орехи'),
(9, 9, 8, '2025-05-04T18:30:00', 2, 'Романтический ужин'),
(8, 8, 6, '2025-05-04T13:00:00', 2, NULL),
(9, 9, 7, '2025-05-04T19:00:00', 2, NULL),
(8, 8, 8, '2025-05-04T13:30:00', 2, NULL),

(10, 10, 6, '2025-05-05T12:15:00', 2, 'Бизнес-ланч'),
(1, 1, 7, '2025-05-05T18:15:00', 2, 'День рождения'),
(10, 10, 8, '2025-05-05T13:00:00', 2, NULL),
(1, 1, 6, '2025-05-05T19:00:00', 2, NULL),
(10, 10, 7, '2025-05-05T13:30:00', 2, NULL),

(2, 2, 7, '2025-05-06T12:45:00', 2, 'Обед'),
(3, 3, 8, '2025-05-06T19:15:00', 2, 'Корпоратив'),
(2, 2, 6, '2025-05-06T13:15:00', 2, NULL),
(3, 3, 7, '2025-05-06T20:00:00', 2, 'Алкоголь'),
(2, 2, 8, '2025-05-06T13:45:00', 2, NULL),

(4, 4, 6, '2025-05-07T12:30:00', 2, 'Деловая встреча'),
(5, 5, 7, '2025-05-07T18:30:00', 2, 'Семейный праздник'),
(4, 4, 8, '2025-05-07T13:00:00', 2, NULL),
(5, 5, 6, '2025-05-07T19:00:00', 2, 'Детское меню'),
(4, 4, 7, '2025-05-07T13:30:00', 2, 'Без специй'),

(6, 6, 7, '2025-05-08T12:15:00', 2, 'Бизнес-ланч'),
(7, 7, 8, '2025-05-08T19:15:00', 2, 'День рождения'),
(6, 6, 6, '2025-05-08T13:00:00', 2, NULL),
(7, 7, 7, '2025-05-08T20:00:00', 2, NULL),
(6, 6, 8, '2025-05-08T13:30:00', 2, NULL),

(8, 8, 6, '2025-05-09T12:45:00', 2, 'Обед с партнерами'),
(9, 9, 7, '2025-05-09T18:45:00', 2, 'Встреча друзей'),
(8, 8, 8, '2025-05-09T13:15:00', 2, NULL),
(9, 9, 6, '2025-05-09T19:15:00', 2, NULL),
(8, 8, 7, '2025-05-09T13:45:00', 2, NULL),

(10, 10, 7, '2025-05-10T12:30:00', 2, 'Деловой обед'),
(10, 10, 8, '2025-05-10T13:00:00', 2, NULL),
(10, 10, 6, '2025-05-10T13:30:00', 2, NULL),
(10, 10, 7, '2025-05-10T14:00:00', 2, NULL),
(10, 10, 8, '2025-05-10T14:30:00', 2, NULL);

-- Позиции в заказах
INSERT INTO OrderItems (order_id, dish_id, quantity, special_requests)
VALUES
(1, 5, 4, NULL), (1, 12, 11, 'Без лука'),
(2, 3, 18, 'Детские порции'),
(3, 25, 4, NULL), (3, 30, 12, NULL), (3, 45, 11, NULL),
(4, 8, 12, 'Острое'),
(5, 15, 13, NULL), (5, 20, 5, 'С собой'),
(6, 7, 12, NULL),
(7, 10, 12, NULL), (7, 13, 13, NULL),
(8, 18, 13, NULL), (8, 22, 12, NULL), (8, 35, 4, NULL),
(9, 5, 13, NULL), (9, 40, 4, NULL), (9, 51, 8, NULL), (9, 2, 11, NULL), (9, 3, 12, NULL),
(10, 40, 12, 'Без глютена'),
(11, 12, 12, NULL), (11, 28, 13, NULL),
(12, 6, 12, 'Острое'),
(13, 19, 13, NULL), (13, 27, 15, NULL), (13, 33, 12, NULL),
(14, 8, 13, NULL),
(15, 11, 12, NULL), (15, 25, 13, NULL),
(16, 30, 3, NULL), (16, 11, 12, NULL), (16, 22, 3, NULL), (16, 3, 14, NULL),
(17, 5, 12, NULL), (17, 15, 7, NULL), (17, 25, 12, NULL),
(18, 9, 13, NULL),
(19, 14, 15, NULL), (19, 29, 4, NULL),
(20, 35, 3, NULL), (20, 42, 12, NULL), (20, 43, 14, NULL), (20, 44, 7, NULL),
(21, 2, 14, NULL), (21, 6, 6, NULL),
(22, 7, 11, NULL), (22, 17, 13, NULL),
(23, 22, 12, NULL),
(24, 5, 11, NULL), (24, 53, 12, NULL), (24, 54, 14, NULL), (24, 55, 3, NULL),
(25, 40, 12, NULL), (25, 2, 12, NULL),
(26, 12, 14, NULL), (26, 28, 13, NULL),
(27, 6, 12, 'Без специй'),
(28, 19, 14, NULL), (28, 27, 2, NULL), (28, 33, 12, NULL),
(29, 8, 11, NULL),
(30, 11, 12, NULL), (30, 25, 13, NULL),
(31, 30, 4, NULL), (31, 34, 3, NULL), (31, 35, 6, NULL), (31, 39, 13, NULL),
(32, 5, 14, NULL), (32, 15, 11, NULL), (32, 25, 3, NULL),
(33, 9, 11, NULL),
(34, 14, 11, NULL), (34, 29, 5, NULL),
(35, 35, 13, NULL), (35, 39, 13, NULL),
(36, 2, 15, NULL),
(37, 7, 17, NULL), (37, 17, 11, NULL),
(38, 22, 11, NULL),
(39, 5, 5, NULL), (39, 2, 15, NULL),
(40, 40, 13, NULL), (40, 42, 15, NULL), (40, 43, 4, NULL), (40, 44, 12, NULL),
(41, 12, 12, NULL), (41, 28, 1, NULL),
(42, 35, 12, NULL), (42, 10, 3, NULL), (42, 12, 11, NULL), (42, 22, 3, NULL),
(43, 19, 15, NULL), (43, 27, 2, NULL), (43, 33, 2, NULL),
(44, 8, 16, NULL), (44, 3, 4, NULL), (44, 45, 10, NULL), (44, 38, 13, NULL),
(45, 11, 11, NULL), (45, 25, 9, NULL),
(46, 30, 15, NULL), (46, 34, 13, NULL), (46, 35, 6, NULL), (46, 39, 3, NULL),
(47, 5, 14, NULL), (47, 15, 15, NULL), (47, 25, 11, NULL),
(48, 9, 18, NULL),
(49, 14, 11, NULL), (49, 29, 13, NULL),
(50, 35, 10, NULL), (50, 10, 4, NULL), (50, 12, 3, NULL), (50, 22, 17, NULL);

GO

-- Смены для поваров
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

-- Распределяем поваров только на новые позиции заказов
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
    )  -- Только позиции, которые еще не распределены
)

INSERT INTO DishAssignments (order_item_id, chef_id, assignment_time, completion_time)
SELECT
    noi.order_item_id,
    (
        SELECT TOP 1 ac.employee_id
        FROM AvailableChefs ac
        WHERE
            -- Повар работает в день заказа
            CONVERT(DATE, noi.order_date) = ac.shift_date
            -- Время приготовления попадает в смену
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
        -- Распределяем между доступными поварами
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