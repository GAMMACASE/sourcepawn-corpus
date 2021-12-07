//fixed array out of bounds error

#include <sourcemod>
#pragma semicolon 1
#define VERSION "0.9.7"

public Plugin:myinfo = {
	name = "L4D Broadcast",
	author = "Voiderest",
	description = "Displays extra info for kills and friendly fire.",
	version = VERSION,
	url = "N/A"
}

new Handle:broadcast=INVALID_HANDLE;
new Handle:broadcast_con=INVALID_HANDLE;
new Handle:broadcast_attack=INVALID_HANDLE;
new Handle:broadcast_victim=INVALID_HANDLE;
new Handle:kill_timers[MAXPLAYERS+1][3];
new kill_counts[MAXPLAYERS+1][3];

public OnPluginStart() {
	//create new cvars
	broadcast = CreateConVar("l4d_broadcast_kill", "1", "0: Off. 1: On. 2: Headshots only.",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,2.0);
	broadcast_con = CreateConVar("l4d_broadcast_con", "0", "Printing Console 0: Off 1: On",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);
	broadcast_attack = CreateConVar("l4d_broadcast_ff", "2", "Print to attacker. 0: Off 1: Hint 2: Hint + Chat 3: Chat",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,3.0);
	broadcast_victim = CreateConVar("l4d_broadcast_hit", "1", "Print to victims chat. 0: Off 1: On",FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);
	
	//hook events
	HookEvent("player_hurt", Event_Player_Hurt, EventHookMode_Post);
	HookEvent("player_death", Event_Player_Death, EventHookMode_Pre);
	
	AutoExecConfig(true,"l4d_broadcast");
}

public Action:Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast) {
	new attacker_userid = GetEventInt(event, "attacker");
	new attacker =  GetClientOfUserId(attacker_userid);
	new bool:headshot = GetEventBool(event, "headshot");
	
	if (attacker == 0 || GetClientTeam(attacker) == 1)
	{
		return Plugin_Continue;
	}
	
	printkillinfo(attacker, headshot);
	
	return Plugin_Continue;
}

printkillinfo(attacker, bool:headshot)
{
	new intbroad=GetConVarInt(broadcast);
	new murder;
	
	if ((intbroad >= 1) && headshot)
	{
		murder = kill_counts[attacker][0];
		
		if(murder>1)
		{
			PrintCenterText(attacker, "HEADSHOT! +%d", murder);
			KillTimer(kill_timers[attacker][0]);
		}
		else
		{
			PrintCenterText(attacker, "HEADSHOT!");
		}
		
		kill_timers[attacker][0] = CreateTimer(5.0, KillCountTimer, (attacker*10));
		kill_counts[attacker][0] = murder+1;
	}
	else if (intbroad == 1)
	{
		murder = kill_counts[attacker][1];
		
		if(murder>=1)
		{
			PrintCenterText(attacker, "KILL! +%d", murder);
			KillTimer(kill_timers[attacker][1]);
		}
		else
		{
			PrintCenterText(attacker, "KILL!");
		}
		
		kill_timers[attacker][1] = CreateTimer(5.0, KillCountTimer, ((attacker*10)+1));
		kill_counts[attacker][1] = murder+1;
	}
}

public Action:KillCountTimer(Handle:timer, any:info) {
	new id=info-(info%10);
	info=info-id;
	id=id/10;
	
	kill_counts[id][info]=0;
}

public Action:Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast) {
	
	new client_userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_userid);
	new attacker_userid = GetEventInt(event, "attacker");
	new attacker = GetClientOfUserId(attacker_userid);

	new ff_attack = GetConVarInt(broadcast_attack);
	new ff_victim = GetConVarInt(broadcast_victim);
	new ff_con = GetConVarInt(broadcast_con);
	
	//Kill everything if...
	if (attacker == 0 || client == 0 || GetClientTeam(attacker) != GetClientTeam(client) || (ff_attack == 0 && ff_victim == 0 && ff_con == 0))
	{
		return Plugin_Continue;
	}
	
	new id = kill_counts[attacker][2];
	kill_timers[attacker][2] = CreateTimer(5.0, KillCountTimer, ((attacker*10)+2));
	kill_counts[attacker][2] = client;
	
	new String:hit[32];
	switch (GetEventInt(event, "hitgroup"))
	{
		case 1:
		{
			hit="'s head";
		}
		case 2:
		{
			hit="'s chest";
		}
		case 3:
		{
			hit="'s stomach";
		}
		case 4:
		{
			hit="'s left arm";
		}
		case 5:
		{
			hit="'s right arm";
		}
		case 6:
		{
			hit="'s left leg";
		}
		case 7:
		{
			hit="'s right leg";
		}
		default:
		{}
	}
	
	//new String:buf[128];
	//Format(buf, 128, "%N hit %N%s.", attacker, client, hit);
	//PrintToServer(buf);
	
	if ((ff_attack == 1 || ff_attack == 2) && (id != client))
	{
		PrintHintText(attacker, "You hit %N.", client);
	}
	
	if (ff_attack == 2 || ff_attack == 3)
	{
		PrintToChat(attacker, "You hit %N%s.", client, hit);
	}
	else if (ff_con == 1)
	{
		PrintToConsole(attacker, "You hit %N%s.", client, hit);
	}
	
	ReplaceString(hit, 32, "'s", "r");
	if (ff_victim == 1)
	{
		PrintToChat(client, "%N hit you%s.", attacker, hit);
	}
	else if (ff_con == 1)
	{
		PrintToConsole(client, "%N hit you%s.", attacker, hit);
	}
	
	return Plugin_Continue;
}
