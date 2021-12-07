/*

    TF2 Medipacks - SourceMod Plugin
    Copyright (C) 2008  Marc H�rsken

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

*/

/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>

#define TF_SCOUT 1
#define TF_SNIPER 2
#define TF_SOLDIER 3 
#define TF_DEMOMAN 4
#define TF_MEDIC 5
#define TF_HEAVY 6
#define TF_PYRO 7
#define TF_SPY 8
#define TF_ENG 9
#define PL_VERSION "1.0.8"
#define SOUND_A "weapons/medigun_no_target.wav"
#define SOUND_B "items/spawn_item.wav"
#define SOUND_C "ui/hint.wav"

public Plugin:myinfo = 
{
	name = "TF2 Medipacks",
	author = "Hunter",
	description = "Allows medics to drop medipacks on death or with secondary Medigun fire.",
	version = PL_VERSION,
	url = "http://www.sourceplugins.de/"
}

new bool:g_IsRunning = true;
new bool:g_Medics[MAXPLAYERS+1];
new bool:g_MedicButtonDown[MAXPLAYERS+1];
new g_MedicUberCharge[MAXPLAYERS+1];
new Float:g_MedicPosition[MAXPLAYERS+1][3];
new g_MedipacksTime[2048];
new Handle:g_IsMedipacksOn = INVALID_HANDLE;
new Handle:g_MedipacksSmall = INVALID_HANDLE;
new Handle:g_MedipacksMedium = INVALID_HANDLE;
new Handle:g_MedipacksFull = INVALID_HANDLE;
new Handle:g_MedipacksKeep = INVALID_HANDLE;
new Handle:g_DefUberCharge = INVALID_HANDLE;
new g_FilteredEntity = -1;
new g_TF_ClassOffsets, g_TF_ChargeLevelOffset, g_TF_ChargeReleaseOffset, g_TF_CurrentOffset, g_TF_TeamNumOffset, g_ResourceEnt;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("medipacks.phrases");
	
	CreateConVar("sm_tf_medipacks", PL_VERSION, "Medipacks", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_IsMedipacksOn = CreateConVar("sm_medipacks","3","Enable/Disable medipacks (0 = disabled | 1 = on death | 2 = on command | 3 = on death and command)");
	g_MedipacksSmall = CreateConVar("sm_medipacks_small","10","UberCharge required for small Medipacks");
	g_MedipacksMedium = CreateConVar("sm_medipacks_medium","25","UberCharge required for medium Medipacks");
	g_MedipacksFull = CreateConVar("sm_medipacks_full","50","UberCharge required for full Medipacks");
	g_MedipacksKeep = CreateConVar("sm_medipacks_keep","60","Time to keep Medipacks on map. (0 = off | >0 = seconds)");
	g_DefUberCharge = CreateConVar("sm_medipacks_ubercharge","25","Give medics a default UberCharge on spawn");
	
	g_TF_ClassOffsets = FindSendPropOffs("CTFPlayerResource", "m_iPlayerClass");
	g_TF_ChargeLevelOffset = FindSendPropOffs("CWeaponMedigun", "m_flChargeLevel");
	g_TF_ChargeReleaseOffset = FindSendPropOffs("CWeaponMedigun", "m_bChargeRelease");
	g_TF_CurrentOffset = FindSendPropOffs("CBasePlayer", "m_hActiveWeapon");
	g_TF_TeamNumOffset = FindSendPropOffs("CTFItem", "m_iTeamNum");
	
	if (g_TF_ClassOffsets == -1)
		SetFailState("Cannot find TF2 m_iPlayerClass offset!")
	if (g_TF_ChargeLevelOffset == -1)
		SetFailState("Cannot find TF2 m_flChargeLevel offset!")
	if (g_TF_ChargeReleaseOffset == -1)
		SetFailState("Cannot find TF2 m_bChargeRelease offset!")
	if (g_TF_CurrentOffset == -1)
		SetFailState("Cannot find TF2 m_hActiveWeapon offset!")
	if (g_TF_TeamNumOffset == -1)
		SetFailState("Cannot find TF2 m_iTeamNum offset!")

	HookConVarChange(g_IsMedipacksOn, ConVarChange_IsMedipacksOn);
	HookConVarChange(g_MedipacksSmall, ConVarChange_MedipacksUber);
	HookConVarChange(g_MedipacksMedium, ConVarChange_MedipacksUber);
	HookConVarChange(g_MedipacksFull, ConVarChange_MedipacksUber);
	HookConVarChange(g_MedipacksKeep, ConVarChange_MedipacksKeep);
	HookConVarChange(g_DefUberCharge, ConVarChange_MedipacksUber);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_changeclass", Event_PlayerClass);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("teamplay_round_active", Event_RoundStart);
	RegConsoleCmd("sm_medipack", Command_Medipack)
	RegAdminCmd("sm_ubercharge", Command_UberCharge, ADMFLAG_CHEATS)
	
	CreateTimer(1.0, Timer_Caching, _, TIMER_REPEAT);
}

public OnMapStart()
{
	PrecacheModel("models/items/medkit_large.mdl", true);
	PrecacheModel("models/items/medkit_medium.mdl", true);
	PrecacheModel("models/items/medkit_small.mdl", true);
	PrecacheSound(SOUND_A, true);
	PrecacheSound(SOUND_B, true);
	PrecacheSound(SOUND_C, true);
	
	g_IsRunning = true;
	g_ResourceEnt = FindResourceObject();
}

public OnClientDisconnect(client)
{
	g_Medics[client] = false;
	g_MedicButtonDown[client] = false;
	g_MedicUberCharge[client] = 0;
	g_MedicPosition[client] = NULL_VECTOR;
}

public OnGameFrame()
{	
	if(!g_IsRunning)
		return;

	new MedipacksOn = GetConVarInt(g_IsMedipacksOn)
	if (MedipacksOn < 2)
		return;

	new maxclients = GetMaxClients();
	for (new i = 1; i <= maxclients; i++)
	{
		if (g_Medics[i] && !g_MedicButtonDown[i] && IsClientInGame(i))
		{
			if (GetClientButtons(i) & IN_ATTACK2)
			{
				g_MedicButtonDown[i] = true;
				CreateTimer(0.5, Timer_ButtonUp, i);
				new String:classname[64];
				TF_GetCurrentWeaponClass(i, classname, 64);
				if(StrEqual(classname, "CWeaponMedigun") && g_MedicUberCharge[i] < 100 && TF_IsUberCharge(i) == 0)
					TF_DropMedipack(i, true);
			}
		}
	}
}

public ConVarChange_IsMedipacksOn(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) > 0)
	{
		g_IsRunning = true
		PrintToChatAll("[SM] %t", "Enabled Medipacks");
		if (StringToInt(newValue) != StringToInt(oldValue))
			g_ResourceEnt = FindResourceObject();
	}
	else
	{
		g_IsRunning = false;
		PrintToChatAll("[SM] %t", "Disabled Medipacks");
	}
}

public ConVarChange_MedipacksUber(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) < 0 || StringToInt(newValue) > 100)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
	}
}

public ConVarChange_MedipacksKeep(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) < 0 || StringToInt(newValue) > 600)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
	}
}

public Action:Command_Medipack(client, args)
{
	if(!g_IsRunning)
		return Plugin_Handled;
	new MedipacksOn = GetConVarInt(g_IsMedipacksOn)
	if (MedipacksOn < 2)
		return Plugin_Handled;
	
	new class = TF_GetClass(client);
	if (class != TF_MEDIC)
		return Plugin_Handled;
	
	new String:classname[64];
	TF_GetCurrentWeaponClass(client, classname, 64);
	if(!StrEqual(classname, "CWeaponMedigun"))
		return Plugin_Handled;
	
	TF_DropMedipack(client, true);
	
	return Plugin_Handled;
}

public Action:Command_UberCharge(client, args)
{
	/* Show usage */
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] %t", "UberCharge Usage");
		return Plugin_Handled;
	}
 
	/* Get the arguments */
	new String:arg1[32], String:arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
 
	/* Try and find a matching player */
	new target = FindTarget(client, arg1);
	if (target == -1)
	{
		/* FindTarget() automatically replies with the 
		 * failure reason.
		 */
		return Plugin_Handled;
	}
	
	new String:name[MAX_NAME_LENGTH]
	GetClientName(target, name, sizeof(name))
	
	new bool:alive = IsPlayerAlive(target);
	if (!alive)
	{
		ReplyToCommand(client, "[SM] %t", "Cannot be performed on dead", name);
		return Plugin_Handled;
	}
	
	new class = TF_GetClass(target);
	if (class != TF_MEDIC)
	{
		ReplyToCommand(client, "[SM] %t", "Not a Medic", name);
		return Plugin_Handled;
	}
	
	new charge = 100;
	/* Validate charge amount */
	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2))
		charge = StringToInt(arg2)
		if (charge < 0 || charge > 100)
		{
			ReplyToCommand(client, "[SM] %t", "Invalid Amount");
			return Plugin_Handled;
		}
	}
 
	TF_SetUberLevel(target, charge)
	
	ReplyToCommand(client, "[SM] %t", "Changed UberCharge", name, charge)
	
	return Plugin_Handled;
}

public Action:Timer_Caching(Handle:timer)
{
	new maxclients = GetMaxClients();
	for (new i = 1; i <= maxclients; i++)
	{
		if (g_Medics[i] && IsClientInGame(i))
		{
			g_MedicUberCharge[i] = TF_GetUberLevel(i);
			GetClientAbsOrigin(i, g_MedicPosition[i]);
		}
	}
	new MedipacksKeep = GetConVarInt(g_MedipacksKeep)
	if (MedipacksKeep > 0)
	{
		new time = GetTime() - MedipacksKeep;
		for (new c = 0; c < 2048; c++)
		{
			if (g_MedipacksTime[c] != 0 && g_MedipacksTime[c] < time)
			{
				g_MedipacksTime[c] = 0;
				if (IsValidEntity(c))
				{
					new String:classname[64];
					GetEntityNetClass(c, classname, 64);
					if(StrEqual(classname, "CBaseAnimating"))
					{
						EmitSoundToAll(SOUND_C, c, _, _, _, 0.75);
						RemoveEdict(c);
					}
				}
			}
		}
	}
}

public Action:Timer_ButtonUp(Handle:timer, any:client)
{
	g_MedicButtonDown[client] = false;
}

public Action:Timer_PlayerDefDelay(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		new DefUberCharge = GetConVarInt(g_DefUberCharge);
		TF_SetUberLevel(client, DefUberCharge);
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new MedipacksOn = GetConVarInt(g_IsMedipacksOn)
	switch (MedipacksOn)
	{
		case 1:
			PrintToChatAll("[SM] %t", "OnDeath Medipacks");
		case 2:
			PrintToChatAll("[SM] %t", "OnCommand Medipacks");
		case 3:
			PrintToChatAll("[SM] %t", "OnDeathAndCommand Medipacks");
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new class = TF_GetClass(client);
	if (class != TF_MEDIC)
		return;
	
	CreateTimer(0.25, Timer_PlayerDefDelay, client);
}

public Action:Event_PlayerClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new class = GetEventInt(event, "class");
	if (class != TF_MEDIC)
	{
		g_Medics[client] = false;
		return;
	}
	g_Medics[client] = true;
	
	CreateTimer(0.25, Timer_PlayerDefDelay, client);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_IsRunning)
		return;
	new MedipacksOn = GetConVarInt(g_IsMedipacksOn)
	if (MedipacksOn < 1 || MedipacksOn == 2)
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!g_Medics[client] || !IsClientInGame(client))
		return;
	
	new class = TF_GetClass(client);	
	if (class != TF_MEDIC)
		return;
	
	TF_DropMedipack(client, false);
	return;
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client != 0)
	{
		new team = GetEventInt(event, "team");
		if (team < 2 && IsClientInGame(client))
		{
			g_Medics[client] = false;
			g_MedicButtonDown[client] = false;
			g_MedicUberCharge[client] = 0;
			g_MedicPosition[client] = NULL_VECTOR;
		}
	}
}

public bool:MedipackTraceFilter(ent, contentMask)
{
   return (ent == g_FilteredEntity) ? false : true;
}

stock FindResourceObject()
{
	new maxclients = GetMaxClients();
	new maxents = GetMaxEntities();
	new i, String:classname[64];
	for(i = maxclients; i <= maxents; i++)
	{
	 	if(IsValidEntity(i))
		{
			GetEntityNetClass(i, classname, 64);
			if(StrEqual(classname, "CTFPlayerResource"))
			{
				return i;
			}
		}
	}
	SetFailState("Cannot find TF2 player ressource prop!")
	return -1;
}

stock TF_SpawnMedipack(client, String:name[], bool:cmd)
{
	new Float:PlayerPosition[3];
	if (cmd)
		GetClientAbsOrigin(client, PlayerPosition);
	else
		PlayerPosition = g_MedicPosition[client];
		
	if (PlayerPosition[0] != 0.0 && PlayerPosition[1] != 0.0 && PlayerPosition[2] != 0.0 && IsEntLimitReached() == false)
	{
		PlayerPosition[2] += 4;
		g_FilteredEntity = client;
		if (cmd)
		{
			new Float:PlayerPosEx[3], Float:PlayerAngle[3], Float:PlayerPosAway[3];
			GetClientEyeAngles(client, PlayerAngle);
			PlayerPosEx[0] = Cosine((PlayerAngle[1]/180)*FLOAT_PI);
			PlayerPosEx[1] = Sine((PlayerAngle[1]/180)*FLOAT_PI);
			PlayerPosEx[2] = 0.0;
			ScaleVector(PlayerPosEx, 75.0);
			AddVectors(PlayerPosition, PlayerPosEx, PlayerPosAway);
			
			new Handle:TraceEx = TR_TraceRayFilterEx(PlayerPosition, PlayerPosAway, MASK_SOLID, RayType_EndPoint, MedipackTraceFilter);
			TR_GetEndPosition(PlayerPosition, TraceEx);
		}

		new Float:Direction[3];
		Direction[0] = PlayerPosition[0];
		Direction[1] = PlayerPosition[1];
		Direction[2] = PlayerPosition[2]-1024;
		new Handle:Trace = TR_TraceRayFilterEx(PlayerPosition, Direction, MASK_SOLID, RayType_EndPoint, MedipackTraceFilter);
		
		new Float:MediPos[3];
		TR_GetEndPosition(MediPos, Trace);
		MediPos[2] += 4;
		
		new Medipack = CreateEntityByName(name);
		DispatchKeyValue(Medipack, "OnPlayerTouch", "!self,Kill,,0,-1")
		if (DispatchSpawn(Medipack))
		{
			SetEntData(Medipack, g_TF_TeamNumOffset, 0, 4, true);
			TeleportEntity(Medipack, MediPos, NULL_VECTOR, NULL_VECTOR);
			EmitSoundToAll(SOUND_B, Medipack, _, _, _, 0.75);
			g_MedipacksTime[Medipack] = GetTime();
		}
	}
}

stock bool:IsEntLimitReached()
{
	new maxclients = GetMaxClients();
	new maxents = GetMaxEntities();
	new i, c = 0;
	for(i = maxclients; i <= maxents; i++)
	{
	 	if(IsValidEntity(i))
			c += 1;
	}
	if (c >= (maxents-16))
	{
		PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
		LogError("Entity limit is nearly reached: %d/%d", c, maxents);
		return true;
	}
	else
		return false;
}

stock TF_GetClass(client)
{
	return GetEntData(g_ResourceEnt, g_TF_ClassOffsets + (client*4), 4);
}

stock TF_IsUberCharge(client)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
		return GetEntData(index, g_TF_ChargeReleaseOffset, 1);
	return 0;
}

stock TF_GetUberLevel(client)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
		return RoundFloat(GetEntDataFloat(index, g_TF_ChargeLevelOffset)*100);
	return 0;
}

stock TF_SetUberLevel(client, uberlevel)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
	{
		g_MedicUberCharge[client] = uberlevel;
		SetEntDataFloat(index, g_TF_ChargeLevelOffset, uberlevel*0.01, true);
	}
}

stock TF_GetCurrentWeaponClass(client, String:name[], maxlength)
{
	new index = GetEntDataEnt(client, g_TF_CurrentOffset);
	if (index != 0)
		GetEntityNetClass(index, name, maxlength);
}

stock bool:TF_DropMedipack(client, bool:cmd)
{
	new charge;
	if (cmd)
		charge = TF_GetUberLevel(client);
	else
		charge = g_MedicUberCharge[client];
	new MedipacksSmall = GetConVarInt(g_MedipacksSmall);
	new MedipacksMedium = GetConVarInt(g_MedipacksMedium);
	new MedipacksFull = GetConVarInt(g_MedipacksFull);
	if (charge >= MedipacksFull && MedipacksFull != 0)
	{
		if (cmd)
			TF_SetUberLevel(client, (charge-MedipacksFull));
		TF_SpawnMedipack(client, "item_healthkit_full", cmd);
		return true;
	}
	else if (charge >= MedipacksMedium && MedipacksMedium != 0)
	{
		if (cmd)
			TF_SetUberLevel(client, (charge-MedipacksMedium));
		TF_SpawnMedipack(client, "item_healthkit_medium", cmd);
		return true;
	}
	else if (charge >= MedipacksSmall && MedipacksSmall != 0)
	{
		if (cmd)
			TF_SetUberLevel(client, (charge-MedipacksSmall));
		TF_SpawnMedipack(client, "item_healthkit_small", cmd);
		return true;
	}
	if (cmd)
	{
		EmitSoundToClient(client, SOUND_A, _, _, _, _, 0.75);
	//	PrintCenterText(client, "Not enough UberCharge!");
	}
	return false;
}