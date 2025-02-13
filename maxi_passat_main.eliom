(** This is the main file if you are using static linking without config file.
    It is not used if you are using a config file and ocsigenserver *)

module%shared Maxi_passat = Maxi_passat

let%server _ =
  Ocsigen_server.start
    [ Ocsigen_server.host
        [Staticmod.run ~dir:"local/var/www/maxi_passat" (); Eliom.run ()] ]
