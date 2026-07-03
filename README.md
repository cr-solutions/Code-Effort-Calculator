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
| `-h`, `--help` | Show help message |

### Examples

```bash
# Analyze a single directory
./code_effort_calculator.bash src/

# Analyze multiple paths
./code_effort_calculator.bash src/Controller/ src/Service/ src/Repository/

# Detailed mode: per-file breakdown
./code_effort_calculator.bash -d src/Controller/
```

## How It Works

### Formula

```
final_effort = coding_effort + documentation_overhead + ai_overhead

coding_effort = base_effort × complexity × coupling × churn × testing × ai_reduction
base_effort   = Σ (LOC_per_language ÷ rate_per_language)
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

### 2. Complexity Factor

An interactive selection that classifies the type and difficulty of work:

| Work Type | Level | Factor | Meaning |
|-----------|-------|--------|---------|
| **Enhancement** | Simple | ×0.1 | Trivial change, single function |
| | Normal | ×0.3 | Multi-file change, some logic |
| | Complex | ×0.5 | Architectural impact, many touch-points |
| **Version Compatibility** | Minor Version | ×1.0 | API compatible, incremental updates |
| | Major Version | ×1.5 | Breaking changes, migration work |
| **Refactoring** | Simple | ×2.5 | Rename, extract method |
| | Normal | ×3.0 | Restructure module, change patterns |
| | Complex | ×3.6 | Architecture overhaul, full rewrite |

---

### 3. Coupling Factor

**What it measures**: How interconnected the code is with other modules. Highly coupled code is riskier to modify because changes cascade.

**How it's calculated**: Counts import/dependency statements (`use`, `require`, `import`, `include`, `from X import`, `extern crate`, `#include`, `using`, etc.) per file. For directories, it averages across all files.

| Average Imports/File | Factor | Interpretation |
|---------------------|--------|----------------|
| ≤ 5 | ×1.00 | Low coupling — isolated, safe to modify |
| 6–10 | ×1.15 | Moderate coupling — some ripple risk |
| > 10 | ×1.30 | High coupling — changes likely affect many modules |

**Why it matters**: A file with 15 imports touches 15 other modules. Changing it requires understanding and potentially updating all of them. This overhead isn't captured by LOC alone.

---

### 4. Churn Factor

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

### 5. Testing Overhead

**What it measures**: Additional effort required for creating or updating automated tests.

| Selection | Factor | Added Effort |
|-----------|--------|--------------|
| No | ×1.00 | No additional effort |
| Yes | ×1.30 | +30% to coding effort |

**Why it matters**: Writing proper tests (unit, integration, or e2e) typically adds ~30% to the pure coding effort. This includes writing the tests, setting up fixtures/mocks, and ensuring coverage.

---

### 6. Documentation Overhead

**What it measures**: Fixed time required for documentation updates, added as a flat amount on top of coding effort.

| Level | Added Time | Examples |
|-------|-----------|----------|
| None | +0h | No docs needed |
| Minor | +1h | Changelog entries, inline code comments |
| Standard | +3h | README updates, API documentation |
| Extensive | +6h | Architecture docs, developer guides, specs |

**Why it's additive**: Documentation effort doesn't scale with code complexity — writing a README takes roughly the same time whether the feature was 100 or 1000 lines.

---

### 7. AI-Assisted Development (LLM)

**What it measures**: The impact of using AI tools (like Claude Opus, GPT-4, GitHub Copilot) on development effort. This has two components:

1. **Coding reduction** — a multiplier that reduces the coding effort
2. **AI overhead** — fixed time added for prompt engineering, review, and validation

| Level | Coding Factor | Overhead | Net Impact |
|-------|--------------|----------|------------|
| No AI | ×1.00 | +0h | Full manual effort |
| Light | ×0.85 (−15%) | +1h | Autocomplete, suggestions |
| Moderate | ×0.65 (−35%) | +2h | Feature generation, refactoring |
| Heavy (Agentic) | ×0.45 (−55%) | +4h | Full RE workflow, agentic AI |

#### What the AI overhead covers:

- **Requirements Engineering**: Structuring prompts, defining acceptance criteria
- **Prompt crafting**: Iterating on prompts to get correct output
- **Code review**: Validating AI-generated code for correctness, security, style
- **Integration**: Adapting generated code to fit the existing architecture
- **Agentic workflow setup**: Configuring and managing multi-step AI workflows

The "Heavy" level assumes use of structured Requirements Engineering workflows such as [Requirements-Engineering-Agentic-AI](https://github.com/cr-solutions/Requirements-Engineering-Agentic-AI).

**Why both factors exist**: AI dramatically reduces raw coding time, but introduces new overhead for steering the AI correctly. The net effect is still positive for larger tasks but may not save time for trivial changes.

---

### 8. Minimum Effort Floor

Any estimate below **0.25 days (2 hours)** is automatically raised to the floor. This accounts for irreducible overhead:

- Context switching (reading existing code, understanding the task)
- Development environment setup
- Code review / PR process
- Deployment and verification

Even a one-line fix requires these steps.

---

## Output

### Terminal Display

The tool provides a colored, structured output with:
- Per-language LOC table with rates
- Base effort breakdown per language (days + hours/minutes)
- Automated analysis results (coupling, churn)
- Interactive selections (work type, tests, docs, AI)
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
| `coupling_factor` | Dependency coupling |
| `churn_factor` | Git history factor |
| `testing_factor` | Testing overhead |
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

## License

CDDL-1.1 — See file header for full license text.
