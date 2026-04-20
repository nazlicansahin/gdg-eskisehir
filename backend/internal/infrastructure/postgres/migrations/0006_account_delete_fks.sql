-- Staff check-ins reference the scanning user; allow the account to be removed
-- without dropping historical registration rows (checked_in_by becomes unknown).

ALTER TABLE checkins DROP CONSTRAINT IF EXISTS checkins_checked_in_by_fkey;
ALTER TABLE checkins ALTER COLUMN checked_in_by DROP NOT NULL;
ALTER TABLE checkins
  ADD CONSTRAINT checkins_checked_in_by_fkey
  FOREIGN KEY (checked_in_by) REFERENCES users(id) ON DELETE SET NULL;
