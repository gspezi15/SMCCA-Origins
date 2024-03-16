local lineguide = require("lineguide")
local npcManager = require("npcManager")

local smwfuzzy = {}
local npcID = NPC_ID

lineguide.registerNpcs(npcID)

-- settings
local smwFuzzySettings = {
	id = npcID, 
	width = 32, 
	height = 32, 
	frames = 2, 
	noiceball = true, 
	noblockcollision = false,
	nowaterphysics = true,
	jumphurt = true,
	spinjumpSafe = true
}

--Applies NPC settings
npcManager.setNpcSettings(smwFuzzySettings)

lineguide.properties[npcID] = {lineSpeed = 3}

--Register events
function smwfuzzy.onInitAPI()
	npcManager.registerEvent(npcID, smwfuzzy, "onTickNPC")
end

function smwfuzzy.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	--Execute main AI. This template just jumps when it touches the ground.
	if v.collidesBlockBottom then
		v.speedX = 3 * v.direction
	end
end

return smwfuzzy