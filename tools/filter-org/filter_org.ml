(**
 * pub_tags -> mark as public & is inheritable (for sub headers)
 * priv_tags -> mark as private & is inheritable (for sub headers)
 * pubh_tags -> mark only the header as public, non inheritable
 *              the file body is private by default.
 * TODO: take args for setting these to make it configurable in CI.
 **)

type org_line = Public | Private | Text
type org_file_headline = Public | Public_Header | Private | End

let pub_tags = [ "pub"; "public" ]
and pubh_tags = [ "pubh"; "public-header" ]
and priv_tags = [ "priv"; "private"; "is"; "innerspace"; "crypt" ]

let rx_headline = "^(?<stars>\\*+).*?(?<tags>:[A-Za-z0-9:_-]+:)?\\s*$"
and rx_file_tags = "^#\\+filetags:\\s*(?<tags>:[A-Za-z0-9:_-]+:)?\\s*$"

let extract_stars line =
  try
    let open Pcre in
    let rex = regexp ~flags:[ `UTF8 ] rx_headline in
    let s = exec ~rex line in
    let stars = get_named_substring rex "stars" s in
    String.length stars
  with _ -> 0

let extract_tags rx line =
  try
    let open Pcre in
    let rex = regexp ~flags:[ `UTF8 ] rx in
    let s = exec ~rex line in
    let tags = get_named_substring rex "tags" s in
    let ts = split ~rex:(regexp ~flags:[ `UTF8 ] ":") tags in
    List.filter (fun x -> x <> "") ts
  with _ -> []

let extract_file_tags = extract_tags rx_file_tags
and extract_headline_tags = extract_tags rx_headline

let set_intersection set tags = List.exists (fun t -> List.mem t tags) set

let parse_header state line =
  match (extract_file_tags line, extract_stars line) with
  | _, i when i > 0 -> End
  | ts, _ when set_intersection priv_tags ts -> Private
  | ts, _ when set_intersection pubh_tags ts -> Public_Header
  | ts, _ when set_intersection pub_tags ts -> Public
  | _ -> state

let rec read_header ifd state ls =
  try
    let l = input_line ifd in
    match parse_header state l with
    | End -> (state, List.rev ls, l)
    | s -> read_header ifd s (l :: ls)
  with End_of_file -> (state, List.rev ls, "")

let rec rm_higher_or_eq n = function
  | [] -> []
  | ((x, _) as e) :: l when x < n -> e :: rm_higher_or_eq n l
  | _ :: l -> rm_higher_or_eq n l

let rec find_highest_bounded acc b ll =
  match (ll, acc) with
  | [], _ -> acc
  | ((x, _) as e) :: l, (ax, _) when x < b && x >= ax ->
      find_highest_bounded e b l
  | _ :: l, _ -> find_highest_bounded acc b l

let _main =
  let input_file = Sys.argv.(1) and output_file = Sys.argv.(2) in
  let ifd = Stdlib.open_in input_file in
  let s, hl, lastline = read_header ifd Private [] in
  let init_ls_acc =
    match s with
    | Private ->
        Stdlib.close_in ifd;
        exit 0
    | Public -> (0, Public)
    | Public_Header -> (0, Private)
    | End ->
        print_endline "bug";
        Stdlib.close_in ifd;
        exit 2
  in
  FileUtil.mkdir ~parent:true @@ Filename.dirname output_file;
  print_endline output_file;
  let ofd = Stdlib.open_out output_file in
  let wr s =
    output_string ofd s;
    output_string ofd "\n"
  in
  let wr_if_pub state string = if state = Public then wr string in
  ignore @@ List.map wr hl;
  let rec extract_headline l levels_state level state =
    try
      let ll () = input_line ifd in
      let ts = extract_headline_tags l in
      let stars = extract_stars l in
      match (stars, ts) with
      | 0, _ when state = Private ->
          extract_headline (ll ()) levels_state level state
      | 0, _ when state = Public ->
          wr l;
          extract_headline (ll ()) levels_state level state
      | n, ts when set_intersection priv_tags ts ->
          extract_headline (ll ())
            ((n, Private) :: rm_higher_or_eq n levels_state)
            n Private
      | n, ts when set_intersection pub_tags ts ->
          wr l;
          extract_headline (ll ())
            ((n, Public) :: rm_higher_or_eq n levels_state)
            n Public
      | n, _ when n > level ->
          wr_if_pub state l;
          extract_headline (ll ()) ((n, state) :: levels_state) n state
      | n, _ (* when n <= level *) ->
          let _, state = find_highest_bounded init_ls_acc n levels_state in
          wr_if_pub state l;
          extract_headline (ll ())
            ((n, state) :: rm_higher_or_eq n levels_state)
            n state
    with End_of_file -> ()
  in
  let _, state = init_ls_acc in
  extract_headline lastline [ init_ls_acc ] 0 state;
  Stdlib.close_in ifd;
  Stdlib.close_out ofd;
  true
