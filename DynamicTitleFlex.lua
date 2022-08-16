DynamicTitleFlex = {
  name = "DynamicTitleFlex",
  version = "1.0.3",
  author = "@Complicative",
}

DynamicTitleFlex.Settings = {
  --Saved Settings
  defaultTitle = nil,
  dungeon = true,
  arena = true,
  trial = true,
  chatOutput = true,
}

DynamicTitleFlex.tempDB = {
  --only used for debugging
}

local LAM2 = LibAddonMenu2
local debug = false

--Used to check, if player changed the title (will be saved as default title) or by this addon (ignored)
DynamicTitleFlex.changedByAddon = false

-- /script for i=1,40 do name = GetAchievementCategoryInfo(i) d(i .. " " .. name) end
-- /script d(GetAchievementName(GetAchievementId((topLevelIndex, nilable categoryIndex, achievementIndex))))

DynamicTitleFlex.db = {
  --DB with all instances and their achievement ids, sorted descending by priority (exceptions noted in brackets)
  --Tier:
  --1 - Dungeon
  --2 - Arena
  --3 - Trial
  [677] = { 1330, 1305, 1304, ["tier"] = 2 }, --Maelstrom
  [725] = { 1391, ["tier"] = 3 }, --Maw of Lorkhaj
  [848] = { 1538, ["tier"] = 1 }, --Cradle of Shadows
  [843] = { 1538, ["tier"] = 1 }, --Ruins of Mazzatun
  [973] = { 1696, 1691, ["tier"] = 1 }, --Bloodroot Forge
  [974] = { 1704, 1699, ["tier"] = 1 }, --Falkreath Hold
  [1000] = { 2075, 2087, 2079, 2077, 2076, ["tier"] = 3 }, --Asylum Sanctorium
  [1010] = { 1981, 1976, ["tier"] = 1 }, --Scalecaller Peak
  [1009] = { 1965, 1960, ["tier"] = 1 }, --Fang Lair
  [1055] = { 2164, 2163, ["tier"] = 1 }, --March of Sacrifices
  [1052] = { 2154, 2153, ["tier"] = 1 }, --Moonhunter Keep
  [1082] = { 2368, 2363, 2362, ["tier"] = 2 }, --Blackrose Prison
  [1080] = { 2266, ["tier"] = 1 }, --Frostvault
  [1081] = { 2275, ["tier"] = 1 }, --Depths of Malatar
  [1122] = { 2421, 2417, ["tier"] = 1 }, --Moongrave Fane
  [1123] = { 2430, 2427, ["tier"] = 1 }, --Lair of Maarselook
  [1153] = { 2555, 2551, ["tier"] = 1 }, --Unhallowed Grave
  [1152] = { 2546, 2541, ["tier"] = 1 }, --Icereach
  [1197] = { 2701, 2755, ["tier"] = 1 }, --Stone Garden
  [1201] = { 2710, 2706, ["tier"] = 1 }, --Castle Thorn
  [1227] = { 2912, 2913, 2908, ["tier"] = 2 }, --Vateshran Hollows
  [1228] = { 2838, 2833, ["tier"] = 1 }, --Black Drake Villa
  [1229] = { 2847, 2843, ["tier"] = 1 }, --The Cauldron
  [1267] = { 3023, 3018, ["tier"] = 1 }, --Red Pettal Bastion
  [1268] = { 3032, 3028, ["tier"] = 1 }, --The Dread Cellar
  [1301] = { 3111, 3226, 3153, ["tier"] = 1 }, --Coral Aerie
  [1302] = { 3120, 3224, 3154, ["tier"] = 1 }, --Shipwrihts Regret
  [975] = { 1838, 1837, 1836, 1810, 1808, ["tier"] = 3 }, --Halls of Fabrication
  [1051] = { 2139, 2140, 2136, 2133, 2131, ["tier"] = 3 }, --Cloudrest
  [1121] = { 2467, 2466, 2435, 2433, ["tier"] = 3 }, --Sunspire (2468 actually highest, but Godslayer is the one people prefere)
  [1196] = { 2746, 2740, 2739, 2734, 2732, ["tier"] = 3 }, --Kyne's Aegis
  [1263] = { 3003, 3007, 2987, 2985, ["tier"] = 3 }, --Rockgrove (3004 actually highest, but Planesbreaker is the one people prefere)
  [1344] = { 3249, 3248, 3252, 3244, 3242, ["tier"] = 3 }, --Dreadsail Reef
  [635] = { 992, 1140, ["tier"] = 2 }, --Dragonstar Arena
  [636] = { 1474, ["tier"] = 3 }, --Hel Ra Citadel
  [638] = { 1503, ["tier"] = 3 }, --Aetherian Archive
  [639] = { 1462, ["tier"] = 3 }, --Sanctum Ophidia
}
--------------------------------------

--Some better looking messages
local function cStart(hex)
  return "|c" .. hex
end

local function cEnd()
  return "|r"
end

local function getTimeStamp()
  return cStart(888888) .. "[" .. os.date('%H:%M:%S') .. "] " .. cEnd()
end

---------------------------------------------
-- OnAddOnLoaded --
---------------------------------------------

function DynamicTitleFlex.OnAddOnLoaded(event, addonName) --initialize the addon
  if addonName ~= DynamicTitleFlex.name then return end

  --Saved Settings
  DynamicTitleFlex.Settings = ZO_SavedVars:New('DynamicTitleFlexSettings', 1, nil, DynamicTitleFlex.Settings)
  if debug then
    --only for debugging. Makes Saved Vars with all achievements and their ID (important), that reward a title, if /saveachiev has been called in game
    DynamicTitleFlex.tempDB = ZO_SavedVars:NewAccountWide('DynamicTitleFlexDB', 7, nil, { ["iDB"] = {} })
  end


  -------------------------------------------
  -- Settings --
  -------------------------------------------
  local panelData = {
    type = "panel",
    name = "DynamicTitleFlex",
    author = '@Complicative',
    version = DynamicTitleFlex.version,
    website = "https://github.com/Complicative/DynamicTitleFlex",
  }

  LAM2:RegisterAddonPanel("DynamicTitleFlexOptions", panelData)

  local optionsData = {}
  optionsData[#optionsData + 1] = {
    type = "description",
    text = "Changes your title to the highest available for a given instance, when you enter it."
  }
  optionsData[#optionsData + 1] = {
    type = "divider",
  }
  optionsData[#optionsData + 1] = {
    type = "checkbox",
    name = "Dungeons",
    tooltip = "Turning this off, will not change your title when entering Dungeons",
    getFunc = function() return DynamicTitleFlex.Settings.dungeon end,
    setFunc = function(value) DynamicTitleFlex.Settings.dungeon = value end,
  }
  optionsData[#optionsData + 1] = {
    type = "checkbox",
    name = "Arenas",
    tooltip = "Turning this off, will not change your title when entering Arenas",
    getFunc = function() return DynamicTitleFlex.Settings.arena end,
    setFunc = function(value) DynamicTitleFlex.Settings.arena = value end,
  }
  optionsData[#optionsData + 1] = {
    type = "checkbox",
    name = "Trials",
    tooltip = "Turning this off, will not change your title when entering Trials",
    getFunc = function() return DynamicTitleFlex.Settings.trial end,
    setFunc = function(value) DynamicTitleFlex.Settings.trial = value end,
  }
  optionsData[#optionsData + 1] = {
    type = "checkbox",
    name = "Chat Output",
    tooltip = "Outputs title changes to chat",
    getFunc = function() return DynamicTitleFlex.Settings.chatOutput end,
    setFunc = function(value) DynamicTitleFlex.Settings.chatOutput = value end,
  }
  optionsData[#optionsData + 1] = {
    type = "checkbox",
    name = "Debug",
    tooltip = "I wouldn't touch that",
    getFunc = function() return debug end,
    setFunc = function(value) debug = value end,
  }

  LAM2:RegisterOptionControls("DynamicTitleFlexOptions", optionsData)
  -----------------------------------------------
  -- Settings end --
  -----------------------------------------------
end

----------------------------------------------
-- OnAddOnLoaded end --
----------------------------------------------



function DynamicTitleFlex.GetCurrentZoneId()
  --returns Id of the zone the player is in right now
  return GetZoneId(GetUnitZoneIndex("player"))
end

function DynamicTitleFlex.CheckForAchievement(id)
  --returns true, if player has unlocked the achievement
  _, _, _, _, c, _, _ = GetAchievementInfo(id)
  return c
end

function DynamicTitleFlex.GetTitleNameFromAchievementId(id)
  --returns true, if achievement gives a title
  _, n = GetAchievementRewardTitle(id)
  return n
end

function DynamicTitleFlex.OnPlayerActivated()

  --Triggered when UI reappears (after porting but also after UI reload)
  if DynamicTitleFlex.Settings.defaultTitle == nil then
    --For when the addon is being used the first time
    --Default title gets initialized as nil
    DynamicTitleFlex.Settings.defaultTitle = GetUnitTitle("player")
    if DynamicTitleFlex.Settings.chatOutput then
      local t = DynamicTitleFlex.Settings.defaultTitle
      if t == "" then t = "No Title" end
      CHAT_SYSTEM:AddMessage(getTimeStamp() .. cStart("FFFFFF") ..
        "Saved [" .. t .. "] as default title" .. cEnd())
    end
  end

  local zID = DynamicTitleFlex.GetCurrentZoneId()
  if (DynamicTitleFlex.db[zID] ~= nil) then
    --Gets triggered, if the zone has data in DynamicTitleFlex.db
    --If Dungeons, Arenas or Trials are deactivated in the setting, breakout.
    if not DynamicTitleFlex.Settings.dungeon and DynamicTitleFlex.db[zID]["tier"] == 1 then return end
    if not DynamicTitleFlex.Settings.arena and DynamicTitleFlex.db[zID]["tier"] == 2 then return end
    if not DynamicTitleFlex.Settings.trial and DynamicTitleFlex.db[zID]["tier"] == 3 then return end


    --Where the fun begins
    for i = 1, #DynamicTitleFlex.db[zID] - 1 do
      -- "-1" because last element is the tier
      local aID = DynamicTitleFlex.db[zID][i]
      --aID - Achievement ID
      if (DynamicTitleFlex.CheckForAchievement(aID)) then
        --If player has the achievement unlocked
        local aName = DynamicTitleFlex.GetTitleNameFromAchievementId(aID)
        --aName - Achievement Name
        for j = 1, GetNumTitles() do
          --searches for the title of unlocked achievement
          if GetTitle(j) == aName then
            if aName ~= GetUnitTitle("player") then
              --Checkes, that old title wasn't the same
              DynamicTitleFlex.changedByAddon = true
              --Important to not mess up the default title
              if DynamicTitleFlex.Settings.chatOutput then
                CHAT_SYSTEM:AddMessage(getTimeStamp() .. cStart("FFFFFF") ..
                  "Title set to " ..
                  cStart("00AA00") ..
                  GetTitle(j) .. cStart("FFFFFF") .. " from " .. GetAchievementLink(aID, 1) .. cEnd())

              end
            end
            --Sets the title and breaks out
            SelectTitle(j)
            return
          end
        end
      end
    end
  else
    for i = 0, GetNumTitles() do
      --Gets triggered if zone has no data in the db (Not an instance)
      if GetTitle(i) == DynamicTitleFlex.Settings.defaultTitle then
        --Searches for the default Title
        if DynamicTitleFlex.Settings.defaultTitle ~= GetUnitTitle("player") then
          --Checks, that old title wasn't the same
          DynamicTitleFlex.changedByAddon = true
          if DynamicTitleFlex.Settings.chatOutput then
            local t = DynamicTitleFlex.Settings.defaultTitle
            if t == "" then t = "No Title" end
            CHAT_SYSTEM:AddMessage(getTimeStamp() .. cStart("FFFFFF") ..
              "Title set back to [" .. t .. "]" .. cEnd())

          end
        end
        --Sets the title and breaks out
        SelectTitle(i)
        return
      end
    end
  end
end

function DynamicTitleFlex.OnTitleUpdated(eventCode, uTag)
  --Gets triggered, if players title is changed. Doesn't matter if manually or by an addon
  if DynamicTitleFlex.changedByAddon then DynamicTitleFlex.changedByAddon = false return end
  --If this addon changes the title, changedByAddon is set to true, then gets set to false here
  if DynamicTitleFlex.Settings.defaultTitle == nil then return end
  --I have put the inital set up of the default title in the onPlayerActivated
  --OnTitleUpdated gets called earlier, so we ignore this case here

  --If we get here, the title has been most likely changed by the player -> defaultTitle is updated
  DynamicTitleFlex.Settings.defaultTitle = GetUnitTitle("player")
  if DynamicTitleFlex.Settings.chatOutput then
    local t = DynamicTitleFlex.Settings.defaultTitle
    if t == "" then t = "No Title" end
    CHAT_SYSTEM:AddMessage(getTimeStamp() .. cStart("FFFFFF") ..
      "Default title changed to [" .. t .. "]" .. cEnd())
  end

end

----------------------------------------------
-- Events Setup --
----------------------------------------------
EVENT_MANAGER:RegisterForEvent(DynamicTitleFlex.name, EVENT_ADD_ON_LOADED, DynamicTitleFlex.OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(DynamicTitleFlex.name, EVENT_PLAYER_ACTIVATED,
  DynamicTitleFlex.OnPlayerActivated)
EVENT_MANAGER:RegisterForEvent(DynamicTitleFlex.name, EVENT_TITLE_UPDATE,
  DynamicTitleFlex.OnTitleUpdated)

----------------------------------------------
-- Events Setup End --
----------------------------------------------

----------------------------------------------
-- Slash Commands --
----------------------------------------------

SLASH_COMMANDS["/dyntitleflex"] = function()
  local t = DynamicTitleFlex.Settings.defaultTitle
  if t == "" then t = "No Title" end
  CHAT_SYSTEM:AddMessage(getTimeStamp() .. cStart("FFFFFF") ..
    "Default title of DynamicTitleFlex is set to [" .. t .. "]" .. cEnd())
end


SLASH_COMMANDS["/dyntitelflexgetzone"] = function()
  --for debuging only. Print the current Zone ID and Name
  if debug then
    CHAT_SYSTEM:AddMessage(getTimeStamp() .. "-------------------")
    CHAT_SYSTEM:AddMessage(getTimeStamp() .. GetZoneId(GetUnitZoneIndex("player")))
    CHAT_SYSTEM:AddMessage(getTimeStamp() .. GetZoneNameById(GetZoneId(GetUnitZoneIndex("player"))))
    CHAT_SYSTEM:AddMessage(getTimeStamp() .. "-------------------")
  end
end


SLASH_COMMANDS["/saveachiev"] = function()

  --For debugging only! Creates a saved var with ALL achievements, that have a title reward and their ID
  if debug then
    DynamicTitleFlex.tempDB.iDB = {}
    --clears the table used for this


    for i = 1, 40 do
      --40 is arbitrary. 36 was the limit at the moment of writing this (High Isle)
      --Following script can be used to check how many categories there are right now:
      -- /script for i=1,40 do name = GetAchievementCategoryInfo(i) d(i .. " " .. name) end


      local n, numSC = GetAchievementCategoryInfo(i)
      -- n - Category Name
      -- numSC -number of Sub Categories in that Main Category

      ----------------------------------
      --d(i .. " " .. n .. " " .. numSC)
      ----------------------------------

      --Going throught the subcategories
      for j = 0, numSC do
        local sn, snumA
        --sn - Sub Category Name
        --snumA - Number of Achievements in that Sub Category
        if j == 0 then
          --GetAchievementSubCategoryInfo(i, 1) starts with the 2nd SubCategory
          --GetAchievementCategoryInfo(i) includes info on the 1st SubCategory if it's "General"
          --If the first SubCategory is not "General", GetAchievementSubCategoryInfo(i, 1) will return the 1st SubCategory
          --"General" still exists, just doesn't have any achievements in there
          --Don't ask me why it's like that... :shruggs:

          --So what happens here:
          --If j == 0, then we will need j as nil for later (Explanation at that point)
          j = nil
          sn = "General"
          --sn - SubCategory Name
          --Since j == 0, we want the "General" Sub Category, which we get by GetAchievementCategoryInfo(i)
          _, _, snumA = GetAchievementCategoryInfo(i)
          --snumA - Subcategory Achievement Amount
        else
          --If j ~= 0, we want the subCategory 2 or higher.
          --GetAchievementSubCategoryInfo(i, 1) will give us the 2nd subcategory.
          --GetAchievementSubCategoryInfo(i, 2) will give us the 3rd subcategory.
          --and so on
          sn, snumA = GetAchievementSubCategoryInfo(i, j)
        end

        ----------------------------------
        --d(sn .. " " .. snumA)
        ----------------------------------

        for k = 0, snumA do
          --Going through all the Achievements in the category
          if GetAchievementRewardTitle(GetAchievementId(i, j, k)) then
            --If the achievement rewards a title
            --This is where the j = nil comes into play
            --2nd argument in GetAchievementId(i,j,k) starts with nil.
            --So if we want an achievement from the "General" Category, we need do to GetAchievementId(i,nil,k)


            local _, tit = GetAchievementRewardTitle(GetAchievementId(i, j, k))
            -- tit - titleName
            local elem = { ["name"] = GetAchievementName(GetAchievementId(i, j, k)),
              ["id"] = GetAchievementId(i, j, k),
              ["title"] = tit }

            if DynamicTitleFlex.tempDB.iDB[n] == nil then
              --if there is no data for the category yet
              DynamicTitleFlex.tempDB.iDB[n] = { [sn] = {} }
            end
            --adds the achievements
            table.insert(DynamicTitleFlex.tempDB.iDB[n][sn], elem)

          end
        end
        --if we set j to nil, we need to set it back to 0, so it can be incrememented
        if j == nil then j = 0 end
      end

      ------------------------------------------
      --d("-------------------")
      ------------------------------------------
    end

    d(getTimeStamp() .. "TempDB updated")
  end

end

-- /script for i=1,40 do name = GetAchievementCategoryInfo(i) d(i .. " " .. name) end
-- /script d(GetAchievementName(GetAchievementId(topLevelIndex, nilable categoryIndex, achievementIndex)))
