## What

<!-- One or two sentences: what does this PR change, and why? -->

## Tiers (docs/testing.md)

- [ ] Tier 0/1 (unit/widget) cover the change — coverage floor holds (CI enforces it)
- [ ] Touches `hardware_wallet`/`wallet` paths → Tier 2 (BitBox simulator) runs on this PR
- [ ] UI flow changed → `tier3:full` label set, or post-merge develop run is sufficient because: <!-- why -->
- [ ] Platform-coupled code without integration test carries `// @no-integration-test: <reason>`

## Goldens & handbook

- [ ] No visual change — baselines untouched
- [ ] Baselines regenerated via `golden-regenerate.yaml` (CI re-runs automatically on the bot commit)

## API authority (CONTRIBUTING.md)

- [ ] No new client-side decision logic — server capability flags consumed as-is
- [ ] Pair-PR with the API repo linked here if a capability is consumed: <!-- link -->

## Security checklist

- [ ] Touches signing, key handling, or `pubspec` → code-owner review requested
- [ ] No secret, seed, or PII logged or persisted outside the secure storage paths
- [ ] New dependency added → justified here: <!-- why this package? -->
