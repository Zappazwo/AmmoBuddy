-- AmmoBuddy: buys the best ammo for your weapon when you open a vendor.
-- Only fills your quiver / ammo pouch and never fills up your normal bags.
local ADDON, ns = ...
local L = ns.L
if not ns.enabled then return end

local Data = ns.Data
local KEEP_FREE_BAG_SLOTS = 2 -- normal bag slots that auto-buy never uses
local BAG_FAMILY = { arrow = 1, bullet = 2 } -- container family bits: quiver / ammo pouch

local C = C_Container or {}
local GetNumSlots = C.GetContainerNumSlots or GetContainerNumSlots
local GetNumFreeSlots = C.GetContainerNumFreeSlots or GetContainerNumFreeSlots
local GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local GetCoinText = GetCoinTextureString or (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString)

local function SlotItem(bag, slot)
  if C.GetContainerItemInfo then
    local info = C.GetContainerItemInfo(bag, slot)
    if info then return info.itemID, info.stackCount end
    return
  end
  local _, count, _, _, _, _, _, _, _, id = GetContainerItemInfo(bag, slot)
  return id, count
end

local function MerchantItem(index)
  if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
    local info = C_MerchantFrame.GetItemInfo(index)
    if not info then return end
    return info.price, info.stackCount, info.numAvailable, info.isUsable, info.hasExtendedCost
  end
  local _, _, price, stackCount, numAvailable, _, isUsable, extendedCost = GetMerchantItemInfo(index)
  return price, stackCount, numAvailable, isUsable, extendedCost
end

-- Total slots of all equipped quivers (kind "arrow") or ammo pouches (kind "bullet").
function ns.DetectAmmoBagSlots(kind)
  local family, total = BAG_FAMILY[kind], 0
  if not family then return 0 end
  for bag = 1, NUM_BAG_SLOTS or 4 do
    local slots = GetNumSlots(bag) or 0
    local _, bagFamily = GetNumFreeSlots(bag)
    if slots > 0 and bagFamily and bit.band(bagFamily, family) ~= 0 then
      total = total + slots
    end
  end
  return total
end

-- Room for itemID: in matching ammo bags, and in normal bags (keeping some slots free).
local function Room(itemID, kind, stack)
  local family = BAG_FAMILY[kind]
  local ammoRoom, ammoSlots, partialRoom, emptyNormal = 0, 0, 0, 0
  for bag = 0, NUM_BAG_SLOTS or 4 do
    local slots = GetNumSlots(bag) or 0
    local _, bagFamily = GetNumFreeSlots(bag)
    bagFamily = bagFamily or 0
    local isAmmoBag = bit.band(bagFamily, family) ~= 0
    if slots > 0 and (isAmmoBag or bagFamily == 0) then
      if isAmmoBag then ammoSlots = ammoSlots + slots end
      for slot = 1, slots do
        local id, count = SlotItem(bag, slot)
        local free = 0
        if not id then
          free = stack
          if not isAmmoBag then emptyNormal = emptyNormal + 1; free = 0 end
        elseif id == itemID then
          free = stack - (count or 0)
        end
        if isAmmoBag then ammoRoom = ammoRoom + free else partialRoom = partialRoom + free end
      end
    end
  end
  local normalRoom = partialRoom + math.max(0, emptyNormal - KEEP_FREE_BAG_SLOTS) * stack
  return ammoRoom, ammoSlots, normalRoom
end

local function BestMerchantAmmo(kind)
  local level, best = UnitLevel("player"), nil
  for i = 1, GetMerchantNumItems() do
    local id = GetMerchantItemID(i)
    local item = id and Data.items[id]
    if item and item.kind == kind and item.req <= level then
      local price, stackCount, numAvailable, isUsable, extendedCost = MerchantItem(i)
      if price and price > 0 and not extendedCost and isUsable ~= false and numAvailable ~= 0
        and (not best or item.dps > best.item.dps) then
        best = { index = i, id = id, item = item, price = price, stackCount = math.max(stackCount or 1, 1),
                 numAvailable = numAvailable }
      end
    end
  end
  return best
end

function ns.AutoBuy()
  if not ns.db.autoBuy then return end
  local kind = ns.RangedAmmoKind()
  if not kind then return end
  local best = BestMerchantAmmo(kind)
  if not best then return end

  -- Don't replace better ammo you already use.
  local equipped = Data.items[GetInventoryItemID("player", ns.AMMO_SLOT) or 0]
  if equipped and equipped.kind == kind and equipped.dps > best.item.dps then return end

  local stack = select(8, GetItemInfo(best.id)) or 200
  local ammoRoom, ammoSlots, normalRoom = Room(best.id, kind, stack)

  local need
  if ns.db.autoSlots and ammoSlots > 0 then
    need = ammoRoom -- fill the quiver / ammo pouch, nothing else
  else
    -- Manual slot count, also the fallback when no matching quiver / pouch is equipped.
    need = ns.db.quiverSlots * stack - ns.ItemCount(best.id)
    need = math.min(need, ammoRoom + normalRoom)
  end

  -- Vendors sell ammo in bundles (e.g. 200); only buy whole bundles.
  local bundle = best.stackCount
  local unitPrice = best.price / bundle
  need = math.min(need, math.floor(GetMoney() / unitPrice))
  if best.numAvailable and best.numAvailable > 0 then need = math.min(need, best.numAvailable * bundle) end
  need = math.floor(need / bundle) * bundle
  if need <= 0 then return end

  local maxPerBuy = math.max(bundle, math.floor((GetMerchantItemMaxStack(best.index) or bundle) / bundle) * bundle)
  local left = need
  while left > 0 do
    local n = math.min(left, maxPerBuy)
    BuyMerchantItem(best.index, n)
    left = left - n
  end
  local cost = math.floor(unitPrice * need + 0.5)
  ns.Print(string.format(L["Bought %d %s for %s."], need, ns.ColoredName(best.id), GetCoinText and GetCoinText(cost) or cost))
end

function ns.SetAutoBuy(v) ns.db.autoBuy = v; if ns.RefreshWindow then ns.RefreshWindow() end end
function ns.SetAutoSlots(v) ns.db.autoSlots = v; if ns.RefreshWindow then ns.RefreshWindow() end end
function ns.SetQuiverSlots(v)
  ns.db.quiverSlots = math.max(0, math.min(40, math.floor(v)))
  if ns.RefreshWindow then ns.RefreshWindow() end
end

local f = CreateFrame("Frame")
f:RegisterEvent("MERCHANT_SHOW")
f:SetScript("OnEvent", function()
  if IsShiftKeyDown() then return end -- hold Shift to skip auto-buy
  C_Timer.After(0.3, function()
    if MerchantFrame and MerchantFrame:IsShown() then ns.AutoBuy() end
  end)
end)
