---
name: preflight-scan
description: >
  Preflight scan for secrets, private data, and work-related content before committing dotfiles changes.
  Run after making significant changes to detect leaks before they reach the public repo.
---

# Preflight Scan

Scan all pending changes (modified live files or git-staged content) for private data, secrets, and work-related content that must not reach the public dotfiles repo.

## When to Invoke

- After making significant edits to deployed config files
- Before the user integrates changes back into chezmoi source
- When explicitly asked to review changes for safety

## Procedure

### 1. Gather Changed Files

Run **both** of the following to collect the full set of changes:

```bash
# Live files that differ from chezmoi source
chezmoi status

# Git working tree changes in the chezmoi repo
git -C ~/.local/share/chezmoi status --short
```

For each changed file, read its content (or diff) to inspect.

### 2. Scan for Violations

Check every changed file and diff hunk for ALL of the following categories:

#### Secrets & Credentials
- API keys, tokens, passwords, passphrases
- SSH private keys or key material
- OAuth client secrets, bearer tokens, JWTs
- Database connection strings with credentials
- Cloud provider credentials (AWS, GCP, Azure)
- `.env`-style `KEY=value` lines where the value looks like a secret

#### Private / Personal Data
- Email addresses (other than public/expected ones)
- IP addresses, internal hostnames, private network ranges
- Filesystem paths that reveal private directory structures (e.g. `/Users/<name>/Company/...`)
- Personal identifiers, phone numbers, physical addresses

#### Work / Employer Content
- Company names, internal project names, product codenames
- Internal URLs, intranet hostnames, VPN endpoints
- Work email domains
- References to internal tools, repos, or infrastructure
- Proprietary configuration fragments

#### Accident Patterns
- Large binary blobs or encoded data that shouldn't be in dotfiles
- Files that look auto-generated or dumped (cookies, tokens, caches, history)
- Temporary debug values left in configs (e.g. `password = "testing123"`)

### 3. Report

Output a structured report:

```
## Preflight Scan Results

**Files scanned**: <count>
**Status**: PASS | FAIL

### Findings (if any)
| File | Line | Category | Detail |
|------|------|----------|--------|
| ... | ... | ... | ... |

### Recommendation
<what to fix before proceeding>
```

- If **PASS**: confirm it is safe to proceed.
- If **FAIL**: list every finding and recommend specific fixes. Do NOT proceed with further changes until the user addresses the findings.

## Rules

1. **Err on the side of caution** — flag anything suspicious, even if uncertain.
2. **Never auto-fix secrets** — report them; let the user decide how to handle.
3. **Check both directions** — content being added AND content being removed (removed secrets in diffs still appear in git history).
4. **Treat all credential-like strings as real** — do not assume example/placeholder values are safe.
