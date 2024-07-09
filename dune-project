(lang dune 3.16)

(name ocaml_web_todo)

(generate_opam_files true)

(source
 (github jajimajp/ocaml-web-todo))

(authors "Yajima Soichi")

(maintainers "Yajima Soichi")

(license MIT)

(documentation https://github.com/jajimajp/ocaml-web-todo)

(package
 (name ocaml_web_todo)
 (synopsis "Todo app with ocaml http backend")
 (description "Todo app with ocaml http backend")
 (depends ocaml dune))
