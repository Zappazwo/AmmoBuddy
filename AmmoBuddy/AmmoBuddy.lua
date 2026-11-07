-- AmmoBuddy: lightweight ammo counter for Hunters (WoW Forever / Classic Era / TBC)
local ADDON, ns = ...

local _, class = UnitClass("player")
if class ~= "HUNTER" then return end
ns.enabled = true

ns.AMMO_SLOT = INVSLOT_AMMO or 0
ns.DEFAULT_ICON = "Interface\\Icons\\INV_Ammo_Arrow_02"
ns.defaults = {
  warn = 200,
  locked = false,
  hidden = false,
  point = { "CENTER", "CENTER", 0, -180 },
  minimap = { hide = false, angle = 225 },
}
ns.onReady = {} -- callbacks run once the saved variables are loaded

-- WoW Forever uses the Midnight addon restrictions: some values are "secret"
-- during combat and must not be compared or used in arithmetic. Displaying them is fine.
local function IsSecret(v)
  return issecretvalue and issecretvalue(v) or false
end

local function CopyDefaults(src, dst)
  for k, v in pairs(src) do
    if type(v) == "table" then
      if type(dst[k]) ~= "table" then dst[k] = {} end
      CopyDefaults(v, dst[k])
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
end

function ns.Print(msg) print("|cffabd473AmmoBuddy:|r " .. msg) end

local db
local warned = false

local f = CreateFrame("Frame", "AmmoBuddyFrame", UIParent, "BackdropTemplate")
f:SetSize(90, 30)
f:SetClampedToScreen(true)
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
f:SetBackdropColor(0, 0, 0, 0.6)

local icon = f:CreateTexture(nil, "ARTWORK")
icon:SetSize(22, 22)
icon:SetPoint("LEFT", 4, 0)
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
text:SetPoint("LEFT", icon, "RIGHT", 6, 0)

f:SetScript("OnDragStart", function(self) if not db.locked then self:StartMoving() end end)
f:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local p, _, rp, x, y = self:GetPoint()
  db.point = { p, rp, x, y }
end)
f:SetScript("OnMouseUp", function(_, button)
  if button == "RightButton" then ns.ToggleOptions() end
end)
f:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  if GetInventoryItemLink("player", ns.AMMO_SLOT) then
    GameTooltip:SetInventoryItem("player", ns.AMMO_SLOT)
  else
    GameTooltip:SetText("AmmoBuddy")
  end
  GameTooltip:AddLine("Right-click to open options", 0.7, 0.7, 0.7)
  GameTooltip:Show()
end)
f:SetScript("OnLeave", GameTooltip_Hide)

local function Update()
  local tex = GetInventoryItemTexture("player", ns.AMMO_SLOT)
  local count = tex and GetInventoryItemCount("player", ns.AMMO_SLOT) or 0
  icon:SetTexture(tex or ns.DEFAULT_ICON)
  if ns.SetMinimapIcon then ns.SetMinimapIcon(tex or ns.DEFAULT_ICON) end
  text:SetText(count)

  -- If the value is secret right now, only display it; evaluate again after combat.
  if IsSecret(count) then return end
  icon:SetDesaturated(count == 0)

  if count == 0 then
    text:SetTextColor(1, 0.1, 0.1)
  elseif count <= db.warn then
    text:SetTextColor(1, 0.8, 0)
  else
    text:SetTextColor(0.3, 1, 0.3)
  end

  if count <= db.warn and not warned then
    warned = true
    local msg = count == 0 and "Out of ammo!" or ("Low ammo: " .. count)
    RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo["RAID_WARNING"])
    PlaySound(SOUNDKIT.RAID_WARNING)
  elseif count > db.warn then
    warned = false
  end
end

local pending = false
local function QueueUpdate()
  if pending then return end
  pending = true
  C_Timer.After(0.2, function() pending = false; Update() end)
end

local function ApplyPosition()
  f:ClearAllPoints()
  local p = db.point
  f:SetPoint(p[1], UIParent, p[2], p[3], p[4])
end

-- Public setters, shared by the slash commands and the options panel.
local function Changed() if ns.RefreshOptions then ns.RefreshOptions() end end

function ns.SetLocked(v) db.locked = v; Changed() end

function ns.SetCounterShown(v)
  db.hidden = not v
  f:SetShown(v)
  if v then Update() end
  Changed()
end

function ns.SetWarn(v)
  v = math.max(0, math.floor(v))
  if v ~= db.warn then
    db.warn = v
    warned = false
    Update()
  end
  Changed()
end

function ns.ResetPosition()
  db.point = { unpack(ns.defaults.point) }
  ApplyPosition()
end

f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 ~= ADDON then return end
    AmmoBuddyDB = AmmoBuddyDB or {}
    db = AmmoBuddyDB
    CopyDefaults(ns.defaults, db)
    ns.db = db
    ApplyPosition()
    f:SetShown(not db.hidden)
    for _, fn in ipairs(ns.onReady) do fn() end
    self:UnregisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
  else
    QueueUpdate()
  end
end)

local function PrintHelp()
  ns.Print("/ammo - open the options window")
  ns.Print("/ammo lock | unlock - lock or unlock the ammo counter")
  ns.Print("/ammo warn <amount> - low-ammo threshold (current: " .. db.warn .. ")")
  ns.Print("/ammo show | hide - show or hide the ammo counter")
  ns.Print("/ammo minimap - toggle the minimap button")
  ns.Print("/ammo reset - reset the ammo counter position")
end

SLASH_AMMOBUDDY1 = "/ammo"
SLASH_AMMOBUDDY2 = "/ammobuddy"
SlashCmdList.AMMOBUDDY = function(input)
  local cmd, arg = strsplit(" ", strtrim(input or ""):lower(), 2)
  if cmd == "" then
    ns.ToggleOptions()
  elseif cmd == "lock" then
    ns.SetLocked(true); ns.Print("Ammo counter locked.")
  elseif cmd == "unlock" then
    ns.SetLocked(false); ns.Print("Ammo counter unlocked - left-click and drag to move it.")
  elseif cmd == "warn" and tonumber(arg) then
    ns.SetWarn(tonumber(arg)); ns.Print("Warning threshold set to " .. db.warn .. ".")
  elseif cmd == "reset" then
    ns.ResetPosition(); ns.Print("Position reset.")
  elseif cmd == "show" then
    ns.SetCounterShown(true)
  elseif cmd == "hide" then
    ns.SetCounterShown(false)
  elseif cmd == "minimap" then
    ns.SetMinimapShown(db.minimap.hide)
  else
    PrintHelp()
  end
end
