-- =====================================================================
-- Project: 30-Day Readmissions and Length of Stay (5 Indiana hospitals)
-- File:    project_analysis.sql  (Session 10C: analysis)
-- Author:  Festus Segun Ajiboye
-- Data:    Synthetic data; no real patient information.
-- Run after: day10_project_setup.sql
-- =====================================================================


-- ---------------------------------------------------------------------
-- Step 1: Clean view that applies all 7 audit decisions (project_audit.sql)
--   Duplicates -> keep one copy (row_number)
--   Orphan patients, unknown hospital -> removed by the inner joins
--   Missing discharge date, impossible dates, missing age -> excluded
--   Messy insurance labels -> cleaned with upper(trim())
-- Expected: 4,951 stays (4,980 raw minus 29 problem rows)
-- ---------------------------------------------------------------------
create or replace view project.clean_admissions as
with numbered as (
    select a.*,
           row_number() over (partition by a.patient_id, a.hospital_id, a.admit_date, a.discharge_date
                              order by a.admission_id) as copy_number
    from project.admissions as a
)
select n.admission_id,
       n.patient_id,
       n.hospital_id,
       h.hospital_name,
       p.age,
       upper(trim(p.insurance_type)) as insurance,
       n.admit_date,
       n.discharge_date,
       n.discharge_date - n.admit_date as los,
       n.discharge_status,
       n.planned
from numbered as n
join project.patients  as p on n.patient_id  = p.patient_id
join project.hospitals as h on n.hospital_id = h.hospital_id
where n.copy_number = 1
  and n.discharge_date is not null
  and n.discharge_date >= n.admit_date
  and p.age is not null;

select count(*) as clean_stays from project.clean_admissions;


-- ---------------------------------------------------------------------
-- Overall 30-day readmission rate (baseline)
-- Expected: denominator 4,591 | numerator 956 | rate 20.8%
-- ---------------------------------------------------------------------
with stays as (
    select *,
           lead(planned) over (partition by patient_id order by admit_date) as next_planned,
           lead(admit_date) over (partition by patient_id order by admit_date) - discharge_date as days_to_next
    from project.clean_admissions
),
index_stays as (
    select *
    from stays
    where discharge_date between '2025-01-01' and '2026-05-31'
      and age >= 18
      and discharge_status not in ('Died', 'Transfer-Acute', 'AMA')
)
select
    count(*) as denominator,
    sum(case when days_to_next between 1 and 30 and next_planned = false then 1 else 0 end) as numerator,
    round(100.0 * sum(case when days_to_next between 1 and 30 and next_planned = false then 1 else 0 end) / count(*), 1) as readmit_rate_pct
from index_stays;


-- ---------------------------------------------------------------------
-- Question 1: Which hospital has the highest 30-day readmission rate?
-- Expected: Westbrook 25.1 | Northside 23.1 | Riverside 19.7 | Southgate 18.8 | Eastview 17.1
-- ---------------------------------------------------------------------
with stays as (
    select *,
           lead(planned) over (partition by patient_id order by admit_date) as next_planned,
           lead(admit_date) over (partition by patient_id order by admit_date) - discharge_date as days_to_next
    from project.clean_admissions
),
index_stays as (
    select *
    from stays
    where discharge_date between '2025-01-01' and '2026-05-31'
      and age >= 18
      and discharge_status not in ('Died', 'Transfer-Acute', 'AMA')
)
select
    hospital_name,
    count(*) as denominator,
    sum(case when days_to_next between 1 and 30 and next_planned = false then 1 else 0 end) as numerator,
    round(100.0 * sum(case when days_to_next between 1 and 30 and next_planned = false then 1 else 0 end) / count(*), 1) as readmit_rate_pct
from index_stays
group by hospital_name
order by readmit_rate_pct desc;


-- ---------------------------------------------------------------------
-- Question 2: Does the readmission rate differ by insurance type?
-- Expected: MEDICAID 29.8 | MEDICARE 19.4 | SELF-PAY 17.9 | PRIVATE 17.8
-- ---------------------------------------------------------------------
with stays as (
    select *,
           lead(planned) over (partition by patient_id order by admit_date) as next_planned,
           lead(admit_date) over (partition by patient_id order by admit_date) - discharge_date as days_to_next
    from project.clean_admissions
),
index_stays as (
    select *
    from stays
    where discharge_date between '2025-01-01' and '2026-05-31'
      and age >= 18
      and discharge_status not in ('Died', 'Transfer-Acute', 'AMA')
)
select
    insurance,
    count(*) as denominator,
    sum(case when days_to_next between 1 and 30 and next_planned = false then 1 else 0 end) as numerator,
    round(100.0 * sum(case when days_to_next between 1 and 30 and next_planned = false then 1 else 0 end) / count(*), 1) as readmit_rate_pct
from index_stays
group by insurance
order by readmit_rate_pct desc;


-- ---------------------------------------------------------------------
-- Question 3: Which hospital has the longest average length of stay?
-- Uses all clean stays (length of stay is not limited to index stays)
-- Expected: Eastview 5.9 (median 6) | Riverside 4.8 | Southgate 4.2 | Northside 4.0 | Westbrook 4.0
-- ---------------------------------------------------------------------
select hospital_name,
       count(*) as stays,
       round(avg(los), 1) as avg_los,
       percentile_cont(0.5) within group (order by los) as median_los
from project.clean_admissions
group by hospital_name
order by avg_los desc;
