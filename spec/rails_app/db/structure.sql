CREATE TABLE public.users (
    old_boolean boolean DEFAULT false,
    old_integer integer NOT NULL,
    old_timestamp timestamp with time zone,
    old character varying,
    id SERIAL PRIMARY KEY
);

CREATE UNIQUE INDEX index_users_on_old_and_id ON public.users USING btree (old, id);
