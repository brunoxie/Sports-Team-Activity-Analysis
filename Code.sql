/***********************************************
**           Sports Team Activity Analysis
** Author:   Bruno Xie
** System:   MySQL
** Date:     05/18/2022
************************************************/

SET GLOBAL local_infile=TRUE; # to locally load the file
SET SQL_SAFE_UPDATES=0; 
SET FOREIGN_KEY_CHECKS=0;

############ Create the tables and load the data #############

-- -----------------------------------------------------
-- Table `marketing`.`team_activity`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS team_activity (
	teamid VARCHAR(32) NOT NULL,
	uploads_last_7_days INT NOT NULL,
	uploads_last_14_days INT NOT NULL,
	uploads_last_30_days INT NOT NULL,
	uploads_last_60_days INT NOT NULL,
	uploads_last_90_days INT NOT NULL,
	uploads_last_365_days INT NOT NULL,
	users_watching_video_last_7_days INT NOT NULL,
	users_watching_video_last_14_days INT NOT NULL,
	Users_watching_video_last_30_days INT NOT NULL,
	Users_watching_video_last_60_days INT NOT NULL,
	users_watching_video_last_90_days INT NOT NULL,
	users_watching_video_last_365_days INT NOT NULL,
	PRIMARY KEY (teamid)
);

LOAD DATA LOCAL INFILE '/Users/bruno/Sports-Team-Activity-Analysis/team_activity.csv'
INTO TABLE team_activity
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- -----------------------------------------------------
-- Table `marketing`.`schools`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS schools (
	school_id VARCHAR(32) NOT NULL,
	state VARCHAR(50) NOT NULL,
	PRIMARY KEY (school_id)
);

LOAD DATA LOCAL INFILE '/Users/bruno/Sports-Team-Activity-Analysis/schools.csv'
INTO TABLE schools
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

UPDATE schools
SET state = REPLACE(REPLACE(state, CHAR(13), ''), CHAR(10), '');

-- -----------------------------------------------------
-- Table `marketing`.`teams`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teams (
	teamid VARCHAR(32) NOT NULL,
	team_name VARCHAR(100) NOT NULL,
	school_id VARCHAR(32) NOT NULL,
	team_level VARCHAR(16) NOT NULL,
	num_coaches_and_admins INT NOT NULL,
	PRIMARY KEY (teamid),
    FOREIGN KEY (school_id) REFERENCES schools(school_id)
);

LOAD DATA LOCAL INFILE '/Users/bruno/Sports-Team-Activity-Analysis/teams.csv'
INTO TABLE teams
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

############ Transform the data #############

# Some state names in table schools are duplicated (e.g. Missouri and MO). Additionally, there are some data of Canada. Since the objective in this task is about the basketball teams in the US, we might drop data of Canada. Need to make some changes

# Take a look at all the states
SELECT DISTINCT state
FROM marketing.schools
ORDER BY state;

# See all rows with state names in abbreviation
SELECT *
FROM marketing.schools
WHERE LENGTH(state) <= 2
ORDER BY state;

# Update the state columns
DELETE FROM marketing.schools
WHERE state IN ('Saskatchewan', 'SK', 'AB', 'alberta', 'BC', 'MB', 'NS', 'ON', 'QC'); # delete the data of Canada

UPDATE schools
SET state = 'Missouri'
WHERE state = 'MO';

UPDATE schools
SET state = 'Nebraska'
WHERE state = 'NB';

# Looks good now
SELECT DISTINCT state
FROM marketing.schools
ORDER BY state;

############ Solve the Problems #############

## 1.1 How many teams have uploaded 10 or more times in the past 60 days?
SELECT
	COUNT(DISTINCT teamid) AS num_upload_10_or_more_past_60_days
FROM
	marketing.team_activity
WHERE
	uploads_last_60_days >= 10;

## 1.2 How many teams have uploaded less than 10 times in the past 60 days?
SELECT
	COUNT(DISTINCT teamid) AS num_upload_10_less_past_60_days
FROM
	marketing.team_activity
WHERE
	uploads_last_60_days < 10
    AND uploads_last_60_days > 0;

## 1.3 How many teams have never uploaded in the past 60 days?
SELECT
	COUNT(DISTINCT teamid) AS num_upload_0_past_60_days
FROM
	marketing.team_activity
WHERE
	uploads_last_60_days = 0;

## 1.4 How many teams have uploaded but have 0 users watching video in the past 60 days?
SELECT
	COUNT(DISTINCT teamid) AS num_uploaded_user_0_past_60_days
FROM
	marketing.team_activity
WHERE
	uploads_last_60_days > 0
    AND users_watching_video_last_60_days = 0;
    
## 1.5 How many teams have more than 5 users watching video in the past 60 days?
SELECT
	COUNT(DISTINCT teamid) AS num_uploaded_user_0_past_60_days
FROM
	marketing.team_activity
WHERE
	uploads_last_60_days > 0 # assume the question also asks for teams that have uploaded, so we could compare the result to 1.4
    AND users_watching_video_last_60_days > 5;

## Combine the results of 1.4 & 1.5 for later data visualization
SELECT
	users_watching_video_last_60_days,
    COUNT(DISTINCT teamid) AS num_user_past_60_days
FROM
	marketing.team_activity
WHERE
	uploads_last_60_days > 0
GROUP BY
	users_watching_video_last_60_days;

## 2. If they were to email coaches and team administrators on the teams with 0 uploads the past 7 days, how many teams would this include? How many coaches and admins would this include?
SELECT
	COUNT(DISTINCT ta.teamid) AS num_team,
    SUM(t.num_coaches_and_admins) AS num_coaches_and_admins
FROM
	marketing.team_activity AS ta
LEFT JOIN
	marketing.teams AS t
    ON ta.teamid = t.teamid
WHERE
	ta.uploads_last_7_days = 0;
    
## 3. Which state has the lowest percentage of teams uploading in the past 30 days?
SELECT
    s.state,
	SUM(CASE WHEN ta.uploads_last_30_days > 0 THEN 1 ELSE 0 END)/
    COUNT(DISTINCT ta.teamid) AS perc,
    SUM(CASE WHEN ta.uploads_last_30_days > 0 THEN 1 ELSE 0 END) AS num_team_uploaded, 
    # also get the numerator and denominator
    # not only focusing on the ratio, we may also want to look at the absolute quantity to know the importance of the ratio
    COUNT(DISTINCT ta.teamid) AS num_team
FROM
	marketing.team_activity AS ta
LEFT JOIN
	marketing.teams AS t
    ON ta.teamid = t.teamid
LEFT JOIN
	schools AS s
    ON t.school_id = s.school_id
WHERE
	s.state IS NOT NULL
GROUP BY
	s.state
ORDER BY
	perc
LIMIT 1;

# this time, we extract all states for later data visualization
SELECT
    s.state,
	SUM(CASE WHEN ta.uploads_last_30_days > 0 THEN 1 ELSE 0 END)/
    COUNT(DISTINCT ta.teamid) AS perc,
    SUM(CASE WHEN ta.uploads_last_30_days > 0 THEN 1 ELSE 0 END) AS num_team_uploaded,
    COUNT(DISTINCT ta.teamid) AS num_team
FROM
	marketing.team_activity AS ta
LEFT JOIN
	marketing.teams AS t
    ON ta.teamid = t.teamid
LEFT JOIN
	schools AS s
    ON t.school_id = s.school_id
WHERE
	s.state IS NOT NULL
    AND s.state NOT IN ('Alberta', 'British Columbia', 'Manitoba', 'Nova Scotia', 'Ontario', 'Quebec', 'Saskatchewan')
GROUP BY
	s.state
ORDER BY
	perc;
    
############ Exploratory Analysis #############

## Get the retention table
SELECT
	1 AS retention_365,
    SUM(CASE WHEN t90.uploads_last_90_days > 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT t365.teamid) AS retention_90,
    SUM(CASE WHEN t60.uploads_last_60_days > 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT t365.teamid) AS retention_60,
    SUM(CASE WHEN t30.uploads_last_30_days > 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT t365.teamid) AS retention_30,
    SUM(CASE WHEN t14.uploads_last_14_days > 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT t365.teamid) AS retention_14,
    SUM(CASE WHEN t7.uploads_last_7_days > 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT t365.teamid) AS retention_7
FROM marketing.team_activity AS t365
LEFT JOIN marketing.team_activity AS t90
	ON t365.teamid = t90.teamid
LEFT JOIN marketing.team_activity AS t60
	ON t365.teamid = t60.teamid
LEFT JOIN marketing.team_activity AS t30
	ON t365.teamid = t30.teamid
LEFT JOIN marketing.team_activity AS t14
	ON t365.teamid = t14.teamid
LEFT JOIN marketing.team_activity AS t7
	ON t365.teamid = t7.teamid
WHERE t365.uploads_last_365_days > 0
# Above codes are for the first row (results for teams that have uploaded in the past 365 days)
UNION
SELECT
	NULL AS retention_365,
    1 AS retention_90,
    SUM(CASE WHEN t60.uploads_last_60_days > 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT t90.teamid) AS retention_60,
    SUM(CASE WHEN t30.uploads_last_30_days > 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT t90.teamid) AS retention_30,
    SUM(CASE WHEN t14.uploads_last_14_days > 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT t90.teamid) AS retention_14,
    SUM(CASE WHEN t7.uploads_last_7_days > 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT t90.teamid) AS retention_7
FROM marketing.team_activity AS t90
LEFT JOIN marketing.team_activity AS t60
	ON t90.teamid = t60.teamid
LEFT JOIN marketing.team_activity AS t30
	ON t90.teamid = t30.teamid
LEFT JOIN marketing.team_activity AS t14
	ON t90.teamid = t14.teamid
LEFT JOIN marketing.team_activity AS t7
	ON t90.teamid = t7.teamid
WHERE t90.uploads_last_90_days > 0
# Above codes are for the second row (results for teams have uploaded in the past 90 days), and so forth
UNION
SELECT
	NULL AS retention_365,
    NULL AS retention_90,
    1 AS retention_60,
    SUM(CASE WHEN t30.uploads_last_30_days > 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT t60.teamid) AS retention_30,
    SUM(CASE WHEN t14.uploads_last_14_days > 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT t60.teamid) AS retention_14,
    SUM(CASE WHEN t7.uploads_last_7_days > 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT t60.teamid) AS retention_7
FROM marketing.team_activity AS t60
LEFT JOIN marketing.team_activity AS t30
	ON t60.teamid = t30.teamid
LEFT JOIN marketing.team_activity AS t14
	ON t60.teamid = t14.teamid
LEFT JOIN marketing.team_activity AS t7
	ON t60.teamid = t7.teamid
WHERE t60.uploads_last_60_days > 0
UNION
SELECT
	NULL AS retention_365,
    NULL AS retention_90,
    NULL AS retention_60,
    1 AS retention_30,
    SUM(CASE WHEN t14.uploads_last_14_days > 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT t30.teamid) AS retention_14,
    SUM(CASE WHEN t7.uploads_last_7_days > 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT t30.teamid) AS retention_7
FROM marketing.team_activity AS t30
LEFT JOIN marketing.team_activity AS t14
	ON t30.teamid = t14.teamid
LEFT JOIN marketing.team_activity AS t7
	ON t30.teamid = t7.teamid
WHERE t30.uploads_last_30_days > 0
UNION
SELECT
	NULL AS retention_365,
    NULL AS retention_90,
    NULL AS retention_60,
    NULL AS retention_30,
    1 AS retention_14,
    SUM(CASE WHEN t7.uploads_last_7_days > 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT t14.teamid) AS retention_7
FROM marketing.team_activity AS t14
LEFT JOIN marketing.team_activity AS t7
	ON t14.teamid = t7.teamid
WHERE t14.uploads_last_14_days > 0;

## Team Level Analysis
SELECT
	t.team_level,
    COUNT(DISTINCT ta.teamid) AS num_team,
    SUM(CASE WHEN ta.uploads_last_30_days = 0 THEN 1 ELSE 0 END)/COUNT(DISTINCT ta.teamid) AS perc_0_upload_30_days
FROM marketing.team_activity AS ta
LEFT JOIN marketing.teams AS t
	ON ta.teamid = t.teamid
WHERE
	t.team_level IS NOT NULL
GROUP BY
	t.team_level;