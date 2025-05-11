-- // Player
local player = game.Players.LocalPlayer
local data = player:WaitForChild("Data")
local questsdata = data:WaitForChild("Quests")
local quests = questsdata:WaitForChild("Quests")
local lasttimequests = questsdata.LastTime
local rerolltokens = data.RerollTokens
local completedllimited = questsdata.CompletedLimited

-- // Functions
local ReplicatedStorage = game.ReplicatedStorage
local MarketplaceService = game:GetService("MarketplaceService")
local Remotes = game.ReplicatedStorage:WaitForChild("Remotes")
local ReplicatedModules = ReplicatedStorage:WaitForChild("Modules")
local QuestList = require(ReplicatedModules:WaitForChild("QuestsList"))
local TimeFunctions = require(ReplicatedModules:WaitForChild("TimeFunctions"))
local remote = Remotes:WaitForChild("Quests")

-- // GUI
local mainframe = script.Parent.Parent.CentralFrame.Quests
local scrollingframe = mainframe.List.ScrollingFrame
local templatequest = scrollingframe.Template
local templatepremiumquest = scrollingframe.PremiumTemplate
local buyrerolls = mainframe.BuyRerolls
local close = mainframe.Close
local reroll = mainframe.Reroll
local rerollamount = mainframe.RerollText
local resettext = mainframe.ResetText

function updateRerolls()
	local premiumreroll = questsdata:FindFirstChild("PremiumReroll")
	local totalrerolls = rerolltokens.Value
	if premiumreroll then
		totalrerolls += 1
	end
	rerollamount.Text = "Quest Rerolls: "..totalrerolls
	if totalrerolls > 0 then
		reroll.Background.ImageColor3 = Color3.fromRGB(0, 170, 255)
	else
		reroll.Background.ImageColor3 = Color3.fromRGB(71,71,71)
	end
end

function loadQuests()
	updateRerolls()
	
	for i,frame in scrollingframe:GetChildren() do
		if frame:IsA("Frame") and frame.Visible then
			frame:Destroy()
		end
	end
	
	for _, quest in quests:GetChildren() do
		local progress = quest.Progress
		local limited = quest:FindFirstChild("Limited")
		local premium = quest:FindFirstChild("Premium")
		local current = progress.Current
		local max = progress.Max
		local completed = quest:FindFirstChild("Completed")
		
		local frame
		local questinfo
		if limited then
			questinfo = QuestList.Limited[quest.Name]
			frame = templatequest:Clone() -- change this when the limited frame is done
			frame.LayoutOrder = 1
		elseif premium then
			questinfo = QuestList.Premium[quest.Name]
			frame = templatepremiumquest:Clone()
			frame.LayoutOrder = 2
		else
			questinfo = QuestList.Normal[quest.Name]
			frame = templatequest:Clone()
			frame.LayoutOrder = 3
		end
		local bar = frame.ProgressBar.Bar
		local claim = frame.Claim
		frame.Title.Text = questinfo.Title
		frame.Description.Text = questinfo.Description
		if string.find(string.lower(quest.Name), "playtime") then
			frame.ProgressBar.Progress.Text = current.Value.."/"..max.Value.." Minutes"
		else
			frame.ProgressBar.Progress.Text = current.Value.."/"..max.Value
		end
		frame.Reward.Text = questinfo.Rewards.Tokens
		bar.Size = UDim2.new(math.clamp((current.Value * 1) / max.Value, 0, 1), 0, bar.Size.Y.Scale, 0)
		if current.Value >= max.Value then
			if not completed then
				frame.Claim.Background.ImageColor3 = Color3.fromRGB(0,170,0)
				local click; click = frame.Claim.MouseButton1Click:Connect(function()
					_G.Sounds["Click"]:Play()
					click:Disconnect()

					remote:InvokeServer("claim", tostring(quest))
					loadQuests()
				end)
			else
				frame.Claim.Background.ImageColor3 = Color3.fromRGB(68, 68, 68)
				frame.Claim.Title.Text = "CLAIMED"
			end
		else
			frame.Claim.Background.ImageColor3 = Color3.fromRGB(71,71,71)
		end
		frame.Name = tostring(quest)
		frame.Visible = true
		frame.Parent = scrollingframe
	end
end

buyrerolls.MouseButton1Click:Connect(function()
	_G.Sounds["Click"]:Play()
	MarketplaceService:PromptProductPurchase(player, 2694301864)
end)

rerolltokens.Changed:Connect(function()
	updateRerolls()
end)

reroll.MouseButton1Click:Connect(function()
	_G.Sounds["Click"]:Play()
	local result = remote:InvokeServer("reroll")
	if result then
		loadQuests()
	end
end)

close.MouseButton1Click:Connect(function()
	_G.Sounds["Click"]:Play()
	mainframe.Visible = false
end)

loadQuests()

local LastTime = os.time()

while true do
	task.wait(1)
	local hours, minutes, seconds = TimeFunctions.getTimeUntilReset()
	resettext.Text = "New Quests in: "..hours.."h "..minutes.."m "..seconds.."s"
	local newDay = TimeFunctions.daysDifference(LastTime, os.time())
	if newDay < 1 then continue end
	LastTime = os.time()
	remote:InvokeServer("reload")
	loadQuests()
end

local module = {}

return module
