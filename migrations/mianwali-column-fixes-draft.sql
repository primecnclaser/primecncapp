-- ══════════════════════════════════════════════
-- DRAFT ONLY — NOT YET APPLIED
-- Fixes 2 column-level discrepancies on Mianwali vs. Jauharabad
-- (jazxyebbbaitvcjeyjly is the source of truth for both).
-- Corrected after first attempt failed: text -> date has no implicit
-- cast in Postgres regardless of row count; USING clause required.
-- ══════════════════════════════════════════════

-- app_users.password_salt: confirmed fresh from Jauharabad —
-- data_type=text, is_nullable=YES, column_default=null
ALTER TABLE public.app_users
  ADD COLUMN password_salt text;

-- invoices.date: text -> date. invoices confirmed empty (0 rows) on
-- Mianwali, re-confirmed fresh immediately before applying. USING
-- clause required by Postgres regardless of row count.
ALTER TABLE public.invoices
  ALTER COLUMN date TYPE date USING date::date;
