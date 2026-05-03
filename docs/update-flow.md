# Update Flow

Updates pull the latest repository content and reapply artifacts into the target opencode-anycli config directory.

## Standard update

```bash
omac update
```

This runs:

```bash
git pull --ff-only
./install.sh --reapply
```

## Pruning stale artifacts

```bash
omac update --prune
```

This also removes files that were installed previously but no longer exist in the current repository or plugin set. Removal is limited to files listed in `$OMAC_TARGET_DIR/.oh-my-anycli/manifest.txt`.

## Manual equivalent

```bash
cd ~/.oh-my-anycli
git pull --ff-only
./install.sh --reapply --prune
```

## Conflict handling

If `git pull --ff-only` fails, resolve local checkout changes manually before updating. Do not use force reset unless you intentionally want to discard local modifications.

## After update

```bash
omac doctor
omac list -v
```
