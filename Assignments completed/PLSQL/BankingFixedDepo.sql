DELIMITER $$

CREATE PROCEDURE calculate_fd_interest(
    IN p_fd_id INT
)
BEGIN
    DECLARE v_principal INT;
    DECLARE v_rate INT;
    DECLARE v_years INT;
    DECLARE v_maturity INT;

    DECLARE exit handler FOR sqlexception
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    -- 1. Fetch FD details
    SELECT principal, rate, years
    INTO v_principal, v_rate, v_years
    FROM fixed_deposit
    WHERE fd_id = p_fd_id;

    -- 2. Calculate maturity amount
    SET v_maturity = v_principal + (v_principal * v_rate * v_years);

    -- 3. Insert into history table
    INSERT INTO fd_history(fd_id, maturity_amount)
    VALUES(p_fd_id, v_maturity);

    COMMIT;

END $$

DELIMITER ;
