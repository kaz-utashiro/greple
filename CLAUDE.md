# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**greple** is an extensible grep-like tool written in Perl, featuring lexical expression support and region control. It's published as the CPAN distribution `App-Greple`.

## Build and Test Commands

This project uses [Minilla](https://metacpan.org/pod/Minilla) with Module::Build::Tiny:

```bash
# Install dependencies
cpanm --installdeps .

# Build the distribution
minil build

# Run all tests
prove -l t/

# Run a single test file
prove -l t/02_search.t

# Run tests with verbose output
prove -lv t/

# Run the command directly during development
perl -Ilib script/greple [options] pattern [files...]
```

## Architecture

### Entry Point
- `script/greple` - Main executable script containing option parsing and the command-line interface

### Core Modules (lib/App/Greple/)
- `Greple.pm` - Version and package declaration only
- `Grep.pm` - Core grep engine with pattern matching logic; defines `App::Greple::Grep::Block`, `::Match`, and `::Result` classes; handles `group_index` parameter (0=off, 1=group, 2=sequential, 3=per-pattern)
- `Pattern.pm` and `Pattern/Holder.pm` - Pattern object management
- `Regions.pm` - Region handling for `--inside`, `--outside`, `--include`, `--exclude` options; `match_regions_by_group` returns 0-origin group indices
- `Common.pm` - Shared utilities and constants (exports `FILELABEL`)
- `Filter.pm` - Input/output filter handling
- `Util.pm` - General utilities

### Extension Modules
- `dig.pm`, `find.pm` - Recursive file search modules
- `perl.pm` - Perl-specific search patterns (POD, comments, code)
- `pgp.pm`, `PgpDecryptor.pm` - PGP-encrypted file support
- `colors.pm` - Color scheme definitions
- `select.pm` - File selection module
- `debug.pm` - Debug output control
- `line.pm` - Line-based operations

### Key Dependencies
- `Getopt::EX` - Extended option processing with module support
- `Term::ANSIColor::Concise` - Color output handling

### Test Framework
Tests use `prove` with a custom runner (`t/runner/Runner.pm`) that wraps script execution. Test files follow the pattern `t/NN_name.t`. Note: avoid using `setstdin()` in tests as it may cause hangs in `minil dist` environment.

## Module System

greple has a powerful module system invoked with `-M`:
- Modules are loaded from `App::Greple::*` namespace
- Module `__DATA__` sections define options using the same syntax as `~/.greplerc`
- Functions defined in modules can be used in options (e.g., `--inside '&function'`)

## Configuration

- User configuration: `~/.greplerc`
- Supports `option`, `define`, `expand`, `help`, `builtin`, and `autoload` directives
- Perl code after `__PERL__` line in config files is evaluated
