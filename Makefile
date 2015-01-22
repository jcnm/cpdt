MODULES_NODOC := CpdtTactics MoreSpecif DepList
MODULES_PROSE := Intro
MODULES_CODE  := StackMachine InductiveTypes Predicates Coinductive Subset GeneralRec \
	MoreDep DataStruct Equality Generic Universes LogicProg Match Reflection \
	Large ProgLang
MODULES_DOC   := $(MODULES_PROSE) $(MODULES_CODE) Conclusion
MODULES       := $(MODULES_NODOC) $(MODULES_DOC)
VS            := $(MODULES:%=src/%.v)
TEX           := $(MODULES:%=latex/%.v.tex)
VS_DOC        := $(MODULES_DOC:%=%.v)
TEMPLATES     := $(MODULES_CODE:%=templates/%.v)

.PHONY: coq clean doc html templates install cpdt.tgz pdf

coq: Makefile.coq
	$(MAKE) -f Makefile.coq

Makefile.coq: Makefile $(VS)
	coq_makefile $(VS) \
		COQC = "coqc -I src" \
		COQDEP = "coqdep -I src" \
		-o Makefile.coq

clean:: Makefile.coq
	$(MAKE) -f Makefile.coq clean
	rm -f Makefile.coq .depend cpdt.tgz templates/*.v
	cd latex; rm -f *.sty *.log *.aux *.dvi *.v.tex *.toc *.bbl *.blg *.idx *.ilg *.pdf *.ind *.out

doc: latex/cpdt.pdf html

latex/%.v.tex: Makefile src/%.v src/%.glob
	cd src ; coqdoc --interpolate --latex --body-only -s \
		$*.v -o ../latex/$*.v.tex

latex/cpdt.pdf: latex/cpdt.tex $(TEX) latex/cpdt.bib
	cd latex ; pdflatex cpdt ; pdflatex cpdt ; bibtex cpdt ; makeindex cpdt ; pdflatex cpdt ; pdflatex cpdt

latex/%.pdf: latex/%.tex latex/cpdt.bib
	cd latex ; pdflatex $* ; pdflatex $* ; bibtex $* ; makeindex $* ; pdflatex $* ; pdflatex $*

html: Makefile $(VS) src/toc.html
	mkdir -p html
	cd src ; coqdoc --interpolate --no-externals $(VS_DOC) \
		-d ../html
	cp src/toc.html html/

templates: $(TEMPLATES)

templates/%.v: src/%.v tools/make_template.ml
	ocaml tools/make_template.ml <$< >$@

cpdt.tgz:
	hg archive -t tgz $@

install: cpdt.tgz latex/cpdt.pdf latex/exercises.pdf html
	cp cpdt.tgz staging/
	cp latex/cpdt.pdf staging/
	cp latex/exercises.pdf staging/ex/
	cp -R html staging/
	rsync -az --exclude '*~' staging/* chlipala.net:sites/chlipala/adam/cpdt/

pdf:
	evince latex/cpdt.pdf&

latex/exercises.pdf: Makefile src/Exercises.v
	coqc -I src src/Exercises
	coqdoc --latex -s src/Exercises.v -o latex/exercises.tex
	cd latex ; pdflatex exercises
