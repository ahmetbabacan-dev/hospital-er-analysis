## Hospital Emergency Room Records Analysis - Project Background

**Role:** Healthcare Data Analyst

**Tools:** SQL Server (T-SQL), Looker Studio (Dashboarding)

**Context:** This project analyzes patient records from a busy Hospital Emergency Room to identify bottlenecks in patient flow and drivers of low patient satisfaction. Using a synthetic dataset representing 9,216 patient visits, the goal was to provide the Hospital Administration with actionable insights regarding staffing optimization, wait times, and demographic trends.

The analysis adopts a hybrid approach: Looker Studio is used for real-time monitoring of patient volume and demographics, while SQL is used to investigate the root causes of wait time inefficiencies.

**Links to Project Files:**
* Dataset used in the project: https://data.world/markbradbourne/rwfd-real-world-fake-data/workspace/file?filename=Hospital+ER.csv
* Interactive Dashboard: https://lookerstudio.google.com/s/oEsq3Yu0Gic
* [SQL Script](https://github.com/ahmetbabacan-dev/hospital-er-analysis/blob/main/hospital.sql)

**Data Structure**
* The original raw dataset contains one fact table that contains data about each visit, which is then normalized into 3 tables using SQL Server: ```visits``` (fact table), ```departments```, and ```patients```.
* ```visits``` Columns:
  
  <img width="213" height="110" alt="visits_columns" src="https://github.com/user-attachments/assets/1ff39cf1-581c-43e0-acb4-331c59f503e4" />

* ```departments``` Columns:

  <img width="226" height="37" alt="departments_columns" src="https://github.com/user-attachments/assets/cdfca209-6181-4ac7-88bc-d2ea5c3a4f0d" />

* ```patients``` Columns:

  <img width="225" height="128" alt="patients_columns" src="https://github.com/user-attachments/assets/d3537bcc-51ab-465e-bf50-0e380c4c1150" />

## Executive Summary

### Overview of Findings

The Emergency Room is currently operating with an average wait time of 35.26 minutes and an average satisfaction score of 4.99/10. The data reveals a systemic capacity issue where nearly 60% of patients are waiting longer than the 30-minute target. While "General Practice" receives the highest volume of patients, operational inefficiencies are present across all departments, with particular bottlenecks occurring during early morning hours (3:00 AM – 7:00 AM).

**Operational Snapshot:**

<img width="1361" height="764" alt="hospital_dashboard" src="https://github.com/user-attachments/assets/43e4f168-a542-4873-b0b2-a88a091b1af2" />

## Insights Deep Dive

### Category 1: Departmental Efficiency

* **Objective:** Determine if specific departments are driving the high average wait times.
* **Analysis:** I calculated the average wait time grouped by department.
* **Finding:** The inefficiency is systemic, not departmental. There is a negligible difference in wait times across departments. "Physiotherapy" and "Neurology" have the highest wait times (36 mins), but even the most efficient departments (General Practice) average 34 mins. This suggests the bottleneck exists at the Triage/Registration level, rather than within specific specialty units.

<details>
<summary><b>View SQL Query</b></summary>
  
```sql
SELECT department_name, AVG(patient_waittime) AS avg_waittime
FROM visits
JOIN departments ON visits.department_referral_id = departments.department_id
GROUP BY department_name
ORDER BY avg_waittime DESC;
```
</details>
<img width="213" height="174" alt="avg_dpt_waittimes" src="https://github.com/user-attachments/assets/2d05f71f-81d9-46e3-b8a2-b4c5483181df" />


### Category 2: Volume Analysis (The 30-Minute Threshold)

* **Objective:** Quantify how many patients are missing the "Standard of Care" target (seen within 30 minutes).
* **Analysis:** I segmented visits into "Long Wait" (>30 mins) and "Short Wait" (≤30 mins).
* **Finding:** 59.3% of all patients (5,467 out of 9,216) fall into the "Long Wait" category. This confirms that the average wait time of 35 minutes is not skewed by a few outliers, but is the standard experience for the majority of patients.

<details>
<summary><b>View SQL Query</b></summary>

  ```sql
SELECT
    CASE
        WHEN patient_waittime > 30 THEN 'Long Wait'
        ELSE 'Short Wait'
    END AS wait_category,
    COUNT(*) AS total
FROM visits
GROUP BY 
    CASE
        WHEN patient_waittime > 30 THEN 'Long Wait'
        ELSE 'Short Wait'
    END;
```
</details>
<img width="158" height="60" alt="long_short_waittimes" src="https://github.com/user-attachments/assets/03555be4-0ef8-4de2-8416-28101d8a09c0" />

### Category 3: Satisfaction Drivers

* **Objective:** Correlate wait times with patient satisfaction scores to find the "tipping point."
* **Analysis:** Grouped wait times into 15-minute bands and calculated average satisfaction.
* **Finding:** There is a clear threshold at 15 minutes.
Patients seen within 0-15 minutes report an average score of 5/10.
Once the wait exceeds 15 minutes (16-30 min bucket), the score drops to 4/10 and plateaus there for waits over 30 minutes.
* **Note:** The overall low satisfaction scores (maxing at 5) suggest that even fast service is not delighting patients, indicating potential issues with care quality or facility comfort.

<details>
<summary><b>View SQL Query</b></summary>

```sql
SELECT
    CASE
        WHEN patient_waittime <= 15 THEN '0-15 min'
        WHEN patient_waittime <= 30 THEN '16-30 min'
        ELSE '+30 min'
    END AS wait_time_band,
    AVG(patient_sat_score) as avg_satisfaction_score
FROM visits
GROUP BY 
    CASE
        WHEN patient_waittime <= 15 THEN '0-15 min'
        WHEN patient_waittime <= 30 THEN '16-30 min'
        ELSE '+30 min'
    END
ORDER BY wait_time_band;
```
</details>
<img width="249" height="80" alt="waittime_band_avg_sat" src="https://github.com/user-attachments/assets/10282535-023a-462d-b48f-4cbd68655403" />

## Recommendations

Based on the insights above, we recommend the Hospital Administration consider the following:

* **Address the Triage Bottleneck:** Since wait times are high (34-36 mins) across all departments, the issue is likely occurring at the front desk or triage. Implementing a "Fast Track" triage for minor ailments could reduce the bottleneck.
* **Staffing Adjustments for Night Shifts:** The Dashboard Heatmap shows a critical spike in wait times between 3 AM and 7 AM. Staffing schedules should be audited to ensure sufficient coverage during this surprisingly high-latency window.
* **Investigate Low Baseline Satisfaction:** Even patients with short wait times (<15 mins) only rate their experience a 5/10. Management should conduct qualitative surveys to understand why "fast" patients are still relatively unsatisfied (e.g., doctor manner, facility cleanliness).
* **Target the 15-Minute Window:** To improve satisfaction scores, the operational goal should be aggressively moved from "under 30 minutes" to "under 15 minutes," as this is where the satisfaction drop-off occurs.

## Assumptions and Caveats

* **Data Origin:** This analysis uses a synthetic dataset. Real-world patterns (e.g., seasonality, flu season spikes) may not be fully represented.
* **Satisfaction Metric:** The satisfaction score is an integer between 1-10. The analysis assumes this is a linear scale.
* **Wait Time Definition:** "Wait Time" is assumed to be the duration from check-in to being seen by a doctor. It does not account for time spent after seeing the doctor.
