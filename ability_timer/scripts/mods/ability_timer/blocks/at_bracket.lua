return {
	export_mod = "ability_timer",
	gamemodes = {
		meatgrinder = true,
		mission = true,
	},
	grid_cols = 0,
	grid_rows = 0,
	label = "Ability Timer (Bracket)",
	localizations = {},
	mod_version = 1,
	name = "at_bracket",
	nodes = {
		{
			callbacks = {
				value = {
					visible = {
						body = "state.at = state.at or get_mod(\"ability_timer\")\
local s = state.at and state.at.get_ability_state()\
visible = s and (s.bar_visible or s.timer_visible) or false",
						kind = "code",
					},
				},
			},
			id = "rect_bracket",
			label = "Timer Bracket",
			offset = {
				0,
				0,
			},
			style = {
				color = {
					255,
					169,
					191,
					153,
				},
				size = {
					210,
					15,
				},
			},
			type = "rect",
			values = {
				material = "content/ui/materials/hud/stamina_gauge",
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
	summary = "Bracket frame that fits over the ability timer bar.",
	version = 2,
}
