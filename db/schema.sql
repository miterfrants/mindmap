--
-- PostgreSQL database dump
--
-- Dumped from database version 11.3 (Debian 11.3-1.pgdg90+1)
-- Dumped by pg_dump version 11.2

SET statement_timeout = 0;

SET lock_timeout = 0;

SET idle_in_transaction_session_timeout = 0;

SET client_encoding = 'UTF8';

SET standard_conforming_strings = ON;

SELECT
    pg_catalog.set_config('search_path', '', FALSE);

SET check_function_bodies = FALSE;

SET client_min_messages = warning;

SET row_security = off;

SET default_tablespace = '';

SET default_with_oids = FALSE;

--
-- Name: board; Type: TABLE; Schema: public; Owner: webservice
--

CREATE TABLE public.board (
    id integer NOT NULL,
    title character varying (128) NOT NULL,
    created_at timestamp(6
) WITH time zone DEFAULT now() NOT NULL,
    deleted_at timestamp(6
) WITH time zone,
    owner_id integer,
    is_public boolean DEFAULT TRUE NOT NULL,
    uniquename character varying (256)
);

ALTER TABLE public.board OWNER TO webservice;

--
-- Name: board_id_seq; Type: SEQUENCE; Schema: public; Owner: webservice
--

ALTER TABLE public.board ALTER COLUMN id
    ADD GENERATED BY
        DEFAULT AS IDENTITY (SEQUENCE NAME
                public.board_id_seq START WITH 1
                INCREMENT BY 1
                NO MINVALUE
                NO MAXVALUE
                CACHE 1
);

--
-- Name: image; Type: TABLE; Schema: public; Owner: webservice
--

CREATE TABLE public.image (
    id integer NOT NULL,
    filename character varying (64) NOT NULL,
    created_at timestamp(6
) WITH time zone DEFAULT now() NOT NULL,
    deleted_at timestamp(6
) WITH time zone,
    owner_id integer,
    node_id integer
);

ALTER TABLE public.image OWNER TO webservice;

--
-- Name: image_id_seq; Type: SEQUENCE; Schema: public; Owner: webservice
--

ALTER TABLE public.image ALTER COLUMN id
    ADD GENERATED BY
        DEFAULT AS IDENTITY (SEQUENCE NAME
                public.image_id_seq START WITH 1
                INCREMENT BY 1
                NO MINVALUE
                NO MAXVALUE
                CACHE 1
);

--
-- Name: node; Type: TABLE; Schema: public; Owner: webservice
--

CREATE TABLE public.node (
    id integer NOT NULL,
    title character varying (512) NOT NULL,
    description text,
    link character varying (512),
    created_at timestamp(6
) WITH time zone DEFAULT now(),
    deleted_at timestamp(6
) WITH time zone,
    owner_id integer,
    board_id integer,
    x numeric,
    y numeric,
    cover character varying (512)
);

ALTER TABLE public.node OWNER TO webservice;

--
-- Name: node_id_seq; Type: SEQUENCE; Schema: public; Owner: webservice
--

ALTER TABLE public.node ALTER COLUMN id
    ADD GENERATED BY
        DEFAULT AS IDENTITY (SEQUENCE NAME
                public.node_id_seq START WITH 1
                INCREMENT BY 1
                NO MINVALUE
                NO MAXVALUE
                CACHE 1
);

--
-- Name: node_relationship; Type: TABLE; Schema: public; Owner: webservice
--

CREATE TABLE public.node_relationship (
    id integer NOT NULL,
    parent_node_id integer NOT NULL,
    child_node_id integer NOT NULL,
    created_at timestamp(6
) WITH time zone DEFAULT now() NOT NULL,
    deleted_at timestamp(6
) WITH time zone
);

ALTER TABLE public.node_relationship OWNER TO webservice;

--
-- Name: node_relationship_id_seq; Type: SEQUENCE; Schema: public; Owner: webservice
--

ALTER TABLE public.node_relationship ALTER COLUMN id
    ADD GENERATED BY
        DEFAULT AS IDENTITY (SEQUENCE NAME
                public.node_relationship_id_seq START WITH 1
                INCREMENT BY 1
                NO MINVALUE
                NO MAXVALUE
                CACHE 1
);

--
-- Name: transaction; Type: TABLE; Schema: public; Owner: webservice
--

CREATE TABLE public.transaction (
    id integer NOT NULL,
    method character varying (64) NOT NULL,
    raw_data json,
    status character varying (12) NOT NULL,
    created_at timestamp(6
) WITH time zone DEFAULT now(),
    deleted_at timestamp(6
) WITH time zone,
    owner_id integer NOT NULL,
    card_holder character varying (128) NOT NULL,
    phone character varying (64) NOT NULL,
    email character varying (32) NOT NULL,
    amount integer NOT NULL,
    discount integer NOT NULL,
    paid_at timestamp(6
) WITH time zone,
    is_next_subscribe boolean DEFAULT TRUE NOT NULL
);

ALTER TABLE public.transaction OWNER TO webservice;

--
-- Name: transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: webservice
--

ALTER TABLE public.transaction ALTER COLUMN id
    ADD GENERATED BY
        DEFAULT AS IDENTITY (SEQUENCE NAME
                public.transaction_id_seq START WITH 1
                INCREMENT BY 1
                NO MINVALUE
                NO MAXVALUE
                CACHE 1
);

--
-- Name: user; Type: TABLE; Schema: public; Owner: webservice
--

CREATE TABLE public. "user" (
    id integer NOT NULL,
    email character varying (512) NOT NULL,
    username character varying (128),
    hashpwd character varying (128),
    birthday timestamp(6
) WITH time zone,
    vocation character varying (64),
    gender character (1),
    created_at timestamp(6
) WITH time zone DEFAULT now() NOT NULL,
    deleted_at timestamp(6
) WITH time zone,
    salt character varying (32),
    latest_login_ip character varying (45),
    provider character varying (16),
    sub character varying (128),
    full_name character varying (64),
    phone character varying (32)
);

ALTER TABLE public. "user" OWNER TO webservice;

--
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: webservice
--

ALTER TABLE public. "user" ALTER COLUMN id
    ADD GENERATED BY
        DEFAULT AS IDENTITY (SEQUENCE NAME
                public.user_id_seq START WITH 1
                INCREMENT BY 1
                NO MINVALUE
                NO MAXVALUE
                CACHE 1
);

--
-- Name: view_node; Type: VIEW; Schema: public; Owner: webservice
--

CREATE VIEW public.view_node AS
SELECT
    node.id,
    node.title,
    node.description,
    node.link,
    node.created_at,
    node.deleted_at,
    node.owner_id,
    node.board_id,
    node.x,
    node.y,
    node.cover,
    board.uniquename AS board_uniquename,
    board.title AS board_title,
    board.is_public AS board_is_public,
    "user".username
FROM ((public.node
        JOIN public.board ON ((node.board_id = board.id)))
    JOIN public. "user" ON ((node.owner_id = "user".id))
);

ALTER TABLE public.view_node OWNER TO webservice;

--
-- Name: view_node_relationship; Type: VIEW; Schema: public; Owner: webservice
--

CREATE VIEW public.view_node_relationship AS
SELECT
    node_relationship.parent_node_id,
    node_relationship.child_node_id,
    node_relationship.id,
    parent_node.board_id
FROM ((public.node_relationship
    LEFT JOIN public.node parent_node ON ((parent_node.id = node_relationship.parent_node_id)))
    LEFT JOIN public.node child_node ON ((child_node.id = node_relationship.child_node_id)))
WHERE ((parent_node.deleted_at IS NULL)
    AND (child_node.deleted_at IS NULL)
    AND (node_relationship.deleted_at IS NULL)
);

ALTER TABLE public.view_node_relationship OWNER TO webservice;

--
-- Name: view_user; Type: VIEW; Schema: public; Owner: webservice
--

create view view_user as (
 WITH t AS (
         SELECT transaction.id,
            transaction.method,
            transaction.raw_data,
            transaction.status,
            transaction.created_at,
            transaction.deleted_at,
            transaction.owner_id,
            transaction.card_holder,
            transaction.phone,
            transaction.email,
            transaction.amount,
            transaction.discount,
            transaction.paid_at,
            transaction.is_next_subscribe,
            row_number() OVER (PARTITION BY transaction.owner_id ORDER BY transaction.paid_at DESC) AS row_number
           FROM transaction
          WHERE to_char(transaction.paid_at, 'YYYYMM'::text) = to_char(now(), 'YYYYMM'::text)
        )
 SELECT "user".id,
    "user".email,
    "user".username,
    "user".hashpwd,
    "user".birthday,
    "user".vocation,
    "user".gender,
    "user".created_at,
    "user".deleted_at,
    "user".salt,
    "user".latest_login_ip,
    "user".provider,
    "user".sub,
    "user".full_name,
    "user".phone,
	(select (case when sum(size) is null then 0 else sum(size) end) from image where owner_id = "user".id and deleted_at is null) as storage_usage,
        CASE
            WHEN user_transaction.id IS NOT NULL THEN true
            ELSE false
        END AS is_subscribed,
    user_transaction.id AS transaction_id,
        CASE
            WHEN user_transaction.is_next_subscribe IS NOT NULL THEN user_transaction.is_next_subscribe
            ELSE false
        END AS is_next_subscribe,
    ( SELECT count(*) AS count
           FROM board
          WHERE board.owner_id = "user".id AND board.deleted_at IS NULL) AS board_count
   FROM "user"
     LEFT JOIN ( SELECT t.id,
            t.method,
            t.raw_data,
            t.status,
            t.created_at,
            t.deleted_at,
            t.owner_id,
            t.card_holder,
            t.phone,
            t.email,
            t.amount,
            t.discount,
            t.paid_at,
            t.is_next_subscribe,
            t.row_number
           FROM t
          WHERE t.row_number = 1) user_transaction ON "user".id = user_transaction.owner_id
);

ALTER TABLE public.view_user OWNER TO webservice;

--
-- Name: board PK_board; Type: CONSTRAINT; Schema: public; Owner: webservice
--

ALTER TABLE ONLY public.board
    ADD CONSTRAINT "PK_board" PRIMARY KEY (id);

--
-- Name: node PK_node; Type: CONSTRAINT; Schema: public; Owner: webservice
--

ALTER TABLE ONLY public.node
    ADD CONSTRAINT "PK_node" PRIMARY KEY (id);

--
-- Name: node_relationship PK_node_relationship; Type: CONSTRAINT; Schema: public; Owner: webservice
--

ALTER TABLE ONLY public.node_relationship
    ADD CONSTRAINT "PK_node_relationship" PRIMARY KEY (id);

--
-- Name: transaction PK_transaction; Type: CONSTRAINT; Schema: public; Owner: webservice
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT "PK_transaction" PRIMARY KEY (id);

--
-- Name: user PK_user; Type: CONSTRAINT; Schema: public; Owner: webservice
--

ALTER TABLE ONLY public. "user"
    ADD CONSTRAINT "PK_user" PRIMARY KEY (id);

--
-- Name: image image_pkey; Type: CONSTRAINT; Schema: public; Owner: webservice
--

ALTER TABLE ONLY public.image
    ADD CONSTRAINT image_pkey PRIMARY KEY (id);

--
-- Name: email; Type: INDEX; Schema: public; Owner: webservice
--

CREATE UNIQUE INDEX email ON public. "user"
USING btree (email);

--
-- Name: node_board_id; Type: INDEX; Schema: public; Owner: webservice
--

CREATE INDEX node_board_id ON public.node
USING btree (board_id);

--
-- Name: node_owner; Type: INDEX; Schema: public; Owner: webservice
--

CREATE INDEX node_owner ON public.node
USING btree (owner_id);

--
-- Name: relationship_key; Type: INDEX; Schema: public; Owner: webservice
--

CREATE UNIQUE INDEX relationship_key ON public.node_relationship
USING btree (GREATEST (parent_node_id, child_node_id), LEAST (parent_node_id, child_node_id))
WHERE (deleted_at IS NULL);

--
-- Name: social_account; Type: INDEX; Schema: public; Owner: webservice
--

CREATE UNIQUE INDEX social_account ON public. "user"
USING btree (sub, provider);

--
-- Name: uniquename; Type: INDEX; Schema: public; Owner: webservice
--

CREATE UNIQUE INDEX uniquename ON public.board
USING btree (uniquename, deleted_at);

--
-- Name: node board_id; Type: FK CONSTRAINT; Schema: public; Owner: webservice
--

ALTER TABLE ONLY public.node
    ADD CONSTRAINT board_id FOREIGN KEY (board_id) REFERENCES public.board (id) ON DELETE RESTRICT;

--
-- PostgreSQL database dump complete
--
