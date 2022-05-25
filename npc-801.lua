--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	gfxheight = 16,
	gfxwidth = 16,
	width = 16,
	height = 16,
	frames = 2,
	framestyle = 0,
	framespeed = 4, 
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