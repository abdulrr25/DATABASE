
-- Online Shopping Database Setup


-- Drop tables if they already exist
DROP TABLE IF EXISTS order_log;
DROP TABLE IF EXISTS shop_orders;
DROP TABLE IF EXISTS shop_products;

-- ============================================================
-- 1. Create Tables
-- ============================================================

CREATE TABLE shop_orders (
    order_id INT PRIMARY KEY,
    product_id INT,
    qty INT,
    status VARCHAR(20) DEFAULT 'PLACED'
);

CREATE TABLE shop_products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50),
    stock INT
);

CREATE TABLE order_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    action VARCHAR(20),
    log_date DATE DEFAULT CURDATE()
);

-- ============================================================
-- 2. Procedures
-- ============================================================

DELIMITER $$

-- 8.0.1 Cancel Order
CREATE PROCEDURE cancel_order(IN p_order_id INT)
BEGIN
    DECLARE v_product_id INT;
    DECLARE v_qty INT;

    SELECT product_id, qty INTO v_product_id, v_qty
    FROM shop_orders WHERE order_id = p_order_id;

    -- Update status
    UPDATE shop_orders SET status = 'CANCELLED'
    WHERE order_id = p_order_id;

    -- Add cancelled quantity back to stock
    UPDATE shop_products SET stock = stock + v_qty
    WHERE product_id = v_product_id;

    -- Log action
    INSERT INTO order_log(order_id, action) VALUES(p_order_id, 'CANCELLED');
END$$

-- 8.0.2 Place Order
CREATE PROCEDURE place_order(IN p_order_id INT, IN p_product_id INT, IN p_qty INT)
BEGIN
    -- Update status
    UPDATE shop_orders SET status = 'PLACED', qty = p_qty, product_id = p_product_id
    WHERE order_id = p_order_id;

    -- Reduce stock
    UPDATE shop_products SET stock = stock - p_qty
    WHERE product_id = p_product_id;

    -- Log action
    INSERT INTO order_log(order_id, action) VALUES(p_order_id, 'PLACED');
END$$

-- 8.0.3 Update Order Quantity
CREATE PROCEDURE update_order_qty(IN p_order_id INT, IN p_new_qty INT)
BEGIN
    DECLARE v_old_qty INT;
    DECLARE v_product_id INT;

    SELECT qty, product_id INTO v_old_qty, v_product_id
    FROM shop_orders WHERE order_id = p_order_id;

    -- Adjust stock (return old qty, subtract new qty)
    UPDATE shop_products
    SET stock = stock + v_old_qty - p_new_qty
    WHERE product_id = v_product_id;

    -- Update order qty
    UPDATE shop_orders SET qty = p_new_qty WHERE order_id = p_order_id;

    -- Log action
    INSERT INTO order_log(order_id, action) VALUES(p_order_id, 'UPDATED');
END$$

-- 8.0.4 Add New Product
CREATE PROCEDURE add_product(IN p_product_id INT, IN p_name VARCHAR(50), IN p_stock INT)
BEGIN
    INSERT INTO shop_products(product_id, product_name, stock)
    VALUES(p_product_id, p_name, p_stock);
END$$

-- 8.0.5 Get All Orders for a Product
CREATE PROCEDURE get_orders_for_product(IN p_product_id INT)
BEGIN
    SELECT * FROM shop_orders WHERE product_id = p_product_id;
END$$

DELIMITER ;

-- ============================================================
-- 3. User Defined Functions (UDFs)
-- ============================================================

DELIMITER $$

-- 8.1 Check Status Before Cancelling
CREATE FUNCTION check_order_status(p_order_id INT) RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE v_status VARCHAR(20);
    SELECT status INTO v_status FROM shop_orders WHERE order_id = p_order_id;

    IF v_status = 'CANCELLED' THEN
        RETURN 'Order already cancelled';
    ELSEIF v_status = 'PLACED' THEN
        RETURN 'Order can be cancelled';
    END IF;
    RETURN 'Unknown status';
END$$

-- 8.2 Total Cancelled Orders for a Product
CREATE FUNCTION product_cancel_count(p_product_id INT) RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count
    FROM shop_orders WHERE product_id = p_product_id AND status = 'CANCELLED';
    RETURN v_count;
END$$

-- 8.3 Get Product Stock After Cancellation
CREATE FUNCTION get_stock(p_product_id INT) RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_stock INT;
    SELECT stock INTO v_stock FROM shop_products WHERE product_id = p_product_id;
    RETURN v_stock;
END$$

-- 8.4 Total Cancelled Quantity of a Product
CREATE FUNCTION product_cancelled_qty(p_product_id INT) RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_qty INT;
    SELECT SUM(qty) INTO v_qty
    FROM shop_orders WHERE product_id = p_product_id AND status = 'CANCELLED';
    RETURN IFNULL(v_qty,0);
END$$

-- 8.5a First Action of an Order
CREATE FUNCTION first_order_action(p_order_id INT) RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE v_action VARCHAR(20);
    SELECT action INTO v_action
    FROM order_log WHERE order_id = p_order_id ORDER BY log_id ASC LIMIT 1;
    RETURN v_action;
END$$

-- 8.5b Last Action of an Order
CREATE FUNCTION last_order_action(p_order_id INT) RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE v_action VARCHAR(20);
    SELECT action INTO v_action
    FROM order_log WHERE order_id = p_order_id ORDER BY log_id DESC LIMIT 1;
    RETURN v_action;
END$$

-- 8.6 Check if Product is Out of Stock
CREATE FUNCTION is_out_of_stock(p_product_id INT) RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE v_stock INT;
    SELECT stock INTO v_stock FROM shop_products WHERE product_id = p_product_id;
    IF v_stock <= 0 THEN
        RETURN 'OUT OF STOCK';
    ELSE
        RETURN 'AVAILABLE';
    END IF;
END$$

-- 8.7 Get Current Order Status
CREATE FUNCTION get_order_status(p_order_id INT) RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE v_status VARCHAR(20);
    SELECT status INTO v_status FROM shop_orders WHERE order_id = p_order_id;
    RETURN v_status;
END$$

-- 8.8 Check if Order Can Be Cancelled
CREATE FUNCTION can_cancel(p_order_id INT) RETURNS VARCHAR(30)
DETERMINISTIC
BEGIN
    DECLARE v_status VARCHAR(20);
    SELECT status INTO v_status FROM shop_orders WHERE order_id = p_order_id;
    IF v_status = 'PLACED' THEN
        RETURN 'Yes, can cancel';
    ELSE
        RETURN 'No, cannot cancel';
    END IF;
END$$

-- 8.9 Days Since Order Placement
CREATE FUNCTION days_since_order(p_order_id INT) RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_days INT;
    DECLARE v_date DATE;
    SELECT log_date INTO v_date
    FROM order_log WHERE order_id = p_order_id ORDER BY log_id ASC LIMIT 1;

    SET v_days = DATEDIFF(CURDATE(), v_date);
    RETURN v_days;
END$$

DELIMITER ;

-- 