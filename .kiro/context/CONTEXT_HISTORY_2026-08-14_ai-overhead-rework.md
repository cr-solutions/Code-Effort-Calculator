# Context History: AI Overhead & Complexity Factor Rework

**Date:** 2026-08-14
**Task:** Rework AI overhead formula and complexity factors for realistic effort sizing

---

## Summary

Complete rework of the effort calculator's AI overhead model and complexity factors to produce realistic, fair estimates suitable for client billing — not too low (team doesn't undercharge) and not too high (customers don't overpay).

---

## Decisions Made

### 1. AI Overhead Formula (main fix)

**Problem:** AI overhead was computed against `base_effort` (raw LOC ÷ rate). For small tasks, the floor-based overhead was 5-20× larger than actual coding savings, making AI appear counterproductive.

**Solution:**
- Overhead now computed against `coding_effort_no_ai` (after complexity/familiarity/coupling/churn/testing multipliers)
- Percentages doubled (10%/20%/30% vs old 5%/10%/15%) to compensate for smaller base
- Floors halved (30min/1h/2h × scope_scale vs old 1h/2h/4h)
- Added **80% savings cap**: `overhead = min(overhead, savings × 0.80)` — AI can never make estimates worse

### 2. Refactoring Complexity Factors

**Problem:** Old factors (1.0/1.3/1.8) implied refactoring equals or exceeds writing from scratch.

**Solution:** Reduced to `0.4 / 0.6 / 0.85`. Refactoring reuses existing logic — you reorganize, you don't reinvent.

### 3. Bugfix Complexity Factors

**Problem:** Deep bugfix at ×0.5 was too high — you READ a lot but CHANGE little.

**Solution:** Adjusted to `0.1 / 0.2 / 0.35`.

### 4. Version Compatibility Factors + Migration Research

**Problem:** Version migration estimates were too low because LOC doesn't capture changelog reading, API investigation, and trial-and-error.

**Solution:**
- Slightly reduced factors: `0.25 / 0.45 / 0.7` (was `0.3 / 0.5 / 0.8`)
- Added automatic **migration research overhead** (2h/4h/6h based on complexity) for `type=version` tasks
- AI reduces migration research: None=×1.0, Light=×0.85, Moderate=×0.60, Heavy=×0.40 (AI reads changelogs and identifies affected code, you verify)

### 5. Preset Key Renumbering (doc, ai)

**Problem:** `doc=1` and `ai=1` meant "none", inconsistent with `functest=0` meaning "none".

**Solution:** Both now use `0` for "none": `doc=0-3`, `ai=0-3`.

---

## Files Changed

| File | Change |
|------|--------|
| `code_effort_calculator.bash` | AI overhead formula, complexity factors, migration research, preset numbering |
| `README.md` | Full documentation rewrite reflecting all changes |
| `CHANGELOG.md` | Created — documents breaking changes and rationale |
| `.gitignore` | Created — excludes `.history/` |

---

## Verification

- Tested small file (23 LOC Python) across all AI levels: overhead capped correctly, AI never makes things worse
- Tested large project (1570 LOC PHP) across all work types × complexity levels × AI levels
- Tested version migration with research overhead: estimates now match gut-feel (~17h for major version compat)
- Tested invalid preset values: proper error messages with new valid ranges
- Interactive mode unchanged (still uses menu selection 1-4)

---

## Open / Future Considerations

- Consider adding per-language AI effectiveness factors (AI is better at Python than at Rust)
- Could add a "confidence interval" output (optimistic/pessimistic range)
- History CSV schema changed — old files need deletion or migration
