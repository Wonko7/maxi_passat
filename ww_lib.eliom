[%%shared.start]
open%client Js_of_ocaml

(* open%client Js_of_ocaml_lwt *)

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

let reactive_input ?(a = []) ?input_r ?output_r ?(value = "") ?validate () =
  let in_signal, set_in_signal =
    match input_r with Some r -> r | None -> Eliom_shared.React.S.create value
  in
  let out_signal, set_out_signal =
    match output_r with Some r -> r | None -> Eliom_shared.React.S.create ""
  in
  let e =
    D.Raw.input
      ~a:
        ([ a_value value
         ; a_oninput
             [%client
               fun ev ->
                 let t = Js.Opt.get ev##.target (fun () -> raise Not_found) in
                 let v = Js.Unsafe.coerce t in
                 ~%set_out_signal @@ Js.to_string @@ v##.value] ]
        @ a)
      ()
  in
  let e' =
    [%client
      (To_dom.of_element ~%e : Js_of_ocaml.Dom_html.element Js_of_ocaml__.Js.t)]
  in
  let e_with_value =
    [%client
      (match Dom_html.tagged ~%e' with
       | Dom_html.Input e -> (e :> < value : Js.js_string Js.t Js.prop > Js.t)
       | Dom_html.Textarea e ->
           (e :> < value : Js.js_string Js.t Js.prop > Js.t)
       | _ -> assert false
        : < value :
              Js_of_ocaml__.Js.js_string Js_of_ocaml__.Js.t
              Js_of_ocaml__.Js.prop >
          Js_of_ocaml__.Js.t)]
  in
  let fuckme_node = span [] in
  let _ =
    [%client
      (Eliom_lib.Dom_reference.retain
         (To_dom.of_element ~%fuckme_node)
         ~keep:
           (React.S.map
              (fun s ->
                print_endline "yes I will do something";
                print_endline s;
                print_endline @@ Js.to_string ~%e_with_value##.value;
                if String.length s >= 7 && String.sub s 0 7 = "__None_"
                then (
                  ~%e_with_value##.value := Js.string "";
                  ~%set_out_signal "")
                else if Js.to_string ~%e_with_value##.value <> s
                then ~%e_with_value##.value := Js.string s)
              ~%in_signal)
        : unit)]
  in
  span [e; fuckme_node], (in_signal, set_in_signal), (out_signal, set_out_signal)
