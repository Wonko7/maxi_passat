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

let make_collapsible ~id title content =
  (* https://www.digitalocean.com/community/tutorials/css-collapsible *)
  div ~a:[a_class ["header wrap-collapsible"; "indent-1"]]
  @@ [ input
         ~a:
           [ a_id id
           ; a_class ["toggle"]
           ; a_input_type `Checkbox
           ; a_checked ()
           ; a_tabindex 0 ]
         ()
     ; label ~a:[a_label_for id; a_class ["lbl-toggle"]] title
     ; div ~a:[a_class ["collapsible-content"]] content ]

let make_ptree_org_note ?headline_id title headlines nodes set_backlinks_id =
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
          ; p_link_dest = None } ]
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
  let processed_org_to_html kind content link_dest link_desc =
    let link_dest = Option.value ~default:"" link_dest in
    let link_desc = Option.value ~default:"" link_desc in
    let content = Option.value ~default:"" content in
    match kind with
    | "file_link" ->
        a ~service:Maxi_passat_services.org_file [txt link_desc]
        @@ String.split_on_char '\n' link_dest
    | "id_link" ->
        a ~service:Maxi_passat_services.org_id [txt link_desc] @@ link_dest
    | "bleau_link" ->
        a ~service:Maxi_passat_services.os_bleau_service
          ~a:
            [ a_target "_blank"
            ; a_rel [`Other "noopener"; `Nofollow]
            ; a_class ["external_link"] ]
          [txt "bleau.info : "; txt link_desc]
        @@ String.split_on_char '/' link_dest
    | "yt_link" ->
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
    | "txt" -> txt content
    | "br" -> br ()
    | _ -> span []
  in
  (* predicate_process, shortened for code golf reasons *)
  let pproc p = function
    | h when p h ->
        Some
          (processed_org_to_html h.p_kind h.p_content h.p_link_dest
             h.p_link_desc)
    | _ -> None
  in
  let hl_to_html hls children =
    let title = List.filter_map (pproc (fun h -> h.p_is_headline)) hls in
    let content = List.filter_map (pproc (fun h -> not h.p_is_headline)) hls in
    let f = List.hd hls in
    let backlinks =
      List.assoc_opt f.p_headline_id nodes
      |> Option.map (fun node_id ->
             span
               ~a:[a_onclick [%client fun _ -> ~%set_backlinks_id ~%node_id]]
               [txt node_id])
    in
    Lwt.return
    @@ make_collapsible
         ~id:(string_of_int @@ Int32.to_int f.p_headline_id)
         title
         [ div ~a:[a_class ["backlinks"]] (backlinks @? [])
         ; div ~a:[a_class ["content"]] (content @ children) ]
  in
  Org.map_ptree_to_html hl_to_html tree

let backlinks
    (backlinks_node : string Eliom_content.Html.F.wrap Eliom_shared.React.S.t)
    : Html_types.div_content Eliom_content.Html.R.elt
  =
  R.node
  @@ Eliom_shared.React.S.map
       [%shared
         fun roam_id ->
           let aclass = ["backlinks"] in
           match roam_id with
           | "" -> div ~a:[a_class ("invisible" :: aclass)] []
           | roam_id -> div ~a:[a_class aclass] [txt roam_id]]
       backlinks_node

let rec add_slash = function
  | a :: b :: l -> a :: "/" :: add_slash (b :: l)
  | a :: [] -> [a]
  | [] -> []

let file_page file_path () =
  let file_path = String.concat "" @@ add_slash file_path in
  let%lwt org_note =
    Ot_spinner.with_spinner
      (let%lwt title, outline_hash =
         match%lwt get_title_outline_for_file_path file_path with
         | Some r -> Lwt.return r
         | None -> failwith file_path
       in
       let backlinks_node, set_backlinks_id = Eliom_shared.React.S.create "" in
       let backlinks_node = backlinks backlinks_node in
       let%lwt hls = get_processed_org_for_path file_path in
       let%lwt nodes = get_roam_nodes file_path in
       let%lwt hls = make_ptree_org_note title hls nodes set_backlinks_id in
       Lwt.return [div [hls]; div [backlinks_node]])
  in
  (* a title would be nice: h1 [%i18n Demo.pgocaml]; *)
  Lwt.return [org_note]

let id_page roam_id () =
  let%lwt org_note =
    Ot_spinner.with_spinner
      (let%lwt hls = get_processed_org_for_id roam_id in
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
       let%lwt nodes = get_roam_nodes file_path in
       (* let%lwt hls = make_ptree_org_note ~headline_id "roam node:" hls nodes in *)
       (* Lwt.return @@ [div [title]; div [hls]]) *)
       Lwt.return @@ [div [title]; div []])
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
