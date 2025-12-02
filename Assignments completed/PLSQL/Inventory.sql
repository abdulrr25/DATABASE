
-- Inventory Stock Alert System

-- Drop tables if they already exist
DROP TABLE IF EXISTS ReorderRequests;
DROP TABLE IF EXISTS Inventory;

-- ============================================================
-- 1. Create Tables
-- ============================================================

CREATE TABLE Inventory (
    inventory_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    quantity INT DEFAULT 0,
    reorder_level INT DEFAULT 10,
    last_updated DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

CREATE TABLE ReorderRequests (
    reorder_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    inventory_id INT,
    request_date DATE DEFAULT CURRENT_DATE,
    quantity_requested INT,
    status VARCHAR(20) DEFAULT 'pending',
    FOREIGN KEY (inventory_id) REFERENCES Inventory(inventory_id)
);

-- ============================================================
-- 2. Procedure: Stock Alert System
-- ============================================================

DELIMITER $$

CREATE PROCEDURE stock_alert()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_inventory_id INT;
    DECLARE v_quantity INT;
    DECLARE v_reorder_level INT;

    -- Cursor to scan all inventory items
    DECLARE cur CURSOR FOR
        SELECT inventory_id, quantity, reorder_level
        FROM Inventory;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO v_inventory_id, v_quantity, v_reorder_level;
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;

        -- Check if stock is below reorder level
        IF v_quantity < v_reorder_level THEN
            -- Insert reorder request
            INSERT INTO ReorderRequests(inventory_id, quantity_requested, status)
            VALUES(v_inventory_id, (v_reorder_level - v_quantity), 'pending');
        END IF;
    END LOOP;

    CLOSE cur;
END$$

DELIMITER ;

-- ============================================================
-- 3. Sample Data
-- ============================================================

-- Assuming Products table already exists
INSERT INTO Products(product_id, product_name, price, stock) VALUES
(1, 'Laptop', 50000, 10),
(2, 'Phone', 20000, 5),
(3, 'Headphones', 2000, 2);

-- Insert inventory records
INSERT INTO Inventory(product_id, quantity, reorder_level) VALUES
(1, 8, 10),   -- Below reorder level
(2, 15, 10),  -- Above reorder level
(3, 3, 5);    -- Below reorder level

-- ============================================================
-- 4. Run Stock Alert
-- ============================================================

CALL stock_alert();

-- View reorder requests
SELECT * FROM ReorderRequests;
