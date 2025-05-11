local Styles = {}
local ReplicatedStorage = game.ReplicatedStorage
local Modules = ReplicatedStorage.Modules
local Remotes = ReplicatedStorage.Remotes
local requestStyles = Remotes.RequestStyles

local Replication = {}
local sharedFunctions = {
	InitializeFlow = function(player, max) -- max seconds it takes to charge Flow
		local playerobject = _G.PLAYERS[player]
		local character = player.Character or player.CharacterAdded:Wait()
		character:GetAttributeChangedSignal("FlowBar"):Connect(function()
			if character:GetAttribute("Flow") then return end
			local att = character:GetAttribute("FlowBar")
			if att + 1 <= max then
				task.wait(1)
				playerobject:set_attribute("FlowBar", att + 1, {NoCountdown = true})
			end
		end)
		character:GetAttributeChangedSignal("Flow"):Connect(function()
			local att = character:GetAttribute("FlowBar")
			if not character:GetAttribute("Flow") then
				task.wait(1)
				playerobject:set_attribute("FlowBar", att + 1, {NoCountdown = true})
				return
			end
		end)
		
		if not character:GetAttribute("FlowBar") then
			playerobject:set_attribute("FlowBar", 0, {NoCountdown = true})
		end
	end,
	Flow = function(player)
		local playerobject = _G.PLAYERS[player]
		local character = player.Character
		local style = _G.PLAYERS[player].get_style()
		if character:GetAttribute("FlowBar") ~= Styles[style].FlowBar or character:GetAttribute("Flow") then return false end
		local result = Styles[style]["Skills"]["G"].func(player) -- effect most likely
		playerobject:set_attribute("Flow", Styles[style].FlowTime)
		playerobject:set_attribute("FlowBar", 0, {NoCountdown = true})
		for key in Styles[style]["FlowSkills"] do
			if character:GetAttribute(key) then
				playerobject:set_attribute(key, nil)
			end
		end
		print("starting Flow", player)
		return result
	end,
}

local meta = {
	__index = sharedFunctions
}

setmetatable(Styles, meta)
for _, mod in script:GetChildren() do
	if mod:IsA("ModuleScript") then
		local style = require(mod)
		setmetatable(style, meta)
		Styles[mod.Name] = style
	end
end

for style, info in Styles do -- Inherit Flow's skills
	for key, skillInfo in Styles[style]["FlowSkills"] do
		if skillInfo.Inherit == true then
			Styles[style]["FlowSkills"][key] = table.clone(Styles[style]["Skills"][key])
		end
	end
end

for style, info in Styles do -- Prepare replication
	Replication[style] = {}
	Replication[style]["FlowBar"] = info.FlowBar
	Replication[style]["FlowTime"] = info.FlowTime
	Replication[style]["FlowSkills"] = {}
	Replication[style]["Skills"] = {}
	for key, skillInfo in Styles[style]["FlowSkills"] do
		if Styles[style]["FlowSkills"][key]["Modes"] then
			Replication[style]["FlowSkills"][key] = {}
			Replication[style]["FlowSkills"][key]["Modes"] = {}
			for mode, info in Styles[style]["FlowSkills"][key]["Modes"] do
				Replication[style]["FlowSkills"][key]["Modes"][mode] = {Cooldown = info.Cooldown or nil, Name = info.Name or "-"}
			end
		else
			Replication[style]["FlowSkills"][key] = {Cooldown = skillInfo.Cooldown or nil, Name = skillInfo.Name or "-"}
		end
	end
	for key, skillInfo in Styles[style]["Skills"] do
		if Styles[style]["Skills"][key]["Modes"] then
			Replication[style]["Skills"][key] = {}
			Replication[style]["Skills"][key]["Modes"] = {}
			for mode, info in Styles[style]["Skills"][key]["Modes"] do
				Replication[style]["Skills"][key]["Modes"][mode] = {Cooldown = info.Cooldown or nil, Name = info.Name or "-"}
			end
		else
			Replication[style]["Skills"][key] = {Cooldown = skillInfo.Cooldown or nil, Name = skillInfo.Name or "-"}
		end
	end
end


requestStyles.OnServerInvoke = function(player)
	return Replication
end

return Styles
