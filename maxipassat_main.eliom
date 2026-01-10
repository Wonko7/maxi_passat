(** This is the main file if you are using static linking without config file.
    It is not used if you are using a config file and ocsigenserver *)

module%shared Maxi_passat = Maxi_passat

let%server _ =
  let statdir =
    Maxi_passat_static_config.prodpath_or_fallback "var/www/maxi_passat/"
      "local/var/www/maxi_passat/"
  in
  Ocsigen_server.start
    ~ports:
      (match Sys.getenv_opt "PORT" with
      | Some p -> [`All, int_of_string p]
      | None -> [`All, 8080])
    ?logdir:(Sys.getenv_opt "LOGDIR")
    ?command_pipe:(Sys.getenv_opt "COMMAND_PIPE")
    [Ocsigen_server.host [Staticmod.run ~dir:statdir (); Eliom.run ()]]

let%shared workaround_tip () =
  (* why do I need this? without this generated JS is broken and fails with:
   * > Code generating the following client values is not linked on the client
   * [...]
   * > Code containing the following injections is not linked on the client *)
  Os_tips.bubble () ~name:"workaround" ~content:[%client fun _ -> Lwt.return []]
