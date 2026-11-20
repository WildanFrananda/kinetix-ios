## Summary

- What changed and why:

## Verification Checklist

- [ ] `./bin/ci` passes (`AGENTS.md`/`CLAUDE.md` parity, `swift-format lint --strict`, `KinetixKit` tests, `KinetixTests` on Simulator, Release simulator build)
- [ ] Zero comments in `.swift` and `.xcconfig` files, 100% English identifiers, and `en` + `id` copy in `Localizable.xcstrings`
- [ ] Hand-written fakes in `KinetixFakes` used for all new tests (no mocking frameworks) and `#Preview` carries no domain data (IOS-D18)
- [ ] Appended to the log in `AGENTS.md` §0.2 and synced `CLAUDE.md` (`cmp AGENTS.md CLAUDE.md`)
