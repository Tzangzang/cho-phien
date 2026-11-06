-- Chợ Phiên: bảng trải nghiệm, quản trị viên, kho ảnh
create table if not exists public.experiences (
  id text primary key,
  title text not null,
  region text not null,
  location text,
  category text not null,
  provider text,
  summary text,
  address text,
  duration_label text,
  duration_hours numeric,
  price_vnd numeric,
  price_note text,
  schedule_note text,
  phone text,
  phone_source_url text,
  booking_url text,
  booking_url_type text,
  website_url text,
  facebook_url text,
  event_url text,
  image_url text,
  sources jsonb,
  verification_note text,
  availability_status text,
  discovery_source text,
  facebook_evidence_status text,
  event_start_date text,
  event_end_date text,
  phone_dial text,
  last_checked_at text,
  seat_availability_verified boolean,
  highlights jsonb,
  itinerary jsonb,
  includes jsonb,
  notes jsonb,
  reviews jsonb,
  evidence jsonb,
  images jsonb,
  image_source_url text,
  area text,
  area_label text,
  image_credit text,
  detail_source_url text,
  checked_at text,
  detail_source_urls jsonb,
  original_title text,
  rating_summary jsonb,
  price_unit text,
  alternate_booking_channels jsonb,
  merged_aliases jsonb,
  review_evidence_note text,
  review_availability text,
  office_address text,
  tags jsonb,
  sort_order integer not null default 0,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists experiences_region_idx on public.experiences (region);
create index if not exists experiences_category_idx on public.experiences (category);

create table if not exists public.admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

create or replace function public.touch_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;
drop trigger if exists experiences_touch on public.experiences;
create trigger experiences_touch before update on public.experiences for each row execute function public.touch_updated_at();

alter table public.experiences enable row level security;
alter table public.admins enable row level security;

drop policy if exists "Ai cũng xem trải nghiệm đã đăng" on public.experiences;
create policy "Ai cũng xem trải nghiệm đã đăng" on public.experiences for select using (is_published or public.is_admin());
drop policy if exists "Quản trị viên thêm trải nghiệm" on public.experiences;
create policy "Quản trị viên thêm trải nghiệm" on public.experiences for insert with check (public.is_admin());
drop policy if exists "Quản trị viên sửa trải nghiệm" on public.experiences;
create policy "Quản trị viên sửa trải nghiệm" on public.experiences for update using (public.is_admin()) with check (public.is_admin());
drop policy if exists "Quản trị viên xoá trải nghiệm" on public.experiences;
create policy "Quản trị viên xoá trải nghiệm" on public.experiences for delete using (public.is_admin());
drop policy if exists "Quản trị viên xem danh sách quản trị" on public.admins;
create policy "Quản trị viên xem danh sách quản trị" on public.admins for select using (public.is_admin());

-- Kho ảnh: ai cũng xem, chỉ quản trị viên tải lên/xoá
insert into storage.buckets (id, name, public) values ('experience-photos', 'experience-photos', true) on conflict (id) do nothing;
drop policy if exists "Quản trị viên tải ảnh" on storage.objects;
create policy "Quản trị viên tải ảnh" on storage.objects for insert with check (bucket_id = 'experience-photos' and public.is_admin());
drop policy if exists "Quản trị viên sửa ảnh" on storage.objects;
create policy "Quản trị viên sửa ảnh" on storage.objects for update using (bucket_id = 'experience-photos' and public.is_admin());
drop policy if exists "Quản trị viên xoá ảnh" on storage.objects;
create policy "Quản trị viên xoá ảnh" on storage.objects for delete using (bucket_id = 'experience-photos' and public.is_admin());
