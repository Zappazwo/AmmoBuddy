-- AmmoBuddy: helpers on top of the generated item / vendor database (Data.lua)
local ADDON, ns = ...
local L = ns.L
if not ns.enabled then return end

local Data = ns.Data
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
local GetItemIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
local GetItemCount = (C_Item and C_Item.GetItemCount) or GetItemCount

ns.AMMO_FOR_BAG = { quiver = "arrow", pouch = "bullet" }
ns.BAG_FOR_AMMO = { arrow = "quiver", bullet = "pouch" }

local QUALITY_COLOR = {
  [0] = { 0.62, 0.62, 0.62 }, [1] = { 1, 1, 1 }, [2] = { 0.12, 1, 0 },
  [3] = { 0, 0.44, 0.87 }, [4] = { 0.64, 0.21, 0.93 }, [5] = { 1, 0.5, 0 },
}

function ns.QualityColor(q)
  local c = QUALITY_COLOR[q or 1] or QUALITY_COLOR[1]
  return c[1], c[2], c[3]
end

-- Item name in the game's language (English from our data until the client has loaded it).
local GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
function ns.ItemName(itemID)
  local name = GetItemInfo(itemID)
  if name then return name end
  if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(itemID) end
  local item = Data.items[itemID]
  return item and item.name or ("item:" .. itemID)
end

-- Quest title in the game's language, if the client knows it.
local function QuestName(src)
  local title
  if C_QuestLog and C_QuestLog.GetTitleForQuestID then
    title = C_QuestLog.GetTitleForQuestID(src.id)
  elseif C_QuestLog and C_QuestLog.GetQuestInfo then
    title = C_QuestLog.GetQuestInfo(src.id)
  end
  return title or src.name
end

-- Reputation standing in the game's language.
local STANDING = { Friendly = 5, Honored = 6, Revered = 7, Exalted = 8 }
local function StandingName(rank)
  return _G["FACTION_STANDING_LABEL" .. (STANDING[rank] or 5)] or rank
end

function ns.ColoredName(itemID)
  local item = Data.items[itemID]
  local r, g, b = ns.QualityColor(item and item.quality)
  return string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, ns.ItemName(itemID))
end

function ns.ItemIcon(itemID)
  return GetItemIcon(itemID) or "Interface\\Icons\\INV_Misc_QuestionMark"
end

function ns.ItemCount(itemID)
  return GetItemCount(itemID) or 0
end

function ns.MapName(mapID)
  local info = mapID and C_Map.GetMapInfo(mapID)
  return info and info.name
end

-- "arrow" / "bullet" for the equipped ranged weapon, or nil (no bow, gun or crossbow).
function ns.RangedAmmoKind()
  local id = GetInventoryItemID("player", INVSLOT_RANGED or 18)
  if not id then return end
  local _, _, _, _, _, classID, subID = GetItemInfoInstant(id)
  if classID ~= 2 then return end
  if subID == 2 or subID == 18 then return "arrow" end
  if subID == 3 then return "bullet" end
end

---------------------------------------------------------------------------
-- Faction and vendor indexes
---------------------------------------------------------------------------
local playerFaction
function ns.PlayerFaction()
  if not playerFaction then
    local f = UnitFactionGroup("player")
    playerFaction = (f == "Alliance" and "A") or (f == "Horde" and "H") or nil
  end
  return playerFaction
end

-- Vendors with an empty faction are neutral (e.g. need reputation); show them to everybody.
function ns.VendorVisible(vendor)
  local f = ns.PlayerFaction()
  return vendor.faction == "" or not f or vendor.faction:find(f, 1, true) ~= nil
end

ns.vendorsByItem = {} -- [itemID] = { vendorID, ... }
ns.vendorsByMap = {}  -- [uiMapID] = { { id = vendorID, x = 0..1, y = 0..1 }, ... }

for vendorID, vendor in pairs(Data.vendors) do
  local ammo, bag = false, false
  for _, itemID in ipairs(vendor.items) do
    local item = Data.items[itemID]
    if item then
      if item.kind == "arrow" or item.kind == "bullet" then ammo = true else bag = true end
      ns.vendorsByItem[itemID] = ns.vendorsByItem[itemID] or {}
      table.insert(ns.vendorsByItem[itemID], vendorID)
    end
  end
  vendor.sellsAmmo, vendor.sellsBags = ammo, bag
  for _, s in ipairs(vendor.spawns) do
    ns.vendorsByMap[s[1]] = ns.vendorsByMap[s[1]] or {}
    table.insert(ns.vendorsByMap[s[1]], { id = vendorID, x = s[2] / 100, y = s[3] / 100 })
  end
end

function ns.VendorIcon(vendor)
  return ns.ItemIcon(vendor.sellsAmmo and 2512 or 11362)
end

---------------------------------------------------------------------------
-- World positions (shared with the minimap pins)
---------------------------------------------------------------------------
-- Returns continent, north, west (yards) for a map position (0..1).
function ns.WorldPos(mapID, x, y)
  local cont, pos = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
  if not cont or not pos then return end
  local north, west = pos:GetXY()
  return cont, north, west
end

function ns.PlayerWorldPos()
  local mapID = C_Map.GetBestMapForUnit("player")
  if not mapID then return end
  local pos = C_Map.GetPlayerMapPosition(mapID, "player")
  if not pos then return end
  local x, y = pos:GetXY()
  if not x or ns.IsSecret(x) or ns.IsSecret(y) then return end
  return ns.WorldPos(mapID, x, y)
end

-- Cached world position of every vendor spawn: { vendorID, cont, north, west, map, x, y }
local spawnCache
function ns.VendorSpawns()
  if spawnCache then return spawnCache end
  spawnCache = {}
  for mapID, list in pairs(ns.vendorsByMap) do
    for _, e in ipairs(list) do
      local cont, north, west = ns.WorldPos(mapID, e.x, e.y)
      if cont then
        table.insert(spawnCache, { id = e.id, cont = cont, north = north, west = west, map = mapID, x = e.x, y = e.y })
      end
    end
  end
  return spawnCache
end

-- Visible vendors for an item, nearest first: { { id, map, x, y, dist }, ... }
function ns.VendorsForItem(itemID)
  local ids = ns.vendorsByItem[itemID]
  if not ids then return {} end
  local wanted = {}
  for _, id in ipairs(ids) do
    if ns.VendorVisible(Data.vendors[id]) then wanted[id] = true end
  end
  local cont, north, west = ns.PlayerWorldPos()
  local list = {}
  for _, s in ipairs(ns.VendorSpawns()) do
    if wanted[s.id] then
      local dist = math.huge
      if cont and s.cont == cont then
        dist = math.sqrt((s.north - north) ^ 2 + (s.west - west) ^ 2)
      end
      table.insert(list, { id = s.id, map = s.map, x = s.x, y = s.y, dist = dist })
    end
  end
  table.sort(list, function(a, b)
    if a.dist ~= b.dist then return a.dist < b.dist end
    return a.id < b.id
  end)
  return list
end

---------------------------------------------------------------------------
-- Item lists and "best" item
---------------------------------------------------------------------------
function ns.ItemsOfKinds(kinds)
  local list = {}
  for id, item in pairs(Data.items) do
    if kinds[item.kind] then table.insert(list, id) end
  end
  table.sort(list, function(a, b)
    local ia, ib = Data.items[a], Data.items[b]
    if ia.kind ~= ib.kind then return ia.kind < ib.kind end
    if ia.ilvl ~= ib.ilvl then return ia.ilvl < ib.ilvl end
    return a < b
  end)
  return list
end

-- Best item of a kind you can buy from a vendor at your level.
function ns.BestVendorItem(kind)
  local level, best, bestScore = UnitLevel("player"), nil, -1
  for id, item in pairs(Data.items) do
    if item.kind == kind and item.req <= level and #ns.VendorsForItem(id) > 0 then
      local score = item.dps or ((item.slots or 0) * 100 + (item.haste or 0))
      if score > bestScore then best, bestScore = id, score end
    end
  end
  return best
end

---------------------------------------------------------------------------
-- "How to get it" texts
---------------------------------------------------------------------------
local FACTION_ONLY = { A = "Alliance only", H = "Horde only" }
local ALTERAC_VALLEY = 1459

local function VendorLine(v)
  local vendor = Data.vendors[v.id]
  return string.format("%s - %s (%.0f, %.0f)", vendor.name, ns.MapName(v.map) or "?", v.x * 100, v.y * 100)
end

local function SourceText(itemID, src)
  if src.type == "vendor" then
    local list = ns.VendorsForItem(itemID)
    if #list == 0 then return L["Vendor (other faction only)"] end
    return string.format(L["Vendor: %s"], VendorLine(list[1]))
      .. (#list > 1 and ("  " .. string.format(L["+%d more"], #list - 1)) or "")
  elseif src.type == "quest" then
    local t = string.format(L["Quest: %s (level %d)"], QuestName(src), src.level)
    if src.faction then t = t .. " - " .. L[FACTION_ONLY[src.faction]] end
    if src.hunterOnly then t = t .. " - " .. L["Hunter quest"] end
    return t
  elseif src.type == "drop" then
    local zone = ns.MapName(src.map)
    return string.format(L["Drop: %s (level %s)"], src.npc, src.level) .. (zone and (" - " .. zone) or "")
  elseif src.type == "craft" then
    return string.format(L["Crafted: %s"], L[src.profession])
  elseif src.type == "rep" then
    return string.format(L["Requires %s reputation (%s)"], StandingName(src.rank), ns.MapName(ALTERAC_VALLEY) or "Alterac Valley")
  end
end

-- One-line summary for the item lists.
function ns.SourceSummary(itemID)
  local parts = {}
  for _, src in ipairs(Data.items[itemID].sources) do
    local t = SourceText(itemID, src)
    if t then table.insert(parts, t) end
  end
  if #parts == 0 then return L["Unknown source"] end
  return table.concat(parts, "   |cff666666·|r   ")
end

-- Adds the full "How to get it" block to a tooltip.
function ns.AddSourceLines(tooltip, itemID)
  tooltip:AddLine(" ")
  tooltip:AddLine(L["How to get it"], 1, 0.82, 0)
  for _, src in ipairs(Data.items[itemID].sources) do
    if src.type == "vendor" then
      local list = ns.VendorsForItem(itemID)
      if #list == 0 then
        tooltip:AddLine(L["Vendor (other faction only)"], 1, 1, 1)
      else
        local head = #list == 1 and L["Sold by 1 vendor:"] or string.format(L["Sold by %d vendors, nearest first:"], #list)
        tooltip:AddLine(head, 1, 1, 1)
        for i = 1, math.min(#list, 8) do
          tooltip:AddLine("   " .. VendorLine(list[i]), 0.8, 0.8, 0.8)
        end
        if #list > 8 then tooltip:AddLine("   " .. string.format(L["... and %d more"], #list - 8), 0.6, 0.6, 0.6) end
      end
    else
      local t = SourceText(itemID, src)
      if t then tooltip:AddLine(t, 1, 1, 1, true) end
    end
  end
end

-- Opens the world map at the nearest vendor of an item. Returns true on success.
function ns.ShowNearestVendor(itemID)
  local v = ns.VendorsForItem(itemID)[1]
  if not v or InCombatLockdown() then return false end
  if not WorldMapFrame:IsShown() then
    if OpenWorldMap then OpenWorldMap(v.map) else ToggleWorldMap() end
  end
  WorldMapFrame:SetMapID(v.map)
  return true
end
