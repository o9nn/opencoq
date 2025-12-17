# Windows Build Troubleshooting Guide

## Common Issues and Solutions

### 1. Cygwin Installation Errors

#### Problem: "No such file or directory" for `/etc/setup/*.rc`, `*.db`, `*.timestamp`

**Cause**: Cygwin setup files are missing during bootstrap process.

**Solution**:
```bash
# Manually create the required setup directories
mkdir -p /etc/setup
touch /etc/setup/setup.rc
touch /etc/setup/installed.db
touch /etc/setup/timestamp
```

The updated `dev/make-sdk-win32.sh` script now automatically creates these directories.

#### Problem: Package 'cygwin32-binutils' not found

**Cause**: This is a legacy package name that may not exist in current Cygwin distributions.

**Solution**: The required compilation tools should come from:
- `mingw64-i686-gcc-core`
- `mingw64-i686-gcc-g++`
- `mingw64-i686-gcc`

These packages include binutils as dependencies.

### 2. Source Retrieval Failures (404 Errors)

#### Problem: Cannot download specific commit SHA tarball

**Cause**: Hardcoded commit SHAs in build configurations may not exist in the repository.

**Solution**:
- Use branch names instead of commit SHAs: `main`, `v8.14`, etc.
- Use `HEAD` or current checkout instead of downloading tarballs
- The GitHub Actions workflow now uses `actions/checkout@v4` which automatically checks out the correct commit

**Example Fix in OPAM or build scripts**:
```bash
# Instead of:
# https://github.com/OpenCoq/opencoq/archive/31ce95d42b4b2f351e162af64846ce1b22f4c173.tar.gz

# Use:
# https://github.com/OpenCoq/opencoq/archive/refs/heads/main.tar.gz
# Or better yet, use git clone with the appropriate branch
```

### 3. Build Prerequisites

#### Required Cygwin Packages

The following packages must be installed via Cygwin setup:

**Essential**:
- `wget` - For downloading dependencies
- `p7zip` - For extracting archives
- `make` - For build system
- `sed` - For text processing

**Compilers**:
- `mingw64-i686-gcc-core` - C compiler
- `mingw64-i686-gcc-g++` - C++ compiler
- `mingw64-i686-gcc` - GCC suite

**Optional but Recommended**:
- `patch` - For applying patches
- `rlwrap` - For readline support
- `libreadline6` - Readline library
- `diffutils` - For diffs
- `tar`, `gzip` - For archive handling

#### Environment Variables

Set these before building:

```bash
export BASE="/cygdrive/c/CoqSDK-85-1"  # Or your preferred location
export VERBOSE=1  # For detailed output
```

### 4. Windows SDK Build Process

To build the complete Windows SDK:

```bash
cd dev
bash make-sdk-win32.sh
```

This script will:
1. Check for required tools (wget, 7z, gcc)
2. Download OCaml, lablgtk, GTK, glib, camlp5, and NSIS
3. Install OCaml compiler
4. Build and install lablgtk with Windows patches
5. Build and install camlp5
6. Install NSIS for installer creation
7. Create a complete SDK zip file

**Expected Output**: `CoqSDK-85-1.zip` in the current directory

### 5. Cygwin Directory Structure

After successful setup, your Cygwin installation should have:

```
/cygdrive/c/cygwin/
├── bin/
├── etc/
│   └── setup/
│       ├── setup.rc
│       ├── installed.db
│       └── timestamp
├── lib/
└── var/
    └── cache/
```

### 6. Using GitHub Actions CI

The repository now includes `.github/workflows/windows-ci.yml` which:

- Automatically sets up Cygwin with all required packages
- Creates necessary setup directories
- Uses the current commit SHA (not hardcoded)
- Provides detailed logging
- Archives build artifacts

**To trigger manually**: Go to Actions → Windows CI → Run workflow

### 7. Debugging Build Failures

#### Enable verbose output:
```bash
export VERBOSE=1
bash dev/make-sdk-win32.sh
```

#### Check log files:
```bash
# After build, check these logs in the build directory:
cat build/lablgtk-*/log-configure
cat build/lablgtk-*/log-make
cat build/camlp5-*/log-configure
cat build/camlp5-*/log-make
```

#### Verify tools:
```bash
which wget 7z make i686-w64-mingw32-gcc
gcc --version
```

### 8. Known Limitations

1. **Spaces in Paths**: The build system does not support spaces in `$BASE`. Choose a path without spaces.
2. **Network Issues**: The build downloads several large files. Ensure stable internet connection.
3. **Disk Space**: The SDK build requires several GB of disk space.

### 9. Getting Help

If you encounter issues not covered here:

1. Check the GitHub Actions logs for detailed error messages
2. Search existing GitHub issues
3. Create a new issue with:
   - Full error message
   - Cygwin version (`uname -a`)
   - GCC version (`gcc --version`)
   - Build script output
   - Contents of log files

### 10. Quick Reference Commands

```bash
# Install Cygwin packages manually
./setup-x86_64.exe -q -P wget,p7zip,make,mingw64-i686-gcc-g++

# Check if required tools are available
for tool in wget 7z make gcc; do which $tool || echo "$tool missing"; done

# Clean build artifacts
rm -rf tmp build CoqSDK-*.zip

# Start fresh SDK build
bash dev/make-sdk-win32.sh

# Build only specific component
bash dev/make-sdk-win32.sh install_ocaml
bash dev/make-sdk-win32.sh build_install_lablgtk
```

## Related Files

- `dev/make-sdk-win32.sh` - Windows 32-bit SDK build script
- `dev/make-sdk-win64.sh` - Windows 64-bit SDK build script  
- `dev/make-installer-win32.sh` - Windows 32-bit installer builder
- `dev/make-installer-win64.sh` - Windows 64-bit installer builder
- `.github/workflows/windows-ci.yml` - GitHub Actions CI workflow
