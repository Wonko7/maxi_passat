\connect org_sql;

-- org_sql db "admin" (not root but has the power to create objects in this db)
CREATE ROLE org_sql WITH LOGIN PASSWORD 'org_sql';

CREATE SCHEMA org AUTHORIZATION org_sql;

GRANT ALL ON SCHEMA org TO org_sql;

GRANT ALL ON SCHEMA org TO wonko;

-- after (org-sql-user-init):

\dn;

\dt org.*;

\dc org.headlines;

-- after (org-sql-user-push):

select * from org.file_metadata;

select * from org.outlines;


select headline_id, headline_text, level, headline_index, content from org.headlines where outline_hash = '3db55aef08678059e115514d15a2db33';


select * from org.headlines where outline_hash = '3db55aef08678059e115514d15a2db33';



select * from org.headlines where false;

SELECT h.headline_id, h.headline_index, h.level, h.content, hc.parent_id
             FROM org.headlines h, org.headline_closures hc
             WHERE outline_hash = '3db55aef08678059e115514d15a2db33'
               AND hc.depth = 0
               AND h.headline_id = hc.headline_id
             ORDER BY level ASC, headline_index ASC
