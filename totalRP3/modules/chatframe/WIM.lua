local function onStart()
	-- Stop right here if Prat is not installed
	if not WIM then return false, "WIM not found." end

	local TRP3GetColoredName = TRP3_API.utils.customGetColoredName;
	local get = TRP3_API.profile.getData;
	local getColoredName = TRP3_API.chat.getColoredName;
	local getFullName = TRP3_API.chat.getFullnameUsingChatMethod;
	local numberToHexa = TRP3_API.utils.color.numberToHexa;
	local _G = _G;

	setfenv(1, WIM);

	local classes = constants.classes;

	classes.GetColoredNameByChatEvent = TRP3GetColoredName;

	classes.GetMyColoredName = function()
		local name = _G.UnitName("player");
		local info = get("player");
		name = getFullName(info, name);
		local color = getColoredName(info);
		if not color then
			local class, englishClass = _G.UnitClass("player");
			local classColorTable = _G.RAID_CLASS_COLORS[englishClass];
			color = numberToHexa(classColorTable.r * 255) .. numberToHexa(classColorTable.g * 255) .. numberToHexa(classColorTable.b * 255)
		end
		return ("|cff%s%s|r"):format(color, name);
	end
end

local MODULE_STRUCTURE = {
	["name"] = "WIM support",
	["description"] = "Add support for the WoW Instant Messenger (WIM) add-on.",
	["version"] = 1.000,
	["id"] = "trp3_wim",
	["onStart"] = onStart,
	["minVersion"] = 25,
};

TRP3_API.module.registerModule(MODULE_STRUCTURE);