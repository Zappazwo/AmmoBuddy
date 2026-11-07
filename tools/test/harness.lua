-- Minimal WoW API mock to smoke-test AmmoBuddy logic outside the game.
-- Usage: ADDON_DIR, then dofile this file; results printed.
unpack = unpack or table.unpack
bit = { band = function(a, b) return a & b end }
local out = {}
function print(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring(select(i, ...)) end out[#out + 1] = table.concat(t, " ") end
function strsplit(sep, s, n) local a, b = s:match("^(%S*)%s*(.-)$"); return a, b end
function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
string.trim = strtrim

-- Generic frame mock ---------------------------------------------------------
local frames = {}
ALL_FRAMES = frames
local Frame = {}
local DATA_KEYS = { scripts = true, events = true, text = true, shown = true, w = true, h = true, mapID = true,
  point = true, lines = true, fs = true, kind = true, name = true, itemID = true, vendorID = true }
Frame.__index = function(t, k)
  if DATA_KEYS[k] or k == "AmmoBuddyHooked" or (type(k) == "string" and k:match("^%l")) then return nil end
  return Frame[k] or function() end
end
function Frame:SetScript(name, fn) self.scripts = self.scripts or {}; self.scripts[name] = fn end
function Frame:GetScript(name) return self.scripts and self.scripts[name] end
function Frame:HookScript(name, fn) self:SetScript(name, fn) end
function Frame:RegisterEvent(e) self.events = self.events or {}; self.events[e] = true end
function Frame:RegisterUnitEvent(e) self:RegisterEvent(e) end
function Frame:UnregisterEvent(e) if self.events then self.events[e] = nil end end
function Frame:CreateTexture() return setmetatable({}, Frame) end
function Frame:CreateFontString() local f = setmetatable({}, Frame); f.SetText = function(s, t) s.text = t end; return f end
function Frame:GetWidth() return self.w or 140 end
function Frame:GetHeight() return self.h or 300 end
function Frame:SetWidth(w) self.w = w end
function Frame:SetHeight(h) self.h = h end
function Frame:SetSize(w, h) self.w, self.h = w, h end
function Frame:GetSize() return 1000, 700 end
function Frame:GetFrameLevel() return rawget(self, 'level') or 1 end
function Frame:SetFrameLevel(l) rawset(self, 'level', l) end
function Frame:GetVerticalScrollRange() return 0 end
function Frame:GetVerticalScroll() return 0 end
function Frame:IsShown() return self.shown ~= false end
function Frame:Show() self.shown = true; local s = self:GetScript("OnShow"); if s then s(self) end end
function Frame:Hide() self.shown = false end
function Frame:SetShown(v) if v then self:Show() else self:Hide() end end
function Frame:SetPoint(...) self.point = { ... } end
function Frame:HasFocus() return false end
function Frame:SetText(t) self.text = t end
function Frame:GetText() return self.text end
function Frame:SetFontString(fs) self.fs = fs end
function Frame:GetCanvas() return self end
function Frame:GetCanvasScale() return 1 end
function Frame:GetMapID() return self.mapID end
function Frame:GetZoom() return 0 end
function CreateFrame(kind, name, parent, template)
  local f = setmetatable({ kind = kind, name = name }, Frame)
  frames[#frames + 1] = f
  if name then _G[name] = f end
  return f
end
UIParent = CreateFrame("Frame", "UIParent")
Minimap = CreateFrame("Frame", "Minimap"); Minimap.w = 140
WorldMapFrame = CreateFrame("Frame", "WorldMapFrame")
WorldMapFrame.OnMapChanged = function() end
GameTooltip = CreateFrame("GameTooltip", "GameTooltip")
GameTooltip.lines = {}
GameTooltip.AddLine = function(self, t) self.lines[#self.lines + 1] = t end
GameTooltip.AddDoubleLine = function(self, a, b) self.lines[#self.lines + 1] = a .. " | " .. b end
RaidWarningFrame = CreateFrame("Frame")
UISpecialFrames = {}
SlashCmdList = {}
function hooksecurefunc(t, k, fn) end
function GameTooltip_Hide() end
function RaidNotice_AddMessage(_, msg) out[#out + 1] = "RAID: " .. msg end
function PlaySound() end
SOUNDKIT = {}
ChatTypeInfo = { RAID_WARNING = {} }
C_Timer = { After = function(_, fn) fn() end }
function GetCVar() return "0" end
function IsIndoors() return false end
function GetPlayerFacing() return 0 end
function InCombatLockdown() return false end
function IsShiftKeyDown() return false end
function IsModifiedClick() return false end

-- Player / items -------------------------------------------------------------
PLAYER = { level = 45, faction = "Alliance", ranged = 1001, ammo = 11285, ammoCount = 700, money = 1000000 }
function UnitClass() return "Hunter", "HUNTER" end
function UnitLevel() return PLAYER.level end
function UnitFactionGroup() return PLAYER.faction end
INVSLOT_AMMO, INVSLOT_RANGED = 0, 18
function GetInventoryItemID(_, slot)
  if slot == 0 then return PLAYER.ammo end
  if slot == 18 then return PLAYER.ranged end
end
function GetInventoryItemTexture(_, slot) if slot == 0 and PLAYER.ammo then return "tex" end end
function GetInventoryItemCount() return PLAYER.ammoCount end
function GetInventoryItemLink() return nil end
function GetItemInfoInstant(id)
  if id == 1001 then return id, "Weapon", "Bows", "", "", 2, 2 end
  if id == 1002 then return id, "Weapon", "Guns", "", "", 2, 3 end
  return id, "Projectile", "Arrow", "", "", 6, 2
end
function GetItemInfo(id) return "Item" .. id, "|Hitem:" .. id .. "|h", 1, 1, 1, "", "", 200 end
function GetItemIcon(id) return "icon" .. id end
BAG_ITEMS = {}
function GetItemCount(id) local n = 0 for _, b in pairs(BAG_ITEMS) do for _, s in pairs(b) do if s.id == id then n = n + s.count end end end return n end
function GetMoney() return PLAYER.money end
function GetCoinTextureString(c) return c .. "c" end

-- Bags: bag 0 = backpack 16 slots, bag 1 = quiver
BAGS = { [0] = { slots = 16, family = 0 }, [1] = { slots = 16, family = 1 } }
NUM_BAG_SLOTS = 4
C_Container = {
  GetContainerNumSlots = function(bag) return BAGS[bag] and BAGS[bag].slots or 0 end,
  GetContainerNumFreeSlots = function(bag) if not BAGS[bag] then return 0, 0 end return 0, BAGS[bag].family end,
  GetContainerItemInfo = function(bag, slot)
    local s = BAG_ITEMS[bag] and BAG_ITEMS[bag][slot]
    if s then return { itemID = s.id, stackCount = s.count } end
  end,
}

-- Merchant
MERCHANT = {}
BOUGHT = {}
function GetMerchantNumItems() return #MERCHANT end
function GetMerchantItemID(i) return MERCHANT[i].id end
function GetMerchantItemInfo(i) local m = MERCHANT[i]; return "x", "t", m.price, 200, -1, true, true, nil end
function GetMerchantItemMaxStack() return 1000 end
function BuyMerchantItem(i, n) BOUGHT[#BOUGHT + 1] = { id = MERCHANT[i].id, n = n } end
MerchantFrame = CreateFrame("Frame", "MerchantFrame")

-- Map: zone = identity mapping in "yards": world north = (1-y)*1000, west = (1-x)*1000
CreateVector2D = function(x, y) return { x = x, y = y, GetXY = function(v) return v.x, v.y end } end
PLAYER_POS = { map = 1429, x = 0.4396, y = 0.6592 }
C_Map = {
  GetMapInfo = function(id) return { name = "Map" .. id } end,
  GetBestMapForUnit = function() return PLAYER_POS.map end,
  GetPlayerMapPosition = function(map) return CreateVector2D(PLAYER_POS.x, PLAYER_POS.y) end,
  GetWorldPosFromMapPos = function(map, pos)
    local cont = (map >= 1411 and map <= 1413) or (map >= 1438 and map <= 1459 and map ~= 1453 and map ~= 1455) and 1 or 0
    return cont, CreateVector2D((1 - pos.y) * 1000 + map * 10000, (1 - pos.x) * 1000)
  end,
}
function GetAddOnMetadata() return "1.3.0" end
function ChatEdit_InsertLink() end
function OpenWorldMap(map) WorldMapFrame.mapID = map end
function WorldMapFrame:SetMapID(map) self.mapID = map end


-- Blizzard map canvas pin system (data providers + pin pools) ----------------
function CreateFromMixins(...) local t = {} for _, m in ipairs({ ... }) do for k, v in pairs(m) do t[k] = v end end return t end
function Mixin(obj, ...) for _, m in ipairs({ ... }) do for k, v in pairs(m) do obj[k] = v end end return obj end
MapCanvasDataProviderMixin = { GetMap = function(self) return self.owningMap end }
MapCanvasPinMixin = {
  UseFrameLevelType = function(self, t) self.levelType = t end,
  SetScalingLimits = function() end,
  SetPosition = function(self, x, y) self.pos = { x, y } end,
}
function CreateFramePool() return {} end
WorldMapFrame.pinPools = {}
WorldMapFrame.activePins = {}
function WorldMapFrame:AddDataProvider(p) p.owningMap = self end
function WorldMapFrame:AcquirePin(template, ...)
  local pool = self.pinPools[template]
  local pin = pool.createFunc()
  pin.pinTemplate = template
  self.activePins[#self.activePins + 1] = pin
  pin:OnAcquired(...)
  return pin
end
function WorldMapFrame:RemoveAllPinsByTemplate(template)
  local keep = {}
  for _, pin in ipairs(self.activePins) do
    if pin.pinTemplate == template then self.pinPools[template].resetFunc(nil, pin) else keep[#keep + 1] = pin end
  end
  self.activePins = keep
end

return out
