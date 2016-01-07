--
-- calculates the average years it takes to reuse a calendar in SQLite
--
-- Text encoding used: windows-1252
--
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

-- Table: Calendars
CREATE TABLE Calendars (
    YEAR     INTEGER PRIMARY KEY,
    LEAP     BOOLEAN,
    STARTDAY STRING  CHECK (STARTDAY IS NULL OR 
                            STARTDAY IN ('mon',
                     'tue',
                     'wed',
                     'thu',
                     'fri',
                     'sat',
                     'sun') ) 
);

-- Table: YEARS
CREATE TABLE YEARS (
    YEAR          INTEGER,
    NUMBEROFYEARS INTEGER DEFAULT (10) 
);

INSERT INTO YEARS (
                      YEAR,
                      NUMBEROFYEARS
                  )
                  VALUES (
                      0,
                      9999
                  );


-- View: Calendars_Fill
CREATE VIEW Calendars_Fill AS
    SELECT YEAR,
           julianday(substr('0000' || (year + 1), - 4) || '-01-01') - julianday(substr('0000' || year, - 4) || '-01-01') == 366 AS LEAP,
           CASE CAST (strftime('%w', julianday(substr('0000' || year, - 4) || '-01-01') ) AS INTEGER) WHEN 0 THEN 'sun' WHEN 1 THEN 'mon' WHEN 2 THEN 'tue' WHEN 3 THEN 'wed' WHEN 4 THEN 'thu' WHEN 5 THEN 'fri' ELSE 'sat' END AS STARTDAY
      FROM (
           WITH RECURSIVE cnt (
                   x
               )
               AS (
                   SELECT 1
                   UNION ALL
                   SELECT x + 1
                     FROM cnt
                    LIMIT 1000000
               )
               SELECT DISTINCT YEARS.YEAR + x AS year
                 FROM cnt,
                      YEARS
                WHERE x <= YEARS.NUMBEROFYEARS
           )
           AS YEARS
     WHERE year >= 0 AND 
           year <= 9999 AND 
NOT        EXISTS (
               SELECT *
                 FROM Calendars
                WHERE Calendars.YEAR = YEARS.YEAR
           );


-- View: Calendars_Next
CREATE VIEW Calendars_Next AS
    SELECT a.YEAR,
           (
               SELECT min(b.year) - a.year
                 FROM Calendars AS b
                WHERE a.leap = b.leap AND 
                      a.startday = b.startday AND 
                      b.year > a.year
           )
           yearstopass
      FROM Calendars AS a
     ORDER BY 1;


COMMIT TRANSACTION;
PRAGMA foreign_keys = on;

insert into YEARS values(0,9999);
insert into Calendars select * from Calendars_Fill;
.headers on
select MAX(yearstopass), MIN(yearstopass), avg(yearstopass) from Calendars_Next;
select LEAP, STARTDAY, group_concat(year) years from Calendars group by LEAP, STARTDAY;