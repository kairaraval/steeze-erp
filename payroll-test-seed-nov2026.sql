-- ============================================================
-- Steeze OS — TEST payroll attendance seed (cutoff Nov 1–15, 2026)
-- Paste into Supabase → SQL Editor → Run.
-- Seeds varied approved DTR days for 8 employees + 1 pending OT filing,
-- all marked source='test-seed' so they are easy to remove afterward.
-- After running: open the app → Payroll Dashboard → Runs → "+ New payroll run"
--   Cycle: Semi-monthly, Period: 2026-11-01 to 2026-11-15 → it computes live.
-- To REMOVE the test data later, run the CLEANUP block at the bottom.
-- ============================================================

with emp(id, kind) as (values
  ('acd2dd72-f197-4289-8087-4d84410e1ad4'::uuid,'perfect'),   -- Rose Anne Vista  (Accounting, monthly)
  ('5c676a81-2f0f-449c-be10-e00fe23a1eaf'::uuid,'late'),      -- Rachelle Castillo(Accounting, monthly) 2 days 30-min late
  ('491be5a0-0d0a-4e90-90ce-0e9a7ca7d8dc'::uuid,'ot'),        -- Rolando Legaspi  (Cutting, monthly)  3 days +2h OT
  ('9a54ce3a-5404-4cea-80a7-07a08ef715c3'::uuid,'absent'),    -- Prince Cañete    (Cutting, daily)    1 absent day
  ('a94fb536-d68d-4e85-aecc-e91bc68ee418'::uuid,'halfday'),   -- Jonathan Legaspi (Cutting, daily)    1 half-day (150m late)
  ('e7388ee6-507d-4066-82a7-46c760db5a9d'::uuid,'missing'),   -- Tomas Moya       (Cutting, daily)    1 missing log  -> Needs Review
  ('d654a084-c2d7-4eea-8858-23b9565fa2d3'::uuid,'perfect'),   -- Almabella Castro (DTF/SUBLI, daily)
  ('3e34f18c-99ce-420c-a8fb-62617a2f572e'::uuid,'pendingot')  -- Myla Tena        (DTF/SUBLI, daily)  pending OT -> Needs Review
),
base as (
  select e.id, e.kind, dd.wd, s.time_in, s.time_out,
    row_number() over (partition by e.id order by dd.wd) rn
  from emp e
  join employees em on em.id=e.id
  join work_schedules s on s.id=em.schedule_id
  join (select d::date wd from generate_series('2026-11-01'::date,'2026-11-15'::date,'1 day') d) dd on true
  where not ((extract(dow from dd.wd)::int) = any(s.rest_days))
)
insert into dtr_days(employee_id, work_date, cutoff_key, status, time_in, time_out, hours_worked,
                     late_min, undertime_min, ot_hours, half_day, approved, approved_at, source, updated_at)
select id, wd, '2026-11-H1',
  case when kind='absent'  and rn=3 then 'absent'
       when kind='missing' and rn=4 then 'missing'
       else 'present' end,
  case when (kind='absent'  and rn=3) then null
       when (kind='missing' and rn=4) then ((wd + time '08:05') at time zone 'Asia/Manila')
       else ((wd + time_in + case when kind='late'    and rn in (2,5) then interval '30 min'
                                  when kind='halfday' and rn=4       then interval '150 min'
                                  else interval '0' end) at time zone 'Asia/Manila') end,
  case when (kind='absent' and rn=3) or (kind='missing' and rn=4) then null
       else ((wd + time_out) at time zone 'Asia/Manila') end,
  case when (kind='absent' and rn=3) or (kind='missing' and rn=4) then 0 else 8 end,
  case when kind='late' and rn in (2,5) then 30 when kind='halfday' and rn=4 then 150 else 0 end,
  0,
  case when kind='ot' and rn in (2,4,6) then 2 else 0 end,
  case when kind='halfday' and rn=4 then true else false end,
  case when (kind='missing' and rn=4) then false else true end,
  case when (kind='missing' and rn=4) then null else now() end,
  'test-seed', now()
from base
on conflict (employee_id, work_date) do update set
  status=excluded.status, time_in=excluded.time_in, time_out=excluded.time_out,
  hours_worked=excluded.hours_worked, late_min=excluded.late_min, ot_hours=excluded.ot_hours,
  half_day=excluded.half_day, approved=excluded.approved, approved_at=excluded.approved_at,
  source='test-seed', updated_at=now();

-- One PENDING overtime filing (lights up the "Overtime awaiting approval" exception)
insert into attendance_filings(employee_id, kind, filing_date, ot_type, ot_hours, status, reason, created_by)
select '3e34f18c-99ce-420c-a8fb-62617a2f572e'::uuid, 'overtime', '2026-11-10'::date, 'normal', 2, 'pending',
       'TEST SEED — rush order OT', (select id from profiles order by created_at limit 1);

select count(*) as seeded_dtr_rows from dtr_days where source='test-seed';

-- ============================================================
-- CLEANUP (run this to remove all test data afterward)
-- ============================================================
-- delete from dtr_days where source='test-seed';
-- delete from attendance_filings where reason like 'TEST SEED%';
-- -- then soft-delete the test run you created in the app from the Runs tab.
