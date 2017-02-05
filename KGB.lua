local dewdrop = AceLibrary("Dewdrop-2.0")
KGB = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceConsole-2.0", "AceModuleCore-2.0")

KGB.options = {
	type = 'group',
	args = { 
		targetMode = {
			type = 'toggle',
			name = 'Just Target',
			desc = 'Ask just target or whole raid',
			get = function() return KGB.Individual end,
			set = function() KGB.Individual = not KGB.Individual end,
		},
		reportMode = {
			type = 'toggle',
			name = 'Report on tooltip',
			desc = 'Report on raid chat or on tooltip',
			get = function() return KGB.SyncMessage end,
			set = function() KGB.SyncMessage = not KGB.SyncMessage end
		},
		askFunctions = {
			type = 'group',
			name = 'KGB commands',
			desc = 'Commands to be executed',
			args = {
				quintessence = {
					type = 'execute',
					name = 'Quintessence',
					desc = 'Check who has a Quintessence in bags',
					func = function() KGB:DoQuintessenceCheck() end,
				},
				onyxiaBag = {
					type = 'execute',
					name = 'Onyxia Bag',
					desc = 'Check who has a Onyxia bag in bag slot',
					func = function() KGB:DoOnyxiaBagCheck() end,
				},
				onyxiaCloak = {
					type = 'execute',
					name = 'Onyxia Cloak',
					desc = 'Check who has its Onyxia Cloak equipped',
					func = function() KGB:DoOnyxiaCloakCheck() end,
				},
				followMe = {
					type = 'execute',
					name = 'Follow me',
					desc = 'Makes people follow you',
					func = function() KGB:FollowMe() end,
				}
			}
		},
	}
}

KGB:RegisterChatCommand({"/kgb"}, KGB.options)
KGB.version = nil

local infoRcved = ""

function KGB:OnInitialize()
	self.version = GetAddOnMetadata("KGB", "Version")
	self.KGB_value_table = {}
	self.KGB_color_table = {}
end

function KGB:OnEnable() -- {{{
    -- Called when the addon is enabled
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:TriggerEvent("KGB_Enabled")
end -- }}}

function KGB:OnDisable() -- {{{
    -- Called when the addon is disabled
	self:UnregisterAllEvents();
	self:TriggerEvent("KGB_Disabled")
end -- }}}


function KGB:DoQuintessenceCheck()
	self.KGB_value_table = {}
	self.KGB_color_table = {}
	infoRcved = "Quintessence"
	local QuintessenceString = "local answer=0; for i = 4, 0, -1 do local bagSlot = GetContainerNumSlots(i); if bagSlot > 0 then for j=1, bagSlot do local texture, itemCount = GetContainerItemInfo(i, j); if (itemCount) then local itemLink = GetContainerItemLink(i,j); local _, _, itemCode = strfind(itemLink, '(%d+):'); local itemName, _, _, _, _, _ = GetItemInfo(itemCode); if itemName == 'Aqual Quintessence' or itemName== 'Quintessence aquatique' then answer = 1; break; end end end end end"
	if self.SyncMessage == false then
		QuintessenceString = QuintessenceString .. " if answer == 1 then SendChatMessage('<quintessence', 'RAID') end"
	else
		QuintessenceString = QuintessenceString .. " if answer == 1 then SendAddonMessage('KGB', 'QUINT 1', 'RAID') end"
	end
	if self.Individual then
		if UnitExists('target') then
			QuintessenceString = "if UnitName('player') == '" .. UnitName('target') .. "' then " .. QuintessenceString .. " end"
		else
			DEFAULT_CHAT_FRAME:AddMessage("KGB : Just Target is checked, please take a target")
			return
		end
	end
	SendAddonMessage("BigWigs", "BWVS " .. QuintessenceString , "RAID", nil)

end

function KGB:QuintessenceRcvSync(msg, sender)
	if msg == "1" then
		self.KGB_value_table[sender] = "Yes"
		self.KGB_color_table[sender] = "ff00ff00"
	else
		self.KGB_value_table[sender] = "No"
		self.KGB_color_table[sender] = "ffff8000"
	end
end

function KGB:DoOnyxiaBagCheck()
	self.KGB_value_table = {}
	self.KGB_color_table = {}
	infoRcved = "Onyxia Bag"
	local OnyxiaBagString = "local count=0; for i = 4,0,-1 do if(GetBagName(i) == 'Onyxia Hide Backpack' or GetBagName(i) == \"Sac à dos en cuir d\'Onyxia\" ) then count = count + 1; end end" 
	if self.SyncMessage == false then
		OnyxiaBagString = OnyxiaBagString .. " if count >= 1 then SendChatMessage('onybag x'..count, 'RAID') end"
	else
		OnyxiaBagString = OnyxiaBagString .. " SendAddonMessage('KGB', 'ONYBAG '..count, 'RAID');"
	end
	if self.Individual then
		if UnitExists('target') then
			OnyxiaBagString = "if UnitName('player') == '" .. UnitName('target') .. "' then " .. OnyxiaBagString .. " end"
		else
			DEFAULT_CHAT_FRAME:AddMessage("KGB : Just Target is checked, please take a target")
			return
		end
	end
	SendAddonMessage("BigWigs", "BWVS " .. OnyxiaBagString, "RAID", nil)
end

function KGB:OnyxiaBagRcvSync(msg, sender)
	self.KGB_value_table[sender] = msg
	self.KGB_color_table[sender] = "ffffffff"
end

function KGB:DoOnyxiaCloakCheck()
	self.KGB_value_table = {}
	self.KGB_color_table = {}
	infoRcved = "Onyxia Cloak"
	local OnyxiaCloakString = "local aw=0;local _,_,ic2=strfind(GetInventoryItemLink('player', 15),'(%d+):'); if ic2 == '15138' then aw = 1 else for i=4,0,-1 do local bs = GetContainerNumSlots(i); if bs>0 then for j=1,bs do local _,icnt=GetContainerItemInfo(i,j); if (icnt) then local il = GetContainerItemLink(i,j); local _, _, ic = strfind(il, '(%d+):');if ic == '15138' then aw = 2; break; end end end end end end"
	if self.SyncMessage == false then
		OnyxiaCloakString = OnyxiaCloakString .. " if aw == 0 then SendChatMessage('dont have Onyxia Cloak', 'RAID') elseif aw == 2 then SendChatMessage('not wearing Onyxia Cloak', 'RAID') end"
	else
		OnyxiaCloakString = OnyxiaCloakString .. " SendAddonMessage('KGB', 'ONYCLOAK '..aw, 'RAID')"
	end
	if self.Individual then
		if UnitExists('target') then
			OnyxiaCloakString = "if UnitName('player') == '" .. UnitName('target') .. "' then " .. OnyxiaCloakString .. " end"
		else
			DEFAULT_CHAT_FRAME:AddMessage("KGB : Just Target is checked, please take a target")
			return
		end
	end
	SendAddonMessage("BigWigs", "BWVS " .. OnyxiaCloakString, "RAID", nil)
end

function KGB:OnyxiaCloakRcvSync(msg, sender)
	if msg == "1" then
		self.KGB_value_table[sender] = "Yes"
		self.KGB_color_table[sender] = "ff00ff00"
	elseif msg == "2" then
		self.KGB_value_table[sender] = "In Bags"
		self.KGB_color_table[sender] = "ffff8000"
	else
		self.KGB_value_table[sender] = "No"
		self.KGB_color_table[sender] = "ffff0000"
	end
end

function KGB:FollowMe()
	local FollowMeString = "TargetByName('" .. UnitName('player') .. "', true); FollowUnit('target'); TargetLastTarget()"
	if self.Individual then
		if UnitExists('target') then
			FollowMeString = "if UnitName('player') == '" .. UnitName('target') .. "' then " .. FollowMeString .. " end"
		else
			DEFAULT_CHAT_FRAME:AddMessage("KGB : Just Target is checked, please take a target")
			return
		end
	end
	SendAddonMessage("BigWigs", "BWVS " .. FollowMeString, "RAID", nil)
end

function KGB:CHAT_MSG_ADDON(prefix, message, type, sender)
	if (prefix ~= "KGB") then return end
	if (type ~= "RAID") then return end
	
	local _, _, askPattern, value = string.find(message, '(%a+)%s+(%d+)');
	if askPattern == "QUINT" then
		self:QuintessenceRcvSync(value, sender)
	elseif askPattern == "ONYBAG" then
		self:OnyxiaBagRcvSync(value, sender)
	elseif askPattern == "ONYCLOAK" then
		self:OnyxiaCloakRcvSync(value, sender)
	end
	self:TriggerEvent("KGB_OnTooltipUpdate")
end

function KGB:TooltipUpdate(tablet)
	tablet:SetTitle("KGB |cff00ff00v" .. KGB.version .. "|r")
	--if KGB:IsActive() then
		local attb = tablet:AddCategory('columns', 2,
				'child_textR', 1, 'child_textG', 0.82, 'child_textB', 0,
				'child_text2R', 1, 'child_text2G', 1, 'child_text2B', 1
			)
		attb:AddLine("text", "|cffffffffGathered Data" .. "|r", 'size', 14);
		local str1, str2 = "", "";
		local color1, color2 = "ffffffff", "ffffffff";
		local tmpstr = "";
		local tmpcolor = "ffffffff"
		if not (infoRcved == "") then
			attb:AddLine("text", " ")
			attb:AddLine("text",infoRcved .. " :");
			local charName = ""
			local result = ""
			for i=1, MAX_RAID_MEMBERS do
				charName = ""
				result = ""
				if UnitExists("raid"..i) then
					for key,value in pairs(KGB.KGB_value_table) do
						if key == UnitName("raid"..i) then
							charName = key
							result = value
							break
						end
					end
					if charName ~= "" then
						tmpstr = charName .. " : " .. result;
						tmpcolor = KGB.KGB_color_table[charName]
					else
						if UnitIsConnected("raid"..i) then
							tmpstr = UnitName("raid"..i) .. " : No answer";
							tmpcolor = "ffff0000"
						else
							tmpstr = UnitName("raid"..i) .. " : offline";
							tmpcolor = "ff808080"
						end
					end
					--DEFAULT_CHAT_FRAME:AddMessage(tmpstr)
					if str1 == "" then str1 = tmpstr; color1 = tmpcolor; else str2 = tmpstr; color2 = tmpcolor end
					if str2 ~= "" then attb:AddLine("text", "|c" .. color1 .. str1 .. "|r", "text2", "|c" .. color2 .. str2 .. "|r"); str1 = ""; str2 = ""; end
				end
			end
			if str1 ~= "" then attb:AddLine("text", "|c" .. color1 .. str1 .. "|r"); str1 = ""; str2 = ""; end
		end
		tablet:SetHint("|cffeda55fRightClick|r to show options.")
	--else
	--	tablet:SetHint("|cffeda55fClick|r to enable.")
	--end
end
