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

(** Messagse for Odiff gui. *)

let error = "Error"
let close = "Close"
let next_diff = "Next diff"
let prev_diff = "Previous diff"
let result = "Result"
let resolve = "Resolve"
let no_conflict = "No conflict."
let validate = "Validate"
let save = "Save"
let save_and_close = "Save and close"
let conflicts_to_resolve n = (string_of_int n)^" conflict(s) to resolve"
let skip = "Skip"
let no_diff_to_display = "No differences to display."
let file_from_repository f = f^" (from repository)"
let import_left = "Left"
let import_right = "Right"
let m_resolve_conflicts = "Resolve merge conflicts"
