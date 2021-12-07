/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>
#include <sdktools>
#include <cstrike>

new String:SND_KILLVOICE[][] = {"counter-strike source/cstrike/sound/vox/firstkill.wav","counter-strike source/cstrike/sound/vox/doublekill.wav",
"counter-strike source/cstrike/sound/vox/triplekill.wav","counter-strike source/cstrike/sound/vox/ultrakill.wav","counter-strike source/cstrike/sound/vox/headshot.wav","counter-strike source/cstrike/sound/vox/humililation.wav","counter-strike source/cstrike/sound/vox/gotit.wav"};

new String:NAME_OVERLAYS[][] = {"materials/overlays/kill/kill_1.vmt","materials/overlays/kill/kill_2.vmt",
"materials/overlays/kill/kill_3.vmt","materials/overlays/kill/kill_4.vmt","materials/overlays/kill/kill_headshot.vmt","materials/overlays/kill/kill_knife.vmt","materials/overlays/kill/kill_grenade.vmt",
"materials/overlays/kill/kill_1.vtf","materials/overlays/kill/kill_2.vtf",
"materials/overlays/kill/kill_3.vtf","materials/overlays/kill/kill_4.vtf","materials/overlays/kill/kill_headshot.vtf","materials/overlays/kill/kill_knife.vtf","materials/overlays/kill/kill_grenade.vtf"};

enum {
	kill_1,
	kill_2,
	kill_3,
	kill_4,
	kill_headshot,
	kill_knife,
	kill_grenade
};

new Handle:g_taskCountdown[33] = INVALID_HANDLE,Handle:g_taskClean[33] = INVALID_HANDLE;
new Handle:g_killCount[33];

public Plugin:myinfo = 
{
	name = "killmessage_overlays",
	author = "wTong",
	description = "CSOL Killed Message",
	version = "1.0",
	url = "www.modchina.com"
}

public OnPluginStart()
{
	// Add your own code here...
	RegConsoleCmd("r_screenoverlay", Command_overlay);
	HookEvent("player_death", Event_PlayerDeath);
	ServerCommand("sv_cheats 0");
}

public OnMapStart()
{
	new String:overlays_file[64];
	for(new i = 0;i<sizeof(SND_KILLVOICE);i++)
	{
		PrecacheSound(SND_KILLVOICE[i],true);
		
		Format(overlays_file,sizeof(overlays_file),"%s.vtf",NAME_OVERLAYS[i]);
		PrecacheDecal(overlays_file,true);
		Format(overlays_file,sizeof(overlays_file),"%s.vmt",NAME_OVERLAYS[i]);
		PrecacheDecal(overlays_file,true);
	}
}

public Action:Command_overlay(client,args)
{
	new String:command[64];
	GetCmdArg(1, command, sizeof(command))

	if(StrEqual(command,"")) return;
	
	new bool:bChange =false;
	for(new i = 0;i<sizeof(NAME_OVERLAYS);i++)
	{
		if(StrEqual(command,NAME_OVERLAYS[i]))
		{
			bChange =true;
			break;
		}
	}
	
	if(g_taskClean[client] !=INVALID_HANDLE && !bChange)
	{
		KillTimer(g_taskClean[client]);
		g_taskClean[client] =INVALID_HANDLE;
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new bool:headshot = GetEventBool(event, "headshot");
	new String:weapon[32];
	GetEventString(event, "weapon",weapon, sizeof(weapon));
	
	g_killCount[victim] = 0;
	if(g_taskCountdown[victim] !=INVALID_HANDLE)
	{
		KillTimer(g_taskCountdown[victim]);
		g_taskCountdown[victim] =INVALID_HANDLE;
	}
	
	if(attacker <1) return;
	
	if(g_killCount[attacker] <4) 
		g_killCount[attacker]++;
	
	if(g_taskCountdown[attacker] !=INVALID_HANDLE)
	{
		KillTimer(g_taskCountdown[attacker]);
		g_taskCountdown[attacker] =INVALID_HANDLE;
	}
	g_taskCountdown[attacker] = CreateTimer(3.0,task_Countdown,attacker,1);
	
	if(g_killCount[attacker] == 1)
	{
		if(StrEqual(weapon,"hegrenade"))
			ShowKillMessage(attacker,kill_grenade);
		else if(StrEqual(weapon,"knife"))
			ShowKillMessage(attacker,kill_knife);
		else if(headshot)
			ShowKillMessage(attacker,kill_headshot);
		else
			ShowKillMessage(attacker,kill_1);
	}
	else if(g_killCount[attacker] == 2)
	{
		ShowKillMessage(attacker,kill_2);
	}
	else if(g_killCount[attacker] == 3)
	{
		ShowKillMessage(attacker,kill_3);
	}
	else if(g_killCount[attacker] == 4)
	{
		ShowKillMessage(attacker,kill_4);
	}
	
	if(g_taskClean[attacker] !=INVALID_HANDLE)
	{
		KillTimer(g_taskClean[attacker]);
		g_taskClean[attacker] =INVALID_HANDLE;
	}
	g_taskClean[attacker] = CreateTimer(3.0,task_Clean,attacker);
}

public Action:task_Countdown(Handle:Timer, any:client)
{
	g_killCount[client] --;
	if(!IsPlayerAlive(client) || g_killCount[client]==0)
	{
		KillTimer(Timer);
		g_taskCountdown[client] = INVALID_HANDLE;
	}
}

public Action:task_Clean(Handle:Timer, any:client)
{
	KillTimer(Timer);
	g_taskClean[client] = INVALID_HANDLE;
	
	ClientCommand(client, "r_screenoverlay \"\"");
}

public ShowKillMessage(client,type)
{
	ClientCommand(client,"speak %s",SND_KILLVOICE[type]);
	if(!IsZoomRifle(client)&&IsClientZooming(client))
		return;
	ClientCommand(client, "r_screenoverlay \"%s\"",NAME_OVERLAYS[type]);
}

public OnClientDisconnect_Post(client)
{
	if(g_taskCountdown[client] !=INVALID_HANDLE)
	{
		KillTimer(g_taskCountdown[client]);
		g_taskCountdown[client] =INVALID_HANDLE;
	}
	
	if(g_taskClean[client] !=INVALID_HANDLE)
	{
		KillTimer(g_taskClean[client]);
		g_taskClean[client] =INVALID_HANDLE;
	}
}

stock IsClientZooming(client)
{
	if(0<GetClientFOV(client)<90) 
		return true;
	
	return false;
}

stock IsZoomRifle(client)
{
	new weapon = GetClientWeaponID(client);
	if(weapon == CSW_AUG || weapon == CSW_SG552)
		return true;
	
	return false;
}