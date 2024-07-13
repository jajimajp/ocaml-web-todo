open Yojson.Basic

let todos conn =
  match Models.Todo.list conn with
  | Error err -> Printf.sprintf "{ \"error\": \"%s\" }" (Caqti_error.show err)
  | Ok todos ->
    todos
    |> List.map (fun (id, title, completed) ->
      `Assoc [
        ("id", `Int id);
        ("title", `String title);
        ("completed", `Bool completed)
      ])
    |> fun l -> `List l
    |> to_string

let ( / ) = Eio.Path.( / )

let rec last_exn = function
| [] -> raise Not_found
| [x] -> x
| _ :: t -> last_exn t


let content_type (path: 'a Eio.Path.t) =
  let _, pathname = path in
  let ext = Str.split (Str.regexp "\\.") pathname |> last_exn in
  match ext with
  | "html" -> "text/html"
  | "css" -> "text/css"
  | "js" -> "application/javascript"
  | _ -> failwith "Not implemented"

let handler env conn =
  fun _socket request _body ->
    match Http.Request.resource request with
    | "/todos" -> Cohttp_eio.Server.respond_string ~status:`OK ~body:(todos conn) ()
    | _ -> (* serve static files *)
      if Http.Request.meth request <> `GET then
        Cohttp_eio.Server.respond_string ~status:`Method_not_allowed ~body:"405 Method Not Allowed" ()
      else
      begin
        let path =
          Http.Request.resource request
          |> String.split_on_char '/'
          |> List.filter (( <> ) "")
          |> String.concat "/"
        in
        let path = if path = "" then "index.html" else path in
        try
          let path = (Eio.Stdenv.cwd env) / "assets" / path in
          let body = Eio.Path.load path in
          Cohttp_eio.Server.(respond_string ()
            ~status:`OK
            ~headers:(Http.Header.of_list [ ("Content-Type", (content_type path)) ])
            ~body)
        with _ ->
          Cohttp_eio.Server.respond_string ~status:`Not_found ~body:"404 Not Found" ()
      end