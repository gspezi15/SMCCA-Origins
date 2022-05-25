--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	gfxheight = 12,
	gfxwidth = 12,
	width = 12,
	height = 12,
	frames = 1,
	framestyle = 0,
	framespeed = 8, 
	speed = 1,
	
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,
	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,
	ignorethrownnpcs = true,

	grabside=false,
	grabtop=false,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Gotta return the library table!
return sampleNPC