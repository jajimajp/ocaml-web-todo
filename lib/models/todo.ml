(* module `Q` contains our query definitions *)
module Q = struct
  open Caqti_request.Infix

  let list =
    Caqti_type.(unit ->* t3 int string bool)
    "SELECT id, title, completed FROM todos"
end

let list (conn : Caqti_eio.connection) =
  let module Conn = (val conn : Caqti_eio.CONNECTION) in
  Conn.collect_list Q.list ()