/*************************************************************************************************
*
*	DOD Single Caps by Vet(3TT3V)
*		For use with DOD 1.3
*		Inspired by 'gunsofnavarone' from dodplugins.net
*
*	Description:
*		This plugin will change the number of player required to cap an area based on the
*		number of players currently in the game. The number of players trigger is variable
*		via CVar. The trigger has a 'deadband' of 2. In other words, if the trigger is set
*		to 5, it takes 4 or less players to turn ON single caps, and then 6 or more players
*		to turn it back OFF. Setting the trigger to 0 turns OFF the auto-detect.
*
*	CVARs:
*		single_caps_trigger <#> (Number of players to trigger change - default 5, 0 = Disable)
*		single_caps_notify <0/1> (Display a message about the change - default 1/On)
*		single_caps_ignore_bots <0/1> (Don't count bots as players - default 0/Off)
*
*	Command:
*		dod_single_caps <on|off|auto> Set the plugin's mode of operation.
*
**************************************************************************************************/

#include <amxmisc>
#include <fakemeta>

#define PLUGIN "DOD_SingleCaps"
#define VERSION "1.6"
#define AUTHOR "Vet(3TT3V)"
#define SVALUE "v1.6 by Vet(3TT3V)"

#define CL_CAPAREA "dod_capture_area"
#define KEY_ALLYNUM "area_allies_numcap"
#define KEY_AXISNUM "area_axis_numcap"

new g_capally[32]		// Ally # to cap
new g_capaxis[32]		// Axis # to cap
new g_capent[32]		// Entity #
new g_capcnt		// Count
new g_ignbots
new g_captrig
new g_notify
new g_status
new g_maxpls

public plugin_precache()
{
	register_forward(FM_KeyValue, "forward_keyvalue")
	return PLUGIN_CONTINUE
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar(PLUGIN, SVALUE, FCVAR_SERVER|FCVAR_SPONLY)
	register_clcmd("dod_single_caps", "cmdSingleCaps", ADMIN_MAP, "<on|off|auto> Change caps mode")

	g_captrig = register_cvar("single_caps_trigger", "5")		// Set to 0 to disable
	g_notify = register_cvar("single_caps_notify", "1")		// Display cap message
	g_ignbots = register_cvar("single_caps_ignore_bots", "0")	// Don't count bots

	g_maxpls = get_maxplayers() + 1
	if (g_capcnt)
		set_task(60.0, "ck_player_num", 707, "", 0, "b")

	return PLUGIN_CONTINUE
}

public forward_keyvalue(ent, handle)
{
	static keyname[32], keyvalue[8], tmpint

	if (!pev_valid(ent))			// exit if invalid entity
		return FMRES_IGNORED

	get_kvd(handle, KV_KeyName, keyname, 31)
	if (keyname[0] != 97)			// Quick check for proper key (start with 'a')
		return FMRES_IGNORED		// Most keynames will fail (its a speed thing)

	if (equali(keyname, KEY_ALLYNUM)) {
		get_kvd(handle, KV_Value, keyvalue, 7)
		tmpint = str_to_num(keyvalue)
		if (tmpint > 1) {
			g_capally[g_capcnt] = tmpint
			g_capent[g_capcnt] = ent
			++g_capcnt
		}
	} else if (equali(keyname, KEY_AXISNUM)) {
		get_kvd(handle, KV_Value, keyvalue, 7)
		tmpint = str_to_num(keyvalue)
		if (tmpint > 1) {
			g_capaxis[g_capcnt] = tmpint
			g_capent[g_capcnt] = ent
			++g_capcnt
		}
	}
	return FMRES_IGNORED
}

public ck_player_num()
{
	static p_num, t_num, b_num, i
	t_num = get_pcvar_num(g_captrig)
	if (t_num) {
		p_num = get_playersnum(1)
		if (get_pcvar_num(g_ignbots)) {
			b_num = 0
			for (i = 1; i < g_maxpls; i++) {
				if (is_user_bot(i))
					++b_num
			}
			p_num -= b_num
		}
		if (p_num > t_num && g_status)
			normal_caps()
		else if (p_num < t_num && !g_status)
			single_caps()
	}
	return PLUGIN_CONTINUE
}

public cmdSingleCaps(id, lvl, cid)
{
	new data1[8] 
	if (cmd_access(id, lvl, cid, 2)) {
		read_argv(1, data1, 7)
		switch (data1[1]) {
			case 'n', 'N': {
				remove_task(707)
				single_caps()
				console_print(id, "DOD SingleCaps set to ON")
			}
			case 'f', 'F': {
				remove_task(707)
				normal_caps()
				console_print(id, "DOD SingleCaps set to OFF")
			}
			case 'u', 'U': {
				ck_player_num()
				if (!task_exists(707))
					set_task(60.0, "ck_player_num", 707, "", 0, "b")
				console_print(id, "DOD SingleCaps set to AUTO")
			}
		}
	}
	return PLUGIN_HANDLED
}

single_caps()
{
	for (new i = 0; i < g_capcnt; i++) {
		if (g_capally[i])
			fm_set_kvd(g_capent[i], KEY_ALLYNUM, "1", CL_CAPAREA)
		else
			fm_set_kvd(g_capent[i], KEY_AXISNUM, "1", CL_CAPAREA)
	}
	g_status = 1
	if (get_pcvar_num(g_notify)) {
		set_hudmessage(255, 128, 255, -1.0, 0.40, 0, 4.0, 5.0, 0.5, 0.15, 4)
		show_hudmessage(0, "Single-man cap areas Enabled")
	}
}

normal_caps()
{
	new tmpstr[8]
	for (new i = 0; i < g_capcnt; i++) {
		if (g_capally[i]) {
			formatex(tmpstr, 7, "%d", g_capally[i])
			fm_set_kvd(g_capent[i], KEY_ALLYNUM, tmpstr, CL_CAPAREA)
		} else {
			formatex(tmpstr, 7, "%d", g_capaxis[i])
			fm_set_kvd(g_capent[i], KEY_AXISNUM, tmpstr, CL_CAPAREA)
		}
	}
	g_status = 0
	if (get_pcvar_num(g_notify)) {
		set_hudmessage(255, 128, 255, -1.0, 0.40, 0, 4.0, 5.0, 0.5, 0.15, 4)
		show_hudmessage(0, "Cap areas have been Reset")
	}
}

stock fm_set_kvd(entity, const key[], const value[], const class[])
{
	set_kvd(0, KV_ClassName, class)
	set_kvd(0, KV_KeyName, key)
	set_kvd(0, KV_Value, value)
	set_kvd(0, KV_fHandled, 0)

	return dllfunc(DLLFunc_KeyValue, entity, 0)
}
