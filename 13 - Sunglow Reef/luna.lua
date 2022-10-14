local autoscroll = require("autoscroll")

function onLoadSection0()
	autoscroll.scrollRight(1)
end

function onTick() 
	if player.deathTimer > 0 then return end 
	if player:mem(0x148, FIELD_WORD) > 0
	and player:mem(0x14C, FIELD_WORD) > 0 then
	player:kill() 
	end
end

function onEvent(eventName)
 if eventName == "battle" then
		Audio.MusicChange(0, "BossMusic/13B Marine Pop.spc")
	end
end 

		