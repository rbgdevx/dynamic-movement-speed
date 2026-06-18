-- Static analysis for the dynamic-movement-speed WoW addon.  Run from the repo root: luacheck .
--
-- Tailored to the addon: WoW globals seeded from its .luarc.json and completed
-- with a luacheck harvest of APIs the code actually calls (luacheck has no WoW
-- API library of its own, unlike the LSP's WoW addon the .luarc.json leans on).
-- NOTE: luacheck must run under Lua <= 5.4 (it crashes on 5.5). The `luacheck`
-- on PATH is built against lua@5.4; we still lint WoW's 5.1 dialect via std.

std = "lua51"            -- WoW runs Lua 5.1
max_line_length = false  -- WoW addon lines are routinely wide

exclude_files = {
  ".libraries", "libs",
}

-- WoW idioms that aren't defects: `_ADDON` addon-load vararg; `self` on
-- `:` colon-method APIs that don't use it.
ignore = { "_ADDON", "212/self" }

-- Globals the addon DEFINES/WRITES (saved-vars, slash handlers).
globals = {
  "DMSDB", "SLASH_DMS1", "SLASH_DMS2", "SlashCmdList",
}

-- Blizzard client API the addon READS.
read_globals = {
  "AbbreviateNumbers", "BASE_MOVEMENT_SPEED", "C_Map", "C_PlayerInfo", "C_Timer",
  "C_UnitAuras", "CopyTable", "CreateFrame", "FrameUtil", "GetInstanceInfo", "GetTime",
  "GetUnitSpeed", "IsFalling", "IsFlying", "IsInInstance", "IsPlayerMoving", "LibStub",
  "Round", "UIParent", "UnitIsUnit", "UnitPosition", "UnitPowerBarID", "format",
  "issecretvalue",
}
