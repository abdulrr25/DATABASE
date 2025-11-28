DELIMITER $$

CREATE PROCEDURE apply_discount(
    IN p_category VARCHAR(30),
    IN p_percent INT
)
BEGIN
    DECLARE exit handler for sqlexception
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    -- 1. Update product prices
    UPDATE product_catalog
    SET price = price - (price * p_percent / 100)
    WHERE category = p_category;

    -- 2. Insert into history table
    INSERT INTO discount_history(category, percent)
    VALUES(p_category, p_percent);

    COMMIT;
END $$

DELIMITER ;
