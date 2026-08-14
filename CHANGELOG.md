# Changelog

## v3.1.0 — 2026-08-14

### Breaking Changes

- **Preset key `doc` renumbered**: Was `1-4` (1=none), now `0-3` (0=none, 1=minor, 2=standard, 3=extensive)
- **Preset key `ai` renumbered**: Was `1-4` (1=none), now `0-3` (0=none, 1=light, 2=moderate, 3=heavy)
- **CSV history schema changed**: New column `migration_research_days` added. Old history files will have misaligned columns — delete `~/.effort_history.csv` to start fresh.

### Fixed

- **AI overhead no longer makes estimates worse than manual coding.** Previous versions computed AI overhead against `base_effort` (raw LOC ÷ rate). This caused absurd results for small tasks: a 3-minute enhancement would get 30-60 minutes of "AI overhead" from the floor alone — making AI appear counterproductive. The formula now uses `coding_effort_without_ai` (after all multipliers) as the basis, and caps overhead at 80% of savings.
- **AI overhead floors recalibrated.** Reduced from 1h/2h/4h to 30min/1h/2h (×scope_scale). The old floors were calibrated against `base_effort` which was always much larger; with the new proportional basis, the higher percentages (10%/20%/30% vs old 5%/10%/15%) already produce reasonable overhead for mid-to-large projects without needing aggressive floors.

### Changed

- **Refactoring complexity factors reduced** from `1.0 / 1.3 / 1.8` to `0.4 / 0.6 / 0.85`. The old values (≥1.0) implied refactoring equals or exceeds writing from scratch, which is unrealistic. Refactoring reuses existing logic and domain knowledge — you reorganize code, you don't reinvent it.
- **Bugfix complexity factors adjusted**: Moderate reduced from `0.25` to `0.2`, Deep reduced from `0.5` to `0.35`. Deep bugs involve extensive investigation (reading 50% of code) but the actual fix is typically small (5-20 lines). The factor now captures the combined investigation + fix effort more accurately.
- **Version Compatibility factors slightly reduced**: Minor `0.3→0.25`, Major `0.5→0.45`, Full `0.8→0.7`. Migrations are largely mechanical (pattern-based find-and-replace). The reduction is compensated by the new migration research overhead (see below).
- **AI overhead percentages doubled** from `5%/10%/15%` to `10%/20%/30%` of `coding_effort_no_ai`. This compensates for the smaller base (coding effort vs raw LOC) and produces realistic overhead values without relying on floor clamping.

### Added

- **Version Migration Research Overhead**: Automatic additive overhead for `type=version` tasks (2h/4h/6h based on complexity). Covers changelog reading, API investigation, trial-and-error, and community research — activities that aren't captured by LOC but are real work in any version migration. AI reduces this overhead (Light ×0.85, Moderate ×0.60, Heavy ×0.40) because AI can read and summarize changelogs and identify affected code.
- **AI reduces documentation effort**: Doc overhead now scales with AI level (Light ×0.80, Moderate ×0.50, Heavy ×0.30). AI can draft documentation from code context — you review and polish instead of writing from scratch.
- **AI reduces unit testing overhead**: Testing factor scales from ×1.30 (no AI) down to ×1.10 (heavy AI). AI excels at generating test boilerplate, mocks, and assertions — tests are more formulaic than production code.
- **Coding effort hint in output**: When AI is active, the calculation breakdown shows `(= steering, review & integration)` below the coding effort line to clarify what that time represents with AI assistance.
- **80% savings cap on AI overhead**: `overhead = min(overhead, savings × 0.80)`. Guarantees that AI always provides a net benefit regardless of task size. For tiny tasks where the floor would dominate, the cap prevents the overhead from exceeding 80% of what the AI actually saves.
- **Consistent 0-based "none" values**: Both `doc` and `ai` preset keys now use `0` for "none", matching the existing `functest=0` convention.

---

## v3.0.0

Initial public release with:
- Per-language LOC rates
- Work type complexity factors
- Familiarity, coupling, churn multipliers
- Unit/integration testing overhead
- Functional testing (manual QA) with buffer
- Documentation overhead
- AI-assisted development with coding reduction + overhead
- Automatic scope scaling for single files
- Minimum effort floor (2h)
- CSV history logging for calibration
