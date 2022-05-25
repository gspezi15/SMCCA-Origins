local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local chucks = require("npcs/ai/chucks")
local colliders = require("Colliders")

local puttingChuck = {}
local npcID = NPC_ID;

--***************************************************************************************************
--                                                                                                  *
--              DEFAULTS AND NPC CONFIGURATION                                                      *
--                                                                                                  *
--***************************************************************************************************

local puttingChuckSettings = {
	id = npcID, 
	gfxwidth = 64, 
	gfxheight = 64, 
	width = 32, 
	height = 48, 
	frames = 8,
	framespeed = 8, 
	framestyle = 1,
	score = 0,
	nofireball = 0,
	noyoshi = 1,
	spinjumpsafe = true,
	npconhit = 311,
	luahandlesspeed = true,
	-- Custom
	throwtime = 30,
	defaultvolley = 3,
	projectileid = npcID + 1,
	turninterval = 40
}

local configFile = npcManager.setNpcSettings(puttingChuckSettings);

npcManager.registerHarmTypes(npcID, 	
{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA}, 
{[HARM_TYPE_JUMP]=73,
[HARM_TYPE_FROMBELOW]=172,
[HARM_TYPE_NPC]=172,
[HARM_TYPE_HELD]=172,
[HARM_TYPE_TAIL]=172,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

-- Defines
local STATE_SWINGING = 0;
local STATE_CHASING = 1;

local thrownOffset = {}
thrownOffset[-1] = -8;
thrownOffset[1] = (configFile.width) + 8;

-- Final setup
local function hurtFunction (v)
	v.ai2 = 0;
	v.ai5 = 0;
	v.ai3 = v.ai4;
end

local function hurtEndFunction (v)
	v.data._basegame.frame = 0;
	v.ai2 = -40;
end

function puttingChuck.onInitAPI()
	npcManager.registerEvent(npcID, puttingChuck, "onTickEndNPC");
	chucks.register(npcID, hurtFunction, hurtEndFunction);
	registerEvent(puttingChuck, "onNPCHarm");
	registerEvent(puttingChuck, "onNPCKill");
end

--*********************************************
--                                            *
--              putting CHUCK                *
--                                            *
--*********************************************

function puttingChuck.onTickEndNPC(v)
	if Defines.levelFreeze then return end;
	
	local data = v.data._basegame
	local settings = v.data._settings
	local plr = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
	
	-- initializing
	if (v:mem(0x12A, FIELD_WORD) <= 0 --[[or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL)]] or v:mem(0x138, FIELD_WORD) > 0) then
		v.ai1 = configFile.health; -- Health
		if settings.volley == 0 then
			v.ai2 = configFile.throwtime + 65;
		else
			v.ai2 = 0; -- Generic Timer
		end
		v.ai3 = settings.volley or configFile.defaultvolley
		v.ai4 = v.ai3; -- Starting ammo
		v.ai5 = 0; -- is jumping?
		data.detectBox = colliders.Box(v.x, v.y, v.width + 48, v.height * 1.5);
		data.hitbox = colliders.Box(v.x, v.y, v.width + 32, v.height - 8);
		data.attackTimer = 30;
		
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
	
	local p = npcutils.getNearestPlayer(v)
	
	-- failsafe
	if (settings.volley == nil) then
		v.ai2 = 0; --Generic Timer
		v.ai3 = configFile.defaultvolley
		v.ai4 = v.ai3;
		settings.volley = v.ai4;
	end
	
	data.detectBox.x = v.x - 24
	data.detectBox.y = v.y - 24
	if v.direction == DIR_LEFT then
		data.hitbox.x = v.x - 24
	else
		data.hitbox.x = v.x - 8
	end
	data.hitbox.y = v.y + 8
	
	-- timer start
	v.ai2 = v.ai2 + 1;
	
	if settings.volley == 0 then v.ai5 = STATE_CHASING end
	if v.ai2 < configFile.throwtime + 12 then npcutils.faceNearestPlayer(v) end
	
	-- regular putting
	if v.ai5 == STATE_SWINGING and not data.hurt then
		if v.ai2 <= configFile.throwtime then
			data.frame = 1;
		end
		if v.ai2 > configFile.throwtime and v.ai2 <= configFile.throwtime + 12 then
			data.frame = 0;
		elseif v.ai2 > configFile.throwtime + 12 then
			data.frame = 2
		end
		if v.ai2 == configFile.throwtime + 12 then
			local myGolfball = NPC.spawn(configFile.projectileid, v.x+thrownOffset[v.direction], v.y+12, p.section)
			myGolfball.direction = v.direction
			myGolfball.layerName = "Spawned NPCs"
			local np = npcutils.getNearestPlayer(v)
			data.vector = vector(np.x-v.x+(np.width-v.width)*11.5 * -v.direction, np.y-v.y+RNG.random(-32,32)+(np.height-v.height)*0.5):normalize()
			Animation.spawn(75, myGolfball.x - 6, myGolfball.y + 6)
			SFX.play(3)
			myGolfball.speedX = data.vector.x*9
			myGolfball.speedY = data.vector.y*9
			myGolfball.friendly = v.friendly
			if v:mem(0x12C, FIELD_WORD) > 0 then
				myGolfball.data._basegame = myGolfball.data._basegame or {}
				myGolfball.data._basegame.thrownPlayer = 1
			end
			
			-- decrement how many golf balls are left
			v.ai3 = v.ai3 - 1;
		end
		
		-- reset
		if v.ai2 == configFile.throwtime + 24 then
			-- if there's still balls left, reset
			if v.ai3 > 0 or settings.volley < 0 then
				v.ai2 = 0;
				data.frame = 0;
			-- otherwise time to switch states
			else
				v.ai5 = STATE_CHASING;
			end
		end
	
	-- chasing AI
	elseif v.ai5 == STATE_CHASING then
		if v.ai2 <= configFile.throwtime + 64 then
			data.frame = 2;
		else
			if data.attackTimer >= 30 then
				data.frame = math.floor(lunatime.tick() / 6) % 2 + 3;
				v.speedX = 3 * NPC.config[npcID].speed * v.direction
				if v.ai2 % puttingChuckSettings.turninterval == 0 then
					if v.x > Player.getNearest(v.x, v.y).x then
						v.direction = -1;
					else
						v.direction = 1;
					end
				end
			else
				data.attackTimer = data.attackTimer + 1
				v.speedX = 0;			
				for _,plr in ipairs(Player.get()) do
					if colliders.collide(plr, data.hitbox) then
						plr:harm()
					end
				end
				if data.attackTimer < 30 and data.attackTimer > 13 then
					data.frame = 7;
				elseif data.attackTimer <= 13 then
					data.frame = math.floor(data.attackTimer / 6) % 3 + 5;
				end
			end
			for _,plr in ipairs(Player.get()) do
				if colliders.collide(plr, data.detectBox) and data.attackTimer >= 30 then
					data.attackTimer = 0
				end
			end
		end
	end
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = configFile.frames
	});
end

function puttingChuck.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	if reason == HARM_TYPE_JUMP and v.ai2 == 0 then
		Animation.spawn(npcID, v.x, v.y + 16)
	end
end

function puttingChuck.onNPCKill(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	Animation.spawn(npcID, v.x, v.y + 16)
end

function puttingChuck.onDrawNPC(v)
	if not Defines.levelFreeze then
		local data = v.data._basegame
		if not data.frame then return end
		v.animationFrame = data.frame + directionOffset[v.direction];
	end
end

return puttingChuck;