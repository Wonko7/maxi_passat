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
  (* can be optimised print_endline "add to ptree yep"; *)
  (* print_string " level: "; *)
  (* let level = Option.value ~default:100l hl.p_level in *)
  (* print_int @@ Int32.to_int level; *)
  (* print_string " index: "; *)
  (* print_int @@ Int32.to_int hl.p_index; *)
  (* print_string " headline_id: "; *)
  (* print_int @@ Int32.to_int hl.p_headline_id; *)
  (* print_string " parent_id: "; *)
  (* print_int @@ Int32.to_int hl.p_parent_id; *)
  (* print_endline ""; *)
  print_endline "did i fuck up?";
  (* ignore @@ (Printexc_lwt.backtrace 15 |> List.map print_endline); *)
  let hl = List.hd node in
  print_endline "yes";
  match tree with
  | PLeaf ->
      print_endline " NEVER added_as_leaf";
      PNode (node, [])
  | PNode ((fhl :: _ as hls), children)
    when hl.p_headline_id = fhl.p_headline_id ->
      print_endline " NEVER? added_as_current_node";
      PNode (hls @ node, children)
  | PNode (hls, children) when hl.p_parent_id = hl.p_headline_id ->
      print_endline " first LEVEL added_as_child";
      PNode (hls, children @ [PNode (node, [])])
  | PNode ((fhl :: _ as hls), children) when fhl.p_headline_id = hl.p_parent_id
    ->
      print_endline " found correct position";
      PNode (hls, children @ [PNode (node, [])])
  | PNode (hls, children) ->
      print_endline " down one level";
      PNode (hls, List.map (add_to_ptree node) children)

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
      let%lwt children = lwt_flatten [] children in
      f hls children
  | PLeaf -> Lwt.return @@ Eliom_content.Html.F.div []

let rec get_subptree p tree =
  match tree with
  | PNode (hls, children) as st when p hls -> st
  | PNode (hls, children) ->
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
    let link_re = Str.regexp {|\[\[id:\([^][]+\)\]\[\([^][]+\)\]\]|} in
    Str.full_split link_re s
    |> List.map
         Str.(
           function
           | Text t -> Lwt.return @@ Db_types.Text t
           | Delim t ->
               ignore @@ search_forward link_re t 0;
               process_id_link (matched_group 1 t) (matched_group 2 t))
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

let process_org_headlines title outline_hash headlines =
  let root =
    Node
      ( { Db_types.headline_id = -1l
        ; parent_id = -1l
        ; headline_text = title
        ; content = None (* FIXME: there is content *)
        ; level = None
        ; headline_index = None }
      , [] )
  in
  let tree = make_org_note_tree headlines root in
  let i = ref 0 in
  let processed_org =
    { Db_types.headline_id = -1l
    ; index = 0l
    ; kind = 0l
    ; outline_hash
    ; is_headline = true
    ; content = None
    ; link_dest = None
    ; link_desc = None }
  in
  let process_hl h =
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
        ; kind = processed_kind_to_int32 text
        ; headline_id = h.headline_id }
      in
      let processed_org =
        match text with
        | Br -> processed_org
        | Text t -> {processed_org with content = Some t}
        | Id_link (dest, desc) ->
            {processed_org with link_dest = Some dest; link_desc = Some desc}
      in
      let%lwt _ = Org_db.add_processed_headline_content processed_org in
      Lwt.return_unit
    in
    ignore @@ List.map (add_processed true) title;
    ignore @@ List.map (add_processed false) content;
    Lwt.return_unit
  in
  sideeffect_map_tree process_hl tree

let process_org_file file_path =
  let%lwt hls = Org_db.get_headlines_for_file_path file_path in
  let%lwt title, outline_hash =
    match%lwt Org_db.get_title_outline_for_file_path file_path with
    | Some r -> Lwt.return r
    | None -> failwith file_path
  in
  process_org_headlines title outline_hash hls

let preprocess_init () =
  let%lwt is_processed = Org_db.is_processed () in
  if is_processed
  then Lwt.return_unit
  else
    let%lwt files = Org_db.get_all_org_files () in
    ignore @@ List.map process_org_file files;
    Lwt.return_unit
