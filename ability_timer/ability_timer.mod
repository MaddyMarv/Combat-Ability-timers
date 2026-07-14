return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`ability_timer` encountered an error loading the Darktide Mod Framework.")

		new_mod("ability_timer", {
			mod_script = "ability_timer/scripts/mods/ability_timer/ability_timer",
			mod_data = "ability_timer/scripts/mods/ability_timer/ability_timer_data",
			mod_localization = "ability_timer/scripts/mods/ability_timer/ability_timer_localization",
		})
	end,
	packages = {},
}


