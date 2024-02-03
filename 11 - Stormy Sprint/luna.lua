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

local lightningIMG = Graphics.loadImage("lightning.png")
local lightning = {
    image = Graphics.loadImage("lightning.png"),
    opacity = {
        max = 0.6,
        min = 0.02,
        factor = 0.99,
        diff = 0.01
    },
    timer = 300
}
local timer = RNG.randomInt(lightning.timer * 0.25, lightning.timer * 0.625)
local opacity = lightning.opacity.max


function onTick()
	timer = timer + 1
	if timer >= lightning.timer then 
		if opacity >= lightning.opacity.min then
			opacity = opacity * lightning.opacity.factor - lightning.opacity.diff
			--makes the lightning fade out over time
		end
		if timer == lightning.timer + 2 then
			if (player.sectionObj.backgroundID == 20 or player.sectionObj.backgroundID == 32) then
				SFX.play("thunderstorm.wav", 3) 
				--plays the 43rd Sound Effect (fireworks/explosion) at a high volume
			else
				SFX.play("thunderstorm.wav", 0.15) 
				--plays the same SFX but at a low volume (Goal is to keep the lightning sound effect in underwater sections, but to a gentler degree)
			end
		end
	end
	if opacity <= lightning.opacity.min then --triggers when the lightning fades out (resets the settings)
		timer = RNG.randomInt(0, lightning.timer * 0.625)
		opacity = lightning.opacity.max
	end
end

function onDraw() --onDraw runs even when the game is paused, onTick doesn't
	if (player.sectionObj.backgroundID == 20 or player.sectionObj.backgroundID == 32) and timer >= lightning.timer then
		Graphics.drawImageWP(lightning.image, 0, 0, opacity, -99) --this makes sure the lightning is visible even when the game is paused
	end
end

function onEvent(eventname)
	if eventname == "boss1" then
		Audio.MusicChange (3, "BossMusic/11C - Mountaintop Tussle.mp3")
	end
end