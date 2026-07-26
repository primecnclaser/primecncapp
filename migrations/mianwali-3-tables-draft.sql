-- ══════════════════════════════════════════════
-- DRAFT ONLY — NOT YET APPLIED
-- Recreates audit_log, amendment_requests, salaries on Mianwali,
-- pulled fresh from Jauharabad's real current schema (jazxyebbbaitvcjeyjly).
-- ══════════════════════════════════════════════

-- ══════════════════════════════════════════════
-- 1. audit_log
-- ══════════════════════════════════════════════
CREATE TABLE public.audit_log (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  branch_id text NOT NULL DEFAULT 'branch_mianwali',   -- Mianwali's real branch_id default, not Jauharabad's 'branch_main'
  table_name text NOT NULL,
  record_key text NOT NULL,
  action text NOT NULL,
  old_data jsonb,
  new_data jsonb,
  changed_by uuid,
  changed_by_username text,
  changed_at timestamptz NOT NULL DEFAULT now(),
  source text NOT NULL DEFAULT 'app',
  CONSTRAINT audit_log_pkey PRIMARY KEY (id),
  CONSTRAINT audit_log_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES app_users(id),  -- NO ACTION on delete/update, confirmed fresh from Jauharabad
  CONSTRAINT audit_log_action_check CHECK (action = ANY (ARRAY['insert','update','delete']))
);

CREATE INDEX idx_audit_log_changed_at ON public.audit_log USING btree (changed_at DESC);
CREATE INDEX idx_audit_log_table_record ON public.audit_log USING btree (table_name, record_key);

-- RLS deliberately NOT enabled — matches Jauharabad exactly (relrowsecurity=false, 0 policies there).
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON public.audit_log TO anon, authenticated, service_role;


-- ══════════════════════════════════════════════
-- 2. amendment_requests
-- ══════════════════════════════════════════════
CREATE TABLE public.amendment_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  branch_id text NOT NULL DEFAULT 'branch_mianwali',
  table_name text NOT NULL,
  record_key text NOT NULL,
  action text NOT NULL,
  old_data jsonb,
  proposed_new_data jsonb,
  description text,
  requested_by uuid NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  reviewed_by uuid,
  reviewed_at timestamptz,
  review_note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT amendment_requests_pkey PRIMARY KEY (id),
  CONSTRAINT amendment_requests_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES app_users(id),  -- NO ACTION, confirmed fresh
  CONSTRAINT amendment_requests_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES app_users(id),      -- NO ACTION, confirmed fresh
  CONSTRAINT amendment_requests_action_check CHECK (action = ANY (ARRAY['insert','update','delete'])),
  CONSTRAINT amendment_requests_status_check CHECK (status = ANY (ARRAY['pending','approved','denied']))
);

CREATE INDEX idx_amendment_requests_status ON public.amendment_requests USING btree (status);
CREATE INDEX idx_amendment_requests_table_record ON public.amendment_requests USING btree (table_name, record_key);

-- RLS deliberately NOT enabled — matches Jauharabad exactly.
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON public.amendment_requests TO anon, authenticated, service_role;


-- ══════════════════════════════════════════════
-- 3. salaries
-- ══════════════════════════════════════════════
CREATE TABLE public.salaries (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  branch_id text NOT NULL DEFAULT 'branch_mianwali',
  employee_id text NOT NULL,
  period_year integer NOT NULL,
  period_month integer NOT NULL,
  basic_sal numeric,
  base_sal_override numeric,
  arrears numeric DEFAULT 0,
  advance numeric DEFAULT 0,
  cash numeric DEFAULT 0,
  tax numeric DEFAULT 0,
  mess numeric DEFAULT 0,
  room numeric DEFAULT 0,
  nights numeric DEFAULT 0,
  days numeric DEFAULT 0,
  days_worked numeric DEFAULT 0,
  ot_amount numeric,
  gross_sal numeric,
  net_sal numeric,
  remaining_ref numeric,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT salaries_pkey PRIMARY KEY (id),
  CONSTRAINT salaries_branch_id_employee_id_period_year_period_month_key UNIQUE (branch_id, employee_id, period_year, period_month),
  CONSTRAINT salaries_period_month_check CHECK (period_month >= 1 AND period_month <= 12)
);
-- No separate CREATE INDEX needed — the UNIQUE constraint above is Jauharabad's only non-pkey index on this table too.

-- RLS deliberately NOT enabled — matches Jauharabad exactly.
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON public.salaries TO anon, authenticated, service_role;
