(*********************************************************************************)
(*                OCamldiff                                                      *)
(*                                                                               *)
(*    Copyright (C) 2004-2012 Institut National de Recherche en Informatique     *)
(*    et en Automatique. All rights reserved.                                    *)
(*                                                                               *)
(*    This program is free software; you can redistribute it and/or modify       *)
(*    it under the terms of the GNU Lesser General Public License version        *)
(*    3 as published by the Free Software Foundation.                            *)
(*                                                                               *)
(*    This program is distributed in the hope that it will be useful,            *)
(*    but WITHOUT ANY WARRANTY; without even the implied warranty of             *)
(*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *)
(*    GNU Library General Public License for more details.                       *)
(*                                                                               *)
(*    You should have received a copy of the GNU Lesser General Public           *)
(*    License along with this program; if not, write to the Free Software        *)
(*    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   *)
(*    02111-1307  USA                                                            *)
(*                                                                               *)
(*    Contact: Maxence.Guesdon@inria.fr                                          *)
(*                                                                               *)
(*                                                                               *)
(*********************************************************************************)

(* $Id$ *)

(** Gui do display and merge differences. *)

(** {2 Displaying diffs} *)

class type diffs_window =
  object
    method window : GWindow.window
    method file   : string
    method diffs  : Odiff.diff list
  end

(** The given file is the second file used in the comparison to compute diffs. *)
val diffs_window :
    title: string -> file: string ->
      Odiff.diff list -> diffs_window

class type string_diffs_window =
  object
    method window : GWindow.window
    method string : string
    method diffs  : Odiff.diff list
  end

(** The given string is the second string used in the comparison to compute diffs. *)
val string_diffs_window :
    title: string -> string: string ->
      Odiff.diff list -> string_diffs_window

(** {2 Merging diffs} *)

type merge_info =
    No_conflict of string
        (** No conflits for this part of the given text *)

  | Conflict of (string * string)
        (** Conflict found in the given file: the two alternatives
           are in parameter *)

(** [build_merge_info file] returns the list of merge info
   by analyzing the contents of the given file.
   It returns a list of [merge_info], which represents the
   parts of the file which have conflits or not. *)
val build_merge_info : string -> merge_info list

val manual_merge_window :
    title: string -> file: string -> merge_info list -> unit
