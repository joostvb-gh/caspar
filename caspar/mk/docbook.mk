# $Id: docbook.mk,v 1.2 2002-03-13 12:09:55 joostvb Exp $

#
#  Usage:
#
#   $ echo 'include caspar/mk/docbook.mk' > Makefile
#
#   $ vi karenina.dbx
#   $ make karenina.view
#   $ make karenina.print
#
#   $ vi svejk.tex
#   $ make svejk.view
#   $ make svejk.print
#
#   $ make clean
#
# read the source for more fancy stuff
#


# see also /usr/local/src/debian/maint-guide/maint-guide-1.0.2/Makefile
# for a debiandoc-sgml example.

XMLDCL ?= /usr/share/sgml/declaration/xml.dcl

# my jade looks in "caspar/print.dsl",
#  "/usr/local/share/sgml/caspar/print.dsl",
#  "/usr/local/lib/sgml/caspar/print.dsl",
#  "/usr/share/sgml/caspar/print.dsl"
# when i specify -d caspar/print.dsl
HTML_DSL ?= caspar/html.dsl
PRINT_DSL ?= caspar/print.dsl

# JADE = /usr/bin/jade
JADE ?= jade
# PDFJADETEX = /usr/bin/pdfjadetex
JADETEX ?= jadetex
LATEX ?= latex

W3M ?= w3m
DVIPS ?= dvips
PS2PDF ?= ps2pdf

PSNUP ?= psnup

LPR ?= lpr
GV ?= gv

XML2HTML_RULE = $(JADE) -t sgml -d $(HTML_DSL) $(XMLDCL) $<

# lynx doesn't deal well with too wide blurbs of <literallayout>  :(
HTML2TXT_RULE = $(W3M) -dump $< > $@

XML2JTEX_RULE = $(JADE) -t tex -d $(PRINT_DSL) -o $@ $(XMLDCL) $<

# run twice for toc processing
JTEX2DVI_RULE = $(JADETEX) $< && $(JADETEX) $< && $(JADETEX) $< && rm -f $*.log $*.out $*.aux

TEX2DVI_RULE = $(LATEX) $<

DVI2PS_RULE = $(DVIPS) -f < $< > $@
PS2PDF_RULE = $(PS2PDF) $< $@
PS22PS_RULE = $(PSNUP) -2 $< $@


%.jtex: %.dbx
	$(XML2JTEX_RULE)

%.dvi: %.jtex
	$(JTEX2DVI_RULE)

%.dvi: %.tex
	$(TEX2DVI_RULE)
# 	rm $*.log

%.ps: %.dvi
	$(DVI2PS_RULE)

%.pdf: %.ps
	$(PS2PDF_RULE)

%.html: %.dbx
	$(XML2HTML_RULE)

%.txt: %.html
	$(HTML2TXT_RULE)

%.2ps: %.ps
	$(PS22PS_RULE)

%.view: %.ps
	$(GV) $<

%.print: %.2ps
	$(LPR) $<

%.printbig: %.ps
	$(LPR) $<

clean:
	-rm *.aux *.log *.dvi

.PRECIOUS: %.ps

