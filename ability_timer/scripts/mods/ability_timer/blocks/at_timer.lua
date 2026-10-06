return {
	export_mod = "ability_timer",
	gamemodes = {
		meatgrinder = true,
		mission = true,
	},
	grid_cols = 0,
	grid_rows = 0,
	label = "Ability Timer (Text)",
	localizations = {},
	mod_version = 1,
	name = "at_timer",
	nodes = {
		{
			callbacks = {
				value = {
					color = {
						body = "state.at = state.at or get_mod(\"ability_timer\")\
local s = state.at and state.at.get_ability_state()\
color = s and s.text_color",
						kind = "code",
					},
					text = {
						body = "state.at = state.at or get_mod(\"ability_timer\")\
local s = state.at and state.at.get_ability_state()\
text = s and s.timer_text or \"\"",
						kind = "code",
					},
					visible = {
						body = "state.at = state.at or get_mod(\"ability_timer\")\
local s = state.at and state.at.get_ability_state()\
visible = s and s.timer_visible or false",
						kind = "code",
					},
				},
			},
			id = "timer_text_1",
			label = "Timer Text",
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
				font_size = 28,
				font_type = "machine_medium",
				shadow = true,
				size = {
					110,
					34,
				},
			},
			type = "text",
			values = {
				mode = "fixed",
				text = "10.0",
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
	summary = "Countdown text showing remaining active duration or cooldown of your combat ability with dynamic progress colors. Requires Ability Timer.",
	version = 2,
}
