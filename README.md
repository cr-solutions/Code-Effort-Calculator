# Code Effort Calculator

A bash-based tool that estimates development effort for code projects by analyzing lines of code, language complexity, git history, and additional workflow factors including or excluding the use of AI.

## Usage

```bash
./code_effort_calculator.bash [OPTIONS] <file_or_directory> ...
```

### Options

| Flag | Description |
|------|-------------|
| `-d`, `--detailed` | Evaluate each file separately instead of aggregating |
| `-p`, `--preset` `KEY=VAL,...` | Non-interactive mode with explicit factors |
| `-h`, `--help` | Show help message |

### Examples

```bash
# Analyze a single directory
./code_effort_calculator.bash src/

# Analyze multiple paths
./code_effort_calculator.bash src/Controller/ src/Service/ src/Repository/

# Detailed mode: per-file breakdown
./code_effort_calculator.bash -d src/Controller/

# Non-interactive with preset factors
./code_effort_calculator.bash -p "type=version,complexity=2,familiarity=2,unittest=y,functest=3,ai=3" src/

# Only override what you need — rest stays at defaults
./code_effort_calculator.bash -p "type=bugfix,complexity=1" src/
```

## How It Works

### Formula

```
final_effort = coding_effort + functest_effort + documentation_overhead + ai_overhead

coding_effort  = base_effort × complexity × familiarity × coupling × churn × unittest × ai_reduction
functest_effort = (coding_effort × functest_factor) + functest_buffer
base_effort    = Σ (LOC_per_language ÷ rate_per_language)
```

---

## Factors Explained

### 1. Lines of Code (LOC) & Per-Language Rates

The tool uses `cloc` to count lines of code per language (excluding comments and blanks). Each language has a different **LOC/day rate** reflecting how many lines a developer can reasonably work through per day. Lower rates mean the language is harder to work with per line.

| Language | Rate | Rationale |
|----------|------|-----------|
| C | 280 | Manual memory management, pointers, low-level |
| C++ | 300 | C complexity + templates, OOP, STL |
| Rust | 300 | Strict ownership/borrow system, lifetimes |
| Go | 350 | Explicit error handling, concurrency patterns |
| Scala | 350 | Mixed FP + OOP, complex type system |
| TypeScript | 380 | Strict type system on top of JS |
| Swift | 380 | Protocol-oriented, strict typing |
| JavaScript | 400 | Async/callback complexity, dynamic |
| Kotlin | 400 | Concise JVM language, null safety |
| Dart | 420 | Flutter/typed, moderate complexity |
| Java | 450 | Verbose, boilerplate-heavy |
| C# | 450 | Similar to Java in structure |
| PHP | 500 | Web-focused, moderate complexity |
| Shell/Bash | 500 | Scripting, but brittle syntax |
| Ruby | 550 | Dynamic, expressive, convention-heavy |
| Python | 600 | Concise, dynamic, fastest per line |
| SQL | 600 | Declarative queries |
| Twig | 800 | Template engine, mostly declarative |
| Jinja2 | 800 | Template engine, mostly declarative |
| CSS/SCSS | 900 | Styling, declarative |
| YAML | 900 | Configuration, declarative |
| HTML | 1000 | Markup, fully declarative |

#### Template/Markup Weighting

Template and markup languages (Twig, Jinja2, HTML, CSS, YAML) use a graduated weighting system rather than counting at full value:

- **> 500 lines**: 30% of LOC is counted
- **101–500 lines**: 15% of LOC is counted
- **≤ 100 lines**: Not counted (negligible effort)

This reflects that template changes are typically simpler than logic changes.

---

### 2. Complexity Factor (Work Type)

An interactive selection that classifies the type and difficulty of work:

| Work Type | Level | # | Factor | Meaning |
|-----------|-------|---|--------|---------|
| **Enhancement** | Simple | 1 | ×0.2 | Small addition, single function or endpoint |
| | Normal | 2 | ×0.4 | Multi-file change, moderate logic |
| | Complex | 3 | ×0.6 | Architectural impact, many touch-points |
| **Bugfix** | Trivial | 1 | ×0.1 | Quick patch, obvious root cause |
| | Moderate | 2 | ×0.25 | Requires investigation, touches multiple files |
| | Deep | 3 | ×0.5 | Root cause hunting, systemic issue |
| **Version Compatibility** | Minor (<30% affected) | 1 | ×0.3 | Few API changes, mostly compatible |
| | Major (30-60% affected) | 2 | ×0.5 | Significant migration, pattern-based changes |
| | Full (>60% affected) | 3 | ×0.8 | Near-complete adaptation required |
| **Refactoring** | Simple | 1 | ×1.0 | Rename, extract method, move class |
| | Normal | 2 | ×1.3 | Restructure module, change patterns |
| | Complex | 3 | ×1.8 | Architecture overhaul, deep redesign |

The `#` column corresponds to the `complexity` value used in `--preset`.

#### Design Rationale

- **Enhancement/Bugfix factors are < 1.0** because you're modifying existing code, not writing all of it from scratch. A "Normal Enhancement" touches roughly 40% of the cognitive load that writing it fresh would require.
- **Version Compatibility factors reflect that migrations are largely mechanical** — API renames, deprecation replacements, namespace shifts. Even "Major" (30-60% affected) uses ×0.5 because most changes are pattern-based rather than creative.
- **Refactoring factors are ≥ 1.0** because restructuring requires understanding the existing design *and* creating a new one. Complex refactoring (×1.8) is significant but never exceeds writing-from-scratch effort (which would be the base effort itself).

> **Tip — Breaking API migrations**: For framework upgrades that constitute a complete API overhaul (e.g. Vue 2→3, Angular.js→Angular, Python 2→3), consider using `type=refactoring,complexity=2` (×1.3) instead of `type=version,complexity=3` (×0.8). Version Compatibility assumes largely mechanical, pattern-based changes. When the migration requires learning a fundamentally new paradigm (Composition API, new reactivity model, removed core features), the refactoring type better reflects the cognitive load involved.

---

### 3. Codebase Familiarity

**What it measures**: How well the developer knows the code being modified. One of the biggest real-world productivity multipliers.

| Level | Factor | Interpretation |
|-------|--------|----------------|
| Own code (wrote it myself) | ×1.00 | Full context, no ramp-up needed |
| Team code (familiar, reviewed it) | ×1.15 | Small overhead for context gaps |
| Inherited (read it, know the gist) | ×1.40 | Significant reading/understanding time |
| Unknown (never seen before) | ×1.70 | Major ramp-up cost, documentation diving |

**Why it matters**: A developer modifying their own code operates at full speed. The same task on a completely unknown codebase takes 70% longer due to understanding the architecture, conventions, implicit assumptions, and undocumented behaviour.

---

### 4. Coupling Factor

**What it measures**: How interconnected the code is with other modules. Highly coupled code is riskier to modify because changes cascade.

**How it's calculated**: Counts import/dependency statements (`use`, `require`, `import`, `include`, `from X import`, `extern crate`, `#include`, `using`, etc.) per file. For directories, it averages across all files.

| Average Imports/File | Factor | Interpretation |
|---------------------|--------|----------------|
| ≤ 5 | ×1.00 | Low coupling — isolated, safe to modify |
| 6–10 | ×1.15 | Moderate coupling — some ripple risk |
| > 10 | ×1.30 | High coupling — changes likely affect many modules |

**Why it matters**: A file with 15 imports touches 15 other modules. Changing it requires understanding and potentially updating all of them. This overhead isn't captured by LOC alone.

---

### 5. Churn Factor

**What it measures**: How frequently the code has been modified historically, based on git commit count.

**How it's calculated**: Counts the number of git commits that touched the file(s). For directories, averages across all source files.

| Commit Count | Factor | Interpretation |
|-------------|--------|----------------|
| ≤ 20 | ×1.00 | Stable code — low risk |
| 21–50 | ×1.10 | Moderate churn — some accumulated complexity |
| > 50 | ×1.20 | High churn — likely tech debt, workarounds, edge cases |

**Why it matters**: Files that have been modified 50+ times often contain accumulated workarounds, undocumented edge cases, and implicit dependencies that make them harder to work with than their LOC would suggest. High churn is a strong indicator of hidden complexity.

**Note**: If the path is not inside a git repository, this factor defaults to ×1.00.

---

### 6. Testing Overhead

#### 6a. Unit/Integration Testing (Automated)

**What it measures**: Additional effort required for creating or updating automated tests.

| Selection | Factor | Added Effort |
|-----------|--------|--------------|
| No | ×1.00 | No additional effort |
| Yes | ×1.30 | +30% to coding effort |

**Preset key**: `unittest=y` or `unittest=n` (also accepts legacy `testing=y/n` for backward compatibility)

**Why it matters**: Writing proper automated tests (unit, integration, or e2e suites) typically adds ~30% to the pure coding effort. This includes writing the tests, setting up fixtures/mocks, and ensuring coverage.

#### 6b. Functional Testing (Manual/QA)

**What it measures**: Effort for manual functional testing and QA — running through test scenarios, verifying behavior across environments, and documenting results. This is additive to coding effort.

**Formula**: `functest_effort = (coding_effort × factor) + fixed_buffer`

| Level | Factor | Buffer | Total Example (10h coding) | Use Case |
|-------|--------|--------|---------------------------|----------|
| None | — | — | +0h | No manual testing needed |
| Basic | ×0.30 | +1.0h | +4.0h | Backend-only, internal logic, happy path |
| Standard | ×0.35 | +1.5h | +5.0h | Mixed frontend/backend, API calls |
| Complex | ×0.50 | +2.0h | +7.0h | UI + third-party APIs, multi-browser, multi-env |

**Preset key**: `functest=0` (none), `functest=1` (basic), `functest=2` (standard), `functest=3` (complex)

**Why the factor varies by level** (factor range 0.3x–0.5x based on Microsoft's internal QA research from the "Code Complete" era, validated against real-world plugin agency experience):

- **Basic (0.3x)**: Pure backend plugins with internal logic are fast to verify — a few API calls or CLI commands cover the happy path and edge cases.
- **Standard (0.35x)**: When frontend components or API integrations are involved, testing requires more workflows, form validation, and error handling verification.
- **Complex (0.5x)**: Third-party API sandboxes, multi-browser testing, responsive checks, multiple CMS/framework versions, and permission matrices all compound the effort significantly.

**Why a fixed buffer exists**: Regardless of coding size, every functional testing cycle has irreducible setup time — configuring test data, spinning up sandbox environments, documenting test results. This costs 1–2 hours whether the plugin is trivial or large.

**Design note**: Both unit testing (×1.30 multiplier) and functional testing (additive) can be active simultaneously. A project may need automated test coverage *and* manual QA. They're independent costs that address different quality dimensions.

> **Tip — Playwright / AI-assisted functional testing**: If functional tests are automated with tools like Playwright or generated via AI, don't increase `functest` — instead use `unittest=y` + `ai=3` to capture the effort of writing/generating those test scripts. The `functest` level can then drop to `0` or `1` (basic smoke test only), since the automated suite covers the repetitive flows. This keeps each parameter measuring one axis cleanly: `functest` = manual QA scope, `unittest` = automated test code, `ai` = tooling assistance.

---

### 7. Documentation Overhead

**What it measures**: Fixed time required for documentation updates, added as a flat amount on top of coding effort.

| Level | Added Time | Examples |
|-------|-----------|----------|
| None | +0h | No docs needed |
| Minor | +1h | Changelog entries, inline code comments |
| Standard | +3h | README updates, API documentation |
| Extensive | +6h | Architecture docs, developer guides, specs |

**Why it's additive**: Documentation effort doesn't scale with code complexity — writing a README takes roughly the same time whether the feature was 100 or 1000 lines.

---

### 8. AI-Assisted Development (LLM)

**What it measures**: The impact of using AI tools (like Claude Opus, GPT-4, GitHub Copilot) on development effort. This has two components:

1. **Coding reduction** — a multiplier that reduces the coding effort
2. **AI overhead** — time added for prompt engineering, review, and validation (scales with project size)

| Level | Coding Factor | Overhead | Net Impact |
|-------|--------------|----------|------------|
| No AI | ×1.00 | +0h | Full manual effort |
| Light | ×0.85 (−15%) | min 1h, or 5% of base | Autocomplete, suggestions |
| Moderate | ×0.65 (−35%) | min 2h, or 10% of base | Feature generation, refactoring |
| Heavy (Agentic) | ×0.45 (−55%) | min 4h, or 15% of base | Full RE workflow, agentic AI |

#### Scaling AI Overhead

Unlike v2.0 (which used fixed overhead), the AI overhead now scales with project size. For a 1-day base effort, the minimum floors apply (1h/2h/4h). For a 10-day base effort, overhead grows proportionally (4h/8h/12h) because larger projects require more prompt iteration, review cycles, and integration work.

#### What the AI overhead covers:

- **Requirements Engineering**: Structuring prompts, defining acceptance criteria
- **Prompt crafting**: Iterating on prompts to get correct output
- **Code review**: Validating AI-generated code for correctness, security, style
- **Integration**: Adapting generated code to fit the existing architecture
- **Agentic workflow setup**: Configuring and managing multi-step AI workflows

The "Heavy" level assumes use of structured Requirements Engineering workflows such as [Requirements-Engineering-Agentic-AI](https://github.com/cr-solutions/Requirements-Engineering-Agentic-AI).

**Why both factors exist**: AI dramatically reduces raw coding time, but introduces new overhead for steering the AI correctly. The net effect is still positive for larger tasks but may not save time for trivial changes.

---

### 9. Minimum Effort Floor

Any estimate below **0.25 days (2 hours)** is automatically raised to the floor. This accounts for irreducible overhead:

- Context switching (reading existing code, understanding the task)
- Development environment setup
- Code review / PR process
- Deployment and verification

Even a one-line fix requires these steps.

---

## Presets (Non-Interactive Mode)

The `-p` / `--preset` flag runs the tool without prompts, using the factors you specify. Unspecified keys use sensible defaults.

### Preset Keys

| Key | Values | Default |
|-----|--------|---------|
| `type` | `enhancement`, `bugfix`, `version`, `refactoring` | `enhancement` |
| `complexity` | `1`, `2`, `3` (maps to the levels per work type) | `2` |
| `familiarity` | `1`=own, `2`=team, `3`=inherited, `4`=unknown | `1` |
| `unittest` | `y` or `n` (automated unit/integration tests) | `n` |
| `functest` | `0`=none, `1`=basic, `2`=standard, `3`=complex | `0` |
| `doc` | `1`=none, `2`=minor, `3`=standard, `4`=extensive | `1` |
| `ai` | `1`=none, `2`=light, `3`=moderate, `4`=heavy | `1` |

> **Backward compatibility**: The legacy key `testing=y/n` still works and maps to `unittest`.

---

## Output

### Terminal Display

The tool provides a colored, structured output with:
- Per-language LOC table with rates
- Base effort breakdown per language (days + hours/minutes)
- Automated analysis results (coupling, churn)
- Interactive selections (work type, familiarity, tests, docs, AI)
- Final calculation box with full factor breakdown
- Tree-style summary

### CSV History

Every estimate is logged to `~/.effort_history.csv` for historical calibration. Columns include:

| Column | Description |
|--------|-------------|
| `date` | ISO 8601 timestamp |
| `timestamp_unix` | Unix epoch |
| `path` | Full analyzed path |
| `basename` | Short name |
| `total_weighted_loc` | Combined weighted LOC |
| `php` through `yaml` | Per-language raw LOC (22 columns) |
| `work_type` | Selected complexity type |
| `complexity_factor` | Work type multiplier |
| `familiarity_factor` | Codebase familiarity multiplier |
| `coupling_factor` | Dependency coupling |
| `churn_factor` | Git history factor |
| `testing_factor` | Unit testing overhead |
| `functest_level` | Functional testing level selected |
| `functest_effort_days` | Functional testing time added |
| `ai_coding_factor` | AI reduction multiplier |
| `ai_level` | AI assistance level selected |
| `ai_overhead_days` | AI overhead added |
| `doc_level` | Documentation level selected |
| `doc_effort_days` | Documentation time added |
| `base_effort_days` | Before any multipliers |
| `coding_effort_days` | After multipliers, before fixed additions |
| `estimated_days` | Final total estimate |
| `estimated_hours` | Final total in hours |
| `floored` | Whether minimum floor was applied |

Use this CSV to compare estimates against actual effort over time and calibrate the rates.

---

## Requirements

- **bash** 4.0+
- **cloc** (auto-installed if missing via `apt`)
- **awk**, **bc** (standard on most Linux systems)
- **git** (optional, for churn factor — gracefully skipped if not in a repo)

## Configuration

All rates and thresholds are defined as variables at the top of the script. Adjust them to match your team's velocity:

```bash
# Example: Your team is faster with Python
PYTHON_RATE=700

# Example: Raise the minimum floor to 4 hours
MIN_EFFORT_DAYS=0.50
```

### Excluded Directories

The tool automatically excludes common dependency/build directories from analysis. These directories contain third-party code that would skew your effort estimation:

```bash
EXCLUDE_DIRS=(vendor node_modules .vendor dist build .git __pycache__ .venv venv)
```

This applies to all three analysis stages:
- **LOC counting** (`cloc --exclude-dir`)
- **Coupling analysis** (`find` with path exclusions)
- **Churn analysis** (`find` with path exclusions)

Add or remove entries as needed for your stack.

## License

CDDL-1.1 — See file header for full license text.
