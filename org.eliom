[%%shared.start]

open Db_types

type 'a tree = Leaf | Node of 'a * 'a tree list
type 'a ptree = PLeaf | PNode of 'a list * 'a ptree list

let reverse list =
  let rec loop acc = function [] -> acc | e :: l -> loop (e :: acc) l in
  loop [] list

let lwt_flatten acc ls =
  let rec loop acc = function
    | [] -> Lwt.return acc
    | e :: ls ->
        let%lwt e = e in
        loop (e :: acc) ls
  in
  let%lwt res = loop acc ls in
  Lwt.return @@ reverse res

let rec add_to_tree (hl : Db_types.headline) (tree : Db_types.headline tree)
    : Db_types.headline tree
  =
  (* can be optimised *)
  match tree with
  | Leaf -> Node (hl, [])
  | Node (thl, children) when hl.parent_id = thl.headline_id ->
      Node (thl, children @ [Node (hl, [])])
  | Node (thl, children) when hl.parent_id = hl.headline_id ->
      Node (thl, children @ [Node (hl, [])])
  | Node (thl, children) -> Node (thl, List.map (add_to_tree hl) children)

let rec make_org_note_tree headlines acc =
  match headlines with
  | [] -> acc
  | hl :: hls -> make_org_note_tree hls (add_to_tree hl acc)

let rec add_to_ptree (node : Db_types.processed_org_headline list)
    (tree : Db_types.processed_org_headline ptree)
    : Db_types.processed_org_headline ptree
  =
  (* can be optimised  *)
  let hl = List.hd node in
  match tree with
  | PLeaf -> PNode (node, [])
  | PNode (hls, children) when hl.p_parent_id = hl.p_headline_id ->
      PNode (hls, children @ [PNode (node, [])])
  | PNode ((fhl :: _ as hls), children) when fhl.p_headline_id = hl.p_parent_id
    ->
      PNode (hls, children @ [PNode (node, [])])
  | PNode (hls, children) -> PNode (hls, List.map (add_to_ptree node) children)

let rec take_while p ls acc =
  match ls with
  | e :: ls when p e -> take_while p ls (e :: acc)
  | l -> reverse acc, l

let rec make_org_note_ptree headlines acc =
  match headlines with
  | [] -> acc
  | hl :: hls ->
      let node_hls, hls =
        take_while (fun h -> h.p_headline_id = hl.p_headline_id) hls []
      in
      let node_hls = hl :: node_hls in
      make_org_note_ptree hls (add_to_ptree node_hls acc)

(* TODO: make a pretty version of these false map fns: *)
let rec sideeffect_map_tree f tree =
  match tree with
  | Node (thl, children) ->
      ignore @@ f thl;
      let children = List.map (sideeffect_map_tree f) children in
      let%lwt children = lwt_flatten [] children in
      ignore @@ children;
      (* let%lwt children = lwt_flatten [] children in *)
      Lwt.return []
  | Leaf -> Lwt.return []

let rec map_tree_to_html f tree =
  match tree with
  | Node (thl, children) ->
      let children = List.map (map_tree_to_html f) children in
      let%lwt children = lwt_flatten [] children in
      f thl children
  | Leaf -> Lwt.return @@ Eliom_content.Html.F.div []

let rec map_ptree_to_html f tree =
  match tree with
  | PNode (hls, children) ->
      let children = List.map (map_ptree_to_html f) children in
      f hls children
  | PLeaf -> Eliom_content.Html.F.div []

let rec get_subptree p tree =
  match tree with
  | PNode (hls, _) as st when p hls -> st
  | PNode (_, children) ->
      List.fold_left (fun acc n -> if n = PLeaf then acc else n) PLeaf
      @@ List.map (get_subptree p) children
  | PLeaf -> PLeaf

[%%server.start]

let process_id_link destination description =
  match%lwt Org_db.get_headline_id_for_roam_id destination with
  | None -> Lwt.return @@ Text description
  | Some _ -> Lwt.return @@ Id_link (destination, description)

let process_org_text s =
  let find_links s =
    let link_re = Str.regexp {|\[\[\([^:]+\):\([^][]+\)\]\[\([^][]+\)\]\]|} in
    let youtube_re = Str.regexp {|^//www.youtube.com/watch\?v=\([^&]+\).*|} in
    let bleau_re = Str.regexp {|^//bleau.info/|} in
    Str.full_split link_re s
    |> List.map
         Str.(
           function
           | Text t -> Lwt.return @@ Db_types.Text t
           | Delim t -> (
               ignore @@ search_forward link_re t 0;
               match matched_group 1 t with
               | "id" -> process_id_link (matched_group 2 t) (matched_group 3 t)
               | "https" ->
                   let dest = matched_group 2 t in
                   let full_dest = String.cat "https:" dest in
                   let desc = matched_group 3 t in
                   Lwt.return
                   @@
                   if Str.string_match youtube_re dest 0
                   then
                     let suff = Str.replace_first youtube_re {|\1|} dest in
                     Yt_link (suff, desc)
                   else if Str.string_match bleau_re dest 0
                   then
                     let suff = Str.replace_first bleau_re {||} dest in
                     Bleau_link (suff, desc)
                   else Https_link (full_dest, desc)
               (* add file & img *)
               | _ -> Lwt.return @@ Db_types.Text "fuck links"))
    |> lwt_flatten []
  in
  let rec add_brs acc = function
    | [] -> Lwt.return []
    | e :: [] ->
        let%lwt a = find_links e in
        Lwt.return @@ acc @ a
    | e :: l ->
        let%lwt a = find_links e in
        add_brs (acc @ a @ [Br]) l
  in
  String.split_on_char '\n' s |> add_brs []

let process_org_headlines _title outline_hash headlines =
  let i = ref 0 in
  let processed_org =
    { Db_types.headline_id = -1l
    ; index = 0l
    ; kind = "txt"
    ; outline_hash
    ; is_headline = true
    ; content = None
    ; link_dest = None
    ; link_desc = None }
  in
  let process_hl (h : Db_types.headline) =
    let%lwt title = process_org_text h.headline_text in
    let%lwt content =
      Option.map (fun c -> process_org_text c) h.content
      |> Option.value ~default:(Lwt.return [])
    in
    let add_processed is_headline text =
      i := !i + 1;
      let processed_org =
        { processed_org with
          index = Int32.of_int !i
        ; is_headline
        ; kind = processed_kind_to_str text
        ; headline_id = h.headline_id }
      in
      let processed_org =
        match text with
        | Br -> processed_org
        | Text t -> {processed_org with content = Some t}
        | Id_link (dest, desc)
        | File_link (dest, desc)
        | Yt_link (dest, desc)
        | Bleau_link (dest, desc)
        | Https_link (dest, desc) ->
            {processed_org with link_dest = Some dest; link_desc = Some desc}
      in
      Org_db.add_processed_headline_content processed_org
    in
    ignore @@ List.map (add_processed true) title;
    ignore @@ List.map (add_processed false) content;
    Lwt.return_unit
  in
  ignore @@ List.map process_hl headlines;
  Lwt.return_unit

let process_org_file file_path =
  print_string " ++ ";
  print_endline file_path;
  let%lwt hls = Org_db.get_headlines_for_file_path file_path in
  let%lwt title, outline_hash =
    match%lwt Org_db.get_title_outline_for_file_path file_path with
    | Some r -> Lwt.return r
    | None -> (
        match%lwt Org_db.get_outline_hash_for_file_path file_path with
        | Some o -> Lwt.return ("", o)
        | None -> failwith file_path)
  in
  process_org_headlines title outline_hash hls

let preprocess_init () =
  (* let%lwt _ = Org_db.reset_processed () in *)
  let%lwt is_processed = Org_db.is_processed () in
  if is_processed
  then Lwt.return_unit
  else (
    print_endline "preprocessing org files";
    let%lwt files = Org_db.get_all_org_files () in
    ignore @@ List.map process_org_file files;
    print_endline "done preprocessing";
    Lwt.return_unit)
