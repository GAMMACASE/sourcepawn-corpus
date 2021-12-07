/* Plugin Template generated by Pawn Studio */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions> 
public Plugin:myinfo = 
{
	name = "Evil Hunter",
	author = "Pan XiaoHai",
	description = "<- Description ->",
	version = "1.5",
	url = "<- URL ->"
}
new Handle:l4d_evil_hunter_chance;
public OnPluginStart()
{
	l4d_evil_hunter_chance = CreateConVar("l4d_evil_hunter_chance", "100.0", "chance of change target" );
	
	AutoExecConfig(true, "evil_hunter_l4d");	
	HookEvent("lunge_pounce", lunge_pounce);
	HookEvent("pounce_end", pounce_end );
 	
	HookEvent("round_start", round_start);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition",  round_end);	
	
}
public Action:round_start(Handle:event, const String:name[], bool:dontBroadcast)
{ 
	ResetAllState();
}
public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetAllState();
}
public OnMapStart()
{
	ResetAllState();
}
#define action_no 0
#define action_stop_pounce 1
#define action_move 2
#define action_attack 3

new HunterVictim[MAXPLAYERS+1];
new HunterAttacker[MAXPLAYERS+1];
new Float:HunterActionTime[MAXPLAYERS+1]; 
new Float:HunterAttackDir[MAXPLAYERS+1][3]; 
new HunterAction[MAXPLAYERS+1];
new HunterTick[MAXPLAYERS+1];
ResetAllState()
{
	for(new i=0; i<=MaxClients; i++)
	{
		HunterVictim[i]=0;
		HunterAttacker[i]=0;
		HunterAction[i]=action_no; 
	}
}
public lunge_pounce (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_evil_hunter_chance))
	{
		if(victim>0 && attacker>0 && IsFakeClient(attacker))
		{		
			HunterVictim[attacker]=victim;
			HunterAttacker[victim]=attacker; 
			HunterAction[attacker]=action_no;
			HunterActionTime[attacker]=GetEngineTime();
			HunterTick[attacker]=0;
			SetEntityMoveType(attacker, MOVETYPE_WALK); 
			//PrintToChatAll("lunge_pounce %N %N", attacker, victim);
		} 
	}
}
public pounce_end  (Handle:event, const String:name[], bool:dontBroadcast)
{ 
	new victim = GetClientOfUserId(GetEventInt(event, "victim")); 
	if(victim>0  )
	{
		new attacker=HunterAttacker[victim];
		HunterVictim[attacker]=0;
		HunterAttacker[victim]=0;
		SetEntityMoveType(attacker, MOVETYPE_WALK); 
		//PrintToChatAll("pounce_end  %N %N", stop, victim); 
	}
}
 
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(HunterAction[client]==action_stop_pounce)
	{
		if(!IsHunter(client))return StopHunter(client);
		new Float:time=GetEngineTime();
		if(time-HunterActionTime[client]>0.1)
		{
			HunterAction[client]=action_move;
			SetEntityMoveType(client, MOVETYPE_WALK); 
			HunterActionTime[client]=time;		
			//PrintToChatAll(" force jump %N", client); 
			buttons=0;  
			return Plugin_Changed; 
		}
		return Plugin_Continue;	
	}
	else if(HunterAction[client]==action_move)
	{
		if(!IsHunter(client))return StopHunter(client);
		new Float:time=GetEngineTime();
		HunterAction[client]=action_attack;		 
		HunterActionTime[client]=time;		
		//PrintToChatAll(" force attack %N", client);
		HunterTick[client]=0;
		buttons=  buttons | IN_ATTACK;
		buttons=  buttons | IN_DUCK;  
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, HunterAttackDir[client]);				
		return Plugin_Changed;	
	}
	else if(HunterAction[client]==action_attack)
	{
		if(!IsHunter(client))return StopHunter(client);
		new Float:time=GetEngineTime();
		if(time-HunterActionTime[client]>3.0)HunterAction[client]=action_no;
		//HunterAction[client]=action_no;
		HunterTick[client]++;
		buttons=0;  
		if(HunterTick[client]%2==0)
		{
			buttons=  buttons | IN_ATTACK;
			//PrintToChatAll("+");
		}
		else
		{
			buttons=  buttons & ~IN_ATTACK;
			//PrintToChatAll("-");
		}
		buttons=  buttons | IN_DUCK;  
		return Plugin_Changed; 
	}
	
	if(HunterVictim[client]==0)return Plugin_Continue;
	if(!IsHunter(client))return StopHunter(client);
		
	new Float:time=GetEngineTime();
	if(time-HunterActionTime[client]>0.2)
	{
		HunterActionTime[client]=time;
		new victim=HunterVictim[client];
		if(!IsSurvivor(victim))return StopHunter(client);
		new incap=GetEntProp(victim, Prop_Send, "m_isIncapacitated", 1);
		if(incap)
		{				
			if(HelperComing(client,victim))
			{
				HunterAction[client]=action_stop_pounce;
				SetEntityMoveType(client, MOVETYPE_NOCLIP);   
				//PrintToChatAll("force end %N", client);
			}			 
		}
	}
	 
	return Plugin_Continue;
}
Action:StopHunter(client)
{
	HunterVictim[client]=0; 
	HunterAction[client]=action_no;
	return Plugin_Continue;
}
bool:IsHunter(client)
{
	if(client>0 && IsClientInGame(client) && GetClientTeam(client)==3 && IsPlayerAlive(client))return true;
	return false;	
}
bool:IsSurvivor(client)
{
	if(client>0 && IsClientInGame(client) && GetClientTeam(client)==2 && IsPlayerAlive(client))return true;
	return false;	 
}
bool:HelperComing(hunter, victim)
{
	new count=0;
	decl Float:pos[3];
	decl Float:hunterPos[3];
	GetClientEyePosition(hunter,  hunterPos);
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client)==2 && IsPlayerAlive(client) && client!=victim)
		{
			if(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))continue;
			GetClientEyePosition(client,  pos);
			if(GetVectorDistance(pos, hunterPos)<300.0)
			{
				count++;
				//SubtractVectors(pos, hunterPos, HunterAttackDir[hunter]);
				HunterAttackDir[hunter][2]=0.0;
				HunterAttackDir[hunter][0]=GetRandomFloat(-1.0, 1.0);
				HunterAttackDir[hunter][1]=GetRandomFloat(-1.0, 1.0);
				NormalizeVector(HunterAttackDir[hunter],HunterAttackDir[hunter]);
				HunterAttackDir[hunter][2]=0.5;
				NormalizeVector(HunterAttackDir[hunter],HunterAttackDir[hunter]);
				ScaleVector(HunterAttackDir[hunter], 800.0);
				break;
			}
		}
	}
	return count>0;
}