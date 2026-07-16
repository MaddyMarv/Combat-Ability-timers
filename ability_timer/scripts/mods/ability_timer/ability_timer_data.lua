local mod = get_mod("ability_timer")

local widgets = {
	{
		setting_id = "display_settings",
		type = "group",
		tab = "Display",
		sub_widgets = {
			{
				setting_id = "display_mode",
				type = "dropdown",
				default_value = "both",
				localize = true,
				options = {
					{ text = "display_mode_both", value = "both" },
					{ text = "display_mode_progress_only", value = "progress_only" },
					{ text = "display_mode_timer_only", value = "timer_only" },
				},
			},
			{
				setting_id = "use_progress_color",
				display_name = mod:localize("use_progress_color"),
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "show_bubble_health",
				display_name = mod:localize("show_bubble_health"),
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "show_bracket",
				display_name = mod:localize("show_bracket"),
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "track_cooldown",
				display_name = mod:localize("track_cooldown"),
				type = "checkbox",
				default_value = false,
			},
			{
				setting_id = "cooldown_display_mode",
				type = "dropdown",
				default_value = "smooth",
				localize = true,
				options = {
					{ text = "cooldown_mode_smooth", value = "smooth" },
					{ text = "cooldown_mode_full", value = "full" },
				},
			},
		},
	},
	{
		setting_id = "gauge_settings",
		type = "group",
		tab = "Gauge",
		sub_widgets = {
			{
				setting_id = "gauge_length",
				display_name = mod:localize("gauge_length"),
				type = "numeric",
				default_value = 210,
				range = { 100, 450 },
				decimals_number = 0,
			},
			{
				setting_id = "gauge_thick",
				display_name = mod:localize("gauge_thick"),
				type = "numeric",
				default_value = 15,
				range = { 5, 50 },
				decimals_number = 0,
			},
			{
				setting_id = "gauge_alpha",
				display_name = mod:localize("gauge_alpha"),
				type = "numeric",
				default_value = 1.0,
				range = { 0, 1 },
				decimals_number = 2,
			},
			{
				setting_id = "comp_orientation",
				display_name = mod:localize("comp_orientation"),
				type = "dropdown",
				default_value = 0,
				options = {
					{ text = "orientation_horizontal", value = 0 },
					{ text = "orientation_vertical", value = 1 },
				},
			},
			{
				setting_id = "bar_direction",
				display_name = mod:localize("bar_direction"),
				type = "dropdown",
				default_value = 1,
				options = {
					{ text = "bar_dir_start", value = 1 },
					{ text = "bar_dir_end", value = 2 },
					{ text = "bar_dir_center", value = 3 },
				},
			},
		},
	},
	{
		setting_id = "position_settings",
		type = "group",
		tab = "Position",
		sub_widgets = {
			{
				setting_id = "position_x",
				display_name = mod:localize("position_x"),
				type = "numeric",
				default_value = 0,
				range = { -1920, 1920 },
				decimals_number = 0,
			},
			{
				setting_id = "position_y",
				display_name = mod:localize("position_y"),
				type = "numeric",
				default_value = 0,
				range = { -1080, 1080 },
				decimals_number = 0,
			},
		},
	},
	{
		setting_id = "ability_filters",
		type = "group",
		tab = "Filters",
		sub_widgets = {
			{
				setting_id = "ability_filters_veteran",
				display_name = mod:localize("ability_filters_veteran"),
				type = "group",
				sub_widgets = {
					{ setting_id = "veteran_ability_stance", display_name = mod:localize("veteran_ability_stance"), type = "checkbox", default_value = true },
					{ setting_id = "veteran_ability_stealth", display_name = mod:localize("veteran_ability_stealth"), type = "checkbox", default_value = true },
					{ setting_id = "veteran_ability_shout", display_name = mod:localize("veteran_ability_shout"), type = "checkbox", default_value = true },
				},
			},
			{
				setting_id = "ability_filters_zealot",
				display_name = mod:localize("ability_filters_zealot"),
				type = "group",
				sub_widgets = {
					{ setting_id = "zealot_ability_dash", display_name = mod:localize("zealot_ability_dash"), type = "checkbox", default_value = true },
					{ setting_id = "zealot_ability_invisibility", display_name = mod:localize("zealot_ability_invisibility"), type = "checkbox", default_value = true },
					{ setting_id = "zealot_ability_relic", display_name = mod:localize("zealot_ability_relic"), type = "checkbox", default_value = true },
				},
			},
			{
				setting_id = "ability_filters_psyker",
				display_name = mod:localize("ability_filters_psyker"),
				type = "group",
				sub_widgets = {
					{ setting_id = "psyker_ability_shout", display_name = mod:localize("psyker_ability_shout"), type = "checkbox", default_value = true },
					{ setting_id = "psyker_ability_overcharge", display_name = mod:localize("psyker_ability_overcharge"), type = "checkbox", default_value = true },
					{ setting_id = "psyker_ability_shield", display_name = mod:localize("psyker_ability_shield"), type = "checkbox", default_value = true },
				},
			},
			{
				setting_id = "ability_filters_ogryn",
				display_name = mod:localize("ability_filters_ogryn"),
				type = "group",
				sub_widgets = {
					{ setting_id = "ogryn_ability_charge", display_name = mod:localize("ogryn_ability_charge"), type = "checkbox", default_value = true },
					{ setting_id = "ogryn_ability_ranged_stance", display_name = mod:localize("ogryn_ability_ranged_stance"), type = "checkbox", default_value = true },
					{ setting_id = "ogryn_ability_taunt", display_name = mod:localize("ogryn_ability_taunt"), type = "checkbox", default_value = true },
				},
			},
			{
				setting_id = "ability_filters_arbites",
				display_name = mod:localize("ability_filters_arbites"),
				type = "group",
				sub_widgets = {
					{ setting_id = "arbites_ability_charge", display_name = mod:localize("arbites_ability_charge"), type = "checkbox", default_value = true },
					{ setting_id = "arbites_ability_stance", display_name = mod:localize("arbites_ability_stance"), type = "checkbox", default_value = true },
					{ setting_id = "arbites_ability_drone", display_name = mod:localize("arbites_ability_drone"), type = "checkbox", default_value = true },
				},
			},
			{
				setting_id = "ability_filters_broker",
				display_name = mod:localize("ability_filters_broker"),
				type = "group",
				sub_widgets = {
					{ setting_id = "broker_ability_focus", display_name = mod:localize("broker_ability_focus"), type = "checkbox", default_value = true },
					{ setting_id = "broker_ability_punk_rage", display_name = mod:localize("broker_ability_punk_rage"), type = "checkbox", default_value = true },
					{ setting_id = "broker_ability_stimm_field", display_name = mod:localize("broker_ability_stimm_field"), type = "checkbox", default_value = true },
				},
			},
			{
				setting_id = "ability_filters_cryptic",
				display_name = mod:localize("ability_filters_cryptic"),
				type = "group",
				sub_widgets = {
					{ setting_id = "cryptic_ability_discharge", display_name = mod:localize("cryptic_ability_discharge"), type = "checkbox", default_value = true },
					{ setting_id = "cryptic_ability_precision_stance", display_name = mod:localize("cryptic_ability_precision_stance"), type = "checkbox", default_value = true },
					{ setting_id = "cryptic_ability_chordclaw", display_name = mod:localize("cryptic_ability_chordclaw"), type = "checkbox", default_value = true },
				},
			},
		},
	},
}

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = widgets,
	},
}
