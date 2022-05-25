local areaNames = require("areanames")

--Change this in your lua file to have automatically appearing messages on section switch for specific sections:
areaNames.sectionNames = {
	[0] = "FMDT Everglades",
        [1] = "Fort Muda",
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

function onNPCKill(eventObj, killedNPC, killReason)
	if killedNPC.id == 400 then
		for i = -1,1 do
			if i ~= 0 then
				local debris1 = Animation.spawn(761,killedNPC.x,killedNPC.y)
				debris1.speedX = 2*i
				debris1.speedY = -4
			end
		end
		Animation.spawn(760,killedNPC.x,killedNPC.y)
		Animation.spawn(763,killedNPC.x,killedNPC.y)
		SFX.play("Save_barrel.wav")
	end
end