CREATE TABLE IF NOT EXISTS audit_log (
    id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(50)  NOT NULL,
    civil_id   VARCHAR(255),
    ip         VARCHAR(45)  NOT NULL,
    success    BOOLEAN      NOT NULL,
    reason     VARCHAR(255),
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_civil_id  ON audit_log (civil_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log (created_at);
