[%%shared.start]

val ( let+ ) : 'a Lwt.t -> ('a -> 'b) -> 'b Lwt.t
val ( let* ) : 'a Lwt.t -> ('a -> 'b Lwt.t) -> 'b Lwt.t
val ( @: ) : 'a -> 'a list -> 'a list
val ( @$ ) : 'a -> 'a -> 'a list
val ( @? ) : 'a option -> 'a list -> 'a list
val ( @?$ ) : 'a option -> 'a -> 'a list
val ( @$? ) : 'a -> 'a option -> 'a list
val ( @?? ) : 'a option -> 'a option -> 'a list

val reactive_input
  :  ?a:[< Html_types.input_attrib] Eliom_content.Html.attrib list
  -> ?input_r:
       string Eliom_shared.React.S.t
       * (?step:React.step -> string -> unit) Eliom_shared.Value.t
  -> ?value:string
  -> ?validate:(string -> bool) Eliom_client_value.t
  -> unit
  -> [> `Input] Eliom_content.Html.elt
     * (string Eliom_shared.React.S.t
       * (?step:React.step -> string -> unit) Eliom_shared.Value.t)
