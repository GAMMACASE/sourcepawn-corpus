#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
}
public Action:Knife(client, args)
{
	if (IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_knife")
		}
			else PrintToChat(client, "\x03 You must be alive to get a knife");
}