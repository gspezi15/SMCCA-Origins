local smwfuzzy = {}

local npcManager = require("npcManager")

local npcID = NPC_ID

-- settings
local config = {
	id = npcID, 
	width = 32, 
    height = 32,
    gfxwidth = 32,
    gfxheight = 32,
    frames = 1,
    framestyle = 1,
    nogravity = true,
	jumphurt = false,
	spinjumpsafe = false,
    noblockcollision = true,
}
npcManager.setNpcSettings(config)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=npcID,
		--[HARM_TYPE_FROMBELOW]=npcID,
		--[HARM_TYPE_NPC]=npcID,
		--[HARM_TYPE_PROJECTILE_USED]=npcID,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=npcID,
		--[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);










function smwfuzzy.onInitAPI()
	npcManager.registerEvent(npcID, smwfuzzy, "onTickNPC")
	npcManager.registerEvent(npcID, smwfuzzy, "onTickEndNPC")
	--npcManager.registerEvent(npcID, Birdo_LOL, "onDrawNPC")
	--registerEvent(Birdo_LOL, "onNPCKill")
end


function onTickNPC(v)
    if v.x > player.x then
        v.animationFrame = 1
    else
        v.animationFrame = 2
    end
    
end
return smwfuzzy