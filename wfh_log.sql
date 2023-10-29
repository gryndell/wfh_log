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

