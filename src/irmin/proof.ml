(*
 * Copyright (c) 2013-2021 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

type 'a inode = { length : int; proofs : (int * 'a) list } [@@deriving irmin]

type ('hash, 'step, 'metadata) t =
  | Blinded_node of 'hash
  | Blinded_contents of 'hash * 'metadata
  | Node of ('step * ('hash, 'step, 'metadata) t) list
  | Inode of ('hash, 'step, 'metadata) t inode

(* TODO(craigfe): fix [ppx_irmin] for inline parameters. *)
let t hash_t step_t metadata_t =
  let open Type in
  mu (fun t ->
      variant "proof" (fun blinded_node node inode blinded_contents -> function
        | Blinded_node x1 -> blinded_node x1
        | Node x1 -> node x1
        | Inode i -> inode i
        | Blinded_contents (x1, x2) -> blinded_contents (x1, x2))
      |~ case1 "Blinded_node" hash_t (fun x1 -> Blinded_node x1)
      |~ case1 "Node" [%typ: (step * t) list] (fun x1 -> Node x1)
      |~ case1 "Inode" [%typ: t inode] (fun i -> Inode i)
      |~ case1 "Blinded_contents" [%typ: hash * metadata] (fun (x1, x2) ->
             Blinded_contents (x1, x2))
      |> Type.sealv)

exception Bad_proof of { context : string }

let bad_proof_exn context = raise (Bad_proof { context })