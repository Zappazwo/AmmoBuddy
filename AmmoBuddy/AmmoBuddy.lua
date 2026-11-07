-- AmmoBuddy: lightweight ammo counter for Hunters (WoW Forever / Classic Era / TBC)
local ADDON = ...
local AMMO_SLOT = INVSLOT_AMMO or 0

-- WoW Forever uses the Midnight addon restrictions: some values are "secret"
-- during combat and must not be compared or used in arithmetic. Displaying them is fine.
local function IsSecret(v)
  return issecretvalue and issecretvalue(v) or false
end

local _, class = UnitClass("player")
if class ~= "HUNTER" then return end

local defaults = { warn = 200, locked = false, point = { "CENTER", "CENTER", 0, -180 } }
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
f:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  if GetInventoryItemLink("player", AMMO_SLOT) then
    GameTooltip:SetInventoryItem("player", AMMO_SLOT)
  else
    GameTooltip:SetText("AmmoBuddy")
  end
  GameTooltip:AddLine("Type /ammo for options", 0.7, 0.7, 0.7)
  GameTooltip:Show()
end)
f:SetScript("OnLeave", GameTooltip_Hide)

local function Update()
  local tex = GetInventoryItemTexture("player", AMMO_SLOT)
  local count = tex and GetInventoryItemCount("player", AMMO_SLOT) or 0
  icon:SetTexture(tex or "Interface\\Icons\\INV_Ammo_Arrow_02")
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

f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 ~= ADDON then return end
    AmmoBuddyDB = AmmoBuddyDB or {}
    db = AmmoBuddyDB
    for k, v in pairs(defaults) do if db[k] == nil then db[k] = v end end
    ApplyPosition()
    self:UnregisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
  else
    QueueUpdate()
  end
end)

local function Print(msg) print("|cffabd473AmmoBuddy:|r " .. msg) end

SLASH_AMMOBUDDY1 = "/ammo"
SLASH_AMMOBUDDY2 = "/ammobuddy"
SlashCmdList.AMMOBUDDY = function(input)
  local cmd, arg = strsplit(" ", strtrim(input or ""):lower(), 2)
  if cmd == "lock" then
    db.locked = true; Print("Frame locked.")
  elseif cmd == "unlock" then
    db.locked = false; Print("Frame unlocked - left-click and drag to move it.")
  elseif cmd == "warn" and tonumber(arg) then
    db.warn = tonumber(arg); warned = false; Update()
    Print("Warning threshold set to " .. db.warn .. ".")
  elseif cmd == "reset" then
    db.point = { unpack(defaults.point) }; ApplyPosition(); Print("Position reset.")
  elseif cmd == "hide" then
    f:Hide()
  elseif cmd == "show" then
    f:Show(); Update()
  else
    Print("Commands: lock, unlock, warn <amount> (current: " .. db.warn .. "), reset, show, hide")
  end
end
