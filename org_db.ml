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

let get () =
  full_transaction_block (fun dbh ->
      [%pgsql dbh "SELECT lastname FROM ocsigen_start.users"])

let obj_to_headline h =
  { Db_types.headline_id = h#headline_id
  ; parent_id = h#parent_id
  ; headline_text = h#headline_text
  ; headline_index = h#headline_index
  ; level = h#level
  ; content = h#content }

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
             ORDER BY level ASC, headline_index ASC "])
  in
  Lwt.return @@ List.map obj_to_headline hls

let get_headlines_for_id roam_id =
  let%lwt hls =
    full_transaction_block (fun dbh ->
        [%pgsql.object
          dbh
            "SELECT h.headline_id, h.headline_index, h.level, h.content,
                    hc.parent_id, h.headline_text, hc.depth
             FROM org.headlines h, org.headline_closures hc, org.properties p
             WHERE p.key_text = 'ID' AND p.val_text = $roam_id
               AND p.outline_hash = h.outline_hash
               AND h.headline_id = hc.headline_id
               AND (hc.depth = 1 OR (hc.depth = 0 AND h.level = 1))
             ORDER BY level ASC, headline_index ASC "])
  in
  Lwt.return @@ List.map obj_to_headline hls

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
