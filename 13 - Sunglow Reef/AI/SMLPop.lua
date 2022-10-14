--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local npcIDs = {}
local pop = {}

--Register events
function pop.register(id)
	npcManager.registerEvent(id, pop, "onTickEndNPC")
	npcManager.registerEvent(id, pop, "onDrawNPC")
	registerEvent(pop, "onExitLevel")
	npcIDs[id] = true
end

--Variable to track which player is riding the NPC
local playerRiding = 0
local saveMount = 0

function pop.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	local config = NPC.config[v.id]
	
	--Timers that just count down

	v.ai1 = v.ai1 - 1
	v.ai3 = v.ai3 - 1
	--When not in use just sit still and detect who's about to enter it
	if v.ai2 == 0 then
		v.animationFrame = 0
		v.speedX = 0
		v.speedY = 0
		if Colliders.collide(Player.getNearest(v.x,v.y),v) and v.ai1 <= 0   then


			
			if Player.getNearest(v.x,v.y) == player then
				playerRiding = player
			else
				playerRiding = player2
				
			end

			if not playerRiding.isInside and playerRiding.mount ~= 2 then
				v.ai1 = 8
			    v.ai2 = 1
				saveMount = playerRiding.mount
				playerRiding.mount = MOUNT_NONE
			end
			
			
		end
	else
        --Stop the pop if player is dead
		if player.deathTimer > 0 then 
		   v.speedX = 0
		   v.speedY = 0
		   return
		end
	
		--Don't let it despawn, it'll softlock the player inside
		v:mem(0x12A, FIELD_WORD, 180)
		
		--Make it look like the player's inside it
		playerRiding.frame = -9999
		playerRiding.x = v.x + v.width / 4 + config.popOffsetX
		playerRiding.y = v.y - v.height + config.popOffsetY
		playerRiding:mem(0x50, FIELD_BOOL, false)
		

		playerRiding.isInside = true

		
		--Allow the player to move the vehicle
		
		v:mem(0x120, FIELD_BOOL, false)
		local dir = vector.zero2

		if playerRiding.keys.up then
			dir.y = -config.movementSpeed
		elseif playerRiding.keys.down then
			dir.y = config.movementSpeed
		end

		if playerRiding.keys.left then
			dir.x = -config.movementSpeed
		elseif playerRiding.keys.right then
			dir.x = config.movementSpeed
		end

		dir:normalize()
		
		v.speedX = dir.x
		v.speedY = dir.y	

		--Shoot torpedoes
		if playerRiding.keys.run == KEYS_PRESSED then
			if v.ai3 <= 0 then
				local n = NPC.spawn(config.projectile, v.x + config.spawnOffsetX[v.direction], v.y + config.spawnOffsetY)
				n.direction = v.direction
				n.speedX = 9 * v.direction
				v.ai3 = config.shootDelay
				SFX.play(config.shotSound)
			end
		end
		
		--Stuff to prevent the player attacking and grabbing items when in the vehicle
		if playerRiding.holdingNPC ~= nil then
			playerRiding.holdingNPC:kill()
		end
		playerRiding:mem(0x160, FIELD_WORD, 1)
		playerRiding:mem(0x162, FIELD_WORD, 1)
		playerRiding:mem(0x164, FIELD_WORD, -1)

		v:mem(0x5C, FIELD_FLOAT, 0)
		
		--Bit of code to make the player exit
		if (playerRiding.keys.jump or playerRiding.keys.altJump) and v.ai1 <= 0 and config.exitable then
			v.ai1 = 8
			v.ai2 = 0
			playerRiding.speedY = -9
			playerRiding.speedX = 0
			SFX.play(1)
			playerRiding.isInside = false
			playerRiding.mount = saveMount
			playerRiding:mem(0x164, FIELD_WORD, 0)
		end
	end
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = config.frames
	});
	
end

--Dunno if this'll do anything but it should hopefully save the player's current mount when they exit a level
function pop.onExitLevel(winType)
	if playerRiding ~= 0 and playerRiding ~= nil then
		if playerRiding.isInside and winType > 0 then
			playerRiding.mount = saveMount
		end
	end
end

--Draw the player inside
function pop.onDrawNPC(v)
	local config = NPC.config[v.id]
	if v.ai2 == 1 and playerRiding ~= 0 and player.deathTimer == 0 then
		playerRiding:render {
			frame = 1,
			direction = v.direction,
			powerup = playerRiding.powerup,
			mount = 0,
			character = playerRiding.character,
			x = v.x + v.width / 4 + config.popOffsetX,
			y = v.y - v.height + config.popOffsetY,
			drawplayer = true,
			ignorestate = true,
			sceneCoords = true,
			priority = -50,
		}
	end
end

return pop
