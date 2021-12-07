 /* Plugin Template generated by Pawn Studio */

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "Radio Spam Block",
	author = "exvel",
	description = "Blocking players from radio spam. Also can disable radio commands for all players on the server if option is set.",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

new last_radio_use[65];
new note[65];
new Handle:cvar_radio_spam_block = INVALID_HANDLE;
new Handle:cvar_radio_spam_block_time = INVALID_HANDLE;
new Handle:cvar_radio_spam_block_all = INVALID_HANDLE;
new Handle:cvar_radio_spam_block_notify = INVALID_HANDLE;
new bool:notify = true;

public OnPluginStart()
{
	CreateConVar("sm_radio_spam_block_version", PLUGIN_VERSION, "Radio Spam Block Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvar_radio_spam_block = CreateConVar("sm_radio_spam_block", "1", "0 = disabled, 1 = enabled Radio Spam Block functionality", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_radio_spam_block_time = CreateConVar("sm_radio_spam_block_time", "5", "Time in seconds between radio messages", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	cvar_radio_spam_block_all = CreateConVar("sm_radio_spam_block_all", "0", "0 = disabled, 1 = block all radio messages", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_radio_spam_block_notify = CreateConVar("sm_radio_spam_block_notify", "1", "0 = disabled, 1 = show a chat message to the player when his radio spam blocked", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	for (new i = 0; i < 64; i++)
	{
		last_radio_use[i] = -1;
	}
	
	RegConsoleCmd("InsRadial", RestrictRadio);
	
	LoadTranslations("radiospamblock.phrases.txt");
}

public Action:RestrictRadio(client ,args)
{
	if (!GetConVarBool(cvar_radio_spam_block))
	{
		return Plugin_Continue;
	}
	
	notify = GetConVarBool(cvar_radio_spam_block_notify);
	
	if(GetConVarBool(cvar_radio_spam_block_all))
	{
		
		if (notify)
		{
			PrintToChat(client, "[SM] %t", "Disabled");
			return Plugin_Handled;
		}
		else
		{
			return Plugin_Handled;
		}
	}
	
	if (last_radio_use[client] == -1)
	{
		last_radio_use[client] = GetTime();
		return Plugin_Continue;
	}
	
	new time = GetTime() - last_radio_use[client];
	new block_time = GetConVarInt(cvar_radio_spam_block_time);
	if ( time >= block_time )
	{
		last_radio_use[client] = GetTime();
		return Plugin_Continue;
	}
	
	new wait_time = block_time - time;
		
	if ( (note[client] != wait_time) && notify)
	{
		if (wait_time <= 1)
		{
			PrintToChat(client, "[SM] %t", "Wait 1 second");
		}
		else
		{
			PrintToChat(client, "[SM] %t", "Wait X seconds", wait_time);
		}
	}
	
	note[client] = wait_time;
	return Plugin_Handled;
}