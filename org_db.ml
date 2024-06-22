(* This file was generated by Ocsigen Start.
   Feel free to use it, modify it, and redistribute it as you wish. *)

open Os_db

(* We are using PGOCaml to make type safe DB requests to Postgresql.
   The Makefile automatically compiles
   all files *_db.ml with PGOCaml's ppx syntax extension.
*)

let org_prefix = "/data/org/"

let strip_org_prefix s =
  let pl = String.length org_prefix in
  let l = String.length s in
  String.sub s pl (l - pl)

let obj_to_headline h =
  { Db_types.headline_id = h#headline_id
  ; parent_id = h#parent_id
  ; headline_text = h#headline_text
  ; headline_index = h#headline_index
  ; level = h#level
  ; content = h#content }

let obj_to_processed_org_headline h =
  { Db_types.p_headline_id = h#headline_id
  ; p_index = h#index
  ; p_level = h#level
  ; p_parent_id = h#parent_id
  ; p_kind = h#kind
  ; p_is_headline = h#is_headline
  ; p_headline_index = h#headline_index
  ; p_content = h#content
  ; p_link_desc = h#link_desc
  ; p_link_dest = h#link_dest
  ; p_file_path = h#file_path }

let get_headlines_for_file_path file_path =
  let file_path = String.cat org_prefix file_path in
  let%lwt hls =
    full_transaction_block (fun dbh ->
        [%pgsql.object
          dbh
            "SELECT h.headline_id, h.headline_index, h.level, h.content,
                    hc.parent_id, h.headline_text, hc.depth
             FROM org.headlines h, org.headline_closures hc, org.file_metadata m
             WHERE m.file_path = $file_path
               AND m.outline_hash = h.outline_hash
               AND h.headline_id = hc.headline_id
               AND (hc.depth = 1 OR (hc.depth = 0 AND h.level = 1))
             ORDER BY h.headline_id ASC "])
  in
  Lwt.return @@ List.map obj_to_headline hls

let get_processed_org_for_id roam_id =
  let%lwt hls =
    full_transaction_block (fun dbh ->
        [%pgsql.object
          dbh
            "SELECT h.headline_id, pc.index, hc.parent_id, h.headline_index, h.level, pc.kind,
                    pc.content, pc.is_headline, pc.link_dest, pc.link_desc, m.file_path
             FROM org.processed_content pc, org.headlines h, org.headline_closures hc, org.properties p, org.file_metadata m
             WHERE p.key_text = 'ID' AND p.val_text = $roam_id
               AND p.outline_hash = h.outline_hash
               AND p.outline_hash = m.outline_hash
               AND h.headline_id = hc.headline_id
               AND h.headline_id = pc.headline_id
               AND (hc.depth = 1 OR (hc.depth = 0 AND h.level = 1))
             ORDER BY level ASC, headline_index ASC "])
  in
  Lwt.return @@ List.map obj_to_processed_org_headline hls

let get_processed_org_for_path file_path =
  let file_path = String.cat org_prefix file_path in
  let%lwt hls =
    full_transaction_block (fun dbh ->
        [%pgsql.object
          dbh (* fixme do i need headline_index? *)
            "SELECT h.headline_id, pc.index, hc.parent_id, h.headline_index, h.level, pc.kind,
                    pc.content, pc.is_headline, pc.link_dest, pc.link_desc, m.file_path
             FROM org.processed_content pc, org.headlines h, org.headline_closures hc, org.file_metadata m
             WHERE m.file_path = $file_path
               AND m.outline_hash = h.outline_hash
               AND h.headline_id = hc.headline_id
               AND h.headline_id = pc.headline_id
               AND (hc.depth = 1 OR (hc.depth = 0 AND h.level = 1))
              ORDER by h.headline_id ASC, pc.index ASC"])
  in
  Lwt.return @@ List.map obj_to_processed_org_headline hls

let get_processed_org_backlinks roam_id =
  let%lwt hls =
    full_transaction_block (fun dbh ->
        [%pgsql.object
          dbh (* fixme do i need headline_index? *)
            "SELECT pc.headline_id, pc.index, hc.parent_id, h.headline_index, h.level, pc.kind,
                    pc.content, pc.is_headline, pc.link_dest, pc.link_desc, m.file_path
             FROM org.processed_content pc, org.headline_closures hc, org.headlines h,
                  org.processed_content pc_links, org.file_metadata m
             WHERE pc_links.link_dest = $roam_id
               AND pc_links.headline_id = hc.headline_id
               AND pc.headline_id = hc.headline_id
               AND h.headline_id = hc.headline_id
               AND h.outline_hash = m.outline_hash
               AND (hc.depth = 1 OR (hc.depth = 0 AND h.level = 1))
             ORDER BY pc.index ASC, h.level ASC, h.headline_index ASC"])
  in
  Lwt.return @@ List.map obj_to_processed_org_headline hls

let get_headline_id_for_roam_id roam_id =
  let%lwt hl_id =
    full_transaction_block (fun dbh ->
        [%pgsql
          dbh
            "SELECT hp.headline_id, m.file_path
             FROM org.headline_properties hp, org.properties p, org.file_metadata m
             WHERE p.key_text = 'ID' AND p.val_text = $roam_id
               AND p.property_id = hp.property_id
               AND p.outline_hash = m.outline_hash"])
  in
  Lwt.return
  @@
  match hl_id with
  | [(i, s)] -> Some (i, strip_org_prefix s)
  | [] -> None
  | _ -> failwith "bug: got multiple headlines"

let get_title_outline_for_file_path file_path =
  let file_path = String.cat org_prefix file_path in
  let%lwt title_and_outline =
    full_transaction_block (fun dbh ->
        [%pgsql
          dbh
            "SELECT p.val_text, m.outline_hash
             FROM org.properties p, org.file_metadata m
             WHERE m.file_path = $file_path
               AND m.outline_hash = p.outline_hash
               and p.key_text = 'TITLE'"])
  in
  Lwt.return
  @@
  match title_and_outline with
  | [res] -> Some res
  | [] -> None
  | _ -> failwith "bug: got multiple titles"

let get_outline_hash_for_file_path file_path =
  let file_path = String.cat org_prefix file_path in
  let%lwt outline =
    full_transaction_block (fun dbh ->
        [%pgsql
          dbh
            "SELECT m.outline_hash
             FROM org.file_metadata m
             WHERE m.file_path = $file_path"])
  in
  Lwt.return
  @@
  match outline with
  | [res] -> Some res
  | [] -> None
  | _ -> failwith "bug: got multiple outlines"

let get_roam_nodes file_path =
  let file_path = String.cat org_prefix file_path in
  full_transaction_block (fun dbh ->
      [%pgsql
        dbh
          "SELECT h.headline_id, p.val_text
             FROM org.headlines h, org.file_metadata m , org.headline_properties hp, org.properties p
             WHERE m.file_path = $file_path
               AND m.outline_hash = h.outline_hash
               AND hp.property_id = p.property_id
               AND h.headline_id = hp.headline_id
               AND p.key_text = 'ID'
           "])

let get_all_org_files () =
  let%lwt files =
    full_transaction_block (fun dbh ->
        [%pgsql dbh "SELECT file_path FROM org.file_metadata;"])
  in
  Lwt.return @@ List.map strip_org_prefix files

let is_processed () =
  let%lwt count =
    full_transaction_block (fun dbh ->
        [%pgsql dbh "SELECT outline_hash FROM org.processed_content LIMIT 1"])
  in
  Lwt.return @@ match count with [] -> false | _ -> true

let reset_processed () =
  full_transaction_block (fun dbh ->
      [%pgsql dbh "DELETE FROM org.processed_content"])

let add_processed_headline_content (processed_org : Db_types.processed_org) =
  let o = processed_org in
  let headline_id = o.headline_id in
  let index = o.index in
  let kind = o.kind in
  let outline_hash = o.outline_hash in
  let content = o.content in
  let is_headline = o.is_headline in
  let link_dest = o.link_dest in
  let link_desc = o.link_desc in
  full_transaction_block (fun dbh ->
      [%pgsql
        dbh
          "INSERT INTO org.processed_content
           (headline_id, index, kind, outline_hash, content, is_headline, link_dest, link_desc)
           VALUES
           ($headline_id, $index, $kind, $outline_hash, $?content, $is_headline, $?link_dest, $?link_desc)"])
