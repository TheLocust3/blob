open! Base
open! Core

module Store = struct
  include Store
end

let run () =
  let _ = Random.self_init () in
    Dream.run ~interface: "0.0.0.0" ~port: (Sys.getenv "PORT" |> Option.value ~default: "8080" |> int_of_string)
    @@ Dream.logger
    @@ Dream.sql_pool ~size: 10 Database.Connect.url
    @@ Dream.router (Blobs.routes @ Common.Middleware.Cors.routes)