-- Migration: 0006_time_matrix.sql
-- Purpose: rename event_start/event_end to start_at/end_at for universal
--          time-matrix semantics; add recurrence_rule column (reserved for v0.2+);
--          defensive FTS trigger rebuild to guard against future column drift.
-- Invariants:
-- - start_at/end_at drive section classification (Inbox/Today/Upcoming), NOT type.
-- - recurrence_rule is NULL until v0.2+ implements RFC 5545 RRULE support.
-- - FTS triggers are functionally identical to 0004; DROP+CREATE is preventive.
-- Backward compatibility:
-- - event_start/event_end column names are retired; all new code uses start_at/end_at.

-- 1. Column renames
ALTER TABLE atoms RENAME COLUMN event_start TO start_at;
ALTER TABLE atoms RENAME COLUMN event_end TO end_at;

-- 2. Reserved recurrence column
ALTER TABLE atoms ADD COLUMN recurrence_rule TEXT;

-- 3. Defensive FTS trigger rebuild (identical logic to 0004)
DROP TRIGGER IF EXISTS atoms_ai_fts;
DROP TRIGGER IF EXISTS atoms_ad_fts;
DROP TRIGGER IF EXISTS atoms_au_fts;

CREATE TRIGGER atoms_ai_fts
AFTER INSERT ON atoms
WHEN NEW.is_deleted = 0
BEGIN
    INSERT INTO atoms_fts (rowid, content, uuid, type)
    VALUES (NEW.rowid, NEW.content, NEW.uuid, NEW.type);
END;

CREATE TRIGGER atoms_ad_fts
AFTER DELETE ON atoms
WHEN OLD.is_deleted = 0
BEGIN
    DELETE FROM atoms_fts
    WHERE rowid = OLD.rowid;
END;

CREATE TRIGGER atoms_au_fts
AFTER UPDATE ON atoms
BEGIN
    DELETE FROM atoms_fts
    WHERE rowid = OLD.rowid;

    INSERT INTO atoms_fts (rowid, content, uuid, type)
    SELECT NEW.rowid, NEW.content, NEW.uuid, NEW.type
    WHERE NEW.is_deleted = 0;
END;
