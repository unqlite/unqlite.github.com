# Makefile for Linux X86-64 platform
# Modify it, if needed

msg=

usage:
	@echo "  Usage:                                    "
	@echo "      1. make test                          "
	@echo "      2. make commit msg='comments'         "
	@echo "      3. make remote-commit                 "
	@echo "                                            "

build:
	@jekyll --server

commit: clean 
	git add .	
	git commit -m '$(msg)'

remote-commit: clean
#	git remote add master https://github.com/guiquanz/guiquanz.github.com.git
	git push -u master

.PHONY: clean test

clean: 
	find . -name \*~ -type f |xargs rm -f 
	find . -name \*.bak -type f |xargs rm -f 

test: clean build
	@echo "Ok\n"

