[%%shared.start]

type headline =
  { headline_id : int32
  ; headline_text : string
  ; level : int32 option
  ; headline_index : int32 option
  ; parent_id : int32
  ; content : string option }
[@@deriving json, show]

(* might add dates to this *)
type processed_kind =
  | Br
  | File_link of string * string
  | Id_link of string * string
  | Text of string

type processed_org =
  { headline_id : int32
  ; index : int32
  ; kind : int32
  ; outline_hash : string
  ; is_headline : bool
  ; content : string option
  ; link_dest : string option
  ; link_desc : string option }
[@@deriving json, show]

type processed_org_headline =
  { p_headline_id : int32
  ; p_index : int32
  ; p_level : int32 option
  ; p_headline_index : int32 option
  ; p_parent_id : int32
  ; p_kind : int32
  ; p_is_headline : bool
  ; p_content : string option
  ; p_link_dest : string option
  ; p_link_desc : string option }
[@@deriving json, show]

let processed_kind_to_int32 = function
  | File_link _ -> 0l
  | Id_link _ -> 1l
  | Text _ -> 2l
  | Br -> 3l
