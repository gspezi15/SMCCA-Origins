


--[[
	Rapto AI for Just Keff pack

	Made by Lucstar
]]


--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")


local Birdo_LOL = {}

Birdo_LOL.idFire = {}



function Birdo_LOL.register(id,isFire)
	
	npcManager.registerEvent(id, Birdo_LOL, "onTickEndNPC")
	if isFire then
		Birdo_LOL.idFire[id] = true
	end
end

local function fire(v,spawnID)
	local Eggs = NPC.spawn(spawnID,v.x + 0.5 * v.width,v.y + 0.3 * v.height,player.section,false,true)
	Eggs.speedX = v.direction*2.25
	SFX.play(38)
	v.data.fire = false

end

local function selectFrame(npc,a,b) --select the frame depend of direction
	if npc.direction == -1 then
		return a	
	end
	return b
end


function Birdo_LOL.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	local cfg = NPC.config[v.id]
	
	local data = v.data
	
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		data.Jump = 0
		data.fire = false

		data.initialized = true
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	if v.x > player.x then
		v.direction = -1
	else
		v.direction =1
	end



	

	if data.fire then
		local npc

		if Birdo_LOL.idFire[v.id] then
			npc = 830
		else
			npc = 828
		end

		if cfg.spawnNPC ~= nil then
			npc = cfg.spawnNPC
		end
		fire(v,npc)
	end

	if v.collidesBlockBottom and not data.fire then
		data.Jump = data.Jump + 1
	    v.animationFrame = selectFrame(v, math.floor((lunatime.tick() / 8) % 2),math.floor((lunatime.tick() / 8) % 2) + 4)
		v.speedX = v.direction
		
	end

	v:mem(0x120,FIELD_BOOL,false) --No turn around if collides with a block

	
    if  not data.fire  then
		if data.Jump >= 90 then
			v.speedX = 0
			v.animationFrame = selectFrame(v,3,7)
		
			
		end
		if data.Jump == 110 then
			data.fire = true
		end
	end

	if not v.collidesBlockBottom then
		v.animationFrame = selectFrame(v,1,5)
	end


	if data.Jump >= 200 then
		v.speedX = v.direction*0.5
		--v.animationFrame = selectFrame(v,1,5)
		v.speedY = -4
		data.Jump = 0
	end


	
	


end

--Gotta return the library table!
return Birdo_LOL