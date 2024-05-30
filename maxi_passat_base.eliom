(* This file was generated by Ocsigen Start.
   Feel free to use it, modify it, and redistribute it as you wish. *)

let%server application_name = !Maxi_passat_config.app_name
let%client application_name = Eliom_client.get_application_name ()
let%shared displayed_app_name = "maxi_passat"

(* Database initialization *)
let () =
  Os_db.init ?host:!Maxi_passat_config.os_db_host ?port:!Maxi_passat_config.os_db_port
    ?user:!Maxi_passat_config.os_db_user
    ?password:!Maxi_passat_config.os_db_password
    ?database:!Maxi_passat_config.os_db_database
    ?unix_domain_socket_dir:!Maxi_passat_config.os_db_unix_domain_socket_dir
    ()

let () = Os_email.set_mailer "/usr/sbin/sendmail"
let () = Os_email.set_from_addr ("maxi_passat team", "noreply@DEFAULT.DEFAULT")

(* Create a module for the application. See
   https://ocsigen.org/eliom/manual/clientserver-applications for more
   information. *)
[%%shared
module App = Eliom_registration.App (struct
    let application_name = application_name
    let global_data_path = Some ["__global_data__"]
  end)]

(* As the headers (stylesheets, etc) won't change, we ask Eliom not to
   update the <head> of the page when changing page. (This also avoids
   blinking when changing page in iOS). *)
let%client _ = Eliom_client.persist_document_head ()
