[%%shared
(* This file was generated by Ocsigen Start.
   Feel free to use it, modify it, and redistribute it as you wish. *)
(* PGOcaml demo *)
open Eliom_content.Html
open Eliom_content.Html.F
open Db_types
open Ww_lib]

let%rpc get_headlines_for_file_path (file_path : string)
    : Db_types.headline list Lwt.t
  =
  Org_db.get_headlines_for_file_path file_path

let%rpc get_roam_nodes (file_path : string) : (int32 * string) list Lwt.t =
  Org_db.get_roam_nodes file_path

let%rpc get_title_outline_for_file_path (file_path : string)
    : (string * string) option Lwt.t
  =
  Org_db.get_title_outline_for_file_path file_path

let%rpc get_processed_org_backlinks (roam_id : string)
    : Db_types.processed_org_headline list Lwt.t
  =
  Org_db.get_processed_org_backlinks roam_id

let%rpc get_processed_org_for_id (roam_id : string)
    : Db_types.processed_org_headline list Lwt.t
  =
  Org_db.get_processed_org_for_id roam_id

let%rpc get_headline_id_for_roam_id (roam_id : string)
    : (int32 * string) option Lwt.t
  =
  Org_db.get_headline_id_for_roam_id roam_id

let%rpc get_file_path_headline (roam_id : string)
    : (string * (string * int32 option)) list Lwt.t
  =
  Org_db.get_file_path_headline roam_id

let%rpc get_file_path_kill_me_with_fire (roam_id : string)
    : (string * (string * int32 option)) list Lwt.t
  =
  Org_db.get_file_path_kill_me_with_fire roam_id

let%rpc get_processed_org_for_path (file_path : string)
    : Db_types.processed_org_headline list Lwt.t
  =
  Org_db.get_processed_org_for_path file_path

[%%shared.start]

let safe_get_title_outline_for_file_path file_path =
  match%lwt get_title_outline_for_file_path file_path with
  | Some r -> Lwt.return r
  | None -> Lwt.return ("", "")

let make_inactive_header_entry ~id ~title_class title content =
  (* this one does not toggle *)
  div ~a:[a_class ["header"]]
  @@ [ div
         [ input
             ~a:
               [ a_id id
               ; a_class ["toggle"]
               ; a_input_type `Checkbox
               ; a_checked ()
               ; a_tabindex 0 ]
             ()
         ; label ~a:[a_label_for id; title_class] title ]
     ; div ~a:[a_class ["org_node_content"]] content ]

let make_collapsible ~id ~title_class title content =
  (* https://www.digitalocean.com/community/tutorials/css-collapsible *)
  div ~a:[a_class ["header"; "wrap-collapsible"]; a_id (String.cat "scroll_" id)]
  @@ [ input
         ~a:
           [ a_id id
           ; a_class ["toggle"]
           ; a_input_type `Checkbox
           ; a_checked ()
           ; a_tabindex 0 ]
         ()
     ; label ~a:[a_label_for id; title_class] title
     ; div ~a:[a_class ["collapsible-content"; "org_node_content"]] content ]

let%client fuck_me_set_file_path
    : (?target_hlid:int32 -> string -> unit Lwt.t) option ref
  =
  ref None

let processed_org_to_html ?(id_links = []) ~kind ~content ~link_dest ~link_desc
    ~active_links
  =
  let link_dest = Option.value ~default:"" link_dest in
  let link_desc = Option.value ~default:"" link_desc in
  let content = Option.value ~default:"" content in
  match active_links, kind with
  | _, "txt" -> txt content
  | _, "br" -> br ()
  | false, "file_link"
  | false, "id_link"
  | false, "file_link"
  | false, "bleau_link"
  | false, "yt_link" ->
      txt link_desc
  | _, "file_link" ->
      a ~service:Maxi_passat_services.org_file [txt link_desc]
      @@ String.split_on_char '\n' link_dest
  | _, "id_link" -> (
    match List.assoc_opt link_dest id_links with
    | Some (filepath, hlid) ->
        span
          ~a:
            [ a_onclick
                [%client
                  fun _ ->
                    Js_of_ocaml.(
                      let set_file_path = Option.get !fuck_me_set_file_path in
                      ignore @@ set_file_path ?target_hlid:~%hlid ~%filepath)]
            ; a_class ["link"] ]
          [txt link_desc]
    | _ -> a ~service:Maxi_passat_services.org_id [txt link_desc] @@ link_dest)
  | _, "bleau_link" ->
      a ~service:Maxi_passat_services.os_bleau_service
        ~a:
          [ a_target "_blank"
          ; a_rel [`Other "noopener"; `Nofollow]
          ; a_class ["external_link"] ]
        [txt "bleau.info : "; txt link_desc]
      @@ String.split_on_char '/' link_dest
  | _, "yt_link" ->
      span
        [ txt "youtube : "
        ; txt link_desc
        ; br ()
        ; iframe
            ~a:
              [ a_width 560
              ; a_height 315 (* ; a_frameborder `Zero *)
              ; Unsafe.string_attrib "frameborder" "0"
              ; Unsafe.string_attrib "allow"
                  "accelerometer autoplay clipboard-write encrypted-media gyroscope picture-in-picture web-share"
              ; a_src
                  (Eliom_content.Xml.uri_of_string
                  @@ String.cat "https://www.youtube.com/embed/" link_dest) ]
            [] ]
  | _ ->
      print_endline "fixme proper warnings please";
      span []

let predicate_org_to_html ?(active_links = true) ?id_links p = function
  | h when p h ->
      Some
        (processed_org_to_html ~kind:h.p_kind ~content:h.p_content
           ~link_dest:h.p_link_dest ~link_desc:h.p_link_desc ?id_links
           ~active_links)
  | _ -> None

let%client last_selected_node =
  let selected, set_selected_title = Eliom_shared.React.S.create false in
  ref set_selected_title

let make_ptree_org_note ?subtree_headline_id ?target_hlid ~title ~headlines
    ~nodes ?id_links
    ~(set_backlinks_id : (string -> unit Lwt.t) Eliom_client_value.t)
  =
  let root =
    Org.PNode
      ( [ { Db_types.p_headline_id = -1l
          ; p_parent_id = -1l
          ; p_is_headline = true
          ; p_content = Some title
          ; p_level = None
          ; p_headline_index = None
          ; p_index = 0l
          ; p_kind = "txt"
          ; p_link_desc = None
          ; p_link_dest = None
          ; p_file_path = "" } ]
      , [] )
  in
  let tree = Org.make_org_note_ptree headlines root in
  let tree =
    Option.fold subtree_headline_id ~none:tree ~some:(fun hid ->
        Org.get_subptree
          (fun hls ->
            match hls with
            | h :: _ when h.p_headline_id = hid -> true
            | _ -> false)
          tree)
  in
  let hl_to_html hls children =
    let f = List.hd hls in
    let pp = predicate_org_to_html ~active_links:true ?id_links in
    let title = List.filter_map (pp (fun h -> h.p_is_headline)) hls in
    let content = List.filter_map (pp (fun h -> not h.p_is_headline)) hls in
    let selected, set_selected_title =
      Eliom_shared.React.S.create
      @@ if target_hlid = Some f.p_headline_id then true else false
    in
    let title_class =
      R.a_class
      @@ Eliom_shared.React.S.map
           [%shared
             let classes = ["lbl-toggle"; "org_node_title"] in
             function false -> classes | true -> "selected_node" :: classes]
           selected
    in
    let backlinks =
      List.assoc_opt f.p_headline_id nodes
      |> Option.map (fun node_id ->
             span
               ~a:
                 [ a_class ["link"]
                 ; a_onclick
                     [%client
                       fun _ ->
                         ignore @@ ~%set_backlinks_id ~%node_id;
                         !last_selected_node false;
                         ignore @@ ~%set_selected_title true;
                         last_selected_node := ~%set_selected_title] ]
               [txt "backlinks"])
      (* TODO i18n *)
    in
    make_collapsible
      ~id:(string_of_int @@ Int32.to_int f.p_headline_id)
      ~title_class title
      [ div ~a:[a_class ["backlinks_link"]] (backlinks @? [])
      ; div ~a:[a_class ["content"]] (content @ children) ]
  in
  let html = Org.map_ptree_to_html hl_to_html tree in
  ignore
  @@ [%client
       (Js_of_ocaml.(
          ignore
          @@ Dom_html.window##setTimeout
               (Js.wrap_callback (fun () ->
                    ignore
                    @@ Option.map
                         (fun hlid ->
                           let elt =
                             Dom_html.getElementById @@ String.cat "scroll_"
                             @@ string_of_int @@ Int32.to_int hlid
                           in
                           elt ## (scrollIntoView Js._true))
                         ~%target_hlid))
               0.01)
         : unit)];
  html

let rec group_by_headline_id (headlines : processed_org_headline list)
    (acc : processed_org_headline list)
    : processed_org_headline list list
  =
  match headlines, acc with
  | [], _ -> [Org.reverse acc]
  | h :: hs, [] -> group_by_headline_id hs [h]
  | h :: hs, (a :: _ as acc) when h.p_headline_id = a.p_headline_id ->
      group_by_headline_id hs (h :: acc)
  | hs, acc -> Org.reverse acc :: group_by_headline_id hs []

let hl_to_inactive_html ~title_selected_s hls =
  let title_class =
    R.a_class
    @@ Eliom_shared.React.S.map
         [%shared
           let classes = ["lbl-toggle"; "org_node_title"; "right_pane_title"] in
           function false -> classes | true -> "selected_node" :: classes]
         title_selected_s
  in
  let pp = predicate_org_to_html ~active_links:false in
  let title = List.filter_map (pp (fun h -> h.p_is_headline)) hls in
  let content = List.filter_map (pp (fun h -> not h.p_is_headline)) hls in
  let f = List.hd hls in
  make_inactive_header_entry
    ~id:(string_of_int @@ Int32.to_int f.p_headline_id)
    ~title_class title
    [div ~a:[a_class ["content"]] content]

let make_backnode_link
    (set_file_path :
      (?target_hlid:int32 -> string -> unit Lwt.t) Eliom_client_value.t) hls
  =
  let title_selected_s, set_selected_title =
    Eliom_shared.React.S.create false
  in
  let f = List.hd hls in
  div
    ~a:
      [ a_onclick
          [%client
            fun _ ->
              ignore
              @@ ~%set_file_path ~target_hlid:~%f.p_headline_id ~%f.p_file_path;
              !last_selected_node false;
              ignore @@ ~%set_selected_title true;
              last_selected_node := ~%set_selected_title] ]
  @@ [hl_to_inactive_html ~title_selected_s hls]

let org_backlinks_content
    (backlinks_node : processed_org_headline list R.list_wrap)
    (set_file_path :
      (?target_hlid:int32 -> string -> unit Lwt.t) Eliom_client_value.t)
  =
  R.div ~a:[a_class ["backlink_content"]]
  @@ Eliom_shared.ReactiveData.RList.map
       [%shared
         fun headlines ->
           let aclass = ["backlinks"] in
           match headlines with
           | [] -> div ~a:[a_class ("invisible" :: aclass)] []
           | headlines ->
               let hls = group_by_headline_id headlines [] in
               let dhls = List.map (make_backnode_link ~%set_file_path) hls in
               div ~a:[a_class aclass] dhls]
       backlinks_node

let org_file_content ~set_file_path
    ~(file_data :
       (string
       * processed_org_headline list
       * (int32 * string) list
       * (string * (string * int32 option)) list option
       * int32 option
       * (string -> unit Lwt.t) Eliom_client_value.t)
       R.wrap)
    : Html_types.div_content Eliom_content.Html.R.elt
  =
  R.node
  @@ Eliom_shared.React.S.map ~eq:[%shared ( == )]
       [%shared
         fun (title, headlines, nodes, id_links, target_hlid, set_backlinks_id) ->
           make_ptree_org_note ?subtree_headline_id:None ?target_hlid ~title
             ~headlines ~nodes ?id_links ~set_backlinks_id]
       file_data

let prepare_roam_id_links hls =
  let%lwt ls =
    List.filter_map
      (fun h ->
        match h.p_kind, h.p_link_dest with
        | "id_link", Some d -> Some d
        | _ -> None)
      hls
    |> List.map (fun id ->
           match%lwt get_file_path_headline id with
           | [] -> get_file_path_kill_me_with_fire id
           | r -> Lwt.return r)
    |> Org.lwt_flatten []
  in
  Lwt.return @@ List.flatten ls

let rec add_slash = function
  | a :: b :: l -> a :: "/" :: add_slash (b :: l)
  | a :: [] -> [a]
  | [] -> []

let gather_org_file_data file_path =
  let%lwt hls = get_processed_org_for_path file_path in
  let%lwt nodes = get_roam_nodes file_path in
  let%lwt roam_links = prepare_roam_id_links hls in
  let%lwt title, _ = safe_get_title_outline_for_file_path file_path in
  Lwt.return (hls, nodes, roam_links, title)

let file_page file_path () =
  let file_path = String.concat "" @@ add_slash file_path in
  let%lwt org_note =
    Ot_spinner.with_spinner
      (let%lwt hls, nodes, id_links, title = gather_org_file_data file_path in
       let backlink_list, set_backlink_nodes =
         Eliom_shared.ReactiveData.RList.create []
       in
       let set_nodes =
         [%client
           fun roam_id ->
             let%lwt nodes = get_processed_org_backlinks roam_id in
             Eliom_shared.ReactiveData.RList.set ~%set_backlink_nodes [nodes];
             Lwt.return_unit]
       in
       let file_data_s, set_file_data =
         Eliom_shared.React.S.create
           (title, hls, nodes, Some id_links, None, set_nodes)
       in
       let set_file_path =
         [%client
           (fun ?target_hlid file_path ->
              let%lwt hls, nodes, id_links, title =
                gather_org_file_data file_path
              in
              ~%set_file_data
                (title, hls, nodes, Some id_links, target_hlid, ~%set_nodes);
              Lwt.return_unit
             : ?target_hlid:int32 -> string -> unit Lwt.t)]
       in
       ignore
       @@ [%client (fuck_me_set_file_path := Some ~%set_file_path : unit)];
       let backlinks_node = org_backlinks_content backlink_list set_file_path in
       let org_content =
         org_file_content ~set_file_path ~file_data:file_data_s
       in
       Lwt.return
         [ div
             ~a:[a_class ["org_page"]]
             [div ~a:[a_class ["org_content"]] [org_content]; backlinks_node] ])
  in
  (* a title would be nice: h1 [%i18n Demo.pgocaml]; *)
  Lwt.return [org_note]

let id_page roam_id () =
  let%lwt org_note =
    (* Ot_spinner.with_spinner *)
    let%lwt hls = get_processed_org_for_id roam_id in
    let%lwt headline_id, file_path =
      match%lwt get_headline_id_for_roam_id roam_id with
      | Some r -> Lwt.return r
      | None -> failwith "could not find parent file_path"
    in
    let title =
      h3
        [ txt "from file : " (* todo i18n *)
        ; a ~service:Maxi_passat_services.org_file [txt file_path]
          @@ String.split_on_char '\n' file_path ]
    in
    (* let%lwt nodes = get_roam_nodes file_path in *)
    (* let%lwt hls = make_ptree_org_note ~headline_id "roam node:" hls nodes in *)
    (* Lwt.return @@ [div [title]; div [hls]]) *)
    Lwt.return @@ [div [title]; div []]
  in
  Lwt.return [div org_note]

let () =
  Maxi_passat_base.App.register ~service:Maxi_passat_services.org_file
    ( Maxi_passat_page.Opt.connected_page @@ fun myid_o file_path () ->
      let%lwt p = file_page file_path () in
      Maxi_passat_container.page ~a:[a_class ["org-page"]] myid_o p );
  Maxi_passat_base.App.register ~service:Maxi_passat_services.org_id
    ( Maxi_passat_page.Opt.connected_page @@ fun myid_o id () ->
      let%lwt p = id_page id () in
      Maxi_passat_container.page ~a:[a_class ["org-page"]] myid_o p )
