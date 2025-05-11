local module = {}
local CAS = game:GetService('ContextActionService');

local plr = game.Players.LocalPlayer
local hud = plr.PlayerGui:WaitForChild("HUD", math.huge)
local emotewheel = hud.CentralFrame.EmoteWheel
local emotewheelsize = emotewheel.Size
emotewheel.Size = UDim2.new(0,0,0,0)

local chr = plr.Character or plr.CharacterAdded:Wait()
local hum = chr:WaitForChild('Humanoid')

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game.ReplicatedStorage
local remotes = ReplicatedStorage.Remotes
local remote = remotes.Keybind

local module = {}

local inputs = {
	Skills = {"C","V","B","G"},
	Basic = {},
	Client = {
		["X"] = {
			action_name = "emotewheel",
			cooldown = 0.6,
			pressingtime = 1.5,

			fun = function(state)
				if not plr.Character then return end

				if emotewheel.Visible then
					local anim = game:GetService("TweenService"):Create(emotewheel, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Size = UDim2.new(0,0,0,0)})
					anim:Play()
					anim:Destroy()

					task.delay(0.25, function()
						emotewheel.Visible = false
						emotewheel.Background.Visible = false
					end)
				else
					emotewheel.Visible = true
					emotewheel.Background.Visible = true

					local anim = game:GetService("TweenService"):Create(emotewheel, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = emotewheelsize})
					anim:Play()
					anim:Destroy()
				end

			end,
		}
	}
}

function findType(input)
	return inputs.Skills[input] and "Skill" or inputs.Basic[input] and "Basic"
end

function initializeInputs() -- change
	local newInputs = {}
	for inputType, info in inputs do
		if inputType == "Client" then
			newInputs[inputType] = info
			continue end
		if not newInputs[inputType] then
			newInputs[inputType] = {}
		end
		for i, value in inputs[inputType] do
			newInputs[inputType][value] = true
		end
	end
	inputs = newInputs
end

initializeInputs()

local CustomArgs = (function()
	local t = {};
	
	local folder = script:WaitForChild('CustomBinds')
	
	local setup = function(m)
		t[m.Name] = require(m)	
	end
	
	for _, v in ipairs(folder:GetChildren()) do task.spawn(setup, v) end

	folder.ChildAdded:Connect(setup)

	return t
end)();

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	input = input.KeyCode.Name
	
	local inputType = findType(input)
	
	if not inputType or chr:GetAttribute(input) or chr:GetAttribute("InAction") then return end
	
	local current_style = _G.get_style()
					
	local result = remote:InvokeServer(input, inputType, CustomArgs[current_style] and CustomArgs[current_style][input] and CustomArgs[current_style][input]())
	
	if not result then
		warn("Ability",input,"didn't work.")
	end
end)

-- client

for key, pack in pairs(inputs.Client) do

	local last = 0;

	CAS:BindAction(pack.action_name, function(_, state)
		if state == Enum.UserInputState.End and pack["fun_end"] then -- hold
			pack.fun_end()
			return
		end
		if state ~= Enum.UserInputState.Begin then return end

		if os.clock() - last < pack.cooldown then return end last = os.clock();
		pack.fun()	
	end, false, Enum.KeyCode[key])
end


hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

hum.StateChanged:Connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Jumping then
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

		script.Jump:Play()

		task.wait(0.5)

		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end

	--if newState == Enum.HumanoidStateType.Landed then
	--	script.Land:Play()
	--end
end)

return module
