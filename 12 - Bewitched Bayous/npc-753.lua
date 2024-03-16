local e = {}

local npcManager = require("npcManager")
local spline = require("spline")
local npcID = NPC_ID
local shieldImg = loadImage("s_shield.png")
npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 68,
	gfxheight = 64,
	width = 32,
	height = 48,
	frames = 4,
	framespeed = 8,
	framestyle = 1,
	score = 3
})

npcManager.registerHarmTypes(
	npcID, 	
	{
		HARM_TYPE_JUMP, 
		HARM_TYPE_FROMBELOW, 
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_NPC, 
		HARM_TYPE_HELD, 
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP, 
		HARM_TYPE_SWORD, 
		HARM_TYPE_LAVA
	}, 
	{
		[HARM_TYPE_JUMP]={id=npcID, speedX=0, speedY=0},
		[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=76,
		[HARM_TYPE_SWORD]=63,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

local protectedLayers = {}
local shields = {}

npcManager.registerEvent(npcID, e, "onTickEndNPC")
npcManager.registerEvent(npcID, e, "onStartNPC")
registerEvent(e, "onNPCHarm")
registerEvent(e, "onTickEnd")
registerEvent(e, "onDraw")

function e.onTickEnd()
	for k=#shields, 1, -1 do
		local v = shields[k]
		v.timer = v.timer + 1

		if v.timer > 20 then
			table.remove(shields, k)
		end
	end
end

local function drawSplineCustom(spline, steps, halfwidth, priority, opacity)
    steps = steps or 50
    local ps = {}
    local idx = 1
    local ds = 1/steps
    local s = 0
	local dir = spline.startTan
    local pold = spline:evaluate(0)
    local tx = {}
    for i = 0,steps do
        local p = spline:evaluate(s)
        s = s+ds
        local texCoord = 0.5
        if i == 0 then
            texCoord = 0
        elseif i == steps then
            texCoord = 1
        end

        local normal = vector(dir.x, dir.y):rotate(-90):normalize() * halfwidth
        
        ps[idx] = p[1] + normal.x + RNG.random(-2, 2)
        ps[idx+1] = p[2] + normal.y + RNG.random(-2, 2)
        ps[idx+2] = p[1] - normal.x + RNG.random(-2, 2)
        ps[idx+3] = p[2] - normal.y + RNG.random(-2, 2)
        tx[idx] = texCoord
        tx[idx+1] = 0
        tx[idx+2] = texCoord
        tx[idx+3] = 1

        if i < steps then
            dir = spline:evaluate(s+ds) - p
        end
        
        idx = idx+4
    end
		
    Graphics.glDraw{
        vertexCoords = ps,
        textureCoords = tx,
        primitive = Graphics.GL_TRIANGLE_STRIP,
        priority = priority,
        sceneCoords = true,
        color = Color.pink .. opacity
    }
end

function e.onDraw()
	local t = math.floor(lunatime.tick() * 0.25) % 2
	for k,v in ipairs(NPC.getIntersecting(camera.x, camera.y, camera.x + camera.width, camera.y + camera.height)) do
		if v.id ~= npcID and v.despawnTimer > 0 then
			if protectedLayers[v.layerName] then
				Graphics.drawImageToSceneWP(shieldImg, v.x + 0.5 * v.width - 0.5 * shieldImg.width, v.y + 0.5 * v.height - 0.5 * shieldImg.width, 0, 0, shieldImg.width, shieldImg.width, 0.4 + 0.15 * t, -10)
			end
		end
	end

	for k,v in ipairs(shields) do
		local f = math.floor(v.timer * 0.25)
		for k,s in ipairs(v.links) do
			drawSplineCustom(s, nil, 1, -15, 1-(f*0.25))
		end
		Graphics.drawImageToSceneWP(shieldImg, v.x - 0.5 * shieldImg.width, v.y - 0.5 * shieldImg.width, 0, shieldImg.width * f, shieldImg.width, shieldImg.width, -10)
	end
end

local function spawnShield(cx, cy, connect)
	local shield = {}
	shield.x = cx
	shield.y = cy
	shield.links = {}
	if connect then
		for k,v in ipairs(connect) do
			table.insert(shield.links, spline.segment{
				start = vector(cx, cy),
				stop = vector(v[1], v[2]),
				startTan = vector.zero2,
				stopTan = vector.zero2,
			})
		end
	end
	shield.timer = 0
	table.insert(shields, shield)
end

function e.onNPCHarm(event, v, rsn, culp)
	if rsn == 6 or rsn == 9 then return end
	if v.id ~= npcID then
		if protectedLayers[v.layerName] then
			local foundOne = false
			local connections = {}
			for k,n in ipairs(protectedLayers[v.layerName]) do
				if n.isValid then
					n.data.laughTimer = 65
					foundOne = true
					table.insert(connections, {n.x + 0.5 * n.width + 30 * n.direction, n.y + 0.5 * n.height})
				end
			end
			if foundOne then
				if (rsn == HARM_TYPE_HELD or rsn == HARM_TYPE_NPC or rsn == HARM_TYPE_PROJECTILE_USED) and culp and culp.__type == "NPC" then
					culp:kill()
				end
				spawnShield(v.x + 0.5 * v.width, v.y + 0.5 * v.height, connections)
				if rsn == 7 then
					local diff = math.sign((player.x + 0.5 * player.width) - (v.x + 0.5 * v.width))
					if player.speedX == 0 or math.sign(player.speedX) ~= diff then
						player.speedX = 3 * math.sign(diff)
						player.speedY = player.speedY - 2
					end
				end
				SFX.play("se_boss_marx_icebomb_fire.ogg")
				SFX.play(RNG.irandomEntry{
					"se_boss_marx_icebomb_right_roll.ogg",
					"se_boss_marx_icebomb_left_roll.ogg"
				})
				event.cancelled = true
				return
			end
			protectedLayers[v.layerName] = nil
		end
	else
		local foundOne = false
		for k,n in ipairs(NPC.get(npcID)) do
			if n ~= v and n.isValid and n.layerName == v.layerName then
				foundOne = true
				break
			end
		end
		if not foundOne then
			for k,n in ipairs(NPC.getIntersecting(camera.x, camera.y, camera.x + camera.width, camera.y + camera.height)) do
				if n.id ~= npcID and n.despawnTimer > 0 and v.layerName == n.layerName then
					spawnShield(n.x + 0.5 * n.width, n.y + 0.5 * n.height, false)
				end
			end
			SFX.play("se_boss_crazyhand_gravityball_fire.ogg")
			SFX.play("se_boss_marx_icebomb_right_roll.ogg")
			protectedLayers[v.layerName] = nil
		end
	end
end

function e.onStartNPC(v)
	protectedLayers[v.layerName] = protectedLayers[v.layerName] or {}
	table.insert(protectedLayers[v.layerName], v)
end

function e.onTickEndNPC(v)
    -- Pyro please use this format to make the NPC thanks!
	if v.isHidden or v.despawnTimer <= 0 then
		v.data.laughTimer = 0
		return
	end

	if v.data.laughTimer == nil then v.data.laughTimer = 0 end
	
	if v.data.laughTimer > 0 then
		v.data.laughTimer = v.data.laughTimer - 1
		v.animationFrame = (math.floor(v.data.laughTimer * 0.25) % 2) + 2
	else
		v.animationFrame = 0
	end
	if v.direction == 1 then v.animationFrame = v.animationFrame + 4 end
	v.animationTimer = 2
end

return e