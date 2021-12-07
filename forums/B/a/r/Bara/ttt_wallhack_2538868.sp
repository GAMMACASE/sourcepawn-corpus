#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#include <ttt_shop>
#include <ttt>
#include <config_loader>
#include <CustomPlayerSkins>
#include <multicolors>

#pragma newdecls required

#define SHORT_NAME_T "wh_t"
#define SHORT_NAME_D "wh_d"
#define LONG_NAME "Wallhack"

#define PLUGIN_NAME TTT_PLUGIN_NAME ... " - Items: " ... LONG_NAME

int g_iColorInnocent[3] =  {0, 255, 0};
int g_iColorTraitor[3] =  {255, 0, 0};
int g_iColorDetective[3] =  {0, 0, 255};

int g_iTraitorPrice = -1;
int g_iDetectivePrice = -1;

int g_iTraitor_Prio = -1;
int g_iDetective_Prio = -1;

float g_fTraitorCooldown = -1.0;
float g_fDetectiveCooldown = -1.0;

float g_fTraitorActive = -1.0;
float g_fDetectiveActive = -1.0;

bool g_bOwnWH[MAXPLAYERS + 1] =  { false, ... };
bool g_bHasWH[MAXPLAYERS + 1] =  { false, ... };

char g_sConfigFile[PLATFORM_MAX_PATH];

Handle g_hTimer[MAXPLAYERS + 1] =  { null, ... };

bool g_bCPS = false;

bool g_bDebug = true;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = TTT_PLUGIN_AUTHOR,
	description = TTT_PLUGIN_DESCRIPTION,
	version = TTT_PLUGIN_VERSION,
	url = TTT_PLUGIN_URL
};

public void OnPluginStart()
{
	TTT_IsGameCSGO();

	BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/ttt/wh.cfg");

	Config_Setup("TTT-Wallhack", g_sConfigFile);
	
	g_iTraitorPrice = Config_LoadInt("wh_traitor_price", 9000, "The amount of credits the Traitor-Wallhack costs. 0 to disable.");
	g_iDetectivePrice = Config_LoadInt("wh_detective_price", 9000, "The amount of credits the Dective-Wallhack costs. 0 to disable.");
	
	g_fTraitorCooldown = Config_LoadFloat("wh_traitor_cooldown", 15.0, "Time of the cooldown for Traitor-Wallhack (time in seconds)");
	g_fDetectiveCooldown = Config_LoadFloat("wh_detective_cooldown", 15.0, "Time of the cooldown for Dective-Wallhack (time in seconds)");
	
	g_fTraitorActive = Config_LoadFloat("wh_traitor_active", 3.0, "Active time for Traitor-Wallhack (time in seconds)");
	g_fDetectiveActive = Config_LoadFloat("wh_detective_active", 3.0, "Active time for Dective-Wallhack (time in seconds)");
	
	g_iTraitor_Prio = Config_LoadInt("wh_traitor_sort_prio", 0, "The sorting priority of the Traitor - Wallhack in the shop menu.");
	g_iDetective_Prio = Config_LoadInt("wh_detective_sort_prio", 0, "The sorting priority of the Detective - Wallhack in the shop menu.");
	
	Config_Done();
	
	HookEvent("player_spawn", Event_PlayerReset);
	HookEvent("player_death", Event_PlayerReset);
	HookEvent("round_end", Event_RoundReset);
	
	g_bCPS = LibraryExists("CustomPlayerSkins");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "CustomPlayerSkins"))
	{
		g_bCPS = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "CustomPlayerSkins"))
	{
		g_bCPS = false;
	}
}

public void OnAllPluginsLoaded()
{
	if (g_bCPS)
	{
		TTT_RegisterCustomItem(SHORT_NAME_T, LONG_NAME, g_iTraitorPrice, TTT_TEAM_TRAITOR, g_iTraitor_Prio);
		TTT_RegisterCustomItem(SHORT_NAME_D, LONG_NAME, g_iDetectivePrice, TTT_TEAM_DETECTIVE, g_iDetective_Prio);
	}
	else
	{
		SetFailState("CustomPlayerSkins not loaded!");
	}
}

public Action Event_PlayerReset(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (TTT_IsClientValid(client))
	{
		g_bHasWH[client] = false;
		g_bOwnWH[client] = false;
		
		UnhookGlow(client);
	}
}

public Action Event_RoundReset(Event event, const char[] name, bool dontBroadcast)
{
	LoopValidClients(client)
	{
		g_bHasWH[client] = false;
		g_bOwnWH[client] = false;
		
		UnhookGlow(client);
	}
}

public void TTT_OnClientGetRole(int client, int role)
{
	SetupGlowSkin(client);
	if (g_bDebug && CheckCommandAccess(client, "sm_radmin", ADMFLAG_ROOT, true)) PrintToChat(client, "Pre SetupGlowSkin");
}

void SetupGlowSkin(int client)
{
	if (!TTT_IsClientValid(client) || !IsPlayerAlive(client) || !TTT_IsRoundActive())
	{
		return;
	}
	
	char sModel[PLATFORM_MAX_PATH];
	GetClientModel(client, sModel, sizeof(sModel));
	int iSkin = CPS_SetSkin(client, sModel, CPS_RENDER);
	
	if (iSkin == -1)
	{
		if (g_bDebug && CheckCommandAccess(client, "sm_radmin", ADMFLAG_ROOT, true)) PrintToChat(client, " FAILED SetupGlowSkin iSkin == -1");
		return;
	}
		
	if (SDKHookEx(iSkin, SDKHook_SetTransmit, OnSetTransmit_GlowSkin))
	{
		if (g_bDebug && CheckCommandAccess(client, "sm_radmin", ADMFLAG_ROOT, true)) PrintToChat(client, " SUCCESS SetupGlowSkin SDKHookEx");
		SetupGlow(client, iSkin);
	}
}

void SetupGlow(int client, int iSkin)
{
	int iOffset;
	
	if ((iOffset = GetEntSendPropOffs(iSkin, "m_clrGlow")) == -1)
	{
		return;
	}
	
	SetEntProp(iSkin, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(iSkin, Prop_Send, "m_nGlowStyle", 0);
	SetEntPropFloat(iSkin, Prop_Send, "m_flGlowMaxDist", 10000000.0);
	
	int iRed = 255;
	int iGreen = 255;
	int iBlue = 255;
	
	if (g_bDebug && CheckCommandAccess(client, "sm_radmin", ADMFLAG_ROOT, true)) PrintToChat(client, "SetupGlow");
	
	if (TTT_GetClientRole(client) == TTT_TEAM_DETECTIVE)
	{
		iRed = g_iColorDetective[0];
		iGreen = g_iColorDetective[1];
		iBlue = g_iColorDetective[2];
	}
	else if (TTT_GetClientRole(client) == TTT_TEAM_TRAITOR)
	{
		iRed = g_iColorTraitor[0];
		iGreen = g_iColorTraitor[1];
		iBlue = g_iColorTraitor[2];
	}
	else if (TTT_GetClientRole(client) == TTT_TEAM_INNOCENT)
	{
		iRed = g_iColorInnocent[0];
		iGreen = g_iColorInnocent[1];
		iBlue = g_iColorInnocent[2];
	}
	
	SetEntData(iSkin, iOffset, iRed, _, true);
	SetEntData(iSkin, iOffset + 1, iGreen, _, true);
	SetEntData(iSkin, iOffset + 2, iBlue, _, true);
	SetEntData(iSkin, iOffset + 3, 255, _, true);
}

public Action TTT_OnItemPurchased(int client, const char[] itemshort, bool count)
{
	if (TTT_IsClientValid(client) && IsPlayerAlive(client))
	{
		if (StrEqual(itemshort, SHORT_NAME_T, false) || StrEqual(itemshort, SHORT_NAME_D, false))
		{
			if (TTT_GetClientRole(client) != TTT_TEAM_TRAITOR && TTT_GetClientRole(client) != TTT_TEAM_DETECTIVE)
					return Plugin_Stop;
			
			g_bHasWH[client] = true;
			g_bOwnWH[client] = true;
			
			if (g_bDebug && CheckCommandAccess(client, "sm_radmin", ADMFLAG_ROOT, true)) PrintToChat(client, "TTT_OnItemPurchased");
			
			if (TTT_GetClientRole(client) == TTT_TEAM_TRAITOR)
			{
				g_hTimer[client] = CreateTimer(g_fTraitorActive, Timer_WHActive, GetClientUserId(client));
			}
			else if (TTT_GetClientRole(client) == TTT_TEAM_DETECTIVE)
			{
				g_hTimer[client] = CreateTimer(g_fDetectiveActive, Timer_WHActive, GetClientUserId(client));
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_WHActive(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if (TTT_IsClientValid(client) && g_bOwnWH[client] && g_bHasWH[client])
	{
		if (g_bDebug && CheckCommandAccess(client, "sm_radmin", ADMFLAG_ROOT, true)) PrintToChat(client, "WH deactived...");
		g_bHasWH[client] = false;
		g_hTimer[client] = null;
		
		if (TTT_GetClientRole(client) == TTT_TEAM_TRAITOR)
		{
			g_hTimer[client] = CreateTimer(g_fTraitorCooldown, Timer_WHCooldown, GetClientUserId(client));
		}
		else if (TTT_GetClientRole(client) == TTT_TEAM_DETECTIVE)
		{
			g_hTimer[client] = CreateTimer(g_fDetectiveCooldown, Timer_WHCooldown, GetClientUserId(client));
		}
	}
	
	return Plugin_Stop;
}

public Action Timer_WHCooldown(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if (TTT_IsClientValid(client) && g_bOwnWH[client] && !g_bHasWH[client])
	{
		if (g_bDebug && CheckCommandAccess(client, "sm_radmin", ADMFLAG_ROOT, true)) PrintToChat(client, "WH actived...");
		g_bHasWH[client] = true;
		g_hTimer[client] = null;
		
		if (TTT_GetClientRole(client) == TTT_TEAM_TRAITOR)
		{
			g_hTimer[client] = CreateTimer(g_fTraitorActive, Timer_WHActive, GetClientUserId(client));
		}
		else if (TTT_GetClientRole(client) == TTT_TEAM_DETECTIVE)
		{
			g_hTimer[client] = CreateTimer(g_fDetectiveActive, Timer_WHActive, GetClientUserId(client));
		}
	}
	
	return Plugin_Stop;
}

public Action OnSetTransmit_GlowSkin(int iSkin, int client)
{
	if (!TTT_IsRoundActive())
	{
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	
	if (!g_bOwnWH[client] ||!g_bHasWH[client])
	{
		return Plugin_Handled;
	}
	
	LoopValidClients(target)
	{
		if (target < 1)
		{
			continue;
		}
		
		if (!g_bDebug && IsFakeClient(target))
		{
			continue;
		}
		
		if (!IsPlayerAlive(target))
		{
			continue;
		}
		
		if (!CPS_HasSkin(target))
		{
			if (g_bDebug && CheckCommandAccess(client, "sm_radmin", ADMFLAG_ROOT, true)) PrintToChat(client, "%N hasn't a skin...", target);
			continue;
		}
		
		if (EntRefToEntIndex(CPS_GetSkin(target)) != iSkin)
		{
			continue;
		}
		
		if (g_bHasWH[client] && g_bOwnWH[client])
		{
			if (g_bDebug && CheckCommandAccess(client, "sm_radmin", ADMFLAG_ROOT, true)) PrintToChat(client, "You should see %N", target);
			return Plugin_Continue;
		}
	}
	
	return Plugin_Handled;
}

void UnhookGlow(int client)
{
	if (!TTT_IsClientValid(client))
	{
		return;
	}
		
	int iSkin = CPS_GetSkin(client);
	if (IsValidEntity(iSkin))
	{
		SetEntProp(iSkin, Prop_Send, "m_bShouldGlow", false, 1);
		SDKUnhook(iSkin, SDKHook_SetTransmit, OnSetTransmit_GlowSkin);
	}
}
