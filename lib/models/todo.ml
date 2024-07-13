(* module `Q` contains our query definitions *)
module Q = struct
  open Caqti_request.Infix

  let list =
    Caqti_type.(unit ->* t3 int string bool)
    "SELECT id, title, completed FROM todos"

  let add =
    Caqti_type.(string ->! t3 int string bool)
    "INSERT INTO todos (title, completed) VALUES (?, '0') RETURNING id, title, completed"

  let update =
    Caqti_type.(t3 string bool int ->! t3 int string bool)
    "UPDATE todos SET title = ?, completed = ? WHERE id = ? RETURNING id, title, completed"

  let delete =
    Caqti_type.(int ->. unit)
    "DELETE FROM todos WHERE id = ?"
end

let list (conn : Caqti_eio.connection) =
  let module Conn = (val conn : Caqti_eio.CONNECTION) in
  Conn.collect_list Q.list ()

let add (conn : Caqti_eio.connection) title =
  let module Conn = (val conn : Caqti_eio.CONNECTION) in
  Conn.find Q.add title

let update (conn : Caqti_eio.connection) id title completed =
  let module Conn = (val conn : Caqti_eio.CONNECTION) in
  Conn.find Q.update (title, completed, id)

let delete (conn : Caqti_eio.connection) id =
  let module Conn = (val conn : Caqti_eio.CONNECTION) in
  Conn.exec Q.delete id