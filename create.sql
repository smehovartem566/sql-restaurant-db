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

-- Таблица блюд (меню)
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