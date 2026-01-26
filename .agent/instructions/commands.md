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

1. **Read ALL files in `.agent/` directory**:
   - `.agent/instructions.md`
   - `.agent/context/project-context.md`
   - `.agent/context/infrastructure.md`
   - `.agent/instructions/general.md`
   - `.agent/instructions/ansible.md`
   - `.agent/instructions/deployment.md`
   - `.agent/instructions/documentation.md`
   - `.agent/instructions/commands.md`
   - `.agent/memory/journal.md`
   - `.agent/memory/deployment-log.md`
   - `.agent/memory/maintenance-log.md`

2. **Check git status** for uncommitted work

3. **Provide brief summary to user**:
   - Last session date and summary
   - Any pending work or open items
   - Current branch and uncommitted files

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
