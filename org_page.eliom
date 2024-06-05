[%%shared
(* This file was generated by Ocsigen Start.
   Feel free to use it, modify it, and redistribute it as you wish. *)
(* PGOcaml demo *)
open Eliom_content.Html.F
open Db_types
open Ww_lib]

(* Fetch users in database *)
let%rpc get_users () : string list Lwt.t =
  (* For this demo, we add a delay to simulate a network or db latency: *)
  let%lwt () = Lwt_unix.sleep 2. in
  Org_db.get ()

let%rpc get_headlines_for_file_path (file_path : string)
    : Db_types.headline list Lwt.t
  =
  Org_db.get_headlines_for_file_path file_path

let%rpc get_headlines_for_id (roam_id : string) : Db_types.headline list Lwt.t =
  Org_db.get_headlines_for_id roam_id

let%rpc get_headline_id_for_roam_id (roam_id : string)
    : (int32 * string) option Lwt.t
  =
  Org_db.get_headline_id_for_roam_id roam_id

[%%shared.start]

let rec lwt_flatten acc ls =
  match ls with
  | [] -> Lwt.return acc
  | e :: ls ->
      let%lwt e = e in
      lwt_flatten (e :: acc) ls
(* lwt_flatten (acc @ [e]) ls *)

type 'a tree = Leaf | Node of 'a * 'a tree list

let rec add_to_tree hl tree =
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

let rec tree_to_div f tree =
  match tree with
  | Node (thl, children) ->
      let children = List.map (tree_to_div f) children in
      let%lwt children = lwt_flatten [] children in
      f thl children
  | Leaf -> Lwt.return @@ div []

let rec get_subtree p tree =
  match tree with
  | Node (thl, children) as st when p thl -> st
  | Node (thl, children) ->
      List.fold_left (fun acc n -> if n = Leaf then acc else n) Leaf
      @@ List.map (get_subtree p) children
  | Leaf -> Leaf

(* let _ = *)
(*   print_endline "wtf"; *)
(*   let s = "fuck [[id:kkt][lol]] you" in *)
(*   ignore *)
(*   @@ Str.global_substitute *)
(*        (Str.regexp {|\[\[id:\([^][]+\)\]\[\([^][]+\)\]\]|}) *)
(*        (fun s -> *)
(*          print_endline "got:"; *)
(*          print_endline s; *)
(*          print_endline @@ Str.matched_group 1 s; *)
(*          print_endline @@ Str.matched_group 2 s; *)
(*          "wtf") *)
(*        s *)

let make_org_id_link path description =
  match%lwt get_headline_id_for_roam_id path with
  | None -> Lwt.return @@ txt description
  | Some _ ->
      Lwt.return
      @@ a ~service:Maxi_passat_services.org_id [txt description] path

let org_text_to_html s =
  let find_links s =
    let link_re = Str.regexp {|\[\[id:\([^][]+\)\]\[\([^][]+\)\]\]|} in
    Str.full_split link_re s
    |> List.map
         Str.(
           function
           | Text t -> Lwt.return @@ txt t
           | Delim t ->
               ignore @@ search_forward link_re s 0;
               make_org_id_link (matched_group 1 s) (matched_group 2 s))
    (*optimise*)
    (* |> Lwt_list.fold_left_s (fun acc a -> Lwt.return @@ acc @ [a]) [] *)
    |> lwt_flatten []
  in
  let rec add_brs acc = function
    (* optimize *)
    | [] -> Lwt.return []
    | e :: [] ->
        let%lwt a = find_links e in
        Lwt.return @@ acc @ a
    | e :: l ->
        let%lwt a = find_links e in
        add_brs (a @ [br ()] @ acc) l
    (* [a; br ()] *)
    (* add_brs (acc @ [a; br ()]) l (\* [a; br ()] *\) *)
  in
  String.split_on_char '\n' s |> add_brs []

let inf_i = ref 0

let make_collapsible title content =
  (* could use headline_id instead of inf_i *)
  (* https://www.digitalocean.com/community/tutorials/css-collapsible *)
  inf_i := !inf_i + 1;
  let cid = String.cat "coll-" @@ string_of_int !inf_i in
  div ~a:[a_class ["header wrap-collapsible"; "indent-1"]]
  @@ [ input
         ~a:
           [ a_id cid
           ; a_class ["toggle"]
           ; a_input_type `Checkbox
           ; a_checked ()
           ; a_tabindex 0 ]
         ()
     ; label ~a:[a_label_for cid; a_class ["lbl-toggle"]] title
     ; div ~a:[a_class ["collapsible-content"]] content ]

let make_tree_org_note ?headline_id title headlines =
  let root =
    Node
      ( { Db_types.headline_id = -1l
        ; parent_id = -1l
        ; headline_text = title
        ; content = None
        ; level = None
        ; headline_index = None }
      , [] )
  in
  let tree = make_org_note_tree headlines root in
  let tree =
    Option.fold headline_id ~none:tree ~some:(fun hid ->
        get_subtree (fun hl -> hl.headline_id = hid) tree)
  in
  let hl_to_html h children =
    let%lwt title = org_text_to_html h.headline_text in
    match h.content with
    | None -> Lwt.return @@ make_collapsible title @@ children
    | Some c ->
        let%lwt c = org_text_to_html c in
        Lwt.return @@ make_collapsible title
        @@ [div ~a:[a_class ["content"]] (c @ children)]
  in
  tree_to_div hl_to_html tree

let rec add_slash = function
  | a :: b :: l -> a :: "/" :: add_slash (b :: l)
  | a :: [] -> [a]
  | [] -> []

let file_page file_path () =
  let file_path = String.concat "" @@ add_slash file_path in
  let%lwt org_note =
    Ot_spinner.with_spinner
      (let%lwt hls = get_headlines_for_file_path file_path in
       let%lwt hls = make_tree_org_note "what" hls in
       Lwt.return [div [hls]])
  in
  (* a title would be nice: h1 [%i18n Demo.pgocaml]; *)
  Lwt.return [org_note]

let id_page roam_id () =
  let%lwt org_note =
    Ot_spinner.with_spinner
      (let%lwt hls = get_headlines_for_id roam_id in
       let%lwt parent_hl_res = get_headline_id_for_roam_id roam_id in
       let title =
         Option.map
           (fun (headline_id, file_path) ->
             h3
               [ txt "from file : "
               ; a ~service:Maxi_passat_services.org_file [txt file_path]
                 @@ String.split_on_char '\n' file_path ])
           parent_hl_res
       in
       let headline_id =
         Option.map (fun (headline_id, _file_path) -> headline_id) parent_hl_res
       in
       let%lwt hls = make_tree_org_note "what" hls ?headline_id in
       Lwt.return @@ title @? [div [hls]])
  in
  Lwt.return [org_note]

let () =
  Maxi_passat_base.App.register ~service:Maxi_passat_services.org_file
    ( Maxi_passat_page.Opt.connected_page @@ fun myid_o file_path () ->
      let%lwt p = file_page file_path () in
      Maxi_passat_container.page ~a:[a_class ["org-page"]] myid_o p );
  Maxi_passat_base.App.register ~service:Maxi_passat_services.org_id
    ( Maxi_passat_page.Opt.connected_page @@ fun myid_o id () ->
      let%lwt p = id_page id () in
      Maxi_passat_container.page ~a:[a_class ["org-page"]] myid_o p )
