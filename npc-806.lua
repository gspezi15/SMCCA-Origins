--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local colliders = require("colliders")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 24,
	height = 24,
	frames = 2,
	framestyle = 0,
	framespeed = 6,
	speed = 2,
	
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,

	jumphurt = true,
	spinjumpsafe = true,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,
	destroyblocktable = {90, 4, 188, 60, 293, 667, 457, 666, 686, 668, 526}
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=npcID,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

function sampleNPC.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	v.speedX = sampleNPCSettings.speed * v.direction
	
	if v:mem(0x120, FIELD_BOOL) and not (v.collidesBlockLeft or v.collidesBlockRight) then
		v:mem(0x120, FIELD_BOOL, false)
	end
	
	for _,p in NPC.iterateIntersecting(v.x - 4, v.y - 4, v.x + v.width + 4, v.y + v.height + 4) do
		if p.idx ~= v.idx and p:mem(0x12A, FIELD_WORD) > 0 and p:mem(0x138, FIELD_WORD) == 0 and (not p.isHidden) and (not p.friendly) and p:mem(0x12C, FIELD_WORD) == 0 then
			v.direction = -v.direction
		end
		v:mem(0x24, FIELD_WORD, 0)
		if NPC.HITTABLE_MAP[p.id] and p:mem(0x12A, FIELD_WORD) > 0 and p:mem(0x138, FIELD_WORD) == 0 and (not p.isHidden) and (not p.friendly) and p:mem(0x12C, FIELD_WORD) == 0 then
			p:harm(HARM_TYPE_HELD)
		end
	end
	
	data.destroyCollider = data.destroyCollider or colliders.Box(v.x - 4, v.y + 8, v.width + 8, v.height - 8);
	data.destroyCollider.x = v.x - 2 + 0.5 * (v.width + 2) * v.direction;
	data.destroyCollider.y = v.y + 8;
	local list = colliders.getColliding{
		a = data.destroyCollider,
		b = sampleNPCSettings.destroyblocktable,
		btype = colliders.BLOCK,
		filter = function(other)
			if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
				return false
			end
			return true
		end
		}
	for _,b in ipairs(list) do
		if v.speedX ~= 0 then
			if b.id == 667 or b.id == 666 then
				b:hit()
			else
				b:remove(true)
			end
		end
	end
	if v.collidesBlockLeft or v.collidesBlockRight then
		v:kill(HARM_TYPE_SPINJUMP)
	end
	
	v.speedY = v.speedY + 0.5
	
end

--Gotta return the library table!
return sampleNPC