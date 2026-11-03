-- =====================================================================
-- Project: 30-Day Readmissions and Length of Stay (5 Indiana hospitals)
-- File:    project_audit.sql  (Session 10B: data-quality audit)
-- Author:  Festus Segun Ajiboye
-- Data:    Synthetic data; no real patient information.
--
-- Rule used for every decision:
--   If the correct value is obvious -> FIX it in the query (raw data untouched).
--   If the correct value is unknown -> EXCLUDE the record and REPORT it. Never guess.
-- =====================================================================


-- Check 1: Duplicate stays (same patient, hospital, admit and discharge date)
-- Found: 5 stays recorded twice (5 extra rows)
-- Decision: keep one copy of each; remove the 5 extra copies (avoids double counting)
select patient_id, hospital_id, admit_date, discharge_date, count(*) as times_recorded
from project.admissions
group by patient_id, hospital_id, admit_date, discharge_date
having count(*) > 1;


-- Check 2: Orphan stays (patient ID not in the patient list)
-- Found: 3 stays (patient IDs 9001, 9002, 9003)
-- Decision: exclude and report (no age or insurance, so the measure rules cannot be applied)
select a.admission_id, a.patient_id
from project.admissions as a
left join project.patients as p
    on a.patient_id = p.patient_id
where p.patient_id is null;


-- Check 3: Unknown hospital (hospital ID not in the hospital list)
-- Found: 2 stays (hospital_id = 9)
-- Decision: exclude and report (cannot be assigned to any hospital)
select a.admission_id, a.hospital_id
from project.admissions as a
left join project.hospitals as h
    on a.hospital_id = h.hospital_id
where h.hospital_id is null;


-- Check 4: Missing discharge date
-- Found: 8 stays
-- Decision: exclude and report (length of stay and the 30-day window cannot be calculated)
select admission_id, patient_id, admit_date, discharge_date
from project.admissions
where discharge_date is null;


-- Check 5: Impossible dates (discharged before admitted)
-- Found: 4 stays
-- Decision: exclude and report (cannot tell which date is wrong)
select admission_id, admit_date, discharge_date
from project.admissions
where discharge_date < admit_date;


-- Check 6: Missing age
-- Found: 3 patients
-- Decision: exclude their stays and report (the "18 or older" rule cannot be applied)
select patient_id, age, insurance_type
from project.patients
where age is null;


-- Check 7: Messy insurance labels ("medicare" and "Private " with a trailing space)
-- Found: 5 patients (6 labels instead of 4)
-- Decision: fix in the query with upper(trim(insurance_type))
select '[' || insurance_type || ']' as label_with_brackets,
       length(insurance_type) as num_characters,
       count(*) as patients
from project.patients
group by insurance_type
order by insurance_type;

-- Cleaned version: 4 labels (MEDICAID 417, MEDICARE 655, PRIVATE 811, SELF-PAY 117)
select upper(trim(insurance_type)) as insurance_clean,
       count(*) as patients
from project.patients
group by 1
order by 1;
