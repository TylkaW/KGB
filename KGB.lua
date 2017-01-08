local dewdrop = AceLibrary("Dewdrop-2.0")
KGB = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceConsole-2.0")

local options = {
	type = 'group',
	args = { 
			show = {
            type = 'toggle',
            name = 'Show Minimap Button',
            desc = 'Show/Hide Minimap Button',
            get = function() return KGBMinimap.show end,
			set = function() KGBMinimap.show = not KGBMinimap.show; if KGBMinimap.show then KGBMinimapButton:Show() else KGBMinimapButton:Hide() end end,
			},
			lock = {
			type = 'toggle',
			name = 'Lock',
			desc = 'Lock/Unlock minimap button',
			get = function() return KGBMinimap.lock end,
			set = function() KGBMinimap.lock = not KGBMinimap.lock end
			}
	}
}

KGB:RegisterChatCommand({"/kgb"}, options)
KGB.version = nil
KGB.SyncMessage = nil
KGB.Individual = nil

local infoRcved = ""

function KGB:OnInitialize()
	self.version = GetAddOnMetadata("KGB", "Version")
	if not KGBMinimap then
		KGBMinimap = {['lock'] = false, ['show'] = true, ['x']=0, ['y'] = 0}
	end
	self.SyncMessage = true
	self.Individual = false
	self.KGB_value_table = {}
	self.KGB_color_table = {}
	KGBMinimapButton_OnInitialize()
end

function KGB:OnEnable() -- {{{
    -- Called when the addon is enabled
	RaidOrganizerMinimapButton:GetNormalTexture():SetDesaturated(false)
	RaidOrganizerMinimapButton:GetPushedTexture():SetDesaturated(false)
	self:RegisterEvent("CHAT_MSG_ADDON")
end -- }}}

function KGB:OnDisable() -- {{{
    -- Called when the addon is disabled
	RaidOrganizerMinimapButton:GetNormalTexture():SetDesaturated(true)
	RaidOrganizerMinimapButton:GetPushedTexture():SetDesaturated(true)
	self:UnregisterAllEvents();
end -- }}}

function KGB:CreateKGBMenu(level, value)
	if level == 1 then
		dewdrop:AddLine( 'text', "Just Target",
							 'checked', self.Individual,
							 'func', function() self.Individual = not self.Individual end,
							 'tooltipTitle', 'Individual or raidwide query',
							 'tooltipText', 'Ask just target or whole raid'
		)
		dewdrop:AddLine( 'text', "Tooltip",
							 'checked', self.SyncMessage,
							 'func', function() self.SyncMessage = not self.SyncMessage end,
							 'tooltipTitle', 'Answer Mode',
							 'tooltipText', 'By sync if checked, raid message otherwise'
		)
		dewdrop:AddLine( 'text', "Check functions",
						 'hasArrow', true,
						 'value', 'commands')
	elseif level == 2 then
		if value == 'commands' then
			dewdrop:AddLine( 'text', "Quintessence",
					 'func', function()
						self:DoQuintessenceCheck()
					 end,
					 'tooltipTitle', "Check Quintessence",
					 'tooltipText', "Check for Quintessence in the raid"
			)
			dewdrop:AddLine( 'text', "Onyxia bag",
					 'func', function()
						self:DoOnyxiaBagCheck()
					 end,
					 'tooltipTitle', "Check Onyxia bag",
					 'tooltipText', "Count how many Onyxia bag raid member have"
			)
			dewdrop:AddLine( 'text', "Onyxia Cloak",
					 'func', function()
						self:DoOnyxiaCloakCheck()
					 end,
					 'tooltipTitle', "Check Onyxia cloak",
					 'tooltipText', "Signal if any raid member doesnt wear his Onyxia cloak"
			)
			dewdrop:AddLine( 'text', "Follow",
					 'func', function()
						self:FollowMe()
					 end,
					 'tooltipTitle', "Make people follow you",
					 'tooltipText', "Make people follow you"
			)
		end
	end
end

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
	SendAddonMessage("BigWigs", "BWVS " .. QuintessenceString , "RAID", nil)
	if self.Individual and UnitExists('target') then
		QuintessenceString = "if UnitName('player') == '" .. UnitName('target') .. "' then " .. QuintessenceString .. " end"
	end
end

function KGB:QuintessenceRcvSync(msg, sender)
	if msg == "1" then
		self.KGB_value_table[sender] = "Yes"
		self.KGB_color_table[sender] = {0,1,0}
	else
		self.KGB_value_table[sender] = "No"
		self.KGB_color_table[sender] = {1,0,0}
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
		OnyxiaBagString = "if UnitName('player') == '" .. UnitName('target') .. "' then " .. OnyxiaBagString .. " end"
	end
	SendAddonMessage("BigWigs", "BWVS " .. OnyxiaBagString, "RAID", nil)
end

function KGB:OnyxiaBagRcvSync(msg, sender)
	self.KGB_value_table[sender] = msg
	self.KGB_color_table[sender] = {1,1,1}
end

function KGB:DoOnyxiaCloakCheck()
	self.KGB_value_table = {}
	self.KGB_color_table = {}
	infoRcved = "Onyxia Cloak"
	local OnyxiaCloakString = "local answer=0;local _,_, itemCode = strfind(GetInventoryItemLink('player', 15),'(%d+):'); if (itemCode=='15138') then answer=1;end"
	if self.SyncMessage == false then
		OnyxiaCloakString = OnyxiaCloakString .. " if answer == 0 then SendChatMessage('not wearing Onyxia Cloak', 'RAID') end"
	else
		OnyxiaCloakString = OnyxiaCloakString .. " SendAddonMessage('KGB', 'ONYCLOAK '..answer, 'RAID')"
	end
	if self.Individual then
		OnyxiaCloakString = "if UnitName('player') == '" .. UnitName('target') .. "' then " .. OnyxiaCloakString .. " end"
	end
	SendAddonMessage("BigWigs", "BWVS " .. OnyxiaCloakString, "RAID", nil)
end

function KGB:OnyxiaCloakRcvSync(msg, sender)
	if msg == "1" then
		self.KGB_value_table[sender] = "Yes"
		self.KGB_color_table[sender] = {0,1,0}
	else
		self.KGB_value_table[sender] = "No"
		self.KGB_color_table[sender] = {1,0,0}
	end
end

function KGB:FollowMe()
	--self.KGB_value_table = {}
	--self.KGB_color_table = {}
	--infoRcved = "Onyxia Cloak"
	local FollowMeString = "TargetByName('" .. UnitName('player') .. "', true); FollowUnit('target'); TargetLastTarget()"
	-- if self.SyncMessage == false then
		-- OnyxiaCloakString = OnyxiaCloakString .. " if answer == 0 then SendChatMessage('not wearing Onyxia Cloak', 'RAID') end"
	-- else
		-- OnyxiaCloakString = OnyxiaCloakString .. " SendAddonMessage('KGB', 'ONYCLOAK '..answer, 'RAID')"
	-- end
	if self.Individual then
		FollowMeString = "if UnitName('player') == '" .. UnitName('target') .. "' then " .. FollowMeString .. " end"
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
end

function KGB_Minimap_OnEnter()
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT");
	GameTooltip:AddLine("KGB " .. KGB.version);
	--GameTooltip:AddLine("Left click to show/hide bar", 0,1,0);
	GameTooltip:AddLine("Right click to show options", 0,1,0);
	GameTooltip:AddLine("Left click and drag to move", 0,1,0);
	local str1, str2 = "", "";
	local color1, color2 = {1,1,1}, {1,1,1};
	local tmpstr = "";
	local tmpcolor = {1,1,1}
	if not (infoRcved == "") then
		GameTooltip:AddLine(" ", 0,0,0);
		GameTooltip:AddLine(infoRcved .. " :");
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
						tmpcolor = {1,0,0}
					else
						tmpstr = UnitName("raid"..i) .. " : offline";
						tmpcolor = {0.5,0.5,0.5}
					end
				end
				if str1 == "" then str1 = tmpstr; color1 = tmpcolor; else str2 = tmpstr; color2 = tmpcolor end
				if str2 ~= "" then GameTooltip:AddDoubleLine(str1, str2, color1[1], color1[2], color1[3], color2[1], color2[2], color2[3]); str1 = ""; str2 = ""; end
			end
		end
		if str1 ~= "" then GameTooltip:AddDoubleLine(str1, "", color1[1], color1[2], color1[3], color2[1], color2[2], color2[3]); str1 = ""; str2 = ""; end
	end
	GameTooltip:Show();
end

function KGB_Minimap_Position(x,y)
	if ( x or y ) then
		if ( x ) then if ( x < 0 ) then x = x + 360; end KGBMinimap.x = x; end
		if ( y ) then KGBMinimap.y = y; end
	end
	x, y = KGBMinimap.x, KGBMinimap.y

	KGBMinimapButton:SetPoint("TOPLEFT","Minimap","TOPLEFT",53-((80+(y))*cos(x)),((80+(y))*sin(x))-55);
end

function KGB_Minimap_DragStart()
	if KGBMinimap.lock then 
		return 
	end
	this:SetScript("OnUpdate", KGB_Minimap_DragUpdate);
end
function KGB_Minimap_DragStop()
	KGBMinimapButton:UnlockHighlight()
	this:SetScript("OnUpdate", nil);
end
function KGB_Minimap_DragUpdate()
	KGBMinimapButton:LockHighlight();
	local curX, curY = GetCursorPosition();
	local mapX, mapY = Minimap:GetCenter();
	local x, y;
	if ( IsShiftKeyDown() ) then
		y = math.pow( math.pow(curY - mapY * Minimap:GetEffectiveScale(), 2) + math.pow(mapX * Minimap:GetEffectiveScale() - curX, 2), 0.5) - 70;
		y = min( max( y, -30 ), 30 );
	end
	x = math.deg(math.atan2( curY - mapY * Minimap:GetEffectiveScale(), mapX * Minimap:GetEffectiveScale() - curX ));

	KGB_Minimap_Position(x,y);
end

function KGB_Minimap_Update()
	if ( KGBMinimap.show ) then
		KGBMinimapButton:Hide();
	else
		KGBMinimapButton:Show();
		KGB_Minimap_Position();
	end
end

function KGB_Minimap_OnClick(arg1)
	-- if arg1 == "LeftButton" then
		-- if not KGB:IsActive() then
			-- KGB:ToggleActive()
			-- if not KGBshowBar then
				-- KGBshowBar = not KGBshowBar
				-- KGB:ShowButtons()
			-- end
		-- else
			-- KGBshowBar = not KGBshowBar
			-- KGB:ShowButtons()
		-- end
	-- else
	dewdrop:Open(KGBMinimapButton)
	--end
end

function KGBMinimapButton_OnInitialize()
	--dewdrop:Register(KGBMinimapButton, 'children', function() dewdrop:FeedAceOptionsTable(options) end)
	dewdrop:Register(KGBMinimapButton, 'dontHook', true, 'children', function(level, value) KGB:CreateKGBMenu(level, value) end)
	
	KGBMinimapButton:SetNormalTexture("Interface\\Icons\\Spell_shadow_shadowworddominate")
	KGBMinimapButton:SetPushedTexture("Interface\\Icons\\Spell_shadow_shadowworddominate")

	KGB_Minimap_Position(nil, nil)
	
	if KGBMinimap.show then
		KGBMinimapButton:Show()
	end
end