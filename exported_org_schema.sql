--
-- PostgreSQL database cluster dump
--

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE org_sql;
ALTER ROLE org_sql WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:eUiUPy9uAEOOKAB7/EbBsA==$TEcsoZFejvV/gquboMgugVl+y0clUReeQ79csCqgAPU=:EeKlNDdcO4A0H/obfqjjPO4b+OUU6McEhUIhq2/09DU=';
CREATE ROLE wonko;
ALTER ROLE wonko WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS;


--
-- PostgreSQL database dump
--

-- Dumped from database version 14.13
-- Dumped by pg_dump version 14.13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: ocsigen_start; Type: SCHEMA; Schema: -; Owner: wonko
--

CREATE SCHEMA ocsigen_start;


ALTER SCHEMA ocsigen_start OWNER TO wonko;

--
-- Name: org; Type: SCHEMA; Schema: -; Owner: org_sql
--

CREATE SCHEMA org;


ALTER SCHEMA org OWNER TO org_sql;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: enum_headlines_stats_cookie_type; Type: TYPE; Schema: org; Owner: wonko
--

CREATE TYPE org.enum_headlines_stats_cookie_type AS ENUM (
    'fraction',
    'percent'
);


ALTER TYPE org.enum_headlines_stats_cookie_type OWNER TO wonko;

--
-- Name: enum_planning_entries_planning_type; Type: TYPE; Schema: org; Owner: wonko
--

CREATE TYPE org.enum_planning_entries_planning_type AS ENUM (
    'closed',
    'scheduled',
    'deadline'
);


ALTER TYPE org.enum_planning_entries_planning_type OWNER TO wonko;

--
-- Name: enum_timestamp_repeaters_habit_unit; Type: TYPE; Schema: org; Owner: wonko
--

CREATE TYPE org.enum_timestamp_repeaters_habit_unit AS ENUM (
    'hour',
    'day',
    'week',
    'month',
    'year'
);


ALTER TYPE org.enum_timestamp_repeaters_habit_unit OWNER TO wonko;

--
-- Name: enum_timestamp_repeaters_repeater_type; Type: TYPE; Schema: org; Owner: wonko
--

CREATE TYPE org.enum_timestamp_repeaters_repeater_type AS ENUM (
    'catch-up',
    'restart',
    'cumulate'
);


ALTER TYPE org.enum_timestamp_repeaters_repeater_type OWNER TO wonko;

--
-- Name: enum_timestamp_repeaters_repeater_unit; Type: TYPE; Schema: org; Owner: wonko
--

CREATE TYPE org.enum_timestamp_repeaters_repeater_unit AS ENUM (
    'hour',
    'day',
    'week',
    'month',
    'year'
);


ALTER TYPE org.enum_timestamp_repeaters_repeater_unit OWNER TO wonko;

--
-- Name: enum_timestamp_warnings_warning_type; Type: TYPE; Schema: org; Owner: wonko
--

CREATE TYPE org.enum_timestamp_warnings_warning_type AS ENUM (
    'all',
    'first'
);


ALTER TYPE org.enum_timestamp_warnings_warning_type OWNER TO wonko;

--
-- Name: enum_timestamp_warnings_warning_unit; Type: TYPE; Schema: org; Owner: wonko
--

CREATE TYPE org.enum_timestamp_warnings_warning_unit AS ENUM (
    'hour',
    'day',
    'week',
    'month',
    'year'
);


ALTER TYPE org.enum_timestamp_warnings_warning_unit OWNER TO wonko;

--
-- Name: can_delete_email(); Type: FUNCTION; Schema: public; Owner: wonko
--

CREATE FUNCTION public.can_delete_email() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF (EXISTS (SELECT 1
                FROM ocsigen_start.emails, ocsigen_start.users
                WHERE emails.userid = old.userid
                  AND users.userid = old.userid
                  AND emails.email <> old.email
                  AND users.main_email = emails.email
                  AND validated))
    THEN
      RETURN old;
    ELSE
      RETURN NULL;
    END IF;
  END;
  $$;


ALTER FUNCTION public.can_delete_email() OWNER TO wonko;

--
-- Name: can_delete_phone(); Type: FUNCTION; Schema: public; Owner: wonko
--

CREATE FUNCTION public.can_delete_phone() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF (EXISTS (SELECT 1
                FROM ocsigen_start.phones
                WHERE userid = old.userid AND number <> old.number) OR
        EXISTS (SELECT 1
                FROM ocsigen_start.emails
                WHERE userid = old.userid
                  AND validated))
    THEN
      RETURN old;
    ELSE
      RETURN NULL;
    END IF;
  END;
  $$;


ALTER FUNCTION public.can_delete_phone() OWNER TO wonko;

--
-- Name: set_main_email(); Type: FUNCTION; Schema: public; Owner: wonko
--

CREATE FUNCTION public.set_main_email() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF (EXISTS (SELECT 1
                FROM  ocsigen_start.users
                WHERE users.userid = NEW.userid
                  AND (users.main_email IS NULL OR
                       users.main_email NOT SIMILAR TO '%@%')))
    THEN
      UPDATE users
         SET main_email = NEW.email WHERE users.userid = NEW.userid;
    END IF;
    RETURN NEW;
  END;
  $$;


ALTER FUNCTION public.set_main_email() OWNER TO wonko;

--
-- Name: trigger_exists(text); Type: FUNCTION; Schema: public; Owner: wonko
--

CREATE FUNCTION public.trigger_exists(t_name text) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
      SELECT EXISTS
        (SELECT 1 FROM pg_trigger
                  WHERE NOT tgisinternal
                  AND tgname = t_name)
    $$;


ALTER FUNCTION public.trigger_exists(t_name text) OWNER TO wonko;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: activation; Type: TABLE; Schema: ocsigen_start; Owner: wonko
--

CREATE TABLE ocsigen_start.activation (
    activationkey text NOT NULL,
    userid bigint NOT NULL,
    email public.citext NOT NULL,
    autoconnect boolean NOT NULL,
    validity bigint DEFAULT 1 NOT NULL,
    action text NOT NULL,
    data text NOT NULL,
    creationdate timestamp without time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
    expiry timestamp without time zone
);


ALTER TABLE ocsigen_start.activation OWNER TO wonko;

--
-- Name: emails; Type: TABLE; Schema: ocsigen_start; Owner: wonko
--

CREATE TABLE ocsigen_start.emails (
    email public.citext NOT NULL,
    userid bigint NOT NULL,
    validated boolean DEFAULT false NOT NULL
);


ALTER TABLE ocsigen_start.emails OWNER TO wonko;

--
-- Name: groups; Type: TABLE; Schema: ocsigen_start; Owner: wonko
--

CREATE TABLE ocsigen_start.groups (
    groupid bigint NOT NULL,
    name text NOT NULL,
    description text
);


ALTER TABLE ocsigen_start.groups OWNER TO wonko;

--
-- Name: groups_groupid_seq; Type: SEQUENCE; Schema: ocsigen_start; Owner: wonko
--

CREATE SEQUENCE ocsigen_start.groups_groupid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ocsigen_start.groups_groupid_seq OWNER TO wonko;

--
-- Name: groups_groupid_seq; Type: SEQUENCE OWNED BY; Schema: ocsigen_start; Owner: wonko
--

ALTER SEQUENCE ocsigen_start.groups_groupid_seq OWNED BY ocsigen_start.groups.groupid;


--
-- Name: phones; Type: TABLE; Schema: ocsigen_start; Owner: wonko
--

CREATE TABLE ocsigen_start.phones (
    number public.citext NOT NULL,
    userid bigint NOT NULL
);


ALTER TABLE ocsigen_start.phones OWNER TO wonko;

--
-- Name: preregister; Type: TABLE; Schema: ocsigen_start; Owner: wonko
--

CREATE TABLE ocsigen_start.preregister (
    email public.citext NOT NULL
);


ALTER TABLE ocsigen_start.preregister OWNER TO wonko;

--
-- Name: user_groups; Type: TABLE; Schema: ocsigen_start; Owner: wonko
--

CREATE TABLE ocsigen_start.user_groups (
    userid bigint NOT NULL,
    groupid bigint NOT NULL
);


ALTER TABLE ocsigen_start.user_groups OWNER TO wonko;

--
-- Name: users; Type: TABLE; Schema: ocsigen_start; Owner: wonko
--

CREATE TABLE ocsigen_start.users (
    userid bigint NOT NULL,
    firstname text NOT NULL,
    lastname text NOT NULL,
    main_email public.citext,
    password text,
    avatar text,
    language text
);


ALTER TABLE ocsigen_start.users OWNER TO wonko;

--
-- Name: users_userid_seq; Type: SEQUENCE; Schema: ocsigen_start; Owner: wonko
--

CREATE SEQUENCE ocsigen_start.users_userid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ocsigen_start.users_userid_seq OWNER TO wonko;

--
-- Name: users_userid_seq; Type: SEQUENCE OWNED BY; Schema: ocsigen_start; Owner: wonko
--

ALTER SEQUENCE ocsigen_start.users_userid_seq OWNED BY ocsigen_start.users.userid;


--
-- Name: clocks; Type: TABLE; Schema: org; Owner: wonko
--

CREATE TABLE org.clocks (
    clock_id integer NOT NULL,
    headline_id integer NOT NULL,
    time_start integer,
    time_end integer,
    clock_note text
);


ALTER TABLE org.clocks OWNER TO wonko;

--
-- Name: file_metadata; Type: TABLE; Schema: org; Owner: wonko
--

CREATE TABLE org.file_metadata (
    file_path text NOT NULL,
    outline_hash text NOT NULL,
    file_uid integer NOT NULL,
    file_gid integer NOT NULL,
    file_modification_time integer NOT NULL,
    file_attr_change_time integer NOT NULL,
    file_modes text NOT NULL
);


ALTER TABLE org.file_metadata OWNER TO wonko;

--
-- Name: file_tags; Type: TABLE; Schema: org; Owner: wonko
--

CREATE TABLE org.file_tags (
    outline_hash text NOT NULL,
    tag text NOT NULL
);


ALTER TABLE org.file_tags OWNER TO wonko;

--
-- Name: headline_closures; Type: TABLE; Schema: org; Owner: wonko
--

CREATE TABLE org.headline_closures (
    headline_id integer NOT NULL,
    parent_id integer NOT NULL,
    depth integer
);


ALTER TABLE org.headline_closures OWNER TO wonko;

--
-- Name: headline_properties; Type: TABLE; Schema: org; Owner: wonko
--

CREATE TABLE org.headline_properties (
    headline_id integer NOT NULL,
    property_id integer NOT NULL
);


ALTER TABLE org.headline_properties OWNER TO wonko;

--
-- Name: headline_tags; Type: TABLE; Schema: org; Owner: wonko
--

CREATE TABLE org.headline_tags (
    headline_id integer NOT NULL,
    tag text NOT NULL,
    is_inherited boolean NOT NULL
);


ALTER TABLE org.headline_tags OWNER TO wonko;

--
-- Name: headlines; Type: TABLE; Schema: org; Owner: wonko
--

CREATE TABLE org.headlines (
    headline_id integer NOT NULL,
    outline_hash text NOT NULL,
    headline_text text NOT NULL,
    level integer,
    headline_index integer,
    keyword text,
    effort integer,
    priority text,
    stats_cookie_type org.enum_headlines_stats_cookie_type,
    stats_cookie_value real,
    is_archived boolean NOT NULL,
    is_commented boolean NOT NULL,
    content text
);


ALTER TABLE org.headlines OWNER TO wonko;

--
-- Name: links; Type: TABLE; Schema: org; Owner: wonko
--

CREATE TABLE org.links (
    link_id integer NOT NULL,
    headline_id integer NOT NULL,
    link_path text NOT NULL,
    link_text text,
    link_type text NOT NULL
);


ALTER TABLE org.links OWNER TO wonko;

--
-- Name: logbook_entries; Type: TABLE; Schema: org; Owner: wonko
--

CREATE TABLE org.logbook_entries (
    entry_id integer NOT NULL,
    headline_id integer NOT NULL,
    entry_type text,
    time_logged integer,
    header text,
    note text
);


ALTER TABLE org.logbook_entries OWNER TO wonko;

--
-- Name: outlines; Type: TABLE; Schema: org; Owner: wonko
--

CREATE TABLE org.outlines (
    outline_hash text NOT NULL,
    outline_size integer NOT NULL,
    outline_lines integer NOT NULL,
    outline_preamble text
);


ALTER TABLE org.outlines OWNER TO wonko;

--
-- Name: planning_changes; Type: TABLE; Schema: org; Owner: wonko
--

CREATE TABLE org.planning_changes (
    entry_id integer NOT NULL,
    timestamp_id integer NOT NULL
);


ALTER TABLE org.planning_changes OWNER TO wonko;

--
-- Name: planning_entries; Type: TABLE; Schema: org; Owner: wonko
--

CREATE TABLE org.planning_entries (
    timestamp_id integer NOT NULL,
    planning_type org.enum_planning_entries_planning_type
);


ALTER TABLE org.planning_entries OWNER TO wonko;

--
-- Name: processed_content; Type: TABLE; Schema: org; Owner: wonko
--

CREATE TABLE org.processed_content (
    pc_id bigint NOT NULL,
    headline_id integer NOT NULL,
    index integer NOT NULL,
    kind text NOT NULL,
    outline_hash text NOT NULL,
    content text,
    is_headline boolean NOT NULL,
    link_dest text,
    link_desc text
);


ALTER TABLE org.processed_content OWNER TO wonko;

--
-- Name: processed_content_pc_id_seq; Type: SEQUENCE; Schema: org; Owner: wonko
--

CREATE SEQUENCE org.processed_content_pc_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE org.processed_content_pc_id_seq OWNER TO wonko;

--
-- Name: processed_content_pc_id_seq; Type: SEQUENCE OWNED BY; Schema: org; Owner: wonko
--

ALTER SEQUENCE org.processed_content_pc_id_seq OWNED BY org.processed_content.pc_id;


--
-- Name: properties; Type: TABLE; Schema: org; Owner: wonko
--

CREATE TABLE org.properties (
    outline_hash text NOT NULL,
    property_id integer NOT NULL,
    key_text text NOT NULL,
    val_text text NOT NULL
);


ALTER TABLE org.properties OWNER TO wonko;

--
-- Name: state_changes; Type: TABLE; Schema: org; Owner: wonko
--

CREATE TABLE org.state_changes (
    entry_id integer NOT NULL,
    state_old text NOT NULL,
    state_new text NOT NULL
);


ALTER TABLE org.state_changes OWNER TO wonko;

--
-- Name: timestamp_repeaters; Type: TABLE; Schema: org; Owner: wonko
--

CREATE TABLE org.timestamp_repeaters (
    timestamp_id integer NOT NULL,
    repeater_value integer NOT NULL,
    repeater_unit org.enum_timestamp_repeaters_repeater_unit NOT NULL,
    repeater_type org.enum_timestamp_repeaters_repeater_type NOT NULL,
    habit_value integer,
    habit_unit org.enum_timestamp_repeaters_habit_unit
);


ALTER TABLE org.timestamp_repeaters OWNER TO wonko;

--
-- Name: timestamp_warnings; Type: TABLE; Schema: org; Owner: wonko
--

CREATE TABLE org.timestamp_warnings (
    timestamp_id integer NOT NULL,
    warning_value integer,
    warning_unit org.enum_timestamp_warnings_warning_unit,
    warning_type org.enum_timestamp_warnings_warning_type
);


ALTER TABLE org.timestamp_warnings OWNER TO wonko;

--
-- Name: timestamps; Type: TABLE; Schema: org; Owner: wonko
--

CREATE TABLE org.timestamps (
    timestamp_id integer NOT NULL,
    headline_id integer NOT NULL,
    raw_value text NOT NULL,
    is_active boolean NOT NULL,
    time_start integer NOT NULL,
    time_end integer,
    start_is_long boolean NOT NULL,
    end_is_long boolean
);


ALTER TABLE org.timestamps OWNER TO wonko;

--
-- Name: groups groupid; Type: DEFAULT; Schema: ocsigen_start; Owner: wonko
--

ALTER TABLE ONLY ocsigen_start.groups ALTER COLUMN groupid SET DEFAULT nextval('ocsigen_start.groups_groupid_seq'::regclass);


--
-- Name: users userid; Type: DEFAULT; Schema: ocsigen_start; Owner: wonko
--

ALTER TABLE ONLY ocsigen_start.users ALTER COLUMN userid SET DEFAULT nextval('ocsigen_start.users_userid_seq'::regclass);


--
-- Name: processed_content pc_id; Type: DEFAULT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.processed_content ALTER COLUMN pc_id SET DEFAULT nextval('org.processed_content_pc_id_seq'::regclass);


--
-- Name: activation activation_pkey; Type: CONSTRAINT; Schema: ocsigen_start; Owner: wonko
--

ALTER TABLE ONLY ocsigen_start.activation
    ADD CONSTRAINT activation_pkey PRIMARY KEY (activationkey);


--
-- Name: emails emails_pkey; Type: CONSTRAINT; Schema: ocsigen_start; Owner: wonko
--

ALTER TABLE ONLY ocsigen_start.emails
    ADD CONSTRAINT emails_pkey PRIMARY KEY (email);


--
-- Name: groups groups_name_key; Type: CONSTRAINT; Schema: ocsigen_start; Owner: wonko
--

ALTER TABLE ONLY ocsigen_start.groups
    ADD CONSTRAINT groups_name_key UNIQUE (name);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: ocsigen_start; Owner: wonko
--

ALTER TABLE ONLY ocsigen_start.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (groupid);


--
-- Name: phones phones_pkey; Type: CONSTRAINT; Schema: ocsigen_start; Owner: wonko
--

ALTER TABLE ONLY ocsigen_start.phones
    ADD CONSTRAINT phones_pkey PRIMARY KEY (number);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: ocsigen_start; Owner: wonko
--

ALTER TABLE ONLY ocsigen_start.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (userid);


--
-- Name: clocks clocks_pkey; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.clocks
    ADD CONSTRAINT clocks_pkey PRIMARY KEY (clock_id);


--
-- Name: file_metadata file_metadata_pkey; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.file_metadata
    ADD CONSTRAINT file_metadata_pkey PRIMARY KEY (file_path);


--
-- Name: file_tags file_tags_pkey; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.file_tags
    ADD CONSTRAINT file_tags_pkey PRIMARY KEY (outline_hash, tag);


--
-- Name: headline_closures headline_closures_pkey; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.headline_closures
    ADD CONSTRAINT headline_closures_pkey PRIMARY KEY (headline_id, parent_id);


--
-- Name: headline_properties headline_properties_pkey; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.headline_properties
    ADD CONSTRAINT headline_properties_pkey PRIMARY KEY (property_id);


--
-- Name: headline_tags headline_tags_pkey; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.headline_tags
    ADD CONSTRAINT headline_tags_pkey PRIMARY KEY (headline_id, tag, is_inherited);


--
-- Name: headlines headlines_pkey; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.headlines
    ADD CONSTRAINT headlines_pkey PRIMARY KEY (headline_id);


--
-- Name: links links_pkey; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.links
    ADD CONSTRAINT links_pkey PRIMARY KEY (link_id);


--
-- Name: logbook_entries logbook_entries_pkey; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.logbook_entries
    ADD CONSTRAINT logbook_entries_pkey PRIMARY KEY (entry_id);


--
-- Name: outlines outlines_pkey; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.outlines
    ADD CONSTRAINT outlines_pkey PRIMARY KEY (outline_hash);


--
-- Name: planning_changes planning_changes_pkey; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.planning_changes
    ADD CONSTRAINT planning_changes_pkey PRIMARY KEY (entry_id);


--
-- Name: planning_changes planning_changes_timestamp_id_key; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.planning_changes
    ADD CONSTRAINT planning_changes_timestamp_id_key UNIQUE (timestamp_id);


--
-- Name: planning_entries planning_entries_pkey; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.planning_entries
    ADD CONSTRAINT planning_entries_pkey PRIMARY KEY (timestamp_id);


--
-- Name: processed_content processed_content_pkey; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.processed_content
    ADD CONSTRAINT processed_content_pkey PRIMARY KEY (pc_id);


--
-- Name: properties properties_pkey; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.properties
    ADD CONSTRAINT properties_pkey PRIMARY KEY (property_id);


--
-- Name: state_changes state_changes_pkey; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.state_changes
    ADD CONSTRAINT state_changes_pkey PRIMARY KEY (entry_id);


--
-- Name: timestamp_repeaters timestamp_repeaters_pkey; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.timestamp_repeaters
    ADD CONSTRAINT timestamp_repeaters_pkey PRIMARY KEY (timestamp_id);


--
-- Name: timestamp_warnings timestamp_warnings_pkey; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.timestamp_warnings
    ADD CONSTRAINT timestamp_warnings_pkey PRIMARY KEY (timestamp_id);


--
-- Name: timestamps timestamps_pkey; Type: CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.timestamps
    ADD CONSTRAINT timestamps_pkey PRIMARY KEY (timestamp_id);


--
-- Name: emails can_delete_email; Type: TRIGGER; Schema: ocsigen_start; Owner: wonko
--

CREATE TRIGGER can_delete_email BEFORE DELETE ON ocsigen_start.emails FOR EACH ROW EXECUTE FUNCTION public.can_delete_email();


--
-- Name: phones can_delete_phone; Type: TRIGGER; Schema: ocsigen_start; Owner: wonko
--

CREATE TRIGGER can_delete_phone BEFORE DELETE ON ocsigen_start.phones FOR EACH ROW EXECUTE FUNCTION public.can_delete_phone();


--
-- Name: emails set_main_email; Type: TRIGGER; Schema: ocsigen_start; Owner: wonko
--

CREATE TRIGGER set_main_email AFTER INSERT ON ocsigen_start.emails FOR EACH ROW EXECUTE FUNCTION public.set_main_email();


--
-- Name: activation activation_userid_fkey; Type: FK CONSTRAINT; Schema: ocsigen_start; Owner: wonko
--

ALTER TABLE ONLY ocsigen_start.activation
    ADD CONSTRAINT activation_userid_fkey FOREIGN KEY (userid) REFERENCES ocsigen_start.users(userid);


--
-- Name: emails emails_userid_fkey; Type: FK CONSTRAINT; Schema: ocsigen_start; Owner: wonko
--

ALTER TABLE ONLY ocsigen_start.emails
    ADD CONSTRAINT emails_userid_fkey FOREIGN KEY (userid) REFERENCES ocsigen_start.users(userid);


--
-- Name: phones phones_userid_fkey; Type: FK CONSTRAINT; Schema: ocsigen_start; Owner: wonko
--

ALTER TABLE ONLY ocsigen_start.phones
    ADD CONSTRAINT phones_userid_fkey FOREIGN KEY (userid) REFERENCES ocsigen_start.users(userid);


--
-- Name: user_groups user_groups_groupid_fkey; Type: FK CONSTRAINT; Schema: ocsigen_start; Owner: wonko
--

ALTER TABLE ONLY ocsigen_start.user_groups
    ADD CONSTRAINT user_groups_groupid_fkey FOREIGN KEY (groupid) REFERENCES ocsigen_start.groups(groupid);


--
-- Name: user_groups user_groups_userid_fkey; Type: FK CONSTRAINT; Schema: ocsigen_start; Owner: wonko
--

ALTER TABLE ONLY ocsigen_start.user_groups
    ADD CONSTRAINT user_groups_userid_fkey FOREIGN KEY (userid) REFERENCES ocsigen_start.users(userid);


--
-- Name: clocks clocks_headline_id_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.clocks
    ADD CONSTRAINT clocks_headline_id_fkey FOREIGN KEY (headline_id) REFERENCES org.headlines(headline_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: file_metadata file_metadata_outline_hash_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.file_metadata
    ADD CONSTRAINT file_metadata_outline_hash_fkey FOREIGN KEY (outline_hash) REFERENCES org.outlines(outline_hash) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: file_tags file_tags_outline_hash_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.file_tags
    ADD CONSTRAINT file_tags_outline_hash_fkey FOREIGN KEY (outline_hash) REFERENCES org.outlines(outline_hash) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: headline_closures headline_closures_headline_id_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.headline_closures
    ADD CONSTRAINT headline_closures_headline_id_fkey FOREIGN KEY (headline_id) REFERENCES org.headlines(headline_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: headline_closures headline_closures_parent_id_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.headline_closures
    ADD CONSTRAINT headline_closures_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES org.headlines(headline_id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: headline_properties headline_properties_headline_id_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.headline_properties
    ADD CONSTRAINT headline_properties_headline_id_fkey FOREIGN KEY (headline_id) REFERENCES org.headlines(headline_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: headline_properties headline_properties_property_id_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.headline_properties
    ADD CONSTRAINT headline_properties_property_id_fkey FOREIGN KEY (property_id) REFERENCES org.properties(property_id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: headline_tags headline_tags_headline_id_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.headline_tags
    ADD CONSTRAINT headline_tags_headline_id_fkey FOREIGN KEY (headline_id) REFERENCES org.headlines(headline_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: headlines headlines_outline_hash_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.headlines
    ADD CONSTRAINT headlines_outline_hash_fkey FOREIGN KEY (outline_hash) REFERENCES org.outlines(outline_hash) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: links links_headline_id_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.links
    ADD CONSTRAINT links_headline_id_fkey FOREIGN KEY (headline_id) REFERENCES org.headlines(headline_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: logbook_entries logbook_entries_headline_id_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.logbook_entries
    ADD CONSTRAINT logbook_entries_headline_id_fkey FOREIGN KEY (headline_id) REFERENCES org.headlines(headline_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: planning_changes planning_changes_entry_id_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.planning_changes
    ADD CONSTRAINT planning_changes_entry_id_fkey FOREIGN KEY (entry_id) REFERENCES org.logbook_entries(entry_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: planning_changes planning_changes_timestamp_id_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.planning_changes
    ADD CONSTRAINT planning_changes_timestamp_id_fkey FOREIGN KEY (timestamp_id) REFERENCES org.timestamps(timestamp_id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: planning_entries planning_entries_timestamp_id_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.planning_entries
    ADD CONSTRAINT planning_entries_timestamp_id_fkey FOREIGN KEY (timestamp_id) REFERENCES org.timestamps(timestamp_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: properties properties_outline_hash_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.properties
    ADD CONSTRAINT properties_outline_hash_fkey FOREIGN KEY (outline_hash) REFERENCES org.outlines(outline_hash) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: state_changes state_changes_entry_id_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.state_changes
    ADD CONSTRAINT state_changes_entry_id_fkey FOREIGN KEY (entry_id) REFERENCES org.logbook_entries(entry_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: timestamp_repeaters timestamp_repeaters_timestamp_id_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.timestamp_repeaters
    ADD CONSTRAINT timestamp_repeaters_timestamp_id_fkey FOREIGN KEY (timestamp_id) REFERENCES org.timestamps(timestamp_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: timestamp_warnings timestamp_warnings_timestamp_id_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.timestamp_warnings
    ADD CONSTRAINT timestamp_warnings_timestamp_id_fkey FOREIGN KEY (timestamp_id) REFERENCES org.timestamps(timestamp_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: timestamps timestamps_headline_id_fkey; Type: FK CONSTRAINT; Schema: org; Owner: wonko
--

ALTER TABLE ONLY org.timestamps
    ADD CONSTRAINT timestamps_headline_id_fkey FOREIGN KEY (headline_id) REFERENCES org.headlines(headline_id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: SCHEMA org; Type: ACL; Schema: -; Owner: org_sql
--

GRANT ALL ON SCHEMA org TO wonko;


--
-- PostgreSQL database dump complete
--
