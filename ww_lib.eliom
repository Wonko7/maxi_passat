[%%shared.start]
open%client Js_of_ocaml
open%client Js_of_ocaml_lwt

open Eliom_content.Html
open Eliom_content.Html.F

let ( let* ) x f = Lwt.bind x f
let ( let+ ) x f = Lwt.map f x
let ( @: ) x xs = x :: xs
let ( @$ ) x y = [x; y]
let ( @? ) x xs = match x with None -> xs | Some x -> x :: xs
let ( @?$ ) x y = x @? [y]
let ( @$? ) x y = x @: y @? []
let ( @?? ) x y = x @? y @? []

let reactive_input ?(a = []) ?input_r ?(value = "") ?validate () =
  let signal, set_signal =
    match input_r with Some r -> r | None -> Eliom_shared.React.S.create value
  in
  let e =
    F.input
      ~a:
        [ a_oninput
            [%client
              fun ev ->
                let t = Js.Opt.get ev##.target (fun () -> raise Not_found) in
                let v = Js.Unsafe.coerce t in
                ~%set_signal @@ Js.to_string @@ v##.value] ]
      ()
  in
  e, (signal, set_signal)
