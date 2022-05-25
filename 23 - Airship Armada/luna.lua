local autoscroll = require("autoscroll")
local areaNames = require("areanames")

--Change this in your lua file to have automatically appearing messages on section switch for specific sections:
areaNames.sectionNames = {
	[0] = "Airship Armada",
        [1] = "Within the Doomship",
		[2] = "Calm before the Storm",
        [3] = "Room Hall 2",
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


function onLoadSection0()
	autoscroll.scrollRight(1.5)
end

function onTick() 
	if player.deathTimer > 0 then return end 
	if player:mem(0x148, FIELD_WORD) > 0
	and player:mem(0x14C, FIELD_WORD) > 0 then
	player:kill() 
	end
end

