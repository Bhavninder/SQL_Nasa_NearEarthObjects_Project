CREATE DATABASE nasa_pbl;
USE nasa_pbl;

CREATE TABLE asteroid_registry (
    asteroid_id INT PRIMARY KEY,
    name VARCHAR(255),
    absolute_magnitude DECIMAL(10, 2),
    is_hazardous TINYINT(1)
);

CREATE TABLE asteroid_approaches (
    approach_id INT AUTO_INCREMENT PRIMARY KEY,
    asteroid_id INT,
    diameter_min_km DECIMAL(10, 5),
    diameter_max_km DECIMAL(10, 5),
    velocity_kph DECIMAL(20, 5),
    miss_distance_km DECIMAL(20, 5),
    CONSTRAINT fk_asteroid_id 
        FOREIGN KEY (asteroid_id) 
        REFERENCES asteroid_registry(asteroid_id)
);

INSERT INTO asteroid_registry (asteroid_id, name, absolute_magnitude, is_hazardous)
SELECT DISTINCT id, name, magnitude, is_hazardous 
FROM temp_asteroids;

INSERT INTO asteroid_approaches (asteroid_id, diameter_min_km, diameter_max_km, velocity_kph, miss_distance_km)
SELECT id, diameter_min_km, diameter_max_km, velocity_kph, miss_distance_km 
FROM temp_asteroids;

SELECT 
    r.name, 
    a.velocity_kph, 
    r.is_hazardous 
FROM asteroid_registry r
JOIN asteroid_approaches a ON r.asteroid_id = a.asteroid_id
LIMIT 10;


-- ==========================================================
-- SECTION 1: EXPLORATORY DATA ANALYSIS (THE BASICS)
-- ==========================================================

-- 1. How many total unique asteroids are recorded in our registry?
SELECT COUNT(*) AS total_asteroids 
FROM asteroid_registry;

-- 2. What is the breakdown of Hazardous vs. Safe asteroids in this dataset?
SELECT is_hazardous, COUNT(*) AS count 
FROM asteroid_registry 
GROUP BY is_hazardous;

-- 3. What is the maximum velocity (speed) recorded among all tracked objects?
SELECT MAX(velocity_kph) AS max_speed_kph 
FROM asteroid_approaches;

-- 4. What are the names of the 5 asteroids that passed closest to Earth?
SELECT r.name, a.miss_distance_km 
FROM asteroid_registry r 
JOIN asteroid_approaches a ON r.asteroid_id = a.asteroid_id 
ORDER BY a.miss_distance_km ASC 
LIMIT 5;


-- ==========================================================
-- SECTION 2: RELATIONAL ANALYSIS (JOIN MASTERY)
-- ==========================================================

-- 5. List the names and absolute magnitudes of all asteroids marked as potentially hazardous.
SELECT r.name, r.absolute_magnitude 
FROM asteroid_registry r 
JOIN asteroid_approaches a ON r.asteroid_id = a.asteroid_id 
WHERE r.is_hazardous = 1;

-- 6. Calculate the average velocity for hazardous vs. non-hazardous asteroids to see if dangerous ones are faster.
SELECT r.is_hazardous, AVG(a.velocity_kph) AS average_velocity 
FROM asteroid_registry r 
JOIN asteroid_approaches a ON r.asteroid_id = a.asteroid_id 
GROUP BY r.is_hazardous;

-- 7. Find the asteroid with the largest estimated diameter in the entire dataset.
SELECT r.name, a.diameter_max_km 
FROM asteroid_registry r 
JOIN asteroid_approaches a ON r.asteroid_id = a.asteroid_id 
ORDER BY a.diameter_max_km DESC 
LIMIT 1;


-- ==========================================================
-- SECTION 3: DATA LOGIC & CHARACTERIZATION
-- ==========================================================

-- 8. Identify all asteroids in the registry that were discovered in the year 2017 using pattern matching.
SELECT name 
FROM asteroid_registry 
WHERE name LIKE '%(2017%)%';

-- 9. Categorize asteroids into 'Small', 'Medium', or 'Large' based on their maximum diameter.
SELECT r.name, a.diameter_max_km,
CASE 
    WHEN a.diameter_max_km < 0.05 THEN 'Small (<50m)'
    WHEN a.diameter_max_km BETWEEN 0.05 AND 0.2 THEN 'Medium (50-200m)'
    ELSE 'Large (>200m)'
END AS size_category
FROM asteroid_registry r
JOIN asteroid_approaches a ON r.asteroid_id = a.asteroid_id;

-- 10. Check for data integrity: Are there any registry entries without an associated approach record?
SELECT r.name 
FROM asteroid_registry r 
LEFT JOIN asteroid_approaches a ON r.asteroid_id = a.asteroid_id 
WHERE a.asteroid_id IS NULL;


-- ==========================================================
-- SECTION 4: ADVANCED BI & SCIENTIFIC INSIGHTS
-- ==========================================================

-- 11. Find all asteroids that are traveling faster than the average speed of all objects in the database.
SELECT r.name, a.velocity_kph 
FROM asteroid_registry r 
JOIN asteroid_approaches a ON r.asteroid_id = a.asteroid_id 
WHERE a.velocity_kph > (SELECT AVG(velocity_kph) FROM asteroid_approaches);

-- 12. Create a reusable VIEW for a 'Daily Threat Report' showing hazardous objects traveling over 50,000 kph.
CREATE OR REPLACE VIEW high_speed_threats AS 
SELECT r.name, a.velocity_kph, a.miss_distance_km 
FROM asteroid_registry r 
JOIN asteroid_approaches a ON r.asteroid_id = a.asteroid_id 
WHERE r.is_hazardous = 1 AND a.velocity_kph > 50000;

-- (To display the view results for your project:)
SELECT * FROM high_speed_threats;

-- 13. Calculate a custom 'Kinetic Risk Index' (Diameter * Velocity) to rank the most impactful objects.
SELECT r.name, (a.diameter_max_km * a.velocity_kph) AS kinetic_index 
FROM asteroid_registry r 
JOIN asteroid_approaches a ON r.asteroid_id = a.asteroid_id 
ORDER BY kinetic_index DESC;

-- 14. Find asteroids with the highest 'Measurement Uncertainty' (Difference between Min and Max diameter estimates).
SELECT r.name, (a.diameter_max_km - a.diameter_min_km) AS uncertainty_km 
FROM asteroid_registry r 
JOIN asteroid_approaches a ON r.asteroid_id = a.asteroid_id 
ORDER BY uncertainty_km DESC;

-- 15. Use the EXISTS clause to find all hazardous asteroids that have a recorded miss distance of less than 30 million km.
SELECT r.name 
FROM asteroid_registry r 
WHERE r.is_hazardous = 1 
AND EXISTS (
    SELECT 1 FROM asteroid_approaches a 
    WHERE a.asteroid_id = r.asteroid_id 
    AND a.miss_distance_km < 30000000
);