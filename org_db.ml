(* This file was generated by Ocsigen Start.
   Feel free to use it, modify it, and redistribute it as you wish. *)

open Os_db

(* We are using PGOCaml to make type safe DB requests to Postgresql.
   The Makefile automatically compiles
   all files *_db.ml with PGOCaml's ppx syntax extension.
*)

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

let get_headlines file_path =
  let file_path = String.cat "/data/org/" file_path in
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
