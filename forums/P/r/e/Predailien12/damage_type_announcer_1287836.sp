#include <sourcemod>

public Plugin:myinfo =
{
	name = "������ Ȯ��",
	author = "Rayne",
	description = "������ Ÿ�� Ȯ���� �� �� �ְ��մϴ�.",
	version = "1.0.0",
	url = "",
}

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PH)
}

public Action:Event_PH(Handle:event, const String:event_name[], bool:dontBroadcast)
{
	new dmg_type = GetEventInt(event, "type")
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	PrintToChat(client, "\x03Damage Type: \x04%d", dmg_type)
}