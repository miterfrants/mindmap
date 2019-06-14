--
-- PostgreSQL database dump
--

-- Dumped from database version 11.3 (Debian 11.3-1.pgdg90+1)
-- Dumped by pg_dump version 11.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: board; Type: TABLE; Schema: public; Owner: webservice
--

CREATE TABLE public.board (
    id integer NOT NULL,
    title character varying(128) NOT NULL,
    created_at timestamp(6) with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp(6) with time zone,
    owner_id integer,
    is_public boolean DEFAULT true NOT NULL,
    uniquename character varying(256) NOT NULL
);


ALTER TABLE public.board OWNER TO webservice;

--
-- Name: board_id_seq; Type: SEQUENCE; Schema: public; Owner: webservice
--

ALTER TABLE public.board ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.board_id_seq
    START WITH 1
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
    title character varying(512) NOT NULL,
    description text,
    link character varying(512),
    created_at timestamp(6) with time zone DEFAULT now(),
    deleted_at timestamp(6) with time zone,
    owner_id integer,
    board_id integer
);


ALTER TABLE public.node OWNER TO webservice;

--
-- Name: node_id_seq; Type: SEQUENCE; Schema: public; Owner: webservice
--

ALTER TABLE public.node ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.node_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: node_relationship; Type: TABLE; Schema: public; Owner: webservice
--

CREATE TABLE public.node_relationship (
    parent_node_id integer NOT NULL,
    child_node_id integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE public.node_relationship OWNER TO webservice;

--
-- Name: node_relationship_id_seq; Type: SEQUENCE; Schema: public; Owner: webservice
--

ALTER TABLE public.node_relationship ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.node_relationship_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user; Type: TABLE; Schema: public; Owner: webservice
--

CREATE TABLE public."user" (
    id integer NOT NULL,
    email character varying(512) NOT NULL,
    username character varying(128),
    hashpwd character varying(128),
    birthday timestamp(6) with time zone,
    vocation character varying(64),
    gender character(1),
    created_at timestamp(6) with time zone,
    deleted_at timestamp(6) with time zone,
    salt character varying(32),
    latest_login_ip character varying(45),
    provider character varying(16),
    sub character varying(128),
    full_name character varying(64)
);


ALTER TABLE public."user" OWNER TO webservice;

--
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: webservice
--

ALTER TABLE public."user" ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: view_node; Type: VIEW; Schema: public; Owner: webservice
--

CREATE VIEW public.view_node AS
 SELECT node.id,
    node.title,
    node.description,
    node.link,
    node.created_at,
    node.deleted_at,
    node.owner_id,
    node.board_id,
    board.uniquename AS board_uniquename,
    board.title AS board_title,
    board.is_public AS board_is_public,
    "user".username
   FROM ((public.node
     JOIN public.board ON ((node.board_id = board.id)))
     JOIN public."user" ON ((node.owner_id = "user".id)));


ALTER TABLE public.view_node OWNER TO webservice;

--
-- Name: view_node_relationship; Type: VIEW; Schema: public; Owner: webservice
--

CREATE VIEW public.view_node_relationship AS
 SELECT node_relationship.parent_node_id,
    node_relationship.child_node_id,
    node_relationship.id,
    parent_node.board_id
   FROM (public.node_relationship
     LEFT JOIN public.node parent_node ON ((parent_node.id = node_relationship.parent_node_id)));


ALTER TABLE public.view_node_relationship OWNER TO webservice;

--
-- Name: board boardpkey; Type: CONSTRAINT; Schema: public; Owner: webservice
--

ALTER TABLE ONLY public.board
    ADD CONSTRAINT boardpkey PRIMARY KEY (id);


--
-- Name: user email; Type: CONSTRAINT; Schema: public; Owner: webservice
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT email UNIQUE (email);


--
-- Name: node id; Type: CONSTRAINT; Schema: public; Owner: webservice
--

ALTER TABLE ONLY public.node
    ADD CONSTRAINT id PRIMARY KEY (id);


--
-- Name: node_relationship node_relationship_pkey; Type: CONSTRAINT; Schema: public; Owner: webservice
--

ALTER TABLE ONLY public.node_relationship
    ADD CONSTRAINT node_relationship_pkey PRIMARY KEY (id);


--
-- Name: node_relationship relationship_key; Type: CONSTRAINT; Schema: public; Owner: webservice
--

ALTER TABLE ONLY public.node_relationship
    ADD CONSTRAINT relationship_key UNIQUE (parent_node_id, child_node_id);


--
-- Name: user social_account; Type: CONSTRAINT; Schema: public; Owner: webservice
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT social_account UNIQUE (sub, provider);


--
-- Name: board uniquename; Type: CONSTRAINT; Schema: public; Owner: webservice
--

ALTER TABLE ONLY public.board
    ADD CONSTRAINT uniquename UNIQUE (uniquename, deleted_at);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: webservice
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- Name: node_board_id; Type: INDEX; Schema: public; Owner: webservice
--

CREATE INDEX node_board_id ON public.node USING btree (board_id);


--
-- Name: node_owner; Type: INDEX; Schema: public; Owner: webservice
--

CREATE INDEX node_owner ON public.node USING btree (owner_id);


--
-- Name: node board_id; Type: FK CONSTRAINT; Schema: public; Owner: webservice
--

ALTER TABLE ONLY public.node
    ADD CONSTRAINT board_id FOREIGN KEY (board_id) REFERENCES public.board(id) ON UPDATE RESTRICT;


--
-- PostgreSQL database dump complete
--

