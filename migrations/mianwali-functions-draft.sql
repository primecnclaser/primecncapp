-- ══════════════════════════════════════════════
-- DRAFT ONLY — NOT YET APPLIED
-- Adds the audited 4-arg update_customer_name/update_customer_phone
-- to Mianwali, bodies pulled verbatim, fresh, from Jauharabad
-- (jazxyebbbaitvcjeyjly) this pass.
--
-- Mianwali currently only has the OLD 2-arg signatures
-- (update_customer_name(text,text), update_customer_phone(text,text))
-- confirmed fresh — no 4-arg overload exists yet.
--
-- Postgres identifies functions by name + argument types together, so
-- a 4-arg signature does not collide with the existing 2-arg one:
-- plain CREATE OR REPLACE is correct here (creates the new overload
-- alongside the old one), NOT DROP + CREATE — there is nothing with
-- this exact signature to drop first.
--
-- NOTE: this does NOT remove the old 2-arg versions. Jauharabad
-- already dropped its own 2-arg overloads (confirmed absent there)
-- once zero callers remained — whether to do the same on Mianwali is
-- a separate, deliberate follow-up decision, not included here.
-- ══════════════════════════════════════════════

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
$function$
;

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
$function$
;
