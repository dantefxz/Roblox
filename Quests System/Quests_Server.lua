-- // Services/Modules
local ReplicatedStorage = game.ReplicatedStorage
local Remotes = game.ReplicatedStorage:WaitForChild("Remotes")
local ReplicatedModules = ReplicatedStorage:WaitForChild("Modules")
local QuestsList = require(ReplicatedModules:WaitForChild("QuestsList"))
local TimeFunctions = require(ReplicatedModules:WaitForChild("TimeFunctions"))
local remote = Remotes:WaitForChild("Quests")

local module = {
	functions = {}
}

local SelfFunctions = module.functions

function returnData(player)
	local data = _G.DATA:Get(player, "raw")
	if not data or not data.Quests then
		warn("Quests data not found/didn't load. Player: "..player.Name)
		return false, "Data not found."
	end
	return data
end

function cleanQuests(player)
	local data = returnData(player)
	for key, info in data.Quests.Quests do
		if not QuestsList.Limited[key] and not QuestsList.Normal[key] and not QuestsList.Premium[key] then
			data.Quests.Quests[key] = nil
		end
	end
end

function checkLimiteds(player)
	local data = returnData(player)
	local currentUTC = os.time()
	
	for key, info in QuestsList.Limited do
		local questdifference = TimeFunctions.daysDifference(info.StartTime, currentUTC)
		if not info.Duration then continue end
		if info.Duration > questdifference then
			if not data.Quests.Quests[key] and not data.Quests.CompletedLimited[key] then
				data.Quests.Quests[key] = {
					Limited = true,
					Progress = {Current = 0, Max = info.Progress},
					Type = info.Type or nil,
					Mob = info.Mob or nil
				}
			end
			continue
		else
			data.Quests.Quests[key] = nil
		end
	end
end

function rollQuest(player, amount)
	local data = returnData(player)
	local quests = {}
	for key in QuestsList.Normal do
		table.insert(quests, key)
	end
	for i = 1, amount do
		if #quests == 0 then break end
		local key = quests[math.random(1, #quests)]
		local questinfo = QuestsList.Normal[key]
		local progress = questinfo.Progress
		if typeof(progress) == "table" then
			progress = questinfo.Progress[math.random(1, #questinfo.Progress)]
		end
		data.Quests.Quests[key] = {
			Progress = {Current = 0, Max = progress},
			Completed = nil,
			Type = questinfo.Type or nil,
			Mob = questinfo.Mob or nil
		}
		table.remove(quests, table.find(quests, key))
	end
end

function giveReward(player, quest)
	local data = returnData(player)
	local questinfo
	if data.Quests.Quests[quest].Limited then
		questinfo = QuestsList.Limited[quest]
	else
		questinfo = QuestsList.Normal[quest]
	end
	_G.ECONOMY:ProcessEconomy(player, data, 'Tokens', 'QUEST', questinfo.Rewards.Tokens)
	for thing, list in questinfo.Rewards do
		if thing == "Tokens" then continue end
		for _, value in list do
			if thing == "Masks" then
				_G.FUNCTIONS.GiveMask(player, value)
			elseif thing == "Packages" then
				_G.FUNCTIONS.GivePackage(player, value)
			elseif thing == "Boosts" then
				if questinfo.Rewards.Boosts.DoublePartyTokens then
					local amount = questinfo.Rewards.Boosts.DoublePartyTokens
					data.Boosts['DoublePartyTokens'] = amount + (data.Boosts['DoublePartyTokens'] or 0);
				end
				if questinfo.Rewards.Boosts.DoubleTokens then
					local amount = questinfo.Rewards.Boosts.DoubleTokens
					data.Boosts['DoubleTokens'] = amount + (data.Boosts['DoubleTokens'] or 0);
				end
			end
		end
	end
end

function SelfFunctions.Init(player)
	local data = returnData(player)

	local currentUTC = os.time()
	local lastTime = data.Quests.LastTime

	local difference = TimeFunctions.daysDifference(lastTime, currentUTC)
	
	cleanQuests(player)
	
	if difference >= 1 then
		for key, info in data.Quests.Quests do
			if info.Limited or info.Premium then continue end
			data.Quests.Quests[key] = nil
		end
		data.Quests.LastTime = os.time()
		rollQuest(player, 3)
		if player.MembershipType == Enum.MembershipType.Premium then
			data.Quests.PremiumReroll = true
			for key, info in QuestsList.Premium do
				local progress = info.Progress
				if typeof(progress) == "table" then
					progress = info.Progress[math.random(1, #info.Progress)]
				end
				data.Quests.Quests[key] = {
					Progress = {Current = 0, Max = progress},
					Completed = nil,
					Premium = true,
					Type = info.Type or nil,
					Mob = info.Mob or nil
				}
			end
		end
	end
	checkLimiteds(player)
end

remote.OnServerInvoke = function(player, action, key)
	local data = returnData(player)
	if action == "reroll" then
		if data.Quests.PremiumReroll == true then
			data.Quests.PremiumReroll = false
		elseif data.RerollTokens > 0 then
			data.RerollTokens -= 1
		else
			return false
		end
		for key, info in data.Quests.Quests do
			if info.Limited or info.Premium then continue end
			data.Quests.Quests[key] = nil
		end
		rollQuest(player, 3)
		return true
	elseif action == "claim" then
		local questprogress = data.Quests.Quests[key].Progress
		if questprogress.Current >= questprogress.Max and not data.Quests.Quests[key].Completed then
			data.Quests.Quests[key].Completed = true
			giveReward(player, key)
		end
	elseif action == "reload" then
		SelfFunctions.Init(player)
	end
end

game.Players.PlayerAdded:Connect(function(player)
	SelfFunctions.Init(player)
end)

for i,player in game.Players:GetPlayers() do
	SelfFunctions.Init(player)
end

return module
