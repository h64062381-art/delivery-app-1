-- وصّلني V13 - additive production schema
-- Run AFTER schema.sql. This file adds operational tables without deleting old data.
create table if not exists public.delivery_zones(
 id uuid primary key default gen_random_uuid(), name_ar text unique not null,
 delivery_fee integer not null default 0 check(delivery_fee>=0), eta_minutes integer not null default 30,
 is_active boolean not null default true, created_at timestamptz default now()
);
create table if not exists public.restaurant_zones(
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 zone_id uuid not null references public.delivery_zones(id) on delete cascade,
 is_active boolean not null default true, primary key(restaurant_id,zone_id)
);
create table if not exists public.driver_profiles(
 driver_id uuid primary key references public.profiles(id) on delete cascade,
 vehicle_type text, plate_number text, is_online boolean default false,
 current_zone_id uuid references public.delivery_zones(id), rating numeric(2,1) default 5,
 total_deliveries int default 0, available_balance integer default 0,
 documents_status text default 'pending', updated_at timestamptz default now()
);
create table if not exists public.order_financials(
 order_id uuid primary key references public.orders(id) on delete cascade,
 platform_commission integer default 0, restaurant_payout integer default 0,
 driver_payout integer default 0, payment_fee integer default 0,
 refund_amount integer default 0, settled boolean default false,
 created_at timestamptz default now(), settled_at timestamptz
);
create table if not exists public.notifications(
 id uuid primary key default gen_random_uuid(), user_id uuid references public.profiles(id) on delete cascade,
 title text not null, body text not null, type text default 'system',
 data jsonb default '{}'::jsonb, read_at timestamptz, created_at timestamptz default now()
);
create table if not exists public.restaurant_staff(
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,
 permission text not null default 'orders', created_at timestamptz default now(), unique(restaurant_id,user_id,permission)
);
create table if not exists public.promo_redemptions(
 id uuid primary key default gen_random_uuid(), coupon_id uuid not null references public.coupons(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,
 order_id uuid references public.orders(id) on delete set null, created_at timestamptz default now(),
 unique(coupon_id,user_id,order_id)
);
create index if not exists idx_notifications_user on public.notifications(user_id,created_at desc);
create index if not exists idx_driver_profiles_online on public.driver_profiles(is_online,current_zone_id);
create index if not exists idx_financials_settled on public.order_financials(settled,created_at desc);

alter table public.delivery_zones enable row level security;
alter table public.restaurant_zones enable row level security;
alter table public.driver_profiles enable row level security;
alter table public.order_financials enable row level security;
alter table public.notifications enable row level security;
alter table public.restaurant_staff enable row level security;
alter table public.promo_redemptions enable row level security;

-- Public discovery: active delivery zones only.
drop policy if exists "active zones public read" on public.delivery_zones;
create policy "active zones public read" on public.delivery_zones for select using (is_active=true);
-- Users can read their own notifications.
drop policy if exists "notifications own read" on public.notifications;
create policy "notifications own read" on public.notifications for select using (auth.uid()=user_id);
drop policy if exists "notifications own update" on public.notifications;
create policy "notifications own update" on public.notifications for update using (auth.uid()=user_id) with check (auth.uid()=user_id);
-- Driver can read/update own operational profile.
drop policy if exists "driver own profile" on public.driver_profiles;
create policy "driver own profile" on public.driver_profiles for select using (auth.uid()=driver_id);
drop policy if exists "driver own profile update" on public.driver_profiles;
create policy "driver own profile update" on public.driver_profiles for update using (auth.uid()=driver_id) with check (auth.uid()=driver_id);
-- Restaurant staff can see their assignments.
drop policy if exists "staff own read" on public.restaurant_staff;
create policy "staff own read" on public.restaurant_staff for select using (auth.uid()=user_id);
-- Financial rows are deliberately not exposed to customers. Use trusted server/admin role for settlement writes.
