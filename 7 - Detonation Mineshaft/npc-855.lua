local smwfuzzy = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

-- settings
local config = {
	id = npcID, 
	gfxoffsety = 0, 
	width = 32, 
    height = 32,
    gfxwidth = 32,
    gfxheight = 32,
    frames = 1,
    framestyle = 0,
    noiceball = true,
    noyoshi = true,
	noblockcollision = true,
    nowaterphysics = false,
    jumphurt = true,
    spinjumpSafe = true,
    nogravity = true,

    extents = 96,
    timerlimit = 64
}

npcManager.setNpcSettings(config)

function smwfuzzy.onInitAPI()
    npcManager.registerEvent(npcID, smwfuzzy, "onTickNPC")
    npcManager.registerEvent(npcID, smwfuzzy, "onDrawNPC")
end

function smwfuzzy.onTickNPC(v)
    if Defines.levelFreeze then return end

    if v:mem(0x12A, FIELD_WORD) <= 0 then
        v.data.timer = nil
        v.data.x = nil
        v.data.offset = nil
        v.data.speedY = nil
        return
    end

    local lspdx = 0
	local lspdy = 0
	if not Layer.isPaused() then
		lspdx = v.layerObj.speedX
		lspdy = v.layerObj.speedY
	end
	v.speedX = lspdx
	v.speedY = lspdy
    

    if v.data.timer == nil then
        if lunatime.tick() % 16 == 0 then
            local cx, cy = v.x + 0.5 * v.width, v.y + 0.5 * v.height
            local p = Player.getNearest(cx, cy)
            local cfg = NPC.config[v.id]
            if p.x + 0.5 * p.width > cx - math.abs(cfg.extents)
            and p.x < cx + math.abs(cfg.extents) then
                v.data.timer = 0
                v.data.dir = -1
            end
        end
    else
        local cfg = NPC.config[v.id]
        if v.data.timer > cfg.timerlimit then
            v.data.offset = nil
            v.data.x = v.data.x or v.x
            v.x = v.data.x
            v.speedX = 0
            v.data.speedY = v.data.speedY + Defines.npc_grav
            v.speedY = math.min(v.speedY + v.data.speedY, 12)
        else
            v.data.speedY = 0
            if v.data.timer % 4 == 0 then
                v.data.offset = 1 * v.data.dir
                v.data.dir = -v.data.dir
            end
        end
        v.data.timer = v.data.timer + 1
    end
end

function smwfuzzy.onDrawNPC(v)
    if v:mem(0x12A, FIELD_WORD) <= 0 then
        return
    end
    if not v.data.offset then return end
    npcutils.drawNPC(v, {
        xOffset = v.data.offset
    })
    npcutils.hideNPC(v)
end

return smwfuzzy