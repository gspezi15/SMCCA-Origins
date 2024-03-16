--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local fuzzbush = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local fuzzbushSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 96,
	gfxwidth = 64,
	width = 60,
	height = 72,
	frames = 7,
	framestyle = 1,
	framespeed = 8,
	speed = 1,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
}

--Applies NPC settings
npcManager.setNpcSettings(fuzzbushSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
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
		[HARM_TYPE_JUMP]=npcID,
		[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

local sfx = Misc.resolveSoundFile("sound/extended/leaf")

local STATE_IDLE = 0
local STATE_PREPARE = 1
local STATE_ATTACK = 2
local STATE_HARM = 3

--Handle animation frame
local function getAnimationFrame(v)
	local data = v.data
		if v.ai2 == 0 then
			data.animTimer = data.animTimer + 1
		else
			data.animTimer = data.animTimer - 1
		end
		if data.animTimer <= 0 then
			v.ai2 = 0
		elseif data.animTimer >= 23 then
			v.ai2 = 1
		end
	if data.state == STATE_IDLE then
		v.animationFrame = math.floor(data.animTimer / 8) % 3
	elseif data.state == STATE_ATTACK then
		v.animationFrame = math.floor(data.animTimer / 8) % 3 + 3
	elseif data.state == STATE_PREPARE then
		v.animationFrame = 2
	else
		if v.ai3 % 7 < 4 then 
			v.animationFrame = 6
		else
			v.animationFrame = -1
		end
	end
	if v.animationFrame >= 0 then
		v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})
	end
end

--Register events
function fuzzbush.onInitAPI()
	npcManager.registerEvent(npcID, fuzzbush, "onTickEndNPC")
	registerEvent(fuzzbush, "onNPCHarm")
end

function fuzzbush.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.state = STATE_IDLE
		data.timer = 0
		data.progressTimer = 0
		data.animTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_IDLE
		data.timer = data.timer or 0
		data.progressTimer = data.progressTimer or 0
		data.animTimer = data.animTimer or 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.timer = 0
		data.state = STATE_IDLE
	end
	getAnimationFrame(v)
	data.progressTimer = data.progressTimer + 1
	
	if settings.delay == nil or settings.move == nil then
		settings.delay = 96
		settings.move = true
	end
	
	--If health is lower or equal to 0 then kill
	if not data.health then
		data.health = 5
	end
	if data.health <= 0 then v:kill() end
	
	--Walk around
	if data.state == STATE_IDLE then
		if settings.move then
			data.timer = data.timer + 1
			v.speedX = 1.5 * v.direction
			if data.timer >= 128 then
				v.direction = -v.direction
				data.timer = 0
			end
		end
		if data.progressTimer >= settings.delay then
			data.state = STATE_PREPARE
			data.progressTimer = 0
		end
	--Prepare and attack
	elseif data.state == STATE_PREPARE then
		v.speedX = 0
		if data.progressTimer >= 16 then
			data.state = STATE_ATTACK
			data.progressTimer = 0
			data.animTimer = 0
			v.ai2 = 0
		end
	elseif data.state == STATE_ATTACK then
		if data.progressTimer == 16 then
			if v.direction == DIR_LEFT then
				local n = NPC.spawn(npcID + 1, v.x, v.y + 8)
				n.speedX = 3 * v.direction
			else
				local n = NPC.spawn(npcID + 1, v.x + 32, v.y + 8)
				n.speedX = 3 * v.direction
			end
			SFX.play(sfx)
			for i = 0,4 do
				local e = Effect.spawn(npcID + 1,v.x + 24,v.y + 24,player.section, true --[[centered hitbox around x/y]])
				e.speedX = RNG.random(1.25 * v.direction,3 * v.direction)
				e.speedY = RNG.random(-3,3)
			end
		elseif data.progressTimer >= 48 then
			data.state = STATE_IDLE
			data.progressTimer = 0
			data.animTimer = 0
			v.ai2 = 0
		end
	--When harmed
	else
		v.speedX = 0
		v.ai3 = v.ai3 + 1
		if data.progressTimer >= 64 then
			data.state = STATE_ATTACK
			data.progressTimer = 0
			v.ai3 = 0
			if settings.move then
				npcutils.faceNearestPlayer(v)
			end
		end
	end
end

--Handle damage
function fuzzbush.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	
	if reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP then
		if data.health > 0 then
			if culprit.x <= v.x then
				culprit.speedX = -4
			else
				culprit.speedX = 4
			end
			SFX.play(2)
			if data.state ~= STATE_HARM then
				data.health = data.health - 2
				data.progressTimer = 0
				data.state = STATE_HARM
			end
			eventObj.cancelled = true
			return
		end
	end
	
	if reason == HARM_TYPE_NPC then
		if culprit then
			if culprit.__type == "NPC" and (culprit.id == 13 or culprit.id == 108 or culprit.id == 17) then
				data.health = data.health - 1
				culprit:kill()
			else
				data.health = 0
			end
		else
			data.health = 0
		end
		
		if data.health > 0 then
			SFX.play(9)
			Animation.spawn(75, culprit.x, culprit.y)
			eventObj.cancelled = true
			return
		end
	end
end

--Gotta return the library table!
return fuzzbush