#pragma semicolon 1

#define DEBUG

#define PLUGIN "[L4D2] sv_steamgroup fixer" 
#define PLUGIN_AUTHOR "Visual77"
#define PLUGIN_VERSION "0.00"

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

ConVar g_hSteamGroupCvar;

public void OnPluginStart()
{
	g_hSteamGroupCvar = FindConVar("sv_steamgroup");
}

public void OnConfigsExecuted()
{
	char stringValue[128];
	g_hSteamGroupCvar.GetString(stringValue, sizeof(stringValue));
	
	int intValue = StringToInt(stringValue);
	
	LogMessage("Setting sv_steamgroup %d", intValue);

	g_hSteamGroupCvar.SetInt(intValue);
}