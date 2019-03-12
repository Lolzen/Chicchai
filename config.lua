--// Chicchai config // --

local _, ns = ...

ns.cfg = {
	["maxHeight"] = 120,			-- How high the chat frames are when maximized
	["animTime"] = 0.3,				-- How lang the animation takes (in seconds)
	["minimizeTime"] = 10,			-- Minimize after X seconds
	["minimizedLines"] = 1,			-- Number of chat messages to show in minimized state

	["MaximizeOnEnter"]	= true,		-- Maximize when entering chat frame, minimize when leaving
	["WaitAfterEnter"] = 0,			-- Wait X seconds after entering before maximizing
	["WaitAfterLeave"] = 0,			-- Wait X seconds after leaving before minimizing

	["LockInCombat"] = false,		-- Do not maximize in combat
	["MaximizeCombatLog"] = true,	-- When the combat log is selected, it will be maximized
}

-- Modify this to maximize only on special channels
-- comment/remove it to react on all channels
-- you still need the "channel"-event on your chat frame!
ns.cfg.channelNumbers = {
	[1] = true,
	[2] = true,
	[3]  = true,
}

ns.cfg.ChatFrameConfig = {	-- Events which maximize the chat for the different windows
	["ChatFrame1"] = {
		"say", "emote", "text_emote",
		"party", "party_leader",
		"whisper",
		"guild", "officer",
		"raid", "raid_leader", "raid_warning",
		"bn_whisper",
		"communities_channel",
	},
	["ChatFrame3"] = true, -- "true" just makes this frame available for minimizing and registers it with Chicchai
}

--[[	REFERENCE EVENT LIST
		An up to date list with the available events is everything starting with "CHAT_MSG" in this link:
		https://wow.gamepedia.com/Category:API_events/Communication
		
		EXAMPLE:
		We are registering ChatFrame1 in ns.cfg.ChatFrameConfig with CHAT_MSG_SAY by using "say".
		If we want to include a guild achivement event we then write "guild_achievement" as we see 
		"CHAT_MSG_GUILD_ACHIEVEMENT" in the link.
]]
