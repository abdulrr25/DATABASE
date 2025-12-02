-- 
-- E-Commerce Database 

-- Drop tables if they already exist (for clean setup)
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;

-- ============================================================
-- 1. Create Products Table
-- ============================================================
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50),
    price INT,
    stock INT,
    discount INT -- random discount between 5% and 30%
);

-- 2. Create Orders Table

CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    qty INT,
    total_price INT,
    cashback INT, -- random cashback between 0 and 100
    order_date DATE DEFAULT CURDATE()
);


-- 3. Trigger: Assign Random Discount on Product Insert

DELIMITER $$

CREATE TRIGGER trg_product_insert
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
    -- Assign random discount between 5% and 30%
    SET NEW.discount = FLOOR(5 + (RAND() * 26));
END$$

DELIMITER ;


-- 4. Procedure: Place Order

DELIMITER $$

CREATE PROCEDURE place_order(
    IN p_customer_id INT,
    IN p_product_id INT,
    IN p_qty INT
)
BEGIN
    DECLARE v_price INT;
    DECLARE v_stock INT;
    DECLARE v_discount INT;
    DECLARE v_total INT;
    DECLARE v_cashback INT;

    -- Check stock availability
    SELECT price, stock, discount INTO v_price, v_stock, v_discount
    FROM products
    WHERE product_id = p_product_id;

    IF v_stock < p_qty THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient stock available';
    ELSE
        -- Reduce stock
        UPDATE products
        SET stock = stock - p_qty
        WHERE product_id = p_product_id;

        -- Apply discount
        SET v_price = v_price - (v_price * v_discount / 100);

        -- Calculate total with GST (18%)
        SET v_total = (v_price * p_qty);
        SET v_total = v_total + (v_total * 18 / 100);

        -- Assign random cashback between 0 and 100
        SET v_cashback = FLOOR(RAND() * 101);

        -- Insert into orders
        INSERT INTO orders(customer_id, product_id, qty, total_price, cashback)
        VALUES(p_customer_id, p_product_id, p_qty, v_total, v_cashback);
    END IF;
END$$

DELIMITER ;
