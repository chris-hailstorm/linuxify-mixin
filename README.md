# linuxify

> Replaces BSD utilities with portable GNU utilities

A comprehensive collection of GNU/Linux utilities that replaces MacOS/BSD utilities with their GNU equivalents, so that commands in MacOS (dev machines) will have the same behavior as in Linux (Docker containers). This ensures portability and correctness of shell scripts and Makefiles.

> **📋 Note**: When copying this repo to your project's `scripts/linuxify/` directory, use `rsync -av --exclude='.git'` to avoid git-within-git problems. This ensures clean project integration without nested git repos. See the [Installation section](#installation) below for more details.

All Linux distros (like those we use for Docker containers) use common utilities that're standardized and portable, such that the same command works the same way on any Linux machine. Perversely, MacOS has its own "special" versions of common utilities, and these BSD utilities are sometimes very different from their GNU/Linux counterparts. Many common utilities -- `sed`, `tar`, `grep`, even very basic commands like `cp` and `mv` -- differ enough that an invocation that works in Linux will fail in MacOS or vice versa -- or worse yet, an invocation will "succeed" in both but have different results! A classic example is a correct `grep` match in GNU/Linux `grep` can give a false negative with BSD `grep`.

## Example: BSD vs GNU incompatibility

Here's a concrete example showing how `sed` behaves differently:

```sh
# In-place file editing with BSD sed (macOS default):
sed -i '' 's/foo/bar/' file.txt        # Works on BSD, fails on GNU

# In-place file editing with GNU sed (Linux):
sed -i 's/foo/bar/' file.txt           # Works on GNU, fails on BSD

# With linuxify, macOS uses GNU sed, so scripts work consistently
```

This incompatibility means a script that works perfectly in your Docker container can silently fail on your Mac, or vice versa. `linuxify` solves this by ensuring both environments use the same GNU tools.

&nbsp;

## Overview

`linuxify` transparently replaces macOS-specific (BSD) utilities with GNU/Linux equivalents by:

* Installing a list of 40+ common system GNU programs
* Installing any that're missing & updating any that're outdated
* Superseding BSD programs with their preferred GNU implementation

This helps ensure shell scripts and Makefiles behave consistently between macOS development and Linux production environments.

`linuxify` is designed to have lower precedence than `asdf`. Our usual pattern is to manage system utilities (like `grep` and `git`) via `linuxify` and development tools (like `python` and `node`) via `asdf`, but there can be cases where that distinction isn't clear or correct. Since `asdf`'s spec file `.tool-versions` is more often tailored to a project than the `linuxify` configuration is, `asdf` "wins" in cases of overlap.

> **🔗 Note on `asdf-direnv` integration**: This repo works seamlessly with the `asdf-direnv` mix-in for automatic project-specific tool management. When used together, `asdf-direnv` automatically sources the `linuxify` configuration without manual `.envrc` setup. See the [asdf-direnv integration section](#asdf-direnv-integration) below for details.

&nbsp;

## Dual operation modes

`linuxify` can be installed in a project-specific way (that exposes utilities and versions required by that particular project), and/or in a machine-wide way (that exposes common versions any time you're in a directory that doesn't have a project-specific `linuxify`). It's a good practice to use both modes: per-project to ensure your repos are portable, and machine-wide for other everyday non-"project" use.

&nbsp;

### 🏠 Global / standalone mode (`~/linuxify/`)

For **global system-wide** GNU utilities integration:

* **Location**: `~/linuxify/`
* **Integration**: Some adds to `~/.zshrc` and `~/.bashrc`
* **Scope**: Anywhere a project-specific config doesn't exist
* **Activation**: Every time a terminal session is created
* **Configuration**: Copies `.linuxify` to `~/.linuxify`
* **Auto-updates**: Supports git-based updates

### 📦 Project / embedded Mode (`*/scripts/linuxify/`)

For **project-specific** integration within repositories:

* **Location**: `/PATH/TO/REPO/scripts/linuxify/`
* **Integration**: Works with project's `.envrc` via `direnv`
* **Scope**: Only within that particular project directory
* **Activation**: Automatic when you `cd` into a project directory (1)
* **Configuration**: Uses project-local `scripts/.linuxify` file
* **Distribution**: Copy this repo to any project's `scripts/` subdir

(1): assuming you've also added the `asdf-direnv` mix-in

&nbsp;

## Installation

### Prerequisites

* **macOS** (Apple Silicon or Intel)
* **Homebrew** installed from [brew.sh](https://brew.sh)
* **zsh** shell (standard on modern macOS)
* **`direnv`** (optional, for project-specific integration)
  * See the `asdf-direnv` repo for how to install `direnv`

&nbsp;

### Global / standalone installation

1. **Clone to home directory:**

```sh
cd ~
git clone <LINUXIFY-REPO-URL> linuxify
```

2. **Install utilities:**

```sh
cd linuxify
./linuxify install
```

3. **Add to shell configuration:**

Add this block manually to **both** `~/.zshrc` and `~/.bashrc` (note the `LINUXIFY-REPO-URL` placeholder):

```sh
#######################################
## GNU utilities via linuxify
#######################################
[[ ! -d ~/linuxify ]] && (echo "Cloning linuxify..." && cd ~ && git clone <LINUXIFY-REPO-URL> linuxify && cd ~/linuxify && ./linuxify install)
pushd ~/linuxify >/dev/null && git remote update && git status -uno | grep 'up to date' || (echo "Pulling linuxify updates..." && git pull && ./linuxify install)
. ~/.linuxify
popd >/dev/null
```

Even if you use `zsh`, this is needed in `~/.bashrc` to support scripts that specify a `bash` shell e.g. via `#!/usr/bin/env bash`.

4. **Open new terminal** to activate

&nbsp;

### Project / embedded installation

1. **Copy to project:**

```sh
# From your project root (using rsync to exclude .git folder)
# Note: no trailing "/" on source means "copy the directory itself" into scripts/
mkdir -p scripts
rsync -av --exclude='.git' /PATH/TO/LINUXIFY/REPO scripts/
```

2. **Install utilities:**

```sh
cd scripts/linuxify
./linuxify install
```

3. **Integrate with `.envrc`:**

**Note**: This step is only needed if your project does NOT use the `asdf-direnv` mix-in. If you're using `asdf-direnv`, `linuxify` integration is automatic.

```sh
# Add to your project's .envrc (only if NOT already using the asdf-direnv version of .envrc)
if [ -f "scripts/linuxify/.linuxify" ]; then
    source scripts/linuxify/.linuxify
fi
```

4. **Enable `direnv`:**

```sh
direnv allow
```

5. **Verify installation:**

```sh
# These should show GNU versions
sed --version    # Should show GNU sed
make --version   # Should show GNU Make  
date --version   # Should show GNU coreutils
```

&nbsp;

## Tool inventory

### Comprehensive GNU utilities

**Core GNU utilities (high impact for script compatibility):**

* `coreutils` - 100+ essential utilities (cat, cp, date, ls, mv, etc.)
* `findutils` - File finding utilities (find, xargs, locate) with extended features
* `diffutils` - File comparison utilities (diff, cmp, sdiff) with more options
* `gnu-sed` - Stream editor with extended regex support
* `gnu-tar` - Archive utility with enhanced features (NOTE: may lose macOS metadata)
* `gnu-which` - Command locator
* `grep` - Pattern matching with extended features
* `gawk` - GNU AWK with more functions
* `make` - Build automation with GNU extensions

**Text processing & development tools:**

* `gnu-indent` - C code formatter
* `wdiff` - Word-based diff
* `ed` - Line editor
* `less` - Pager with more features
* `nano` - Text editor
* `vim` - Enhanced text editor
* `emacs` - Text editor

**Compression & archive utilities:**

* `gzip` - Compression utility
* `unzip` - Archive extraction

**Build & compilation tools:**

* `autoconf` - Automatic configure script builder
* `m4` - Macro processor
* `bison` - Parser generator
* `flex` - Fast lexical analyzer
* `binutils` - Binary utilities
* `gpatch` - Apply patches

**System libraries (important for asdf / Python support):**

* `openssl@3` - Cryptography and SSL/TLS toolkit
* `readline` - Command line editing library
* `sqlite` - Embedded SQL database engine
* `xz` - XZ and LZMA compression library
* `zlib` - General-purpose compression library
* `bzip2` - Block-sorting compression library
* `libffi` - Foreign function interface library
* `tcl-tk` - Tool Command Language and Tk GUI toolkit

**Network & download tools:**

* `wget` - Network downloader
* `curl` - Enhanced HTTP client
* `nmap` - Network scanning and discovery
* `openssh` - Secure shell

**System utilities:**

* `watch` - Execute program periodically
* `screen` - Terminal multiplexer
* `tree` - Directory structure visualization
* `file-formula` - Enhanced file type identification
* `bash` - GNU Bourne-Again Shell
* `perl` - Programming language
* `rsync` - File synchronization

**Security & crypto tools:**

* `gpg` - GNU Privacy Guard
* `libressl` - OpenSSL alternative

**Version control & development:**

* `git` - Version control
* `gh` - GitHub CLI

**Database & formatting tools:**

* `libpq` - PostgreSQL client tools
* `pgformatter` - PostgreSQL formatter
* `sqlfluff` - SQL linter and formatter

**Container & monitoring tools:**

* `ctop` - Container monitoring

&nbsp;

### Intel-only tools (1 tool)

**Available on Intel Macs only:**

* `gdb` - GNU Debugger (requires special configuration)

&nbsp;

## Integration with dev tools

### `asdf` compatibility

`linuxify` is designed to work seamlessly with `asdf` version manager:

* **Division of responsibility**: `linuxify` handles system utilities, `asdf` handles language-specific tools
* **Tool prioritization**: `asdf`-managed tools take precedence over Homebrew versions, in case of overlap
* **No conflicts**: Python and other dev-oriented or language tools are intentionally excluded from `linuxify`

See the `asdf-direnv` mix-in for more information.

&nbsp;

### `direnv` support

Enhanced integration with `direnv` for project-specific environments:

* **Direct sourcing**: Project `.envrc` files can source linuxify configuration directly
* **Environment variable support**: Exports `LDFLAGS`, `CPPFLAGS`, `PKG_CONFIG_PATH`
* **Project isolation**: Embedded mode works cleanly with `.envrc` files

See the `asdf-direnv` mix-in for more information.

&nbsp;

### Dockerized development

* **Consistent behavior**: Scripts work identically in macOS and Linux containers
* **Environment variables**: Properly configured build flags for compilation

&nbsp;

## Technical details

### Path management

Tools are prioritized in this order:

1. **`asdf`-specific paths** (e.g., what's specified in `.tool-versions`)
2. **GNU-specific paths** (e.g., `/opt/homebrew/opt/coreutils/libexec/gnubin`)
3. **General Homebrew paths** (e.g., `/opt/homebrew/bin`)
4. **System paths** (e.g., `/usr/bin`, `/bin`)

&nbsp;

### Environment variables

Variables are handled additively to avoid conflicts:

```sh
export LDFLAGS="${LDFLAGS:-} -L${BREW_HOME}/opt/flex/lib"
export CPPFLAGS="${CPPFLAGS:-} -I${BREW_HOME}/opt/flex/include"
```

### Homebrew optimization

`linuxify` sets `HOMEBREW_NO_AUTO_UPDATE=1` and `HOMEBREW_NO_INSTALL_CLEANUP=1` to speed up Homebrew operations. Note: These variables persist in the current terminal session once linuxify loads, even when changing to directories without `linuxify`. To apply globally across all terminal sessions, add these variables to your `~/.zshrc`.

&nbsp;

### Mode detection

The script automatically detects its operation mode:

* **Standalone**: When located at `~/linuxify/`
* **Embedded**: When located at `*/scripts/linuxify/`
* **Unknown**: When run from any other location, the script will install tools but won't copy configuration files to standard locations

&nbsp;

## Troubleshooting

### Common issues

**Command not found after installation:**

* Open a new terminal session
* Check that shell configuration was properly updated
* Verify PATH with `echo $PATH | tr ':' '\n' | grep -E '(gnu|homebrew)'`

**Conflicts with existing tools:**

* `asdf` tools should take precedence over GNU (if using `asdf`)
* GNU tools should take precedence over BSD (always)
* Check installation order in shell configuration
* Use `which <command>` to verify tool source

**Permission errors:**

* Ensure Homebrew directories are writable
* Run with appropriate permissions: `./linuxify install`

&nbsp;

## Commands

```sh
./linuxify install      # Install all utilities
./linuxify uninstall    # Remove all utilities (keeps current shell if bash)
./linuxify info         # Show information about all tools
./linuxify help         # Show usage information
```

&nbsp;

### Verification

**Quick test** - verify individual tools:

```sh
# These should show GNU versions
sed --version    # Should show GNU sed
make --version   # Should show GNU Make
date --version   # Should show GNU coreutils
```

**Comprehensive test** - verify all utilities at once:

```sh
./test-linuxify
```

This script checks:
- All utilities are installed and runnable
- GNU tools show "GNU" in their version output
- Commands resolve to Homebrew versions (not macOS BSD versions)
- Libraries are installed via Homebrew

The test provides a clear summary with pass/fail counts and helpful troubleshooting tips.

&nbsp;

## Compatible mix-ins

The `linuxify` mix-in works seamlessly with other development environment mix-ins. Its compatibility and arms-length integration with `asdf-direnv` is especially notable. Neither `linuxify` and `asdf-direnv` depends on the other, but they were each developed with the other in mind. When you're changing either repo, it's wise to have a look at the other one too, and test them in combination.

### `asdf-direnv` integration

`asdf-direnv` and `linuxify` both contribute to standardizing tools and versions in the MacOS environment, although different sets of tools. `linuxify` focuses on general system utilities like `git` or `grep` that can usually be used with any project and no specific version requirement other than "pretty recent". `asdf-direnv` focuses on programming tools like `python` and `node`, and also more general tools that are often used in scripts and Makefiles like `jq` and `awscli`.

When `linuxify` is used with the `asdf-direnv` mix-in:

* **Automatic configuration**: No manual .envrc configuration needed
* **Proper precedence**: `asdf` versions → GNU tools → System tools
* **Error handling**: Fails fast if linuxify configuration is broken

### Other compatible mix-ins

* **Make modules**: Standardized makefile capabilities
* **Local postgres**: Dev-local database automation
* *(Additional mix-ins TBD)*

### Manual Integration

For projects not using `asdf-direnv`, add to `.envrc`:

```sh
# GNU utilities (linuxify mix-in)
if [ -f "scripts/linuxify/.linuxify" ]; then
    source scripts/linuxify/.linuxify || {
        echo "❌ FATAL: Failed to load linuxify configuration"
        return 1
    }
fi
```

&nbsp;

## Contributing

### Adding new utilities

When adding a new utility to `linuxify`, you need to update up to three files:

1. **`linuxify`** - Add the formula to the appropriate section
2. **`.linuxify`** - Add PATH/environment variables (if needed)
3. **`README.md`** - Document the new utility

#### Step 1: Add to `linuxify` script

Add the Homebrew formula name to the `linuxify_formulas` array in the appropriate section:

```bash
linuxify_formulas=(
    # ... existing tools ...

    # === YOUR SECTION ===
    "your-formula"   # Brief description
)
```

#### Step 2: Determine if `.linuxify` needs updates

Check if the formula is "keg-only" (not symlinked to `/opt/homebrew/bin`):

```sh
brew info your-formula | grep "keg-only"
```

**Example 1: Non-keg-only formula (like `wget`)**

Most utilities install to `${BREW_HOME}/bin` and are automatically symlinked. These need **no changes** to `.linuxify`.

```sh
# wget installs to /opt/homebrew/bin/wget - already in PATH
# No .linuxify update needed
```

**Example 2: Keg-only formula (like `openssl@3`)**

Keg-only formulas aren't symlinked to avoid conflicts with macOS system libraries. These **require** `.linuxify` updates:

```sh
# openssl@3 is keg-only - needs explicit PATH and flags
```

Add to `.linuxify`:

```bash
# openssl@3 - Cryptography and SSL/TLS toolkit
export PATH="${BREW_HOME}/opt/openssl@3/bin:$PATH"
export LDFLAGS="${LDFLAGS:-} -L${BREW_HOME}/opt/openssl@3/lib"
export CPPFLAGS="${CPPFLAGS:-} -I${BREW_HOME}/opt/openssl@3/include"
export PKG_CONFIG_PATH="${BREW_HOME}/opt/openssl@3/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
```

**When to add what:**
- **PATH**: If the formula provides binaries you want to use
- **LDFLAGS**: If other software needs to link against its libraries
- **CPPFLAGS**: If other software needs to compile against its headers
- **PKG_CONFIG_PATH**: If the formula provides `.pc` files for pkg-config

**Special cases requiring `.linuxify` updates:**

Some non-keg-only formulas also need PATH updates if their binaries are in non-standard locations (e.g., `coreutils` installs to `libexec/gnubin` to avoid conflicts).

#### Step 3: Update README.md

Add the tool to the "Tool inventory" section under the appropriate category with a brief description.

#### Testing your changes

1. **Test installation**: `./linuxify install`
2. **Test both modes**: Standalone (`~/linuxify/`) and embedded (`*/scripts/linuxify/`)
3. **Verify PATH**: `which your-command` shows the Homebrew version
4. **Test builds**: If adding libraries, verify software can compile against them

### General contribution guidelines

When updating this consolidated version:

1. **Test both modes**: Standalone and embedded operation
2. **Verify tool lists**: Ensure all tools install correctly
3. **Check integrations**: Test with existing `.envrc` and shell configs
4. **Update documentation**: Keep README current with changes
5. **Coordinate changes**: Keep `linuxify` and `.linuxify` in sync

&nbsp;

## License

MIT License - see LICENSE file for details.
