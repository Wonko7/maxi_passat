(* This file was generated by Ocsigen Start.
   Feel free to use it, modify it, and redistribute it as you wish. *)

[%%shared.start]

val about_service
  : ( unit
    , unit
    , Eliom_service.get
    , Eliom_service.att
    , Eliom_service.non_co
    , Eliom_service.non_ext
    , Eliom_service.reg
    , [`WithoutSuffix]
    , unit
    , unit
    , Eliom_service.non_ocaml )
    Eliom_service.t

val upload_user_avatar_service : (unit, unit) Ot_picture_uploader.service

val settings_service
  : ( unit
    , unit
    , Eliom_service.get
    , Eliom_service.att
    , Eliom_service.non_co
    , Eliom_service.non_ext
    , Eliom_service.reg
    , [`WithoutSuffix]
    , unit
    , unit
    , Eliom_service.non_ocaml )
    Eliom_service.t

val demo_pgocaml
  : ( unit
    , unit
    , Eliom_service.get
    , Eliom_service.att
    , Eliom_service.non_co
    , Eliom_service.non_ext
    , Eliom_service.reg
    , [`WithoutSuffix]
    , unit
    , unit
    , Eliom_service.non_ocaml )
    Eliom_service.t

val os_github_service
  : ( unit
    , unit
    , Eliom_service.get
    , Eliom_service.att
    , Eliom_service.non_co
    , Eliom_service.ext
    , Eliom_service.non_reg
    , [`WithoutSuffix]
    , unit
    , unit
    , Eliom_service.non_ocaml )
    Eliom_service.t

val ocsigen_service
  : ( unit
    , unit
    , Eliom_service.get
    , Eliom_service.att
    , Eliom_service.non_co
    , Eliom_service.ext
    , Eliom_service.non_reg
    , [`WithoutSuffix]
    , unit
    , unit
    , Eliom_service.non_ocaml )
    Eliom_service.t
