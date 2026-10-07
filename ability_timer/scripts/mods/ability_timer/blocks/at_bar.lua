return {
	export_mod = "ability_timer",
	gamemodes = {
		meatgrinder = true,
		mission = true,
	},
	grid_cols = 0,
	grid_rows = 0,
	label = "Ability Timer (Bar)",
	localizations = {},
	mod_version = 1,
	name = "at_bar",
	nodes = {
		{
			callbacks = {
				value = {
					color = {
						body = "state.at = state.at or get_mod(\"ability_timer\")\
local s = state.at and state.at.get_ability_state()\
color = s and s.bar_color",
						kind = "code",
					},
					current = {
						body = "state.at = state.at or get_mod(\"ability_timer\")\
local s = state.at and state.at.get_ability_state()\
current = s and s.fraction or 0",
						kind = "code",
					},
					segments = {
						body = "state.at = state.at or get_mod(\"ability_timer\")\
local s = state.at and state.at.get_ability_state()\
segments = s and s.segments or 1",
						kind = "code",
					},
					visible = {
						body = "state.at = state.at or get_mod(\"ability_timer\")\
local s = state.at and state.at.get_ability_state()\
visible = s and (s.bar_visible or s.timer_visible) or false",
						kind = "code",
					},
				},
			},
			id = "progress_bar_1",
			label = "Timer Bar",
			offset = {
				0,
				0,
			},
			style = {
				bg_color = {
					160,
					0,
					0,
					0,
				},
				color = {
					255,
					255,
					255,
					255,
				},
				segment_gap = 3,
				size = {
					210,
					15,
				},
			},
			type = "progress_bar",
			values = {
				current = 1,
				max = 1,
				segments = 1,
			},
		},
	},
	offset = {
		0,
		0,
	},
	requires = {
		"ability_timer",
	},
	summary = "Progress bar for your ability duration and cooldown.",
	version = 2,
}
