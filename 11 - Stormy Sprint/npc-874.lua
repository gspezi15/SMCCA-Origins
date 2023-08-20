local lightning = {}

local npcManager = require("npcManager")

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	gfxwidth = 32, 
	gfxheight = 32, 
	width = 16,
	height = 32,
	frames = 1,
	harmlessgrab=true,
	ignorethrownnpcs = true,
	framespeed = 8,
	framestyle = 0,
	nofireball=1,
	noiceball=-1,
	noyoshi=1,
	nohurt=-1,
	speed=1,
	nogravity=-1,
	noblockcollision=-1,
	jumphurt = 1,
	nowaterphysics=true,
	spinjumpsafe = false,
	lightradius=32,
	lightbrightness=1,
	lightcolor=Color.white,

	spawnid = 875
})

function lightning.onInitAPI()
	npcManager.registerEvent(npcID, lightning, "onTickNPC")
end

function lightning.onTickNPC(v)
	if Defines.levelFreeze
		or v.isHidden
		or v:mem(0x12C, FIELD_WORD) > 0
		or v:mem(0x138, FIELD_WORD) > 0
		or v:mem(0x12A, FIELD_WORD) <= 0 then return end

	local data = v.data._basegame
	
	if data.feet == nil then
		data.feet = Colliders.Box(0,0,v.width,1)
		data.lastFrameCollision = true
	end
	
	if v:mem(0x136, FIELD_BOOL) == false then
		v.speedY = NPC.config[npcID].speed * 7
	else
		v.speedY = v.speedY + Defines.npc_grav
		data.wasThrown = data.wasThrown or v:mem(0x132, FIELD_WORD) > 0
	end

	if v.speedY > 0 then
		data.feet.x = v.x
		data.feet.y = v.y + v.height
		local collidesWithSolid = false
		local footCollisions = Colliders.getColliding{
		
			a=	data.feet,
			b=	Block.SOLID ..
				Block.PLAYER ..
				Block.SEMISOLID,
			btype = Colliders.BLOCK,
			filter= function(other)
				if (not collidesWithSolid and not other.isHidden and other:mem(0x5A, FIELD_WORD) == 0) then
					if Block.SOLID_MAP[other.id] or Block.PLAYER_MAP[other.id] then
						return true
					end
					if data.feet.y <= other.y + 8 then
						return true
					end
				end
				return false
			end
			
		}
		
		if #footCollisions > 0 then
			collidesWithSolid = true
			
			if not data.lastFrameCollision then
				local id = NPC.config[v.id].spawnid
				local fl = NPC.spawn(id, v.x + 0.5 * v.width, footCollisions[1].y - 0.5 * NPC.config[id].height, v:mem(0x146, FIELD_WORD), false, true)
				local fr = NPC.spawn(id, v.x + 0.5 * v.width, footCollisions[1].y - 0.5 * NPC.config[id].height, v:mem(0x146, FIELD_WORD), false, true)
				fl.speedX = -5
				fr.speedX = 5
				v:kill(9)
				return
			end
		end
		data.lastFrameCollision = collidesWithSolid
	end
end

return lightning