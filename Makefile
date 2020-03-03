SHELL := /bin/bash

.PHONY: docs
docs: README.md

README.md: $(wildcard *.tf)
	terraform-docs markdown table . | \
		sed 's/  *$$//g' | \
		tee $@ &>/dev/null
