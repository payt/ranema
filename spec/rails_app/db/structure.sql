CREATE TABLE public.users (
    old character varying(255),
    id SERIAL PRIMARY KEY
);

CREATE TABLE public.defaults (
    old_boolean boolean DEFAULT false,
    new_boolean boolean,
    old_timestamp timestamp with time zone DEFAULT transaction_timestamp(),
    new_timestamp timestamp with time zone
);
