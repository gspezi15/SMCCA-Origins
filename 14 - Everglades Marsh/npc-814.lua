--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local effectconfig = require("game/effectconfig")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 84,
	gfxwidth = 80,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 40,
	height = 64,
	--Frameloop-related
	frames = 20,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	--This here contains a list of each character set to be unable to stomp Krusha. The numbers reference a character id, add or remove numbers to your liking.
	--For a reference, here's a link: https://docs.codehaus.moe/#/constants/characters
	characterList = {2,3,4,5,9,10,11,12,13},
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

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

local STATE_WALK = 0
local STATE_LAUGH = 1

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function effectconfig.onTick.TICK_KRUSHA(v)
    if v.timer == v.lifetime-1 then
        v.speedX = math.abs(v.speedX)*v.direction
    end

	if v.timer == v.lifetime-1 then
		SFX.play("Krusha Die.wav")
	end

    v.animationFrame = math.min(v.frames-1,math.floor((v.lifetime-v.timer)/v.framespeed))
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.state = STATE_WALK
		data.timer = 0
		data.turnTimer = 0
		data.dir = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_WALK
		data.timer = data.timer or 0
		data.turnTimer = data.turnTimer or 0
		data.dir = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.timer = 0
		data.state = STATE_WALK
	end
	
	data.timer = data.timer + 1
	
	if data.state == STATE_WALK then
		--Do this when the NPC changes direction
		if data.lastDirection == -v.direction then
			data.turnTimer = 1
		end
		if data.turnTimer > 0 and data.turnTimer <=8 then
			data.turnTimer = data.turnTimer + 1
			v.animationFrame = math.floor((data.turnTimer - 2)/4) % 2
			data.timer = 0
		else
			--If not that then just keep walking
			data.turnTimer = 0
			v.animationFrame = math.floor((data.timer)/6) % 12 + 2
			v.speedX = 1.5 * v.direction
		end
		data.lastDirection = v.direction
		
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = sampleNPCSettings.frames
		});
		
	else
		v.speedX = 0
		--Make the animation play in the correct spot
		if data.timer == 1 then
			if (plr.x + 0.5 * plr.width) < (v.x + v.width*0.5) then
				data.dir = 0
			else
				data.dir = sampleNPCSettings.frames
			end
		end
		if data.timer <= 24 then
			v.animationFrame = math.floor((data.timer)/4) % 6 + 14 + data.dir
		else
			v.animationFrame = math.floor((data.timer)/4) % 3 + 17 + data.dir
		end
		if data.timer >= 48 then
			data.timer = 0
			data.state = STATE_WALK
		end
	end
end

function sampleNPC.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	
	if culprit then
		if culprit.__type == "Player" then
			--Bit of code taken from the basegame chucks
			if (culprit.x + 0.5 * culprit.width) < (v.x + v.width*0.5) then
				culprit.speedX = -4
			else
				culprit.speedX = 4
			end
			for k,t in ipairs(sampleNPCSettings.characterList) do
				if reason == HARM_TYPE_TAIL or ((reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP) and (culprit.character == t)) then
					eventObj.cancelled = true
					data.state = STATE_LAUGH
					SFX.play("Krusha.wav")
					data.timer = 0
					SFX.play(2)
				end
			end
		end
		if culprit.__type == "NPC" and culprit.id == 13 or culprit.id == 265 then
			eventObj.cancelled = true
			data.state = STATE_LAUGH
			SFX.play("Krusha.wav")
			data.timer = 0
		end
	end
end

--Gotta return the library table!
return sampleNPC