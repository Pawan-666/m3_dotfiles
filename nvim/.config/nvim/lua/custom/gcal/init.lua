-- GCal sync plugin for nvim
-- Uses Google Calendar API directly with OAuth2

local M = {}

-- Load .env file from nvim config directory
local function load_env()
  local env_path = vim.fn.stdpath("config") .. "/.env"
  local f = io.open(env_path, "r")
  if not f then return end
  for line in f:lines() do
    local key, value = line:match("^([^#][^=]*)=(.*)$")
    if key and value then
      key = key:match("^%s*(.-)%s*$")
      value = value:match("^%s*(.-)%s*$")
      -- Remove quotes if present
      value = value:gsub("^[\"'](.*)[\"\']$", "%1")
      vim.env[key] = value
    end
  end
  f:close()
end

load_env()

-- Check for required env vars
local client_id = vim.env.GCAL_CLIENT_ID
local client_secret = vim.env.GCAL_CLIENT_SECRET

if not client_id or not client_secret then
  M.disabled = true
  M.setup = function()
    vim.notify("GCal disabled: GCAL_CLIENT_ID and GCAL_CLIENT_SECRET not found in ~/.config/nvim/.env", vim.log.levels.WARN)
  end
  return M
end

local curl = require("plenary.curl")
local json = vim.json

-- OAuth2 configuration
local OAUTH = {
  client_id = client_id,
  client_secret = client_secret,
  redirect_uri = "http://localhost:8085",
  auth_uri = "https://accounts.google.com/o/oauth2/v2/auth",
  token_uri = "https://oauth2.googleapis.com/token",
  scopes = "https://www.googleapis.com/auth/calendar",
}

local CONFIG_DIR = vim.fn.stdpath("data") .. "/gcal"
local TOKENS_FILE_PERSONAL = CONFIG_DIR .. "/tokens_personal.json"
local TOKENS_FILE_WORK = CONFIG_DIR .. "/tokens_work.json"

M.config = {
  calendars = {
    personal = "primary",
    work = "primary",
  },
  vault_path = vim.fn.expand("~/vault"),
  folder_calendar_map = {
    ["work"] = "work",
    ["personal"] = "personal",
    ["daily"] = "personal",
  },
}

-- Ensure config directory exists
local function ensure_config_dir()
  vim.fn.mkdir(CONFIG_DIR, "p")
end

-- Get tokens file for account type
local function get_tokens_file(account_type)
  return account_type == "work" and TOKENS_FILE_WORK or TOKENS_FILE_PERSONAL
end

-- Load tokens from file
local function load_tokens(account_type)
  local file = get_tokens_file(account_type)
  local f = io.open(file, "r")
  if not f then return nil end
  local content = f:read("*all")
  f:close()
  local ok, tokens = pcall(json.decode, content)
  return ok and tokens or nil
end

-- Save tokens to file
local function save_tokens(account_type, tokens)
  ensure_config_dir()
  local file = get_tokens_file(account_type)
  local f = io.open(file, "w")
  if f then
    f:write(json.encode(tokens))
    f:close()
  end
end

-- Generate auth URL
local function get_auth_url()
  local params = {
    client_id = OAUTH.client_id,
    redirect_uri = OAUTH.redirect_uri,
    response_type = "code",
    scope = OAUTH.scopes,
    access_type = "offline",
    prompt = "consent",
  }
  local query = {}
  for k, v in pairs(params) do
    table.insert(query, k .. "=" .. vim.uri_encode(v))
  end
  return OAUTH.auth_uri .. "?" .. table.concat(query, "&")
end

-- Exchange auth code for tokens
local function exchange_code(code, callback)
  curl.post(OAUTH.token_uri, {
    body = vim.uri_encode("client_id") .. "=" .. vim.uri_encode(OAUTH.client_id)
      .. "&" .. vim.uri_encode("client_secret") .. "=" .. vim.uri_encode(OAUTH.client_secret)
      .. "&" .. vim.uri_encode("code") .. "=" .. vim.uri_encode(code)
      .. "&" .. vim.uri_encode("grant_type") .. "=" .. vim.uri_encode("authorization_code")
      .. "&" .. vim.uri_encode("redirect_uri") .. "=" .. vim.uri_encode(OAUTH.redirect_uri),
    headers = {
      ["Content-Type"] = "application/x-www-form-urlencoded",
    },
    callback = function(response)
      vim.schedule(function()
        if response.status == 200 then
          local ok, tokens = pcall(json.decode, response.body)
          if ok then
            callback(tokens)
          else
            vim.notify("Failed to parse token response", vim.log.levels.ERROR)
          end
        else
          vim.notify("Token exchange failed: " .. (response.body or "unknown error"), vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

-- Refresh access token
local function refresh_token(account_type, callback)
  local tokens = load_tokens(account_type)
  if not tokens or not tokens.refresh_token then
    vim.notify("No refresh token for " .. account_type .. ". Please re-authenticate.", vim.log.levels.ERROR)
    return
  end

  curl.post(OAUTH.token_uri, {
    body = vim.uri_encode("client_id") .. "=" .. vim.uri_encode(OAUTH.client_id)
      .. "&" .. vim.uri_encode("client_secret") .. "=" .. vim.uri_encode(OAUTH.client_secret)
      .. "&" .. vim.uri_encode("refresh_token") .. "=" .. vim.uri_encode(tokens.refresh_token)
      .. "&" .. vim.uri_encode("grant_type") .. "=" .. vim.uri_encode("refresh_token"),
    headers = {
      ["Content-Type"] = "application/x-www-form-urlencoded",
    },
    callback = function(response)
      vim.schedule(function()
        if response.status == 200 then
          local ok, new_tokens = pcall(json.decode, response.body)
          if ok then
            -- Keep refresh token if not returned
            new_tokens.refresh_token = new_tokens.refresh_token or tokens.refresh_token
            save_tokens(account_type, new_tokens)
            callback(new_tokens.access_token)
          end
        else
          vim.notify("Token refresh failed", vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

-- Get valid access token (refresh if needed)
local function get_access_token(account_type, callback)
  local tokens = load_tokens(account_type)
  if not tokens then
    vim.notify("Not authenticated for " .. account_type .. ". Run :GcalAuth" .. (account_type == "work" and "Work" or "Personal"), vim.log.levels.WARN)
    return
  end
  -- Always try to refresh to ensure valid token
  refresh_token(account_type, callback)
end

-- Make authenticated API request
local function api_request(method, endpoint, account_type, body, callback)
  get_access_token(account_type, function(access_token)
    local opts = {
      headers = {
        ["Authorization"] = "Bearer " .. access_token,
        ["Content-Type"] = "application/json",
      },
      callback = function(response)
        vim.schedule(function()
          if response.status >= 200 and response.status < 300 then
            local ok, data = pcall(json.decode, response.body)
            callback(ok and data or response.body)
          else
            vim.notify("API error: " .. (response.body or "unknown"), vim.log.levels.ERROR)
          end
        end)
      end,
    }
    if body then
      opts.body = json.encode(body)
    end

    local url = "https://www.googleapis.com/calendar/v3" .. endpoint
    if method == "GET" then
      curl.get(url, opts)
    elseif method == "POST" then
      curl.post(url, opts)
    end
  end)
end

-- Start local server to receive OAuth callback
local function start_auth_server(account_type)
  local server_script = [[
python3 -c "
import http.server
import socketserver
import urllib.parse

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        query = urllib.parse.urlparse(self.path).query
        params = urllib.parse.parse_qs(query)
        code = params.get('code', [''])[0]

        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

        if code:
            self.wfile.write(b'<h1>Success!</h1><p>You can close this window and return to nvim.</p>')
            print('CODE:' + code)
        else:
            self.wfile.write(b'<h1>Error</h1><p>No authorization code received.</p>')

    def log_message(self, format, *args):
        pass

with socketserver.TCPServer(('', 8085), Handler) as httpd:
    httpd.handle_request()
"
]]

  vim.fn.jobstart(server_script, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        local code = line:match("CODE:(.+)")
        if code then
          exchange_code(code, function(tokens)
            save_tokens(account_type, tokens)
            vim.notify("Successfully authenticated " .. account_type .. " account!", vim.log.levels.INFO)
          end)
        end
      end
    end,
    on_stderr = function(_, data)
      if data and data[1] ~= "" then
        -- Ignore stderr noise
      end
    end,
  })
end

-- Authenticate with Google
function M.authenticate(account_type)
  account_type = account_type or "personal"
  vim.notify("Starting authentication for " .. account_type .. " account...", vim.log.levels.INFO)

  -- Start local server
  start_auth_server(account_type)

  -- Open browser
  local auth_url = get_auth_url()
  local open_cmd = vim.fn.has("mac") == 1 and "open" or "xdg-open"
  vim.fn.jobstart({ open_cmd, auth_url }, { detach = true })

  vim.notify("Browser opened. Please authorize the app.", vim.log.levels.INFO)
end

-- Get calendar for file path
function M.get_account_for_path(filepath)
  local vault = M.config.vault_path:gsub("~", os.getenv("HOME"))
  local rel = filepath:gsub(vault .. "/", "")
  local folder = rel:match("^([^/]+)/")

  if folder and M.config.folder_calendar_map[folder] then
    return M.config.folder_calendar_map[folder]
  end
  return "personal"
end

-- Get start of week (Monday)
local function get_week_start()
  local now = os.time()
  local day_of_week = tonumber(os.date("%w", now)) -- 0=Sun, 1=Mon, ...
  if day_of_week == 0 then day_of_week = 7 end -- Make Sunday = 7
  local monday = now - ((day_of_week - 1) * 86400)
  return os.time({ year = tonumber(os.date("%Y", monday)), month = tonumber(os.date("%m", monday)), day = tonumber(os.date("%d", monday)), hour = 0, min = 0, sec = 0 })
end

-- Render week grid calendar
local function render_week_grid(events, account_type)
  local week_start = get_week_start()
  local days = { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" }
  local col_width = 18
  local hours_start = 7  -- 7 AM
  local hours_end = 22   -- 10 PM

  -- Organize events by day and hour
  local grid = {}
  for d = 1, 7 do
    grid[d] = {}
  end

  for _, event in ipairs(events or {}) do
    local start = event.start.dateTime or event.start.date
    local event_time = start:match("T(%d%d):(%d%d)")
    local event_date = start:match("^(%d%d%d%d%-?%d%d%-?%d%d)")
    if event_date then
      event_date = event_date:gsub("%-", "")
    end

    for d = 1, 7 do
      local day_time = week_start + ((d - 1) * 86400)
      local day_str = os.date("%Y%m%d", day_time)
      if event_date and event_date:gsub("%-", "") == day_str then
        local hour = event_time and tonumber(event_time:match("^(%d%d)")) or 0
        if not grid[d][hour] then grid[d][hour] = {} end
        table.insert(grid[d][hour], event.summary or "(no title)")
      end
    end
  end

  local lines = {}

  -- Header with month/year
  local month_year = os.date("%B %Y", week_start)
  local header_pad = string.rep(" ", math.floor((7 * col_width - #month_year) / 2))
  table.insert(lines, header_pad .. month_year .. " (" .. account_type .. ")")
  table.insert(lines, "")

  -- Day headers with dates
  local day_header = "      │"
  local date_header = "      │"
  for d = 1, 7 do
    local day_time = week_start + ((d - 1) * 86400)
    local day_name = days[d]
    local day_num = os.date("%d", day_time)
    local is_today = os.date("%Y%m%d", day_time) == os.date("%Y%m%d")

    local day_str = day_name
    local date_str = day_num
    if is_today then
      day_str = ">" .. day_name .. "<"
      date_str = "[" .. day_num .. "]"
    end

    day_header = day_header .. string.format(" %-" .. (col_width - 1) .. "s│", day_str)
    date_header = date_header .. string.format(" %-" .. (col_width - 1) .. "s│", date_str)
  end
  table.insert(lines, day_header)
  table.insert(lines, date_header)
  table.insert(lines, "──────┼" .. string.rep("─", col_width) .. string.rep("┼" .. string.rep("─", col_width), 6) .. "┤")

  -- Time slots
  for hour = hours_start, hours_end do
    local time_str = string.format("%02d:00", hour)
    local row = time_str .. " │"

    for d = 1, 7 do
      local cell_events = grid[d][hour]
      local cell = ""
      if cell_events and #cell_events > 0 then
        cell = cell_events[1]
        if #cell > col_width - 2 then
          cell = cell:sub(1, col_width - 4) .. ".."
        end
        if #cell_events > 1 then
          cell = cell .. " +" .. (#cell_events - 1)
        end
      end
      row = row .. string.format(" %-" .. (col_width - 1) .. "s│", cell)
    end

    table.insert(lines, row)

    -- Add a light separator every 2 hours
    if hour % 2 == 0 and hour < hours_end then
      table.insert(lines, "      │" .. string.rep(" " .. string.rep("·", col_width - 1) .. "│", 7))
    end
  end

  -- Footer
  table.insert(lines, "──────┴" .. string.rep("─", col_width) .. string.rep("┴" .. string.rep("─", col_width), 6) .. "┘")
  table.insert(lines, "")
  table.insert(lines, " [q] Close  [h/l] Prev/Next week  [a] Add event  [r] Refresh")

  return lines
end

-- Show week view
function M.show_week(account_type, week_offset)
  account_type = account_type or "personal"
  week_offset = week_offset or 0

  local week_start = get_week_start() + (week_offset * 7 * 86400)
  local week_end = week_start + (7 * 86400)

  local time_min = os.date("!%Y-%m-%dT00:00:00Z", week_start)
  local time_max = os.date("!%Y-%m-%dT23:59:59Z", week_end)

  local calendar_id = vim.uri_encode(M.config.calendars[account_type])
  local endpoint = "/calendars/" .. calendar_id .. "/events"
    .. "?timeMin=" .. vim.uri_encode(time_min)
    .. "&timeMax=" .. vim.uri_encode(time_max)
    .. "&singleEvents=true"
    .. "&orderBy=startTime"

  api_request("GET", endpoint, account_type, nil, function(data)
    local lines = render_week_grid(data.items, account_type)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")

    local width = 6 + (18 * 7) + 8
    local height = #lines
    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = math.min(width, vim.o.columns - 4),
      height = math.min(height, vim.o.lines - 4),
      col = math.max(0, (vim.o.columns - width) / 2),
      row = math.max(0, (vim.o.lines - height) / 2),
      style = "minimal",
      border = "rounded",
    })

    -- Store state for navigation
    vim.b[buf].gcal_account = account_type
    vim.b[buf].gcal_week_offset = week_offset

    -- Keymaps
    vim.keymap.set("n", "q", ":close<CR>", { buffer = buf, silent = true })
    vim.keymap.set("n", "<Esc>", ":close<CR>", { buffer = buf, silent = true })
    vim.keymap.set("n", "l", function()
      vim.cmd("close")
      M.show_week(account_type, week_offset + 1)
    end, { buffer = buf, silent = true })
    vim.keymap.set("n", "h", function()
      vim.cmd("close")
      M.show_week(account_type, week_offset - 1)
    end, { buffer = buf, silent = true })
    vim.keymap.set("n", "a", function()
      vim.cmd("close")
      M.interactive_add()
    end, { buffer = buf, silent = true })
    vim.keymap.set("n", "r", function()
      vim.cmd("close")
      M.show_week(account_type, week_offset)
    end, { buffer = buf, silent = true })

    -- Highlight current day column
    vim.api.nvim_buf_add_highlight(buf, -1, "Title", 0, 0, -1)
  end)
end

-- List events (simple agenda view for today)
function M.list_events(account_type, days)
  if days == 7 then
    M.show_week(account_type, 0)
    return
  end

  account_type = account_type or "personal"
  days = days or 1

  local now = os.date("!%Y-%m-%dT%H:%M:%SZ")
  local future = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time() + (days * 86400))

  local calendar_id = vim.uri_encode(M.config.calendars[account_type])
  local endpoint = "/calendars/" .. calendar_id .. "/events"
    .. "?timeMin=" .. vim.uri_encode(now)
    .. "&timeMax=" .. vim.uri_encode(future)
    .. "&singleEvents=true"
    .. "&orderBy=startTime"

  api_request("GET", endpoint, account_type, nil, function(data)
    if not data.items or #data.items == 0 then
      vim.notify("No events today", vim.log.levels.INFO)
      return
    end

    local lines = { "  Today's Events (" .. account_type .. ")", "  " .. string.rep("─", 40), "" }
    for _, event in ipairs(data.items) do
      local start = event.start.dateTime or event.start.date
      local time = start:match("T(%d%d:%d%d)") or "All day"
      table.insert(lines, string.format("  %s  │  %s", time, event.summary or "(no title)"))
    end
    table.insert(lines, "")
    table.insert(lines, "  [q] Close  [w] Week view")

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)

    local width = 50
    local height = #lines
    vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = width,
      height = height,
      col = (vim.o.columns - width) / 2,
      row = (vim.o.lines - height) / 2,
      style = "minimal",
      border = "rounded",
    })

    vim.keymap.set("n", "q", ":close<CR>", { buffer = buf, silent = true })
    vim.keymap.set("n", "<Esc>", ":close<CR>", { buffer = buf, silent = true })
    vim.keymap.set("n", "w", function()
      vim.cmd("close")
      M.show_week(account_type, 0)
    end, { buffer = buf, silent = true })
  end)
end

-- Add event
function M.add_event(title, date, time, duration_minutes, account_type)
  account_type = account_type or M.get_account_for_path(vim.fn.expand("%:p"))
  duration_minutes = duration_minutes or 60
  time = time or "09:00"

  local start_dt = date .. "T" .. time .. ":00"
  local end_time = os.time({
    year = tonumber(date:sub(1, 4)),
    month = tonumber(date:sub(6, 7)),
    day = tonumber(date:sub(9, 10)),
    hour = tonumber(time:sub(1, 2)),
    min = tonumber(time:sub(4, 5)) + duration_minutes,
  })
  local end_dt = os.date("%Y-%m-%dT%H:%M:00", end_time)

  local event = {
    summary = title,
    start = { dateTime = start_dt, timeZone = "America/Los_Angeles" },
    ["end"] = { dateTime = end_dt, timeZone = "America/Los_Angeles" },
  }

  local calendar_id = vim.uri_encode(M.config.calendars[account_type])
  api_request("POST", "/calendars/" .. calendar_id .. "/events", account_type, event, function(data)
    if data.id then
      vim.notify("Event created: " .. title, vim.log.levels.INFO)
    end
  end)
end

-- Parse date from string
local function parse_date(str)
  if str == "today" then
    return os.date("%Y-%m-%d")
  elseif str == "tomorrow" then
    return os.date("%Y-%m-%d", os.time() + 86400)
  end
  local y, m, d = str:match("(%d%d%d%d)%-(%d%d)%-(%d%d)")
  if y then return string.format("%s-%s-%s", y, m, d) end
  return nil
end

-- Sync task line to calendar
function M.sync_task_line()
  local line = vim.api.nvim_get_current_line()
  local task = line:match("%- %[.%] (.+)")
  if not task then
    vim.notify("Not a task line", vim.log.levels.WARN)
    return
  end

  local date = task:match("@date%(([^)]+)%)") or task:match("due:(%S+)") or task:match("📅%s*(%S+)")
  if not date then
    vim.notify("No date found. Use @date(YYYY-MM-DD) or due:YYYY-MM-DD", vim.log.levels.WARN)
    return
  end

  local parsed = parse_date(date)
  if not parsed then
    vim.notify("Could not parse date: " .. date, vim.log.levels.ERROR)
    return
  end

  local title = task:gsub("@date%([^)]+%)", ""):gsub("due:%S+", ""):gsub("📅%s*%S+", ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
  M.add_event(title, parsed)
end

-- Interactive add
function M.interactive_add()
  local account = M.get_account_for_path(vim.fn.expand("%:p"))

  vim.ui.input({ prompt = "Event title: " }, function(title)
    if not title or title == "" then return end

    vim.ui.input({ prompt = "Date (YYYY-MM-DD or today/tomorrow): " }, function(date)
      if not date or date == "" then return end
      local parsed = parse_date(date)
      if not parsed then
        vim.notify("Invalid date", vim.log.levels.ERROR)
        return
      end

      vim.ui.input({ prompt = "Time (HH:MM): ", default = "09:00" }, function(time)
        time = (time and time ~= "") and time or "09:00"

        vim.ui.input({ prompt = "Duration (minutes): ", default = "60" }, function(dur)
          local duration = tonumber(dur) or 60
          M.add_event(title, parsed, time, duration, account)
        end)
      end)
    end)
  end)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  ensure_config_dir()

  -- Commands
  vim.api.nvim_create_user_command("GcalAuthPersonal", function() M.authenticate("personal") end, {})
  vim.api.nvim_create_user_command("GcalAuthWork", function() M.authenticate("work") end, {})

  vim.api.nvim_create_user_command("GcalToday", function() M.list_events("personal", 1) end, {})
  vim.api.nvim_create_user_command("GcalTodayWork", function() M.list_events("work", 1) end, {})
  vim.api.nvim_create_user_command("GcalTodayPersonal", function() M.list_events("personal", 1) end, {})

  vim.api.nvim_create_user_command("GcalWeek", function() M.list_events("personal", 7) end, {})
  vim.api.nvim_create_user_command("GcalWeekWork", function() M.list_events("work", 7) end, {})
  vim.api.nvim_create_user_command("GcalWeekPersonal", function() M.list_events("personal", 7) end, {})

  vim.api.nvim_create_user_command("GcalAdd", function() M.interactive_add() end, {})
  vim.api.nvim_create_user_command("GcalSyncTask", function() M.sync_task_line() end, {})

  vim.notify("GCal loaded. Authenticate with :GcalAuthPersonal or :GcalAuthWork", vim.log.levels.INFO)
end

return M
