# Create New Branch

You are helping create a new feature branch from main.

## Your Role

Guide the user through creating a properly named feature branch from the latest main branch.

## Workflow Steps

1. **Ask what they want to build:**
   - "What feature or improvement are you working on?"
   - Get a brief description from the user

2. **Suggest branch name:**
   - Based on their description, suggest a branch name following the pattern:
     - `feature/short-description` for new features
     - `fix/short-description` for bug fixes
     - `docs/short-description` for documentation
     - `refactor/short-description` for refactoring
   - Use kebab-case (lowercase with hyphens)
   - Keep it concise but descriptive
   - Ask user to confirm or provide alternative name

3. **Switch to main branch:**
   ```bash
   git checkout main
   ```

4. **Pull latest changes:**
   ```bash
   git pull origin main
   ```

5. **Create and checkout new branch:**
   ```bash
   git checkout -b <branch-name>
   ```

6. **Confirm success:**
   - Show current branch with `git branch --show-current`
   - Report to user that branch is ready

## Example Interaction

```
User: I want to add a contact form
Assistant: I'll help you create a branch for adding a contact form.

Suggested branch name: feature/contact-form

Does this name work for you, or would you like a different name?

User: That's good
Assistant: 
✅ Switched to main branch
✅ Pulled latest changes from origin/main
✅ Created new branch: feature/contact-form
✅ Currently on: feature/contact-form

Your branch is ready! You can now start working on the contact form.
```

## Branch Naming Guidelines

- **feature/** - New features or enhancements
- **fix/** - Bug fixes
- **docs/** - Documentation updates
- **refactor/** - Code refactoring
- **test/** - Test additions or updates
- **chore/** - Maintenance tasks

Use descriptive but concise names:
- ✅ Good: `feature/user-authentication`, `fix/mobile-layout`, `docs/api-guide`
- ❌ Bad: `feature/new-stuff`, `fix/bug`, `my-branch`

## Error Handling

- If main branch doesn't exist: Report error and suggest checking remote
- If pull fails: Report conflict and suggest resolving manually
- If branch name already exists: Suggest alternative name with suffix (e.g., `-v2`)
- If uncommitted changes exist: Warn user and ask if they want to stash or commit first

## Notes

- Always create branches from main to ensure clean starting point
- Pull before creating branch to get latest changes
- Use kebab-case for consistency with existing branches
- Keep branch names under 50 characters when possible
