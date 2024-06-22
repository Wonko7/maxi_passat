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
  | Bleau_link of string * string
  | Yt_link of string * string
  | Https_link of string * string
  | Text of string

type processed_org =
  { headline_id : int32
  ; index : int32
  ; kind : string
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
  ; p_kind : string
  ; p_is_headline : bool
  ; p_content : string option
  ; p_link_dest : string option
  ; p_link_desc : string option
  ; p_file_path : string }
[@@deriving json, show]

let processed_kind_to_str = function
  | Br -> "br"
  | Text _ -> "txt"
  | Id_link _ -> "id_link"
  | File_link _ -> "file_link"
  | Yt_link _ -> "yt_link"
  | Bleau_link _ -> "bleau_link"
  | Https_link _ -> "https_link"
