--[[
	By Marioman2007
	HUGE amount of code taken from extendedKoopas.lua and spike npcs by MrDoubleA, so credits to them!
]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local armad = {}

armad.npcList = {}
armad.npcMap = {}

armad.shellList = {}
armad.shellMap = {}


local THROWN_NPC_COOLDOWN    = 0x00B2C85C
local SHELL_HORIZONTAL_SPEED = 0x00B2C860


local STATE = {
	-- for the npc
	IDLE = 0,
	CURL = 1,

	-- for the shell
	CHRG = 1,
	ROLL = 2,
}


function armad.registerNPC(id)
	npcManager.registerEvent(id, armad, "onTickNPC", "onTickArmad")
	npcManager.registerEvent(id, armad, "onTickEndNPC", "onTickEndArmad")
	table.insert(armad.npcList, id)
	armad.npcMap[id] = true
end


function armad.registerShell(id)
	npcManager.registerEvent(id, armad, "onTickNPC", "onTickShell")
	npcManager.registerEvent(id, armad, "onDrawNPC", "onDrawShell")
	table.insert(armad.shellList, id)
	armad.shellMap[id] = true
end


local function launchShell(v, culprit)
    if type(culprit) == "Player" then
        if (v.x + v.width/2) > (culprit.x + culprit.width/2) then
            v.direction = DIR_RIGHT
        else
            v.direction = DIR_LEFT
        end

        v:mem(0x12E, FIELD_WORD, mem(THROWN_NPC_COOLDOWN,FIELD_WORD))
        v:mem(0x130, FIELD_WORD, culprit.idx)
    else
        v.direction = -v.direction
    end

    v.speedY = -5
    v:mem(0x136,FIELD_BOOL,true)
end


local function startCurling(v, speedY, speedX)
	v.data.state = STATE.CURL
	v.data.timer = 0
	v.speedX = speedX or 0
	v.speedY = speedY or -2
end


local function getSlopeAngle(v)
	for _,b in Block.iterateIntersecting(v.x, v.y + v.height, v.x + v.width, v.y + v.height + 0.2) do
		if Block.SLOPE_MAP[b.id] then
			return math.deg(math.atan2(
				(b.y + b.height) - (b.y) * Block.config[b.id].floorslope,
				(b.x + b.width) - (b.x)
			))
		end
	end

	return 0
end


function armad.onInitAPI()
	registerEvent(armad, "onPostNPCKill")
	registerEvent(armad, "onNPCHarm", "onNPCHarmShell")
    registerEvent(armad, "onNPCHarm", "onNPCHarmArmad")
end


------------
-- Armads --
------------

function armad.onTickArmad(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	local walkFrames = config.frames - config.curlingFrames

	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.state = STATE.IDLE
		data.frame = 0
		data.timer = 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0 -- Grabbed
	or v:mem(0x136, FIELD_BOOL)     -- Thrown
	or v:mem(0x138, FIELD_WORD) > 0 -- Contained within
	then
		return
	end

	if data.state == STATE.IDLE then
		data.frame = math.floor(data.timer / config.framespeed) % walkFrames
		v.speedX = v.direction

		if v:mem(0x22,FIELD_WORD) ~= 0 then
			startCurling(v, v.speedY, v.speedX)
		end

		local bounds = config.detectArea

		local box = {
			x1 = v.x + v.width/2 + bounds.x * v.direction,
			y1 = v.y + v.height/2 + bounds.y,
			x2 = v.x + v.width/2 + (bounds.x + bounds.w) * v.direction,
			y2 = v.y + v.height/2 + bounds.y + bounds.h,
		}
	
		if v.direction == -1 then
			box.x1, box.x2 = box.x2, box.x1
		end

		if #Player.getIntersecting(box.x1, box.y1, box.x2, box.y2) > 0 then
			startCurling(v)
			data.changeState = true
		end

	elseif data.state == STATE.CURL then
		local frameIndex = math.floor(data.timer / config.framespeed)

		if frameIndex >= config.curlingFrames then
			v:transform(config.shellID)
			v.speedX = 0
			v.speedY = 0
			v:mem(0x18,FIELD_FLOAT,0)
			v.data.initialized = false

			if data.changeState then
				v.data.state = true
			end
		end

		data.frame = (frameIndex % config.curlingFrames) + walkFrames
	end

	data.timer = data.timer + 1
end


function armad.onTickEndArmad(v)
	local data = v.data
	local config = NPC.config[v.id]

	if not data.frame then return end

	if config.framestyle == 1 and v.direction == 1 then
		v.animationFrame = data.frame + config.frames
	else
		v.animationFrame = data.frame
	end
end


------------
-- Shells --
------------

function armad.onTickShell(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]

	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		if data.state == true then
			data.state = STATE.CHRG
			v.speedX = -v.direction
		else
			data.state = STATE.IDLE
		end
		
		data.initialized = true
		data.rotation = 0
		data.bounceStrength = 0
		data.slowingDown = false
		data.mainDir = v.direction
		data.chargeTimer = 0
		data.smokeTimer = 0
	end

	if v:mem(0x138, FIELD_WORD) > 0 then
		return
	end

	if data.state ~= STATE.CHRG and v:mem(0x12C, FIELD_WORD) == 0 then
		local angle = getSlopeAngle(v)

		if angle ~= 0 then
			v.speedX = v.speedX + angle/896

			if v.speedY >= 0 then
				v.speedY = 8
			end
		end

		if v.speedX ~= 0 and data.state ~= STATE.ROLL then
			data.state = STATE.ROLL
			v:mem(0x136, FIELD_BOOL, true)
		end
	end

	if data.state ~= STATE.ROLL and data.state ~= STATE.CHRG then
		if (v:mem(0x12E, FIELD_WORD) > 0 --[[or v:mem(0x136, FIELD_BOOL)]]) and v.speedX ~= 0 then
			v:mem(0x136, FIELD_BOOL, true)
			data.state = STATE.ROLL
		end
	end

	if data.state == STATE.IDLE or data.slowingDown then
		v.speedX = v.speedX * 0.95

		if math.abs(v.speedX) < 0.5 then
			v.speedX = 0
		end

		if data.slowingDown then
			if v.speedX == 0 then
				data.state = STATE.IDLE
				data.slowingDown = false
			end

			if v.collidesBlockBottom and data.bounceStrength > 0 then
				v.speedY = -data.bounceStrength
				data.bounceStrength = 0
			end
		end
	end

	if v:mem(0x12C, FIELD_WORD) > 0 then return end

	if data.state == STATE.IDLE then
		-- do stuff later
	elseif data.state == STATE.CHRG then
		data.chargeTimer = data.chargeTimer + 1
		
		if v.collidesBlockBottom and data.smokeTimer % 2 == 0 then
			local e = Effect.spawn(74, v.x + v.width/2, v.y + v.height)
			e.x = e.x - e.width/2
			e.y = e.y - e.height/2
			e.speedX = -v.speedX
		end

		if data.chargeTimer == 32 then
			data.chargeTimer = 0
			v.direction = data.mainDir
			v.speedX = mem(SHELL_HORIZONTAL_SPEED,FIELD_FLOAT) * v.direction
			v:mem(0x136,FIELD_BOOL,true)
			data.state = STATE.ROLL
		end
	elseif data.state == STATE.ROLL and not data.slowingDown then
		local maxSpeed = mem(SHELL_HORIZONTAL_SPEED,FIELD_FLOAT)

		if v:mem(0x22,FIELD_WORD) == 0 then
			if v.speedX > -maxSpeed and v.direction == -1 then
				v.speedX = math.max(v.speedX - 0.1, -maxSpeed)
			elseif v.speedX < maxSpeed and v.direction == 1 then
				v.speedX = math.min(v.speedX + 0.1, maxSpeed)
			end
		end

		if v.collidesBlockBottom and data.smokeTimer % 2 == 0 then
			local e = Effect.spawn(74, v.x + v.width/2, v.y + v.height)
			e.x = e.x - e.width/2
			e.y = e.y - e.height/2
			e.speedX = -v.speedX
		end

		if (v.collidesBlockLeft or v.collidesBlockRight) and v.speedX ~= 0 then
			data.slowingDown = true
			data.bounceStrength = 4
			data.rotation = 0
			v:mem(0x18,FIELD_FLOAT,0)
			v:mem(0x136, FIELD_BOOL, false)
			v.speedY = -4
		end
	end

	data.smokeTimer = data.smokeTimer + 1
	data.rotation = data.rotation + math.deg(v.speedX / ((v.width + v.height) / 4))
end


function armad.onDrawShell(v)
	local config = NPC.config[v.id]

	if v.despawnTimer <= 0 or v.isHidden then return end

	Graphics.drawBox{
		texture = Graphics.sprites.npc[v.id].img,
		x = v.x + v.width/2 + config.gfxoffsetx * v.direction,
		y = v.y + v.height/2 + config.gfxoffsety,
		sourceX = 0,
		sourceY = v.animationFrame * config.gfxheight,
		sourceWidth = config.gfxwidth,
		sourceHeight = config.gfxheight,
		priority = (config.foreground and -15) or -45,
		sceneCoords = true,
		centered = true,
		rotation = v.data.rotation or 0,
	}

	npcutils.hideNPC(v)
end


------------------------
-- Spawn death effect --
------------------------

local noEffectReasons = table.map{HARM_TYPE_LAVA, HARM_TYPE_SPINJUMP, HARM_TYPE_OFFSCREEN}

function armad.onPostNPCKill(v, r)
	if (not armad.shellMap[v.id] and not armad.npcMap[v.id]) or noEffectReasons[r] then return end

	local e = Effect.spawn(NPC.config[v.id].deathEffect, v.x + v.width/2, v.y + v.height/2)
	local rotation = v.data.rotation or 0

	if armad.shellMap[v.id] then
		e.direction = -v.direction
		e.speedX = math.clamp(math.abs(v.speedX), 4, 6) * e.direction

		if rotation > 0 then
			e.angle = rotation
		end
	else
		e.direction = v.direction
		e.speedX = e.direction * 4
		e.speedY = -10
	end

	e.rotation = 12 * e.direction
end


---------------------------------------
-- Stuff copied from extendendKoopas --
---------------------------------------

function armad.onNPCHarmArmad(eventObj,v,reason,culprit)
	if not armad.npcMap[v.id] then return end

	local config = NPC.config[v.id]
	local data = v.data

	if reason == HARM_TYPE_JUMP then
		startCurling(v)
		eventObj.cancelled = true
		SFX.play(2)

	elseif reason == HARM_TYPE_FROMBELOW or (reason == HARM_TYPE_TAIL and v:mem(0x26,FIELD_WORD) == 0) then
		startCurling(v)
		launchShell(v,culprit,true)
		eventObj.cancelled = true

		if reason == HARM_TYPE_TAIL then
			v:mem(0x26,FIELD_WORD,8)
			SFX.play(9)
		else
			SFX.play(2)
		end      
	elseif reason == HARM_TYPE_SPINJUMP and (config.isflying and config.spinjumpsafe) then -- isflying is hardcoded to always let spin jumps work! for some reason!
		eventObj.cancelled = true      
	end
end


function armad.onNPCHarmShell(eventObj, v, reason, culprit)
	if not armad.shellMap[v.id] then return end

	local config = NPC.config[v.id]
	local data = v.data

	if reason == HARM_TYPE_FROMBELOW or (reason == HARM_TYPE_TAIL and v:mem(0x26,FIELD_WORD) == 0) then
		launchShell(v, culprit, true)

		if reason == HARM_TYPE_TAIL then
			SFX.play(9)
			v:mem(0x26,FIELD_WORD,8)
		else
			SFX.play(2)
		end

		eventObj.cancelled = true
		return
	end

	-- The rest of this code is for handling kicking for custom shells. Since for some reason, isshell only half works
	local culpritIsPlayer = (type(culprit) == "Player")

	if reason == HARM_TYPE_JUMP then
		if v:mem(0x138, FIELD_WORD) == 2 then -- dropping out of the item box
			v:mem(0x138, FIELD_WORD, 0)
		end

		if not culpritIsPlayer or (culprit:mem(0xBC,FIELD_WORD) <= 0 and culprit.mount ~= MOUNT_CLOWNCAR) then
			local playerIsCantHurtPlayer = (culpritIsPlayer and v:mem(0x130,FIELD_WORD) == culprit.idx)
			
			if v.speedX == 0 and not playerIsCantHurtPlayer then
				SFX.play(9)

				if culpritIsPlayer then
					v.direction = culprit.direction
					v:mem(0x12E,FIELD_WORD, mem(THROWN_NPC_COOLDOWN,FIELD_WORD))
					v:mem(0x130,FIELD_WORD, culprit.idx)
				end

				v.speedX = mem(SHELL_HORIZONTAL_SPEED,FIELD_FLOAT) * v.direction
				v.speedY = -7
				v:mem(0x136,FIELD_BOOL,true)
				data.state = STATE.ROLL
			elseif not playerIsCantHurtPlayer or (culpritIsPlayer and v:mem(0x22,FIELD_WORD) == 0 and not culprit.climbing) then
				SFX.play(2)
				v.speedX = 0
				v.speedY = -2
				v:mem(0x18,FIELD_FLOAT,0)
				v:mem(0x136,FIELD_BOOL,false)
				data.state = STATE.IDLE
				data.rotation = 0
			end
		end

		eventObj.cancelled = true
		return
	end
end


return armad