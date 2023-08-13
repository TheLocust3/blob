open Lwt_result

open Common

exception Unauthorized

module Context = struct
  type t = {
    connection : Caqti_lwt.connection;
    user_id : string option;
  }
end

module Policy = struct
  open Model.Bucket.Policy

  module Context = struct
    type t = {
      connection : Caqti_lwt.connection;
      user_id : string option;
      bucket : Model.Bucket.t;
    }
  end

  let principal_matches (context : Context.t) principal = match principal with
    | Principal.All -> true
    | Principal.UserId principal ->
      (match context.user_id with
      | Some user_id -> principal == user_id
      | None -> false)

  let apply context for_action statement =
    let Statement.({ effect; action; principal }) = statement in
    (if principal_matches context principal && action == for_action then
      match effect with
      | (Effect.Deny) -> fail Unauthorized
      | (Effect.Allow) -> return ()
    else
      return ())

  let guard_for (context : Context.t) for_action =
    let { head; rest } = context.bucket.policy in
    let%lwt _ = apply context for_action head in
    let%lwt _ = Magic.Lwt.flatmap (apply context for_action) rest in
    return ()

  module Read = struct
    let guard context = guard_for context Action.Read
  end

  module List = struct
    let guard context = guard_for context Action.List
  end

  module Write = struct
    let guard context = guard_for context Action.Write
  end
end

module Blob = struct
  let get bucket key context =
    let _ = Dream.log "[Store.Blob.get] bucket: `%s` key: `%s`" bucket key in
    let Context.({ connection; _ }) = context in
    Database.Buckets.by_name bucket connection >>= fun bucket ->
      let _ = Dream.log "[Store.Blob.get] bucket: `%s` key: `%s` - found bucket" bucket.name key in
      let%lwt _ = Policy.Read.guard Policy.Context.({ connection = context.connection; user_id = context.user_id; bucket = bucket }) in
      let _ = Dream.log "[Store.Blob.get] bucket: `%s` key: `%s` - authorized" bucket.name key in
      Database.Blobs.by_key bucket.name key connection

  let list bucket prefix context =
    let _ = Dream.log "[Store.Blob.list] bucket: `%s` prefix: `%s`" bucket prefix in
    let Context.({ connection; _ }) = context in
    Database.Buckets.by_name bucket connection >>= fun bucket ->
      let _ = Dream.log "[Store.Blob.list] bucket: `%s` prefix: `%s` - found bucket" bucket.name prefix in
      let%lwt _ = Policy.List.guard Policy.Context.({ connection = context.connection; user_id = context.user_id; bucket = bucket }) in
      let _ = Dream.log "[Store.Blob.list] bucket: `%s` prefix: `%s` - authorized" bucket.name prefix in
      Database.Blobs.by_prefix bucket.name prefix connection

  let create (blob : Model.Blob.t) context =
    let _ = Dream.log "[Store.Blob.create] bucket: `%s` key: `%s`" blob.bucket blob.key in
    let Context.({ connection; _ }) = context in
    Database.Buckets.by_name blob.bucket connection >>= fun bucket ->
      let _ = Dream.log "[Store.Blob.create] bucket: `%s` key: `%s` - found bucket" blob.bucket blob.key in
      let%lwt _ = Policy.Write.guard Policy.Context.({ connection = context.connection; user_id = context.user_id; bucket = bucket }) in
      let _ = Dream.log "[Store.Blob.create] bucket: `%s` key: `%s` - authorized" blob.bucket blob.key in
      Database.Blobs.create blob connection

  let delete bucket key context =
    let _ = Dream.log "[Store.Blob.delete] bucket: `%s` key: `%s`" bucket key in
    let Context.({ connection; _ }) = context in
    Database.Buckets.by_name bucket connection >>= fun bucket ->
      let _ = Dream.log "[Store.Blob.delete] bucket: `%s` key: `%s` - found bucket" bucket.name key in
      let%lwt _ = Policy.Write.guard Policy.Context.({ connection = context.connection; user_id = context.user_id; bucket = bucket }) in
      let _ = Dream.log "[Store.Blob.delete] bucket: `%s` key: `%s` - authorized" bucket.name key in
      Database.Blobs.delete bucket.name key connection
end
