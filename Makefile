.POSIX:

DESTDIR =
PREFIX  = /usr
BINDIR  = /bin
MANDIR  = /share/man
INSTALL = install
CFLAGS  = -Wall -O2
CC      = gcc


## Pseudo targets

all: owl documentation
owl: bin/ol
documentation: owl doc/ol.1.gz doc/ovm.1.gz # manual.md


### Lisp boostrap

## virtual machine

bin/vm: c/vm.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $?

c/_vm.c: c/ovm.c
	# remove comments and most white-space
	#sed -f bin/compact.sed $? >$@
	cp c/ovm.c c/_vm.c

c/vm.c: c/_vm.c
	echo 'static void *heap = 0;' | cat - $? >$@

## bytecode image (fixedpoint)

fasl/boot.fasl: fasl/init.fasl
	# start bootstrapping with the bundled init.fasl image
	make bin/vm
	bin/vm fasl/init.fasl -r bin/fasl-build.scm bin/vm fasl/init.fasl -r owl/ol.scm -o $@

fasl/ol.fasl: fasl/boot.fasl owl/*.scm owl/*/*.scm scheme/*.scm tests/*.scm tests/*.sh
	# selfcompile boot.fasl until a fixed point is reached
	make bin/vm
	bin/vm fasl/init.fasl -r bin/fasl-build.scm -f bin/vm fasl/boot.fasl -r owl/ol.scm -o fasl/bootp.fasl

## binary image

c/ol.c: fasl/ol.fasl
	# compile the repl using the fixed point image
	bin/vm fasl/ol.fasl --run owl/ol.scm -s some -o $@

bin/ol: c/ol.c
	# compile the real owl repl binary
	$(CC) $(CFLAGS) $(LDFLAGS) -o bin/olp $?
	CC="$(CC)" LDFLAGS="$(LDFLAGS)" CFLAGS="$(CFLAGS)" sh tests/run all bin/olp
	test '!' -f $@ || mv $@ bin/ol-old
	mv bin/olp $@

c/ol-small.c: fasl/ol.fasl
	# small version for release
	bin/vm fasl/ol.fasl --run owl/ol.scm -s none -o $@

### Documentation

## manual pages

doc/ol.1.gz: doc/ol.1
	gzip -9n <$? >$@

doc/ovm.1.gz: doc/ovm.1
	gzip -9n <$? >$@

## other documentation

manual.md: doc/manual.md owl/*.scm owl/*/*.scm scheme/*.scm
	bin/ol -r bin/tada.scm -d owl -d scheme -o manual.md

manual.man: manual.md
	pandoc $? -s -t man >$@

manual.pdf: manual.md
	pandoc --latex-engine xelatex -o $@ $?


### Tests

fasltest: bin/vm fasl/ol.fasl
	sh tests/run all bin/vm fasl/ol.fasl

test: bin/ol
	sh tests/run all bin/ol

random-test: bin/vm bin/ol fasl/ol.fasl
	sh tests/run random bin/vm fasl/ol.fasl
	sh tests/run random bin/ol

## Automatically generated data

owl/unicode-char-folds.scm:
	echo "(define char-folds '(" >owl/unicode-char-folds.scm
	curl http://www.unicode.org/Public/6.0.0/ucd/CaseFolding.txt | grep "[0-9A-F]* [SFC]; " | sed -re 's/ #.*//' -e 's/( [SFC])?;//g' -e 's/^/ /' -e 's/ / #x/g' -e 's/ /(/' -e 's/$$/)/' | tr "[A-F]" "[a-f]" >> owl/unicode-char-folds.scm
	echo '))' >>owl/unicode-char-folds.scm

## Release tarball

tarball: c/ol.c bin/ol
	# check that version is specified
	echo "${VERSION}" | grep [0-9]
	# make a new tarball
	-rm -rf owl-${VERSION}
	mkdir owl-${VERSION}
	cp -va bin owl-${VERSION} # keep times
	-rm owl-${VERSION}/bin/vm owl-${VERSION}/bin/ol owl-${VERSION}/bin/ol-old
	cp -va Makefile c fasl LICENCE README.md THANKS owl scheme tests doc owl-${VERSION}
	tar -f - -c owl-${VERSION} | gzip -9 > owl-${VERSION}.tar.gz
	# check that build of the contents succeeds
	find owl-${VERSION}
	cd owl-${VERSION} && make
	owl-${VERSION}/bin/ol --version
	bin/vm fasl/ol.fasl --run owl/ol.scm -s none -o ol-${VERSION}.c
	cc -O -o ol-${VERSION} ol-${VERSION}.c
	./ol-${VERSION} --version
	gzip -9 ol-${VERSION}.c


## Installation

install: bin/ol bin/vm doc/ol.1.gz doc/ovm.1.gz
	-mkdir -p $(DESTDIR)$(PREFIX)$(BINDIR)
	-mkdir -p $(DESTDIR)$(PREFIX)$(MANDIR)/man1
	$(INSTALL) -m 755 bin/ol $(DESTDIR)$(PREFIX)$(BINDIR)/ol
	$(INSTALL) -m 755 bin/vm $(DESTDIR)$(PREFIX)$(BINDIR)/ovm
	$(INSTALL) -m 644 doc/ol.1.gz $(DESTDIR)$(PREFIX)$(MANDIR)/man1/ol.1.gz
	$(INSTALL) -m 644 doc/ovm.1.gz $(DESTDIR)$(PREFIX)$(MANDIR)/man1/ovm.1.gz

uninstall:
	-rm -f $(DESTDIR)$(PREFIX)$(BINDIR)/ol
	-rm -f $(DESTDIR)$(PREFIX)$(BINDIR)/ovm
	-rm -f $(DESTDIR)$(PREFIX)$(MANDIR)/man1/ol.1.gz
	-rm -f $(DESTDIR)$(PREFIX)$(MANDIR)/man1/ovm.1.gz

clean:
	-rm -f fasl/boot.fasl fasl/bootp.fasl fasl/ol.fasl
	-rm -f c/_vm.c c/vm.c c/ol.c
	-rm -f doc/*.gz manual.md
	-rm -f tmp/*
	-rm -f bin/ol bin/ol-old bin/vm

.PHONY: all documentation owl clean install uninstall random-test test fasltest
