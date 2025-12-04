/* ************************************
   TCSS 445 — Phase III (PostgreSQL Schema)
   DBMS: PostgreSQL
   Project: Husky Ride Share
   ************************************ */

/* Drop in dependency order (safe re-runs) */
DROP TABLE IF EXISTS Ratings CASCADE;
DROP TABLE IF EXISTS Matches CASCADE;
DROP TABLE IF EXISTS RideRequests CASCADE;
DROP TABLE IF EXISTS RideOffers CASCADE;
DROP TABLE IF EXISTS Vehicles CASCADE;
DROP TABLE IF EXISTS Users CASCADE;
DROP TABLE IF EXISTS BankAccounts CASCADE;

/* ============ USERS ============ */
CREATE TABLE Users (
  user_id    SERIAL PRIMARY KEY,
  uw_email   VARCHAR(120) NOT NULL UNIQUE,
  full_name  VARCHAR(80)  NOT NULL,
  role       VARCHAR(10)  DEFAULT 'rider'   NOT NULL
             CHECK (role IN ('rider','driver','both')),
  status     VARCHAR(10)  DEFAULT 'ACTIVE'  NOT NULL
             CHECK (status IN ('ACTIVE','SUSPENDED')),
  created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP NOT NULL
);

/* ============ VEHICLES ============ */
CREATE TABLE Vehicles (
  vehicle_id SERIAL PRIMARY KEY,
  driver_id  INTEGER,  -- nullable; if driver deleted we keep record but null the link
  make       VARCHAR(40) NOT NULL,
  model      VARCHAR(40) NOT NULL,
  color      VARCHAR(20),
  plate      VARCHAR(15) UNIQUE,
  capacity   INTEGER DEFAULT 4 NOT NULL
             CHECK (capacity BETWEEN 1 AND 7),
  CONSTRAINT fk_vehicle_driver
    FOREIGN KEY (driver_id) REFERENCES Users(user_id) ON DELETE SET NULL
);

/* ============ RIDE OFFERS ============ */
CREATE TABLE RideOffers (
  offer_id        SERIAL PRIMARY KEY,
  driver_id       INTEGER NOT NULL,
  vehicle_id      INTEGER,
  start_zone      VARCHAR(40) NOT NULL,  -- e.g., 'Kent P&R'
  end_zone        VARCHAR(40) NOT NULL,  -- e.g., 'UW Tacoma'
  start_time      TIMESTAMP   NOT NULL,
  seats_available INTEGER     DEFAULT 3 NOT NULL
                  CHECK (seats_available BETWEEN 0 AND 7),
  notes           VARCHAR(200),
  CONSTRAINT fk_offer_driver
    FOREIGN KEY (driver_id)  REFERENCES Users(user_id)        ON DELETE CASCADE,
  CONSTRAINT fk_offer_vehicle
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id)  ON DELETE SET NULL
);

/* ============ RIDE REQUESTS ============ */
CREATE TABLE RideRequests (
  request_id    SERIAL PRIMARY KEY,
  rider_id      INTEGER      NOT NULL,
  from_zone     VARCHAR(40) NOT NULL,
  to_zone       VARCHAR(40) NOT NULL,
  desired_time  TIMESTAMP    NOT NULL,
  seats_needed  INTEGER      DEFAULT 1 NOT NULL
                CHECK (seats_needed BETWEEN 1 AND 4),
  status        VARCHAR(12) DEFAULT 'open' NOT NULL
                CHECK (status IN ('open','matched','cancelled','completed')),
  CONSTRAINT fk_request_rider
    FOREIGN KEY (rider_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

/* ============ MATCHES (offer↔request) ============ */
CREATE TABLE Matches (
  match_id   SERIAL PRIMARY KEY,
  offer_id   INTEGER NOT NULL,
  request_id INTEGER NOT NULL,
  matched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  status     VARCHAR(12) DEFAULT 'pending' NOT NULL
             CHECK (status IN ('pending','confirmed','completed','cancelled')),
  CONSTRAINT uq_offer_request UNIQUE (offer_id, request_id),
  CONSTRAINT fk_match_offer
    FOREIGN KEY (offer_id)   REFERENCES RideOffers(offer_id)     ON DELETE CASCADE,
  CONSTRAINT fk_match_request
    FOREIGN KEY (request_id) REFERENCES RideRequests(request_id) ON DELETE CASCADE
);

/* ============ RATINGS ============ */
CREATE TABLE Ratings (
  rating_id      SERIAL PRIMARY KEY,
  rater_user_id  INTEGER NOT NULL,
  ratee_user_id  INTEGER NOT NULL,
  ride_date      DATE   NOT NULL,
  score          INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
  review_comment VARCHAR(400),
  created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  CONSTRAINT fk_rating_rater
    FOREIGN KEY (rater_user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
  CONSTRAINT fk_rating_ratee
    FOREIGN KEY (ratee_user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
  CONSTRAINT chk_rater_ratee CHECK (rater_user_id <> ratee_user_id)
);

/* ============ BANK ACCOUNTS (for transaction demo) ============ */
CREATE TABLE BankAccounts (
  account_id INTEGER PRIMARY KEY,
  name       VARCHAR(50),
  balance    DECIMAL(10,2)
);

/* Helpful indexes */
CREATE INDEX ix_offer_start_time     ON RideOffers(start_time);
CREATE INDEX ix_request_desired_time ON RideRequests(desired_time);
CREATE INDEX ix_ratings_ratee        ON Ratings(ratee_user_id);

/* ************************************ 
   PART B — SAMPLE DATA FOR HUSKY RIDESHARE (PostgreSQL)
************************************ */

-- Insert Users data
INSERT INTO Users (uw_email, full_name, role, status) VALUES 
  ('eu.tellus@icloud.couk','Gwendolyn Wright','driver','ACTIVE'),
  ('turpis.vitae.purus@icloud.couk','Quail Barton','driver','SUSPENDED'),
  ('suspendisse.sagittis@icloud.org','Dolan Monroe','both','SUSPENDED'),
  ('placerat.eget@icloud.org','Quinn Beard','both','ACTIVE'),
  ('amet.nulla@protonmail.edu','Gail Savage','both','SUSPENDED'),
  ('fusce.fermentum@hotmail.edu','Grant Hendricks','driver','SUSPENDED'),
  ('tempus.scelerisque@aol.edu','Elvis Petty','rider','SUSPENDED'),
  ('ipsum@protonmail.com','Mona Sosa','rider','ACTIVE'),
  ('sagittis@hotmail.couk','Kaseem Fulton','driver','ACTIVE'),
  ('donec.at.arcu@yahoo.couk','Harriet Fleming','driver','ACTIVE');

-- Insert Vehicles data
INSERT INTO Vehicles (driver_id, make, model, color, plate, capacity) VALUES 
  (1,'Toyota','Prius','Blue','WA-PRU123',4),
  (10,'Honda','Civic','Silver','WA-CIV456',4),
  (9,'Subaru','Outback','Green','WA-OUT789',5),
  (4,'Tesla','Model 3','White','WA-EVX321',4),
  (6,'Ford','Escape','Black','WA-ESC654',4),
  (1,'Hyundai','Elantra','Red','WA-ELA852',4),
  (9,'Toyota','Camry','Gray','WA-CAM147',4),
  (4,'Kia','Niro','Blue','WA-NIR963',4),
  (10,'Chevrolet','Bolt','White','WA-BLT753',4),
  (1,'Honda','Accord','Black','WA-ACC159',5);

-- Insert RideOffers data
INSERT INTO RideOffers (driver_id, vehicle_id, start_zone, end_zone, start_time, seats_available, notes) VALUES
  (1, 1, 'Federal Way TC','UW Tacoma', '2025-11-10 07:30:00', 3,'Early run'),
  (10, 2, 'Puyallup Station','UW Tacoma', '2025-11-10 08:00:00', 2,'Can detour 38th'),
  (9, 3, 'Tacoma Dome','UW Tacoma', '2025-11-10 08:15:00', 3,'Near Dome'),
  (4, 4, 'Downtown Seattle','UW Tacoma', '2025-11-10 07:00:00', 2,'Charging stop ok'),
  (6, 5, 'Lakewood','UW Tacoma', '2025-11-11 09:00:00', 3,'Library drop'),
  (1, 6, 'Kent P&R','UW Tacoma', '2025-11-11 07:40:00', 2,'No food pls'),
  (9, 7, 'Auburn Station','UW Tacoma', '2025-11-11 07:10:00', 3,'Can play music'),
  (4, 8, 'Gig Harbor P&R','UW Tacoma', '2025-11-12 08:05:00', 2,'Return 5pm'),
  (10, 9, 'Federal Way TC','UW Tacoma', '2025-11-12 07:35:00', 2,'Pickup Lot A'),
  (1, 10, 'Fife','UW Tacoma', '2025-11-12 08:00:00', 3,'Flexible by 10 min');

-- Insert RideRequests data
INSERT INTO RideRequests (rider_id, from_zone, to_zone, desired_time, seats_needed, status) VALUES
  (8, 'Federal Way TC','UW Tacoma', '2025-11-10 07:50:00', 1,'open'),
  (5, 'Puyallup Station','UW Tacoma', '2025-11-10 08:10:00', 2,'open'),
  (7, 'Tacoma Dome','UW Tacoma', '2025-11-10 08:25:00', 1,'open'),
  (9, 'Fife','UW Tacoma', '2025-11-12 07:55:00',1,'open'),
  (4, 'Gig Harbor P&R','UW Tacoma', '2025-11-12 08:00:00',1,'open'),
  (1, 'Kent P&R','UW Tacoma', '2025-11-11 07:45:00', 2,'open'),
  (6, 'Lakewood','UW Tacoma', '2025-11-11 09:10:00', 1,'open'),
  (2, 'Auburn Station','UW Tacoma', '2025-11-11 07:20:00', 1,'open'),
  (3, 'Downtown Seattle','UW Tacoma', '2025-11-10 06:55:00',1,'open'),
  (10, 'Federal Way TC','UW Tacoma', '2025-11-12 07:40:00', 1,'open');

-- Insert Matches
INSERT INTO Matches (offer_id, request_id, status) VALUES
  (1, 1, 'confirmed'),
  (2, 2, 'confirmed'),
  (3, 3, 'confirmed'),
  (4, 4, 'confirmed'),
  (5, 5, 'pending'),
  (6, 6, 'confirmed'),
  (7, 7, 'confirmed'),
  (8, 8, 'pending'),
  (1, 2, 'confirmed'),
  (2, 1, 'pending');

-- Insert Ratings data
INSERT INTO Ratings (rater_user_id, ratee_user_id, ride_date, score, review_comment) VALUES
  (10, 1, '2025-11-10', 5,'On time, smooth'),
  (5, 10, '2025-11-10', 5,'Friendly driver'),
  (8, 9, '2025-11-10', 4,'Traffic but okay'),
  (3, 4, '2025-11-10', 5,'Great convo'),
  (9, 6, '2025-11-11', 5,'Clean car'),
  (1, 6, '2025-11-11', 4,'Left a bit early'),
  (5, 9, '2025-11-11', 5,'Music was nice'),
  (8, 4, '2025-11-12', 5,'Quick trip'),
  (4, 10, '2025-11-12', 4,'Parking was crowded'),
  (10, 1, '2025-11-12', 5,'Would ride again');

-- Insert BankAccounts for transaction demo
INSERT INTO BankAccounts VALUES
  (1, 'Alice', 500.00),
  (2, 'Bob',   300.00);

/* ****************************************************
   PART C — SQL Queries (PostgreSQL)
   **************************************************** */

/* Query 1:
   Purpose: Show all confirmed rides with driver & rider names, start/end zones, time, status
   Expected result: Returns 7+ rows using sample data (one row per confirmed match)
*/
SELECT d.full_name AS driver_name,
       r.full_name AS rider_name,
       o.start_zone,
       o.end_zone,
       o.start_time,
       m.status
FROM Matches m
JOIN RideOffers   o ON m.offer_id   = o.offer_id
JOIN RideRequests q ON m.request_id = q.request_id
JOIN Users d ON o.driver_id = d.user_id
JOIN Users r ON q.rider_id  = r.user_id
WHERE m.status = 'confirmed'
ORDER BY o.start_time;

/* Query 2:
   Purpose: Find top-rated drivers (highest average score across Ratings)
   Expected result: Returns 1+ rows (ties possible): driver_name, avg_score
*/
SELECT u.full_name AS driver_name, 
       ROUND(AVG(t.score)::numeric, 2) AS avg_score
FROM Ratings t
JOIN Users u ON t.ratee_user_id = u.user_id
WHERE u.role IN ('driver','both')
GROUP BY u.user_id, u.full_name
HAVING AVG(t.score) >= ALL (
  SELECT AVG(t2.score)
  FROM Ratings t2
  JOIN Users u2 ON t2.ratee_user_id = u2.user_id
  WHERE u2.role IN ('driver','both')
  GROUP BY u2.user_id
)
ORDER BY avg_score DESC, driver_name;

/* Query 3:
   Purpose: Identify overbooked offers (matched seats > seats available)
   Expected result: Returns 0+ rows: offer_id, driver_name, seats_available, seats_matched
*/
SELECT o.offer_id,
       u.full_name AS driver_name,
       o.seats_available,
       (SELECT COUNT(*)
          FROM Matches m
         WHERE m.offer_id = o.offer_id
           AND m.status IN ('pending','confirmed')) AS seats_matched
FROM RideOffers o
JOIN Users u ON o.driver_id = u.user_id
WHERE o.seats_available < (
  SELECT COUNT(*) 
  FROM Matches m
  WHERE m.offer_id = o.offer_id
    AND m.status IN ('pending','confirmed')
)
ORDER BY o.offer_id;

/* Query 4:
   Purpose: Supply vs demand by zone + day using FULL OUTER JOIN of offers and requests
   Expected result: Returns rows for matched or unmatched items; NULLs indicate no counterpart
*/
SELECT COALESCE(o.start_zone, q.from_zone) AS zone,
       DATE(COALESCE(o.start_time, q.desired_time)) AS ride_day,
       o.offer_id,
       q.request_id
FROM RideOffers o
FULL OUTER JOIN RideRequests q
  ON o.start_zone  = q.from_zone
 AND o.end_zone    = q.to_zone
 AND DATE(o.start_time) = DATE(q.desired_time)
ORDER BY ride_day, zone;

/* Query 5:
   Purpose: Users who are both drivers & riders (INTERSECT logic or equivalent)
   Expected result: Returns 0+ rows: user_id, full_name, uw_email
*/
SELECT u.user_id, u.full_name, u.uw_email
FROM Users u
WHERE u.user_id IN (
  SELECT driver_id FROM RideOffers
  INTERSECT
  SELECT rider_id FROM RideRequests
)
ORDER BY u.full_name;

/* Query 6:
   Purpose: Transaction test — transfer money between accounts with COMMIT/ROLLBACK (uses BankAccounts)
   Expected result: Shows current account balances. The actual transaction (BEGIN/COMMIT/ROLLBACK) 
   is handled in the web application (query6.js controller), not in this SQL file.
   
   Note: To test transactions manually, use:
   BEGIN;
     UPDATE BankAccounts SET balance = balance - 100.00 WHERE account_id = 1;
     UPDATE BankAccounts SET balance = balance + 100.00 WHERE account_id = 2;
     SELECT account_id, name, balance FROM BankAccounts ORDER BY account_id;
   COMMIT;  -- or ROLLBACK; to undo
*/
SELECT account_id, name, balance 
FROM BankAccounts 
ORDER BY account_id;

/* Query 7:
   Purpose: Count drivers by status and/or role (aggregate + GROUP BY)
   Expected result: Returns rows showing count of drivers grouped by status and role
*/
SELECT 
  u.status,
  u.role,
  COUNT(*) AS driver_count
FROM Users u
WHERE u.role IN ('driver', 'both')
GROUP BY u.status, u.role
ORDER BY u.status, u.role;

/* Query 8:
   Purpose: Top 5 riders who requested the most rides
   Expected result: Returns up to 5 rows: rider_name, request_count
*/
SELECT 
  u.full_name AS rider_name,
  COUNT(*) AS request_count
FROM RideRequests r
JOIN Users u ON r.rider_id = u.user_id
GROUP BY u.user_id, u.full_name
ORDER BY request_count DESC, rider_name
LIMIT 5;

/* Query 9:
   Purpose: Vehicles with the highest capacity (list driver + car info)
   Expected result: Returns vehicles with maximum capacity, showing driver and vehicle details
*/
SELECT 
  v.vehicle_id,
  v.make,
  v.model,
  v.color,
  v.capacity,
  u.full_name AS driver_name,
  u.uw_email AS driver_email
FROM Vehicles v
LEFT JOIN Users u ON v.driver_id = u.user_id
WHERE v.capacity = (SELECT MAX(capacity) FROM Vehicles)
ORDER BY v.vehicle_id;

/* Query 10:
   Purpose: Drivers who have never received a rating (NOT EXISTS / LEFT JOIN … IS NULL)
   Expected result: Returns drivers who have no ratings in the Ratings table
*/
SELECT 
  u.user_id,
  u.full_name AS driver_name,
  u.uw_email,
  u.role
FROM Users u
WHERE u.role IN ('driver', 'both')
  AND NOT EXISTS (
    SELECT 1 
    FROM Ratings r 
    WHERE r.ratee_user_id = u.user_id
  )
ORDER BY u.full_name;

-- Alternative using LEFT JOIN (commented out):
/*
SELECT 
  u.user_id,
  u.full_name AS driver_name,
  u.uw_email,
  u.role
FROM Users u
LEFT JOIN Ratings r ON r.ratee_user_id = u.user_id
WHERE u.role IN ('driver', 'both')
  AND r.rating_id IS NULL
ORDER BY u.full_name;
*/

