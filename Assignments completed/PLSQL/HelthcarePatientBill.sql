DELIMITER $$

CREATE FUNCTION calc_bill(p_patient_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_doctor_fee INT;
    DECLARE v_medicine_fee INT;
    DECLARE v_insurance VARCHAR(3);
    DECLARE v_total DECIMAL(10,2);

    -- Fetch fees from treatment table
    SELECT doctor_fee, medicine_fee
    INTO v_doctor_fee, v_medicine_fee
    FROM treatment
    WHERE patient_id = p_patient_id;

    -- Fetch insurance status
    SELECT insurance
    INTO v_insurance
    FROM patients
    WHERE patient_id = p_patient_id;

    -- Total amount
    SET v_total = v_doctor_fee + v_medicine_fee;

    -- Apply insurance discount 20%
    IF v_insurance = 'YES' THEN
        SET v_total = v_total - (v_total * 0.20);
    END IF;

    RETURN v_total;
END$$

DELIMITER ;
