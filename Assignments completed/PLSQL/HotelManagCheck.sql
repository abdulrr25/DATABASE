DELIMITER $$

CREATE PROCEDURE check_in(
    IN p_guest_id INT,
    IN p_room_no INT
)
BEGIN
    DECLARE v_status VARCHAR(20);

    DECLARE exit handler FOR sqlexception
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    -- 1. Check current room status
    SELECT status INTO v_status
    FROM rooms
    WHERE room_no = p_room_no
    FOR UPDATE;

    -- If room already occupied → error
    IF v_status <> 'Available' THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Room is already occupied!';
    END IF;

    -- 2. Update room status
    UPDATE rooms
    SET status = 'Occupied'
    WHERE room_no = p_room_no;

    -- 3. Insert into check-in log
    INSERT INTO checkin_log(guest_id, room_no)
    VALUES(p_guest_id, p_room_no);

    COMMIT;

END $$

DELIMITER ;
