DELIMITER $$

CREATE PROCEDURE transfer_funds(
    IN p_from_acc INT,
    IN p_to_acc INT,
    IN p_amount INT
)
BEGIN
    DECLARE v_balance INT;
    DECLARE exit handler for sqlexception 
    BEGIN
        -- Any error → rollback
        ROLLBACK;
    END;

    -- Start transaction
    START TRANSACTION;

    -- 1. Check sender's balance
    SELECT balance INTO v_balance
    FROM accounts
    WHERE acc_no = p_from_acc
    FOR UPDATE;

    IF v_balance < p_amount THEN
        -- Insufficient balance → rollback
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient balance!';
    END IF;

    -- 2. Deduct from sender
    UPDATE accounts
    SET balance = balance - p_amount
    WHERE acc_no = p_from_acc;

    -- 3. Add to receiver
    UPDATE accounts
    SET balance = balance + p_amount
    WHERE acc_no = p_to_acc;

    -- 4. Insert into transaction history
    INSERT INTO transaction_history(from_acc, to_acc, amount)
    VALUES(p_from_acc, p_to_acc, p_amount);

    -- Commit if everything is OK
    COMMIT;

END$$

DELIMITER ;
