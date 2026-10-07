return {
	export_mod = "ability_timer",
	gamemodes = {
		meatgrinder = true,
		mission = true,
	},
	grid_cols = 0,
	grid_rows = 0,
	label = "Bubble Shield Health",
	localizations = {},
	mod_version = 1,
	name = "at_bubble_health",
	nodes = {
		{
			callbacks = {
				value = {
					color = {
						body = "state.at = state.at or get_mod(\"ability_timer\")\
local s = state.at and state.at.get_ability_state()\
color = s and s.bubble_color",
						kind = "code",
					},
					text = {
						body = "state.at = state.at or get_mod(\"ability_timer\")\
local s = state.at and state.at.get_ability_state()\
text = s and (s.bubble_text or (s.bubble_percent and (s.bubble_percent .. \"%\")) or \"\") or \"\"",
						kind = "code",
					},
					visible = {
						body = "state.at = state.at or get_mod(\"ability_timer\")\
local s = state.at and state.at.get_ability_state()\
visible = s and s.bubble_visible or false",
						kind = "code",
					},
				},
			},
			id = "bubble_health_text_1",
			label = "Bubble Health Text",
			offset = {
				0,
				0,
			},
			style = {
				align = "center",
				color = {
					255,
					255,
					255,
					255,
				},
				font_size = 24,
				font_type = "machine_medium",
				shadow = true,
				size = {
					210,
					30,
				},
			},
			type = "text",
			values = {
				mode = "fixed",
				text = "100%",
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
	summary = "Shield health for the Psyker dome.",
	version = 2,
}
