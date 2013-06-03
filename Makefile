#################################################################################
#                OCamldiff                                                      #
#                                                                               #
#    Copyright (C) 2004-2012 Institut National de Recherche en Informatique     #
#    et en Automatique. All rights reserved.                                    #
#                                                                               #
#    This program is free software; you can redistribute it and/or modify       #
#    it under the terms of the GNU Lesser General Public License version        #
#    3 as published by the Free Software Foundation.                            #
#                                                                               #
#    This program is distributed in the hope that it will be useful,            #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of             #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
#    GNU Library General Public License for more details.                       #
#                                                                               #
#    You should have received a copy of the GNU Lesser General Public           #
#    License along with this program; if not, write to the Free Software        #
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   #
#    02111-1307  USA                                                            #
#                                                                               #
#    Contact: Maxence.Guesdon@inria.fr                                          #
#                                                                               #
#                                                                               #
#################################################################################

#
 # do not forget to update META
VERSION=1.0
PACKAGE=diff-gtk

PACKAGES=unix,diff,lablgtk2


OF_FLAGS=-package $(PACKAGES)
OCAMLFIND=ocamlfind
OCAMLLEX=ocamllex
OCAMLYACC=ocamlyacc
OCAML_COMPFLAGS= -annot
OCAMLC=$(OCAMLFIND) ocamlc $(OF_FLAGS) $(OCAML_COMPFLAGS)
OCAMLOPT=$(OCAMLFIND) ocamlopt $(OF_FLAGS) $(OCAML_COMFLAGS)
OCAMLDOC=$(OCAMLFIND) ocamldoc $(OF_FLAGS)
OCAMLDEP=ocamldep

all: byte opt
byte: odiff_gtk.cma
opt: odiff_gtk.cmxa odiff_gtk.cmxs

CMOFILES= \
	odiff_messages.cmo \
	odiff_merge.cmo \
	odiff_box.cmo \
	odiff_gtk.cmo

CMXFILES=$(CMOFILES:.cmo=.cmx)
CMIFILES=$(CMOFILES:.cmo=.cmi)

odiff_gtk.cma: $(CMIFILES) $(CMOFILES)
	$(OCAMLC) -o $@ -a $(CMOFILES)

odiff_gtk.cmxa: $(CMIFILES) $(CMXFILES)
	$(OCAMLOPT) -o $@ -a $(CMXFILES)

odiff_gtk.cmxs: $(CMIFILES) $(CMXFILES)
	$(OCAMLOPT) -shared -o $@ $(CMXFILES)

.PHONY: doc depend

doc: all
	mkdir -p html
	$(OCAMLDOC) -t OCamldiff-gtk -d html -html odiff_gtk.mli

webdoc: doc
	mkdir -p ../odiff-gtk-gh-pages/refdoc
	cp html/* ../odiff-gtk-gh-pages/refdoc/
	cp web/index.html web/style.css ../odiff-gtk-gh-pages/

.depend depend:
	$(OCAMLDEP) odiff*.ml odiff*.mli > .depend

# installation :
################
install: byte opt
	$(OCAMLFIND) install $(PACKAGE) META LICENSE \
	odiff_gtk.cmi odiff_gtk.cma odiff_gtk.cmxa odiff_gtk.a odiff_gtk.cmxs

uninstall:
	ocamlfind remove $(PACKAGE)

# archive :
###########
archive:
	git archive --prefix=odiff-gtk-$(VERSION)/ HEAD | gzip > ../odiff-gtk-gh-pages/odiff-gtk-$(VERSION).tar.gz

# Cleaning :
############
clean:
	rm -f *.cm* *.a *.annot *.o

# headers :
###########
HEADFILES=Makefile *.ml *.mli *.mly *.mll
.PHONY: headers noheaders
headers:
	headache -h header -c .headache_config $(HEADFILES)

noheaders:
	headache -r -c .headache_config $(HEADFILES)

# generic rules :
#################
.SUFFIXES: .mli .ml .cmi .cmo .cmx .mll .mly .sch .html .mail

%.cmi:%.mli
	$(OCAMLC) -c $<

%.cmo:%.ml
	$(OCAMLC) -c $<

%.cmi %.cmo:%.ml
	$(OCAMLC) -c $<

%.cmx %.o:%.ml
	$(OCAMLOPT) -c $<

%.mli %.ml: %.mly
	$(OCAMLYACC) $<

%.ml: %.mll
	$(OCAMLLEX) $<


include .depend

