local spawnzones = API.load("spawnzones")

local areaNames = require("areanames")

--Change this in your lua file to have automatically appearing messages on section switch for specific sections:
areaNames.sectionNames = {
	[0] = "Digital Blockyard",
        [1] = "Circuit Central",
		[2] = "Digital Metropolis",
        [3] = "City Hall",
        [4] = "Caldera Terminal",
        [5] = "House 1",
        [6] = "House 2",
        [7] = "House 3",
        [8] = "Lightcycle Entrance",
        [9] = "The Caldera",
        [10] = "",
        [11] = "",
        [12] = "",
        [13] = "",
        [14] = "",
        [15] = "",
        [16] = "",
        [17] = "",
        [18] = "",
        [19] = "",
        [20] = ""
}

function onEvent(eventname)
	if eventname == "Musicchange" then
		Audio.MusicChange (0, "13 Serious Trouble!.ogg")
	end
end