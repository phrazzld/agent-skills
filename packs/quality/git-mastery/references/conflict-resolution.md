# Distributed Conflict Resolution

Async-first patterns for resolving conflicts without synchronous coordination.

## CODEOWNERS-Based Assignment

Create `.github/CODEOWNERS`:
```
# Each line: pattern + owners
/src/auth/        @auth-team
/src/api/         @api-team
*.sql             @dba-team
```

Conflicts auto-assigned to file owners. No Slack required.

## Pre-Merge Conflict Detection

Detect conflicts in CI before approval:
```yaml
- name: Conflict Check
  run: |
    git fetch origin main
    if ! git merge-tree $(git merge-base HEAD origin/main) HEAD origin/main | grep -q "^<<<<<<"; then
      echo "No conflicts"
    else
      echo "Conflicts detected - rebase required"
      exit 1
    fi
```

## Resolution Workflow

1. **Detect early**: CI runs conflict check on every push
2. **Auto-assign**: CODEOWNERS routes to right person
3. **Context-rich**: PR includes enough info for async review
4. **Rebase frequently**: Daily `git pull --rebase origin main` minimizes drift

## Semantic Merge Tools

Language-aware merging reduces false conflicts:
```bash
# .gitattributes
*.ts merge=union
*.json merge=union
```

For complex merges, use semantic-merge tools that understand AST.

## Recovery Patterns

```bash
# Abort failed rebase
git rebase --abort

# Undo last merge
git reset --hard HEAD~1

# Recover lost commits
git reflog
git cherry-pick <sha>
```
