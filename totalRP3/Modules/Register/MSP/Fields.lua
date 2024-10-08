-- Copyright The Total RP 3 Authors
-- SPDX-License-Identifier: Apache-2.0

local Ellyb = TRP3_API.Ellyb;

local Globals = TRP3_API.globals;

local module = AddOn_TotalRP3.MSP or {};

module.TOOLTIP_FIELDS = {"CO", "IC", "PX", "RC", "RS", "TR", "PN"};
module.REQUEST_FIELDS = {"TT", "IC", "PG", "PR", "PN", "PV", "CO", "AE", "AG", "AH", "AW", "DE", "HB", "HH", "HI", "MO", "NH", "MU", "PE", "PS", "RS"};

-- Registry of known serializers/deserializers by name.
local serializers = {};
local deserializers = {};

-- SerializeField converts a given TRP profile value back to an
-- MSP-exportable value (typically a string or number).
--
-- If the serializer for the named field encounters an error, it is logged
-- and nil is returned instead.
function module.SerializeField(field, ...)
	Ellyb.Assertions.isNotNil(field, "field");

	local serializer = serializers[field];
	if not serializer then
		return nil;
	end

	local ok, result = pcall(serializer, ...);
	if not ok then
		local err = result or "<nil error>";
		TRP3_API.Logf("Error serializing field %q: %s", field, err);
		return nil;
	end

	return result;
end

-- DeserializeField converts a given field value back to a TRP-compatible
-- result for storage in a profile.
--
-- If the deserializer for the named field encounters an error, it is logged
-- and nil is returned instead.
function module.DeserializeField(field, value)
	Ellyb.Assertions.isNotNil(field, "field");

	local deserializer = deserializers[field];
	if not deserializer then
		return nil;
	end

	local ok, result = pcall(deserializer, value);
	if not ok then
		local err = result or "<nil error>";
		TRP3_API.Logf("Error deserializing field %q: %s", field, err);
		return nil;
	end

	return result;
end

-- Registers a field with the given name and specification. The specification
-- must contain two functions with the keys Serialize and Deserialize.
--
-- If the field already exists, an error is raised.
--
-- @param field string The name of the field to add.
-- @param spec  table  The specification for this field.
function module.RegisterField(field, spec)
	Ellyb.Assertions.isNotNil(field, "field");
	Ellyb.Assertions.isType(spec, "table", "spec");

	-- Check the required fields in the spec table and assert their existence.
	Ellyb.Assertions.isNotNil(spec.Serialize, "spec.Serialize");
	Ellyb.Assertions.isNotNil(spec.Deserialize, "spec.Deserialize");

	-- Verify the field doesn't already exist.
	if serializers[field] or deserializers[field] then
		error(("Field %q has already been registered"):format(field), 2);
	end

	serializers[field] = spec.Serialize;
	deserializers[field] = spec.Deserialize;
end

-- Attempts to register a named field with the given specification. If the
-- field already exists, false is returned, else true.
function module.TryRegisterField(...)
	if not pcall(module.RegisterField, ...) then
		return false;
	end

	return true
end

AddOn_TotalRP3.MSP = module;

---
--- Serializer/Deserializer Implementations
---

-- The PS field is serialized to the form:
--    attr  := ident "=" quoted-value
--    trait := "[trait" { " " attr } "]"
--
-- Where `ident` is just an ASCII string identifier like "name" or "icon"
-- with support for limited special characters (-, _), and `quoted-value` is
-- a value wrapped in double quotes.
--
-- For now, there's no support for escaping " characters in quoted-values`.
--
-- Example:
--    [trait id="3" value="0.75"]
--    [trait value="0.4" left-name="My Left Trait" right-name="My Right Trait"]
--
-- A newline may be present between individual trait pairs but isn't required.
--
-- In terms of attributes, the following are supported:
--    id:    Numeric identifier for a standard trait.
--    value: [0-1] floating point number representing the strength of this trait.
--    (left|right)-name:  Name of a custom trait.
--    (left|right)-icon:  Name of a custom icon for this trait.
--    (left|right)-color: Hexadecimal color code for this trait.

-- Min/max ranges of the known trait IDs. These map to our own internal
-- trait ID definitions exactly, but if we add new ones then other addons
-- would need to support them too.
local PS_MIN_BUILTIN_TRAIT_ID = 1;
local PS_MAX_BUILTIN_TRAIT_ID = 11;

-- Format strings used when serialising the traits.
local PS_BUILTIN_FORMAT = "[trait value=\"%.2f\" id=\"%d\"]";
local PS_CUSTOM_FORMAT = "[trait value=\"%.2f\""
	.. " left-name=%q left-icon=%q left-color=\"%02x%02x%02x\""
	.. " right-name=%q right-icon=%q right-color=\"%02x%02x%02x\""
	.. "]";

module.TryRegisterField("PS", {
	Serialize = function(traits)
		local out = {};
		for _, trait in ipairs(traits) do
			local value = (Globals.PSYCHO_DEFAULT_VALUE_V2 / Globals.PSYCHO_MAX_VALUE_V2);

			if trait.V2 then
				value = trait.V2 / Globals.PSYCHO_MAX_VALUE_V2;
			end

			-- If there's an ID it's a built-in trait, otherwise it's custom
			-- and thus needs the name/icon/color stuff.
			if trait.ID
				and trait.ID >= PS_MIN_BUILTIN_TRAIT_ID
				and trait.ID <= PS_MAX_BUILTIN_TRAIT_ID then
				-- It's a builtin trait within the known ID range.
				table.insert(out, PS_BUILTIN_FORMAT:format(value, trait.ID));
			elseif trait.LT and trait.RT then
				-- We'll strip " and ] from the names for simplicity if present.
				local leftName = trait.LT:gsub("[%]=]", "");
				local leftIcon = trait.LI or TRP3_InterfaceIcons.Default;
				local leftColor = trait.LC or TRP3_API.MiscColors.PersonalityTraitColorLeft:GetRGBTable();

				local rightName = trait.RT:gsub("[%]=]", "");
				local rightIcon = trait.RI or TRP3_InterfaceIcons.Default;
				local rightColor = trait.RC or TRP3_API.MiscColors.PersonalityTraitColorRight:GetRGBTable();

				table.insert(out, PS_CUSTOM_FORMAT:format(
					value,
					leftName,
					leftIcon,
					(leftColor.r or 1) * 255,
					(leftColor.g or 1) * 255,
					(leftColor.b or 1) * 255,
					rightName,
					rightIcon,
					(rightColor.r or 1) * 255,
					(rightColor.g or 1) * 255,
					(rightColor.b or 1) * 255
				));
			end
		end

		-- Join all the resulting traits into a single string.
		local traitString = table.concat(out, "\n");

		return traitString;
	end,

	Deserialize = function(fieldValue)
		-- Shortcut cases where a profile hasn't given us a thing.
		if not fieldValue or type(fieldValue) ~= "string" then
			return nil;
		end

		-- We'll store the resulting trait structures here.
		local traits = {};

		-- Parse each [trait {attr...}] block.
		for trait in fieldValue:gmatch("%[trait [^%]]-%]") do
			local struct = {};

			-- And then each attr="value" pair.
			for key, value in trait:gmatch("([%w_-]+)=\"([^\"]*)\"") do
				if key == "id" then
					struct.ID = tonumber(value);
				elseif key == "value" then
					struct.V2 = math.floor(tonumber(value) * Globals.PSYCHO_MAX_VALUE_V2);
				elseif key == "left-name" then
					struct.LT = value;
				elseif key == "left-icon" then
					struct.LI = value;
				elseif key == "left-color" then
					struct.LC = TRP3_API.CreateColorFromHexString(value):GetRGBTable();
				elseif key == "right-name" then
					struct.RT = value;
				elseif key == "right-icon" then
					struct.RI = value;
				elseif key == "right-color" then
					struct.RC = TRP3_API.CreateColorFromHexString(value):GetRGBTable();
				end
			end

			-- If it's a built-in clear any extraenous junk.
			if struct.ID then
				-- Capture the keepable fields and then wipe the table. Less
				-- hassle when new things pop up.
				local id = struct.ID;
				local va = struct.VA;
				local v2 = struct.V2;

				table.wipe(struct);

				struct.ID = id;
				struct.VA = va;
				struct.V2 = v2;
			elseif struct.LT and struct.RT then
				-- It's custom, default any missing fields.
				struct.LI = struct.LI or TRP3_InterfaceIcons.Default;
				struct.LC = struct.LC or TRP3_API.MiscColors.PersonalityTraitColorLeft:GetRGBTable();
				struct.RI = struct.RI or TRP3_InterfaceIcons.Default;
				struct.RC = struct.RC or TRP3_API.MiscColors.PersonalityTraitColorRight:GetRGBTable();
			end

			-- Only register traits that are valid. If the ID or custom names
			-- are missing, or the value isn't present we'll ignore it.
			if (struct.ID or (struct.LT and struct.RT)) and struct.V2 then
				table.insert(traits, struct);
			end
		end

		return traits;
	end,
});
