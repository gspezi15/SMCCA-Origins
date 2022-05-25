local rain = SFX.open(Misc.resolveSoundFile("Falling Rain.spc"))

function onStart()
    SFX.play(rain, 0.5, 0)
end
-- SFX.play(sound, volume, loops [0 means forever])

