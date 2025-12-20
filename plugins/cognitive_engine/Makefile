# Cognitive Engine Plugin Makefile
# Supports OCaml-only, GGML-enabled, and RocksDB-enabled builds

# Configuration
OCAMLFIND ?= ocamlfind
OCAMLOPT ?= ocamlopt
OCAMLC ?= ocamlc
CC ?= gcc
AR ?= ar

# Detect GGML availability
GGML_AVAILABLE := $(shell pkg-config --exists ggml 2>/dev/null && echo yes || echo no)
ifeq ($(GGML_AVAILABLE),no)
  # Try alternative detection methods
  GGML_AVAILABLE := $(shell test -f /usr/local/lib/libggml.a && echo yes || echo no)
endif
ifeq ($(GGML_AVAILABLE),no)
  GGML_AVAILABLE := $(shell test -f /usr/lib/libggml.a && echo yes || echo no)
endif

# Detect RocksDB availability
ROCKSDB_AVAILABLE := $(shell pkg-config --exists rocksdb 2>/dev/null && echo yes || echo no)
ifeq ($(ROCKSDB_AVAILABLE),no)
  ROCKSDB_AVAILABLE := $(shell test -f /usr/local/lib/librocksdb.a && echo yes || echo no)
endif
ifeq ($(ROCKSDB_AVAILABLE),no)
  ROCKSDB_AVAILABLE := $(shell test -f /usr/lib/librocksdb.a && echo yes || echo no)
endif
ifeq ($(ROCKSDB_AVAILABLE),no)
  ROCKSDB_AVAILABLE := $(shell test -f /usr/lib/x86_64-linux-gnu/librocksdb.so && echo yes || echo no)
endif

# Compiler flags
OCAMLFLAGS = -I . -I ../.. -I ../../lib -I ../../kernel -I ../../library
CFLAGS = -fPIC -O2 -Wall -Wextra
LDFLAGS =

# GGML configuration
ifeq ($(GGML_AVAILABLE),yes)
  ifeq ($(shell pkg-config --exists ggml 2>/dev/null && echo yes),yes)
    CFLAGS += -DHAVE_GGML $(shell pkg-config --cflags ggml)
    LDFLAGS += $(shell pkg-config --libs ggml)
  else
    CFLAGS += -DHAVE_GGML -I/usr/local/include
    LDFLAGS += -L/usr/local/lib -lggml
  endif
  GGML_STATUS = enabled
else
  GGML_STATUS = disabled (fallback to OCaml)
endif

# CUDA support for GGML
CUDA_AVAILABLE := $(shell which nvcc >/dev/null 2>&1 && echo yes || echo no)
ifeq ($(CUDA_AVAILABLE),yes)
ifeq ($(GGML_AVAILABLE),yes)
  CFLAGS += -DGGML_USE_CUDA
  LDFLAGS += -lcuda -lcublas
  CUDA_STATUS = enabled
endif
else
  CUDA_STATUS = disabled
endif

# Metal support for GGML (macOS)
METAL_AVAILABLE := $(shell test -d /System/Library/Frameworks/Metal.framework && echo yes || echo no)
ifeq ($(METAL_AVAILABLE),yes)
ifeq ($(GGML_AVAILABLE),yes)
  CFLAGS += -DGGML_USE_METAL
  LDFLAGS += -framework Metal -framework Foundation
  METAL_STATUS = enabled
endif
else
  METAL_STATUS = disabled
endif

# RocksDB configuration
ifeq ($(ROCKSDB_AVAILABLE),yes)
  ifeq ($(shell pkg-config --exists rocksdb 2>/dev/null && echo yes),yes)
    CFLAGS += -DHAVE_ROCKSDB $(shell pkg-config --cflags rocksdb)
    LDFLAGS += $(shell pkg-config --libs rocksdb)
  else
    CFLAGS += -DHAVE_ROCKSDB -I/usr/local/include
    LDFLAGS += -L/usr/local/lib -lrocksdb -lpthread -lz -lsnappy -llz4 -lzstd -lbz2
  endif
  ROCKSDB_STATUS = enabled
else
  ROCKSDB_STATUS = disabled (fallback to JSON)
endif

# Source files
ML_SOURCES = \
  hypergraph.ml \
  tensor_backend.ml \
  ggml_bindings.ml \
  ggml_native.ml \
  rocksdb_native.ml \
  task_system.ml \
  attention_system.ml \
  pln_formulas.ml \
  pln_cache.ml \
  pln_integration.ml \
  pln_moses.ml \
  moses_programs.ml \
  persistence.ml \
  reasoning_engine.ml \
  neural_symbolic_fusion.ml \
  creative_problem_solving.ml \
  metacognition.ml \
  cognitive_engine.ml \
  cognitive_engine_plugin_mod.ml

MLI_SOURCES = $(ML_SOURCES:.ml=.mli)

C_SOURCES = ggml_stubs.c ggml_native.c rocksdb_stubs.c

# Object files
CMO_FILES = $(ML_SOURCES:.ml=.cmo)
CMX_FILES = $(ML_SOURCES:.ml=.cmx)
CMI_FILES = $(ML_SOURCES:.ml=.cmi)
C_OBJECTS = $(C_SOURCES:.c=.o)

# Library name
PLUGIN_NAME = cognitive_engine_plugin

# Targets
.PHONY: all clean byte native test info deps check-deps install uninstall

all: info check-deps native byte

info:
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║     Cognitive Engine Build Configuration                 ║"
	@echo "╠══════════════════════════════════════════════════════════╣"
	@echo "║  OCaml:    $(shell $(OCAMLOPT) -version 2>/dev/null || echo 'not found')"
	@echo "║  GGML:     $(GGML_STATUS)"
	@echo "║  CUDA:     $(CUDA_STATUS)"
	@echo "║  Metal:    $(METAL_STATUS)"
	@echo "║  RocksDB:  $(ROCKSDB_STATUS)"
	@echo "╚══════════════════════════════════════════════════════════╝"

check-deps:
	@echo "Checking dependencies..."
	@which $(OCAMLOPT) >/dev/null 2>&1 || (echo "ERROR: OCaml not found" && exit 1)
	@which $(CC) >/dev/null 2>&1 || (echo "ERROR: C compiler not found" && exit 1)
	@echo "All required dependencies found."

# Native code compilation
native: $(PLUGIN_NAME).cmxa lib$(PLUGIN_NAME)_stubs.a

$(PLUGIN_NAME).cmxa: $(CMX_FILES)
	$(OCAMLOPT) -a -o $@ $(CMX_FILES)

lib$(PLUGIN_NAME)_stubs.a: $(C_OBJECTS)
	$(AR) rcs $@ $(C_OBJECTS)

# Bytecode compilation
byte: $(PLUGIN_NAME).cma

$(PLUGIN_NAME).cma: $(CMO_FILES)
	$(OCAMLC) -a -o $@ $(CMO_FILES)

# C stubs compilation
%.o: %.c
	$(CC) $(CFLAGS) -I$(shell $(OCAMLOPT) -where) -c $< -o $@

# OCaml compilation rules
%.cmi: %.mli
	$(OCAMLOPT) $(OCAMLFLAGS) -c $<

%.cmo: %.ml
	$(OCAMLC) $(OCAMLFLAGS) -c $<

%.cmx: %.ml
	$(OCAMLOPT) $(OCAMLFLAGS) -c $<

# Dependencies
deps:
	ocamldep $(ML_SOURCES) $(MLI_SOURCES) > .depend

-include .depend

# Manual dependencies (fallback)
hypergraph.cmi: 
hypergraph.cmx: hypergraph.cmi
tensor_backend.cmi: 
tensor_backend.cmx: tensor_backend.cmi
ggml_bindings.cmi:
ggml_bindings.cmx: ggml_bindings.cmi
ggml_native.cmi:
ggml_native.cmx: ggml_native.cmi
rocksdb_native.cmi:
rocksdb_native.cmx: rocksdb_native.cmi
task_system.cmi: hypergraph.cmi
task_system.cmx: task_system.cmi hypergraph.cmx
attention_system.cmi: hypergraph.cmi
attention_system.cmx: attention_system.cmi hypergraph.cmx
pln_formulas.cmi:
pln_formulas.cmx: pln_formulas.cmi
pln_cache.cmi: pln_formulas.cmi
pln_cache.cmx: pln_cache.cmi pln_formulas.cmx
pln_integration.cmi: hypergraph.cmi pln_formulas.cmi
pln_integration.cmx: pln_integration.cmi hypergraph.cmx pln_formulas.cmx
pln_moses.cmi: pln_formulas.cmi moses_programs.cmi
pln_moses.cmx: pln_moses.cmi pln_formulas.cmx moses_programs.cmx
moses_programs.cmi:
moses_programs.cmx: moses_programs.cmi
persistence.cmi: hypergraph.cmi
persistence.cmx: persistence.cmi hypergraph.cmx
reasoning_engine.cmi: hypergraph.cmi
reasoning_engine.cmx: reasoning_engine.cmi hypergraph.cmx
neural_symbolic_fusion.cmi: hypergraph.cmi tensor_backend.cmi
neural_symbolic_fusion.cmx: neural_symbolic_fusion.cmi hypergraph.cmx tensor_backend.cmx
creative_problem_solving.cmi: hypergraph.cmi
creative_problem_solving.cmx: creative_problem_solving.cmi hypergraph.cmx
metacognition.cmi: hypergraph.cmi task_system.cmi attention_system.cmi
metacognition.cmx: metacognition.cmi hypergraph.cmx task_system.cmx attention_system.cmx
cognitive_engine.cmi: hypergraph.cmi task_system.cmi attention_system.cmi reasoning_engine.cmi metacognition.cmi
cognitive_engine.cmx: cognitive_engine.cmi hypergraph.cmx task_system.cmx attention_system.cmx reasoning_engine.cmx metacognition.cmx
cognitive_engine_plugin_mod.cmi: cognitive_engine.cmi
cognitive_engine_plugin_mod.cmx: cognitive_engine_plugin_mod.cmi cognitive_engine.cmx

# Test targets
.PHONY: test test-pln test-moses test-persistence test-ggml test-rocksdb

test: test-pln test-moses test-persistence
	@echo "All tests completed."

test-pln: test_pln_formulas test_pln_cache test_pln_moses
	./test_pln_formulas
	./test_pln_cache
	./test_pln_moses

test-moses: test_moses_programs
	./test_moses_programs

test-persistence: test_persistence
	./test_persistence

test-ggml: test_ggml_bindings
	./test_ggml_bindings

test-rocksdb: test_rocksdb_native
	./test_rocksdb_native

test_pln_formulas: test_pln_formulas.ml pln_formulas.cmx
	$(OCAMLOPT) $(OCAMLFLAGS) -o $@ pln_formulas.cmx $<

test_pln_cache: test_pln_cache.ml pln_formulas.cmx pln_cache.cmx pln_integration.cmx
	$(OCAMLOPT) $(OCAMLFLAGS) -o $@ pln_formulas.cmx pln_integration.cmx pln_cache.cmx $<

test_pln_moses: test_pln_moses.ml pln_formulas.cmx moses_programs.cmx pln_moses.cmx
	$(OCAMLOPT) $(OCAMLFLAGS) -o $@ pln_formulas.cmx moses_programs.cmx pln_moses.cmx $<

test_moses_programs: test_moses_programs.ml moses_programs.cmx
	$(OCAMLOPT) $(OCAMLFLAGS) -o $@ moses_programs.cmx $<

test_persistence: test_persistence.ml hypergraph.cmx persistence.cmx
	$(OCAMLOPT) $(OCAMLFLAGS) -o $@ unix.cmxa hypergraph.cmx persistence.cmx $<

test_ggml_bindings: test_ggml_bindings.ml ggml_bindings.cmx ggml_native.cmx
	$(OCAMLOPT) $(OCAMLFLAGS) -o $@ bigarray.cmxa ggml_bindings.cmx ggml_native.cmx $< \
		-cclib -L. -cclib -l$(PLUGIN_NAME)_stubs $(LDFLAGS)

test_rocksdb_native: test_rocksdb_native.ml rocksdb_native.cmx
	$(OCAMLOPT) $(OCAMLFLAGS) -o $@ rocksdb_native.cmx $< \
		-cclib -L. -cclib -l$(PLUGIN_NAME)_stubs $(LDFLAGS)

# Clean
clean:
	rm -f *.cmi *.cmo *.cmx *.cma *.cmxa *.o *.a
	rm -f test_pln_formulas test_pln_cache test_pln_moses
	rm -f test_moses_programs test_persistence
	rm -f test_ggml_bindings test_rocksdb_native
	rm -f .depend

# Deep clean (including generated files)
distclean: clean
	rm -rf _build
	rm -f *.annot *.cmt *.cmti

# Install
INSTALL_DIR ?= $(shell $(OCAMLOPT) -where)/cognitive_engine

install: all
	@echo "Installing to $(INSTALL_DIR)..."
	mkdir -p $(INSTALL_DIR)
	cp $(PLUGIN_NAME).cmxa $(PLUGIN_NAME).cma $(INSTALL_DIR)/
	cp lib$(PLUGIN_NAME)_stubs.a $(INSTALL_DIR)/
	cp *.cmi $(INSTALL_DIR)/
	cp *.mli $(INSTALL_DIR)/
	@echo "Installation complete."

uninstall:
	@echo "Uninstalling from $(INSTALL_DIR)..."
	rm -rf $(INSTALL_DIR)
	@echo "Uninstallation complete."

# Documentation
.PHONY: doc
doc:
	ocamldoc -html -d doc $(MLI_SOURCES)

# Benchmark
.PHONY: bench
bench: native
	@echo "Running benchmarks..."
	@echo "TODO: Implement benchmarks"
