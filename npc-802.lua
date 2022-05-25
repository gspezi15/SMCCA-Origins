local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local chucks = require("npcs/ai/chucks")

local servingChuck = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local servingChuckSettings = {
	id = npcID, 
	gfxwidth = 80, 
	gfxheight = 70, 
	width = 32,
	height = 48,
	frames = 6,
	framespeed = 8, 
	framestyle = 1,
	score = 0,
	nofireball = 0,
	noyoshi = 1,
	spinjumpsafe = true,
	npconhit = 311,
	luahandlesspeed = true,
	-- Custom
	jumprange = 80,
	jumpheight = 6.5,
	projectileid = npcID - 1,
	radius = 384,
}

local configFile = npcManager.setNpcSettings(servingChuckSettings);

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]=73,
[HARM_TYPE_FROMBELOW]=172,
[HARM_TYPE_NPC]=172,
[HARM_TYPE_HELD]=172,
[HARM_TYPE_TAIL]=172,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

-- Defines
local STATE_GROUNDED = 0;
local STATE_JUMPING = 1;

local thrownOffset = {}
thrownOffset[-1] = -8;
thrownOffset[1] = (configFile.width) + 8;

-- Final setup
local function hurtFunction(v)
	v.data._basegame.hangInAir = 0;
	v.speedY = 0;
	v.ai5 = 0;
end

local function hurtEndFunction(v)
	v.data._basegame.frame = 0;
end

function servingChuck.onInitAPI()
	npcManager.registerEvent(npcID, servingChuck, "onTickEndNPC");
	chucks.register(npcID, hurtFunction, hurtEndFunction);
end

--*********************************************
--                                            *
--              pitching CHUCK                *
--                                            *
--*********************************************

function servingChuck.onTickEndNPC(v)
	if Defines.levelFreeze then return end;
	
	local data = v.data._basegame
	local settings = v.data._settings
	local plr = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
	
	-- initializing
	if (v:mem(0x12A, FIELD_WORD) <= 0 --[[or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL)]] or v:mem(0x138, FIELD_WORD) > 0) then
		v.ai1 = configFile.health; -- Health
		v.ai5 = 0; -- is jumping?
		
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
		data.hangInAir = 0;
	end

	-- hanging in midair handler
	if data.hangInAir == 1 and not data.hurt then
		v.speedY = v.speedY - Defines.npc_grav;
	end
	
	local p = npcutils.getNearestPlayer(v)
	
	-- regular pitching
	if v.ai5 == STATE_GROUNDED and not data.hurt then
		npcutils.faceNearestPlayer(v)
		data.frame = 0;
		v.ai2 = v.ai2 + 1;
		if v.ai2 >= 60 then
			v.speedY = -3.5;
			v.ai2 = 0;
		end
		
		if math.abs(p.x - v.x) <= servingChuckSettings.radius then
			v.ai2 = 0
			v.ai5 = STATE_JUMPING;
		end
	-- jumping AI
	elseif v.ai5 == STATE_JUMPING then
		v.ai2 = v.ai2 + 1;
		-- jumping animation change
		if v.ai2 >= 9 and v.ai2 < 17 then	
			data.frame = 1;
		elseif v.ai2 >= 17 and v.ai2 < 42 then
			data.frame = 2;
			if v.collidesBlockBottom then
				v.speedY = -7
			end
		elseif v.ai2 >= 42 and v.ai2 < 57 then
			data.frame = 3;
		elseif v.ai2 >= 57 and v.ai2 < 65 then
			data.frame = 4;
		else
			data.frame = 5;
		end
		
		-- hang in air
		if v.ai2 == 42 then
			v.speedY = -0.25;
			data.hangInAir = 1;
		end
		
		if v.ai2 == 57 then
			SFX.play(3)
			local myBaseball = NPC.spawn(configFile.projectileid, v.x + thrownOffset[v.direction] - 8, v.y + 24, p.section)
			myBaseball.direction = v.direction
			myBaseball.layerName = "Spawned NPCs"
			if myBaseball.direction == DIR_LEFT then
				myBaseball.speedX = 5.5 * ((plr.x+100) - (v.x+50))/100
			else
				myBaseball.speedX = 5.5 * ((plr.x) - (v.x+50))/100
			end
			myBaseball.speedY = 5.5
			myBaseball.friendly = v.friendly
			if v:mem(0x12C, FIELD_WORD) > 0 then
				myBaseball.data._basegame = myBaseball.data._basegame or {}
				myBaseball.data._basegame.thrownPlayer = p;
			end
		end
		
		-- reset
		if v.ai2 == 56 then
			data.hangInAir = 0;
		end
		
		if v.collidesBlockBottom and v.ai2 > 81 then
			v.ai2 = 0
			v.ai5 = STATE_GROUNDED
		end
	end
	
	-- resetting
	if v.collidesBlockBottom and v.speedY >= 0 then
		if v.speedX ~= 0 then
			v.speedX = 0;
		end
				
		if data.frame > 3 then
			data.frame = 0;
		end
	end
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = configFile.frames
	});
end

function servingChuck.onDrawNPC(v)
	if not Defines.levelFreeze then
		local data = v.data._basegame
		if not data.frame then return end
		v.animationFrame = data.frame + directionOffset[v.direction];
	end
end

return servingChuck;