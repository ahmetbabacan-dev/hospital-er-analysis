-- Get the first 25 rows to check the data
SELECT TOP 25 * FROM visits;

-- Fix the column name typo
EXEC sp_rename 'visits.patient_first_inital',  'patient_first_initial', 'COLUMN';

-- Count null values for each column
SELECT
	SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END) AS date_null,
	SUM(CASE WHEN patient_id IS NULL THEN 1 ELSE 0 END) AS patient_id_null,
	SUM(CASE WHEN patient_gender IS NULL THEN 1 ELSE 0 END) AS patient_gender_null,
	SUM(CASE WHEN patient_age IS NULL THEN 1 ELSE 0 END) AS patient_age_null,
	SUM(CASE WHEN patient_sat_score IS NULL THEN 1 ELSE 0 END) AS patient_sat_score_null,
	SUM(CASE WHEN patient_first_initial IS NULL THEN 1 ELSE 0 END) AS patient_first_inital_null,
	SUM(CASE WHEN patient_last_name IS NULL THEN 1 ELSE 0 END) AS patient_last_name_null,
	SUM(CASE WHEN patient_race IS NULL THEN 1 ELSE 0 END) AS patient_race_null,
	SUM(CASE WHEN patient_admin_flag IS NULL THEN 1 ELSE 0 END) AS patient_admin_flag_null,
	SUM(CASE WHEN patient_waittime IS NULL THEN 1 ELSE 0 END) AS patient_waittime_null,
	SUM(CASE WHEN department_referral IS NULL THEN 1 ELSE 0 END) AS department_referral_null
FROM visits;

-- Create Departments table
CREATE TABLE departments (
    department_id INT IDENTITY(1,1) PRIMARY KEY,
    department_name VARCHAR(50) UNIQUE
);

-- Insert unique departments
INSERT INTO departments (department_name)
SELECT DISTINCT department_referral FROM visits;


-- Create patients table
CREATE TABLE patients (
    patient_id VARCHAR(20) PRIMARY KEY, -- data type should be the same as the visits.patient_id table to be a FK
    patient_gender VARCHAR(2),
    patient_age SMALLINT,
    patient_first_initial CHAR(1),
    patient_last_name VARCHAR(50),
    patient_race VARCHAR(50)
);

-- Insert unique patient information
INSERT INTO patients (
    patient_id,
    patient_gender,
    patient_age,
    patient_first_initial,
    patient_last_name,
    patient_race
)
SELECT DISTINCT 
    patient_id,
    patient_gender,
    patient_age,
    patient_first_initial,
    patient_last_name,
    patient_race
FROM visits;

-- Add the null department_referral_id column to the fact table
ALTER TABLE visits
ADD department_referral_id INT NULL;

-- Add the department IDs
UPDATE visits
SET visits.department_referral_id = departments.department_id
FROM visits
JOIN departments ON visits.department_referral = departments.department_name;

-- Drop the redundant columns in the fact table
ALTER TABLE visits
DROP COLUMN patient_gender,
    patient_age,
    patient_sat_score,
    patient_first_initial,
    patient_last_name,
    patient_race,
    department_referral;

-- Add the foreign keys to the columns
ALTER TABLE visits
ADD CONSTRAINT visits_patient_id_FK
FOREIGN KEY (patient_id)
REFERENCES patients(patient_id);

ALTER TABLE visits
ADD CONSTRAINT visits_department_referral_id_FK
FOREIGN KEY (department_referral_id)
REFERENCES departments(department_id);

-- Analysis queries
-- Total patients
SELECT COUNT(*) FROM patients AS num_of_patients;

-- Visit year, month, days
SELECT
    date,
    YEAR(date) AS visit_year,
    DATENAME(MONTH, date) AS visit_month,
    DATENAME(WEEKDAY,date) AS visit_day
FROM visits;

-- Visits by gender
SELECT patient_gender, COUNT(*) AS total_patients
FROM visits
JOIN patients ON visits.patient_id = patients.patient_id
GROUP BY patient_gender
ORDER BY total_patients DESC;

-- Visits by race
SELECT patient_race, COUNT(*) AS total_patients
FROM visits
JOIN patients ON visits.patient_id = patients.patient_id
GROUP BY patient_race
ORDER BY total_patients DESC;

-- Average wait times of the departments
SELECT department_name, AVG(patient_waittime) AS avg_waittime
FROM visits
JOIN departments ON visits.department_referral_id = departments.department_id
GROUP BY department_name
ORDER BY avg_waittime DESC;

-- Categorize wait times
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

-- Admission rates by department
SELECT
    department_name,
    ROUND(
        CAST(
            SUM(
                CAST(
                    patient_admin_flag AS INT
                    )
                ) AS FLOAT
            )
          / COUNT(*), 4) AS admission_rate
FROM visits
JOIN departments ON visits.department_referral_id = departments.department_id
GROUP BY department_name
ORDER BY admission_rate DESC;

-- Average satisfaction by department
SELECT department_name, AVG(patient_sat_score) AS avg_satisfaction_score
FROM visits
JOIN departments ON visits.department_referral_id = departments.department_id
GROUP BY department_name
ORDER BY avg_satisfaction_score DESC;

-- Does wait time impact satisfaction?
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

-- Identify departments with an average wait time longer than the overall average
WITH department_wait_times AS (
    SELECT department_name, AVG(patient_waittime) AS avg_wait_time
    FROM visits
    JOIN departments ON visits.department_referral_id = departments.department_id
    GROUP BY department_name
)
SELECT department_name, avg_wait_time AS has_longer_than_avg_waittime
FROM department_wait_times
WHERE avg_wait_time > (SELECT AVG(patient_waittime) FROM visits);