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

## Adding Options

### Option Definition (script/greple:215-382)
- Defined via `newopt` function; stored as spec/handler pairs in `@optargs`
- Organized by section: PATTERN, MATCH, STYLE, COLOR, REGION, FILE, OTHER
- Boolean: `'name|X !'`, string: `'name|X =s'`, integer: `'name|X =i'`
- Parsed by Getopt::Long with bundling, no_getopt_compat, no_ignore_case

### Option Processing Flow (script/greple)
1. Option parsing (~line 443)
2. Encoding setup (~line 550)
3. **Pre-processing for new options** (~line 556) — implicit settings go here
4. Pattern construction (~line 565) — takes first ARGV as pattern if `@opt_pattern` is empty
5. Count calculation (~line 610) — `$count_must`, `$count_need`, `$count_allow`
6. Filter setup (~line 680)
7. Color setup (~line 720)
8. Grep execution loop (~line 1117)
9. Exit — `exit($opt_exit // ($stat{match_effective} == 0))`

### Controlling Pattern Requirement
- Lines 569-571: if no positive pattern in `@opt_pattern`, first ARGV is taken as pattern
- Adding a flag to the `unless` condition can bypass this requirement
- Modules (`-M`) cannot bypass this logic from outside the main script

## Grep Engine (lib/App/Greple/Grep.pm)

### Processing Flow: `run` → `prepare` → `compose`

#### prepare
1. Execute pattern matching → build `@result` and `@blocks`
2. Region selection via `--inside`/`--outside`
3. Region filtering via `--include`/`--exclude`
4. BLOCKS construction: generate blocks from match ranges; `[0, length]` when nothing matched
5. Build match table: POSI/NEGA/MUST counts per block

#### compose
- Filter blocks by `need`, `must`, `allow`
- When `need < 0`: `compromize = abs(need)` tolerates unmatched required patterns
- `--all`: replaces first block with `[0, length]` to cover entire content

### Match Table Constants
```
POSI_POSI(0), POSI_NEGA(1), POSI_LIST(2)  # positive patterns
NEGA_POSI(3), NEGA_NEGA(4), NEGA_LIST(5)  # negative patterns
MUST_POSI(6), MUST_NEGA(7), MUST_LIST(8)  # required patterns
```

### How --need=0 Works
- `$count_need = $1 - $must` → when must=0, need=0
- In compose, `POSI_POSI >= 0` is always true → all blocks become effective
- Output is produced even with no matches

## Test Framework

Tests use `prove` with a custom runner (`t/runner/Runner.pm`) that wraps script execution. Test files follow the pattern `t/NN_name.t`.

- `t/Util.pm`: `run()`, `greple()`, `line()` helpers
- `run('options file')->stdout` for output, `->status` for exit code
- `line(n)`: regex expecting n lines — `qr/\A(?:.*\n){n}\z/`
- **Do not use `setstdin()`** — causes hangs in `minil dist` environment

## Module System

greple has a powerful module system invoked with `-M`:
- Modules are loaded from `App::Greple::*` namespace
- Module `__DATA__` sections define options using the same syntax as `~/.greplerc`
- Functions defined in modules can be used in options (e.g., `--inside '&function'`)
- `builtin` enables Perl code invocation from option definitions
- Modules cannot control main script logic (e.g., pattern requirement)

## Configuration

- User configuration: `~/.greplerc`
- Supports `option`, `define`, `expand`, `help`, `builtin`, and `autoload` directives
- Perl code after `__PERL__` line in config files is evaluated

## Debugging
- `-d g`: display grep engine match table
- `-d o`: display original ARGV
- `-d m`: display search pattern details
- `-d f`: display file names being processed

## Known Issues

### `@-`/`@+` Performance with UTF-8

In `Regions.pm`, we avoid using `$-[0]`/`$+[0]` and instead use `pos()` with `${^MATCH}` because accessing `@-`/`@+` is extremely slow with UTF-8 text.

**Benchmark results (Perl 5.34, 50000 matches on UTF-8 text):**
- Using `@-`/`@+`: 42.3 sec
- Using `pos()`/`${^MATCH}`: 0.012 sec
- Ratio: ~3500x slower

With ASCII text the difference is only ~1.4x, but UTF-8 triggers severe performance degradation.

This issue exists since at least Perl 5.12 and is still not fixed in Perl 5.34. Not yet reported to perl5 issue tracker.

Reference: https://qiita.com/kaz-utashiro/items/2facc87ea9ba25e81cd9
