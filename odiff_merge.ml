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

(** Assisting the user to resolve merge conlicts. *)


type t =
    No_conflict of string
  | Conflict of (string * string)


let arrow = [|
"21 21 4 1";
"       c None";
".      c #FFFFFF";
"+      c #000000";
"@      c #0000FF";
"                     ";
"                     ";
"                     ";
"    .............    ";
"    +@@@@@@@@@@@.    ";
"     +@@@@@@@@@.     ";
"     +@@@@@@@@@.     ";
"      +@@@@@@@.      ";
"      +@@@@@@@.      ";
"       +@@@@@.       ";
"       +@@@@@.       ";
"        +@@@.        ";
"        +@@@.        ";
"         +@.         ";
"         +@.         ";
"          +          ";
"          +          ";
"                     ";
"                     ";
"                     ";
"                     "|]

let arrow_pix () =
  let gdk_pix = GDraw.pixmap_from_xpm_d ~data: arrow
      ~colormap: (Gdk.Color.get_system_colormap ())
      ()
  in
  let pix = GMisc.pixmap gdk_pix () in
  pix


(*c==v=[File.string_of_file]=1.0====*)
let string_of_file name =
  let chanin = open_in_bin name in
  let len = 1024 in
  let s = String.create len in
  let buf = Buffer.create len in
  let rec iter () =
    try
      let n = input chanin s 0 len in
      if n = 0 then
        ()
      else
        (
         Buffer.add_substring buf s 0 n;
         iter ()
        )
    with
      End_of_file -> ()
  in
  iter ();
  close_in chanin;
  Buffer.contents buf
(*/c==v=[File.string_of_file]=1.0====*)

let build_info filename =
  let file = string_of_file filename in
  let mark_start = "<<<<<<< "^(Filename.basename filename)^"\n" in
  let len_mark_start = String.length mark_start in
  let start_re = Str.regexp_string mark_start in
  let mark_end = ">>>>>>> [0-9]+\\(\\.[0-9]+\\)*\n" in
  let end_re = Str.regexp mark_end in
  let mark_middle = "=======\n" in
  let len_mark_middle = String.length mark_middle in
  let middle_re = Str.regexp_string mark_middle in
  let info = ref ([] : t list) in
  let rec iter pos =
    try
      let conf_start = Str.search_forward start_re file pos in
      let s = String.sub file pos (conf_start - pos) in
      info := (No_conflict s) :: !info ;
      try
	let conf_end = Str.search_forward end_re file conf_start in
	let matched = Str.matched_string file in
	let len_mark_end = String.length matched in
	let new_pos = conf_end + len_mark_end in
	try
	  let conf_middle = Str.search_forward middle_re file conf_start in
	  let s1 = String.sub file
	      (conf_start + len_mark_start)
	      (conf_middle - conf_start - len_mark_start)
	  in
	  let s2 = String.sub file
	      (conf_middle + len_mark_middle)
	      (conf_end - conf_middle - len_mark_middle)
	  in
	  info := (Conflict (s1, s2)) :: !info;
	  iter new_pos
	with
	  Not_found ->
	  prerr_endline (mark_middle^" not found in "^
			 (String.sub file conf_start ((String.length file) - pos - conf_start)));
	  raise (Failure "Conflict without middle.")
      with
	Not_found ->
	  prerr_endline (mark_end^" not found in "^
			 (String.sub file conf_start ((String.length file) - pos -conf_start)));
	  raise (Failure "Conflict not ended.")
    with
      Not_found ->
	(* no more conflict *)
	let s = String.sub file pos ((String.length file) - pos) in
	let i = No_conflict s in
	info := i :: !info
  in
  iter 0;
  List.rev !info



class window ~title ~file info =
  let window = GWindow.window ~kind: `TOPLEVEL ~modal: true
      ~width: 500
      ~height: 600
      ~title: title
      ()
  in

  let vbox = GPack.vbox ~packing: window#add () in
  let wnote = GPack.notebook ~packing: (vbox#pack ~expand: true) () in


  let vbox_work = GPack.vbox () in
  let _  = wnote#append_page
      ~tab_label: (GMisc.label ~text: Odiff_messages.resolve ())#coerce
      vbox_work#coerce
  in

  let wscroll_1 = GBin.scrolled_window
      ~hpolicy: `AUTOMATIC ~vpolicy: `AUTOMATIC
      ()
  in
  let wview_1 = GText.view
      ~editable: false
      ~packing: wscroll_1#add ()
  in
  let _  = wnote#append_page
      ~tab_label: (GMisc.label ~text: Odiff_messages.result ())#coerce
      wscroll_1#coerce
  in

  let vpane = GPack.paned `VERTICAL ~packing: (vbox_work#pack ~expand: true) () in
  let hpane = GPack.paned `HORIZONTAL ~packing: (vpane#add1) () in
  let vbox1 = GPack.vbox ~packing: (hpane#add1) () in
  let wscroll1 = GBin.scrolled_window
      ~hpolicy: `AUTOMATIC ~vpolicy: `AUTOMATIC
      ~packing: (vbox1#pack ~expand: true) ()
  in
  let wlist1 = GList.clist
      ~titles: [file]
      ~titles_show: true
      ~selection_mode: `SINGLE
      ~packing: wscroll1#add
      ()
  in
  let _ = wlist1#misc#set_sensitive false in

  let vbox2 = GPack.vbox ~packing: (hpane#add2) () in
  let wscroll2 = GBin.scrolled_window
      ~hpolicy: `AUTOMATIC ~vpolicy: `AUTOMATIC
      ~packing: (vbox2#pack ~expand: true) ()
  in
  let wlist2 = GList.clist
      ~titles: [Odiff_messages.file_from_repository (Filename.basename file)]
      ~titles_show: true
      ~selection_mode: `SINGLE
      ~packing: wscroll2#add
      ()
  in
  let _ = wlist2#misc#set_sensitive false in

  let _ = vbox1#misc#set_size_request ~width: 250 ~height: 300 () in
  let _ = vbox2#misc#set_size_request ~width: 250 ~height: 300 () in


  let vbox_text = GPack.vbox ~packing: (vpane#add2) () in

  let wscroll = GBin.scrolled_window
      ~hpolicy: `AUTOMATIC ~vpolicy: `AUTOMATIC
      ~packing: (vbox_text#pack ~expand: true) () in
  let wview = GText.view
      ~editable: true
      ~packing: wscroll#add () in

  let wb_import_left = GButton.button
      ~packing: (vbox1#pack ~expand: false) ()
  in
  let _ = wb_import_left#add (arrow_pix ())#coerce in

  let wb_import_right = GButton.button
      ~packing: (vbox2#pack ~expand: false) ()
  in
  let _ = wb_import_right#add (arrow_pix ())#coerce in

  let wl_status = GMisc.label
      ~text: ""
      ~packing: (vbox_text#pack ~expand: false) ()
  in

  let hbox_buttons = GPack.hbox
      ~packing: (vbox_text#pack ~expand: false ~padding: 3) ()
  in
  let wb_validate = GButton.button ~label: Odiff_messages.validate
      ~packing: (hbox_buttons#pack ~expand: true) ()
  in
  let wb_skip = GButton.button ~label: Odiff_messages.skip
      ~packing: (hbox_buttons#pack ~expand: true) ()
  in

  let hbox_main_buttons = GPack.hbox
      ~packing: (vbox#pack ~expand: false ~padding: 3) ()
  in
  let wb_save = GButton.button ~label: Odiff_messages.save
      ~packing: (hbox_main_buttons#pack ~expand: true) ()
  in
  let wb_save_close = GButton.button ~label: Odiff_messages.save_and_close
      ~packing: (hbox_main_buttons#pack ~expand: true) ()
  in
  let wb_close = GButton.button ~label: Odiff_messages.close
      ~packing: (hbox_main_buttons#pack ~expand: true) ()
  in

  object (self)
    val colors = ("Blue" , "Red")

    val mutable remain = info
    val resolved = Buffer.create 15000
    val mutable current_conflict = (None : (string * string) option)

    val mutable lines1 = [] (* list of line numbers of the info element ;
			      pairs (pos, number of lines) *)
    val mutable lines2 = []

    method insert_string ?emph (wl : string GList.clist) s =
      let rec iter acc = function
	  [] -> acc
	| [""] when acc > 0 ->
            (* on ne met pas la dernière ligne vide après le dernier retour charriot *)
	    acc
	| s :: q ->
	    ignore (wl#append [s]) ;
	    (
	     match emph with
	       None -> ()
	     | Some f ->
		 ignore
		   (wl#set_row
		      ~foreground: (`NAME (f colors))
		      (wl#rows - 1)
		   )
	    );
	    iter (acc + 1) q
      in
      iter 0 (Str.split_delim (Str.regexp_string "\n") s)

    method update_wlists =
      wlist1#clear () ;
      wlist2#clear () ;
      let cpt1 = ref 0 in
      let cpt2 = ref 0 in
      List.iter
	(fun i -> match i with
	  No_conflict s ->
	    let n = self#insert_string wlist1 s in
	    ignore (self#insert_string wlist2 s);
	    lines1 <- (!cpt1, n) :: lines1;
	    lines2 <- (!cpt2, n) :: lines2;
	    cpt1 := !cpt1 + n;
	    cpt2 := !cpt2 + n

	| Conflict (s1, s2) ->
	    let n1  = self#insert_string ~emph: fst wlist1 s1 in
	    let n2 = self#insert_string ~emph: snd wlist2 s2 in
	    lines1 <- (!cpt1, n1) :: lines1;
	    lines2 <- (!cpt2, n2) :: lines2;
	    cpt1 := !cpt1 + n1;
	    cpt2 := !cpt2 + n2
	)
	info;
      lines1 <- List.rev lines1 ;
      lines2 <- List.rev lines2


    method grey_lines =
      let lremain = List.length remain in
      let linfo = List.length info in
      let n = linfo - lremain - 1 in
      (* n < 0 if lremain = linfo *)
      if n >= 0 then
	(
	 try
	   let (pos1, l1) = List.nth lines1 n in
	   let (pos2, l2) = List.nth lines2 n  in
	   for i = pos1 to (pos1 + l1 - 1) do
	     ignore (wlist1#set_row ~foreground: (`NAME "Grey") i)
	   done;
	   for i = pos2 to (pos2 + l2 - 1) do
	     ignore (wlist2#set_row ~foreground: (`NAME "Grey") i)
	   done
	 with
	   Invalid_argument s ->
	     prerr_endline s
	)

    method resolve_next =
      self#grey_lines ;
      match remain with
	[] -> ()
      |	(No_conflict s) :: q ->
	  Buffer.add_string resolved s ;
	  wview_1#buffer#insert s;
	  remain <- q;
	  self#resolve_next
      |	(Conflict (s1, s2)) :: q ->
	  current_conflict <- Some (s1, s2);
	  wb_validate#misc#set_sensitive true ;
	  wb_skip#misc#set_sensitive true ;
	  wview#set_editable true

    method remaining_conflicts =
      List.length
	(List.filter
	   (function Conflict _ -> true | _ -> false)
	   remain)

    method validate () =
      let s = wview#buffer#get_text () in
      match remain with
      |	[] -> ()
      |	Conflict _ :: q ->
	  Buffer.add_string resolved s ;
	  let tag = wview_1#buffer#create_tag [`FOREGROUND "DarkGreen"] in
	  wview_1#buffer#insert ~tags: [tag] s;
	  remain <- q ;
	  wview#buffer#set_text "";
	  current_conflict <- None;
	  wl_status#set_text
	    (Odiff_messages.conflicts_to_resolve self#remaining_conflicts);
	  wb_validate#misc#set_sensitive false ;
	  wb_skip#misc#set_sensitive false ;
	  wview#set_editable false ;
	  self#resolve_next
      |	_ :: q ->
	  ()

    method import f_which_one () =
      match current_conflict with
	None -> ()
      |	Some cpl ->
	  let tag = wview#buffer#create_tag [`FOREGROUND (f_which_one colors)] in
	  wview#buffer#insert ~tags: [tag] (f_which_one cpl);
	  wview#misc#grab_focus ()

    method string_of_conflict (s1, s2) =
      "<<<<<<< "^(Filename.basename file)^"\n"^
      s1^"=======\n"^
      s2^">>>>>>> 1.1\n"

    method skip () =
      match current_conflict, remain with
      |	Some _, ((Conflict cpl) :: q) ->
	  let s = self#string_of_conflict cpl in
	  Buffer.add_string resolved s;
	  let tag = wview_1#buffer#create_tag [`FOREGROUND "DarkGreen"] in
	  wview_1#buffer#insert ~tags: [tag] s;
	  remain <- q ;
	  wview#buffer#set_text "";
	  current_conflict <- None;
	  wl_status#set_text
	    (Odiff_messages.conflicts_to_resolve self#remaining_conflicts);
	  wb_validate#misc#set_sensitive false ;
	  wb_skip#misc#set_sensitive false ;
	  wview#set_editable false ;
	  self#resolve_next
      |	_ ->
	  ()

    method save () =
      try
	let oc = open_out file in
	output_string oc (Buffer.contents resolved) ;
	List.iter
	  (function
	      No_conflict s -> output_string oc s
	    | Conflict (s1, s2) -> output_string oc (self#string_of_conflict (s1, s2))
	  )
	  remain;
	close_out oc
      with
	Sys_error s ->
	  GToolbox.message_box Odiff_messages.error s

    method close = window#destroy
    method save_and_close () =
      self#save () ;
      self#close ()

    initializer
      ignore (wb_validate#connect#clicked self#validate);
      ignore (wb_skip#connect#clicked self#skip);
      ignore (wb_save#connect#clicked self#save);
      ignore (wb_save_close#connect#clicked self#save_and_close);
      ignore (wb_close#connect#clicked self#close);
      ignore (wb_import_left#connect#clicked (self#import fst));
      ignore (wb_import_right#connect#clicked (self#import snd));
      wl_status#set_text
	(Odiff_messages.conflicts_to_resolve self#remaining_conflicts);
      self#update_wlists;
      match remain with
	[]
      |	[No_conflict _]->
	  ignore (GToolbox.message_box
		    Odiff_messages.m_resolve_conflicts Odiff_messages.no_conflict);
	  window#destroy ()
      |	_ ->
	  window#show ();
	  ignore (window#connect#destroy GMain.Main.quit);
	  self#resolve_next;
	  GMain.Main.main ()


  end
