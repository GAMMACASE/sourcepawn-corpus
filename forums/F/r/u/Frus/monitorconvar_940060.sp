/* Plugin Template generated by Pawn Studio */

#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Simple Single CVAR Monitor",
	author = "Frustian",
	description = "Monitors a single CVAR",
	version = "0.0.1",
	url = "<- URL ->"
}
new Handle:CVAR;
new Handle:Monitored
public OnPluginStart()
{
	CVAR = CreateConVar("sm_monitoredcvar", "z_ghost_speed", "CVAR to monitor",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	HookConVarChange(CVAR, OnCVARchange);
	decl String:CVARString[128];
	GetConVarString(CVAR, CVARString, sizeof(CVARString));
	Monitored = FindConVar(CVARString);
	HookConVarChange(Monitored, OnMonitoredchange);
}
public OnCVARchange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UnhookConVarChange(Monitored, OnMonitoredchange);
	Monitored = FindConVar(newVal);
	HookConVarChange(Monitored, OnMonitoredchange);
}
	
public OnMonitoredchange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:CVARString[128];
	GetConVarString(CVAR, CVARString, sizeof(CVARString));
	PrintToChatAll("%s has been changed to %s", CVARString, newVal);
}