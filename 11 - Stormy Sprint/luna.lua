local areaNames = require("areanames")

--Change this in your lua file to have automatically appearing messages on section switch for specific sections:
areaNames.sectionNames = {
	[0] = "Tornado Alley",
        [1] = "Tornado!!!",
		[2] = "Barn",
        [3] = "Tatsumaki the Super Lakithunder",
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

function onEvent(eventname)
	if eventname == "boss1" then
		Audio.MusicChange (3, "BossMusic/11C - Mountaintop Tussle.mp3")
	end
end