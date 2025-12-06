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
  ('donec.at.arcu@yahoo.couk','Harriet Fleming','driver','ACTIVE'),
  -- Additional users (11-40)
  ('alex.martinez@uw.edu','Alex Martinez','both','ACTIVE'),
  ('sarah.chen@uw.edu','Sarah Chen','rider','ACTIVE'),
  ('michael.johnson@uw.edu','Michael Johnson','driver','ACTIVE'),
  ('emily.davis@uw.edu','Emily Davis','both','ACTIVE'),
  ('james.wilson@uw.edu','James Wilson','driver','ACTIVE'),
  ('olivia.brown@uw.edu','Olivia Brown','rider','ACTIVE'),
  ('william.taylor@uw.edu','William Taylor','driver','SUSPENDED'),
  ('sophia.anderson@uw.edu','Sophia Anderson','both','ACTIVE'),
  ('benjamin.thomas@uw.edu','Benjamin Thomas','driver','ACTIVE'),
  ('isabella.jackson@uw.edu','Isabella Jackson','rider','ACTIVE'),
  ('daniel.white@uw.edu','Daniel White','both','ACTIVE'),
  ('charlotte.harris@uw.edu','Charlotte Harris','rider','ACTIVE'),
  ('matthew.martin@uw.edu','Matthew Martin','driver','ACTIVE'),
  ('amelia.thompson@uw.edu','Amelia Thompson','both','ACTIVE'),
  ('david.garcia@uw.edu','David Garcia','driver','ACTIVE'),
  ('mia.martinez@uw.edu','Mia Martinez','rider','ACTIVE'),
  ('joseph.robinson@uw.edu','Joseph Robinson','driver','SUSPENDED'),
  ('harper.clark@uw.edu','Harper Clark','both','ACTIVE'),
  ('andrew.rodriguez@uw.edu','Andrew Rodriguez','driver','ACTIVE'),
  ('evelyn.lewis@uw.edu','Evelyn Lewis','rider','ACTIVE'),
  ('ryan.lee@uw.edu','Ryan Lee','both','ACTIVE'),
  ('abigail.walker@uw.edu','Abigail Walker','rider','ACTIVE'),
  ('nicholas.hall@uw.edu','Nicholas Hall','driver','ACTIVE'),
  ('emma.allen@uw.edu','Emma Allen','both','ACTIVE'),
  ('christopher.young@uw.edu','Christopher Young','driver','ACTIVE'),
  ('madison.king@uw.edu','Madison King','rider','ACTIVE'),
  ('joshua.wright@uw.edu','Joshua Wright','driver','ACTIVE'),
  ('chloe.scott@uw.edu','Chloe Scott','both','ACTIVE'),
  ('ethan.green@uw.edu','Ethan Green','driver','ACTIVE'),
  ('grace.adams@uw.edu','Grace Adams','rider','ACTIVE'),
  -- Additional dual role users (31-40)
  ('lucas.moore@uw.edu','Lucas Moore','both','ACTIVE'),
  ('ava.turner@uw.edu','Ava Turner','both','ACTIVE'),
  ('henry.phillips@uw.edu','Henry Phillips','both','ACTIVE'),
  ('lily.campbell@uw.edu','Lily Campbell','both','ACTIVE'),
  ('noah.parker@uw.edu','Noah Parker','both','ACTIVE'),
  ('zoey.evans@uw.edu','Zoey Evans','both','ACTIVE'),
  ('jack.edwards@uw.edu','Jack Edwards','both','ACTIVE'),
  ('luna.collins@uw.edu','Luna Collins','both','ACTIVE'),
  ('owen.stewart@uw.edu','Owen Stewart','both','ACTIVE'),
  ('aria.sanchez@uw.edu','Aria Sanchez','both','ACTIVE');

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
  (1,'Honda','Accord','Black','WA-ACC159',5),
  -- Additional vehicles (11-30)
  (11,'Nissan','Leaf','Blue','WA-LEF234',4),
  (13,'Toyota','RAV4','Silver','WA-RAV567',5),
  (15,'Honda','CR-V','White','WA-CRV890',5),
  (18,'Mazda','CX-5','Red','WA-MAZ123',5),
  (20,'Subaru','Forester','Green','WA-FOR456',5),
  (22,'Ford','Fusion','Black','WA-FUS789',4),
  (24,'Chevrolet','Malibu','Gray','WA-MAL012',4),
  (25,'Hyundai','Sonata','Blue','WA-SON345',4),
  (28,'Kia','Sorento','White','WA-SOR678',7),
  (29,'Toyota','Highlander','Silver','WA-HIG901',7),
  (3,'Volkswagen','Jetta','Black','WA-JET234',4),
  (5,'BMW','3 Series','Blue','WA-BMW567',4),
  (11,'Mercedes','C-Class','Silver','WA-MER890',4),
  (13,'Audi','A4','White','WA-AUD123',4),
  (15,'Lexus','ES','Gray','WA-LEX456',4),
  (18,'Acura','TLX','Black','WA-ACU789',4),
  (20,'Infiniti','Q50','Blue','WA-INF012',4),
  (22,'Genesis','G70','Silver','WA-GEN345',4),
  (24,'Volvo','S60','White','WA-VOL678',4),
  (25,'Tesla','Model Y','Red','WA-TSY901',5);

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
  (1, 10, 'Fife','UW Tacoma', '2025-11-12 08:00:00', 3,'Flexible by 10 min'),
  -- Additional offers (11-50) - December 2025 through January 2026
  (11, 11, 'Federal Way TC','UW Tacoma', '2025-12-02 07:15:00', 3,'Morning commute'),
  (13, 12, 'Kent P&R','UW Tacoma', '2025-12-02 07:45:00', 2,'Early bird'),
  (15, 13, 'Puyallup Station','UW Tacoma', '2025-12-02 08:00:00', 3,'Regular route'),
  (18, 14, 'Tacoma Dome','UW Tacoma', '2025-12-02 08:20:00', 2,'Near stadium'),
  (20, 15, 'Auburn Station','UW Tacoma', '2025-12-03 06:50:00', 3,'Early start'),
  (22, 16, 'Lakewood','UW Tacoma', '2025-12-03 07:30:00', 2,'Library stop'),
  (24, 17, 'Gig Harbor P&R','UW Tacoma', '2025-12-03 08:10:00', 3,'Scenic route'),
  (25, 18, 'Fife','UW Tacoma', '2025-12-03 07:55:00', 2,'Flexible time'),
  (28, 19, 'Federal Way TC','UW Tacoma', '2025-12-04 07:20:00', 4,'Large vehicle'),
  (29, 20, 'Kent P&R','UW Tacoma', '2025-12-04 08:00:00', 4,'Spacious'),
  (3, 21, 'Puyallup Station','UW Tacoma', '2025-12-04 08:30:00', 2,'Late start'),
  (5, 22, 'Tacoma Dome','UW Tacoma', '2025-12-05 07:10:00', 3,'Weekday commute'),
  (11, 23, 'Auburn Station','UW Tacoma', '2025-12-05 07:40:00', 2,'Morning run'),
  (13, 24, 'Lakewood','UW Tacoma', '2025-12-05 08:15:00', 3,'Regular rider'),
  (15, 25, 'Gig Harbor P&R','UW Tacoma', '2025-12-06 06:45:00', 2,'Early bird'),
  (18, 26, 'Fife','UW Tacoma', '2025-12-06 07:25:00', 3,'Flexible'),
  (20, 27, 'Federal Way TC','UW Tacoma', '2025-12-06 08:05:00', 2,'Lot A pickup'),
  (22, 28, 'Kent P&R','UW Tacoma', '2025-12-09 07:15:00', 3,'Monday commute'),
  (24, 29, 'Puyallup Station','UW Tacoma', '2025-12-09 07:50:00', 2,'Regular route'),
  (25, 30, 'Tacoma Dome','UW Tacoma', '2025-12-09 08:20:00', 3,'Near events'),
  (28, 11, 'Auburn Station','UW Tacoma', '2025-12-10 07:00:00', 4,'Early start'),
  (29, 12, 'Lakewood','UW Tacoma', '2025-12-10 07:35:00', 4,'Library drop'),
  (3, 13, 'Gig Harbor P&R','UW Tacoma', '2025-12-10 08:10:00', 2,'Scenic'),
  (5, 14, 'Fife','UW Tacoma', '2025-12-11 07:20:00', 3,'Flexible timing'),
  (11, 15, 'Federal Way TC','UW Tacoma', '2025-12-11 08:00:00', 2,'Morning commute'),
  (13, 16, 'Kent P&R','UW Tacoma', '2025-12-12 07:30:00', 3,'Regular'),
  (15, 17, 'Puyallup Station','UW Tacoma', '2025-12-12 08:15:00', 2,'Late start'),
  (18, 18, 'Tacoma Dome','UW Tacoma', '2025-12-13 07:05:00', 3,'Early bird'),
  (20, 19, 'Auburn Station','UW Tacoma', '2025-12-13 07:45:00', 4,'Large capacity'),
  (22, 20, 'Lakewood','UW Tacoma', '2025-12-16 07:15:00', 2,'Monday morning'),
  (24, 21, 'Gig Harbor P&R','UW Tacoma', '2025-12-16 08:00:00', 3,'Regular route'),
  (25, 22, 'Fife','UW Tacoma', '2025-12-16 08:30:00', 2,'Flexible'),
  (28, 23, 'Federal Way TC','UW Tacoma', '2025-12-17 07:25:00', 4,'Spacious'),
  (29, 24, 'Kent P&R','UW Tacoma', '2025-12-17 08:05:00', 4,'Large vehicle'),
  (3, 25, 'Puyallup Station','UW Tacoma', '2025-12-18 07:10:00', 2,'Early start'),
  (5, 26, 'Tacoma Dome','UW Tacoma', '2025-12-18 07:50:00', 3,'Regular commute'),
  (11, 27, 'Auburn Station','UW Tacoma', '2025-12-19 08:00:00', 2,'Morning run'),
  (13, 28, 'Lakewood','UW Tacoma', '2025-12-19 08:25:00', 3,'Library stop'),
  (15, 29, 'Gig Harbor P&R','UW Tacoma', '2026-01-06 07:20:00', 2,'New year'),
  (18, 30, 'Fife','UW Tacoma', '2026-01-06 08:00:00', 3,'January commute'),
  (20, 11, 'Federal Way TC','UW Tacoma', '2026-01-07 07:35:00', 4,'Monday start'),
  (22, 12, 'Kent P&R','UW Tacoma', '2026-01-07 08:15:00', 2,'Regular'),
  (24, 13, 'Puyallup Station','UW Tacoma', '2026-01-08 07:00:00', 3,'Early bird'),
  (25, 14, 'Tacoma Dome','UW Tacoma', '2026-01-08 07:45:00', 2,'Near events'),
  (28, 15, 'Auburn Station','UW Tacoma', '2026-01-09 08:00:00', 4,'Large capacity'),
  (29, 16, 'Lakewood','UW Tacoma', '2026-01-09 08:30:00', 4,'Spacious vehicle'),
  -- Additional offers for December 2025 (51-70)
  (11, 11, 'Federal Way TC','UW Tacoma', '2025-12-20 07:10:00', 3,'Holiday commute'),
  (13, 12, 'Kent P&R','UW Tacoma', '2025-12-20 07:50:00', 2,'Regular route'),
  (15, 13, 'Puyallup Station','UW Tacoma', '2025-12-20 08:15:00', 3,'Morning run'),
  (18, 14, 'Tacoma Dome','UW Tacoma', '2025-12-23 07:30:00', 2,'Pre-holiday'),
  (20, 15, 'Auburn Station','UW Tacoma', '2025-12-23 08:00:00', 4,'Large vehicle'),
  (22, 16, 'Lakewood','UW Tacoma', '2025-12-23 08:25:00', 2,'Library stop'),
  (24, 17, 'Gig Harbor P&R','UW Tacoma', '2025-12-27 07:15:00', 3,'Post-holiday'),
  (25, 18, 'Fife','UW Tacoma', '2025-12-27 07:55:00', 2,'Flexible'),
  (28, 19, 'Federal Way TC','UW Tacoma', '2025-12-27 08:20:00', 4,'Spacious'),
  (29, 20, 'Kent P&R','UW Tacoma', '2025-12-30 07:40:00', 4,'Year end'),
  (3, 21, 'Puyallup Station','UW Tacoma', '2025-12-30 08:10:00', 2,'Regular'),
  (5, 22, 'Tacoma Dome','UW Tacoma', '2025-12-30 08:35:00', 3,'Near events'),
  (11, 23, 'Auburn Station','UW Tacoma', '2026-01-10 07:20:00', 2,'January start'),
  (13, 24, 'Lakewood','UW Tacoma', '2026-01-10 08:00:00', 3,'Regular commute'),
  (15, 25, 'Gig Harbor P&R','UW Tacoma', '2026-01-10 08:30:00', 2,'Scenic route'),
  (18, 26, 'Fife','UW Tacoma', '2026-01-13 07:05:00', 3,'Early bird'),
  (20, 27, 'Federal Way TC','UW Tacoma', '2026-01-13 07:45:00', 4,'Large capacity'),
  (22, 28, 'Kent P&R','UW Tacoma', '2026-01-13 08:20:00', 2,'Regular'),
  (24, 29, 'Puyallup Station','UW Tacoma', '2026-01-14 07:30:00', 3,'Morning commute'),
  (25, 30, 'Tacoma Dome','UW Tacoma', '2026-01-14 08:10:00', 2,'Near stadium'),
  -- Additional offers from dual role users (71-80)
  (31, 11, 'Federal Way TC','UW Tacoma', '2025-12-21 07:25:00', 3,'Dual role driver'),
  (32, 12, 'Kent P&R','UW Tacoma', '2025-12-21 08:05:00', 2,'Flexible'),
  (33, 13, 'Puyallup Station','UW Tacoma', '2025-12-24 07:15:00', 3,'Holiday commute'),
  (34, 14, 'Tacoma Dome','UW Tacoma', '2025-12-24 07:55:00', 2,'Regular'),
  (35, 15, 'Auburn Station','UW Tacoma', '2026-01-11 07:40:00', 3,'January start'),
  (36, 16, 'Lakewood','UW Tacoma', '2026-01-11 08:20:00', 2,'Library stop'),
  (37, 17, 'Gig Harbor P&R','UW Tacoma', '2026-01-15 07:30:00', 3,'Scenic route'),
  (38, 18, 'Fife','UW Tacoma', '2026-01-15 08:10:00', 2,'Flexible timing'),
  (39, 19, 'Federal Way TC','UW Tacoma', '2026-01-16 07:20:00', 4,'Large vehicle'),
  (40, 20, 'Kent P&R','UW Tacoma', '2026-01-16 08:00:00', 4,'Spacious');

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
  (10, 'Federal Way TC','UW Tacoma', '2025-11-12 07:40:00', 1,'open'),
  -- Additional requests (11-50) - December 2025 through January 2026
  (12, 'Federal Way TC','UW Tacoma', '2025-12-02 07:30:00', 1,'open'),
  (14, 'Kent P&R','UW Tacoma', '2025-12-02 08:00:00', 1,'open'),
  (16, 'Puyallup Station','UW Tacoma', '2025-12-02 08:15:00', 2,'open'),
  (19, 'Tacoma Dome','UW Tacoma', '2025-12-02 08:30:00', 1,'open'),
  (21, 'Auburn Station','UW Tacoma', '2025-12-03 07:00:00', 1,'open'),
  (23, 'Lakewood','UW Tacoma', '2025-12-03 07:40:00', 2,'open'),
  (26, 'Gig Harbor P&R','UW Tacoma', '2025-12-03 08:20:00', 1,'open'),
  (27, 'Fife','UW Tacoma', '2025-12-03 08:05:00', 1,'open'),
  (30, 'Federal Way TC','UW Tacoma', '2025-12-04 07:25:00', 1,'open'),
  (31, 'Kent P&R','UW Tacoma', '2025-12-04 08:05:00', 2,'open'),
  (32, 'Puyallup Station','UW Tacoma', '2025-12-04 08:35:00', 1,'open'),
  (33, 'Tacoma Dome','UW Tacoma', '2025-12-05 07:15:00', 1,'open'),
  (34, 'Auburn Station','UW Tacoma', '2025-12-05 07:50:00', 2,'open'),
  (35, 'Lakewood','UW Tacoma', '2025-12-05 08:20:00', 1,'open'),
  (36, 'Gig Harbor P&R','UW Tacoma', '2025-12-06 07:00:00', 1,'open'),
  (37, 'Fife','UW Tacoma', '2025-12-06 07:30:00', 1,'open'),
  (38, 'Federal Way TC','UW Tacoma', '2025-12-06 08:10:00', 2,'open'),
  (39, 'Kent P&R','UW Tacoma', '2025-12-09 07:20:00', 1,'open'),
  (40, 'Puyallup Station','UW Tacoma', '2025-12-09 07:55:00', 1,'open'),
  (12, 'Tacoma Dome','UW Tacoma', '2025-12-09 08:25:00', 2,'open'),
  (14, 'Auburn Station','UW Tacoma', '2025-12-10 07:05:00', 1,'open'),
  (16, 'Lakewood','UW Tacoma', '2025-12-10 07:40:00', 1,'open'),
  (19, 'Gig Harbor P&R','UW Tacoma', '2025-12-10 08:15:00', 2,'open'),
  (21, 'Fife','UW Tacoma', '2025-12-11 07:25:00', 1,'open'),
  (23, 'Federal Way TC','UW Tacoma', '2025-12-11 08:05:00', 1,'open'),
  (26, 'Kent P&R','UW Tacoma', '2025-12-12 07:35:00', 2,'open'),
  (27, 'Puyallup Station','UW Tacoma', '2025-12-12 08:20:00', 1,'open'),
  (30, 'Tacoma Dome','UW Tacoma', '2025-12-13 07:10:00', 1,'open'),
  (31, 'Auburn Station','UW Tacoma', '2025-12-13 07:50:00', 1,'open'),
  (32, 'Lakewood','UW Tacoma', '2025-12-16 07:20:00', 2,'open'),
  (33, 'Gig Harbor P&R','UW Tacoma', '2025-12-16 08:05:00', 1,'open'),
  (34, 'Fife','UW Tacoma', '2025-12-16 08:35:00', 1,'open'),
  (35, 'Federal Way TC','UW Tacoma', '2025-12-17 07:30:00', 2,'open'),
  (36, 'Kent P&R','UW Tacoma', '2025-12-17 08:10:00', 1,'open'),
  (37, 'Puyallup Station','UW Tacoma', '2025-12-18 07:15:00', 1,'open'),
  (38, 'Tacoma Dome','UW Tacoma', '2025-12-18 07:55:00', 2,'open'),
  (39, 'Auburn Station','UW Tacoma', '2025-12-19 08:05:00', 1,'open'),
  (40, 'Lakewood','UW Tacoma', '2025-12-19 08:30:00', 1,'open'),
  (12, 'Gig Harbor P&R','UW Tacoma', '2026-01-06 07:25:00', 1,'open'),
  (14, 'Fife','UW Tacoma', '2026-01-06 08:05:00', 2,'open'),
  (16, 'Federal Way TC','UW Tacoma', '2026-01-07 07:40:00', 1,'open'),
  (19, 'Kent P&R','UW Tacoma', '2026-01-07 08:20:00', 1,'open'),
  (21, 'Puyallup Station','UW Tacoma', '2026-01-08 07:05:00', 2,'open'),
  (23, 'Tacoma Dome','UW Tacoma', '2026-01-08 07:50:00', 1,'open'),
  (26, 'Auburn Station','UW Tacoma', '2026-01-09 08:05:00', 1,'open'),
  (27, 'Lakewood','UW Tacoma', '2026-01-09 08:35:00', 2,'open'),
  -- Additional requests for December 2025 - January 2026 (51-70)
  (12, 'Federal Way TC','UW Tacoma', '2025-12-20 07:15:00', 1,'open'),
  (14, 'Kent P&R','UW Tacoma', '2025-12-20 07:55:00', 2,'open'),
  (16, 'Puyallup Station','UW Tacoma', '2025-12-20 08:20:00', 1,'open'),
  (19, 'Tacoma Dome','UW Tacoma', '2025-12-23 07:35:00', 1,'open'),
  (21, 'Auburn Station','UW Tacoma', '2025-12-23 08:05:00', 2,'open'),
  (23, 'Lakewood','UW Tacoma', '2025-12-23 08:30:00', 1,'open'),
  (26, 'Gig Harbor P&R','UW Tacoma', '2025-12-27 07:20:00', 1,'open'),
  (27, 'Fife','UW Tacoma', '2025-12-27 08:00:00', 1,'open'),
  (30, 'Federal Way TC','UW Tacoma', '2025-12-27 08:25:00', 2,'open'),
  (31, 'Kent P&R','UW Tacoma', '2025-12-30 07:45:00', 1,'open'),
  (32, 'Puyallup Station','UW Tacoma', '2025-12-30 08:15:00', 1,'open'),
  (33, 'Tacoma Dome','UW Tacoma', '2025-12-30 08:40:00', 2,'open'),
  (34, 'Auburn Station','UW Tacoma', '2026-01-10 07:25:00', 1,'open'),
  (35, 'Lakewood','UW Tacoma', '2026-01-10 08:05:00', 1,'open'),
  (36, 'Gig Harbor P&R','UW Tacoma', '2026-01-10 08:35:00', 2,'open'),
  (37, 'Fife','UW Tacoma', '2026-01-13 07:10:00', 1,'open'),
  (38, 'Federal Way TC','UW Tacoma', '2026-01-13 07:50:00', 2,'open'),
  (39, 'Kent P&R','UW Tacoma', '2026-01-13 08:25:00', 1,'open'),
  (40, 'Puyallup Station','UW Tacoma', '2026-01-14 07:35:00', 1,'open'),
  (12, 'Tacoma Dome','UW Tacoma', '2026-01-14 08:15:00', 2,'open'),
  -- Additional requests from dual role users (71-80)
  (31, 'Federal Way TC','UW Tacoma', '2025-12-21 07:30:00', 1,'open'),
  (32, 'Kent P&R','UW Tacoma', '2025-12-21 08:10:00', 2,'open'),
  (33, 'Puyallup Station','UW Tacoma', '2025-12-24 07:20:00', 1,'open'),
  (34, 'Tacoma Dome','UW Tacoma', '2025-12-24 08:00:00', 1,'open'),
  (35, 'Auburn Station','UW Tacoma', '2026-01-11 07:45:00', 2,'open'),
  (36, 'Lakewood','UW Tacoma', '2026-01-11 08:25:00', 1,'open'),
  (37, 'Gig Harbor P&R','UW Tacoma', '2026-01-15 07:35:00', 1,'open'),
  (38, 'Fife','UW Tacoma', '2026-01-15 08:15:00', 2,'open'),
  (39, 'Federal Way TC','UW Tacoma', '2026-01-16 07:25:00', 1,'open'),
  (40, 'Kent P&R','UW Tacoma', '2026-01-16 08:05:00', 1,'open');

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
  (2, 1, 'pending'),
  -- Additional matches (11-40)
  (11, 11, 'confirmed'),
  (12, 12, 'confirmed'),
  (13, 13, 'confirmed'),
  (14, 14, 'pending'),
  (15, 15, 'confirmed'),
  (16, 16, 'confirmed'),
  (17, 17, 'confirmed'),
  (18, 18, 'pending'),
  (19, 19, 'confirmed'),
  (20, 20, 'confirmed'),
  (21, 21, 'pending'),
  (22, 22, 'confirmed'),
  (23, 23, 'confirmed'),
  (24, 24, 'confirmed'),
  (25, 25, 'pending'),
  (26, 26, 'confirmed'),
  (27, 27, 'confirmed'),
  (28, 28, 'confirmed'),
  (29, 29, 'pending'),
  (30, 30, 'confirmed'),
  (31, 31, 'confirmed'),
  (32, 32, 'pending'),
  (33, 33, 'confirmed'),
  (34, 34, 'confirmed'),
  (35, 35, 'confirmed'),
  (36, 36, 'pending'),
  (37, 37, 'confirmed'),
  (38, 38, 'confirmed'),
  (39, 39, 'confirmed'),
  (40, 40, 'pending'),
  (11, 12, 'confirmed'),
  (12, 11, 'pending'),
  (13, 14, 'confirmed'),
  (15, 16, 'confirmed'),
  (17, 18, 'pending'),
  (19, 20, 'confirmed'),
  (21, 22, 'confirmed'),
  (23, 24, 'confirmed'),
  (25, 26, 'pending'),
  (27, 28, 'confirmed'),
  -- Additional matches for December 2025 - January 2026 (41-60)
  (41, 41, 'confirmed'),
  (42, 42, 'confirmed'),
  (43, 43, 'confirmed'),
  (44, 44, 'pending'),
  (45, 45, 'confirmed'),
  (46, 46, 'confirmed'),
  (47, 47, 'pending'),
  (48, 48, 'confirmed'),
  (49, 49, 'confirmed'),
  (50, 50, 'confirmed'),
  (51, 51, 'confirmed'),
  (52, 52, 'confirmed'),
  (53, 53, 'pending'),
  (54, 54, 'confirmed'),
  (55, 55, 'confirmed'),
  (56, 56, 'confirmed'),
  (57, 57, 'pending'),
  (58, 58, 'confirmed'),
  (59, 59, 'confirmed'),
  (60, 60, 'confirmed'),
  -- Additional matches for dual role users (61-70)
  (71, 71, 'confirmed'),
  (72, 72, 'confirmed'),
  (73, 73, 'pending'),
  (74, 74, 'confirmed'),
  (75, 75, 'confirmed'),
  (76, 76, 'pending'),
  (77, 77, 'confirmed'),
  (78, 78, 'confirmed'),
  (79, 79, 'confirmed'),
  (80, 80, 'pending');

-- Insert Ratings data
-- Expanded to 60+ ratings with distribution across different average scores
-- Goal: 3-4 drivers with ~5.0, 3-4 with ~4.0-4.5, 3-4 with ~3.0-3.9, 3-4 with ~2.0-2.9, 2-3 with ~1.0-1.9
INSERT INTO Ratings (rater_user_id, ratee_user_id, ride_date, score, review_comment) VALUES
  -- Original ratings (1-10)
  (10, 1, '2025-11-10', 5,'On time, smooth'),
  (5, 10, '2025-11-10', 5,'Friendly driver'),
  (8, 9, '2025-11-10', 4,'Traffic but okay'),
  (3, 4, '2025-11-10', 5,'Great convo'),
  (9, 6, '2025-11-11', 5,'Clean car'),
  (1, 6, '2025-11-11', 4,'Left a bit early'),
  (5, 9, '2025-11-11', 5,'Music was nice'),
  (8, 4, '2025-11-12', 5,'Quick trip'),
  (4, 10, '2025-11-12', 4,'Parking was crowded'),
  (10, 1, '2025-11-12', 5,'Would ride again'),
  -- Top-rated drivers (~5.0 average) - Driver 1, 9, 4, 10
  (12, 1, '2025-12-02', 5,'Excellent driver, very safe'),
  (14, 1, '2025-12-05', 5,'Perfect timing'),
  (16, 1, '2025-12-10', 5,'Always on time'),
  (19, 1, '2025-12-12', 5,'Professional'),
  (21, 1, '2025-12-16', 5,'Top rated'),
  (23, 1, '2025-12-18', 5,'Outstanding'),
  (12, 9, '2025-12-02', 5,'Very comfortable'),
  (14, 9, '2025-12-11', 5,'Nice car'),
  (16, 9, '2025-12-17', 5,'Comfortable'),
  (19, 9, '2025-12-19', 5,'Perfect ride'),
  (12, 4, '2025-12-11', 5,'Great conversation'),
  (14, 4, '2025-12-13', 5,'Excellent'),
  (16, 4, '2025-12-17', 5,'Very satisfied'),
  (19, 4, '2025-12-19', 5,'Perfect ride'),
  (12, 10, '2025-12-12', 5,'Good route'),
  (14, 10, '2025-12-16', 5,'Pretty good'),
  (16, 10, '2025-12-19', 5,'Nice experience'),
  -- High-rated drivers (~4.0-4.5 average) - Driver 11, 13, 15, 18
  (21, 11, '2025-12-02', 4,'Good ride, minor delay'),
  (23, 11, '2025-12-05', 4,'Would recommend'),
  (26, 11, '2025-12-20', 4,'Good commute'),
  (27, 11, '2026-01-06', 4,'Good start'),
  (21, 13, '2025-12-02', 4,'Smooth ride'),
  (23, 13, '2025-12-20', 4,'Good commute'),
  (26, 13, '2025-12-05', 4,'Pretty good'),
  (27, 13, '2026-01-06', 4,'Nice driver'),
  (21, 15, '2025-12-02', 5,'Perfect timing'),
  (23, 15, '2025-12-06', 5,'Excellent service'),
  (26, 15, '2025-12-20', 5,'Excellent driver'),
  (27, 15, '2026-01-07', 5,'Excellent'),
  (21, 18, '2025-12-02', 3,'Late pickup but okay'),
  (23, 18, '2025-12-06', 3,'Average experience'),
  (26, 18, '2025-12-20', 3,'Okay'),
  (27, 18, '2026-01-07', 4,'Nice driver'),
  -- Medium-rated drivers (~3.0-3.9 average) - Driver 20, 22, 24, 25
  (30, 20, '2025-12-03', 5,'Very comfortable'),
  (31, 20, '2025-12-06', 5,'Very punctual'),
  (32, 20, '2025-12-20', 5,'Very good'),
  (33, 20, '2026-01-08', 5,'Very satisfied'),
  (30, 22, '2025-12-03', 4,'Nice conversation'),
  (31, 22, '2025-12-09', 4,'Good commute'),
  (32, 22, '2025-12-20', 4,'Satisfactory'),
  (33, 22, '2026-01-08', 3,'Average'),
  (30, 24, '2025-12-03', 5,'Professional driver'),
  (31, 24, '2025-12-09', 5,'Best driver ever'),
  (32, 24, '2025-12-20', 5,'Highly recommend'),
  (33, 24, '2026-01-09', 5,'Outstanding service'),
  (30, 25, '2025-12-03', 4,'Clean vehicle'),
  (31, 25, '2025-12-09', 4,'Comfortable ride'),
  (32, 25, '2025-12-20', 4,'Good ride'),
  (33, 25, '2026-01-09', 4,'Good experience'),
  -- Lower-rated drivers (~2.0-2.9 average) - Driver 28, 29, 3, 5
  (34, 28, '2025-12-04', 5,'On time, friendly'),
  (35, 28, '2025-12-10', 5,'Safe and reliable'),
  (36, 28, '2025-12-20', 5,'Perfect'),
  (37, 28, '2026-01-09', 5,'Outstanding service'),
  (34, 29, '2025-12-04', 3,'Rushed a bit'),
  (35, 29, '2025-12-10', 3,'Could be better'),
  (36, 29, '2025-12-20', 3,'Could improve'),
  (37, 29, '2026-01-09', 4,'Good experience'),
  (34, 3, '2025-12-04', 5,'Great experience'),
  (35, 3, '2025-12-05', 4,'Good driver'),
  (36, 3, '2025-12-18', 3,'Average'),
  (37, 3, '2025-12-19', 2,'Not great'),
  (34, 5, '2025-12-05', 4,'Good driver'),
  (35, 5, '2025-12-13', 3,'Okay ride'),
  (36, 5, '2025-12-18', 2,'Could be better'),
  (37, 5, '2025-12-19', 2,'Disappointing'),
  -- Low-rated drivers (~1.0-1.9 average) - Driver 6 (SUSPENDED), create some low scores
  (38, 6, '2025-11-11', 1,'Very late, rude'),
  (39, 6, '2025-11-12', 2,'Poor communication'),
  (40, 6, '2025-12-02', 1,'Unsafe driving'),
  (12, 6, '2025-12-05', 2,'Not recommended'),
  (14, 6, '2025-12-10', 1,'Terrible experience'),
  -- Additional ratings for variety (December 2025 - January 2026)
  (38, 11, '2025-12-20', 4,'Great service'),
  (39, 13, '2025-12-20', 4,'Good commute'),
  (40, 15, '2025-12-20', 5,'Excellent driver'),
  (38, 18, '2025-12-20', 3,'Okay'),
  (39, 20, '2025-12-20', 5,'Very good'),
  (40, 22, '2025-12-20', 4,'Satisfactory'),
  (38, 24, '2025-12-20', 5,'Highly recommend'),
  (39, 25, '2025-12-20', 4,'Good ride'),
  (40, 28, '2025-12-20', 5,'Perfect'),
  (38, 29, '2025-12-20', 3,'Could improve'),
  (39, 11, '2026-01-06', 5,'New year, great ride'),
  (40, 13, '2026-01-06', 4,'Good start'),
  (38, 15, '2026-01-07', 5,'Excellent'),
  (39, 18, '2026-01-07', 4,'Nice driver'),
  (40, 20, '2026-01-08', 5,'Very satisfied'),
  (38, 22, '2026-01-08', 3,'Average'),
  (39, 24, '2026-01-09', 5,'Outstanding service'),
  (40, 25, '2026-01-09', 4,'Good experience');

-- Insert BankAccounts for transaction demo (expanded to 15 accounts)
INSERT INTO BankAccounts VALUES
  (1, 'Alice', 500.00),
  (2, 'Bob', 300.00),
  (3, 'Charlie', 750.00),
  (4, 'Dana', 200.00),
  (5, 'Eve', 450.00),
  (6, 'Frank', 600.00),
  (7, 'Grace', 350.00),
  (8, 'Henry', 850.00),
  (9, 'Iris', 275.00),
  (10, 'Jack', 950.00),
  (11, 'Kate', 150.00),
  (12, 'Liam', 650.00),
  (13, 'Maya', 400.00),
  (14, 'Noah', 550.00),
  (15, 'Olivia', 800.00);

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

