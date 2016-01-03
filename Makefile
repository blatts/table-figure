# -*- mode: Makefile -*-
# Time-stamp: "2016-01-03 19:25:10 sb"

#  file       Makefile
#  copyright  (c) Sebastian Blatt 2009 -- 2016

types := asy
files = table_figure_test.asy
targets := $(foreach t,$(types),$(files:.$(t)=.pdf))

all: $(targets)

%.pdf: %.asy
	@echo "asymptote: $< -> $@"
	@asy $<

.PHONY: clean

clean:
	@echo "removing all targets: $(targets)"
	@-rm -f $(targets)
