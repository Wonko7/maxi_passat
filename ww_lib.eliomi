[%%shared.start]

val ( let+ ) : 'a Lwt.t -> ('a -> 'b) -> 'b Lwt.t
val ( let* ) : 'a Lwt.t -> ('a -> 'b Lwt.t) -> 'b Lwt.t
val ( @: ) : 'a -> 'a list -> 'a list
val ( @$ ) : 'a -> 'a -> 'a list
val ( @? ) : 'a option -> 'a list -> 'a list
val ( @?$ ) : 'a option -> 'a -> 'a list
val ( @$? ) : 'a -> 'a option -> 'a list
val ( @?? ) : 'a option -> 'a option -> 'a list
