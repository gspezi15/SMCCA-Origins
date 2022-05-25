--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Chasing AI taken from Eclipsed's Silverfish

--Create the library table
local Tyran = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local TyranSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 120,
	gfxwidth = 128,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 50,
	height = 120,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 2,
	framestyle = 1,
	framespeed = 8, --# frames between frame change

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	playerblocktop = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	grabside=false,
	grabtop=false,
	isheavy = 1,
}

--Applies NPC settings
npcManager.setNpcSettings(TyranSettings)


npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_LAVA,
		HARM_TYPE_OFFSCREEN,
	}, 
	{
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_OFFSCREEN]=10,
	}
);


--Register events
function Tyran.onInitAPI()
	npcManager.registerEvent(npcID, Tyran, "onTickNPC")
	--npcManager.registerEvent(npcID, Tyran, "onTickEndNPC")
	--npcManager.registerEvent(npcID, Tyran, "onDrawNPC")
	--registerEvent(Tyran, "onNPCKill")
end

local function getDistance(k,p)
	return k.x < p.x
end

local function setDir(dir, v)
	if (dir and v.data._basegame.direction == 1) or (v.data._basegame.direction == -1 and not dir) then return end
	if dir then
		v.data._basegame.direction = 1
	else
		v.data._basegame.direction = -1
	end
end

local function chasePlayers(v)
	local dir1 = getDistance(v, player)
	setDir(dir1, v)
end

function Tyran.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	chasePlayers(v)

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = data.timer or 0
	end
	
	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	if not v.collidesBlockLeft and not v.collidesBlockRight then
		v:mem(0x120,FIELD_BOOL,false)
	end
	
	v.despawnTimer = 1
	
	data.timer = data.timer + 1
	
	v.speedX = math.clamp(v.speedX + 0.25 * data.direction, -5, 5)
	
	if (v.x + v.width > camera.x and v.x < camera.x + 800 and v.y + v.height > camera.y and v.y < camera.y + 600) then
		if data.timer >= 32 then
			if RNG.randomInt(1,150) == 1 then
				SFX.play(61)
				data.timer = 0
			end
		end
	end
	
	for _,p in ipairs(Player.get()) do
		if (p.standingNPC ~= nil and p.standingNPC.idx == v.idx) then
			p.speedX = 6 * v.direction
		end
	end
end

--Gotta return the library table!
return Tyran