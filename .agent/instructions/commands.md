# Session Commands

Reserved commands for managing AI agent sessions.

## Commands

| Command | Action |
|---------|--------|
| `start session` | Initialize session, review context |
| `push` | Commit to current branch and push to origin |
| `pull` | Pull latest changes from origin to current branch |
| `journal` | Update .agent journal with work log and instructions |

## Start Session Behavior

When `start session` is invoked:
1. Read `.agent/instructions.md` and key instruction files
2. Check latest entry in `.agent/memory/journal.md`
3. Check git status for any uncommitted work
4. Provide brief reminder to user:
   - Last session date and summary
   - Any pending work or open items
   - Current branch status

## End Session Behavior

When `end session` is invoked:
1. **Commit pending changes** (if user confirms)
2. **Journal**: Run the `journal` command logic
3. **Commit documentation updates** separately from code changes
4. Provide session summary to user

## Push Behavior
- Check status
- Stage all changes (interactive confirmation if needed)
- Commit with descriptive commit message
- Push to current branch

## Pull Behavior
- Check status (stash if needed)
- Pull from origin (rebase preferred)
- Pop stash if needed

## Journal Behavior
- **Update agentic instructions** based on session learnings:
   - New patterns discovered → update relevant `.agent/instructions/*.md`
   - New deployment procedures → update `deployment.md`
   - Gotchas or pitfalls → add to relevant instruction file
- **Write journal entry** in `.agent/memory/journal.md`:
   - Date and session title
   - Summary of work completed
   - Key decisions made
   - Open items for next session
