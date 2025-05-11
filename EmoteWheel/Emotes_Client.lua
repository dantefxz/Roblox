-- explorer stuff
local player = game.Players.LocalPlayer
local data = player:WaitForChild("Data")
local replicated_emotes = data:WaitForChild("Emotes")
local RS = game.ReplicatedStorage
local assets = RS:WaitForChild('Assets')
local remote = RS:WaitForChild('Remotes'):WaitForChild('Emotes')
local emotes = assets:WaitForChild('Emotes')

-- GUI
local BaseFrame = script.Parent.Parent:FindFirstChild('CentralFrame') or script.Parent.Parent
local emotewheel = BaseFrame.EmoteWheel
local mainframe = emotewheel.Background.Frame
local emotelist = emotewheel.EmotesList
local editlist = emotelist.List
local edittemplate = editlist.Template
local searchbar = emotelist.Search

local tweenservice = game:GetService("TweenService")
local marketplaceservice = game:GetService("MarketplaceService")

local editing = false

local mouseEnterColor = Color3.fromRGB(0, 0, 0)
local mouseLeaveColor = Color3.fromRGB(255,255,255)

-- prepare main dummy
local description = game.Players:GetHumanoidDescriptionFromUserId(player.UserId)
local dummy = game.Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R6,"Default")
if dummy:FindFirstChild("Animate") then
	dummy.Animate:Destroy()
end
for i,v in pairs(dummy.Humanoid:GetPlayingAnimationTracks()) do
	v:Stop()
end
dummy.Name = "EmoteDummy"
-- main
local module = {}

function openEditor(button, value)
	if not value then
		editing = false
		emotelist.Visible = false
		if button then
			local anim = tweenservice:Create(button, TweenInfo.new(0.2), {ImageColor3 = mouseLeaveColor})
			anim:Play()
			anim:Destroy()
		end
		return
	end
	local number = tonumber(button.Name)
	local anim = tweenservice:Create(button, TweenInfo.new(0.2), {ImageColor3 = Color3.fromRGB(69, 160, 221)})
	anim:Play()
	anim:Destroy()
	if (number % 2) == 1 then -- left side
		emotelist.Position = UDim2.fromScale(-0.017, 0.499)
		emotelist.Visible = value
	else -- right side
		emotelist.Position = UDim2.fromScale(1.016, 0.499)
		emotelist.Visible = value
	end
end

function checkButton(button)
	if button:GetAttribute("Emote") == "N/A" then
		button.ImageTransparency = 0.8
		button.Template.AddImage.Visible = true
		button.Template.ViewportFrame.Visible = false
	else
		button.ImageTransparency = 0.4
		button.Template.AddImage.Visible = false
		button.Template.ViewportFrame.Visible = true
	end
end

function updateUI()
	if not player:GetAttribute("DataLoaded") then player:GetAttributeChangedSignal("DataLoaded"):Wait() end
	for _, emote in replicated_emotes:GetChildren() do
		for _, button in mainframe:GetChildren() do
			if not button:IsA("ImageLabel") then continue end
			local equippedvalue = emote:FindFirstChild("Equipped")
			if (not equippedvalue and button:GetAttribute("Emote") ~= "N/A" and button:GetAttribute("Emote") == emote.Name) or (equippedvalue and button:GetAttribute("Emote") == emote.Name and equippedvalue.Value ~= button.Name) then
				-- make dummy to stop playing if unequipped or slot is changed
				button:SetAttribute("Emote", "N/A")
				local dummy = button.Template.ViewportFrame.WorldModel.EmoteDummy
				loadDummy(dummy, nil)
			end
			if equippedvalue and equippedvalue.Value == button.Name and button:GetAttribute("Emote") ~= emote.Name then -- apply dummy animation
				button:SetAttribute("Emote", emote.Name)
				local dummy = button.Template.ViewportFrame.WorldModel.EmoteDummy
				local emoteinstance = emotes:FindFirstChild(emote.Name)
				loadDummy(dummy, emoteinstance)
			end
			button.Template.TextLabel.Text = button:GetAttribute("Emote") or "N/A"
			if not button:GetAttribute("Emote") then
				warn(button.Name," Has no Emote Attribute!")
			end
			checkButton(button)
		end
	end
end

function loadDummy(dummy, emoteinstance)
	if emoteinstance then
		loadDummy(dummy, nil)
		local anim = dummy.Humanoid:LoadAnimation(emoteinstance)
		anim.Name = "Emote"
		anim.Looped = true
		anim:Play()
	else
		for _,v in dummy.Humanoid:GetPlayingAnimationTracks() do
			if v.Name == "Emote" then
				v:Stop()
			end
		end
	end
end

function updateList(newemote)
	for _, emote in replicated_emotes:GetChildren() do
		if editlist:FindFirstChild(emote.Name) then continue end
		local template = edittemplate:Clone()
		template.Name = emote.Name
		template.TextName.Text = emote.Name
		template.Visible = true
		template.Parent = editlist
		template.LayoutOrder = emote:FindFirstChild('ID') and emote.ID.Value or 0
		if newemote and newemote.Name == emote.Name then
			template.Background.ImageColor3 = Color3.fromRGB(170, 85, 0)
			template.Background.UIStroke.Color = Color3.fromRGB(99, 50, 0)
			template.NewIcon.Visible = true
			template.LayoutOrder = 0
		end
		template.MouseButton1Click:Connect(function()
			if editing == false then return end
			template.Background.ImageColor3 = Color3.fromRGB(255, 209, 134)
			template.Background.UIStroke.Color = Color3.fromRGB(130, 106, 68)
			template.NewIcon.Visible = false
			template.LayoutOrder = emote:FindFirstChild('ID') and emote.ID.Value or 0
			_G.Sounds["Equip"]:Play()
			local info = {slot = editing, emote = emote.Name}
			openEditor(template, false)
			local action = remote:InvokeServer(info)
			if action == "update" then
				updateUI()
			end
		end)
	end
end

for _, button: ImageLabel in emotewheel:GetDescendants() do
	if not button:IsA("ImageLabel") then continue end
	if not tonumber(button.Name) then continue end

	local pressingtime, lasttime = 0.5, nil
	local lockedup = false
	local OGX, OGY = button.Size.X.Scale, button.Size.Y.Scale
	local function editor()
		lasttime = nil
		openEditor(button, true)
		_G.Sounds["Click"]:Play()
		if editing and editing ~= button.Name then
			mainframe:FindFirstChild(editing).ImageColor3 = mouseLeaveColor
		elseif editing and editing == button.Name then
			openEditor(button, false)
			return
		end
		editing = button.Name
	end
	
	button.Hitbox.MouseEnter:Connect(function()
		task.wait()
		if editing ~= button.Name then
			local anim = tweenservice:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = mouseEnterColor, Size = UDim2.fromScale(button.Size.X.Scale * 1.03, button.Size.Y.Scale * 1.03)})
			local addanim =  tweenservice:Create(button.Template.AddImage, TweenInfo.new(0.2), {ImageTransparency = 0.4})
			anim:Play()
			anim:Destroy()
			addanim:Play()
			addanim:Destroy()
		end
	end)

	button.Hitbox.MouseLeave:Connect(function()
		if editing ~= button.Name then
			local anim = tweenservice:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = mouseLeaveColor, Size = UDim2.fromScale(OGX, OGY)})
			local addanim =  tweenservice:Create(button.Template.AddImage, TweenInfo.new(0.2), {ImageTransparency = 0.8})
			anim:Play()
			anim:Destroy()
			addanim:Play()
			addanim:Destroy()
		end
	end)

	button.Hitbox.MouseButton1Down:Connect(function()
		_G.Sounds["Click"]:Play()
		lasttime = tick()
		while lasttime ~= nil do
			if (tick() - lasttime) >= pressingtime then
				editor(button)
				lockedup = true
				break
			end
			task.wait()
		end
		lasttime = nil
	end)

	button.Hitbox.MouseButton2Down:Connect(function()
		editor(button)
	end)
	
	button.Hitbox.MouseButton1Up:Connect(function()
		if (lasttime == nil or (tick() - lasttime) <= pressingtime) and not lockedup then
			lasttime = nil
			local info = {slot = 0, emote = button:GetAttribute("Emote")}
			emotewheel.Visible = false
			openEditor((typeof(editing) == "string" and mainframe:FindFirstChild(editing)) or nil, false)
			if button:GetAttribute("Emote") == "N/A" and info.slot == 0 then return end
			local action = remote:InvokeServer(info)
		end
		lockedup = false
	end)

	local dummy = dummy:Clone()
	local camera = Instance.new("Camera")
	local viewportframe = button.Template.ViewportFrame
	viewportframe.CurrentCamera = camera
	dummy.Parent = viewportframe.WorldModel
	camera.Parent = viewportframe
	dummy:PivotTo(camera.CFrame * CFrame.new(0,-1,-6))
	dummy.PrimaryPart.CFrame = dummy.PrimaryPart.CFrame * CFrame.Angles(0, math.pi, 0)
end

emotewheel.Changed:Connect(function()
	if not emotewheel.Visible then
		editing = false
		for _, button in mainframe:GetChildren() do
			if not button:IsA("ImageButton") then continue end
			checkButton(button)
		end
	end
end)

searchbar.Changed:Connect(function(att) -- GetAttributeChangedSignal("Text") didn't work
	if att ~= "Text" then return end
	local textlength = #searchbar.Text
	if textlength == 0 then
		for _, button in editlist:GetChildren() do
			if not button:IsA("ImageButton") or button.Name == "Template" then continue end
			button.Visible = true
		end
	else
		for _, button in editlist:GetChildren() do
			if not button:IsA("ImageButton") then continue end
			if string.sub(string.lower(searchbar.Text), 0, textlength) ~= string.sub(string.lower(button.Name), 0, textlength) then
				button.Visible = false
			end
		end
	end
end)

updateUI()
updateList()

replicated_emotes.ChildAdded:Connect(updateList)

local emote_setup = function(this_plr)
		--if this_plr == player then return end

	this_plr:GetAttributeChangedSignal('Emoting'):Connect(function()
		if this_plr:GetAttribute("Emoting") and not player:GetAttribute("EmotesMusic") then

			while this_plr:GetAttribute("Emoting") do
				if not this_plr.Character then break end
					
				local music = this_plr.Character:WaitForChild('HumanoidRootPart'):FindFirstChild('EmoteMusic')
				if not music then task.wait() continue end

				music.Volume = 0
				task.wait()
			end
		end
	end)
end

for _, this_plr in ipairs(game.Players:GetPlayers()) do
	emote_setup(this_plr)
end

game.Players.ChildAdded:Connect(emote_setup)


return module