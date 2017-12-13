--// Chicchai config // --

local _, ns = ...

ns.cfg = {
	["maxHeight"] = 120,			-- How high the chat frames are when maximized
	["animTime"] = 0.3,				-- How lang the animation takes (in seconds)
	["minimizeTime"] = 10,			-- Minimize after X seconds
	["minimizedLines"] = 3,			-- Number of chat messages to show in minimized state

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
		"party", "party_leader", "party_guide",
		"whisper",
		"guild", "officer",
		"battleground", "battleground_leader",
		"raid", "raid_leader", "raid_warning",
	
		"bn_whisper",
		"bn_conversation",
		"bn_broadcast",
	},
	["ChatFrame3"] = {"whisper", "bn_whisper",}
}

--[[
	REFERENCE LIST
	These are the available chat events for ChatFrameConfig
		say, yell, emote, text_emote,
		party, party_leader, party_guide,
		whisper, whisper_inform, afk, dnd, ignored,
		guild, officer,
		channel, channel_join, channel_leave, channel_list, channel_notice, channel_notice_user,
		battleground, battleground_leader,
		raid, raid_leader, raid_warning,

		bn_whisper, bn_whisper_inform,
		bn_conversation, bn_conversation_notice, bn_conversation_list,
		bn_alert,
		bn_broadcast, bn_broadcast_inform,
		bn_inline_toast_alert, bn_inline_toast_broadcast, bn_inline_toast_broadcast_inform, bn_inline_toast_conversation,

		system, achievement, guild_achievement,
		bg_system_neutral, bg_system_alliance, bg_system_horde,
		monster_say, monster_party, monster_yell, monster_whisper, monster_emote,
		raid_boss_whisper, raid_boss_emote,
		skill, loot, money, opening, tradeskills, pet_info, combat_misc_info, combat_xp_gain, combat_honor_gain, combat_faction_change,
]]
