# Neovim Google Calendar Plugin

A custom Neovim plugin that integrates with Google Calendar API using OAuth2 authentication. View, add, and sync calendar events directly from Neovim.

## Prerequisites

- Neovim 0.8+
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) - Required for HTTP requests
- Python 3 - Used for the OAuth callback server
- `open` command (macOS) or `xdg-open` (Linux) - For opening the browser during auth

## Setup

### Step 1: Create Google Cloud Project & OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com)

2. **Create a new project** (or select an existing one):
   - Click the project dropdown at the top
   - Click "New Project"
   - Give it a name (e.g., "Neovim Calendar")
   - Click "Create"

3. **Enable the Google Calendar API**:
   - Go to "APIs & Services" → "Library"
   - Search for "Google Calendar API"
   - Click on it and press "Enable"

4. **Configure OAuth Consent Screen**:
   - Go to "APIs & Services" → "OAuth consent screen"
   - Choose "External" (unless you have a Google Workspace)
   - Fill in required fields:
     - App name: "Neovim Calendar"
     - User support email: your email
     - Developer contact: your email
   - Click "Save and Continue"
   - On "Scopes" page, click "Add or Remove Scopes"
     - Add `https://www.googleapis.com/auth/calendar`
   - Click "Save and Continue"
   - On "Test users" page, add your Google account email(s)
   - Click "Save and Continue"

5. **Create OAuth Credentials**:
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "OAuth client ID"
   - Application type: **Desktop app**
   - Name: "Neovim Client"
   - Click "Create"
   - **Important**: Copy the Client ID and Client Secret

6. **Add Authorized Redirect URI** (if using web application type):
   - Edit your OAuth client
   - Under "Authorized redirect URIs", add: `http://localhost:8085`
   - Save

### Step 2: Configure Environment Variables

Create a `.env` file in your Neovim config directory:

```bash
# ~/.config/nvim/.env

GCAL_CLIENT_ID=your_client_id_here.apps.googleusercontent.com
GCAL_CLIENT_SECRET=your_client_secret_here
```

**Security Note**: Make sure `.env` is in your `.gitignore` to avoid exposing credentials.

### Step 3: Configure the Plugin

Edit `lua/plugins/gcal.lua` to match your setup:

```lua
return {
  dir = vim.fn.stdpath("config") .. "/lua/custom/gcal",
  name = "gcal",
  config = function()
    require("custom.gcal").setup({
      -- Your calendar email addresses
      calendars = {
        personal = "your-personal@gmail.com",
        work = "your-work@company.com",
      },

      -- Path to your notes vault (for folder-based calendar selection)
      vault_path = vim.fn.expand("~/vault"),

      -- Map folders to calendar accounts
      -- When adding events from files in these folders,
      -- the plugin will use the corresponding calendar
      folder_calendar_map = {
        ["work"] = "work",
        ["personal"] = "personal",
        ["daily"] = "personal",
      },
    })
  end,
}
```

### Step 4: Authenticate

Open Neovim and run the authentication commands:

```vim
:GcalAuthPersonal    " For personal Google account
:GcalAuthWork        " For work Google account
```

This will:
1. Start a local server on port 8085
2. Open your browser to Google's OAuth consent page
3. After you authorize, redirect back to capture the auth code
4. Exchange the code for access/refresh tokens
5. Store tokens in `~/.local/share/nvim/gcal/`

**Note**: You'll see "Success!" in the browser when authentication completes.

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `:GcalAuthPersonal` | Authenticate personal Google account |
| `:GcalAuthWork` | Authenticate work Google account |
| `:GcalToday` | Show today's events (personal calendar) |
| `:GcalTodayPersonal` | Show today's events (personal calendar) |
| `:GcalTodayWork` | Show today's events (work calendar) |
| `:GcalWeek` | Show week view grid (personal calendar) |
| `:GcalWeekPersonal` | Show week view grid (personal calendar) |
| `:GcalWeekWork` | Show week view grid (work calendar) |
| `:GcalAdd` | Interactively add a new event |
| `:GcalSyncTask` | Sync current markdown task line to calendar |

### Week View

The week view displays a grid showing events from 7 AM to 10 PM:

```
              January 2026 (personal)

      │ Mon              │ Tue              │ Wed              │ ...
      │ 06               │ 07               │ [08]             │ ...
──────┼──────────────────┼──────────────────┼──────────────────┼...
09:00 │ Team standup     │                  │ Code review      │
10:00 │                  │ 1:1 with manager │                  │
...
```

**Keybindings in week view:**

| Key | Action |
|-----|--------|
| `h` | Go to previous week |
| `l` | Go to next week |
| `a` | Add new event |
| `r` | Refresh current view |
| `q` or `Esc` | Close the calendar |

### Adding Events

#### Interactive Method

Run `:GcalAdd` and follow the prompts:

1. **Event title**: Enter the name of the event
2. **Date**: Enter in `YYYY-MM-DD` format, or use `today` / `tomorrow`
3. **Time**: Enter in `HH:MM` format (default: 09:00)
4. **Duration**: Enter in minutes (default: 60)

#### From Markdown Tasks

If you have a task line with a date, place your cursor on it and run `:GcalSyncTask`:

```markdown
- [ ] Submit quarterly report @date(2026-01-15)
- [ ] Review PR due:2026-01-10
- [ ] Team lunch 📅 2026-01-12
```

Supported date formats:
- `@date(YYYY-MM-DD)`
- `due:YYYY-MM-DD`
- `📅 YYYY-MM-DD`

The plugin will automatically select the calendar based on the folder the file is in (using `folder_calendar_map`).

## Token Storage

OAuth tokens are stored in:
- Personal: `~/.local/share/nvim/gcal/tokens_personal.json`
- Work: `~/.local/share/nvim/gcal/tokens_work.json`

Tokens include:
- `access_token`: Short-lived token for API requests
- `refresh_token`: Long-lived token to get new access tokens

The plugin automatically refreshes expired access tokens using the refresh token.

## Troubleshooting

### "GCAL_CLIENT_ID and GCAL_CLIENT_SECRET not found"

- Ensure `.env` file exists at `~/.config/nvim/.env`
- Check that variable names are exactly `GCAL_CLIENT_ID` and `GCAL_CLIENT_SECRET`
- Restart Neovim after creating/editing the `.env` file

### "Not authenticated" errors

- Run `:GcalAuthPersonal` or `:GcalAuthWork` to authenticate
- If re-authenticating, delete the token file and try again

### Browser doesn't open on macOS

Edit `lua/custom/gcal/init.lua` line 285, change:
```lua
vim.fn.jobstart({ "xdg-open", auth_url }, { detach = true })
```
to:
```lua
vim.fn.jobstart({ "open", auth_url }, { detach = true })
```

### Port 8085 already in use

The OAuth callback server uses port 8085. If it's in use:
1. Find and kill the process using it: `lsof -i :8085`
2. Or modify `OAUTH.redirect_uri` in init.lua and update Google Cloud Console

### "Token refresh failed"

- Your refresh token may have expired (happens if unused for 6 months with external OAuth)
- Re-authenticate with `:GcalAuthPersonal` or `:GcalAuthWork`

### API quota errors

- Google Calendar API has usage limits
- Default is 1,000,000 queries per day (should be plenty for personal use)

## File Structure

```
lua/
├── plugins/
│   └── gcal.lua          # Plugin spec (lazy.nvim compatible)
└── custom/
    └── gcal/
        ├── init.lua      # Main plugin code
        └── README.md     # This file
```

## API Reference

### Lua Functions

```lua
local gcal = require("custom.gcal")

-- Authenticate
gcal.authenticate("personal")  -- or "work"

-- List events
gcal.list_events("personal", 1)   -- Today's events
gcal.list_events("personal", 7)   -- Week view

-- Show week grid
gcal.show_week("personal", 0)     -- Current week
gcal.show_week("work", -1)        -- Last week
gcal.show_week("work", 1)         -- Next week

-- Add event
gcal.add_event("Meeting", "2026-01-15", "14:00", 60, "work")

-- Interactive add
gcal.interactive_add()

-- Sync current task line
gcal.sync_task_line()

-- Get account for current file path
gcal.get_account_for_path(vim.fn.expand("%:p"))
```

## License

This is a custom plugin for personal use.
