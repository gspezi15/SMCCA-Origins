--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local rng = require("rng")
--Create the library table
local A_Thing_Angry = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local A_Thing_AngrySettings = {
	id = npcID,
	gfxheight = 64,
	gfxwidth = 42,
	width = 42,
	height = 46,
	frames = 2,
	framestyle = 1,
	framespeed = 8,
	speed = 0, 
	projectileSpeed = 4, --This is for the projectile lmao
	
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
	nowaterphysics = false,
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,

	iswaternpc = true,
	FireSpeeds = {-1.5,0,1.5}
}

--Applies NPC settings
npcManager.setNpcSettings(A_Thing_AngrySettings)

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
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=npcID,
		[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Register events
function A_Thing_Angry.onInitAPI()
	npcManager.registerEvent(npcID, A_Thing_Angry, "onTickEndNPC")
end

function A_Thing_Angry.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	
	if settings.jumpHeight == nil then
		settings.jumpHeight = 6
	end

	if settings.jumpTimer == nil then
		settings.jumpTimer = 250
	end
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = settings.jumpTimer - 1
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = settings.jumpTimer - 1
	end

	if data.timer > 0 or v.underwater then
		data.timer = data.timer + rng.random(1,1.5)
	end

	if data.timer >= settings.jumpTimer then
		if v.direction == DIR_LEFT then 
			v.animationFrame = 1
		else
			v.animationFrame = 3
		end
		v.speedY = -settings.jumpHeight 
	else
		if v.direction == DIR_LEFT then 
			v.animationFrame = 0
		else
			v.animationFrame = 2
		end
	end
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	local dir = vector.v2(plr.x + 0.5 * plr.width  - (v.x + 0.5 * v.width), 
	plr.y + 0.5 * plr.height - (v.y + 0.5 * v.height)):normalize()
	
	
	if data.timer > settings.jumpTimer + 50 then
		for i=1,3 do
			local fire = NPC.spawn(npcID + 3, v.x + 0.5 * v.width, v.y - 0 * v.height, player.section, false, true)
			SFX.play(42)
			fire.direction = v.direction
			fire.layerName = "Spawned NPCs"
			fire.speedY = A_Thing_AngrySettings.FireSpeeds[i]
			fire.speedX = fire.direction * A_Thing_AngrySettings.projectileSpeed
			data.timer = 0
		end
	end 
end

--Gotta return the library table!
return A_Thing_Angry