# Commit Pass Workflow

## Goal
Based on your knowledge of the project, commit all changed files now in a series of logically connected groupings with super detailed commit messages for each and then push. Take your time to do it right. Don't edit the code at all. Don't commit obviously ephemeral files.

Always commit as atomically as possible. Review ALL beads (tasks) that have been recently completed, or are in progress, and isolate very small commits that encapsulate at most one full task. Don't be afraid to stage single chunks inside files.


## Safe rules
- Never `git add -A`
- Stage explicit paths only
- Review `git diff --cached` before every commit
- If unsure a change is yours, do not stage it

## Suggested grouping
- 1 commit per coherent change (feature, refactor, test fix, docs)
- If you solved multiple tasks, commit each task separately
- Keep beads updates with the relevant code changes
