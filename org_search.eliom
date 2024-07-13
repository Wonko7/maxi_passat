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
  (* let in_s, set_in = Eliom_shared.React.S.create "" in *)
  let e, (in_s, set_in), (out_s, set_out) =
    Ww_lib.reactive_input ()
    (* Ww_lib.reactive_input ~input_r:(in_s, set_in) () *)
  in
  let res_s, set_results = Eliom_shared.React.S.create [] in
  print_endline "created sigs & search elmt.";
  let reset_search =
    [%client
      (fun () ->
         print_endline "!!!!!!!!!!  reset";
         (* this only works if the signal is new, if you repeat "" it
            does not work. if you repeat "None" it won't work either. *)
         ~%set_in @@ String.cat "__None_"
         @@ string_of_float ((new%js Js_of_ocaml.Js.date_now)##getTime /. 1000.);
         print_endline "!!!!!!!!!!  reset to ''"
        : unit -> unit)]
  in
  let result =
    R.node
    @@ Eliom_shared.React.S.map ~eq:[%shared ( == )]
         [%shared
           let reset_search = ~%reset_search in
           fun fs ->
             print_endline "got new search results";
             ul
             @@ List.map
                  (fun m ->
                    li
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
  let _ =
    [%client
      ((*    ignore *)
       (* @@ React.S.map *)
       (*      (fun s -> *)
       (*        print_endline s; *)
       (*        print_endline "new input from ocsigen!") *)
       (*      ~%in_s; *)
       React.S.map
         (fun s ->
           print_endline s;
           print_endline "new input from user!";
           (* function *)
           match s with
           | "" -> ~%set_results []
           | s ->
               let r = Str.regexp_string s in
               let fs = List.filter (search_str r) ~%fs in
               ~%set_results fs)
         ~%out_s
        : unit Eliom_shared.React.S.t)]
  in
  (* let _ = *)
  (*   [%client *)
  (*     (React.S.map *)
  (*        (fun s -> *)
  (*          print_endline s; *)
  (*          print_endline "new input from ocsigen!") *)
  (*        ~%in_s *)
  (*       : unit Eliom_shared.React.S.t)] *)
  (* in *)
  Lwt.return @@ div [e; div ~a:[a_class ["search_results"]] [result]]
