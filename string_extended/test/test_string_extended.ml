open! Core
open Expect_test_helpers_core

let%test_module "collate" =
  (module struct
    let collate = String_extended.collate
    let ( <! ) s s' = collate s s' < 0
    let%test _ = "a2b" <! "a10b"
    let%test _ = "a2b" <! "a02b"
    let%test _ = "a010b" <! "a20b"

    (* https://en.wikipedia.org/wiki/Total_order *)
    let%test_module "collate is a strict total order" =
      (module struct
        let%expect_test "collate is irreflexive" =
          quickcheck_m
            [%here]
            (module String)
            ~f:(fun s -> require [%here] (not (s <! s)))
        ;;

        let%expect_test "collate is transitive" =
          quickcheck_m
            [%here]
            (module struct
              type t = string * string * string [@@deriving quickcheck, sexp_of]
            end)
            ~f:(fun (a, b, c) -> require [%here] ((a <! b && b <! c) ==> (a <! c)))
        ;;

        let%expect_test "collate is connected" =
          quickcheck_m
            [%here]
            (module struct
              type t = string * string [@@deriving quickcheck, sexp_of]
            end)
            ~f:(fun (a, b) -> require [%here] (String.( <> ) a b ==> (a <! b || b <! a)))
        ;;
      end)
    ;;
  end)
;;

let%test_module "edit_distance" =
  (module struct
    let edit_distance = String_extended.edit_distance
    let%test _ = edit_distance "" "" = 0
    let%test _ = edit_distance "stringStringString" "stringStringString" = 0
    let%test _ = edit_distance "ocaml" "coaml" = 2
    let%test _ = edit_distance ~transpose:() "ocaml" "coaml" = 1
    let%test _ = edit_distance "sitting" "kitten" = 3
    let%test _ = edit_distance ~transpose:() "sitting" "kitten" = 3
    let%test _ = edit_distance "abcdef" "1234567890" = 10
    let%test _ = edit_distance "foobar" "fubahr" = 3
    let%test _ = edit_distance "hylomorphism" "zylomorphism" = 1
  end)
;;

let%test_module "unescaped_exn" =
  (module struct
    let unescaped_exn = (String_extended.unescaped_exn [@alert "-deprecated"])

    let require_unescape_roundtrips_with_string_escape s =
      require_equal [%here] (module String) (unescaped_exn (String.escaped s)) s
    ;;

    let%expect_test "unescaped_exn" =
      quickcheck_m
        [%here]
        (module String)
        ~examples:[ "" ]
        ~f:require_unescape_roundtrips_with_string_escape;
      (* hex escape *)
      require_equal [%here] (module String) (unescaped_exn "\\xff") "\xff";
      (* strict, illegal escape *)
      require_does_raise [%here] (fun () -> unescaped_exn "\\a");
      [%expect
        {|
        (Invalid_argument
         "String_extended.unescaped_exn error at position 2 of \\a: got invalid escape character: a") |}];
      (* non-strict *)
      require_equal
        [%here]
        (module String)
        ~message:"non-strict"
        (unescaped_exn ~strict:false "\\a")
        "\\a";
      (* non-strict, illegal escape  *)
      require_does_raise [%here] (fun () -> unescaped_exn ~strict:false "\\512");
      [%expect
        {|
        (Invalid_argument
         "String_extended.unescaped_exn error at position 4 of \\512: got invalid escape code 512") |}]
    ;;

    let%expect_test "[unescaped_exn ~strict:true] is equivalent to [Scanf.unescaped], \
                     modulo exception constructor"
      =
      Quickcheck.test_can_generate
        String.quickcheck_generator
        ~sexp_of:[%sexp_of: string]
        ~f:(fun s -> Exn.does_raise (fun () -> unescaped_exn ~strict:true s));
      quickcheck_m
        [%here]
        (module String)
        ~f:(fun s ->
          let s =
            unstage (String.Escaping.escape ~escapeworthy:[ '\"' ] ~escape_char:'\\') s
          in
          Expect_test_helpers_core.require_equal
            [%here]
            (module struct
              type t = (string, (exn[@equal.ignore])) Result.t [@@deriving equal, sexp_of]
            end)
            (Result.try_with (fun () -> unescaped_exn s ~strict:true))
            (Result.try_with (fun () -> Scanf.unescaped s)))
    ;;
  end)
;;
