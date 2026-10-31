# Hospital Readmissions and Length of Stay (SQL Project)

**Author:** Festus Segun Ajiboye
**Tools:** PostgreSQL, DBeaver
**Data:** Synthetic (computer-generated) data for 5 Indiana hospitals, 2,000 patients and 4,980 admissions. No real patient information is used.

**Status:** In progress. Data-quality audit, analysis and findings are being added.

---

## Project question

How do 30-day readmission rates and length of stay differ across five hospitals and across insurance types?

## Files in this repository

| File | What it does |
|---|---|
| `day10_project_setup.sql` | Builds the project database (hospitals, patients, admissions) |
| `README.md` | This page: project overview and measure specification |

---

## Measure specification: 30-day readmission rate

**1. Unit of analysis:** One hospital stay (an "index stay").

**2. Measurement period:** Stays discharged January 1, 2025 to May 31, 2026. The period stops at May 31 because a stay discharged in June would not have a full 30 days of follow-up data before the data ends on June 30, 2026.

**3. Denominator (who is counted):** Stays for patients aged 18 or older who did not die in hospital, transfer to another acute-care hospital, or leave against medical advice (AMA).

**4. Numerator (who had the event):** Denominator stays followed by an unplanned admission for the same patient 1 to 30 days after discharge.

**5. Exclusions and reasons**

| Exclusion | Reason |
|---|---|
| Died | The patient cannot be readmitted. |
| Transferred to another acute hospital | Care continued at another hospital, so the stay is not a true discharge. |
| Left against medical advice (AMA) | The hospital did not control the discharge. |
| Under 18 | Children's care is measured separately from adults. |
| Planned readmissions | Scheduled care (for example, chemotherapy or surgery) is part of the care plan, not a failure. |

**6. Questions this project answers**
1. Which hospital has the highest 30-day readmission rate?
2. Does the readmission rate differ by insurance type?
3. Which hospital has the longest average length of stay?

**Rate formula:** readmission rate = numerator / denominator x 100
