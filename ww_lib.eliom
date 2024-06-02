[%%shared
let ( let* ) x f = Lwt.bind x f
let ( let+ ) x f = Lwt.map f x
let ( @: ) x xs = x :: xs
let ( @$ ) x y = [x; y]
let ( @? ) x xs = match x with None -> xs | Some x -> x :: xs
let ( @?$ ) x y = x @? [y]
let ( @$? ) x y = x @: y @? []
let ( @?? ) x y = x @? y @? []]
