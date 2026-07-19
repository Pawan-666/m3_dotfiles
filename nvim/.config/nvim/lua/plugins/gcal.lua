-- Google Calendar sync plugin (uses Google Calendar API)
return {
  dir = vim.fn.stdpath("config") .. "/lua/custom/gcal",
  name = "gcal",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = {
    "GcalAuthPersonal",
    "GcalAuthWork",
    "GcalToday",
    "GcalTodayWork",
    "GcalTodayPersonal",
    "GcalWeek",
    "GcalWeekWork",
    "GcalWeekPersonal",
    "GcalAdd",
    "GcalSyncTask",
  },
  config = function()
    require("custom.gcal").setup({
      calendars = {
        personal = "primary",  -- "primary" uses the authenticated account's main calendar
        work = "primary",
      },
      vault_path = vim.fn.expand("~/vault"),
      folder_calendar_map = {
        ["work"] = "work",
        ["personal"] = "personal",
        ["daily"] = "personal",
      },
    })
  end,
}
