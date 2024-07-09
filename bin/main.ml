let with_conn f ~stdenv =
  let uri = Uri.of_string "sqlite3://" in
  Caqti_eio_unix.with_connection uri ~stdenv f

(* module `Q` contains our query definitions *)
module Q = struct
  open Caqti_request.Infix

  let add =
    Caqti_type.(t2 int int ->! int)
    "SELECT ? + ?"
end

let add a b (conn : Caqti_eio.connection) =
  let module Conn = (val conn : Caqti_eio.CONNECTION) in
  Conn.find Q.add (a, b)

open Printf

type data = int

let main (env : Eio_unix.Stdenv.base) =
  let ( let* ) = Result.bind in
  let program : (data, 'err) result =
    with_conn ~stdenv:(env :> Caqti_eio.stdenv) @@ fun conn ->
      let* sum = add 1 2 conn in
      Ok sum in

  match program with
  | Error err -> failwith (sprintf "Error: %s" (Caqti_error.show err))
  | Ok sum -> printf "Sum: %d\n" sum

let () = Eio_main.run main