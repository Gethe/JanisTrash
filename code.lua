local _, ns = ...

local HBDP = _G.LibStub("HereBeDragons-Pins-2.0")

-- https://www.wowhead.com/achievement=12482/get-hekd
local ZANDALAR_MAP_ID = 1642
local introQuests = {
    Horde = {
        {quest = 47441, x = 1076.9038117188, y = -620.23978984375},
        {quest = 47442, x = 1215.7229570313, y = -405.85644414063},
    },
    Alliance = {
        {quest = 51142, x = 4196.8896151367, y = 2872.8127099609},
        {quest = 51145, x = 4227.5458607422, y = 2667.0752394531},
    }
}
local pins = {
    -- Zuldazar 862
    {quest = 50381, x = 465.7609890625, y = -1266.2106604492}, -- The Great Hat Robbery
    {quest = 50332, x = 106.01625273437, y = 441.52193808594}, -- Big Hunter Mon
    {quest = 50308, x = -357.84284257812, y = -949.7131421875, item = 156963}, -- Golden Ravasaur Egg
    {quest = 50431, x = 400.58370742188, y = 218.11192519531, item = 157794}, -- Feathered Viper Scale
    -- Nazmir 863
    {quest = 50444, x = 610.23339189453, y = 932.38970732422}, -- Taking the Loa Road
    {quest = 50441, x = -156.04551894531, y = 2379.1001978516, item = 157802}, -- Nazwathan Relic
    {quest = 50437, x = 1660.1247851562, y = 898.06929384766, item = 157801}, -- Snapjaw Tail
    {quest = 50435, x = -805.72818701172, y = 1887.4077435547, item = 157797}, -- Vilescale Pearl
    -- Vol'dun 864
    {quest = 50901, x = 3818.1146694336, y = 1066.1379689453}, -- Saurid Surprise
    {quest = 50890, x = 2858.2335570312, y = 3644.4417660156, item = 158915}, -- Polished Ringhorn Hoof
    {quest = 50892, x = 3328.9772395508, y = 506.60471582031, item = 158916}, -- Sturdy Redrock Jaw
    {quest = 50883, x = 3491.7959662109, y = 2222.4461365234, item = 158910}, -- Charged Ranishu Antennae
}

local GameTooltip = _G.WorldMapTooltip or _G.GameTooltip
local function onEnter(this)
    local text
    if this.pin.item then
        text = this.pin.item:GetItemName()
    else
        text = _G.C_QuestLog.GetQuestInfo(this.pin.quest)
    end

    GameTooltip:SetOwner(this, "ANCHOR_CURSOR_RIGHT")
    GameTooltip:SetText(text or "Loading...")
    GameTooltip:Show()
end
local function onLeave(this)
    GameTooltip:Hide()
end
local function CreateIcon(pin)
    local icon = _G.CreateFrame("Frame")
    icon:SetSize(32, 32)
    icon:SetScript("OnEnter", onEnter)
    icon:SetScript("OnLeave", onLeave)
    icon.pin = pin

    local texture = icon:CreateTexture(nil, "ARTWORK")
    texture:SetTexture([[Interface/AddOns/Jani's Trash/icons]])
    texture:SetAllPoints()

    if pin.item then
        texture:SetTexCoord(0.5, 1.0, 0.0, 0.5)
    else
        texture:SetTexCoord(0.0, 0.5, 0.0, 0.5)
    end

    return icon
end


local function SearchBagsForItem(itemID)
    for bagID = 0, _G.NUM_BAG_SLOTS do
        for slotIndex = 1, _G.GetContainerNumSlots(bagID) do
            local id = _G.GetContainerItemID(bagID, slotIndex)
            if id == itemID then
                return bagID, slotIndex
            end
        end
    end
    return false
end
local function ShouldFloatOnEdge(pin)
    local floatOnEdge = false
    if pin.item then
        local bagID, slotIndex = SearchBagsForItem(pin.item:GetItemID())
        if bagID then
            floatOnEdge = true
            if not pin.item:HasItemLocation() then
                pin.item:SetItemLocation(_G.ItemLocation:CreateFromBagAndSlot(bagID, slotIndex))
            end
        end
    end

    return floatOnEdge
end


local function AddPin(pin)
    local icon = pin.icon
    if not icon then
        if pin.item then
            pin.item = _G.Item:CreateFromItemID(pin.item)
        end
        icon = {}
        icon.world = CreateIcon(pin)
        icon.mini = CreateIcon(pin)
        pin.icon = icon
    end

    HBDP:AddWorldMapIconWorld(ns, icon.world, ZANDALAR_MAP_ID, pin.x, pin.y, 1)
    HBDP:AddMinimapIconWorld(ns, icon.mini, ZANDALAR_MAP_ID, pin.x, pin.y, ShouldFloatOnEdge(pin))
end


local faction, finished = introQuests[_G.UnitFactionGroup("player") or "Horde"], false
local function IntroIsFinished()
    if not finished then
        for i=1, #faction do
            local pin = faction[i]
            if not _G.IsQuestFlaggedCompleted(pin.quest) then
                AddPin(pin)
                return false
            end
        end
        finished = true
    end
    return true
end


local function UpdatePins(questID)
    HBDP:RemoveAllWorldMapIcons(ns)
    HBDP:RemoveAllMinimapIcons(ns)

    if IntroIsFinished() then
        for i=1, #pins do
            local pin = pins[i]
            if not _G.IsQuestFlaggedCompleted(pin.quest) then
                AddPin(pin)
            end
        end
    end
end


local eventFrame = _G.CreateFrame("Frame")
eventFrame:RegisterEvent("QUEST_REMOVED")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    UpdatePins(...)
end)
UpdatePins()
