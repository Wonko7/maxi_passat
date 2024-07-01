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




SELECT p.val_text, m.outline_hash
             FROM org.properties p, org.file_metadata m
             WHERE
             -- m.file_path = '/data/org/here-be-dragons/20210825151927-mont_ussy.org'
               m.outline_hash = p.outline_hash
               and p.key_text = 'TITLE'


select * from org.file_metadata;

SELECT outline_hash FROM org.processed_content LIMIT 1;

DELETE FROM org.processed_content;

COUNT 2

SELECT pc.headline_id, pc.index, hc.parent_id, hc.depth, h.headline_index, h.level, pc.kind, pc.is_headline, substring(pc.content, 1, 40)
FROM org.processed_content pc, org.headline_closures hc, org.headlines h
--WHERE pc.outline_hash = '18471498edea3d0a0f2ad5e8e62e83fe'
WHERE pc.outline_hash = 'b08c20d0681e873fa55ff94a6960bab3'
  AND pc.headline_id = hc.headline_id
  AND h.headline_id = hc.headline_id
  AND (hc.depth = 1 OR (hc.depth = 0 AND h.level = 1))
   ORDER BY h.headline_id
   -- h.level ASC, h.headline_index ASC

18471498edea3d0a0f2ad5e8e62e83fe

-- this one wins:
-- SELECT h.headline_id, pc.index, hc.parent_id, h.headline_index, h.level, pc.kind, substring(pc.content, 1, 40), hc.parent_id
SELECT h.headline_id, pc.index, hc.parent_id, h.headline_index, h.level, pc.kind, pc.content,
       pc.kind, pc.is_headline, pc.link_dest, pc.link_desc
FROM org.processed_content pc, org.headlines h, org.headline_closures hc, org.file_metadata m
             WHERE m.file_path = '/data/org/here-be-dragons/the-road-so-far/_archive/2024-05-28.org'
               AND m.outline_hash = h.outline_hash
               AND h.headline_id = hc.headline_id
               AND h.headline_id = pc.headline_id
               AND (hc.depth = 1 OR (hc.depth = 0 AND h.level = 1))
              ORDER by pc.index ASC


SELECT h.headline_id, pc.index, hc.parent_id, h.headline_index, h.level, pc.kind, substring(pc.content, 1, 40),
                    pc.is_headline, pc.link_dest, pc.link_desc
             FROM org.processed_content pc, org.headlines h, org.headline_closures hc, org.file_metadata m
             WHERE m.file_path =  '/data/org/here-be-dragons/the-road-so-far/_archive/2024-05-28.org'
               AND m.outline_hash = h.outline_hash
               AND h.headline_id = hc.headline_id
               AND h.headline_id = pc.headline_id
               AND (hc.depth = 1 OR (hc.depth = 0 AND h.level = 1))
              ORDER by headline_id, pc.index ASC

LIMIT 1;


SELECT h.headline_id, hc.parent_id, h.headline_index, h.level, substring(h.content, 1, 40), substring(h.headline_text, 1, 40), hc.depth
             FROM org.headlines h, org.headline_closures hc, org.file_metadata m
             WHERE m.file_path = '/data/org/here-be-dragons/the-road-so-far/_archive/2024-05-28.org'
               AND m.outline_hash = h.outline_hash
               AND h.headline_id = hc.headline_id
               AND (hc.depth = 1 OR (hc.depth = 0 AND h.level = 1))
             ORDER BY h.headline_id ASC
             -- ORDER BY level ASC, headline_index ASC


SELECT pc.headline_id, pc.index, hc.parent_id, h.headline_index, h.level,
                    substring(pc.content, 1, 40),
                    pc.kind, pc.is_headline, pc.link_dest, pc.link_desc
             FROM org.processed_content pc, org.headline_closures hc, org.file_metadata m, org.headlines h
             WHERE m.file_path = '/data/org/here-be-dragons/20210825151927-mont_ussy.org'
               AND m.outline_hash = h.outline_hash
               AND h.headline_id = hc.headline_id
               AND pc.headline_id = hc.headline_id
               AND (hc.depth = 1 OR (hc.depth = 0 AND h.level = 1))
             ORDER BY h.headline_index


SELECT pc.headline_id, pc.index, hc.parent_id, h.headline_index, h.level,
                    pc.content,
                    pc.kind, pc.is_headline, pc.link_dest, pc.link_desc
           FROM org.processed_content pc, org.headline_closures hc, org.headlines h
           WHERE pc.outline_hash = $outline_hash
             AND pc.headline_id = hc.headline_id
             AND h.headline_id = hc.headline_id
             AND (hc.depth = 1 OR (hc.depth = 0 AND h.level = 1))
           ORDER BY pc.index ASC, h.level ASC, h.headline_index ASC


SELECT pc.headline_id, pc.index, hc.parent_id, hc.depth, h.headline_index, h.level, pc.kind, pc.is_headline, substring(pc.content, 1, 40)
FROM org.processed_content pc, org.headline_closures hc, org.headlines h
--WHERE pc.outline_hash = '18471498edea3d0a0f2ad5e8e62e83fe'
WHERE pc.outline_hash = 'b08c20d0681e873fa55ff94a6960bab3'
  AND pc.headline_id = hc.headline_id
  AND h.headline_id = hc.headline_id
  AND (hc.depth = 1 OR (hc.depth = 0 AND h.level = 1))
   ORDER BY h.headline_id




select m.file_path, hp.headline_id from org.properties p, org.headline_properties hp,  org.file_metadata m
-- where  p.val_text = '61ff0e60-0d01-4813-9673-cfa19d6c9934'
where  p.val_text = 'ae49f1f5-8302-4556-857b-1830baf58e53'
 AND p.key_text = 'ID'
 AND hp.property_id = p.property_id
 AND p.outline_hash = m.outline_hash

select m.file_path from org.properties p, org.file_metadata m
where  p.val_text = '61ff0e60-0d01-4813-9673-cfa19d6c9934'
 AND p.key_text = 'ID'
 AND p.outline_hash = m.outline_hash

select m.file_path from org.file_metadata m;
