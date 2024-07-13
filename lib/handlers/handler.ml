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

let add conn title =
  match Models.Todo.add conn title with
  | Error err -> Printf.sprintf "{ \"error\": \"%s\" }" (Caqti_error.show err)
  | Ok (id, title, completed) -> 
    Printf.sprintf
      "{ \"id\": %d, \"title\": \"%s\", \"completed\": %s }"
      id title (if completed then "true" else "false")
      
let update conn id title completed =
  match Models.Todo.update conn id title completed with
  | Error err -> Printf.sprintf "{ \"error\": \"%s\" }" (Caqti_error.show err)
  | Ok (id, title, completed) -> 
    Printf.sprintf
      "{ \"id\": %d, \"title\": \"%s\", \"completed\": %s }"
      id title (if completed then "true" else "false")

let delete conn id =
  match Models.Todo.delete conn id with
  | Error err -> Printf.sprintf "{ \"error\": \"%s\" }" (Caqti_error.show err)
  | Ok () -> "{ \"success\": true }"

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
    let resource = Http.Request.resource request in
    if Str.string_match (Str.regexp "^/todos/?\\(.*\\)$") resource 0 then
      let open Yojson.Basic.Util in
      let headers = (Http.Header.of_list [ ("Content-Type", "application/json") ]) in
      begin match Http.Request.meth request with
      | `GET -> Cohttp_eio.Server.respond_string ~headers ~status:`OK ~body:(todos conn) ()
      | `POST ->
        let body = Eio.Flow.read_all _body in
        let json = from_string body in
        let title = json |> member "title" |> to_string in
        Cohttp_eio.Server.respond_string ~headers ~status:`Created ~body:(add conn title) ()
      | `PUT ->
        let id = Str.matched_group 1 resource |> int_of_string in
        let body = Eio.Flow.read_all _body in
        let json = from_string body in
        let title = json |> member "title" |> to_string in
        let completed = json |> member "completed" |> to_bool in
        Cohttp_eio.Server.respond_string ~headers ~status:`OK ~body:(update conn id title completed) ()
      | `DELETE ->
        let id = Str.matched_group 1 resource |> int_of_string in
        Cohttp_eio.Server.respond_string ~headers ~status:`OK ~body:(delete conn id) ()
      | _ -> Cohttp_eio.Server.respond_string ~status:`Method_not_allowed ~body:"405 Method Not Allowed" ()
      end
    else (* serve static files *)
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