-- ══════════════════════════════════════════════
-- DRAFT ONLY — NOT YET APPLIED
-- Fixes 6 FK ON DELETE actions on Mianwali to match Jauharabad's real,
-- confirmed definitions. Constraint names pulled fresh from Mianwali's
-- actual pg_constraint rows (jazxyebbbaitvcjeyjly is the source of truth
-- for the target actions; fmaitcnrqclojaqwncmz is being fixed).
-- All 3 affected tables currently have 0 rows on Mianwali — no existing
-- data to violate the new CASCADE/SET NULL behavior.
-- ══════════════════════════════════════════════

-- edit_access_grants.granted_by → app_users(id) ON DELETE SET NULL
ALTER TABLE public.edit_access_grants
  DROP CONSTRAINT edit_access_grants_granted_by_fkey;
ALTER TABLE public.edit_access_grants
  ADD CONSTRAINT edit_access_grants_granted_by_fkey
  FOREIGN KEY (granted_by) REFERENCES app_users(id) ON DELETE SET NULL;

-- edit_access_grants.granted_to → app_users(id) ON DELETE CASCADE
ALTER TABLE public.edit_access_grants
  DROP CONSTRAINT edit_access_grants_granted_to_fkey;
ALTER TABLE public.edit_access_grants
  ADD CONSTRAINT edit_access_grants_granted_to_fkey
  FOREIGN KEY (granted_to) REFERENCES app_users(id) ON DELETE CASCADE;

-- edit_access_grants.reviewed_by → app_users(id) ON DELETE SET NULL
ALTER TABLE public.edit_access_grants
  DROP CONSTRAINT edit_access_grants_reviewed_by_fkey;
ALTER TABLE public.edit_access_grants
  ADD CONSTRAINT edit_access_grants_reviewed_by_fkey
  FOREIGN KEY (reviewed_by) REFERENCES app_users(id) ON DELETE SET NULL;

-- identity_change_requests.requested_by → app_users(id) ON DELETE CASCADE
ALTER TABLE public.identity_change_requests
  DROP CONSTRAINT identity_change_requests_requested_by_fkey;
ALTER TABLE public.identity_change_requests
  ADD CONSTRAINT identity_change_requests_requested_by_fkey
  FOREIGN KEY (requested_by) REFERENCES app_users(id) ON DELETE CASCADE;

-- identity_change_requests.reviewed_by → app_users(id) ON DELETE SET NULL
ALTER TABLE public.identity_change_requests
  DROP CONSTRAINT identity_change_requests_reviewed_by_fkey;
ALTER TABLE public.identity_change_requests
  ADD CONSTRAINT identity_change_requests_reviewed_by_fkey
  FOREIGN KEY (reviewed_by) REFERENCES app_users(id) ON DELETE SET NULL;

-- invoice_items.invoice_id → invoices(id) ON DELETE CASCADE
ALTER TABLE public.invoice_items
  DROP CONSTRAINT invoice_items_invoice_id_fkey;
ALTER TABLE public.invoice_items
  ADD CONSTRAINT invoice_items_invoice_id_fkey
  FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE;
