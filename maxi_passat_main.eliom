(** This is the main file if you are using static linking without config file.
    It is not used if you are using a config file and ocsigenserver *)

module%shared Maxi_passat = Maxi_passat

let%server _ =
  Ocsigen_server.start
    ~ports:
      (match Sys.getenv_opt "PORT" with
      | Some p -> [`All, int_of_string p]
      | None -> [`All, 8080])
    ?logdir:(Sys.getenv_opt "LOGDIR")
    ?command_pipe:(Sys.getenv_opt "COMMAND_PIPE")
    [ Ocsigen_server.host
        [Staticmod.run ~dir:"local/var/www/maxi_passat" (); Eliom.run ()] ]
