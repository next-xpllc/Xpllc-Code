# git-workflow

when_to_use: |
  User asks about branches, rebases, merge conflicts, cherry-picks, squashing,
  PRs, reverting, or "I messed up my git history".

## Golden rules

1. **`git reflog` is your time machine.** Nothing is truly lost for 90 days.
2. **Never force-push shared branches** (main, release/*). Force-pushing your
   own feature branch is fine if you announce it on the PR.
3. **Small commits > big commits.** Reviewers parse commits, not files.
4. **Rebase on your own branch. Merge on trunk.**
5. **The commit message is a letter to the developer reading this in 3 years.**
   That developer is usually you. Be kind.

## Common procedures

### Starting a new branch
```bash
bash ~/.config/xpllc-code/scripts/linux_tools.sh fresh_branch feat/my-thing
```
This fetches origin, verifies no uncommitted changes, and branches from
`origin/main`. Never from your stale local `main`.

### The "I committed to main by accident" recovery
```bash
# Still on main with the bad commit as HEAD
git branch feat/rescue                 # save the work
git reset --hard origin/main           # restore main to clean state
git checkout feat/rescue               # continue work on the feature branch
```

### Cleaning up commit history before a PR
```bash
git rebase -i origin/main
# In the editor:
#   pick   = keep as-is
#   reword = keep diff, edit message
#   squash = combine into previous commit
#   fixup  = combine, discard this message
#   drop   = remove entirely
```
**Never squash your PR into 1 commit if the logical steps add review value.**
2–5 well-named commits on a PR is a gift to the reviewer.

### Recovering a lost commit
```bash
git reflog                              # find the dropped SHA
git cherry-pick <sha>                   # bring it back
```

### Resolving a merge conflict — principled approach
1. `git status` — see which files are conflicted.
2. For each file: open it, find `<<<<<<<` markers, understand **what each side meant**.
   If you can't articulate intent from both sides, stop and ask whoever wrote
   the other side. Random merging loses information.
3. `git add <file>` once resolved.
4. `git rebase --continue` (or `git merge --continue`).
5. Run the test suite before the final commit.

### Signing off commits (DCO / contributor agreements)
```bash
git commit -s -m "feat: …"
```

## Commit message format (Conventional Commits)

```
<type>(<scope>): <subject in imperative mood, ≤50 chars>

<body wrapped at 72 chars explaining the WHY, not the WHAT.>
<The diff already shows what. The message has to explain why.>

<footer: issue refs, breaking change notices, co-authored-by>
```

Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `chore`, `ci`, `build`.

## Anti-patterns to refuse

- `git commit -m "WIP"` → squash or reword before pushing.
- `git commit -m "fix"` — fix what?
- Force-pushing to `main` "to clean up".
- Resolving a conflict by keeping "yours" blindly.
- Merging your branch into `main` locally and pushing (bypasses PR + CI).

## PR hygiene checklist

- [ ] Title follows Conventional Commits format.
- [ ] Description explains WHY, not just what.
- [ ] Linked issue number.
- [ ] Tests added or updated.
- [ ] No unrelated changes (formatting, import reordering, etc).
- [ ] Screenshot / demo for UI changes.
- [ ] Breaking changes called out in a `BREAKING CHANGE:` footer.
