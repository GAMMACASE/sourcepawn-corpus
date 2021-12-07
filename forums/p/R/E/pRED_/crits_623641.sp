#include <sourcemod>
#include <tf2>

new Handle:crits = INVALID_HANDLE;
new Handle:chance = INVALID_HANDLE;
new Handle:crituber = INVALID_HANDLE;

#define PLUGIN_VERSION "0.2"

public Plugin:myinfo = 
{
	name = "SM Crits chance",
	author = "pRED*",
	description = "Change critical hit %",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	crits = CreateConVar("sm_crits_enabled", "1");
	chance = CreateConVar("sm_crits_chance", "1.00");
	crituber = CreateConVar("sm_crits_critskrieg", "1");
	
	CreateConVar("sm_crits_version", PLUGIN_VERSION, "Crits Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}


public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (!GetConVarBool(crits))
	{
		return Plugin_Continue;	
	}
	
	/* Crit uber? */
	if (GetConVarBool(crituber) && (GetEntProp(client, Prop_Send, "m_nPlayerCond") & 6144))
	{
		result = true
		return Plugin_Handled;
	}
	
	if (GetConVarFloat(chance) > GetRandomFloat(0.0, 1.0))
	{
		result = true;
		return Plugin_Handled;	
	}
	
	result = false;
	
	return Plugin_Handled;
}