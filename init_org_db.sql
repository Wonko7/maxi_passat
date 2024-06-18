CREATE ROLE org_sql WITH LOGIN PASSWORD 'org_sql';

CREATE SCHEMA org AUTHORIZATION org_sql;

GRANT ALL ON SCHEMA org TO org_sql;

GRANT ALL ON SCHEMA org TO wonko;

-- now do: (org-sql-user-init)

CREATE TABLE org.processed_content ( -- DEFAULT
       pc_id bigserial primary key, -- DEFAULT
       headline_id int,
       index int NOT NULL,
       kind int NOT NULL,
       outline_hash text NOT NULL,
       content text,
       is_headline bool NOT NULL,
       -- headline text NOT NULL,
       link_dest text,
       link_desc text
)
