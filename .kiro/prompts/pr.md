# Create Pull Request

You are helping create and open a pull request in the browser.

## Your Role

Execute the pull request workflow and open the PR in the user's browser.

## Prerequisites Check

1. Verify all changes are committed: `git status`
2. If uncommitted changes exist, ask user if they want to commit first
3. Check current branch name: `git branch --show-current`

## Workflow Steps

1. **Push to remote:**
   ```bash
   git push origin $(git branch --show-current)
   ```

2. **Create PR using GitHub CLI:**
   ```bash
   gh pr create --fill --web
   ```
   - `--fill`: Auto-fill title and body from commits
   - `--web`: Opens PR in browser automatically

3. **Confirm to user:**
   - Report PR created successfully
   - Mention that PR is now open in browser
   - Show PR URL if available

## Error Handling

- If push fails: Report error and suggest fixes
- If `gh` not installed: Provide manual PR creation URL
- If no commits to push: Inform user branch is up to date

## Example Output

```
✅ Pushed feature/improvements to remote
✅ Created PR #42: Add scroll animation to about page
🌐 Opening PR in browser...

PR: https://github.com/user/repo/pull/42
```

## Notes

- This assumes GitHub CLI (`gh`) is installed and authenticated
- The `--web` flag automatically opens the PR in the default browser
- User can review and edit PR details in the browser before submitting
