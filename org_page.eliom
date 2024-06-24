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
  div ~a:[a_class ["header"; "wrap-collapsible"]]
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

let processed_org_to_html ~kind ~content ~link_dest ~link_desc ~active_links =
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
  | _, "id_link" ->
      a ~service:Maxi_passat_services.org_id [txt link_desc] @@ link_dest
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

let predicate_org_to_html ?(active_links = true) p = function
  | h when p h ->
      Some
        (processed_org_to_html ~kind:h.p_kind ~content:h.p_content
           ~link_dest:h.p_link_dest ~link_desc:h.p_link_desc ~active_links)
  | _ -> None

let%client last_selected_node =
  let selected, set_selected_title = Eliom_shared.React.S.create false in
  ref set_selected_title

let make_ptree_org_note ?headline_id title headlines nodes
    (set_backlinks_id : (string -> unit Lwt.t) Eliom_client_value.t)
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
    Option.fold headline_id ~none:tree ~some:(fun hid ->
        Org.get_subptree
          (fun hls ->
            match hls with
            | h :: _ when h.p_headline_id = hid -> true
            | _ -> false)
          tree)
  in
  let hl_to_html hls children =
    let pp = predicate_org_to_html ~active_links:true in
    let title = List.filter_map (pp (fun h -> h.p_is_headline)) hls in
    let content = List.filter_map (pp (fun h -> not h.p_is_headline)) hls in
    let selected, set_selected_title = Eliom_shared.React.S.create false in
    let title_class =
      R.a_class
      @@ Eliom_shared.React.S.map
           [%shared
             let classes = ["lbl-toggle"; "org_node_title"] in
             function false -> classes | true -> "selected_node" :: classes]
           selected
    in
    let f = List.hd hls in
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
  Org.map_ptree_to_html hl_to_html tree

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
    (set_file_path : (string -> unit Lwt.t) Eliom_client_value.t) hls
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
              ignore @@ ~%set_file_path ~%f.p_file_path;
              !last_selected_node false;
              ignore @@ ~%set_selected_title true;
              last_selected_node := ~%set_selected_title] ]
  @@ [hl_to_inactive_html ~title_selected_s hls]

(* let print_trace f = *)
(*   try f () *)
(*   with e -> *)
(*     let msg = Printexc.to_string e and stack = Printexc.get_backtrace () in *)
(*     Printf.eprintf "there was an error: %s%s\n" msg stack; *)
(*     raise e *)

let org_backlinks_content
    (backlinks_node : processed_org_headline list R.list_wrap) set_file_path
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

let org_file_content
    (file_data :
      (string
      * processed_org_headline list
      * (int32 * string) list
      * (string -> unit Lwt.t) Eliom_client_value.t)
      list
      R.list_wrap)
  =
  R.div
  @@ Eliom_shared.ReactiveData.RList.map
       [%shared
         function
         | [(title, headlines, nodes, set_nodes)] ->
             make_ptree_org_note title headlines nodes set_nodes
         | _ -> failwith "bad file data for org_file_content"]
       file_data

let rec add_slash = function
  | a :: b :: l -> a :: "/" :: add_slash (b :: l)
  | a :: [] -> [a]
  | [] -> []

let file_page file_path () =
  let file_path = String.concat "" @@ add_slash file_path in
  let%lwt org_note =
    Ot_spinner.with_spinner
      (let%lwt title, _ = safe_get_title_outline_for_file_path file_path in
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
       let%lwt hls = get_processed_org_for_path file_path in
       let%lwt nodes = get_roam_nodes file_path in
       let file_data_list, set_file_data =
         Eliom_shared.ReactiveData.RList.create [[title, hls, nodes, set_nodes]]
       in
       let set_filepath =
         [%client
           fun file_path ->
             let%lwt hls = get_processed_org_for_path file_path in
             let%lwt nodes = get_roam_nodes file_path in
             let%lwt title, _ =
               safe_get_title_outline_for_file_path file_path
             in
             Eliom_shared.ReactiveData.RList.set ~%set_file_data
               [[title, hls, nodes, ~%set_nodes]];
             Lwt.return_unit]
       in
       let backlinks_node = org_backlinks_content backlink_list set_filepath in
       let org_content = org_file_content file_data_list in
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
