let log_warning exn =
  Printf.eprintf "Warning: %s\n%!" (Printexc.to_string exn)

let () =
  let port = ref 8080 in
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
    let conn = Caqti_eio_unix.connect
                  ~sw
                  ~stdenv:(env :> Caqti_eio.stdenv)
                  (Uri.of_string "sqlite3://:test") in
    let conn = match conn with
      | Ok conn -> conn
      | Error err -> failwith (Printf.sprintf "Error: %s" (Caqti_error.show err)) in
    let handler = Handlers.Handler.handler env conn in
    let rec loop () =
      let socket =
        Eio.Net.listen env#net ~sw ~backlog:128 ~reuse_addr:true
        (`Tcp (Eio.Net.Ipaddr.V4.loopback, !port))
      and server = Cohttp_eio.Server.make ~callback:handler () in
      Cohttp_eio.Server.run socket server ~on_error:log_warning
      loop () in
    loop ()
