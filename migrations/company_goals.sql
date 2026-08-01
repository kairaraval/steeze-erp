-- Vision & Goal board (owner/admin private). One hierarchical table:
--   kind = 'vision'  → the company vision statement (usually one row)
--   kind = 'goal'    → a strategic goal (child of the vision)
--   kind = 'kr'      → a key result / measurable target under a goal
-- Progress rolls up: KR → Goal → Vision.
create table if not exists company_goals (
  id            uuid primary key default gen_random_uuid(),
  parent_id     uuid references company_goals(id) on delete cascade,
  kind          text not null default 'goal',        -- 'vision' | 'goal' | 'kr'
  title         text not null,
  description   text,
  owner_name    text,                                 -- who's accountable (free text)
  status        text default 'on_track',              -- 'not_started' | 'on_track' | 'at_risk' | 'achieved'
  metric_type   text default 'checklist',             -- KR only: 'number' | 'checklist' | 'manual'
  target_value  numeric,
  current_value numeric,
  unit          text,                                 -- e.g. '₱', 'pcs', '%'
  auto_metric   text,                                 -- optional key to auto-pull the 'actual' from live OS data
  manual_pct    numeric,                              -- for metric_type='manual' (0-100)
  milestones    jsonb default '[]'::jsonb,            -- [{ id, text, done }]
  due_date      date,
  sort          int  default 0,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now(),
  created_by    uuid
);
create index if not exists company_goals_parent_idx on company_goals(parent_id);

alter table company_goals enable row level security;
-- App already gates this board to the admin/owner in the UI; keep RLS permissive
-- like the rest of the Steeze OS tables.
drop policy if exists company_goals_all on company_goals;
create policy company_goals_all on company_goals for all using (true) with check (true);
