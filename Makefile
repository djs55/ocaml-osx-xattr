.PHONY: build test install uninstall reinstall clean

FINDLIB_NAME=osx-xattr
MOD_NAME=osx_xattr

OCAML_LIB_DIR=$(shell ocamlc -where)
LWT_LIB_DIR=$(shell ocamlfind query lwt)
CTYPES_LIB_DIR=$(shell ocamlfind query ctypes)

OCAMLBUILD=CTYPES_LIB_DIR=$(CTYPES_LIB_DIR) OCAML_LIB_DIR=$(OCAML_LIB_DIR) \
           LWT_LIB_DIR=$(LWT_LIB_DIR)       \
	ocamlbuild -use-ocamlfind -classic-display

WITH_LWT=$(shell ocamlfind query threads lwt > /dev/null 2>&1 ; echo $$?)

TARGETS=.cma .cmxa

PRODUCTS=$(addprefix $(MOD_NAME),$(TARGETS)) \
	lib$(MOD_NAME)_stubs.a dll$(MOD_NAME)_stubs.so

ifeq ($(WITH_LWT), 0)
PRODUCTS+=$(addprefix $(MOD_NAME)_lwt,$(TARGETS))
endif

TYPES=.mli .cmi .cmti

INSTALL:=$(addprefix $(MOD_NAME), $(TYPES)) \
         $(addprefix $(MOD_NAME), $(TARGETS))

INSTALL:=$(addprefix _build/lib/,$(INSTALL))

ifeq ($(WITH_LWT), 0)
INSTALL_LWT:=$(addprefix $(MOD_NAME)_lwt,$(TYPES)) \
             $(addprefix $(MOD_NAME)_lwt,$(TARGETS))

INSTALL_LWT:=$(addprefix _build/lwt/,$(INSTALL_LWT))
INSTALL_LWT:=$(INSTALL_LWT) \
	      -dll _build/lwt/dll$(MOD_NAME)_lwt_stubs.so \
	      -nodll _build/lwt/lib$(MOD_NAME)_lwt_stubs.a
INSTALL+=$(INSTALL_LWT)
endif

ARCHIVES:=_build/lib/$(MOD_NAME).a

ifeq ($(WITH_LWT), 0)
ARCHIVES+=_build/lwt/$(MOD_NAME)_lwt.a
endif

build:
	$(OCAMLBUILD) $(PRODUCTS)

test: build
	$(OCAMLBUILD) lib_test/test.native
	$(OCAMLBUILD) lwt_test/test_lwt.native
	./test.native
	./test_lwt.native

install:
	ocamlfind install $(FINDLIB_NAME) META \
		$(INSTALL) \
		-dll _build/lib/dll$(MOD_NAME)_stubs.so \
		-nodll _build/lib/lib$(MOD_NAME)_stubs.a \
		$(ARCHIVES)

uninstall:
	ocamlfind remove $(FINDLIB_NAME)

reinstall: uninstall install

clean:
	ocamlbuild -clean
