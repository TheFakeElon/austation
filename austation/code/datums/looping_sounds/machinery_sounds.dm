#define BASE_FREQ 0.5

/datum/looping_sound/flywheel
	start_sound = 'austation/sound/effects/flywheel/startup.ogg'
	mid_sounds = list('austation/sound/effects/flywheel/powered1.ogg' = 1)
	volume = 50
	end_sound = 'austation/sound/effects/flywheel/shutdown.ogg'
	extra_range = 6
	var/wrr = 1

/datum/looping_sound/flywheel/play(soundfile)
	var/list/atoms_cache = output_atoms
	var/sound/S = sound(soundfile)
	if(direct)
		S.channel = open_sound_channel()
		S.volume = volume
	for(var/i in 1 to atoms_cache.len)
		var/atom/thing = atoms_cache[i]
		if(direct)
			SEND_SOUND(thing, S)
		else
			playsound(thing, S, volume, wrr, extra_range, wrr)

/datum/looping_sound/flywheel/proc/update_wrr(rpm, max_rpm)
	wrr = BASE_FREQ + rpm / max_rpm

#undef BASE_FREQ
