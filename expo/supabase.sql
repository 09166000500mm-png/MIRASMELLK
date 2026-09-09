create table if not exists public.properties (
 id text primary key,
 created_at timestamptz not null default now(),
 address text not null,
 area text,
 year text,
 floor text,
 amenities text,
 deal text,
 transcript text,
 audio_uri text
);
alter table public.properties enable row level security;