local ReplicatedStorage = game.ReplicatedStorage
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local styleMain = require(script:WaitForChild("StylesMain"))
local remote = Remotes:WaitForChild("Keybind")

local module = {}

function skillMode(player, key, skills)
	local playerobject = _G.PLAYERS[player]
	local character = player.Character
	local info = skills[key]["Modes"]
	local totalmodes = #info
	local current = 0
	if not character:GetAttribute(key.."Mode") then
		character:SetAttribute(key.."Mode", 1)
		current = 1
	else
		current = character:GetAttribute(key.."Mode")
		if current + 1 > totalmodes then warn("Bug with",key,"!") return end -- this will never happen
		current += 1
		playerobject:set_attribute(key.."Mode", current, {StaticCooldown = info[current].ModeDuration or false})
	end
	return info[current]
end

function useSkill(player, key, ...)
	local playerobject = _G.PLAYERS[player]
	local style = playerobject:get_style()
	local character = player.Character
	local skills = styleMain[style].Skills
	
	-- // Flow
	local function checkFlow()
		if key == "G" then
			local activatedFlow = styleMain.Flow(player)
			return activatedFlow
		end
		return nil
	end
	
	if character:GetAttribute("Flow") then
		skills = styleMain[style].FlowSkills
	end
	-- //
	
	-- // Get ability and apply cooldowns
	local info = skills[key]
	if not info then return end
	if info["Modes"] then
		local currentmode = skillMode(player, key, skills)
		if currentmode then
			info = currentmode
		end
	end
	if not info.func then return end
	if character:GetAttribute(key) then return end
	playerobject:set_attribute("InAction", info.InAction or 0)
	playerobject:set_attribute(key, info.Cooldown or 0)
	--//
	
	--// Execute
	local canFlow, result = checkFlow()
	if canFlow ~= nil then
		result = true
	else
		result = info.func(player, ...)
	end
	
	if not result then
		playerobject:set_attribute("InAction", nil)
		playerobject:set_attribute(key, nil)
	end
	--//
	
	return result
end

function useBasic(player, key)
	
end

remote.OnServerInvoke = function(player, key, inputType, ...)
	local character = player.Character
	if character:GetAttribute("InAction") then return end
	local types = {
		["Skill"] = useSkill,
		["Basic"] = useBasic
	}
	local result = types[inputType](player, key, ...)
	return result
end

setmetatable(module, {__index = styleMain})

return module
