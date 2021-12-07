/* Plugin Template generated by Pawn Studio
* V:0.1
* Initial Release
* 
*  */
#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"
#pragma semicolon 1
#include <sdktools>
#include <sourcemod>
#include <cstrike>
#define PLUGIN_VERSION "0.1"

public Plugin:myinfo = 
{
	name = "Nade Effects",
	author = "Keksmampfer",
	description = "Adds special effects to the explosion.",
	version = PLUGIN_VERSION,
	url = "NoURL"
}


new g_GlowSprite;

new Handle:g_version = INVALID_HANDLE;
new Handle:g_enable = INVALID_HANDLE;
new Handle:g_duration = INVALID_HANDLE;

public OnPluginStart()
{
	new String:fldr[64];
	
	GetGameFolderName(fldr, sizeof(fldr));
	
	if(strcmp(fldr, "cstrike") != 0)
	{
		LogMessage("Your mod isn't supported but the plugin tries to run. Look for fueature updates.");
		
	}
	g_version = CreateConVar("sm_nadeeffects_version", PLUGIN_VERSION, "Nade Effects Version", FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_enable = CreateConVar("sm_nadeeffects_enable", "1", "1 - Turn the plugin On\n0 - Turn the plugin OFF", _, true, 0.0, true, 1.0);
	g_duration = CreateConVar("sm_nadeeffects_duration", "3", "Duration of the effect in seconds", _, true, 0.0, true, 99.0);
	
	AutoExecConfig(true, "plugin.nadeeffects");
	
	HookEvent("player_hurt" , Event_hurt);
	
	SetConVarString(g_version, PLUGIN_VERSION);
}
public OnMapStart()
{
	g_GlowSprite = PrecacheModel("sprites/blueglow2.vmt");	
	
}

public Event_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(g_enable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new String:weapon[64];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		new clientteam = GetClientTeam(client);
		
		if( StrEqual(weapon,"hegrenade") && clientteam == CS_TEAM_T)
		{
			freeze(client, GetConVarFloat(g_duration));
		}
	}
}

freeze(client, Float:time)
{
	
	//taken from scripting/funcommands/ice.sp
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, 0, 128, 255, 192);
	
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);
	
	TE_SetupGlowSprite(vec, g_GlowSprite, time, 1.5, 50);
	TE_SendToAll();
	
	CreateTimer(time , UnfreezeClient, client); 
}

//taken from scripting/funcommands/ice.sp
public Action:UnfreezeClient(Handle:timer, any:data)
{
	new client = data;
	
	if (IsClientInGame(client))
	{
		new Float:vec[3];
		GetClientAbsOrigin(client, vec);
		vec[2] += 10;	
		
		GetClientEyePosition(client, vec);
		EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);
		
		SetEntityMoveType(client, MOVETYPE_WALK);
		
		SetEntityRenderColor(client, 255, 255, 255, 255);
		
	}
}