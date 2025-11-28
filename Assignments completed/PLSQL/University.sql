DELIMITER $$

CREATE PROCEDURE promote_students(
    IN p_course_id INT
)
BEGIN
    -- Promote all students who passed
    UPDATE student_academic
    SET semester = semester + 1
    WHERE course_id = p_course_id
      AND marks >= 50;
END $$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE assign_random_batches()
BEGIN
    UPDATE student_academic
    SET batch = ELT(FLOOR(1 + (RAND() * 3)), 'A', 'B', 'C');
END $$

DELIMITER ;
