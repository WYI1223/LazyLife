-- Migration: 0010_s1_core_fields.sql
-- Purpose: S1 ruling R2/R3/R8 — add title, content_type; rename type → view_hint; rebuild FTS.
-- Invariants:
-- - title is non-empty for atoms with non-empty content (backfilled from first line).
-- - content_type defaults to 'markdown' for all existing and new atoms.
-- - view_hint preserves original type values ('note','task','event').
-- - FTS5 now indexes both content and title for search.
-- Backward compatibility:
-- - Requires SQLite ≥ 3.25 for RENAME COLUMN.
-- - CHECK constraint on type is auto-updated to reference view_hint.

-- 1. Add new columns
ALTER TABLE atoms ADD COLUMN title TEXT NOT NULL DEFAULT '';
ALTER TABLE atoms ADD COLUMN content_type TEXT DEFAULT 'markdown';

-- 2. Rename type → view_hint (SQLite 3.25+)
ALTER TABLE atoms RENAME COLUMN type TO view_hint;

-- 3. Backfill title from content first non-empty line, strip '#', trim, max 50 chars
UPDATE atoms SET title = SUBSTR(
  TRIM(REPLACE(
    SUBSTR(content, 1, INSTR(content || X'0A', X'0A') - 1),
    '#', ''
  )),
  1, 50
) WHERE content != '' AND title = '';

-- 4. Drop old FTS table and triggers (they reference 'type' column)
DROP TRIGGER IF EXISTS atoms_ai_fts;
DROP TRIGGER IF EXISTS atoms_ad_fts;
DROP TRIGGER IF EXISTS atoms_au_fts;
DROP TABLE IF EXISTS atoms_fts;

-- 5. Rebuild FTS5 with title column (standalone mode, same as original)
CREATE VIRTUAL TABLE atoms_fts USING fts5(
  content,
  title,
  tokenize = 'unicode61'
);

-- 6. Populate FTS from existing data
INSERT INTO atoms_fts(rowid, content, title)
  SELECT rowid, content, title FROM atoms WHERE is_deleted = 0;

-- 7. Rebuild triggers (standalone FTS, insert/delete by rowid)
CREATE TRIGGER atoms_ai_fts AFTER INSERT ON atoms
WHEN NEW.is_deleted = 0
BEGIN
  INSERT INTO atoms_fts(rowid, content, title) VALUES (NEW.rowid, NEW.content, NEW.title);
END;

CREATE TRIGGER atoms_ad_fts AFTER DELETE ON atoms
BEGIN
  DELETE FROM atoms_fts WHERE rowid = OLD.rowid;
END;

CREATE TRIGGER atoms_au_fts AFTER UPDATE ON atoms
BEGIN
  DELETE FROM atoms_fts WHERE rowid = OLD.rowid;
  INSERT INTO atoms_fts(rowid, content, title)
    SELECT NEW.rowid, NEW.content, NEW.title WHERE NEW.is_deleted = 0;
END;
