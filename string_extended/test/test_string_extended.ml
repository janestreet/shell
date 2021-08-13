open Core
open Poly
open Quickcheck_deprecated

let ( @? ) name bool = if not bool then print_s [%message name]

let dup gen () =
  let x = gen () in
  x, x
;;

let true_count l = List.fold l ~f:(fun acc v -> if v then acc + 1 else acc) ~init:0
let definitive_clause l = true_count l = 1

let unescaped_exn_test ~name s =
  name @? (String_extended.unescaped_exn (String.escaped s) = s)
;;

let%expect_test "[collate]" =
  let ( <! ) s s' = String_extended.collate s s' < 0
  and ( >! ) s s' = String_extended.collate s s' > 0 in
  let basic_tests (s, s') =
    "invertible" @? (s' <! s = (s >! s'));
    "total" @? definitive_clause [ s <! s'; s = s'; s >! s' ]
  in
  repeat 50 basic_tests (pg sg sg);
  repeat 2 basic_tests (dup sg);
  repeat
    50
    (fun (s, s', s'') ->
       let s1, s2, s3 =
         match List.sort ~compare:String_extended.collate [ s; s'; s'' ] with
         | [ s1; s2; s3 ] -> s1, s2, s3
         | _ -> assert false
       in
       "transitive" @? ((s1 <! s2 || s2 <! s3) = (s1 <! s3)))
    (tg sg sg sg)
;;

let%expect_test "unescaped_exn" =
  unescaped_exn_test ~name:"empty" "";
  repeat 50 (unescaped_exn_test ~name:"random") sg;
  "hex" @? (String_extended.unescaped_exn "\\xff" = "\xff");
  ("strict illegal escape"
   @?
   try
     ignore (String_extended.unescaped_exn "\\a");
     false
   with
   | Invalid_argument _ -> true);
  "non strict" @? (String_extended.unescaped_exn ~strict:false "\\a" = "\\a");
  "non-strict illegal escape"
  @?
  try
    ignore (String_extended.unescaped_exn ~strict:false "\\512");
    false
  with
  | Invalid_argument _ -> true
;;
