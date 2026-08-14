# Project Rules: Code Effort Calculator

## Release Process
- Always update the version number in the script output (both usage header and startup banner) when making changes.
- Keep `CHANGELOG.md` up to date with every change — document breaking changes, fixes, and new features.
- Keep `README.md` in sync with the actual implementation — all factors, formulas, and preset keys must match the code.
- Update `.kiro/context/CONTEXT_HISTORY_*.md` for significant changes.

## Design Principles
- **AI affects all effort components**: When adding or modifying any effort component, consider how AI assistance impacts it. Currently AI reduces: coding effort, unit testing factor, documentation overhead, and migration research. Functional testing is reduced indirectly (based on reduced coding effort).
- **Additive overheads must be justified**: Fixed time additions (doc, migration R&D, functest buffer) should have clear real-world activities they represent.
- **AI must never make estimates worse**: The 80% savings cap ensures AI always provides a net benefit. Any new AI-related overhead must respect this invariant.
- **0 = none for all preset keys**: All optional additive features use `0` to mean "disabled/none" (functest, doc, ai). Don't introduce `1` as "none" for new keys.
- **Floors scale with scope**: Minimum floors for overheads are reduced for single-file and small-directory scopes (×0.25, ×0.50). Only version and refactoring types use full floors regardless of scope.

## Testing Changes
- After modifying calculations, test with both a small single file (~23 LOC) and a larger project (~1500 LOC).
- Verify all AI levels (0-3) produce a smooth, decreasing progression.
- Verify all work types × complexity levels produce realistic estimates.
- Confirm the minimum effort floor (2h) still applies for trivially small tasks.

## Code Style
- Shell script follows existing formatting (2-space function body indent is not used — match existing style).
- Use `awk` for floating-point math, `bc` only when needed.
- Keep ANSI color codes consistent with existing definitions.
- Comments explain the "why" — especially for factor values and formula design decisions.
