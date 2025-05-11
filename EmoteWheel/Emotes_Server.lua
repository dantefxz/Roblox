local RS = game:GetService('ReplicatedStorage');

local Assets = RS:WaitForChild('Assets')
local Emotes = Assets:WaitForChild('Emotes')
local DuoEmotes = Emotes:WaitForChild("DuoEmotes")

local module = {
	["Default"] = {
		Animation = Assets:WaitForChild('Emotes'):FindFirstChild('Default'),
		Looped = false,
	}
}

setmetatable(module, {
	__index = {
		GetNewRandomEmote = function(self, plr: Player)
			local data = _G.DATA:Get(plr, "raw")

			local emote_keys = {}; for k, info in pairs(self) do
				if info.Exclusive then continue end

				table.insert(emote_keys, k)
			end

			Random.new():Shuffle(emote_keys);

			for _, k in ipairs(emote_keys) do
				if data.Emotes[k] then continue end

				return (function()
					return k
				end)();
			end
		end,

		GiveEmote = function(self, plr: Player, emote: string)
			local data = _G.DATA:Get(plr, "raw")

			data.Emotes[emote] = {}
			data.Emotes[emote].ID = #plr.Data.Emotes:GetChildren() + 1
			
			_G.LocalFunctions:FireClient(plr,"Notify",{
				Title = "New emote unlocked!",
				Text = "Obtained "..emote.." Emote",
				Icon = "rbxassetid://11713358131"
			})

		end,
	}
})

local emotes = RS.Assets.Emotes

local remote = RS.Remotes.Emotes

local connections = {}
local playing_emotes = {}

function initializeEmotes(player)
	local data = _G.DATA:Get(player, "raw")
	local ID = 1
	data.Emotes["Default"].ID = 1 -- force default to be 1 just in case
	for emote, info in data.Emotes do
		if not info.ID or info.ID == ID then -- due to "Default" being forced, info.ID == ID is to make sure it will respect to go second
			ID += 1
			data.Emotes[emote].ID = ID
		else
			if info.ID >= ID then
				ID = info.ID
			end
		end
	end
end

local function isPathClear(character, secondcharacter, startPos, endPos)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {character, secondcharacter}
	params.FilterType = Enum.RaycastFilterType.Exclude
	local result = workspace:Raycast(startPos, (endPos - startPos), params)
	return result == nil
end

remote.OnServerInvoke = function(player, info)
	local slot, emote = info.slot, info.emote
	local data = _G.DATA:Get(player, "raw")
	local datafolder = player.Data
	local emotesfolder = datafolder.Emotes

	if slot ~= 0 then
		--if tonumber(slot) >= 5 and not player:GetAttribute("EmotesSecondPage") then return false end
		for checkemote, checkinfo in data.Emotes do
			if checkinfo.Equipped == slot then
				data.Emotes[checkemote] = {}
			end
		end
		task.wait()
		data.Emotes[emote].Equipped = slot
		return "update"
	else
		
		local function StartAnimation(player, forcedanim)
			local emote = info.emote
			if forcedanim then emote = forcedanim end
			local animation = emotes:FindFirstChild(emote) or DuoEmotes:FindFirstChild(emote)
			local character = player.Character
			local humanoid = player.Character.Humanoid
			local animator = humanoid:WaitForChild("Animator")
			local anim: AnimationTrack
			local music: Sound
			local motor; 
			
			if character:GetAttribute('DisableEmote') then return end
			
			if character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart.Anchored then return end
			
			--if character:FindFirstChild("WagonWeld") then return end

			local stop_emote = function()	
				player:SetAttribute("Emoting", nil)		
				
				local EmoteObject = character:FindFirstChild('EmoteObject')
				if EmoteObject then EmoteObject:Destroy() end
				if motor then motor:Destroy() end
				
				if playing_emotes[player.UserId] == emote then playing_emotes[player.UserId] = nil end
				if anim then anim:Stop() end
				if character.HumanoidRootPart:FindFirstChild("EmoteMusic") then character.HumanoidRootPart:FindFirstChild("EmoteMusic"):Destroy() end
				if character:FindFirstChild("EmoteEffect") then character.EmoteEffect:Destroy() end			
				if character.HumanoidRootPart:FindFirstChild("DuoEmote") then
					character.HumanoidRootPart:FindFirstChild("DuoEmote"):Destroy()
				end
				local duo = player:GetAttribute("DuoEmoting")
				character.Humanoid.AutoRotate = true
				if duo then
					local duo_player = game.Players:FindFirstChild(duo)
					duo_player:SetAttribute("Emoting", nil)
					duo_player:SetAttribute("DuoEmoting", nil)
					player:SetAttribute("DuoEmoting", nil)
				end
			end

			for _,v in animator:GetPlayingAnimationTracks() do
				if v.Name == "Emote" then
					v:Stop()
				end
			end

			if playing_emotes[player.UserId] == emote then
				playing_emotes[player.UserId] = nil
				stop_emote()
				return 
			end

			playing_emotes[player.UserId] = emote
	
			
			anim = animator:LoadAnimation(animation)
			anim.Name = "Emote"

			if character.HumanoidRootPart:FindFirstChild("EmoteMusic") then
				character.HumanoidRootPart:FindFirstChild("EmoteMusic"):Destroy()
			end

			if character:FindFirstChild("EmoteEffect") then character.EmoteEffect:Destroy() end

			anim:GetMarkerReachedSignal("Effect"):Connect(function(name)
				if character:FindFirstChild("EmoteEffect") then return end

				local EmoteEffect = Assets:WaitForChild('EmotesEffect'):FindFirstChild(name)

				if EmoteEffect then
					local Obj = EmoteEffect:Clone()
					Obj.Parent = character
					Obj.Name = "EmoteEffect"
					Obj:PivotTo(character:GetPivot())

					local Weld = Instance.new('WeldConstraint')
					Weld.Parent = Obj
					Weld.Part0 = character.HumanoidRootPart
					Weld.Part1 = Obj
				end

			end)

			anim:GetMarkerReachedSignal("EmoteObject"):Connect(function(name)
				local EmoteObjects = Assets:WaitForChild('EmotesObject'):FindFirstChild(name)
				if not EmoteObjects or character:FindFirstChild('EmoteObject') then return end
				
				local obj = EmoteObjects:Clone()
				obj.Parent = character
				obj.Name = "EmoteObject"
			end)
			
			anim:GetMarkerReachedSignal("CustomEffect"):Connect(function(name)
				local EmotesObject = Assets.EmotesObject:FindFirstChild(name)
				if EmotesObject then
					task.spawn(function()
						for _,v in EmotesObject:GetChildren() do
							if v:IsA("ModuleScript") then
								task.spawn(function()
									local func = require(v)
									func(player, game.Players:FindFirstChild(player:GetAttribute("DuoEmoting")))
								end)
							end
						end
					end)
				end
				
				_G.LocalEffects:FireAllClients("EmitterEffect",{
					Name = name,
					Position = character.HumanoidRootPart,
					Weld = character.HumanoidRootPart,
					Duration = 5
				})
			end)
			
			anim:GetMarkerReachedSignal("RigObject"):Connect(function(name)
				local EmoteObject = character:FindFirstChild('EmoteObject')
				if not EmoteObject then return end
				
				if character:FindFirstChild(name):FindFirstChild(EmoteObject.PrimaryPart.Name) then return end
				
				motor = Instance.new('Motor6D')
				motor.Name = EmoteObject.PrimaryPart.Name or "Handle"
				motor.Parent = character:FindFirstChild(name)
				motor.Part0 = character:FindFirstChild(name)
				motor.Part1 = EmoteObject.PrimaryPart
				motor.C0 = EmoteObject:FindFirstChild('Offset').Value
			end)
			
			anim:GetMarkerReachedSignal("EmitterEffect"):Connect(function(name)
				_G.LocalEffects:FireAllClients("EmitterEffect",{
					Name = name,
					Position = character.HumanoidRootPart,
					Duration = 5,
				})
			end)
			
			anim:GetMarkerReachedSignal("AuraEffect"):Connect(function(name)
				local split = string.split(name,',')
				
				_G.LocalEffects:FireAllClients("AuraEffect",{
					Name = split[2],
					LocationParts = {character:FindFirstChild(split[1])},
					Duration = split[3] or 2,
				})
				
			end)
			
			anim:GetMarkerReachedSignal("PlaySound"):Connect(function(name)
				_G.Effects.PlaySound(name,{
					Where = character.HumanoidRootPart
				})
			end)

			anim:GetMarkerReachedSignal("Stop"):Connect(function(name)
				anim:AdjustSpeed(0)
			end)
			
			if animation:FindFirstChild("Music") then
				music = animation.Music:Clone()
				music.Parent = character.HumanoidRootPart
				music.Name = "EmoteMusic"
				music:Play()
			end

			anim:Play()

			if anim:GetAttribute("AdjustSpeed") then
				anim:AdjustSpeed(anim:GetAttribute("AdjustSpeed"))
			end

			if not module[info.emote].Looped or forcedanim then
				anim.Stopped:Once(function()
					if playing_emotes[player.UserId] == emote then
						playing_emotes[player.UserId] = nil
						player:SetAttribute("Emoting", false)
					end
				end)
			end

			--if not connections[player.UserId] then
			--	connections[player.UserId] = game:GetService("RunService").Heartbeat:Connect(function() --// Detect if the character is moving
			--		if _G.PLAYERS[player].dead then return end
			--		if (player.Character.HumanoidRootPart.AssemblyLinearVelocity * Vector3.new(1,0,1)).Magnitude > 1 then
			--			stop_emote()
			--		end
			--	end)	
			--end
			
			if not module[info.emote].CanWalk or forcedanim then
				local pos = character.HumanoidRootPart.Position

				if player:GetAttribute("Emoting") and connections[player.UserId] then connections[player.UserId]:Disconnect() end

				connections[player.UserId] = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function() --// Detect if the character is moving
					if humanoid.MoveDirection ~= Vector3.new(0,0,0) then					
						player:SetAttribute("Emoting", false)
					end
				end)	
				
				--player:GetAttributeChangedSignal('Emoting'):Once(function()
				--	if not player:GetAttribute('Emoting') then
				--		connections.MoveDetection:Disconnect()
				--	end
				--end)

			else
				humanoid.Jumping:Once(function(IsJumping)
					if IsJumping then
						stop_emote()
					end
				end)
			end

			player:SetAttribute("Emoting", true)
			
			player:GetAttributeChangedSignal('Emoting'):Once(function()
				connections[player.UserId]:Disconnect()
				stop_emote()
			end)
			
			if animation:GetAttribute("Duo") then
				if character.HumanoidRootPart:FindFirstChild("DuoEmote") then
					character.HumanoidRootPart:FindFirstChild("DuoEmote"):Destroy()
				end
				local prompt = Instance.new("ProximityPrompt")
				prompt.Name = "DuoEmote"
				prompt.Parent = character.HumanoidRootPart
				prompt.ActionText = "Emote together"
				prompt.ObjectText = "Emote"
				prompt.RequiresLineOfSight = false
				prompt.HoldDuration = 0.3
				prompt.MaxActivationDistance = 5
				prompt:AddTag("SelectivePrompt")
				prompt:SetAttribute("PlayersToHide", player.Name)
				prompt.Triggered:Once(function(secondplayer)
					local secondcharacter = secondplayer.Character
					local secondhumanoid = secondcharacter.Humanoid
					local checkingpos = character.HumanoidRootPart.CFrame * CFrame.new(0,0,animation:GetAttribute("DistanceBetween") or -4.3)
					local checkingpos2 = character.HumanoidRootPart.CFrame * CFrame.new(-2,2,animation:GetAttribute("DistanceBetween") or -4.3)
					local checkingpos3 = character.HumanoidRootPart.CFrame * CFrame.new(2,2,animation:GetAttribute("DistanceBetween") or -4.3)
					local distance = (character.HumanoidRootPart.Position - secondcharacter.HumanoidRootPart.Position).Magnitude
					local midpoint = character.HumanoidRootPart.Position + CFrame.new(character.HumanoidRootPart.Position,  checkingpos.Position).LookVector * distance/2 -- could look from either position, doesn't matter.
					if isPathClear(character, secondcharacter, character.HumanoidRootPart.Position, midpoint) and
						isPathClear(character, secondcharacter,checkingpos.Position, midpoint) and
						isPathClear(character, secondcharacter,checkingpos2.Position, midpoint) and
						isPathClear(character, secondcharacter,checkingpos3.Position, midpoint) then
						secondcharacter:PivotTo(checkingpos)
						player:SetAttribute("DuoEmoting", secondplayer.Name)
						secondplayer:SetAttribute("DuoEmoting", player.Name)
						humanoid.AutoRotate = false
						secondhumanoid.AutoRotate = false
						character:PivotTo(CFrame.new(character.HumanoidRootPart.Position, midpoint))
						secondcharacter:PivotTo(CFrame.new(secondcharacter.HumanoidRootPart.Position, midpoint))
						prompt:Destroy()
					else
						player:SetAttribute("Emoting", false)
						prompt:Destroy()
						return
					end
					character:PivotTo(CFrame.new(character.HumanoidRootPart.Position, midpoint))
					secondcharacter:PivotTo(CFrame.new(secondcharacter.HumanoidRootPart.Position, midpoint))
					StartAnimation(player, animation:GetAttribute("Player1"))
					StartAnimation(secondplayer, animation:GetAttribute("Player2"))
				end)
			end
		end
		
		StartAnimation(player)
	end
end

game.Players.PlayerAdded:Connect(function(player)
	initializeEmotes(player)
end)

return module
