-- ============================================================
-- Jauharabad RECREATION SCRIPT (draft, NOT applied)
-- Source project: jazxyebbbaitvcjeyjly (Prime CNC Laser Works Jauharabad)
-- Target project: txztiagmsanitsljcggz (Jauharabad new, empty)
-- Structure: 1) tables (no inline FK)  2) FK constraints  3) indexes
--            4) RLS enable (17 tables only)  5) policies  6) functions
-- ============================================================

-- ============================================================
-- SECTION 0: Sequences required by Section 1 defaults (excel_invoices.id, pending_bills.id)
-- Source sequences were OWNED BY their respective column (standard bigserial ownership);
-- fresh sequences starting at 1 are sufficient here since this step is schema-only —
-- no data is being loaded yet, and the future data-migration step will insert explicit
-- ID values rather than rely on nextval(). Sequences should be advanced via setval()
-- after that data load so future inserts don't collide with the loaded IDs.
-- ============================================================

CREATE SEQUENCE public.excel_invoices_id_seq;
CREATE SEQUENCE public.pending_bills_id_seq;

-- ============================================================
-- SECTION 1: CREATE TABLE statements (21) — PK/UNIQUE/CHECK only, NO FOREIGN KEY
-- ============================================================

-- TABLE: amendment_requests
CREATE TABLE public.amendment_requests (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  branch_id text DEFAULT 'branch_main'::text NOT NULL,
  table_name text NOT NULL,
  record_key text NOT NULL,
  action text NOT NULL,
  old_data jsonb,
  proposed_new_data jsonb,
  description text,
  requested_by uuid NOT NULL,
  status text DEFAULT 'pending'::text NOT NULL,
  reviewed_by uuid,
  reviewed_at timestamp with time zone,
  review_note text,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.amendment_requests ADD CONSTRAINT amendment_requests_pkey PRIMARY KEY (id);
ALTER TABLE public.amendment_requests ADD CONSTRAINT amendment_requests_action_check CHECK ((action = ANY (ARRAY['insert'::text, 'update'::text, 'delete'::text])));
ALTER TABLE public.amendment_requests ADD CONSTRAINT amendment_requests_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'denied'::text])));

-- TABLE: app_users
CREATE TABLE public.app_users (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  username text NOT NULL,
  password_hash text NOT NULL,
  role text DEFAULT 'user'::text NOT NULL,
  display_name text,
  tab_invoice boolean DEFAULT true,
  tab_database boolean DEFAULT true,
  tab_search boolean DEFAULT true,
  tab_summary boolean DEFAULT true,
  tab_finance boolean DEFAULT false,
  tab_settings boolean DEFAULT false,
  finance_edit boolean DEFAULT false,
  force_pw_change boolean DEFAULT false,
  last_login timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  email text,
  phone text,
  profile_setup boolean DEFAULT false,
  tab_payment boolean DEFAULT true,
  tab_production boolean DEFAULT true,
  branch_id text DEFAULT 'branch_main'::text NOT NULL,
  password_salt text
);
ALTER TABLE public.app_users ADD CONSTRAINT app_users_pkey PRIMARY KEY (id);
ALTER TABLE public.app_users ADD CONSTRAINT app_users_username_key UNIQUE (username);
ALTER TABLE public.app_users ADD CONSTRAINT app_users_role_check CHECK ((role = ANY (ARRAY['admin'::text, 'manager'::text, 'user'::text])));

-- TABLE: audit_log
CREATE TABLE public.audit_log (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  branch_id text DEFAULT 'branch_main'::text NOT NULL,
  table_name text NOT NULL,
  record_key text NOT NULL,
  action text NOT NULL,
  old_data jsonb,
  new_data jsonb,
  changed_by uuid,
  changed_by_username text,
  changed_at timestamp with time zone DEFAULT now() NOT NULL,
  source text DEFAULT 'app'::text NOT NULL
);
ALTER TABLE public.audit_log ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);
ALTER TABLE public.audit_log ADD CONSTRAINT audit_log_action_check CHECK ((action = ANY (ARRAY['insert'::text, 'update'::text, 'delete'::text])));

-- TABLE: auth_log
CREATE TABLE public.auth_log (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  username text,
  action text,
  detail text,
  created_at timestamp with time zone DEFAULT now()
);
ALTER TABLE public.auth_log ADD CONSTRAINT auth_log_pkey PRIMARY KEY (id);

-- TABLE: cash_holder_entries
CREATE TABLE public.cash_holder_entries (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  holder_slot integer NOT NULL,
  amount numeric NOT NULL,
  remark text DEFAULT ''::text,
  entry_date date DEFAULT CURRENT_DATE NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  branch_id text DEFAULT 'branch_main'::text NOT NULL
);
ALTER TABLE public.cash_holder_entries ADD CONSTRAINT cash_holder_entries_pkey PRIMARY KEY (id);
ALTER TABLE public.cash_holder_entries ADD CONSTRAINT cash_holder_entries_holder_slot_check CHECK ((holder_slot = ANY (ARRAY[2, 3])));

-- TABLE: cash_holder_names
CREATE TABLE public.cash_holder_names (
  slot integer NOT NULL,
  name text DEFAULT ''::text NOT NULL,
  updated_at timestamp with time zone DEFAULT now(),
  branch_id text DEFAULT 'branch_main'::text NOT NULL
);
ALTER TABLE public.cash_holder_names ADD CONSTRAINT cash_holder_names_pkey PRIMARY KEY (slot);
ALTER TABLE public.cash_holder_names ADD CONSTRAINT cash_holder_names_slot_check CHECK ((slot = ANY (ARRAY[1, 2, 3])));

-- TABLE: customer_payments
CREATE TABLE public.customer_payments (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  customer_name text NOT NULL,
  phone text,
  amount numeric DEFAULT 0 NOT NULL,
  payment_date date,
  type text DEFAULT 'payment'::text NOT NULL,
  source text DEFAULT 'imported'::text,
  note text,
  invoice_ref text,
  created_by text,
  created_at timestamp with time zone DEFAULT now(),
  branch_id text DEFAULT 'branch_main'::text NOT NULL,
  updated_at timestamp with time zone
);
ALTER TABLE public.customer_payments ADD CONSTRAINT customer_payments_pkey PRIMARY KEY (id);

-- TABLE: customer_rates
CREATE TABLE public.customer_rates (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  customer_name text NOT NULL,
  phone text,
  rate_14g numeric,
  rate_16g numeric,
  rate_18g numeric,
  rate_kg numeric,
  created_by text,
  updated_at timestamp with time zone DEFAULT now(),
  branch_id text DEFAULT 'branch_main'::text
);
ALTER TABLE public.customer_rates ADD CONSTRAINT customer_rates_pkey PRIMARY KEY (id);

-- TABLE: edit_access_grants
CREATE TABLE public.edit_access_grants (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  customer_name text NOT NULL,
  phone text,
  granted_to uuid NOT NULL,
  granted_by uuid,
  status text DEFAULT 'active'::text NOT NULL,
  requested_at timestamp with time zone,
  reason text,
  granted_at timestamp with time zone,
  expires_at timestamp with time zone,
  reviewed_by uuid,
  reviewed_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  branch_id text DEFAULT 'branch_main'::text NOT NULL
);
ALTER TABLE public.edit_access_grants ADD CONSTRAINT edit_access_grants_pkey PRIMARY KEY (id);
ALTER TABLE public.edit_access_grants ADD CONSTRAINT edit_access_grants_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'active'::text, 'expired'::text, 'revoked'::text, 'denied'::text])));

-- TABLE: employee_change_requests
CREATE TABLE public.employee_change_requests (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  branch_id text DEFAULT 'branch_main'::text NOT NULL,
  table_name text DEFAULT 'employee_roster'::text NOT NULL,
  record_key text NOT NULL,
  action text DEFAULT 'update'::text NOT NULL,
  old_data jsonb,
  proposed_new_data jsonb,
  requested_by uuid NOT NULL,
  status text DEFAULT 'pending'::text NOT NULL,
  reviewed_by uuid,
  reviewed_at timestamp with time zone,
  reason text,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.employee_change_requests ADD CONSTRAINT employee_change_requests_pkey PRIMARY KEY (id);
ALTER TABLE public.employee_change_requests ADD CONSTRAINT employee_change_requests_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'denied'::text])));

-- TABLE: excel_invoices
CREATE TABLE public.excel_invoices (
  id bigint DEFAULT nextval('excel_invoices_id_seq'::regclass) NOT NULL,
  customer_name text NOT NULL,
  phone text,
  order_num text,
  date date,
  total_bill numeric(12,2) DEFAULT 0 NOT NULL,
  received numeric(12,2) DEFAULT 0 NOT NULL,
  bad_debt numeric(12,2) DEFAULT 0 NOT NULL,
  discount numeric(12,2) DEFAULT 0 NOT NULL,
  remaining numeric(12,2) DEFAULT 0 NOT NULL,
  source text DEFAULT 'excel_import'::text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  received_entries jsonb DEFAULT '[]'::jsonb,
  extra_charges numeric DEFAULT 0,
  extra_charges_label text DEFAULT 'Extra Charges'::text,
  order_status text,
  status_updated_at timestamp with time zone,
  branch_id text DEFAULT 'branch_main'::text NOT NULL,
  updated_at timestamp with time zone
);
ALTER TABLE public.excel_invoices ADD CONSTRAINT excel_invoices_pkey PRIMARY KEY (id);
ALTER TABLE public.excel_invoices ADD CONSTRAINT unique_order_num UNIQUE (order_num);

-- TABLE: finance_ledger
CREATE TABLE public.finance_ledger (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  entry_date date NOT NULL,
  entry_type text NOT NULL,
  category text NOT NULL,
  amount numeric(14,2) DEFAULT 0,
  note text,
  source text DEFAULT 'manual'::text,
  ref_id text,
  created_by text,
  created_at timestamp with time zone DEFAULT now(),
  branch_id text DEFAULT 'branch_main'::text NOT NULL
);
ALTER TABLE public.finance_ledger ADD CONSTRAINT finance_ledger_pkey PRIMARY KEY (id);

-- TABLE: identity_change_requests
CREATE TABLE public.identity_change_requests (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  old_name text NOT NULL,
  old_phone text,
  new_name text,
  new_phone text,
  change_type text NOT NULL,
  requested_by uuid NOT NULL,
  reason text,
  status text DEFAULT 'pending'::text NOT NULL,
  reviewed_by uuid,
  reviewed_at timestamp with time zone,
  rows_affected integer,
  requested_at timestamp with time zone DEFAULT now() NOT NULL,
  branch_id text DEFAULT 'branch_main'::text NOT NULL
);
ALTER TABLE public.identity_change_requests ADD CONSTRAINT identity_change_requests_pkey PRIMARY KEY (id);
ALTER TABLE public.identity_change_requests ADD CONSTRAINT identity_change_requests_change_type_check CHECK ((change_type = ANY (ARRAY['name'::text, 'phone'::text, 'both'::text])));
ALTER TABLE public.identity_change_requests ADD CONSTRAINT identity_change_requests_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'denied'::text])));

-- TABLE: inventory_purchases
CREATE TABLE public.inventory_purchases (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  gauge text NOT NULL,
  sheet_count integer NOT NULL,
  size_label text,
  length_ft numeric NOT NULL,
  width_ft numeric NOT NULL,
  sqft_per_sheet numeric NOT NULL,
  total_sqft numeric NOT NULL,
  weight_kg numeric NOT NULL,
  purchase_date date DEFAULT CURRENT_DATE NOT NULL,
  note text,
  created_by text,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  branch_id text DEFAULT 'branch_main'::text
);
ALTER TABLE public.inventory_purchases ADD CONSTRAINT inventory_purchases_pkey PRIMARY KEY (id);
ALTER TABLE public.inventory_purchases ADD CONSTRAINT inventory_purchases_gauge_check CHECK ((gauge = ANY (ARRAY['14'::text, '16'::text, '18'::text])));

-- TABLE: inventory_sizes
CREATE TABLE public.inventory_sizes (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  label text NOT NULL,
  length_ft numeric NOT NULL,
  width_ft numeric NOT NULL,
  is_custom boolean DEFAULT false NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  branch_id text DEFAULT 'branch_main'::text
);
ALTER TABLE public.inventory_sizes ADD CONSTRAINT inventory_sizes_pkey PRIMARY KEY (id);
ALTER TABLE public.inventory_sizes ADD CONSTRAINT inventory_sizes_label_key UNIQUE (label);

-- TABLE: invoice_items
CREATE TABLE public.invoice_items (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  invoice_id uuid,
  row_num integer,
  sizes text,
  foot numeric DEFAULT 0,
  inch numeric DEFAULT 0,
  sooter numeric DEFAULT 0,
  kg numeric DEFAULT 0,
  qty numeric DEFAULT 0,
  gauge text,
  rate numeric DEFAULT 0,
  sqft numeric DEFAULT 0,
  amount numeric DEFAULT 0,
  mode text DEFAULT 'sqft'::text,
  foot2 numeric DEFAULT 0,
  inch2 numeric DEFAULT 0,
  sooter2 numeric DEFAULT 0,
  branch_id text DEFAULT 'branch_main'::text NOT NULL
);
ALTER TABLE public.invoice_items ADD CONSTRAINT invoice_items_pkey PRIMARY KEY (id);

-- TABLE: invoices
CREATE TABLE public.invoices (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  inv_num text NOT NULL,
  date date,
  cust_name text,
  phone text,
  area text,
  del_date text,
  sub_total numeric DEFAULT 0,
  discount numeric DEFAULT 0,
  total numeric DEFAULT 0,
  received numeric DEFAULT 0,
  remaining numeric DEFAULT 0,
  bad_debt numeric DEFAULT 0,
  created_at timestamp without time zone DEFAULT now(),
  edited_at text,
  is_advance boolean DEFAULT false,
  extra_charges numeric DEFAULT 0,
  extra_charges_label text DEFAULT 'Extra Charges'::text,
  order_status text,
  status_updated_at timestamp with time zone,
  total_sqft numeric DEFAULT 0,
  total_kg numeric DEFAULT 0,
  branch_id text DEFAULT 'branch_main'::text NOT NULL,
  updated_at timestamp with time zone
);
ALTER TABLE public.invoices ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);
ALTER TABLE public.invoices ADD CONSTRAINT invoices_inv_num_unique UNIQUE (inv_num);
ALTER TABLE public.invoices ADD CONSTRAINT unique_inv_num UNIQUE (inv_num);

-- TABLE: pending_bills
CREATE TABLE public.pending_bills (
  id bigint DEFAULT nextval('pending_bills_id_seq'::regclass) NOT NULL,
  customer_name text,
  phone text,
  area text,
  order_no text,
  bill_date text,
  total_bill numeric DEFAULT 0,
  received1 numeric DEFAULT 0,
  received2 numeric DEFAULT 0,
  discount numeric DEFAULT 0,
  bad_debt numeric DEFAULT 0,
  pending_balance numeric DEFAULT 0,
  source text DEFAULT 'excel_import'::text,
  created_at timestamp with time zone DEFAULT now(),
  branch_id text DEFAULT 'branch_main'::text NOT NULL
);
ALTER TABLE public.pending_bills ADD CONSTRAINT pending_bills_pkey PRIMARY KEY (id);

-- TABLE: salaries
CREATE TABLE public.salaries (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  branch_id text DEFAULT 'branch_main'::text NOT NULL,
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
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);
ALTER TABLE public.salaries ADD CONSTRAINT salaries_pkey PRIMARY KEY (id);
ALTER TABLE public.salaries ADD CONSTRAINT salaries_branch_id_employee_id_period_year_period_month_key UNIQUE (branch_id, employee_id, period_year, period_month);
ALTER TABLE public.salaries ADD CONSTRAINT salaries_period_month_check CHECK (((period_month >= 1) AND (period_month <= 12)));

-- TABLE: shop_settings
CREATE TABLE public.shop_settings (
  key text NOT NULL,
  value text,
  updated_at timestamp with time zone DEFAULT now(),
  branch_id text DEFAULT 'branch_main'::text NOT NULL
);
ALTER TABLE public.shop_settings ADD CONSTRAINT shop_settings_pkey PRIMARY KEY (key);

-- TABLE: sync_conflict_log
CREATE TABLE public.sync_conflict_log (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  table_name text NOT NULL,
  record_key text NOT NULL,
  field text,
  local_value text,
  remote_value text,
  resolution text NOT NULL,
  device_id text,
  created_by text,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.sync_conflict_log ADD CONSTRAINT sync_conflict_log_pkey PRIMARY KEY (id);

-- ============================================================
-- SECTION 2: FOREIGN KEY constraints (applied only after all tables exist)
-- ============================================================

ALTER TABLE public.amendment_requests ADD CONSTRAINT amendment_requests_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES app_users(id);
ALTER TABLE public.amendment_requests ADD CONSTRAINT amendment_requests_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES app_users(id);
ALTER TABLE public.audit_log ADD CONSTRAINT audit_log_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES app_users(id);
ALTER TABLE public.edit_access_grants ADD CONSTRAINT edit_access_grants_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES app_users(id) ON DELETE SET NULL;
ALTER TABLE public.edit_access_grants ADD CONSTRAINT edit_access_grants_granted_to_fkey FOREIGN KEY (granted_to) REFERENCES app_users(id) ON DELETE CASCADE;
ALTER TABLE public.edit_access_grants ADD CONSTRAINT edit_access_grants_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES app_users(id) ON DELETE SET NULL;
ALTER TABLE public.employee_change_requests ADD CONSTRAINT employee_change_requests_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES app_users(id) ON DELETE CASCADE;
ALTER TABLE public.employee_change_requests ADD CONSTRAINT employee_change_requests_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES app_users(id) ON DELETE SET NULL;
ALTER TABLE public.identity_change_requests ADD CONSTRAINT identity_change_requests_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES app_users(id) ON DELETE CASCADE;
ALTER TABLE public.identity_change_requests ADD CONSTRAINT identity_change_requests_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES app_users(id) ON DELETE SET NULL;
ALTER TABLE public.invoice_items ADD CONSTRAINT invoice_items_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE;

-- ============================================================
-- SECTION 3: Non-PK indexes
-- ============================================================

CREATE INDEX idx_amendment_requests_status ON public.amendment_requests USING btree (status);
CREATE INDEX idx_amendment_requests_table_record ON public.amendment_requests USING btree (table_name, record_key);
CREATE INDEX idx_app_users_branch_id ON public.app_users USING btree (branch_id);
CREATE INDEX idx_audit_log_changed_at ON public.audit_log USING btree (changed_at DESC);
CREATE INDEX idx_audit_log_table_record ON public.audit_log USING btree (table_name, record_key);
CREATE INDEX idx_cash_holder_entries_slot ON public.cash_holder_entries USING btree (holder_slot);
CREATE INDEX idx_customer_payments_branch_id ON public.customer_payments USING btree (branch_id);
CREATE INDEX idx_customer_payments_customer_name ON public.customer_payments USING btree (customer_name);
CREATE INDEX idx_customer_payments_invoice_ref ON public.customer_payments USING btree (invoice_ref);
CREATE INDEX idx_customer_payments_payment_date ON public.customer_payments USING btree (payment_date);
CREATE INDEX idx_customer_payments_type ON public.customer_payments USING btree (type);
CREATE UNIQUE INDEX uq_customer_payments_invoice_type_live ON public.customer_payments USING btree (invoice_ref, type) WHERE (source <> 'imported'::text);
CREATE UNIQUE INDEX customer_rates_name_key ON public.customer_rates USING btree (lower(TRIM(BOTH FROM customer_name))) WHERE ((phone IS NULL) OR (phone = ''::text));
CREATE UNIQUE INDEX customer_rates_phone_key ON public.customer_rates USING btree ("right"(regexp_replace(phone, '\D'::text, ''::text, 'g'::text), 10)) WHERE ((phone IS NOT NULL) AND (phone <> ''::text));
CREATE INDEX idx_eag_customer ON public.edit_access_grants USING btree (customer_name, phone);
CREATE INDEX idx_eag_granted_to ON public.edit_access_grants USING btree (granted_to, status);
CREATE INDEX idx_eag_status ON public.edit_access_grants USING btree (status);
CREATE INDEX idx_excel_invoices_branch_id ON public.excel_invoices USING btree (branch_id);
CREATE INDEX idx_excel_invoices_customer_name ON public.excel_invoices USING btree (customer_name);
CREATE INDEX idx_excel_invoices_date ON public.excel_invoices USING btree (date);
CREATE INDEX idx_excel_invoices_name ON public.excel_invoices USING btree (customer_name);
CREATE INDEX idx_excel_invoices_order ON public.excel_invoices USING btree (order_num);
CREATE INDEX idx_excel_invoices_order_num ON public.excel_invoices USING btree (order_num);
CREATE INDEX idx_excel_invoices_order_status ON public.excel_invoices USING btree (order_status);
CREATE INDEX idx_excel_invoices_phone ON public.excel_invoices USING btree (phone);
CREATE UNIQUE INDEX idx_excel_invoices_unique ON public.excel_invoices USING btree (order_num, source) WHERE (order_num IS NOT NULL);
CREATE INDEX finance_ledger_entry_date_idx ON public.finance_ledger USING btree (entry_date);
CREATE INDEX finance_ledger_entry_date_idx1 ON public.finance_ledger USING btree (entry_date);
CREATE INDEX finance_ledger_entry_type_idx ON public.finance_ledger USING btree (entry_type);
CREATE INDEX finance_ledger_entry_type_idx1 ON public.finance_ledger USING btree (entry_type);
CREATE INDEX finance_ledger_source_idx ON public.finance_ledger USING btree (source);
CREATE INDEX finance_ledger_source_idx1 ON public.finance_ledger USING btree (source);
CREATE INDEX idx_finance_ledger_branch_id ON public.finance_ledger USING btree (branch_id);
CREATE INDEX idx_finance_ledger_category ON public.finance_ledger USING btree (category);
CREATE INDEX idx_finance_ledger_entry_date ON public.finance_ledger USING btree (entry_date);
CREATE UNIQUE INDEX uq_manual_entry_date_type_cat ON public.finance_ledger USING btree (entry_date, entry_type, category) WHERE (source = 'manual'::text);
CREATE INDEX idx_icr_requested_by ON public.identity_change_requests USING btree (requested_by);
CREATE INDEX idx_icr_status ON public.identity_change_requests USING btree (status);
CREATE INDEX idx_invoices_branch_id ON public.invoices USING btree (branch_id);
CREATE INDEX idx_invoices_cust_name ON public.invoices USING btree (cust_name);
CREATE INDEX idx_invoices_inv_num ON public.invoices USING btree (inv_num);
CREATE INDEX idx_invoices_order_status ON public.invoices USING btree (order_status);
CREATE INDEX idx_pb_name ON public.pending_bills USING btree (customer_name);
CREATE INDEX idx_pb_phone ON public.pending_bills USING btree (phone);

-- ============================================================
-- SECTION 4: Enable Row Level Security — 17 tables that have it in source
-- (amendment_requests, audit_log, employee_change_requests, salaries deliberately excluded)
-- ============================================================

ALTER TABLE public.app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.auth_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_holder_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_holder_names ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.edit_access_grants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.excel_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.finance_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.identity_change_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_sizes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pending_bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shop_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_conflict_log ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- SECTION 5: RLS Policies (17 tables)
-- ============================================================

-- Policies for app_users
CREATE POLICY "allow_all_app_users" ON public.app_users AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon full access app_users" ON public.app_users AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);

-- Policies for auth_log
CREATE POLICY "anon full access auth_log" ON public.auth_log AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);

-- Policies for cash_holder_entries
CREATE POLICY "anon full access cash_holder_entries" ON public.cash_holder_entries AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);

-- Policies for cash_holder_names
CREATE POLICY "anon full access cash_holder_names" ON public.cash_holder_names AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);

-- Policies for customer_payments
CREATE POLICY "allow_all_customer_payments" ON public.customer_payments AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);

-- Policies for customer_rates
CREATE POLICY "allow_all_customer_rates" ON public.customer_rates AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);

-- Policies for edit_access_grants
CREATE POLICY "allow_all_edit_access_grants" ON public.edit_access_grants AS PERMISSIVE FOR ALL TO anon,authenticated USING (true) WITH CHECK (true);

-- Policies for excel_invoices
CREATE POLICY "allow_all_excel_invoices" ON public.excel_invoices AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon full access excel_invoices" ON public.excel_invoices AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);

-- Policies for finance_ledger
CREATE POLICY "Allow anon full access" ON public.finance_ledger AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_finance_ledger" ON public.finance_ledger AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon full access finance_ledger" ON public.finance_ledger AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);

-- Policies for identity_change_requests
CREATE POLICY "allow_all_identity_change_requests" ON public.identity_change_requests AS PERMISSIVE FOR ALL TO anon,authenticated USING (true) WITH CHECK (true);

-- Policies for inventory_purchases
CREATE POLICY "allow_all_inventory_purchases" ON public.inventory_purchases AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);

-- Policies for inventory_sizes
CREATE POLICY "allow_all_inventory_sizes" ON public.inventory_sizes AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);

-- Policies for invoice_items
CREATE POLICY "allow all" ON public.invoice_items AS PERMISSIVE FOR ALL TO public USING (true);
CREATE POLICY "anon full access invoice_items" ON public.invoice_items AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);

-- Policies for invoices
CREATE POLICY "allow all" ON public.invoices AS PERMISSIVE FOR ALL TO public USING (true);
CREATE POLICY "allow_all_invoices" ON public.invoices AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon full access invoices" ON public.invoices AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);

-- Policies for pending_bills
CREATE POLICY "anon full access pending_bills" ON public.pending_bills AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);

-- Policies for shop_settings
CREATE POLICY "allow_all_shop_settings" ON public.shop_settings AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon full access shop_settings" ON public.shop_settings AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);

-- Policies for sync_conflict_log
CREATE POLICY "allow_all_sync_conflict_log" ON public.sync_conflict_log AS PERMISSIVE FOR ALL TO anon USING (true) WITH CHECK (true);

-- ============================================================
-- SECTION 6: Custom functions (8)
-- ============================================================

-- FUNCTION: count_customer_invoices
CREATE OR REPLACE FUNCTION public.count_customer_invoices(p_name text)
 RETURNS TABLE(inv_count bigint, excel_count bigint, pay_count bigint, grant_count bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*) FROM invoices WHERE cust_name ILIKE p_name) AS inv_count,
    (SELECT COUNT(*) FROM excel_invoices WHERE customer_name ILIKE p_name) AS excel_count,
    (SELECT COUNT(*) FROM customer_payments WHERE customer_name ILIKE p_name) AS pay_count,
    (SELECT COUNT(*) FROM edit_access_grants WHERE customer_name ILIKE p_name AND customer_name != '__ALL__') AS grant_count;
END;
$function$;

-- FUNCTION: get_latest_production_orders
CREATE OR REPLACE FUNCTION public.get_latest_production_orders(p_limit integer DEFAULT 30)
 RETURNS TABLE(id text, inv_num text, customer_name text, phone text, total numeric, inv_date text, order_status text, status_updated_at timestamp with time zone, total_sqft numeric, total_kg numeric, source text, inv_number_int integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT * FROM (
    SELECT i.id::text, i.inv_num, i.cust_name as customer_name, i.phone, i.total,
      i.date::text as inv_date, i.order_status, i.status_updated_at,
      COALESCE(i.total_sqft,0) as total_sqft, COALESCE(i.total_kg,0) as total_kg,
      'new'::text as source,
      regexp_replace(i.inv_num,'[^0-9]','','g')::integer as inv_number_int
    FROM invoices i WHERE i.order_status IS DISTINCT FROM 'delivered'
    AND i.cust_name IS NOT NULL AND i.total > 0
    UNION ALL
    SELECT e.id::text, 'INV-'||e.order_num::text, e.customer_name, e.phone,
      e.total_bill as total, e.date::text as inv_date, e.order_status, e.status_updated_at,
      0::numeric, 0::numeric, 'excel'::text as source, e.order_num::integer
    FROM excel_invoices e WHERE e.order_status IS DISTINCT FROM 'delivered'
    AND e.customer_name IS NOT NULL AND e.total_bill > 0
  ) combined ORDER BY inv_number_int DESC LIMIT p_limit;
END;
$function$;

-- FUNCTION: merge_shop_setting_array_item
CREATE OR REPLACE FUNCTION public.merge_shop_setting_array_item(p_key text, p_id_field text, p_id_value text, p_item jsonb)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
  v_current jsonb;
  v_found boolean;
begin
  select value::jsonb into v_current from shop_settings where key = p_key for update;
  if v_current is null then
    v_current := '[]'::jsonb;
  end if;

  select coalesce(bool_or(elem->>p_id_field = p_id_value), false) into v_found
  from jsonb_array_elements(v_current) elem;

  if v_found then
    select jsonb_agg(case when elem->>p_id_field = p_id_value then p_item else elem end)
      into v_current
    from jsonb_array_elements(v_current) elem;
  else
    v_current := v_current || jsonb_build_array(p_item);
  end if;

  insert into shop_settings (key, value, updated_at)
  values (p_key, v_current, now())
  on conflict (key) do update
    set value = excluded.value, updated_at = now();
end;
$function$;

-- FUNCTION: merge_shop_setting_subkey
CREATE OR REPLACE FUNCTION public.merge_shop_setting_subkey(p_key text, p_subkey text, p_value jsonb)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
  insert into shop_settings (key, value, updated_at)
  values (p_key, jsonb_build_object(p_subkey, p_value), now())
  on conflict (key) do update
    set value = coalesce(shop_settings.value::jsonb, '{}'::jsonb) || jsonb_build_object(p_subkey, p_value),
        updated_at = now();
end;
$function$;

-- FUNCTION: rename_customer_in_drafts
CREATE OR REPLACE FUNCTION public.rename_customer_in_drafts(p_old_name text, p_new_name text)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_count INTEGER := 0;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM shop_settings, jsonb_array_elements(value::jsonb) elem
  WHERE key = 'inv_drafts' AND elem->>'custName' ILIKE p_old_name;

  IF v_count > 0 THEN
    UPDATE shop_settings
    SET value = (
      SELECT jsonb_agg(
        CASE WHEN elem->>'custName' ILIKE p_old_name
             THEN jsonb_set(elem, '{custName}', to_jsonb(p_new_name))
             ELSE elem
        END
      )
      FROM jsonb_array_elements(value::jsonb) elem
    )::text
    WHERE key = 'inv_drafts';
  END IF;

  RETURN v_count;
END;
$function$;

-- FUNCTION: update_customer_name
CREATE OR REPLACE FUNCTION public.update_customer_name(p_old_name text, p_new_name text, p_changed_by uuid, p_changed_by_username text)
 RETURNS TABLE(total bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_inv_count BIGINT := 0;
  v_excel_count BIGINT := 0;
  v_pay_count BIGINT := 0;
  v_grant_count BIGINT := 0;
  v_rates_count BIGINT := 0;
  v_inv_rows    invoices[];
  v_excel_rows  excel_invoices[];
  v_pay_rows    customer_payments[];
  v_grant_rows  edit_access_grants[];
  v_rates_rows  customer_rates[];
  r_inv         invoices;
  r_excel       excel_invoices;
  r_pay         customer_payments;
  r_grant       edit_access_grants;
  r_rates       customer_rates;
BEGIN
  SELECT array_agg(t) INTO v_inv_rows FROM invoices t WHERE t.cust_name ILIKE p_old_name;
  UPDATE invoices SET cust_name = p_new_name
  WHERE cust_name ILIKE p_old_name;
  GET DIAGNOSTICS v_inv_count = ROW_COUNT;

  SELECT array_agg(t) INTO v_excel_rows FROM excel_invoices t WHERE t.customer_name ILIKE p_old_name;
  UPDATE excel_invoices SET customer_name = p_new_name
  WHERE customer_name ILIKE p_old_name;
  GET DIAGNOSTICS v_excel_count = ROW_COUNT;

  SELECT array_agg(t) INTO v_pay_rows FROM customer_payments t WHERE t.customer_name ILIKE p_old_name;
  UPDATE customer_payments SET customer_name = p_new_name
  WHERE customer_name ILIKE p_old_name;
  GET DIAGNOSTICS v_pay_count = ROW_COUNT;

  SELECT array_agg(t) INTO v_grant_rows FROM edit_access_grants t
    WHERE t.customer_name ILIKE p_old_name AND t.customer_name != '__ALL__';
  UPDATE edit_access_grants SET customer_name = p_new_name
  WHERE customer_name ILIKE p_old_name AND customer_name != '__ALL__';
  GET DIAGNOSTICS v_grant_count = ROW_COUNT;

  -- customer_rates: identity anchor is phone (untouched here), only the
  -- display name is relabeled so saved rates keep following the same
  -- phone-keyed row through a rename.
  SELECT array_agg(t) INTO v_rates_rows FROM customer_rates t WHERE t.customer_name ILIKE p_old_name;
  UPDATE customer_rates SET customer_name = p_new_name, updated_at = now()
  WHERE customer_name ILIKE p_old_name;
  GET DIAGNOSTICS v_rates_count = ROW_COUNT;

  -- Audit logging — wrapped so a failure anywhere in here can never roll
  -- back the 5 UPDATE statements above, which have already succeeded.
  BEGIN
    IF v_inv_rows IS NOT NULL THEN
      FOREACH r_inv IN ARRAY v_inv_rows LOOP
        INSERT INTO audit_log (table_name, record_key, action, old_data, new_data, changed_by, changed_by_username, source)
        VALUES ('invoices', r_inv.id::text, 'update', to_jsonb(r_inv),
                to_jsonb(r_inv) || jsonb_build_object('cust_name', p_new_name),
                p_changed_by, p_changed_by_username, 'app');
      END LOOP;
    END IF;

    IF v_excel_rows IS NOT NULL THEN
      FOREACH r_excel IN ARRAY v_excel_rows LOOP
        INSERT INTO audit_log (table_name, record_key, action, old_data, new_data, changed_by, changed_by_username, source)
        VALUES ('excel_invoices', r_excel.id::text, 'update', to_jsonb(r_excel),
                to_jsonb(r_excel) || jsonb_build_object('customer_name', p_new_name),
                p_changed_by, p_changed_by_username, 'app');
      END LOOP;
    END IF;

    IF v_pay_rows IS NOT NULL THEN
      FOREACH r_pay IN ARRAY v_pay_rows LOOP
        INSERT INTO audit_log (table_name, record_key, action, old_data, new_data, changed_by, changed_by_username, source)
        VALUES ('customer_payments', r_pay.id::text, 'update', to_jsonb(r_pay),
                to_jsonb(r_pay) || jsonb_build_object('customer_name', p_new_name),
                p_changed_by, p_changed_by_username, 'app');
      END LOOP;
    END IF;

    IF v_grant_rows IS NOT NULL THEN
      FOREACH r_grant IN ARRAY v_grant_rows LOOP
        INSERT INTO audit_log (table_name, record_key, action, old_data, new_data, changed_by, changed_by_username, source)
        VALUES ('edit_access_grants', r_grant.id::text, 'update', to_jsonb(r_grant),
                to_jsonb(r_grant) || jsonb_build_object('customer_name', p_new_name),
                p_changed_by, p_changed_by_username, 'app');
      END LOOP;
    END IF;

    IF v_rates_rows IS NOT NULL THEN
      FOREACH r_rates IN ARRAY v_rates_rows LOOP
        INSERT INTO audit_log (table_name, record_key, action, old_data, new_data, changed_by, changed_by_username, source)
        VALUES ('customer_rates', r_rates.id::text, 'update', to_jsonb(r_rates),
                to_jsonb(r_rates) || jsonb_build_object('customer_name', p_new_name, 'updated_at', now()),
                p_changed_by, p_changed_by_username, 'app');
      END LOOP;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    NULL; -- swallow any audit-logging failure; the real updates above already committed
  END;

  RETURN QUERY SELECT (v_inv_count + v_excel_count + v_pay_count + v_grant_count + v_rates_count);
END;
$function$;

-- FUNCTION: update_customer_phone
CREATE OR REPLACE FUNCTION public.update_customer_phone(p_name text, p_phone text, p_changed_by uuid, p_changed_by_username text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_inv_count   INTEGER := 0;
  v_excel_count INTEGER := 0;
  v_pay_count   INTEGER := 0;
  v_grant_count INTEGER := 0;
  v_rates_count INTEGER := 0;
  v_inv_rows    invoices[];
  v_excel_rows  excel_invoices[];
  v_pay_rows    customer_payments[];
  v_grant_rows  edit_access_grants[];
  v_rates_rows  customer_rates[];
  r_inv         invoices;
  r_excel       excel_invoices;
  r_pay         customer_payments;
  r_grant       edit_access_grants;
  r_rates       customer_rates;
BEGIN
  SELECT array_agg(t) INTO v_inv_rows FROM invoices t WHERE TRIM(t.cust_name) ILIKE TRIM(p_name);
  UPDATE invoices
  SET phone = p_phone
  WHERE TRIM(cust_name) ILIKE TRIM(p_name);
  GET DIAGNOSTICS v_inv_count = ROW_COUNT;

  SELECT array_agg(t) INTO v_excel_rows FROM excel_invoices t WHERE TRIM(t.customer_name) ILIKE TRIM(p_name);
  UPDATE excel_invoices
  SET phone = p_phone
  WHERE TRIM(customer_name) ILIKE TRIM(p_name);
  GET DIAGNOSTICS v_excel_count = ROW_COUNT;

  SELECT array_agg(t) INTO v_pay_rows FROM customer_payments t WHERE TRIM(t.customer_name) ILIKE TRIM(p_name);
  UPDATE customer_payments
  SET phone = p_phone
  WHERE TRIM(customer_name) ILIKE TRIM(p_name);
  GET DIAGNOSTICS v_pay_count = ROW_COUNT;

  SELECT array_agg(t) INTO v_grant_rows FROM edit_access_grants t
    WHERE TRIM(t.customer_name) ILIKE TRIM(p_name) AND t.customer_name != '__ALL__';
  UPDATE edit_access_grants
  SET phone = p_phone
  WHERE TRIM(customer_name) ILIKE TRIM(p_name) AND customer_name != '__ALL__';
  GET DIAGNOSTICS v_grant_count = ROW_COUNT;

  SELECT array_agg(t) INTO v_rates_rows FROM customer_rates t WHERE TRIM(t.customer_name) ILIKE TRIM(p_name);
  UPDATE customer_rates
  SET phone = p_phone, updated_at = now()
  WHERE TRIM(customer_name) ILIKE TRIM(p_name);
  GET DIAGNOSTICS v_rates_count = ROW_COUNT;

  -- Audit logging — wrapped so a failure anywhere in here can never roll
  -- back the 5 UPDATE statements above, which have already succeeded.
  BEGIN
    IF v_inv_rows IS NOT NULL THEN
      FOREACH r_inv IN ARRAY v_inv_rows LOOP
        INSERT INTO audit_log (table_name, record_key, action, old_data, new_data, changed_by, changed_by_username, source)
        VALUES ('invoices', r_inv.id::text, 'update', to_jsonb(r_inv),
                to_jsonb(r_inv) || jsonb_build_object('phone', p_phone),
                p_changed_by, p_changed_by_username, 'app');
      END LOOP;
    END IF;

    IF v_excel_rows IS NOT NULL THEN
      FOREACH r_excel IN ARRAY v_excel_rows LOOP
        INSERT INTO audit_log (table_name, record_key, action, old_data, new_data, changed_by, changed_by_username, source)
        VALUES ('excel_invoices', r_excel.id::text, 'update', to_jsonb(r_excel),
                to_jsonb(r_excel) || jsonb_build_object('phone', p_phone),
                p_changed_by, p_changed_by_username, 'app');
      END LOOP;
    END IF;

    IF v_pay_rows IS NOT NULL THEN
      FOREACH r_pay IN ARRAY v_pay_rows LOOP
        INSERT INTO audit_log (table_name, record_key, action, old_data, new_data, changed_by, changed_by_username, source)
        VALUES ('customer_payments', r_pay.id::text, 'update', to_jsonb(r_pay),
                to_jsonb(r_pay) || jsonb_build_object('phone', p_phone),
                p_changed_by, p_changed_by_username, 'app');
      END LOOP;
    END IF;

    IF v_grant_rows IS NOT NULL THEN
      FOREACH r_grant IN ARRAY v_grant_rows LOOP
        INSERT INTO audit_log (table_name, record_key, action, old_data, new_data, changed_by, changed_by_username, source)
        VALUES ('edit_access_grants', r_grant.id::text, 'update', to_jsonb(r_grant),
                to_jsonb(r_grant) || jsonb_build_object('phone', p_phone),
                p_changed_by, p_changed_by_username, 'app');
      END LOOP;
    END IF;

    IF v_rates_rows IS NOT NULL THEN
      FOREACH r_rates IN ARRAY v_rates_rows LOOP
        INSERT INTO audit_log (table_name, record_key, action, old_data, new_data, changed_by, changed_by_username, source)
        VALUES ('customer_rates', r_rates.id::text, 'update', to_jsonb(r_rates),
                to_jsonb(r_rates) || jsonb_build_object('phone', p_phone, 'updated_at', now()),
                p_changed_by, p_changed_by_username, 'app');
      END LOOP;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    NULL; -- swallow any audit-logging failure; the real updates above already committed
  END;

  RETURN json_build_object(
    'success', true,
    'invoices_updated', v_inv_count,
    'excel_updated', v_excel_count,
    'payments_updated', v_pay_count,
    'grants_updated', v_grant_count,
    'rates_updated', v_rates_count,
    'total', v_inv_count + v_excel_count + v_pay_count + v_grant_count + v_rates_count
  );
END;
$function$;

-- FUNCTION: upsert_customer_payment_live
CREATE OR REPLACE FUNCTION public.upsert_customer_payment_live(p_invoice_ref text, p_type text, p_customer_name text, p_phone text, p_amount numeric, p_payment_date date, p_note text, p_created_by text)
 RETURNS TABLE(id uuid, was_conflict boolean)
 LANGUAGE sql
AS $function$
  INSERT INTO customer_payments
    (customer_name, phone, amount, payment_date, type, source, note, invoice_ref, created_by, updated_at)
  VALUES
    (p_customer_name, p_phone, p_amount, p_payment_date, p_type, 'non_imported', p_note, p_invoice_ref, p_created_by, now())
  ON CONFLICT (invoice_ref, type) WHERE source <> 'imported'
  DO UPDATE SET amount = EXCLUDED.amount, updated_at = EXCLUDED.updated_at
  RETURNING customer_payments.id, (xmax <> 0) AS was_conflict;
$function$;
