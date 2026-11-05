-- =====================================================================
--  Carnet de nounou : base de données Supabase
--  À coller en entier dans Supabase > SQL Editor > New query > Run
-- =====================================================================

-- 1. Les personnes qui ont accès au carnet
create table public.membres (
  email text primary key,
  nom   text not null,
  role  text not null check (role in ('parent','nounou'))
);
alter table public.membres enable row level security;

-- vrai si la personne connectée fait partie du carnet
create function public.est_membre() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.membres where email = lower(coalesce(auth.jwt()->>'email','')));
$$;

-- vrai si la personne connectée est un parent (peut modifier le contrat)
create function public.est_parent() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.membres where email = lower(coalesce(auth.jwt()->>'email','')) and role = 'parent');
$$;

create policy "membres : lecture" on public.membres for select to authenticated
  using (email = lower(coalesce(auth.jwt()->>'email','')) or public.est_membre());

-- 2. Les données du carnet (jours, cahier de liaison, photos, évènements, documents, contrat)
create table public.docs (
  coll       text not null,          -- mois, liaison, journal, evenements, papiers, config
  id         text not null,          -- ex. 2026-11 ou 2026-11-05
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by text,
  primary key (coll, id)
);
alter table public.docs enable row level security;

create policy "docs : lecture" on public.docs for select to authenticated
  using (public.est_membre());
create policy "docs : ajout" on public.docs for insert to authenticated
  with check (public.est_membre() and (not (coll = 'config' and id = 'contrat') or public.est_parent()));
create policy "docs : modification" on public.docs for update to authenticated
  using (public.est_membre())
  with check (public.est_membre() and (not (coll = 'config' and id = 'contrat') or public.est_parent()));
create policy "docs : suppression" on public.docs for delete to authenticated
  using (public.est_membre() and coll <> 'config');

-- accès par l'API pour les personnes connectées (la sécurité est assurée par les règles ci-dessus)
grant select on public.membres to authenticated;
grant select, insert, update, delete on public.docs to authenticated;
revoke all on public.membres, public.docs from anon;

-- mises à jour en direct entre les téléphones
alter publication supabase_realtime add table public.docs;

-- 3. Photos et documents : espace de stockage PRIVÉ (visible seulement par les membres)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('fichiers', 'fichiers', false, 10485760,
        array['image/jpeg','image/png','image/webp','image/heic','image/gif','application/pdf']);

create policy "fichiers : lecture" on storage.objects for select to authenticated
  using (bucket_id = 'fichiers' and public.est_membre());
create policy "fichiers : ajout" on storage.objects for insert to authenticated
  with check (bucket_id = 'fichiers' and public.est_membre());
create policy "fichiers : suppression" on storage.objects for delete to authenticated
  using (bucket_id = 'fichiers' and public.est_membre());

-- 4. Qui a accès (adresses en minuscules)
insert into public.membres (email, nom, role) values
  ('estelle.lavenac@gmail.com', 'Estelle', 'parent'),
  ('adresse_aurelie@exemple.fr', 'Aurélie', 'parent'),
  ('adresse_marine@exemple.fr', 'Marine', 'nounou');

-- 5. Reprise du tableau Excel : contrat de Marine et jours déjà saisis
insert into public.docs (coll, id, data) values
  ('config', 'contrat', '{"assistante": "Marine", "debut": "2026-09-01", "semaines": 52, "salaireNet": 838.5, "tauxHoraire": 4.5, "heuresHebdo": 43, "heuresMensualisees": 186.33, "entretienJour": 4.1, "conges": "Salaire maintenu pour congés payés acquis", "horaires": {"1": ["08:00", "17:30"], "2": ["08:00", "17:30"], "3": ["08:00", "13:00"], "4": ["08:00", "17:30"], "5": ["08:00", "17:30"]}}'::jsonb),
  ('mois', '2026-10', '{"days": {"01": {"s": "work", "start": "08:00", "end": "17:00", "note": ""}, "02": {"s": "work", "start": "08:00", "end": "17:00", "note": ""}, "05": {"s": "exc", "start": "", "end": "", "note": "absence"}, "06": {"s": "work", "start": "08:00", "end": "17:30", "note": ""}, "07": {"s": "work", "start": "08:00", "end": "13:00", "note": ""}, "08": {"s": "work", "start": "08:00", "end": "17:30", "note": ""}, "09": {"s": "work", "start": "08:00", "end": "17:30", "note": ""}, "12": {"s": "exc", "start": "", "end": "", "note": "décès familial"}, "13": {"s": "exc", "start": "", "end": "", "note": "décès familial"}, "14": {"s": "exc", "start": "", "end": "", "note": "décès familial"}, "15": {"s": "work", "start": "08:00", "end": "17:30", "note": ""}, "16": {"s": "work", "start": "08:00", "end": "17:30", "note": ""}, "19": {"s": "work", "start": "08:00", "end": "17:30", "note": ""}, "20": {"s": "work", "start": "08:00", "end": "17:30", "note": ""}, "21": {"s": "work", "start": "08:00", "end": "13:00", "note": ""}, "22": {"s": "work", "start": "08:00", "end": "17:30", "note": ""}, "23": {"s": "work", "start": "08:00", "end": "17:30", "note": ""}, "26": {"s": "work", "start": "08:00", "end": "17:30", "note": ""}, "27": {"s": "work", "start": "08:00", "end": "17:30", "note": ""}, "28": {"s": "work", "start": "08:00", "end": "13:00", "note": ""}, "29": {"s": "work", "start": "08:00", "end": "17:30", "note": ""}, "30": {"s": "work", "start": "08:00", "end": "17:30", "note": ""}}}'::jsonb),
  ('mois', '2026-11', '{"days": {"02": {"s": "work", "start": "08:00", "end": "17:30", "note": ""}}}'::jsonb);
