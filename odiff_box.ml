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

(** Graphical user interface to display differences. *)

open Odiff

let get_n_first_ele max l =
  let rec iter n l =
    if n < max then
      match l with
        [] ->
          ([], [])
      | h :: q ->
          let (l1, l2) = iter (n+1) q in
          (h :: l1, l2)
    else
      ([], l)
  in
  iter 0 l

let first_of_index i =
  match i with
    One n
  | Many (n,_) -> n

let last_of_index i =
  match i with
    One n
  | Many (_,n) -> n

let range_of_index i =
  match i with
    One _ -> 1
  | Many (n1, n2) -> n2 - n1 + 1

let range_of_diff d =
  match d with
    Add (_,i,_) -> range_of_index i
  | Delete (i2,i,_)
  | Change (i2,_,i,_) -> (range_of_index i) + (range_of_index i2)

let first_of_diff d =
  match d with
    Add (i2,i,_) -> first_of_index i
  | Delete (i2,i,_)
  | Change (i2,_,i,_) ->
      (first_of_index i) - (range_of_index i2)

let last_of_diff d =
  match d with
    Add (_,i,_) -> last_of_index i
  | Delete (i2,i,_)
  | Change (i2,_,i,_) ->
      (last_of_index i) + (range_of_index i2)

let range_of_index2_of_diff d =
  match d with
    Add (i2,i,_) -> 0
  | Delete (i2,i,_)
  | Change (i2,_,i,_) -> (range_of_index i2)


(** This function takes a line number and list of differences and return
   the number of the first line of the previous diff before the given line number.
   The given list of differences is supposed to be sorted.
   @return None if the list is empty. If no difference is found before the given
   line number, then the last difference is used.*)
let find_prev line diffs =
  let rec iter acc_d acc_l = function
      [] -> None, 0
    | d :: q ->
	if (first_of_diff d) < line - acc_l then
	  (
	   prerr_endline (Printf.sprintf "first=%d line=%d acc_l=%d" (first_of_diff d) line acc_l);
	  let sup =
	    match  d with
	      Add (_,_,_) -> 0
	    | Delete (i2,i,_)
	    | Change (i2,_,i,_) -> (range_of_index i2)
	  in
	  match q with
	    [] -> (Some d, acc_l + sup)
	  | _ -> iter (Some d) (acc_l + sup) q
	  )
	else
	  acc_d, acc_l
  in
  let (diff_opt, decal) = iter None 0 diffs in
  match diff_opt with
    Some d -> Some ((first_of_diff d) + decal - 1)
  | None ->
      match List.rev diffs with
	h :: _ ->
	  let decal = List.fold_left
	      (fun acc -> fun d -> (range_of_index2_of_diff d) + acc)
	      0
	      diffs
	  in
	  Some ((first_of_diff h) + decal - (range_of_index2_of_diff h) -1 )
      | [] -> None


(** This function takes a line number and list of differences and return
   the number of the first line of the next diff after the given line number.
   The given list of differences is supposed to be sorted.
   @return None if the list is empty. If no difference is found after the given
   line number, then the first difference is used.*)
let find_next line diffs =
  match diffs with
    [] -> None
  | h :: q ->
      let rec iter acc_l = function
	  [] -> h, (range_of_index2_of_diff h)
	| d :: q ->
	    if (first_of_diff d) > line - acc_l then
	      d, acc_l + (range_of_index2_of_diff d)
	    else
	      let sup =
		match  d with
		  Add (_,_,_) -> 0
		| Delete (i2,i,_)
		| Change (i2,_,i,_) -> (range_of_index i2)
	      in
	      iter (acc_l + sup) q
      in
      let (diff, decal) = iter 0 diffs in
      Some ((first_of_diff diff) + decal - 1)


(** The window to display differences. *)
class string_window title string diffs =
  let window = GWindow.window ~kind: `TOPLEVEL
      ~width: 500
      ~height: 600
      ~title: title
      ()
  in
  let vbox = GPack.vbox ~packing: window#add () in
  (* the buttons *)
  let hbox = GPack.hbox ~packing: (vbox#pack ~expand: false ~padding: 3) () in
  let wb_close = GButton.button ~label: Odiff_messages.close
      ~packing: (hbox#pack ~expand: true) ()
  in
  let wb_next = GButton.button ~label: Odiff_messages.next_diff
      ~packing: (hbox#pack ~expand: true) ()
  in
  let wb_prev = GButton.button ~label: Odiff_messages.prev_diff
      ~packing: (hbox#pack ~expand: true) ()
  in

  (* the wlist *)
  let wscroll = GBin.scrolled_window ~packing: (vbox#pack ~expand: true) () in
  let wlist = GList.clist
      ~titles: ["Line" ; "Text"]
      ~titles_show: false
      ~selection_mode: `SINGLE
      ~packing: wscroll#add
      ()
  in
(*  let style = wlist#misc#style in
  let fixed_font = Gdk.Font.load_fontset "fixed" in
  let _ = style#set_font fixed_font in
*)
  object (self)
    (** The current position *)
    val mutable line = 0

    method window = window

    method insert_line ?line ?(fgcolor="Black") ?(bgcolor="White") s =
      let _ = wlist#append
	  [ (match line with None -> "" | Some n -> string_of_int n) ;
	    s
	  ]
      in
      let _ = wlist#set_row
	  ~foreground: (`NAME fgcolor)
	  ~background: (`NAME bgcolor)
(*	  ~style: style*)
          (wlist#rows -1)
      in
      ()

    method display =
      wlist#clear () ;
      wlist#freeze () ;
      let l = Str.split (Str.regexp "\n") string in
      let rec iter n lines diffs =
	match diffs with
	  [] ->
	    (
	     match lines with
	       [] ->
		 ()
	     | s :: q ->
		 self#insert_line ~line: n s ;
		 iter (n+1) q []
	    )
	| d :: q ->
	    match d with
	      Add (_,One i,_) ->
		let lines_before, lines_after =
		  get_n_first_ele (i-n) lines
		in
		iter n lines_before [] ;
		let lines_diff, remain =
		  get_n_first_ele 1 lines_after
		in
		(match lines_diff with
		  [s] -> self#insert_line ~line: i
		      ~fgcolor: "Orange"
		      ~bgcolor: "DarkSlateBlue"
		      s
		| _ -> ()
		);
		iter (i+1) remain q

	    | Add (_, Many(first, last), _) ->
		let n_lines_before = first - n in
		let lines_before, lines_after =
		  get_n_first_ele n_lines_before lines
		in
		(* print the lines before the diff *)
		iter n lines_before [] ;
		let n_lines_diff = last - first + 1 in
		let lines_diff, remain =
		  get_n_first_ele n_lines_diff lines_after
		in
		let next = List.fold_left
		    (fun line -> fun s ->
		      self#insert_line ~line: line
			~fgcolor: "Orange"
			~bgcolor: "DarkSlateBlue"
			s;
		      (line + 1)
		    )
		    first
		    lines_diff
		in
		iter next remain q

	    | Delete (_, i2, s) ->
		let lines_before, lines_after =
		  get_n_first_ele ((first_of_index i2) - n) lines
		in
		iter n lines_before [] ;
		List.iter
		  (fun s -> self#insert_line ~fgcolor: "White" ~bgcolor: "Grey" s)
		  (Str.split (Str.regexp "\n") s) ;
		iter (first_of_index i2) lines_after q

	    | Change(i1, s1, i2, s2) ->
		(* replace the Change by a Delete and a Add. *)
		let del = Delete (i1, One (first_of_index i2), s1) in
		let add = Add (One (first_of_index i1), i2, s2) in
		iter n lines (del :: add :: q)
      in
      iter 1 l diffs ;
      GToolbox.autosize_clist wlist ;
      wlist#thaw ()

    method show_next_diff =
      match find_next line diffs with
      |	None -> ()
      |	Some n ->
	  wlist#moveto n 0 ;
          wlist#select n 0 ;
	  line <- n + 1;

    method show_prev_diff =
      match find_prev line diffs with
      |	None -> ()
      |	Some n ->
	  wlist#moveto n 0 ;
          wlist#select n 0

    initializer
      let _ = wb_close#connect#clicked window#destroy in
      let _ = wb_next#connect#clicked (fun () -> self#show_next_diff) in
      let _ = wb_prev#connect#clicked (fun () -> self#show_prev_diff) in

      let f_select ~row ~column ~event = line <- row in
      let f_unselect ~row ~column ~event = line <- row  in
      (* connect the select and deselect events *)
      let _ = wlist#connect#select_row f_select in
      let _ = wlist#connect#unselect_row f_unselect in

      self#display
  end

let window title file diffs =
  let string = Odiff_merge.string_of_file file in
  new string_window title string diffs
