--// Chicchai --
-- by Lolzen & Cargor (EU-Nozdormu) aka xConStruct

local _, ns = ...

local UP, DOWN = 1, -1

local function getMinHeight(self)
	local minHeight = 0
	for i=1, ns.cfg.minimizedLines do
		minHeight = minHeight + math.floor(select(2, self:GetFont())+0.5) + (self:GetSpacing()*0.9)
	end
	return minHeight
end

local function Animate(chatframe, dir, waitTime, finishedFunc)
	if chatframe.Frozen == true then return end
	if chatframe.Animate == dir or chatframe.State == dir and not chatframe.Animate then return end

	if chatframe.Animate == -dir then
		chatframe.TimeRunning = ns.cfg.animTime - chatframe.TimeRunning
	else
		chatframe.TimeRunning = 0
	end
	chatframe.WaitTime = waitTime
	chatframe.Animate = dir
	chatframe.finishedFunc = finishedFunc
end

local function MinimizeAfterWait(chatframe)
	Animate(chatframe, DOWN, ns.cfg.minimizeTime)
end

if ns.cfg.MaximizeCombatLog == true then
	ns.cfg.ChatFrameConfig["ChatFrame2"] = true
	hooksecurefunc("FCF_Tab_OnClick", function(tab)
		local chatframe = _G["ChatFrame2"]
		if chatframe.isDocked then
			chatframe = GENERAL_CHAT_DOCK.primary
		end
		if not chatframe then return end

		if tab:GetName() == "ChatFrame2Tab"then
			Animate(chatframe, UP)
			chatframe.Frozen = true
		elseif chatframe.Frozen then
			chatframe.Frozen = false
			Animate(chatframe, DOWN)
		end
	end)
end

local function updateHeight(chatframe)
	if chatframe.State ~= DOWN then return end
	chatframe:ScrollToBottom()
	chatframe:SetHeight(getMinHeight(chatframe))
end

local function chatEvent(chatframe, ...)
	local chatevent, message, _, _, _, _, _, number = ...
	if event == "CHAT_MSG_CHANNEL" and ns.cfg.channelNumbers and not ns.cfg.channelNumbers[number] then return end
	if chatframe.isDocked then
		if type(ns.cfg.ChatFrameConfig[FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK):GetName()]) == "boolean" then return end
		local checkevent = string.gsub(chatevent, "CHAT_MSG_", "")
		for _, event in pairs(ns.cfg.ChatFrameConfig[FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK):GetName()]) do
			if string.match(event, string.lower(checkevent)) then
				if(ns.cfg.LockInCombat == false or not UnitAffectingCombat("player")) then
					Animate(chatframe, UP, nil, MinimizeAfterWait)
				end
			end
		end
	else
		if type(ns.cfg.ChatFrameConfig[chatframe:GetName()]) == "boolean" then return end
		local checkevent = string.gsub(chatevent, "CHAT_MSG_", "")
		for _, event in pairs(ns.cfg.ChatFrameConfig[chatframe:GetName()]) do
			if string.match(event, string.lower(checkevent)) then
				if(ns.cfg.LockInCombat == false or not UnitAffectingCombat("player")) then
					Animate(chatframe, UP, nil, MinimizeAfterWait)
				end
			end
		end
	end
end

local function Update(chatframe, elapsed)
	if chatframe.isDocked then
		chatframe = GENERAL_CHAT_DOCK.primary
	end
	if ns.cfg.MaximizeOnEnter == true then
		if not ns.cfg.ChatFrameConfig[chatframe:GetName()] then return end
		if MouseIsOver(chatframe) and not chatframe.wasOver then
			chatframe.wasOver = true
			Animate(chatframe, UP, ns.cfg.WaitAfterEnter)
		elseif chatframe.wasOver and not MouseIsOver(chatframe) then
			chatframe.wasOver = nil
			Animate(chatframe, DOWN, ns.cfg.WaitAfterLeave)
		end
	end

	if chatframe.WaitTime then
		chatframe.WaitTime = chatframe.WaitTime - elapsed
		if chatframe.WaitTime > 0 then return end
		chatframe.WaitTime = nil
	end

	chatframe.State = nil

	if chatframe.TimeRunning == nil then return end
	chatframe.TimeRunning = chatframe.TimeRunning + elapsed
	local animPercent = min(chatframe.TimeRunning/ns.cfg.animTime, 1)

	local heightPercent = chatframe.Animate == DOWN and 1-animPercent or animPercent

	local minHeight = getMinHeight(chatframe)
	chatframe:SetHeight(minHeight + (ns.cfg.maxHeight-minHeight) * heightPercent)

	if(animPercent >= 1) then
		chatframe.State = chatframe.Animate
			chatframe.Animate = nil
			chatframe.TimeRunning = nil
		if chatframe.finishedFunc then chatframe:finishedFunc() end
	end
end

for chatname, options in pairs(ns.cfg.ChatFrameConfig) do
	local chatframe = _G[chatname]

	if type(options) == "table" then
		for _, event in pairs(options) do
			if(not event:match("[A-Z]")) then
				event = "CHAT_MSG_"..event:upper()
			end
			chatframe:RegisterEvent(event)
		end
	end

	chatframe:SetScript("OnUpdate", Update)
	chatframe:HookScript("OnEvent", chatEvent)

	updateHeight(chatframe)
end
