install:
	find . -mindepth 2 -name Makefile -exec grep -l install: {} \; | \
		xargs --no-run-if-empty -n 1 dirname | \
		xargs --no-run-if-empty -n 1 -I {} bash -c "make -C {} install || exit 255"
