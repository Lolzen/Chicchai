--// Chicchai --
-- by Lolzen & Cargor (EU-Nozdormu) aka xConStruct

local _, ns = ...
local cfg = ns.cfg

local MIN, MAX = "min", "max"
local HOVER_POLL_INTERVAL = 0.1

local abs, max, min, ceil = math.abs, math.max, math.min, math.ceil
local GetTime = GetTime
local issecretvalue = issecretvalue or function() return false end

-- All state lives in these tables instead of on the Blizzard chat frames,
-- writing keys onto the chat frames would taint them
local states = {}			-- [targetFrame] = state of a frame whose height we control
local configured = {}		-- [chatFrame] = true for every chat frame from ChatFrameConfig
local eventFrames = {}		-- [EVENT] = { chatFrame, ... } which should maximize on this event
local hookedContent = {}	-- [chatFrame] = true once we listen for display refreshes on it
local paused = false		-- Edit Mode is open

local driver = CreateFrame("Frame")
driver:Hide()

local function GetDock()
	local dock = GENERAL_CHAT_DOCK
	if dock and dock.primary then return dock end
end

local function GetSelectedDockWindow(dock)
	if FCFDock_GetSelectedWindow then
		return FCFDock_GetSelectedWindow(dock)
	end
	return dock.selected
end

-- The frame whose height actually has to be changed, docked frames
-- are anchored to the primary frame of the dock
local function GetTarget(chatframe)
	local dock = GetDock()
	if dock and chatframe.isDocked then
		return dock.primary
	end
	return chatframe
end

-- The frame whose messages are currently shown within the target
local function GetContent(target)
	local dock = GetDock()
	if dock and target == dock.primary then
		local selected = GetSelectedDockWindow(dock)
		if selected and selected.isDocked then
			return selected
		end
	end
	return target
end

--[[ Minimized height
	Every message of a ScrollingMessageFrame is a single FontString which is word wrapped
	to the frame width and messages are stacked with the font spacing in between. We rebuild
	that with an own FontString to get the real height of the last X messages, no matter how
	many lines each of them spans.
]]
local measure = UIParent:CreateFontString(nil, "BACKGROUND")
measure:SetPoint("TOPLEFT", UIParent, "BOTTOMRIGHT", 100, -100)	-- off screen
measure:SetAlpha(0)

local function GetMinHeight(target)
	local content = GetContent(target)
	local fontObject = content.GetFontObject and content:GetFontObject()
	if not fontObject then
		return select(2, content:GetFont()) or 14
	end

	measure:SetFontObject(fontObject)
	measure:SetNonSpaceWrap(true)
	local lineHeight = measure:GetLineHeight()
	local spacing = measure:GetSpacing() or 0
	local width = content:GetWidth()
	local canMeasure = width and width > 0
	if canMeasure then
		measure:SetWidth(width)
	end

	local numMessages = content.GetNumMessages and content:GetNumMessages() or 0
	local offset = content.GetScrollOffset and content:GetScrollOffset() or 0
	-- GetMessageInfo(numMessages) is the newest message
	local newest = numMessages - offset

	local height, count = 0, 0
	for index = newest, max(newest - cfg.minimizedLines + 1, 1), -1 do
		local message = content:GetMessageInfo(index)
		local messageHeight = lineHeight
		-- we can't measure secret messages (Midnight restrictions), treat them as one line
		if canMeasure and type(message) == "string" and not issecretvalue(message) then
			measure:SetText(message)
			local h = measure:GetStringHeight()
			if h and not issecretvalue(h) and h > 0 then
				messageHeight = h
			end
		end
		height = height + messageHeight
		count = count + 1
	end
	measure:SetText("")

	if count == 0 then
		return ceil(lineHeight)
	end
	return ceil(height + spacing * (count - 1))
end

local function GetMaxHeight(target)
	return cfg.maxHeight
end

local function UpdateMinHeight(target, st)
	st.minHeight = GetMinHeight(target)
	return st.minHeight
end

-- Animation
local function AnimateTo(target, st, height)
	local current = target:GetHeight()
	if abs(current - height) < 0.5 then
		st.anim = nil
		return
	end
	local range = abs(GetMaxHeight(target) - (st.minHeight or UpdateMinHeight(target, st)))
	local duration = range > 0 and cfg.animTime * min(abs(height - current) / range, 1) or 0
	st.anim = { from = current, to = height, elapsed = 0, duration = duration }
	driver:Show()
end

local function CancelTimer(st)
	if st.timer then
		st.timer:Cancel()
		st.timer = nil
	end
end

local function SetMode(target, mode, delay)
	local st = states[target]
	if not st or paused then return end
	CancelTimer(st)

	if delay and delay > 0 then
		st.timer = C_Timer.NewTimer(delay, function()
			st.timer = nil
			SetMode(target, mode)
		end)
		return
	end

	if mode == MIN and (st.frozen or st.hovered) then return end
	st.mode = mode
	st.dirty = nil
	AnimateTo(target, st, mode == MAX and GetMaxHeight(target) or UpdateMinHeight(target, st))
end

local function Maximize(target, delay) SetMode(target, MAX, delay) end
local function Minimize(target, delay) SetMode(target, MIN, delay) end

driver:SetScript("OnUpdate", function(self, elapsed)
	local busy = false
	for target, st in pairs(states) do
		local anim = st.anim
		if anim then
			anim.elapsed = anim.elapsed + elapsed
			local progress = anim.duration > 0 and min(anim.elapsed / anim.duration, 1) or 1
			target:SetHeight(anim.from + (anim.to - anim.from) * progress)
			if progress >= 1 then
				st.anim = nil
			else
				busy = true
			end
		end
		-- messages changed while minimized, readjust the height
		if not st.anim and st.dirty then
			st.dirty = nil
			if st.mode == MIN and not paused then
				AnimateTo(target, st, UpdateMinHeight(target, st))
				busy = busy or st.anim ~= nil
			end
		end
	end
	if not busy then
		self:Hide()
	end
end)

-- Called by the ScrollingMessageFrame after new messages were added, scrolling etc.
local function OnDisplayRefreshed(content)
	local st = states[GetTarget(content)]
	if st and st.mode == MIN and GetContent(GetTarget(content)) == content then
		st.dirty = true
		driver:Show()
	end
end

local function WatchContent(content)
	if hookedContent[content] or not content.AddOnDisplayRefreshedCallback then return end
	hookedContent[content] = true
	content:AddOnDisplayRefreshedCallback(OnDisplayRefreshed)
end

-- Combat log handling
local function IsFrozen(target)
	if not cfg.MaximizeCombatLog then return false end
	local combatlog = _G.COMBATLOG or _G.ChatFrame2
	if not combatlog then return false end
	local dock = GetDock()
	if dock and combatlog.isDocked then
		return target == dock.primary and GetSelectedDockWindow(dock) == combatlog
	end
	return target == combatlog and combatlog:IsShown()
end

local function UpdateFrozen()
	for target, st in pairs(states) do
		local frozen = IsFrozen(target)
		if frozen ~= st.frozen then
			st.frozen = frozen
			if frozen then
				Maximize(target)
			else
				Minimize(target)
			end
		end
	end
end

-- (Re)build the list of frames whose height we control, docking changes it
local function UpdateTargets()
	local wanted = {}
	for chatframe in pairs(configured) do
		wanted[GetTarget(chatframe)] = true
	end

	for target, st in pairs(states) do
		if not wanted[target] then
			CancelTimer(st)
			states[target] = nil
			-- give frames we no longer handle their full height back
			if not target.isDocked then
				target:SetHeight(GetMaxHeight(target))
			end
		end
	end

	for target in pairs(wanted) do
		if not states[target] then
			states[target] = { mode = MIN }
			WatchContent(target)
			if not paused then
				target:SetHeight(UpdateMinHeight(target, states[target]))
			end
		end
		WatchContent(GetContent(target))
		states[target].dirty = true
	end

	UpdateFrozen()
	driver:Show()
end

-- Chat events
local eventHandler = CreateFrame("Frame")
eventHandler:SetScript("OnEvent", function(self, event, ...)
	local frames = eventFrames[event]
	if not frames then return end

	if event == "CHAT_MSG_CHANNEL" and cfg.channelNumbers then
		local channelIndex = select(8, ...)
		if issecretvalue(channelIndex) or not cfg.channelNumbers[channelIndex] then return end
	end
	if cfg.LockInCombat and UnitAffectingCombat("player") then return end

	local dock = GetDock()
	for i = 1, #frames do
		local chatframe = frames[i]
		-- a docked frame only counts when its tab is the one shown
		if not chatframe.isDocked or not dock or GetSelectedDockWindow(dock) == chatframe then
			local target = GetTarget(chatframe)
			local st = states[target]
			if st and target:IsVisible() and not st.hovered and not st.frozen then
				Maximize(target)
				Minimize(target, cfg.animTime + cfg.minimizeTime)
			end
		end
	end
end)

local function IsEventValid(event)
	if C_EventUtils and C_EventUtils.IsEventValid then
		return C_EventUtils.IsEventValid(event)
	end
	return true
end

-- Mouseover handling
local function PollHover()
	for target, st in pairs(states) do
		local over = target:IsVisible() and target:IsMouseOver() or false
		if over ~= (st.hovered or false) then
			st.hovered = over
			if over then
				Maximize(target, cfg.WaitAfterEnter)
			else
				Minimize(target, cfg.WaitAfterLeave)
			end
		end
	end
end

-- Pause while Edit Mode is open, the user wants to see and resize the real frame
local function SetPaused(pause)
	paused = pause
	for target, st in pairs(states) do
		CancelTimer(st)
		st.anim = nil
		if not paused then
			SetMode(target, (st.frozen or st.hovered) and MAX or MIN)
		end
	end
end

-- Snap every frame to its current state without animation
local function ApplyHeights()
	if paused then return end
	for target, st in pairs(states) do
		CancelTimer(st)
		st.anim = nil
		target:SetHeight(st.mode == MAX and GetMaxHeight(target) or UpdateMinHeight(target, st))
	end
end

local function Initialize()
	for chatname, options in pairs(cfg.ChatFrameConfig) do
		local chatframe = _G[chatname]
		if not chatframe then
			print("|cffffcc00Chicchai:|r "..chatname.." does not exist and is ignored.")
		else
			configured[chatframe] = true
			if type(options) == "table" then
				for _, event in ipairs(options) do
					if not event:match("[A-Z]") then
						event = "CHAT_MSG_"..event:upper()
					end
					if IsEventValid(event) then
						eventFrames[event] = eventFrames[event] or {}
						tinsert(eventFrames[event], chatframe)
						eventHandler:RegisterEvent(event)
					else
						print("|cffffcc00Chicchai:|r unknown event "..event.." for "..chatname..".")
					end
				end
			end
		end
	end

	if cfg.MaximizeCombatLog then
		local combatlog = _G.COMBATLOG or _G.ChatFrame2
		if combatlog then
			configured[combatlog] = true
		end
	end

	-- docking, undocking and switching tabs change which frame we have to resize
	for _, func in ipairs({"FCF_DockFrame", "FCF_UnDockFrame", "FCFDock_SelectWindow"}) do
		if _G[func] then
			hooksecurefunc(func, UpdateTargets)
		end
	end

	if EventRegistry then
		EventRegistry:RegisterCallback("EditMode.Enter", function() SetPaused(true) end, ns)
		EventRegistry:RegisterCallback("EditMode.Exit", function() SetPaused(false) end, ns)
	end

	UpdateTargets()

	if cfg.MaximizeOnEnter then
		C_Timer.NewTicker(HOVER_POLL_INTERVAL, PollHover)
	end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
if IsEventValid("EDIT_MODE_LAYOUTS_UPDATED") then
	loader:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
end
loader:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		Initialize()
		self:UnregisterEvent("PLAYER_LOGIN")
	else
		-- chat windows and Edit Mode restore their saved sizes while loading,
		-- apply our heights again afterwards
		C_Timer.After(0, ApplyHeights)
	end
end)
