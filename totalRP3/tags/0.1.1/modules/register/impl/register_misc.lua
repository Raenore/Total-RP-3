--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Total RP 3
-- Register : Peek section
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

-- imports
local Utils, Events, Globals = TRP3_API.utils, TRP3_API.events, TRP3_API.globals;
local stEtN = Utils.str.emptyToNil;
local color, getIcon, tableRemove = Utils.str.color, Utils.str.icon, Utils.table.remove;
local loc = TRP3_API.locale.getText;
local get = TRP3_API.profile.getData;
local tcopy = Utils.table.copy;
local assert, table, wipe, _G = assert, table, wipe, _G;
local getDefaultProfile = TRP3_API.profile.getDefaultProfile;
local showIconBrowser = TRP3_API.popup.showIconBrowser;
local tinsert = tinsert;
local pairs = pairs;
local type = type;
local tostring = tostring;
local setupListBox = TRP3_API.ui.listbox.setupListBox;
local setTooltipForSameFrame, toast = TRP3_API.ui.tooltip.setTooltipForSameFrame, TRP3_API.ui.tooltip.toast;
local getCurrentContext, getCurrentPageID = TRP3_API.navigation.page.getCurrentContext, TRP3_API.navigation.page.getCurrentPageID;
local setupIconButton = TRP3_API.ui.frame.setupIconButton;
local setupFieldSet = TRP3_API.ui.frame.setupFieldPanel;
local showPopup = TRP3_API.popup.showPopup;
local hasProfile = TRP3_API.register.hasProfile;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- SCHEMA
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

getDefaultProfile().player.misc = {
	v = 1,
	PE = {},
	ST = {},
}

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- RP Style
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local STYLE_FIELDS;
local function buildStyleStructure()
	STYLE_FIELDS = {
		{
			id = "1",
			name = loc("REG_PLAYER_STYLE_FREQ"),
			values = {
				{loc("REG_PLAYER_STYLE_FREQ_1"), 1},
				{loc("REG_PLAYER_STYLE_FREQ_2"), 2},
				{loc("REG_PLAYER_STYLE_FREQ_3"), 3},
				{loc("REG_PLAYER_STYLE_FREQ_4"), 4},
				{loc("REG_PLAYER_STYLE_FREQ_5"), 5},
				{loc("REG_PLAYER_STYLE_HIDE"), 0},
			}
		},
		{
			id = "2",
			name = loc("REG_PLAYER_STYLE_INJURY"),
			values = {
				{YES, 1},
				{NO, 2},
				{loc("REG_PLAYER_STYLE_PERMI"), 3},
				{loc("REG_PLAYER_STYLE_HIDE"), 0},
			}
		},
		{
			id = "3",
			name = loc("REG_PLAYER_STYLE_DEATH"),
			values = {
				{YES, 1},
				{"No", 2},
				{loc("REG_PLAYER_STYLE_PERMI"), 3},
				{loc("REG_PLAYER_STYLE_HIDE"), 0},
			}
		},
		{
			id = "4",
			name = loc("REG_PLAYER_STYLE_ROMANCE"),
			values = {
				{YES, 1},
				{NO, 2},
				{loc("REG_PLAYER_STYLE_PERMI"), 3},
				{loc("REG_PLAYER_STYLE_HIDE"), 0},
			}
		},
		{
			id = "5",
			name = loc("REG_PLAYER_STYLE_BATTLE"),
			values = {
				{loc("REG_PLAYER_STYLE_BATTLE_1"), 1},
				{loc("REG_PLAYER_STYLE_BATTLE_2"), 2},
				{loc("REG_PLAYER_STYLE_BATTLE_3"), 3},
				{loc("REG_PLAYER_STYLE_BATTLE_4"), 4},
				{loc("REG_PLAYER_STYLE_HIDE"), 0},
			}
		},
		{
			id = "6",
			name = loc("REG_PLAYER_STYLE_GUILD"),
			values = {
				{loc("REG_PLAYER_STYLE_GUILD_IC"), 1},
				{loc("REG_PLAYER_STYLE_GUILD_OOC"), 2},
				{loc("REG_PLAYER_STYLE_HIDE"), 0},
			}
		},
	};
end

local styleLines = {};

local function onEditStyle(choice, frame)
	frame = frame:GetParent();
	assert(frame.fieldData, "No data in frame !");
	local context = getCurrentContext();
	assert(context, "No context for page player_main !");
	if context.isPlayer then
		local dataTab = get("player/misc");
		dataTab.ST[frame.fieldData.id] = choice;
		-- version increment
		assert(type(dataTab.v) == "number", "Error: No version in draftData or not a number.");
		dataTab.v = Utils.math.incrementNumber(dataTab.v, 2);
	end
end

local function displayRPStyle(context)
	local dataTab = context.profile.misc or Globals.empty;
	local styleData = dataTab.ST or {};
	
	-- Hide all
	for _, frame in pairs(styleLines) do
		frame:Hide();
	end
	
	local previous = nil;
	local count = 0;
	for index, fieldData in pairs(STYLE_FIELDS) do
		local frame = styleLines[index];
		if frame == nil then
			frame = CreateFrame("Frame", "TRP3_RegisterMiscViewRPStyle_line"..index, TRP3_RegisterMiscViewRPStyle, "TRP3_RegisterRPStyleMain_Edit_Line");
			setupListBox(_G[frame:GetName().."Values"], fieldData.values, onEditStyle, nil, 180, true);
			frame.fieldData = fieldData;
			tinsert(styleLines, frame);
		end
		
		local selectedValue = styleData[fieldData.id] or 0;
		
		if context.isPlayer or selectedValue ~= 0 then
			-- Position
			frame:ClearAllPoints();
			if previous == nil then
				frame:SetPoint("TOPLEFT", TRP3_RegisterMiscViewRPStyle, "TOPLEFT", 25, -20);
			else
				frame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, 0);
			end
			frame:SetPoint("LEFT", 0, 0);
			frame:SetPoint("RIGHT", 0, 0);
			
			-- Value
			_G[frame:GetName().."FieldName"]:SetText(fieldData.name);
			local dropDown = _G[frame:GetName().."Values"];
			local readOnlyValue = _G[frame:GetName().."FieldValue"];
			if context.isPlayer then
				dropDown:SetSelectedValue(selectedValue);
				dropDown:Show();
				readOnlyValue:Hide();
			else
				dropDown:Hide();
				readOnlyValue:Show();
				local valueText = nil;
				for _, data in pairs(fieldData.values) do
					if data[2] == selectedValue then
						valueText = data[1];
						break;
					end
				end
				readOnlyValue:SetText(valueText);
			end
			
			frame:Show();
			previous = frame;
			count = count + 1;
		end
	end
	
	TRP3_RegisterMiscViewRPStyleEmpty:Hide();
	if not context.isPlayer and count == 0 then
		TRP3_RegisterMiscViewRPStyleEmpty:Show();
	end
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- PEEK
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local GLANCE_NOT_USED_ICON = "INV_Misc_QuestionMark";

local function setupGlanceButton(button, active, icon, title, text, isMine)
	button:Enable();
	button:SetNormalTexture("Interface\\ICONS\\" .. (icon or GLANCE_NOT_USED_ICON));
	if active then
		button:SetAlpha(1);
		if not isMine then
			setTooltipForSameFrame(button, "RIGHT", 0, 5, title or "...", text);
		else
			setTooltipForSameFrame(button, "RIGHT", 0, 5, title or "...", (text or "...") .. "\n" .. color("y") .. loc("REG_PLAYER_GLANCE_CONFIG"));
		end
	else
		button:SetAlpha(0.1);
		if not isMine then
			button:Disable();
		else
			setTooltipForSameFrame(button, "RIGHT", 0, 5, loc("REG_PLAYER_GLANCE_UNUSED"), color("y") .. loc("REG_PLAYER_GLANCE_CONFIG"));
		end
	end
end

local function displayPeek(context)
	local dataTab = context.profile.misc or Globals.empty;
	for i=1,5 do
		local glanceData = (dataTab.PE or {})[tostring(i)] or {};
		local button = _G["TRP3_RegisterMiscViewGlanceSlot" .. i];
		setupGlanceButton(button, glanceData.AC, glanceData.IC, glanceData.TI, glanceData.TX, context.isPlayer);
	end
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Peek editor
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local currentSelected;
local draftData = {};

local function onIconSelected(icon)
	icon = icon or Globals.icons.default;
	setupIconButton(TRP3_RegisterMiscEdit_Glance_Icon, icon);
	TRP3_RegisterMiscEdit_Glance_Icon.icon = icon;
	showPopup(TRP3_RegisterGlanceEditor);
end

local function onIconClosed()
	showPopup(TRP3_RegisterGlanceEditor);
end

local function onSlotClick(button)
	local context = getCurrentContext();
	assert(context, "No context for page player_main !");
	if context.isPlayer then
		currentSelected = button.index;
		local dataTab = get("player/misc");
		draftData = (dataTab.PE or {})[currentSelected] or {};
		TRP3_RegisterMiscEdit_Glance_Active:SetChecked(draftData.AC);
		TRP3_RegisterMiscEdit_Glance_TextScrollText:SetText(draftData.TX or "");
		TRP3_RegisterMiscEdit_Glance_Title:SetText(draftData.TI or "");
		TRP3_RegisterMiscEdit_Glance_PresetSaveCategory:SetText("");
		TRP3_RegisterMiscEdit_Glance_PresetSaveName:SetText("");
		onIconSelected(draftData.IC);
		showPopup(TRP3_RegisterGlanceEditor);
	end
end

local function applyPeekSlot(slot, ic, ac, ti, tx)
	assert(slot, "No selection ...");
	local dataTab = get("player/misc");
	if not dataTab.PE then
		dataTab.PE = {};
	end
	if not dataTab.PE[slot] then
		dataTab.PE[slot] = {};
	end
	local peekTab = dataTab.PE[slot];
	peekTab.IC = ic;
	peekTab.AC = ac;
	peekTab.TI = ti;
	peekTab.TX = tx;
	-- version increment
	assert(type(dataTab.v) == "number", "Error: No version in draftData or not a number.");
	dataTab.v = Utils.math.incrementNumber(dataTab.v, 2);
	-- Refresh display & target frame
	Events.fireEvent(Events.REGISTER_MISC_SAVED);
end

local function peekEditorApply()
	applyPeekSlot(
		currentSelected,
		TRP3_RegisterMiscEdit_Glance_Icon.icon,
		TRP3_RegisterMiscEdit_Glance_Active:GetChecked(),
		stEtN(TRP3_RegisterMiscEdit_Glance_Title:GetText()),
		stEtN(TRP3_RegisterMiscEdit_Glance_TextScrollText:GetText())
	);
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Misc logic
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local function showMiscTab()
	local context = getCurrentContext();
	assert(context, "No context for page player_main !");
	assert(context.profile, "No profile in context");
	TRP3_RegisterMisc:Show();
	displayPeek(context);
	displayRPStyle(context);
end
TRP3_API.register.ui.showMiscTab = showMiscTab;

function TRP3_API.register.player.getMiscExchangeData()
	return get("player/misc");
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Presets
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local LOAD_PREFIX, REMOVE_PREFIX = "+", "-";
local PEEK_PRESETS, PEEK_PRESETS_CATEGORY;
local listData = {};
local titleElement, noneElement;
local rebuildPresetListBox;
local presetStructureForTargetFrame = {};

function TRP3_API.register.ui.getMiscPresetDropListData()
	return presetStructureForTargetFrame;
end

function TRP3_API.register.player.setGlanceSlotPreset(slot, presetID)
	if presetID == -1 then
		applyPeekSlot(slot, nil, nil, nil, nil);
	else
		assert(PEEK_PRESETS[presetID], "Unknown peek preset: " .. tostring(presetID));
		local preset = PEEK_PRESETS[presetID];
		applyPeekSlot(slot, preset.icon, true, preset.title, preset.text);
	end
end

local function createPeekFinalElement(peek)
	return {
		{loc("CM_LOAD"), LOAD_PREFIX .. peek},
		{loc("CM_REMOVE"), REMOVE_PREFIX .. peek}
	};
end

local function buildPresetListData()
	wipe(listData);
	wipe(presetStructureForTargetFrame);
	-- Title
	tinsert(listData, titleElement);
	tinsert(presetStructureForTargetFrame, titleElement);
	tinsert(presetStructureForTargetFrame, noneElement);
	-- Category sorting
	local tmp = {};
	for category, _ in pairs(PEEK_PRESETS_CATEGORY) do
		tinsert(tmp, category);
	end
	table.sort(tmp);
	for _, category in pairs(tmp) do
		local categoryTab = PEEK_PRESETS_CATEGORY[category];
		local categoryListElement = {category, {}};
		local categoryListElementTarget = {category, {}};
		-- Peek
		for _, peek in pairs(categoryTab) do
			local peekInfo = PEEK_PRESETS[peek];
			tinsert(categoryListElement[2], {getIcon(peekInfo.icon, 20) .. " " .. peek, createPeekFinalElement(peek)});
			tinsert(categoryListElementTarget[2], {getIcon(peekInfo.icon, 20) .. " " .. peek, peek});
		end
		tinsert(listData, categoryListElement);
		tinsert(presetStructureForTargetFrame, categoryListElementTarget);
	end
	
	return listData;
end

local function loadPreset(presetID)
	assert(PEEK_PRESETS[presetID], "Unknown peek preset: " .. tostring(presetID));
	TRP3_RegisterMiscEdit_Glance_PresetList:SetSelectedIndex(1);
	local preset = PEEK_PRESETS[presetID];
	TRP3_RegisterMiscEdit_Glance_Active:SetChecked(true);
	TRP3_RegisterMiscEdit_Glance_Title:SetText(preset.title or "");
	TRP3_RegisterMiscEdit_Glance_TextScrollText:SetText(preset.text or "");
	onIconSelected(preset.icon);
end

local function removePreset(presetID)
	assert(PEEK_PRESETS[presetID], "Unknown peek preset: " .. tostring(presetID));
	wipe(PEEK_PRESETS[presetID]);
	PEEK_PRESETS[presetID] = nil;
	for category, categoryTab in pairs(PEEK_PRESETS_CATEGORY) do
		local found = tableRemove(categoryTab, presetID);
		if found and #categoryTab == 0 then
			wipe(PEEK_PRESETS_CATEGORY[category]);
			PEEK_PRESETS_CATEGORY[category] = nil;
		end
	end
	rebuildPresetListBox();
end

local function onPresetSelected(presetAction)
	if presetAction == nil then return end
	local action = presetAction:sub(1, 1);
	if action == LOAD_PREFIX then
		loadPreset(presetAction:sub(2));
	elseif action == REMOVE_PREFIX then
		removePreset(presetAction:sub(2));
	end
end

function rebuildPresetListBox()
	setupListBox(TRP3_RegisterMiscEdit_Glance_PresetList, buildPresetListData(), onPresetSelected, nil, 180, true);
	TRP3_RegisterMiscEdit_Glance_PresetList:SetSelectedIndex(1);
end

local function savePreset()
	local presetTitle = TRP3_RegisterMiscEdit_Glance_Title:GetText();
	local presetText = TRP3_RegisterMiscEdit_Glance_TextScrollText:GetText();
	local presetIcon = TRP3_RegisterMiscEdit_Glance_Icon.icon;
	local presetCategory = TRP3_RegisterMiscEdit_Glance_PresetSaveCategory:GetText();
	local presetID = TRP3_RegisterMiscEdit_Glance_PresetSaveName:GetText();
	if presetCategory:len() == 0 or presetID:len() == 0 then
		toast(loc("REG_PLAYER_GLANCE_PRESET_ALERT1"), 2);
		return;
	end
	if not PEEK_PRESETS[presetID] then
		PEEK_PRESETS[presetID] = {};
		PEEK_PRESETS[presetID].icon = presetIcon;
		PEEK_PRESETS[presetID].title = presetTitle;
		PEEK_PRESETS[presetID].text = presetText;
		if not PEEK_PRESETS_CATEGORY[presetCategory] then
			PEEK_PRESETS_CATEGORY[presetCategory] = {};
		end
		tinsert(PEEK_PRESETS_CATEGORY[presetCategory], presetID);
		TRP3_RegisterMiscEdit_Glance_PresetSaveCategory:SetText("");
		TRP3_RegisterMiscEdit_Glance_PresetSaveName:SetText("");
		rebuildPresetListBox();
	else
		toast(loc("REG_PLAYER_GLANCE_PRESET_ALERT2"):format(presetID), 2);
	end
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Tool
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

function TRP3_API.register.checkGlanceActivation(dataTab)
	for _, glanceTab in pairs(dataTab) do
		if glanceTab.AC then return true end
	end
	return false;
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Init
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

function TRP3_API.register.inits.miscInit()
	buildStyleStructure();
	
	if not TRP3_Presets then
		TRP3_Presets = {};
	end
	if not TRP3_Presets.peek then
		TRP3_Presets.peek = {};
	end
	if not TRP3_Presets.peekCategory then
		TRP3_Presets.peekCategory = {};
	end
	PEEK_PRESETS = TRP3_Presets.peek;
	PEEK_PRESETS_CATEGORY = TRP3_Presets.peekCategory;
	
	setupFieldSet(TRP3_RegisterMiscViewGlance, loc("REG_PLAYER_GLANCE"), 150);
	TRP3_RegisterMiscEdit_Glance_ActiveText:SetText(loc("REG_PLAYER_GLANCE_USE"));
	TRP3_RegisterMiscEdit_Glance_Apply:SetText(loc("CM_APPLY"));
	TRP3_RegisterMiscEdit_Glance_TitleText:SetText(loc("REG_PLAYER_GLANCE_TITLE"));
	TRP3_RegisterGlanceEditorTitle:SetText(loc("REG_PLAYER_GLANCE_EDITOR"));
	TRP3_RegisterMiscViewRPStyleEmpty:SetText(loc("REG_PLAYER_STYLE_EMPTY"));
	TRP3_RegisterMiscEdit_Glance_PresetText:SetText(loc("REG_PLAYER_GLANCE_PRESET"));
	TRP3_RegisterMiscEdit_Glance_PresetSave:SetText(loc("REG_PLAYER_GLANCE_PRESET_SAVE"));
	TRP3_RegisterMiscEdit_Glance_PresetSaveButton:SetText(loc("REG_PLAYER_GLANCE_PRESET_SAVE_SMALL"));
	TRP3_RegisterMiscEdit_Glance_PresetSaveCategoryText:SetText(loc("REG_PLAYER_GLANCE_PRESET_CATEGORY"));
	TRP3_RegisterMiscEdit_Glance_PresetSaveNameText:SetText(loc("REG_PLAYER_GLANCE_PRESET_NAME"));
	
	TRP3_RegisterMiscEdit_Glance_PresetSaveButton:SetScript("OnClick", savePreset);
	TRP3_RegisterMiscEdit_Glance_Icon:SetScript("OnClick", function() showIconBrowser(onIconSelected, onIconClosed); end);
	TRP3_RegisterMiscEdit_Glance_Apply:SetScript("OnClick", peekEditorApply);
	for index=1,5,1 do
		-- DISPLAY
		local button = _G["TRP3_RegisterMiscViewGlanceSlot" .. index];
		button:SetDisabledTexture("Interface\\ICONS\\" .. GLANCE_NOT_USED_ICON);
		button:GetDisabledTexture():SetDesaturated(1);
		button:SetScript("OnClick", onSlotClick);
		button.index = tostring(index);
	end
	
	titleElement = {loc("REG_PLAYER_GLANCE_PRESET_SELECT"), nil};
	noneElement = {loc("REG_PLAYER_GLANCE_PRESET_NONE"), -1};
	rebuildPresetListBox();
	
	-- RP style
	setupFieldSet(TRP3_RegisterMiscViewRPStyle, loc("REG_PLAYER_STYLE_RPSTYLE"), 150);
	
	Events.listenToEvent(Events.REGISTER_MISC_SAVED, function()
		if getCurrentPageID() == "player_main" then
			TRP3_API.popup.hidePopups();
			local context = getCurrentContext();
			assert(context, "No context for page player_main !");
			displayPeek(context);
		end
	end);
end