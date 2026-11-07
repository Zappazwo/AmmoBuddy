-- AmmoBuddy: vendor pins on the world map and the minimap (no libraries)
local ADDON, ns = ...
if not ns.enabled then return end

local Data = ns.Data
local PIN_SIZE_MAP, PIN_SIZE_MINIMAP = 18, 14

-- Minimap diameter in yards per zoom level (same values HereBeDragons uses).
local MINIMAP_YARDS = {
  outdoor = { [0] = 466 + 2 / 3, [1] = 400, [2] = 333 + 1 / 3, [3] = 266 + 2 / 3, [4] = 200, [5] = 133 + 1 / 3 },
  indoor  = { [0] = 300, [1] = 240, [2] = 180, [3] = 120, [4] = 80, [5] = 50 },
}

---------------------------------------------------------------------------
-- Pins and tooltip
---------------------------------------------------------------------------
local function ShowVendorTooltip(pin)
  local vendor = Data.vendors[pin.vendorID]
  if not vendor then return end
  GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
  GameTooltip:SetText(vendor.name, 1, 1, 1)
  if vendor.title then GameTooltip:AddLine(vendor.title, 0.6, 0.6, 0.6) end
  GameTooltip:AddLine(" ")
  local level = UnitLevel("player")
  for _, itemID in ipairs(vendor.items) do
    local item = Data.items[itemID]
    if item then
      local line = string.format("|T%s:16|t %s", ns.ItemIcon(itemID), ns.ColoredName(itemID))
      local r, g, b = 0.8, 0.8, 0.8
      if item.req > level then r, g, b = 1, 0.25, 0.25 end
      GameTooltip:AddDoubleLine(line, "Level " .. item.req, 1, 1, 1, r, g, b)
    end
  end
  GameTooltip:Show()
end

local function CreatePin(parent, size)
  local pin = CreateFrame("Button", nil, parent)
  pin:SetSize(size, size)
  local border = pin:CreateTexture(nil, "BACKGROUND")
  border:SetAllPoints()
  border:SetColorTexture(0, 0, 0, 0.85)
  pin.icon = pin:CreateTexture(nil, "ARTWORK")
  pin.icon:SetPoint("TOPLEFT", 1, -1)
  pin.icon:SetPoint("BOTTOMRIGHT", -1, 1)
  pin.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  pin:SetScript("OnEnter", ShowVendorTooltip)
  pin:SetScript("OnLeave", GameTooltip_Hide)
  return pin
end

---------------------------------------------------------------------------
-- World map
---------------------------------------------------------------------------
local worldPins, worldUsed = {}, 0

function ns.RefreshWorldMapPins()
  for i = 1, #worldPins do worldPins[i]:Hide() end
  worldUsed = 0
  if not ns.db or not ns.db.mapPins or not WorldMapFrame or not WorldMapFrame:IsShown() then return end

  local list = ns.vendorsByMap[WorldMapFrame:GetMapID()]
  if not list then return end
  local canvas = WorldMapFrame:GetCanvas()
  local w, h = canvas:GetSize()
  local scale = WorldMapFrame.GetCanvasScale and (1 / WorldMapFrame:GetCanvasScale()) or 1

  for _, e in ipairs(list) do
    local vendor = Data.vendors[e.id]
    if ns.VendorVisible(vendor) then
      worldUsed = worldUsed + 1
      local pin = worldPins[worldUsed]
      if not pin then
        pin = CreatePin(canvas, PIN_SIZE_MAP)
        worldPins[worldUsed] = pin
      end
      pin.vendorID = e.id
      pin.icon:SetTexture(ns.VendorIcon(vendor))
      pin:SetScale(scale)
      pin:SetFrameLevel(canvas:GetFrameLevel() + 500)
      pin:ClearAllPoints()
      -- SetPoint offsets are in the pin's own (scaled) units.
      pin:SetPoint("CENTER", canvas, "TOPLEFT", e.x * w / scale, -e.y * h / scale)
      pin:Show()
    end
  end
end

local function HookWorldMap()
  if not WorldMapFrame or WorldMapFrame.AmmoBuddyHooked then return end
  WorldMapFrame.AmmoBuddyHooked = true
  WorldMapFrame:HookScript("OnShow", ns.RefreshWorldMapPins)
  hooksecurefunc(WorldMapFrame, "OnMapChanged", ns.RefreshWorldMapPins)
  if WorldMapFrame.OnCanvasScaleChanged then
    hooksecurefunc(WorldMapFrame, "OnCanvasScaleChanged", ns.RefreshWorldMapPins)
  end
end

---------------------------------------------------------------------------
-- Minimap
---------------------------------------------------------------------------
local miniPins = {}
local updater = CreateFrame("Frame")
local elapsed = 0

local function HideMinimapPins(from)
  for i = from or 1, #miniPins do miniPins[i]:Hide() end
end

local function UpdateMinimapPins()
  local cont, pNorth, pWest = ns.PlayerWorldPos()
  if not cont then HideMinimapPins(); return end

  local zoom = Minimap:GetZoom()
  local yards = (IsIndoors() and MINIMAP_YARDS.indoor or MINIMAP_YARDS.outdoor)[zoom] or 400
  local size = Minimap:GetWidth()
  local radius = size / 2 - PIN_SIZE_MINIMAP / 2
  local pxPerYard = size / yards
  local square = GetMinimapShape and GetMinimapShape() == "SQUARE"

  local facing = 0
  if GetCVar("rotateMinimap") == "1" then
    facing = GetPlayerFacing()
    if not facing or ns.IsSecret(facing) then facing = 0 end
  end
  local cosF, sinF = math.cos(facing), math.sin(facing)

  local used = 0
  for _, s in ipairs(ns.VendorSpawns()) do
    if s.cont == cont and ns.VendorVisible(Data.vendors[s.id]) then
      local north, east = s.north - pNorth, pWest - s.west
      -- Rotating minimap: turn the map so that the player's facing points up.
      local x = (east * cosF + north * sinF) * pxPerYard
      local y = (-east * sinF + north * cosF) * pxPerYard
      local inside
      if square then
        inside = math.abs(x) <= radius and math.abs(y) <= radius
      else
        inside = x * x + y * y <= radius * radius
      end
      if inside then
        used = used + 1
        local pin = miniPins[used]
        if not pin then
          pin = CreatePin(Minimap, PIN_SIZE_MINIMAP)
          miniPins[used] = pin
        end
        pin.vendorID = s.id
        pin.icon:SetTexture(ns.VendorIcon(Data.vendors[s.id]))
        pin:SetFrameLevel(Minimap:GetFrameLevel() + 5)
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", Minimap, "CENTER", x, y)
        pin:Show()
      end
    end
  end
  HideMinimapPins(used + 1)
end

updater:SetScript("OnUpdate", function(_, dt)
  elapsed = elapsed + dt
  if elapsed < 0.1 then return end
  elapsed = 0
  UpdateMinimapPins()
end)

function ns.RefreshMinimapPins()
  if ns.db.minimapPins then
    updater:Show()
  else
    updater:Hide()
    HideMinimapPins()
  end
end

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------
function ns.SetMapPins(v)
  ns.db.mapPins = v
  ns.RefreshWorldMapPins()
  if ns.RefreshWindow then ns.RefreshWindow() end
end

function ns.SetMinimapPins(v)
  ns.db.minimapPins = v
  ns.RefreshMinimapPins()
  if ns.RefreshWindow then ns.RefreshWindow() end
end

updater:Hide()
table.insert(ns.onReady, function()
  HookWorldMap()
  if not WorldMapFrame then
    -- The world map may be load-on-demand; hook it once it is loaded.
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, _, name)
      if name == "Blizzard_WorldMap" then HookWorldMap(); self:UnregisterAllEvents() end
    end)
  end
  ns.RefreshMinimapPins()
end)
