create extension if not exists pgcrypto;
create type public.user_role as enum ('customer','restaurant_owner','restaurant_staff','driver','support','admin');
create type public.order_status as enum ('pending','confirmed','preparing','ready','picked_up','on_the_way','delivered','cancelled');
create type public.payment_status as enum ('pending','paid','failed','refunded','partially_refunded');
create table if not exists public.profiles(id uuid primary key references auth.users(id) on delete cascade,full_name text,phone text unique,role public.user_role not null default 'customer',avatar_url text,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists public.restaurants(id uuid primary key default gen_random_uuid(),owner_id uuid references public.profiles(id),name text not null,slug text unique not null,description text,logo_url text,cover_url text,phone text,address text,lat double precision,lng double precision,rating numeric(2,1) default 0,delivery_fee integer default 0,min_order integer default 0,is_open boolean default true,is_verified boolean default false,commission_rate numeric(5,2) default 15,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists public.restaurant_hours(id uuid primary key default gen_random_uuid(),restaurant_id uuid not null references public.restaurants(id) on delete cascade,dow smallint not null check(dow between 0 and 6),open_time time,close_time time,is_closed boolean default false);
create table if not exists public.categories(id uuid primary key default gen_random_uuid(),name_ar text not null,slug text unique not null,sort_order int default 0);
create table if not exists public.menu_items(id uuid primary key default gen_random_uuid(),restaurant_id uuid not null references public.restaurants(id) on delete cascade,category_id uuid references public.categories(id),name_ar text not null,description_ar text,price integer not null check(price>=0),image_url text,is_available boolean default true,options jsonb default '[]'::jsonb,sort_order int default 0,created_at timestamptz default now(),updated_at timestamptz default now());
create table if not exists public.addresses(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,label text,phone text,address_line text not null,lat double precision,lng double precision,notes text,is_default boolean default false,created_at timestamptz default now());
create table if not exists public.coupons(id uuid primary key default gen_random_uuid(),code text unique not null,kind text not null check(kind in('fixed','percent','delivery')),value numeric not null,min_order integer default 0,max_discount integer,starts_at timestamptz,ends_at timestamptz,max_uses int,uses_count int default 0,is_active boolean default true);
create table if not exists public.orders(id uuid primary key default gen_random_uuid(),public_code text unique not null,customer_id uuid references public.profiles(id),restaurant_id uuid not null references public.restaurants(id),driver_id uuid references public.profiles(id),address_id uuid references public.addresses(id),status public.order_status not null default 'pending',payment_method text not null default 'cash',payment_status public.payment_status not null default 'pending',payment_reference text,customer_name text,customer_phone text,delivery_address text,lat double precision,lng double precision,notes text,subtotal integer not null default 0,delivery_fee integer not null default 0,discount integer not null default 0,total integer not null default 0,coupon_id uuid references public.coupons(id),created_at timestamptz default now(),accepted_at timestamptz,prepared_at timestamptz,picked_up_at timestamptz,delivered_at timestamptz,cancelled_at timestamptz);
create table if not exists public.order_items(id uuid primary key default gen_random_uuid(),order_id uuid not null references public.orders(id) on delete cascade,menu_item_id uuid references public.menu_items(id),product_name text not null,price integer not null,quantity integer not null check(quantity>0),options jsonb default '[]'::jsonb);
create table if not exists public.order_events(id bigint generated always as identity primary key,order_id uuid not null references public.orders(id) on delete cascade,status public.order_status,actor_id uuid references public.profiles(id),message text,created_at timestamptz default now());
create table if not exists public.driver_locations(id bigint generated always as identity primary key,driver_id uuid not null references public.profiles(id) on delete cascade,order_id uuid references public.orders(id) on delete cascade,lat double precision not null,lng double precision not null,heading double precision,speed double precision,created_at timestamptz default now());
create table if not exists public.reviews(id uuid primary key default gen_random_uuid(),order_id uuid unique not null references public.orders(id) on delete cascade,customer_id uuid not null references public.profiles(id),restaurant_id uuid not null references public.restaurants(id),driver_id uuid references public.profiles(id),restaurant_rating int check(restaurant_rating between 1 and 5),driver_rating int check(driver_rating between 1 and 5),food_rating int check(food_rating between 1 and 5),comment text,created_at timestamptz default now());
create table if not exists public.support_tickets(id uuid primary key default gen_random_uuid(),customer_id uuid references public.profiles(id),order_id uuid references public.orders(id),subject text,priority text default 'normal',status text default 'open',created_at timestamptz default now(),updated_at timestamptz default now());
create table if not exists public.support_messages(id bigint generated always as identity primary key,ticket_id uuid not null references public.support_tickets(id) on delete cascade,sender_id uuid references public.profiles(id),message text not null,created_at timestamptz default now());
create table if not exists public.wallet_transactions(id uuid primary key default gen_random_uuid(),user_id uuid references public.profiles(id),order_id uuid references public.orders(id),amount integer not null,type text not null,reference text,created_at timestamptz default now());
create index if not exists idx_orders_customer on public.orders(customer_id,created_at desc);create index if not exists idx_orders_restaurant on public.orders(restaurant_id,status,created_at desc);create index if not exists idx_locations_order on public.driver_locations(order_id,created_at desc);create index if not exists idx_menu_restaurant on public.menu_items(restaurant_id,is_available);


-- V10 security baseline: enable RLS on sensitive operational tables.
alter table public.profiles enable row level security;
alter table public.addresses enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_events enable row level security;
alter table public.driver_locations enable row level security;
alter table public.reviews enable row level security;
alter table public.support_tickets enable row level security;
alter table public.support_messages enable row level security;

-- These policies are intentionally conservative starters. Review with your production roles before launch.
drop policy if exists "profiles own read" on public.profiles;
drop policy if exists "profiles own update" on public.profiles;
drop policy if exists "addresses own access" on public.addresses;
drop policy if exists "orders customer read" on public.orders;
drop policy if exists "order items customer read" on public.order_items;
drop policy if exists "order events customer read" on public.order_events;
drop policy if exists "driver own locations" on public.driver_locations;
drop policy if exists "reviews own read" on public.reviews;
drop policy if exists "reviews own create" on public.reviews;
drop policy if exists "support own tickets" on public.support_tickets;
drop policy if exists "support own messages" on public.support_messages;
create policy "profiles own read" on public.profiles for select using (auth.uid() = id);
create policy "profiles own update" on public.profiles for update using (auth.uid() = id);
create policy "addresses own access" on public.addresses for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "orders customer read" on public.orders for select using (auth.uid() = customer_id);
create policy "order items customer read" on public.order_items for select using (exists(select 1 from public.orders o where o.id=order_id and o.customer_id=auth.uid()));
create policy "order events customer read" on public.order_events for select using (exists(select 1 from public.orders o where o.id=order_id and o.customer_id=auth.uid()));
create policy "driver own locations" on public.driver_locations for all using (auth.uid() = driver_id) with check (auth.uid() = driver_id);
create policy "reviews own read" on public.reviews for select using (auth.uid() = customer_id);
create policy "reviews own create" on public.reviews for insert with check (auth.uid() = customer_id);
create policy "support own tickets" on public.support_tickets for all using (auth.uid() = customer_id) with check (auth.uid() = customer_id);
create policy "support own messages" on public.support_messages for select using (exists(select 1 from public.support_tickets t where t.id=ticket_id and t.customer_id=auth.uid()));

-- V11 production additions: platform operations, courier state, payouts and notifications.
create table if not exists public.driver_profiles(
  id uuid primary key references public.profiles(id) on delete cascade,
  is_online boolean not null default false,
  is_verified boolean not null default false,
  vehicle_type text,
  vehicle_plate text,
  current_lat double precision,
  current_lng double precision,
  current_order_id uuid references public.orders(id) on delete set null,
  rating numeric(2,1) default 0,
  total_deliveries int not null default 0,
  updated_at timestamptz not null default now()
);
create table if not exists public.restaurant_staff(
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  staff_role text not null default 'staff',
  is_active boolean not null default true,
  unique(restaurant_id,user_id)
);
create table if not exists public.delivery_zones(
  id uuid primary key default gen_random_uuid(),
  name_ar text not null,
  governorate text not null default 'بغداد',
  delivery_fee integer not null default 0,
  min_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.restaurant_zones(
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  zone_id uuid not null references public.delivery_zones(id) on delete cascade,
  primary key(restaurant_id,zone_id)
);
create table if not exists public.notifications(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  type text not null default 'system',
  order_id uuid references public.orders(id) on delete set null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists public.payouts(
  id uuid primary key default gen_random_uuid(),
  beneficiary_id uuid not null references public.profiles(id),
  beneficiary_role public.user_role not null,
  period_start date not null,
  period_end date not null,
  gross_amount integer not null default 0,
  commission_amount integer not null default 0,
  net_amount integer not null default 0,
  status text not null default 'pending',
  paid_at timestamptz,
  reference text,
  created_at timestamptz not null default now()
);
create table if not exists public.order_status_history(
  id bigint generated always as identity primary key,
  order_id uuid not null references public.orders(id) on delete cascade,
  from_status public.order_status,
  to_status public.order_status not null,
  actor_id uuid references public.profiles(id),
  note text,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_user on public.notifications(user_id,is_read,created_at desc);
create index if not exists idx_driver_online on public.driver_profiles(is_online,is_verified);
create index if not exists idx_payouts_beneficiary on public.payouts(beneficiary_id,created_at desc);
create index if not exists idx_order_history_order on public.order_status_history(order_id,created_at desc);

alter table public.driver_profiles enable row level security;
alter table public.restaurant_staff enable row level security;
alter table public.delivery_zones enable row level security;
alter table public.restaurant_zones enable row level security;
alter table public.notifications enable row level security;
alter table public.payouts enable row level security;
alter table public.order_status_history enable row level security;

drop policy if exists "driver own profile" on public.driver_profiles;
create policy "driver own profile" on public.driver_profiles for all using(auth.uid()=id) with check(auth.uid()=id);
drop policy if exists "notifications own" on public.notifications;
create policy "notifications own" on public.notifications for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
drop policy if exists "zones public read" on public.delivery_zones;
create policy "zones public read" on public.delivery_zones for select using(is_active=true);
drop policy if exists "restaurant zones public read" on public.restaurant_zones;
create policy "restaurant zones public read" on public.restaurant_zones for select using(true);
drop policy if exists "history customer read" on public.order_status_history;
create policy "history customer read" on public.order_status_history for select using(exists(select 1 from public.orders o where o.id=order_id and o.customer_id=auth.uid()));

-- Keep payment/order totals controlled by trusted server-side logic in production.
-- Never expose service_role keys in the browser.

-- V12 operational additions: delivery zones, notifications, payments, settlements and restaurant staff.
create table if not exists public.delivery_zones(
 id uuid primary key default gen_random_uuid(),
 name_ar text not null,
 city text not null default 'بغداد',
 fee integer not null default 0,
 min_order integer not null default 0,
 is_active boolean not null default true,
 created_at timestamptz default now()
);
create table if not exists public.restaurant_staff(
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 profile_id uuid not null references public.profiles(id) on delete cascade,
 staff_role text not null default 'operator',
 is_active boolean not null default true,
 created_at timestamptz default now(),
 unique(restaurant_id,profile_id)
);
create table if not exists public.notifications(
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 title text not null,
 body text not null,
 type text not null default 'general',
 order_id uuid references public.orders(id) on delete cascade,
 is_read boolean not null default false,
 created_at timestamptz default now()
);
create table if not exists public.payment_transactions(
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null references public.orders(id) on delete cascade,
 provider text not null,
 reference text,
 amount integer not null check(amount>=0),
 status text not null default 'pending',
 raw_response jsonb,
 created_at timestamptz default now()
);
create table if not exists public.restaurant_settlements(
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 period_start date not null,
 period_end date not null,
 gross_amount integer not null default 0,
 commission_amount integer not null default 0,
 refunds_amount integer not null default 0,
 net_amount integer not null default 0,
 status text not null default 'pending',
 paid_at timestamptz,
 created_at timestamptz default now()
);
create table if not exists public.driver_settlements(
 id uuid primary key default gen_random_uuid(),
 driver_id uuid not null references public.profiles(id) on delete cascade,
 period_start date not null,
 period_end date not null,
 gross_amount integer not null default 0,
 adjustments integer not null default 0,
 net_amount integer not null default 0,
 status text not null default 'pending',
 paid_at timestamptz,
 created_at timestamptz default now()
);
create index if not exists idx_notifications_user on public.notifications(user_id,is_read,created_at desc);
create index if not exists idx_staff_restaurant on public.restaurant_staff(restaurant_id,is_active);
create index if not exists idx_payment_order on public.payment_transactions(order_id,created_at desc);
create index if not exists idx_settlement_restaurant on public.restaurant_settlements(restaurant_id,period_end desc);

alter table public.notifications enable row level security;
alter table public.restaurant_staff enable row level security;
alter table public.payment_transactions enable row level security;
alter table public.restaurant_settlements enable row level security;
alter table public.driver_settlements enable row level security;

drop policy if exists "notifications own read" on public.notifications;
drop policy if exists "notifications own update" on public.notifications;
create policy "notifications own read" on public.notifications for select using (auth.uid()=user_id);
create policy "notifications own update" on public.notifications for update using (auth.uid()=user_id);

-- Demo seed is intentionally separate from production data; see demo-restaurants.sql.
