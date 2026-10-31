DROP SCHEMA IF EXISTS project CASCADE;
CREATE SCHEMA project;

CREATE TABLE project.hospitals (
    hospital_id   INT PRIMARY KEY,
    hospital_name VARCHAR(50),
    city          VARCHAR(30)
);
INSERT INTO project.hospitals VALUES
(1, 'Riverside General',  'Indianapolis'),
(2, 'Northside Medical',  'Carmel'),
(3, 'Eastview Community', 'Fishers'),
(4, 'Westbrook Health',   'Avon'),
(5, 'Southgate Regional', 'Greenwood');

CREATE TABLE project.patients (
    patient_id     INT PRIMARY KEY,
    age            INT,
    sex            CHAR(1),
    insurance_type VARCHAR(20)
);
INSERT INTO project.patients
SELECT 1000 + g,
       CASE WHEN g % 50 = 0 THEN 10 + g % 8 ELSE 18 + (g * 37) % 73 END,
       CASE WHEN g % 2 = 0 THEN 'F' ELSE 'M' END,
       CASE WHEN g % 17 = 0 THEN 'Self-pay'
            WHEN g % 50 <> 0 AND 18 + (g * 37) % 73 >= 65 THEN 'Medicare'
            WHEN g % 3 = 1 THEN 'Medicaid'
            ELSE 'Private' END
FROM generate_series(1, 2000) AS g;

CREATE TABLE project.admissions (
    admission_id     SERIAL PRIMARY KEY,
    patient_id       INT,
    hospital_id      INT,
    admit_date       DATE,
    discharge_date   DATE,
    discharge_status VARCHAR(20),
    planned          BOOLEAN
);
INSERT INTO project.admissions (patient_id, hospital_id, admit_date, discharge_date, discharge_status, planned)
SELECT p.patient_id,
       h.h_id,
       d.adm,
       d.adm + d.los,
       CASE WHEN k = p.n AND p.g % 40 = 0 THEN 'Died'
            WHEN (p.g + k) % 41 = 0 THEN 'Transfer-Acute'
            WHEN (p.g * 3 + k) % 53 = 0 THEN 'AMA'
            WHEN p.age >= 75 AND (p.g + k) % 5 = 0 THEN 'SNF'
            ELSE 'Home' END,
       (p.g * k) % 19 = 0
FROM (
    SELECT pt.*, pt.patient_id - 1000 AS g, 1 + (pt.patient_id - 1000) % 4 AS n
    FROM project.patients pt
) p
CROSS JOIN generate_series(1, 4) AS k
CROSS JOIN LATERAL (
    SELECT CASE WHEN (p.g + k) % 7 = 0 THEN 1 + (p.g + k) % 5
                WHEN p.g % 10 < 3 THEN 1
                WHEN p.g % 10 < 5 THEN 2
                WHEN p.g % 10 < 7 THEN 3
                WHEN p.g % 10 < 9 THEN 4
                ELSE 5 END AS h_id
) h
CROSS JOIN LATERAL (
    SELECT date '2025-01-01' + (p.g * 53) % 400
             + (k - 1) * (16 + (p.g * 13) % 60
                          - CASE WHEN p.g % 10 IN (7, 8) THEN 8 ELSE 0 END
                          - CASE WHEN p.insurance_type = 'Medicaid' THEN 6 ELSE 0 END) AS adm,
           1 + (p.g * k * 17) % 6
             + CASE WHEN (p.g + k) % 23 = 0 THEN 10 ELSE 0 END
             + CASE h.h_id WHEN 1 THEN 1 WHEN 3 THEN 2 ELSE 0 END
             + CASE WHEN p.age >= 75 THEN 2 ELSE 0 END AS los
) d
WHERE k <= p.n
ORDER BY p.patient_id, k;

DELETE FROM project.admissions WHERE admit_date > '2026-06-30';

-- Planted data-quality problems (part of the exercise)
INSERT INTO project.admissions (patient_id, hospital_id, admit_date, discharge_date, discharge_status, planned)
SELECT patient_id, hospital_id, admit_date, discharge_date, discharge_status, planned
FROM project.admissions
WHERE admission_id IN (101, 702, 1503, 2804, 3905)
ORDER BY admission_id;

INSERT INTO project.admissions (patient_id, hospital_id, admit_date, discharge_date, discharge_status, planned) VALUES
(9001, 1, '2025-03-10', '2025-03-14', 'Home', false),
(9002, 2, '2025-07-21', '2025-07-25', 'Home', false),
(9003, 4, '2025-11-02', '2025-11-05', 'Home', false);

UPDATE project.admissions SET hospital_id = 9 WHERE admission_id IN (450, 2650);
UPDATE project.admissions SET discharge_date = NULL WHERE admission_id IN (55, 610, 1220, 1888, 2402, 3017, 3666, 4210);
UPDATE project.admissions SET discharge_date = admit_date - 2 WHERE admission_id IN (333, 1444, 2555, 3999);
UPDATE project.patients SET age = NULL WHERE patient_id IN (1123, 1456, 1789);
UPDATE project.patients SET insurance_type = 'medicare' WHERE patient_id IN (1072, 1145, 1218);
UPDATE project.patients SET insurance_type = 'Private ' WHERE patient_id IN (1302, 1505);
