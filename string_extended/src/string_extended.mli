(** Extensions to [Core.Core_String]. *)

open! Core

(** [collate s1 s2] sorts string in an order that's usually more suited for human
    consumption by treating ints specially, e.g. it will output:
    [["rfc1.txt";"rfc822.txt";"rfc2086.txt"]].

    It works by splitting the strings in numerical and non-numerical chunks and comparing
    chunks two by two from left to right (and starting on a non numerical chunk):

    - Non_numerical chunks are compared using lexicographical ordering.
    - Numerical chunks are compared based on the values of the represented ints
      and the number of trailing zeros.

    It is a total order. *)
val collate : string -> string -> int


(**
   [unescaped_exn s] is the inverse operation of [escaped]: it takes a string where
   all the special characters are escaped following the lexical convention of
   OCaml and returns an unescaped copy.
   The [strict] switch is on by default and makes the function treat illegal
   backslashes as errors.
   When [strict] is [false] every illegal backslash except escaped numeral
   greater than [255] is copied literally. The aforementioned numerals still
   raise errors. This mimics the behaviour of the ocaml lexer.
*)
val unescaped_exn : ?strict:bool -> string -> string
[@@deprecated
  "[since 2021-08] Consider using [Scanf.unescaped] instead.  Be aware it behaves \
   differently on inputs containing double-quote characters."]


(** [squeeze str] reduces all sequences of spaces, newlines, tabs, and carriage
    returns to single spaces.
*)
val squeeze : string -> string

val line_break : len:int -> string -> string list
[@@deprecated "[since 2021-08] Use [word_wrap] instead."]

(**
   [word_wrap ~soft_limit s]

   Wraps the string so that it fits the length [soft_limit]. It doesn't break
   words unless we go over [hard_limit].

   if [nl] is passed it is inserted instead of the normal newline character.
*)
val word_wrap
  :  ?trailing_nl:bool
  -> ?soft_limit:int
  -> ?hard_limit:int
  -> ?nl:string
  -> string
  -> string

(** Gives the Levenshtein distance between 2 strings, which is the number of insertions,
    deletions, and substitutions necessary to turn either string into the other. With the
    [transpose] argument, it also considers transpositions (Damerau-Levenshtein
    distance). *)
val edit_distance : ?transpose:unit -> string -> string -> int
