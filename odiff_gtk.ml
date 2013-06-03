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



class type diffs_window =
  object
    method window : GWindow.window
    method file   : string
    method diffs  : Odiff.diffs
  end

class type string_diffs_window =
  object
    method window : GWindow.window
    method string : string
    method diffs  : Odiff.diffs
  end

let diffs_window ~title ~file diffs =
  let x = Odiff_box.window title file diffs in
  object
    method window = x#window
    method file = file
    method diffs = diffs
  end

let string_diffs_window ~title ~string diffs =
  let x = new Odiff_box.string_window title string diffs in
  object
    method window = x#window
    method string = string
    method diffs = diffs
  end

type merge_info = Odiff_merge.t =
    No_conflict of string
  | Conflict of (string * string)

let build_merge_info = Odiff_merge.build_info

let manual_merge_window ~title ~file mi =
  ignore(new Odiff_merge.window ~title ~file mi)
