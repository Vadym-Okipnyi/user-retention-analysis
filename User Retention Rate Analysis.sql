SELECT * 
FROM cohort_users_raw LIMIT 10;

SELECT * 
FROM
cohort_events_raw LIMIT 10;

-- ОЧИЩЕННЯ ТА ПЕРЕТВОРЕННЯ ДАТИ ДЛЯ cohort_users_raw -- 

WITH users_clean AS (
SELECT
    user_id,
    promo_signup_flag,
    signup_datetime,
    TO_DATE(
        LPAD(split_part(d,'-',1),2,'0') || '-' ||
        LPAD(split_part(d,'-',2),2,'0') || '-' ||
        split_part(d,'-',3),
        'DD-MM-YY'
    )::timestamp AS signup_timestamp
FROM (
SELECT *,
       REPLACE(REPLACE(SPLIT_PART(TRIM(signup_datetime),' ',1),'.','-'),'/','-') AS d
FROM cohort_users_raw
) t
)
SELECT *
FROM users_clean;

-- ОЧИЩЕННЯ ТА ПЕРЕТВОРЕННЯ ДАТИ ДЛЯ cohort_events_raw --

WITH events_clean AS (
SELECT
    user_id,
    event_type,
    TO_DATE(
        LPAD(split_part(ed,'-',1),2,'0') || '-' ||
        LPAD(split_part(ed,'-',2),2,'0') || '-' ||
        split_part(ed,'-',3),
        'DD-MM-YY'
    )::timestamp AS event_timestamp
FROM (
SELECT *,
       REPLACE(REPLACE(SPLIT_PART(TRIM(event_datetime),' ',1),'.','-'),'/','-') AS ed
FROM cohort_events_raw
) f
)
SELECT *
FROM events_clean;

-- ОБЄДНАННЯ ТА ФІЛЬТРАЦІЯ events_clean ТА users_clean --

WITH users_clean AS (
SELECT
    user_id,
    promo_signup_flag,
    signup_datetime,
    TO_DATE(
        LPAD(split_part(d,'-',1),2,'0') || '-' ||
        LPAD(split_part(d,'-',2),2,'0') || '-' ||
        split_part(d,'-',3),
        'DD-MM-YY'
    )::timestamp AS signup_timestamp
FROM (
SELECT *,
       REPLACE(REPLACE(SPLIT_PART(TRIM(signup_datetime),' ',1),'.','-'),'/','-') AS d
FROM cohort_users_raw
) t
),
events_clean AS 
(
SELECT
    user_id,
    event_type,
    TO_DATE(
        LPAD(split_part(ed,'-',1),2,'0') || '-' ||
        LPAD(split_part(ed,'-',2),2,'0') || '-' ||
        split_part(ed,'-',3),
        'DD-MM-YY'
    )::timestamp AS event_timestamp
FROM (
SELECT *,
       REPLACE(REPLACE(SPLIT_PART(TRIM(event_datetime),' ',1),'.','-'),'/','-') AS ed
FROM cohort_events_raw
) f
),
user_activity AS
(
SELECT 
u.user_id,
u.promo_signup_flag,
DATE_TRUNC('month', signup_timestamp)::date AS cohort_month,
DATE_TRUNC('month', event_timestamp)::date AS activity_month,
(
(DATE_PART('year', DATE_TRUNC('month', event_timestamp)::date) 
- DATE_PART('year', DATE_TRUNC('month', signup_timestamp)::date)) * 12 +
(DATE_PART('month', DATE_TRUNC('month', event_timestamp)::date)
- DATE_PART('month', DATE_TRUNC('month', signup_timestamp)::date))
)::int AS month_offset
FROM users_clean u
JOIN events_clean e
ON (u.user_id = e.user_id)
WHERE 
u.signup_timestamp IS NOT NULL
AND e.event_timestamp IS NOT NULL
AND e.event_type IS NOT NULL
AND e.event_type <> 'test_event'
)
SELECT
promo_signup_flag,
cohort_month,
month_offset,
COUNT(DISTINCT user_id) AS users_total
FROM user_activity
WHERE activity_month BETWEEN '2025-01-01' AND '2025-06-01'
GROUP BY 
promo_signup_flag,
cohort_month,
month_offset
ORDER BY 
promo_signup_flag,
cohort_month,
month_offset

---------------------------------

