SHELL := /bin/bash

.PHONY: docs
docs: README.md

README.md: $(wildcard *.tf)
	terraform-docs markdown table . | tee $@ &>/dev/null
