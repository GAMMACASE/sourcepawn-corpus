/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <tf2_stocks>
#include <tf2>

//////////////////////////////////////////////////////
// ABOUT
//
//This plugin specifically targets the heavy glitch.
//The Heavy glitch allows him to move at faster than normal
//speeds while having the minigun revved up.
//
//How To Reproduce Glitch:
// 1. Go Heavy
// 2. Spin up MiniGun (do not release Mouse2)
// 3. Change Secondary or Melee weapon in spawn (do NOT release Mouse2)
// 4. You can now move walking speed while having MiniGun revved up
//
// Glitch resets once Mouse2 is released
//
///////////////////////////////////////////////////////
#define PLUGIN_VERSION "1.0.2"

new Handle:c_Enabled   = INVALID_HANDLE;
new m_hActiveWeapon;
new m_flMaxspeed;
	
public Plugin:myinfo = 
{
	name = "[TF2] Heavy Glitch Fix",
	author = "Fox",
	description = "Prevents fast Heavy glitch",
	version = PLUGIN_VERSION,
	url = "http://www.rtdgaming.com"
}

public OnPluginStart()
{
	
	//HookEvent("player_spawn", Event_ApplySlowDown, EventHookMode_Post);
	HookEvent("post_inventory_application", Event_ApplySlowDown); 
	
	CreateConVar("sm_heavyglitchfix_version", PLUGIN_VERSION, "[TF2]Prevents fast Heavy glitch", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	c_Enabled   = CreateConVar("sm_heavyglitchfix_enable",    "1",        "<0/1> Enable Heavy Glitch Fix");
	
	HookConVarChange(c_Enabled,	ConVarChange);
	
	m_hActiveWeapon = FindSendPropInfo("CTFPlayer", "m_hActiveWeapon");
	m_flMaxspeed = FindSendPropInfo("CTFPlayer", "m_flMaxspeed")
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == c_Enabled)
	{
		if(GetConVarInt(c_Enabled))
		{
			PrintCenterTextAll("Heavy Glitch Fix: ENABLED");
		}else{
			PrintCenterTextAll("Heavy Glitch Fix: DISABLED");
		}
	}
}

public Action:Event_ApplySlowDown(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	if(!GetConVarInt(c_Enabled))
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client)
		return;
	
	
	//is player heavy?
	if(TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		new iWeapon = GetEntDataEnt2(client, m_hActiveWeapon)
		if(IsValidEntity(iWeapon))
		{
			if(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") == 15 || GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") == 41)
			{
				new m_IdealActivity = GetEntProp(iWeapon, Prop_Data, "m_IdealActivity") ;
				//PrintToChat(client, "m_IdealActivity: %i", m_IdealActivity);
				
				//Player is not revving up or shooting
				if(m_IdealActivity == 173 || m_IdealActivity == 171)
					return;
					
				CreateTimer(0.0, Timer_ResetSpeed, client);
				TF2_AddCondition(client, TFCond_Slowed, 99.1);
			}
		}
	}
}

public Action:Timer_ResetSpeed(Handle:Timer, any:client)
{
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	if(TF2_GetPlayerClass(client) != TFClass_Heavy)
		return Plugin_Stop;
	
	
	//Player is revving up the minigun. His speed must be 
	//80 or else this player is most likely exploiting
	if(GetEntDataFloat(client,FindSendPropInfo("CTFPlayer", "m_flMaxspeed")) == 230)
	{
		TF2_AddCondition(client, TFCond_Slowed, 99.1);
		SetEntData(client, m_flMaxspeed, 110.0);
		
		new String:clsteamId[64];
		new String:clientname[32];
		
		GetClientAuthString(client, clsteamId, sizeof(clsteamId));
		GetClientName(client, clientname, sizeof(clientname));
		
		PrintToChatAll("\x04[Exploit]\x03 %s (%s) has attempted Heavy speed exploit", clientname, clsteamId);
		LogMessage("[Exploit] %s (%s) as attempted Heavy speed exploit", clientname, clsteamId);
	}
	
	return Plugin_Stop;
}