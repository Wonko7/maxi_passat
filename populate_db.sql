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

SELECT h.headline_id, h.headline_index, h.level, hc.parent_id
             FROM org.headlines h, org.headline_closures hc
             WHERE outline_hash = '3db55aef08678059e115514d15a2db33'
               AND (hc.depth = 1 OR (hc.depth = 0 AND h.level = 1))
               AND h.headline_id = hc.headline_id
             ORDER BY level ASC, headline_index ASC


select file_path, outline_hash from org.file_metadata;

SELECT h.headline_id, h.headline_index, h.level, h.content, hc.parent_id, h.headline_text, hc.depth
             FROM org.headlines h, org.headline_closures hc
             WHERE outline_hash = '3db55aef08678059e115514d15a2db33'
               AND h.level = 1
--               AND hc.depth = 1
               AND h.headline_id = hc.headline_id
             ORDER BY level ASC, headline_index ASC

-- WHERE m.file_path = '/data/org/here-be-dragons/20210825151927-mont_ussy.org'

SELECT h.headline_id, h.headline_index, h.level, h.content, hc.parent_id, h.headline_text, hc.depth
             FROM org.headlines h, org.headline_closures hc, org.file_metadata m
             WHERE m.file_path = '/data/org/here-be-dragons/the-road-so-far/2024-05-28.org'
               AND m.outline_hash = h.outline_hash
               AND h.headline_id = hc.headline_id
               AND (hc.depth = 1 OR (hc.depth = 0 AND h.level = 1))
             ORDER BY level ASC, headline_index ASC


select * from org.headline_properties

select * from org.properties

SELECT hp.headline_id, hp.property_id, m.file_path
  FROM org.headline_properties hp, org.properties p, org.file_metadata m
  WHERE p.key_text = 'ID' AND p.val_text = 'b0b02d9e-9591-484b-9642-7fabc25f6901'
    AND p.property_id = hp.property_id
    AND p.outline_hash = m.outline_hash

  -- WHERE p.key_text = 'ID' AND p.val_text = $roam_id

select p.val_text from org.file_metadata m, org.properties p
where '/data/org/here-be-dragons/20210825151927-mont_ussy.org' = m.file_path
and p.outline_hash = m.outline_hash


  FROM org.headline_properties hp, org.properties p, org.file_metadata m
  WHERE p.key_text = 'ID' AND p.val_text = 'b0b02d9e-9591-484b-9642-7fabc25f6901'



SELECT hp.headline_id, m.file_path
             FROM org.headline_properties hp, org.properties p, org.file_metadata m
             WHERE p.key_text = 'ID' AND p.val_text = 'b0b02d9e-9591-484b-9642-7fabc25f6901'
               AND p.property_id = hp.property_id
               and p.outline_hash = m.outline_hash



SELECT hp.headline_id, m.file_path
             FROM org.headline_properties hp, org.properties p, org.file_metadata m
             WHERE p.key_text = 'ID' AND p.val_text =
               AND p.property_id = hp.property_id
               AND p.outline_hash = m.outline_hash




SELECT m.file_path, p.val_text
             FROM org.headline_properties hp, org.properties p, org.file_metadata m
             WHERE p.key_text = 'ID'
             AND p.val_text = '61ff0e60-0d01-4813-9673-cfa19d6c9934'


select * from org.properties p
where  p.val_text = '61ff0e60-0d01-4813-9673-cfa19d6c9934'
