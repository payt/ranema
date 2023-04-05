CREATE TABLE public.users (
    old character varying(255),
    id SERIAL PRIMARY KEY
);

CREATE TABLE public.copy_values (
    old character varying(255),
    new character varying(255),
    id SERIAL PRIMARY KEY
);

CREATE TABLE public.defaults (
    old_boolean boolean DEFAULT false,
    new_boolean boolean,
    old_string character varying DEFAULT 'unknown',
    new_string character varying,
    old_timestamp timestamp with time zone DEFAULT transaction_timestamp(),
    new_timestamp timestamp with time zone
);

INSERT INTO "copy_values" (old) VALUES ('old_value')
