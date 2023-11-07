-- Definition for WFH logging database

CREATE TABLE IF NOT EXISTS wfh_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    start_time integer,
    finish_time integer,
    reason TEXT
);
CREATE UNIQUE INDEX IF NOT EXISTS log_id ON wfh_log(id);
CREATE INDEX IF NOT EXISTS log_reason ON wfh_log(reason);
CREATE INDEX IF NOT EXISTS log_reason_lower ON wfh_log(lower(reason));

CREATE TABLE IF NOT EXISTS wfh_reason (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    reason TEXT,
    description TEXT
);
CREATE UNIQUE INDEX IF NOT EXISTS reason_id ON wfh_reason(id);
CREATE INDEX IF NOT EXISTS reason_reason ON wfh_reason(reason);
CREATE INDEX IF NOT EXISTS reason_reason_lower ON wfh_reason(lower(reason));

CREATE TABLE IF NOT EXISTS wfh_rate (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    start_date TEXT,
    end_date TEXT,
    rate REAL
);
CREATE UNIQUE INDEX IF NOT EXISTS rate_id ON wfh_rate(id);
CREATE INDEX IF NOT EXISTS rate_start_date ON wfh_rate(start_date);
CREATE INDEX IF NOT EXISTS rate_end_date ON wfh_rate(end_date);
CREATE VIEW IF NOT EXISTS view_log AS
    SELECT datetime(start_time, 'unixepoch', 'localtime') AS 'Start',
            time(finish_time, 'unixepoch', 'localtime') AS 'Finish',
            printf('%.2f', (finish_time - start_time) / 3600.0) as 'Hours',
            reason AS 'Reason'
    FROM wfh_log WHERE
    id > ((SELECT max(id) FROM wfh_log) - 10)
    ORDER BY id;
