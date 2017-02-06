
assert(KGB, "KGB not found!")

local AceLocale = AceLibrary("AceLocale-2.1")
------------------------------
--      Are you local?      --
------------------------------
AceLocale:RegisterTranslation("KGBOptions", "enUS", function()
    return {
		["AA"] = "GG"
	}
end)
AceLocale:RegisterTranslation("KGBOptions", "enGB", function()
    return {
		["AA"] = "GG"
	}
end)
AceLocale:RegisterTranslation("KGBOptions", "frFR", function()
    return {
		["AA"] = "GG"
	}
end)
AceLocale:RegisterTranslation("KGBOptions", "deDE", function()
    return {
		["AA"] = "GG"
	}
end)

local L = AceLibrary("AceLocale-2.1"):GetInstance("KGBOptions", true)
local tablet = AceLibrary("Tablet-2.0")

KGBOptions = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceConsole-2.0", "AceDB-2.0", "FuBarPlugin-2.0")

local deuce = KGB:NewModule("KGB Options Menu")
deuce.hasFuBar = IsAddOnLoaded("FuBar") and FuBar
deuce.consoleCmd = not deuce.hasFuBar and "Minimap"
deuce.consoleOptions = not deuce.hasFuBar and {
	type = "toggle",
	name = "Minimap",
	desc = "Toggle Minimap",
	get = function() return KGBOptions.minimapFrame and KGBOptions.minimapFrame:IsVisible() or false end,
	set = function(v)
		if v then
			KGBOptions:Show()
		else
			KGBOptions:Hide()
		end
	end,
	map = {[false] = "hidden", [true] = "shown"},
	message = "%s icon is now %s.",
	hidden = function() return deuce.hasFuBar end,
}

KGBOptions.name = "FuBar - KGB"
KGBOptions:RegisterDB("KGBOptionsFubarDB")

KGBOptions.hasNoColor = true
KGBOptions.hasIcon = "Interface\\Icons\\spell_shadow_shadowworddominate"
KGBOptions.lockMinimap = true
KGBOptions.defaultMinimapPosition = 180
KGBOptions.clickableTooltip = true
KGBOptions.hideWithoutStandby = true

KGBOptions.OnMenuRequest = KGB.options
local args = AceLibrary("FuBarPlugin-2.0"):GetAceOptionsDataTable(KGBOptions)
for k,v in pairs(args) do
	if KGBOptions.OnMenuRequest.args[k] == nil then
		KGBOptions.OnMenuRequest.args[k] = v
	end
end
-----------------------------
--      Icon Handling      --
-----------------------------

function KGBOptions:OnEnable()
	self:RegisterEvent("KGB_Enabled", "OnStateChange")
	self:RegisterEvent("KGB_Disabled", "OnStateChange")
	self:RegisterEvent("KGB_OnTooltipUpdate", "UpdateTooltip")
	self:OnStateChange()		
end

function KGBOptions:OnStateChange()
	self:SetIcon("Interface\\Icons\\spell_shadow_shadowworddominate")
	self:UpdateTooltip()
end

-----------------------------
--      FuBar Methods      --
-----------------------------

function KGBOptions:OnTooltipUpdate()
	KGB:TooltipUpdate(tablet)
end


function KGBOptions:OnClick()
end