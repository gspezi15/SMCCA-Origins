local areaNames = require("areanames")

--Change this in your lua file to have automatically appearing messages on section switch for specific sections:
areaNames.sectionNames = {
	[0] = "Cascades City",
        [1] = "Monroe Caverns",
		[2] = "Monroe Hightops",
        [3] = "",
        [4] = "",
        [5] = "",
        [6] = "",
        [7] = "",
        [8] = "",
        [9] = "",
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

function onEvent(eventName)
 if eventName == "bossmusic" then
		Audio.MusicChange(0, "BossMusic/1B - Shadowrun Gunfight.spc")
	end
end 

		