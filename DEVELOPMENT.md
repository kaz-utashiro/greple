# App::Greple Development Notes

## Adding Options

### 1. Option Definition (script/greple:215-382)
- Defined via `newopt` function; stored as spec/handler pairs in `@optargs`
- Organized by section: PATTERN, MATCH, STYLE, COLOR, REGION, FILE, OTHER
- Boolean: `'name|X !'`, string: `'name|X =s'`, integer: `'name|X =i'`
- Parsed by Getopt::Long with bundling, no_getopt_compat, no_ignore_case

### 2. Option Processing Flow (script/greple)
1. Option parsing (~line 443)
2. Encoding setup (~line 550)
3. **Pre-processing for new options** (~line 556) — implicit settings go here
4. Pattern construction (~line 565) — takes first ARGV as pattern if `@opt_pattern` is empty
5. Count calculation (~line 610) — `$count_must`, `$count_need`, `$count_allow`
6. Filter setup (~line 680)
7. Color setup (~line 720)
8. Grep execution loop (~line 1117)
9. Exit — `exit($opt_exit // ($stat{match_effective} == 0))`

### 3. Controlling Pattern Requirement
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

## Testing

### Test Framework
- `t/runner/Runner.pm`: script execution wrapper
- `t/Util.pm`: `run()`, `greple()`, `line()` helpers
- `run('options file')->stdout` for output, `->status` for exit code
- `line(n)`: regex expecting n lines — `qr/\A(?:.*\n){n}\z/`
- File naming: `t/NN_name.t`
- **Do not use `setstdin()`** — causes hangs in `minil dist` environment

### Running Tests
```bash
prove -l t/              # all tests
prove -lv t/02_search.t  # single test, verbose
```

## Module System
- `-Mname` loads `App::Greple::name`
- `__DATA__` section defines options via `option --name ...` (macro expansion)
- `builtin` enables Perl code invocation from option definitions
- Modules cannot control main script logic (e.g., pattern requirement)

## Debugging
- `-d g`: display grep engine match table
- `-d o`: display original ARGV
- `-d m`: display search pattern details
- `-d f`: display file names being processed
