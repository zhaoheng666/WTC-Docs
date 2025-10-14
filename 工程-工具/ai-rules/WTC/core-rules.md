# Core Rules (Detailed)

Detailed rules for WorldTourCasino project. This file is imported by main CLAUDE.md.

## Mandatory Rules

### File Path Links

Convert all source code file links to GitHub format when writing documentation.

Format:
```
https://github.com/zhaoheng666/WorldTourCasino/blob/classic_vegas/path/to/file.ext
https://github.com/zhaoheng666/WorldTourCasino/blob/classic_vegas/path/to/file.ext#L10
https://github.com/zhaoheng666/WorldTourCasino/blob/classic_vegas/path/to/file.ext#L10-L20
```

### Docs Subproject Links

In `docs/` subproject only:
- Convert all relative markdown links to absolute HTTP links
- Use `http://localhost:5173/WTC-Docs/` for local
- Use `https://zhaoheng666.github.io/WTC-Docs/` for production
- Link processor runs automatically during build

### Extension Activation

VS Code extensions must activate only in WTC project:
- Check `workspace.getWorkspaceFolder()` name
- Use activation event: `onStartupFinished`
- Never activate globally

### Config File Sync

Synchronize `.vscode/settings.json` ↔ `WorldTourCasino.code-workspace`:
- Update both files when changing configurations
- Use scripts in `.vscode/scripts/` for automation
- Test after changes

## Shell Scripts

Write all shell scripts following these rules:

Shebang:
```bash
#!/usr/bin/env zsh
```

Error handling:
```bash
set -euo pipefail
```

Best practices:
- Use absolute paths
- Avoid `cd` commands when possible
- Quote all variables: `"$var"`
- Check file existence before operations

## Git Commit Messages

### Main Project

Format: `cv：关卡X [描述]`

Examples:
- `cv：关卡1 fix bug in slot machine`
- `cv：关卡2 add new bonus feature`

Or use standard format:
- `type(scope): subject`
- Types: feat, fix, chore, docs, style, refactor

### Docs Subproject

Always use standard format:
- `type(scope): subject`
- Add footer: `🤖 Generated with [Claude Code](https://claude.com/claude-code)`

## Terminology

### Flavor System

- **Flavor**: Game variant/brand
  - CV = Classic Vegas (res_oldvegas/)
  - DH = Double Hit (res_doublehit/)
  - DHX = Double X (res_doublex/)
  - VS = Vegas Star (res_vegasstar/)

- **res_*/** directories: Flavor-specific resources
- **src/** directory: Shared code across all flavors
- **flavor/** subdirectory: Flavor-specific JavaScript code

### Important Files

- `resource_dirs.json`: Resource version control (debug/release)
- `project.json`: Cocos2d project configuration
- `main.js`: Game entry point
- `.vscode/settings.json`: VS Code workspace settings
- `WorldTourCasino.code-workspace`: Multi-root workspace config

## Workflow Patterns

### Adding New Feature

1. Check current branch and flavor context
2. Modify `src/` (shared) or `res_*/flavor/` (flavor-specific)
3. Run local build: `scripts/build_local_[flavor].sh`
4. Test in browser
5. Run `npm run lint`
6. Commit with proper format

### Updating Resources

1. Add/modify resources in appropriate `res_*/` directory
2. Run `scripts/gen_res_list.py` to update manifest
3. Update version in `resource_dirs.json` if needed
4. Build and test locally

### Working with Docs

1. Enter docs subproject: `cd docs`
2. Start dev server: `npm run dev`
3. Make changes
4. Test build: `npm run build`
5. Commit in docs repo (separate from main project)
6. Sync to GitHub Pages: `npm run sync`

## Reference

For complete project architecture and detailed information, see:
- `docs/工程-工具/ai-rules/WTC/CLAUDE-REFERENCE.md` (comprehensive reference)
- Online docs: https://zhaoheng666.github.io/WTC-Docs/
