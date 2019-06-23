-- PRAGMA foreign_keys = ON;

-- status values:
-- 0 - not approved
-- 1 - approved (active)
-- 2 - disabled (inactive)

CREATE TABLE IF NOT EXISTS domains (
    id INTEGER PRIMARY KEY,
    updated TEXT DEFAULT (datetime('now')),
    name TEXT UNIQUE,
    token TEXT DEFAULT NULL,
    ttl INTEGER DEFAULT 60,
    class TEXT DEFAULT 'SOA',
    name_server TEXT DEFAULT NULL,
    email_addr TEXT DEFAULT NULL,
    sn INTEGER DEFAULT 1,
    refresh INTEGER DEFAULT 60,
    retry INTEGER DEFAULT 600,
    expiry INTEGER DEFAULT 604800,
    nx INTEGER DEFAULT 86400,
    desc TEXT DEFAULT NULL,
    status INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS domains_name_idx ON domains (name);
CREATE INDEX IF NOT EXISTS domains_updated_idx ON domains (updated);
INSERT INTO domains (id, name, name_server, email_addr, sn, status) VALUES (1, 'yourdomain.foo', 'ns.yourdomain.foo', 'root.yourdomain.foo', 1, 1);


CREATE TABLE IF NOT EXISTS records (
    id INTEGER PRIMARY KEY,
    updated TEXT DEFAULT (datetime('now')),
    domain_id INTEGER DEFAULT NULL,
    name TEXT,
    ttl INTEGER DEFAULT 60,
    class TEXT DEFAULT 'IN',
    type TEXT DEFAULT 'A',
    data TEXT DEFAULT NULL,
    desc TEXT DEFAULT NULL,
    token TEXT DEFAULT NULL,
    status INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS records_name_idx ON records (name);
CREATE INDEX IF NOT EXISTS records_domain_id_idx ON records (domain_id);
CREATE INDEX IF NOT EXISTS records_updated_idx ON records (updated);
INSERT INTO records (id, domain_id, name, type, data, status) VALUES (1, 1, 'yourdomain.foo', 'NS', 'ns.yourdomain.foo', 1);
INSERT INTO records (id, domain_id, name, type, data, status) VALUES (2, 1, 'ns.yourdomain.foo', 'A', 'SOME.IP.ADDRESS', 1);
INSERT INTO records (id, domain_id, name, type, data, status) VALUES (3, 1, 'yourdomain.foo', 'A', 'SOME.IP.ADDRESS', 1);


CREATE TABLE IF NOT EXISTS config (
    id INTEGER PRIMARY KEY,
    key TEXT UNIQUE NOT NULL,
    value TEXT DEFAULT NULL,
    desc TEXT DEFAULT NULL
);
CREATE INDEX IF NOT EXISTS config_key_idx ON config (key);
INSERT INTO config (id, key, value, desc) VALUES (1, 'zone_updater::last_seen', datetime('now', '-1000 years'), 'The time of the last running of the Zone updater process');
