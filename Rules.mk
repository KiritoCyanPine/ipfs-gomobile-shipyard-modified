TGT_BIN :=
CLEAN :=
COVERAGE :=
DISTCLEAN :=
TEST :=
TEST_SHORT :=
GOCC ?= go
PROTOC ?= protoc

all: help    # all has to be first defined target
.PHONY: all

include mk/git.mk # has to be before tarball.mk
include mk/tarball.mk
include mk/util.mk
include mk/golang.mk

# -------------------- #
#   extra properties   #
# -------------------- #

ifeq ($(TEST_NO_FUSE),1)
	GOTAGS += nofuse
endif
export LIBP2P_TCP_REUSEPORT=false

# -------------------- #
#       sub-files      #
# -------------------- #
dir := bin
include $(dir)/Rules.mk

# tests need access to rules from plugin
dir := plugin
include $(dir)/Rules.mk

dir := test
include $(dir)/Rules.mk

dir := cmd/ipfs
include $(dir)/Rules.mk

# include this file only if coverage target is executed
# it is quite expensive
ifneq ($(filter coverage% clean distclean test/unit/gotest.junit.xml,$(MAKECMDGOALS)),)
	# has to be after cmd/ipfs due to PATH
	dir := coverage
	include $(dir)/Rules.mk
endif

# -------------------- #
#   universal rules    #
# -------------------- #

%.pb.go: %.proto bin/protoc-gen-gogofaster
	$(PROTOC) --gogofaster_out=. --proto_path=.:$(GOPATH)/src:$(dir $@) $<

# -------------------- #
#     core targets     #
# -------------------- #

build: $(TGT_BIN)
.PHONY: build

clean:
	rm -rf $(CLEAN)
.PHONY: clean

coverage: $(COVERAGE)
.PHONY: coverage

distclean: clean
	rm -rf $(DISTCLEAN)
	git clean -ffxd
.PHONY: distclean

test: $(TEST)
.PHONY: test

test_short: $(TEST_SHORT)
.PHONY: test_short

deps:
.PHONY: deps

nofuse: GOTAGS += nofuse
nofuse: build
.PHONY: nofuse

install: cmd/ipfs-install
.PHONY: install

install_unsupported: install
	@echo "/=======================================================================\\"
	@echo '|                                                                       |'
	@echo '| `make install_unsupported` is deprecated, use `make install` instead. |'
	@echo '|                                                                       |'
	@echo "\\=======================================================================/"
.PHONY: install_unsupported

uninstall:
	$(GOCC) clean -i ./cmd/ipfs
.PHONY: uninstall

supported:
	@echo "Currently supported platforms:"
	@for p in ${SUPPORTED_PLATFORMS}; do echo $$p; done
.PHONY: supported

help:
	@echo 'DEPENDENCY TARGETS:'
	@echo ''
	@echo '  deps                 - Download dependencies using bundled gx'
	@echo '  test_sharness_deps   - Download and build dependencies for sharness'
	@echo ''
	@echo 'BUILD TARGETS:'
	@echo ''
	@echo '  all          - print this help message'
	@echo '  build        - Build binary at ./cmd/ipfs/ipfs'
	@echo '  nofuse       - Build binary with no fuse support'
	@echo '  install      - Build binary and install into $$GOPATH/bin'
#	@echo '  dist_install - TODO: c.f. ./cmd/ipfs/dist/README.md'
	@echo ''
	@echo 'CLEANING TARGETS:'
	@echo ''
	@echo '  clean        - Remove files generated by build'
	@echo '  distclean    - Remove files that are no part of a repository'
	@echo '  uninstall    - Remove binary from $$GOPATH/bin'
	@echo ''
	@echo 'TESTING TARGETS:'
	@echo ''
	@echo '  test                    - Run all tests'
	@echo '  test_short              - Run short go tests and short sharness tests'
	@echo '  test_go_short           - Run short go tests'
	@echo '  test_go_test            - Run all go tests'
	@echo '  test_go_expensive       - Run all go tests and compile on all platforms'
	@echo '  test_go_race            - Run go tests with the race detector enabled'
	@echo '  test_go_lint            - Run the `golangci-lint` vetting tool'
	@echo '  test_sharness_short     - Run short sharness tests'
	@echo '  test_sharness_expensive - Run all sharness tests'
	@echo '  coverage     - Collects coverage info from unit tests and sharness'
	@echo
.PHONY: help
