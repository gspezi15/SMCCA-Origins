local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local chucks = require("npcs/ai/chucks")

local bowlingChuck = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local bowlingChuckSettings = {
	id = npcID, 
	gfxwidth = 74, 
	gfxheight = 48, 
	width = 32, 
	height = 48, 
	frames = 12,
	framespeed = 8, 
	framestyle = 1,
	score = 0,
	nofireball = 0,
	noyoshi = 1,
	spinjumpsafe = true,
	npconhit = 311,
}

local configFile = npcManager.setNpcSettings(bowlingChuckSettings);

local throwSFX = Misc.resolveSoundFile("bowlingball")

local thrownOffset = {}
thrownOffset[-1] = -32;
thrownOffset[1] = (configFile.width) + 8;

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]=73,
[HARM_TYPE_FROMBELOW]=172,
[HARM_TYPE_NPC]=172,
[HARM_TYPE_HELD]=172,
[HARM_TYPE_TAIL]=172,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

-- Final setup
local function hurtFunction (v)
	v.ai2 = 0;
end

local function hurtEndFunction (v)
	v.data._basegame.frame = 0;
end

function bowlingChuck.onInitAPI()
	npcManager.registerEvent(npcID, bowlingChuck, "onTickEndNPC");
	chucks.register(npcID, hurtFunction, hurtEndFunction);
end

local function spawnBall(v)
	local settings = v.data._settings
	local spawn
	if settings.bomb then
		spawnNPC = 2
	else
		spawnNPC = 1
	end
	local ball = NPC.spawn(npcID + spawnNPC, v.x+thrownOffset[v.direction], v.y+12, player.section)
	ball.direction = v.direction
	ball.layerName = "Spawned NPCs"
	SFX.play(throwSFX)
	ball.speedY = -4
	ball.friendly = v.friendly
end

--*********************************************
--                                            *
--              Chessing CHUCK                *
--                                            *
--*********************************************

function bowlingChuck.onTickEndNPC(v)
	if Defines.levelFreeze then return end;
	
	local data = v.data._basegame
	local settings = v.data._settings
	
	-- initializing
	if (v:mem(0x12A, FIELD_WORD) <= 0 --[[or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL)]] or v:mem(0x138, FIELD_WORD) > 0) then
		v.ai1 = configFile.health; -- Health
		data.state = STATE_THINK
		v.ai2 = 0
		data.timer = 0
		
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = 0,
			frames = configFile.frames
		})
		return
	end
	if (data.exists == nil) then
		v.ai1 = configFile.health;
		data.exists = 0;
		data.frame = 0;
	end
	
	local aFrame
	if settings.bomb then
		aFrame = 6
	else
		aFrame = 0
	end
	
	-- timer start
	v.ai2 = v.ai2 + 1
	if not data.hurt then
		if settings.delay >= 40 then
			if v.ai2 <= settings.delay - 80 then
				data.frame = 0 + aFrame;
			elseif v.ai2 > settings.delay - 80 and v.ai2 <= settings.delay - 72 then
				data.frame = 1 + aFrame;
			elseif v.ai2 > settings.delay - 72 and v.ai2 <= settings.delay - 52 then
				data.frame = 2 + aFrame;
			elseif v.ai2 > settings.delay - 52 and v.ai2 <= settings.delay - 36 then
				data.timer = data.timer + 1
				data.frame = math.floor(data.timer / 8) % 3 + 3 + aFrame;
			else
				data.timer = 0
				data.frame = 5 + aFrame;
			end
			--Text.print(v.ai2,0,0)
			if v.ai2 >= settings.delay then
				v.ai2 = 0
			end
			
			if v.ai2 == settings.delay - 36 then
				spawnBall(v)
			end
		else
			if v.ai2 >= settings.delay - 8 then
				data.frame = 5 + aFrame;
			else
				data.frame = 4 + aFrame;
			end
			if v.ai2 >= settings.delay then
				spawnBall(v)
				v.ai2 = 0
			end
		end
	end
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = configFile.frames
	});
end

function bowlingChuck.onDrawNPC(v)
	if not Defines.levelFreeze then
		local data = v.data._basegame
		if not data.frame then return end
		v.animationFrame = data.frame + directionOffset[v.direction];
	end
end

return bowlingChuck;