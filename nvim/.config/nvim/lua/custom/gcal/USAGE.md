# GCal Usage Guide

## Commands

| Command | Description |
|---------|-------------|
| `:GcalAuthPersonal` | Authenticate personal Google account |
| `:GcalAuthWork` | Authenticate work Google account |
| `:GcalToday` | Show today's events (personal) |
| `:GcalTodayPersonal` | Show today's events (personal) |
| `:GcalTodayWork` | Show today's events (work) |
| `:GcalWeek` | Show week view (personal) |
| `:GcalWeekPersonal` | Show week view (personal) |
| `:GcalWeekWork` | Show week view (work) |
| `:GcalAdd` | Add event interactively |
| `:GcalSyncTask` | Sync markdown task to calendar |

## Week View Keybindings

| Key | Action |
|-----|--------|
| `h` | Previous week |
| `l` | Next week |
| `a` | Add new event |
| `r` | Refresh view |
| `q` / `Esc` | Close calendar |

## Adding Events

### Interactive
Run `:GcalAdd` and enter:
1. Event title
2. Date (`YYYY-MM-DD`, `today`, or `tomorrow`)
3. Time (`HH:MM`, default: 09:00)
4. Duration in minutes (default: 60)

### From Markdown Tasks
Place cursor on a task line with a date and run `:GcalSyncTask`:

```markdown
- [ ] Submit report @date(2026-01-15)
- [ ] Review PR due:2026-01-10
- [ ] Team lunch 📅 2026-01-12
```

Supported date formats:
- `@date(YYYY-MM-DD)`
- `due:YYYY-MM-DD`
- `📅 YYYY-MM-DD`

## Lua API

```lua
local gcal = require("custom.gcal")

-- Authenticate
gcal.authenticate("personal")
gcal.authenticate("work")

-- List events
gcal.list_events("personal", 1)   -- Today
gcal.list_events("personal", 7)   -- Week

-- Show week grid
gcal.show_week("personal", 0)     -- Current week
gcal.show_week("personal", -1)    -- Last week
gcal.show_week("personal", 1)     -- Next week

-- Add event
gcal.add_event("Meeting", "2026-01-15", "14:00", 60, "work")

-- Interactive add
gcal.interactive_add()

-- Sync current task line
gcal.sync_task_line()

-- Get account for current file
gcal.get_account_for_path(vim.fn.expand("%:p"))
```
