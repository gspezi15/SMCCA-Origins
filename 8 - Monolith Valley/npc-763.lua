local npcManager = require("npcManager")
local AI = require("AI/armad")

local sampleNPC = {}
local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 34,
	gfxwidth = 48,

	width = 32,
	height = 32,

	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 7,
	framestyle = 1,
	framespeed = 8,

	speed = 1,
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,

	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	cliffturn = true,

	shellID = npcID + 1,
	curlingFrames = 3,
	detectArea = {x = 0, y = -16, w = 256, h = 32},
	deathEffect = npcID,
}

npcManager.setNpcSettings(sampleNPCSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP] = nil,
		[HARM_TYPE_FROMBELOW] = nil,
		[HARM_TYPE_NPC] = nil,
		[HARM_TYPE_PROJECTILE_USED] = nil,
		[HARM_TYPE_LAVA] = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD] = nil,
		[HARM_TYPE_TAIL] = nil,
		[HARM_TYPE_SPINJUMP] = 10,
		[HARM_TYPE_OFFSCREEN] = 10,
		[HARM_TYPE_SWORD] = nil,
	}
);

AI.registerNPC(npcID, NPC.config[npcID].shellID)

return sampleNPC