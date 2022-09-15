local areaNames = require("areanames")

--Change this in your lua file to have automatically appearing messages on section switch for specific sections:
areaNames.sectionNames = {
	[0] = "Mountain Mania",
        [1] = "Mountain Tunnel",
		[2] = "Mountain Tunnel",
        [3] = "Mountain Blaze",
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
	if eventname == "Musicchange" then
		Audio.MusicChange (0, "13 Serious Trouble!.ogg")
	end
end