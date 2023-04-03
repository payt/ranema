CREATE TABLE public.users (
    admin boolean DEFAULT false,
    company_id integer NOT NULL,
    confirmation_sent_at timestamp with time zone,
    name character varying,
    id SERIAL PRIMARY KEY
);

CREATE UNIQUE INDEX index_users_on_company_id_and_name_and_id ON public.users USING btree (company_id, name, id);