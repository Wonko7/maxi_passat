[%%shared
(* This file was generated by Ocsigen Start.
   Feel free to use it, modify it, and redistribute it as you wish. *)
(* PGOcaml demo *)
open Eliom_content.Html
open Eliom_content.Html.F]

let%rpc get_all_org_files () : string list Lwt.t = Org_db.get_all_org_files ()
[%%shared.start]

let%shared search_str r s =
  try
    ignore @@ Str.search_forward r s 0;
    true
  with Not_found -> false

let%shared search_files
    ?(onclick :
       (?target_hlid:int32 -> string -> unit Lwt.t) Eliom_client_value.t option)
    ()
  =
  let%lwt fs = get_all_org_files () in
  let res_s, set_results = Eliom_shared.React.S.create (0, []) in
  let in_s, set_in = Eliom_shared.React.S.create "" in
  let reset_search =
    [%client
      (fun () ->
         (* fixme: find a better workaround.
            this only works if the signal is new, if you repeat "" it
            does not work. if you repeat "None" it won't work either. *)
         ~%set_in @@ String.cat "__None_"
         @@ string_of_float ((new%js Js_of_ocaml.Js.date_now)##getTime /. 1000.)
        : unit -> unit)]
  in
  let a_search_keyboard_ui =
    [ a_onkeydown
        [%client
          let incr_sel i =
            let i', fs = React.S.value ~%res_s in
            let l = List.length fs in
            let i' = if i' > l then l - 1 else i' in
            let i' = if i' < 0 then 0 else i' in
            ~%set_results (i + i', fs)
          in
          let visit () =
            let i', fs = React.S.value ~%res_s in
            let target = List.nth fs i' in
            match ~%onclick with
            | None ->
                Js_of_ocaml.(
                  Dom_html.window##.location##assign
                    (Js.string @@ String.cat "/org/file/" target))
            | Some onclick ->
                ignore @@ onclick target;
                ~%reset_search ()
          in
          fun ev ->
            match ev##.keyCode with
            (* arrows order [37-40] = lurd *)
            | 38 -> incr_sel (-1)
            | 40 -> incr_sel 1
            | 13 -> visit ()
            | e -> ()] ]
  in
  let e, _, (out_s, set_out) =
    Ww_lib.reactive_input ~a:a_search_keyboard_ui ~input_r:(in_s, set_in) ()
  in
  let _ =
    (* react to new user input: search and filter results signal *)
    [%client
      (React.S.map
         (function
           | "" -> ~%set_results (0, [])
           | s ->
               let ws = String.split_on_char ' ' s in
               let rs = List.map Str.regexp_string ws in
               let fs =
                 List.filter
                   (fun file ->
                     List.fold_left
                       (fun acc r -> acc && search_str r file)
                       true rs)
                   ~%fs
               in
               ~%set_results (0, fs))
         ~%out_s
        : unit Eliom_shared.React.S.t)]
  in
  let result =
    (* react to results signal: make dom entries for each search result *)
    R.node
    @@ Eliom_shared.React.S.map ~eq:[%shared ( == )]
         [%shared
           let reset_search = ~%reset_search in
           fun (nb_selected, fs) ->
             ul
             @@ List.mapi
                  (fun i m ->
                    let selected_class =
                      if i = nb_selected then ["search_selected"] else []
                    in
                    li ~a:[a_class selected_class]
                    @@ [ (match ~%onclick with
                         | None ->
                             a ~service:Maxi_passat_services.org_file [txt m]
                             @@ String.split_on_char '/' m
                         | Some onclick ->
                             span
                               ~a:
                                 [ a_class ["link"]
                                 ; a_onclick
                                     [%client
                                       fun _ev ->
                                         ignore @@ ~%onclick ~%m;
                                         ~%reset_search ()] ]
                               [txt m]) ])
                  fs]
         res_s
  in
  Lwt.return @@ div [e; div ~a:[a_class ["search_results"]] [result]]
