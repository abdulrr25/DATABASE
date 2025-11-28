DELIMITER $$

CREATE PROCEDURE process_salary(IN p_emp_id INT)
BEGIN
    DECLARE v_basic INT;
    DECLARE v_allowance INT;
    DECLARE v_deduction INT;
    DECLARE v_net_salary INT;

    -- Step 2: Fetch salary details
    SELECT basic, allowance, deduction 
    INTO v_basic, v_allowance, v_deduction
    FROM employees
    WHERE emp_id = p_emp_id;

    -- Step 3: Calculate net salary
    SET v_net_salary = v_basic + v_allowance - v_deduction;

    -- Step 4: Insert into payroll_history
    INSERT INTO payroll_history(emp_id, net_salary)
    VALUES(p_emp_id, v_net_salary);

END$$

DELIMITER ;
