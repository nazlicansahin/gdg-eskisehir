CREATE TABLE IF NOT EXISTS sponsors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NULL REFERENCES events(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  logo_url TEXT,
  website_url TEXT,
  tier TEXT NOT NULL DEFAULT 'partner' CHECK (tier IN ('platinum', 'gold', 'silver', 'partner')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sponsors_event ON sponsors(event_id);
