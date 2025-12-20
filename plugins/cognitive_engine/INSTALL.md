# OpenCoq Cognitive Engine - Installation Guide

This document provides instructions for building and installing the OpenCoq Cognitive Engine plugin with native library support.

## Prerequisites

### Required

- **OCaml** >= 4.14.0
- **GCC** or Clang C compiler
- **Make** build system

### Optional (for native performance)

- **GGML** - Tensor computation library
- **RocksDB** - High-performance key-value store
- **CUDA Toolkit** - For GPU acceleration (NVIDIA)
- **Metal Framework** - For GPU acceleration (macOS)

## Quick Start

```bash
# Clone the repository
git clone https://github.com/o9nn/opencoq.git
cd opencoq/plugins/cognitive_engine

# Build with automatic dependency detection
make

# Run tests
make test
```

## Installing Dependencies

### Ubuntu/Debian

```bash
# Install OCaml and build tools
sudo apt-get update
sudo apt-get install -y ocaml ocaml-native-compilers opam build-essential

# Install RocksDB
sudo apt-get install -y librocksdb-dev

# Install GGML (from source)
git clone https://github.com/ggerganov/ggml.git
cd ggml
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
sudo make install
```

### macOS

```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install OCaml and build tools
brew install ocaml opam

# Install RocksDB
brew install rocksdb

# Install GGML (from source)
git clone https://github.com/ggerganov/ggml.git
cd ggml
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DGGML_METAL=ON
make -j$(sysctl -n hw.ncpu)
sudo make install
```

### Arch Linux

```bash
# Install OCaml and build tools
sudo pacman -S ocaml opam base-devel

# Install RocksDB
sudo pacman -S rocksdb

# Install GGML (from AUR or source)
git clone https://github.com/ggerganov/ggml.git
cd ggml
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
sudo make install
```

## Build Options

### Standard Build (OCaml-only fallback)

```bash
make
```

This builds the cognitive engine with pure OCaml implementations. Tensor operations will use the fallback implementation.

### Build with GGML

```bash
# Ensure GGML is installed
pkg-config --exists ggml && echo "GGML found"

# Build
make
```

The Makefile automatically detects GGML and enables native tensor operations.

### Build with RocksDB

```bash
# Ensure RocksDB is installed
pkg-config --exists rocksdb && echo "RocksDB found"

# Build
make
```

The Makefile automatically detects RocksDB and enables native persistence.

### Build with CUDA Support

```bash
# Ensure CUDA is installed
which nvcc && echo "CUDA found"

# Build GGML with CUDA
cd ggml/build
cmake .. -DGGML_CUDA=ON
make -j$(nproc)
sudo make install

# Rebuild cognitive engine
cd opencoq/plugins/cognitive_engine
make clean && make
```

### Build with Metal Support (macOS)

```bash
# Build GGML with Metal
cd ggml/build
cmake .. -DGGML_METAL=ON
make -j$(sysctl -n hw.ncpu)
sudo make install

# Rebuild cognitive engine
cd opencoq/plugins/cognitive_engine
make clean && make
```

## Verification

### Check Build Configuration

```bash
make info
```

Expected output:
```
╔══════════════════════════════════════════════════════════════╗
║     Cognitive Engine Build Configuration                     ║
╠══════════════════════════════════════════════════════════════╣
║  OCaml:    4.14.0
║  GGML:     enabled
║  CUDA:     enabled
║  Metal:    disabled
║  RocksDB:  enabled
╚══════════════════════════════════════════════════════════════╝
```

### Run Tests

```bash
# Run all tests
make test

# Run specific test suites
make test-pln        # PLN reasoning tests
make test-moses      # MOSES evolution tests
make test-persistence # Persistence layer tests
make test-ggml       # GGML bindings tests (requires GGML)
make test-rocksdb    # RocksDB bindings tests (requires RocksDB)
```

## Installation

### System-wide Installation

```bash
sudo make install
```

This installs the plugin to the OCaml library directory.

### Custom Installation Directory

```bash
make install INSTALL_DIR=/path/to/custom/dir
```

### Uninstallation

```bash
sudo make uninstall
```

## Troubleshooting

### GGML Not Detected

If GGML is installed but not detected:

```bash
# Check if pkg-config can find GGML
pkg-config --modversion ggml

# If not found, set PKG_CONFIG_PATH
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

# Or specify library path directly
export LIBRARY_PATH=/usr/local/lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
```

### RocksDB Not Detected

If RocksDB is installed but not detected:

```bash
# Check if pkg-config can find RocksDB
pkg-config --modversion rocksdb

# If not found, try installing the development package
sudo apt-get install librocksdb-dev  # Ubuntu/Debian
brew install rocksdb                  # macOS
```

### Compilation Errors

If you encounter compilation errors:

```bash
# Clean and rebuild
make clean
make

# Check for missing dependencies
make check-deps

# Verbose build
make VERBOSE=1
```

### Runtime Errors

If you encounter runtime errors with native libraries:

```bash
# Check library paths
ldd ./test_ggml_bindings  # Linux
otool -L ./test_ggml_bindings  # macOS

# Set library path if needed
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
```

## Performance Tuning

### GGML Thread Count

```ocaml
(* Set number of threads for GGML operations *)
let ctx = Ggml_native.create_context ~n_threads:8 ()
```

### RocksDB Compression

```ocaml
(* Use LZ4 compression for better performance *)
let db = Rocksdb_native.open_db ~compression:LZ4 "/path/to/db"

(* Use Zstd for better compression ratio *)
let db = Rocksdb_native.open_db ~compression:Zstd "/path/to/db"
```

### Memory Configuration

```ocaml
(* Allocate more memory for GGML context *)
let ctx = Ggml_native.create_context ~mem_size:(512 * 1024 * 1024) ()
```

## API Documentation

Generate API documentation:

```bash
make doc
```

Documentation will be generated in the `doc/` directory.

## Support

For issues and questions:
- GitHub Issues: https://github.com/o9nn/opencoq/issues
- Documentation: https://github.com/o9nn/opencoq/wiki

## License

GNU Lesser General Public License Version 2.1
