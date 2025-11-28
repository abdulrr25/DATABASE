DELIMITER $$

CREATE PROCEDURE book_ticket(IN p_passenger VARCHAR(50), IN p_train_id INT)
BEGIN
    DECLARE v_total INT;
    DECLARE v_booked INT;
    DECLARE v_seat_no INT;

    -- Step 1: Get seat info
    SELECT total_seats, booked_seats INTO v_total, v_booked
    FROM trains
    WHERE train_id = p_train_id;

    -- Step 2: Check seat availability
    IF v_booked < v_total THEN
        -- Step 3: Assign seat
        SET v_seat_no = v_booked + 1;

        -- Step 4: Insert confirmed ticket
        INSERT INTO tickets(passenger_name, train_id, seat_no, status)
        VALUES(p_passenger, p_train_id, v_seat_no, 'CONFIRMED');

        -- Step 5: Update booked seats
        UPDATE trains
        SET booked_seats = booked_seats + 1
        WHERE train_id = p_train_id;

    ELSE
        -- Step 6: Add to waiting list
        INSERT INTO waiting_list(passenger_name, train_id)
        VALUES(p_passenger, p_train_id);
    END IF;

END$$

DELIMITER ;
