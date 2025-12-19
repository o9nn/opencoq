# Cognitive Engine Plugin Makefile
# Supports both OCaml-only and GGML-enabled builds

# Configuration
OCAMLFIND ?= ocamlfind
OCAMLOPT ?= ocamlopt
OCAMLC ?= ocamlc
CC ?= gcc
AR ?= ar

# Detect GGML availability
GGML_AVAILABLE := $(shell pkg-config --exists ggml 2>/dev/null && echo yes || echo no)

# Compiler flags
OCAMLFLAGS = -I . -I ../.. -I ../../lib -I ../../kernel -I ../../library
CFLAGS = -fPIC -O2 -Wall

ifeq ($(GGML_AVAILABLE),yes)
  CFLAGS += -DHAVE_GGML $(shell pkg-config --cflags ggml)
  LDFLAGS = $(shell pkg-config --libs ggml)
  GGML_STATUS = enabled
else
  LDFLAGS =
  GGML_STATUS = disabled (fallback to OCaml)
endif

# Source files
ML_SOURCES = \
  hypergraph.ml \
  tensor_backend.ml \
  ggml_bindings.ml \
  task_system.ml \
  attention_system.ml \
  pln_formulas.ml \
  pln_integration.ml \
  moses_programs.ml \
  reasoning_engine.ml \
  neural_symbolic_fusion.ml \
  creative_problem_solving.ml \
  metacognition.ml \
  cognitive_engine.ml \
  cognitive_engine_plugin_mod.ml

MLI_SOURCES = $(ML_SOURCES:.ml=.mli)

C_SOURCES = ggml_stubs.c

# Object files
CMO_FILES = $(ML_SOURCES:.ml=.cmo)
CMX_FILES = $(ML_SOURCES:.ml=.cmx)
CMI_FILES = $(ML_SOURCES:.ml=.cmi)
C_OBJECTS = $(C_SOURCES:.c=.o)

# Targets
.PHONY: all clean byte native test info

all: info native byte

info:
	@echo "=== Cognitive Engine Build Configuration ==="
	@echo "GGML Backend: $(GGML_STATUS)"
	@echo "OCaml: $(shell $(OCAMLOPT) -version 2>/dev/null || echo 'not found')"
	@echo "============================================="

# Native code compilation
native: cognitive_engine_plugin.cmxa

cognitive_engine_plugin.cmxa: $(CMX_FILES) $(C_OBJECTS)
	$(OCAMLOPT) -a -o $@ $(CMX_FILES)
ifeq ($(GGML_AVAILABLE),yes)
	$(AR) rcs libcognitive_engine_stubs.a $(C_OBJECTS)
endif

# Bytecode compilation
byte: cognitive_engine_plugin.cma

cognitive_engine_plugin.cma: $(CMO_FILES) $(C_OBJECTS)
	$(OCAMLC) -a -o $@ $(CMO_FILES)

# C stubs compilation
%.o: %.c
	$(CC) $(CFLAGS) -I$(shell $(OCAMLOPT) -where) -c $< -o $@

# OCaml compilation rules
%.cmi: %.mli
	$(OCAMLOPT) $(OCAMLFLAGS) -c $<

%.cmo: %.ml %.cmi
	$(OCAMLC) $(OCAMLFLAGS) -c $<

%.cmx: %.ml %.cmi
	$(OCAMLOPT) $(OCAMLFLAGS) -c $<

# Dependencies (simplified - real build should use ocamldep)
hypergraph.cmi: 
hypergraph.cmx: hypergraph.cmi
tensor_backend.cmi: 
tensor_backend.cmx: tensor_backend.cmi
ggml_bindings.cmi:
ggml_bindings.cmx: ggml_bindings.cmi
task_system.cmi: hypergraph.cmi
task_system.cmx: task_system.cmi hypergraph.cmx
attention_system.cmi: hypergraph.cmi
attention_system.cmx: attention_system.cmi hypergraph.cmx
pln_formulas.cmi:
pln_formulas.cmx: pln_formulas.cmi
pln_integration.cmi: hypergraph.cmi pln_formulas.cmi
pln_integration.cmx: pln_integration.cmi hypergraph.cmx pln_formulas.cmx
moses_programs.cmi:
moses_programs.cmx: moses_programs.cmi
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
test: test_pln_formulas
	./test_pln_formulas

test_pln_formulas: test_pln_formulas.ml pln_formulas.cmx
	$(OCAMLOPT) $(OCAMLFLAGS) -o $@ pln_formulas.cmx $<

# Clean
clean:
	rm -f *.cmi *.cmo *.cmx *.cma *.cmxa *.o *.a
	rm -f test_pln_formulas

# Install (placeholder)
install: all
	@echo "Installation requires Coq build system integration"
