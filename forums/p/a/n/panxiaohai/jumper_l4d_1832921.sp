/* Plugin Template generated by Pawn Studio */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions> 
#include <sdkhooks>
 

#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6

new ZOMBIECLASS_TANK=	5;
new GameMode;
new L4D2Version;

public Plugin:myinfo = 
{
	name = "A new method of battle �� kick",
	author = "Pan XiaoHai",
	description = "<- Description ->",
	version = "1.1",
	url = "<- URL ->"
}
new Handle:l4d_jumper_force;
new Handle:l4d_jumper_enable;
new Handle:l4d_jumper_delay;
new Handle:l4d_jumper_damage;

new Handle:l4d_jumper_kicktank;
new Handle:l4d_jumper_kickwitch;
new Handle:l4d_jumper_kickrock;

new Handle:SdkShove = INVALID_HANDLE;
new Handle:SdkFling = INVALID_HANDLE;
new Handle:SdkStartActivationTimer=INVALID_HANDLE;
new Handle:SdkOnPummelEnded=INVALID_HANDLE;
new g_PointHurt;
public OnPluginStart()
{
	GameCheck();
	if(!L4D2Version)
	{
		SetFailState("l4d2 only");
		return ;
	}
	SetupSDKCall();
	l4d_jumper_force = CreateConVar("l4d_jumper_force", "150.0", " jump force [50.0, 200.0]" );
	l4d_jumper_enable = CreateConVar("l4d_jumper_enable", "1", "0:disable, 1:enable" );
	l4d_jumper_delay = CreateConVar("l4d_jumper_delay", "0.6", "[0.5, 3.0]" );
	l4d_jumper_damage = CreateConVar("l4d_jumper_damage", "100.0", "damage to infected [50.0, 200.0]" );	 	
	
	l4d_jumper_kicktank = CreateConVar("l4d_jumper_kicktank", "1", "0:disable, 1:enable [0, 1]" );
	l4d_jumper_kickwitch = CreateConVar("l4d_jumper_kickwitch", "1", "0:disable, 1:enable [0, 1]" );
	l4d_jumper_kickrock = CreateConVar("l4d_jumper_kickrock", "1", "0:disable, 1:enable [0, 1]" );


	AutoExecConfig(true, "jumper_l4d");	
 
	HookEvent("round_start", round_start);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition",  round_end);	
	
	HookEvent("player_spawn", player_spawn);
	HookEvent("player_death", player_death);
	 
 
	HookEvent("player_bot_replace", player_bot_replace );	  
	HookEvent("bot_player_replace", bot_player_replace ); 	
 
	RegConsoleCmd("sm_jumper", sm_jumper);
	ResetAllState();
	
}
 
new ClientEnable[MAXPLAYERS+1];

new Float:Energe[MAXPLAYERS+1];    
 
new LastButton[MAXPLAYERS+1]; 
new Float:LastTime[MAXPLAYERS+1] ; 
new Attacker[MAXPLAYERS+1];   
new Float:AttackTime[MAXPLAYERS+1] ; 
new Float:NextShoveTime[MAXPLAYERS+1];
new Float:ShoveTime[MAXPLAYERS+1];
new Float:ShoveDelay[MAXPLAYERS+1];
new Float:JumpTime[MAXPLAYERS+1];
new Float:JumpOnGroundTime[MAXPLAYERS+1];
new Float:KeyPressedTime[MAXPLAYERS+1] ;
new EnemyList[MAXPLAYERS+1][MAXPLAYERS+1];


new bool:AttackDisable[MAXPLAYERS+1];
new Float:AttackDisableTime[MAXPLAYERS+1] ;
public Action:player_spawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client  = GetClientOfUserId(GetEventInt(event, "userid"));
  	if(client>0 )
	{
		ResetClientState(client);
	}
  	return Plugin_Continue;
}
public Action:player_death(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client  = GetClientOfUserId(GetEventInt(event, "userid"));
  	if(client>0 )
	{
		ResetClientState(client);
	}
  	return Plugin_Continue;
}
public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
 	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));   
 
	if(client>0 && bot>0)
	{ 
		ResetClientState(client);
		ResetClientState(bot);
	}
 
} 
public bot_player_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
 	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));   
	 
	if(client>0 && bot>0)
	{
		ResetClientState(client);
		ResetClientState(bot);
	}
 
} 

public lunge_pounce (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	 
	if(victim>0 && attacker>0 )
	{		
		Energe[victim]=0.0;
		Attacker[victim]=attacker; 
		AttackTime[victim]=GetEngineTime(); 
		//PrintToChatAll("lunge_pounce %N %N", attacker, victim);
	}  
}
 
public tongue_grab (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
 
	if(victim>0 && attacker>0 )
	{	
		Energe[victim]=0.0;
		Attacker[victim]=attacker; 
		AttackTime[victim]=GetEngineTime(); 
		//PrintToChatAll("tongue_grab %N %N", attacker, victim);
	}  
	
}
public jockey_ride (Handle:event, const String:name[], bool:dontBroadcast)
{ 
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	 
	if(victim>0 && attacker>0)
	{	
		Energe[victim]=0.0;
		Attacker[victim]=attacker; 
		AttackTime[victim]=GetEngineTime(); 
	
	} 
 
}
public charger_pummel_start (Handle:event, const String:name[], bool:dontBroadcast)
{ 
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	 
	if(victim>0 && attacker>0 )
	{	
		Energe[victim]=0.0;
		Attacker[victim]=attacker; 
		AttackTime[victim]=GetEngineTime();   
	} 
	//PrintToChatAll("charger start");
}
public Action:player_ledge_grab(Handle:event, String:event_name[], bool:dontBroadcast)
{ 
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	 
	if(victim>0 ) 
	{
		if(Attacker[victim]==0)Energe[victim]=0.0;
		if(Attacker[victim]==0)Attacker[victim]=victim; 
		AttackTime[victim]=GetEngineTime(); 
 	}
}


public player_incapacitated (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	 
	if(victim>0 ) 
	{
		if(Attacker[victim]==0)Energe[victim]=0.0;
		if(Attacker[victim]==0)Attacker[victim]=victim; 
		AttackTime[victim]=GetEngineTime(); 
 	}
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


ResetAllState()
{
	g_PointHurt=0;
	for(new i=0; i<=MaxClients; i++)
	{
		ResetClientState(i);
		ClientEnable[i]=0;
		JumpTime[i]=0.0;
		JumpOnGroundTime[i]=0.0;
		
		AttackDisableTime[i]=0.0;
		AttackDisable[i]=false;
	}
} 
ResetClientState(client)
{ 
	KeyPressedTime[client]=0.0;
	Energe[client]=0.0;
	Attacker[client]=0;
	LastTime[client]=0.0;
	LastButton[client]=0;
	
	NextShoveTime[client]=0.0;
	ShoveTime[client]=0.0;
	ShoveDelay[client]=100.0;
	
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		//SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
}
 
new Float:g_MaxEnerge;

Fling2(victim,  Float:force  )
{ 
	force=210.0;
	if(SdkFling==INVALID_HANDLE)return;	  
 
	decl Float:dir[3]; 
	GetClientEyeAngles(victim, dir); 
	dir[0]= 0.0;
	//GetAngleVectors(dir,  NULL_VECTOR,  dir,  NULL_VECTOR);
	GetAngleVectors(dir,  dir,NULL_VECTOR  ,  NULL_VECTOR);
	NormalizeVector(dir, dir);
	//ScaleVector(dir, -1.0);
	PrintVector("dir", dir);
	ScaleVector(dir, force);
	SDKCall(SdkFling, victim, dir, 86, victim, 2.0); // 96 95 98 80 81 back  82 84  jump 86 roll 87 88 91 92 jump 93 
}
Fling3(victim,  Float:force, Float:dir[3])
{ 
	
	if(SdkFling==INVALID_HANDLE)return;	   
	decl Float:vec[3]; 
	CopyVector(dir, vec);
	NormalizeVector(vec,vec);
	ScaleVector(vec, force);
	SDKCall(SdkFling, victim, vec, 86, victim, 2.0); // 96 95 98 80 81 back  82 84  jump 86 roll 87 88 91 92 jump 93 
}
CalcDir(client, Float:front, Float:right, Float:dir[3])
{
	decl Float:vec_front[3]; 
	decl Float:vec_right[3]; 
	GetClientEyeAngles(client, dir); 
	if(front>=0.0 && dir[0]>-20.0)
	{
		//PrintToChatAll("ajust");
		dir[0]= -10.0;
	}
	GetAngleVectors(dir,  vec_front ,NULL_VECTOR  ,  NULL_VECTOR);
	GetAngleVectors(dir,  NULL_VECTOR ,vec_right  ,  NULL_VECTOR);
	
	NormalizeVector(vec_front, vec_front);
	NormalizeVector(vec_right, vec_right);
	
	ScaleVector(vec_front, front);
	ScaleVector(vec_right, right);
	AddVectors(vec_front,vec_right,dir);
	NormalizeVector(dir,dir);
	//PrintVector("front", vec_front);
	//PrintVector("right", vec_right);
}
public OnTouch(client, other)
{ 
	if(GetEngineTime()-JumpTime[client]<0.5)
	{
		if(other>0)
		{
			new count=EnemyList[client][0];
			new bool:find=false;
			for(new i=1; i<=count && i<=MAXPLAYERS; i++)
			{
				if(other==EnemyList[client][i])
				{
					find=true;
					break;
				}
			}
			if(!find)
			{
				EnemyList[client][count+1]=other;
				EnemyList[client][0]++;
			 
			
				//PrintToChatAll("time %f %d", GetEngineTime()-JumpTime[client], other);
				//PrintToChatAll("%N touch %d", client, other);
				if(other>0 && other <=MaxClients)
				{
					//PrintToChatAll("%N touch %N", client, other);
					new class = GetEntProp(other, Prop_Send, "m_zombieClass");
					
					if(class==ZOMBIECLASS_TANK)
					{
						if(GetConVarInt(l4d_jumper_kicktank)==1)Shove2(other, client , -1.0);
						DoPointHurtForInfected(other, client, GetConVarFloat(l4d_jumper_damage), 1);
						PrintToChatAll("IS TANK");
					}
					else
					{
						Shove2(other, client , -1.0);
						DoPointHurtForInfected(other, client, GetConVarFloat(l4d_jumper_damage), 1);
						//PrintToChatAll("time %f %d %N", GetEngineTime()-JumpTime[client], other, other);
						//Fling(other, client, 200.0);
				
					}
					
				}
				else if(other>0)
				{
					decl String:classname[64];
					GetEdictClassname(other, classname, 64);	
					if(StrContains(classname, "witch")!=-1 )
					{
						if(GetConVarInt(l4d_jumper_kickwitch)==1)DoPointHurtForInfected(other, client, GetConVarFloat(l4d_jumper_damage), 1);						
						else DoPointHurtForInfected(other, client, GetConVarFloat(l4d_jumper_damage), 0);
					}
					else if(StrContains(classname, "infected")!=-1 || StrContains(classname, "player")!=-1)
					{
						//PrintToChatAll("time %f %d %s", GetEngineTime()-JumpTime[client], other, classname);
						DoPointHurtForInfected(other, client, GetConVarFloat(l4d_jumper_damage), 1);
					}
					else if((GetClientButtons(client) & IN_ATTACK2) && StrContains(classname, "prop_physics")!=-1)ThrowEnt(client, other, 1000.0);
					 
				}
				//decl Float:pos[3];
				//GetEntPropVector(other, Prop_Send, "m_vecOrigin", pos);   
				//
			}
		}
		
	}
	else SDKUnhook(client, SDKHook_Touch, OnTouch);
	
}
public Action:sm_jumper(client,args)
{ 
	ClientEnable[client]=!ClientEnable[client];
	if(ClientEnable[client])
	{
		PrintToChatAll("you can kick infected by press shift");
	}
	
}
GetAttacker(client)
{
	new attacker=0;
	new m_pounceAttacker=GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	new m_tongueOwner=GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	new m_isIncapacitated=GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
	new m_isHangingFromLedge=GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1);	
	
	if(m_isIncapacitated>0)attacker=m_isIncapacitated;
	if(m_isHangingFromLedge>0)attacker=m_isHangingFromLedge;	 
	if(L4D2Version)
	{
		new m_pummelAttacker=GetEntPropEnt(client, Prop_Send, "m_pummelAttacker" );
		new m_jockeyAttacker=GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker" );
		
		if(m_pounceAttacker>0)attacker=m_pounceAttacker;
		else if(m_tongueOwner>0)attacker=m_tongueOwner;
		else if(m_pummelAttacker>0)attacker=m_pummelAttacker;
		else if(m_jockeyAttacker>0)attacker=m_jockeyAttacker;

	 
	}
	else
	{
		if(m_pounceAttacker>0)attacker=m_pounceAttacker;
		else if(m_tongueOwner>0)attacker=m_tongueOwner; 

	}		
	return attacker;
}
 
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{

	if(!ClientEnable[client])return Plugin_Continue;
	new bool:a2=(buttons & IN_SPEED) && !(LastButton[client] & IN_SPEED) ;
	new bool:jump=(buttons & IN_JUMP)  ;
	new Float:time=GetEngineTime();
	new Float:duration=time-JumpTime[client];
	
	if(duration<0.3)
	{
		
	}
	if((a2) && duration>GetConVarFloat(l4d_jumper_delay) && GetAttacker(client)==0 && IsPlayerAlive(client))
	{
		 
		JumpTime[client]=time;
		 
		
		new Float:move_front=vel[0];
		if(move_front>0.0)move_front=1.0;
		else if(move_front<0.0)move_front=-1.0;
		else move_front=0.0;

		new Float:move_right=vel[1];
		if(move_right>0.0)move_right=1.0;
		else if(move_right<0.0)move_right=-1.0;
		else move_right=0.0;
	 
		decl Float:dir[3]; 
		CalcDir(client, move_front, move_right, dir);
		
		//Fling2(client, 200.0);
		if(move_front<0.0)Fling3(client, GetConVarFloat(l4d_jumper_force)*0.5, dir);
		else Fling3(client, GetConVarFloat(l4d_jumper_force), dir);
		
		for(new i=0; i<MAXPLAYERS; i++)
		{
			EnemyList[client][i]=0;
		}
		SDKUnhook(client, SDKHook_Touch, OnTouch);
		SDKHook(client, SDKHook_Touch , OnTouch); 
	}
	LastButton[client]=buttons;
	return Plugin_Continue;
	 
	 
}
 
 
bool:IsInfected(client, type=0)
{
	
	if(client>0 && IsClientInGame(client) && GetClientTeam(client)==3 && IsPlayerAlive(client))
	{
		PrintToChatAll("is %N", client);
		if(type!=0)
		{
			new class = GetEntProp(client, Prop_Send, "m_zombieClass");
			if(type==class)return true;
		}
		return true;
	}
	return false;	
}
 

PrintVector(String:s[], Float:target[3])
{
	PrintToChatAll("%s - %f %f %f", s, target[0], target[1], target[2]); 
}
CopyVector(Float:source[3], Float:target[3])
{
	target[0]=source[0];
	target[1]=source[1];
	target[2]=source[2];
}
SetVector(Float:target[3], Float:x, Float:y, Float:z)
{
	target[0]=x;
	target[1]=y;
	target[2]=z;
}

GameCheck()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	
	
	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		GameMode = 1;
	else
	{
		GameMode = 0;
 	}
	GameMode=GameMode+0;
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		ZOMBIECLASS_TANK=8;
		L4D2Version=true;
 
	}	
	else
	{
 
		L4D2Version=false;
 
	}
 
}
 
 

SetupSDKCall()
{
	if(L4D2Version)
	{
		StartPrepSDKCall(SDKCall_Player);
		if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x81\xEC\x2A\x2A\x2A\x2A\x56\x8B\xF1\xE8\x2A\x2A\x2A\x2A\x84\xC0\x0F\x2A\x2A\x2A\x2A\x2A\x8B\x8C\x2A\x2A\x2A\x2A\x2A\x55\x33\xED\x3B\xCD\x74", 35))
		{
			PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer18OnShovedBySurvivorEPS_RK6Vector", 0);
		} 
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		SdkShove = EndPrepSDKCall();
		if(SdkShove == INVALID_HANDLE)
		{
			PrintToServer("Unable to find the 'shove' signature");
		}
		
		StartPrepSDKCall(SDKCall_Player);
		if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x81\xEC\x2A\x2A\x2A\x2A\x55\x57\x8B\xE9\x33\xFF\x57\x89\x2A\x2A\x2A\xE8", 18))
		{
			PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer5FlingERK6Vector17PlayerAnimEvent_tP20CBaseCombatCharacterf", 0);
		} 
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		SdkFling = EndPrepSDKCall();
		if(SdkFling == INVALID_HANDLE)
		{
			PrintToServer("Unable to find the 'CTerrorPlayer_Fling' signature, check the file version!");
 		}	
		
		StartPrepSDKCall(SDKCall_Entity);
		if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\xD9\xEE\xD9\x44\x24\x08\xDD\xE1\xDF\xE0\xDD\xD9\xF6\xC4\x44\x7A\x18\xDD", 18))
		{
			PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN12CBaseAbility20StartActivationTimerEff", 0);
		} 
		 
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);

		SdkStartActivationTimer = EndPrepSDKCall();
		if(SdkStartActivationTimer == INVALID_HANDLE)
		{
			PrintToServer("Unable to find the 'CBaseAbility::StartActivationTimer' signature, check the file version!");
 		}	
		
		
		StartPrepSDKCall(SDKCall_Player);
		if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x8B\x15****\x56\x8B\xF1\x8B\x86\x40\x3E\x00\x00\x83", 12))
		{
			PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer13OnPummelEndedEbPS_", 0);
		} 
        PrepSDKCall_AddParameter(SDKType_Bool,SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_CBasePlayer,SDKPass_Pointer,VDECODE_FLAG_ALLOWNULL);
        SdkOnPummelEnded = EndPrepSDKCall();
		if(SdkOnPummelEnded == INVALID_HANDLE)
		{
			PrintToServer("Unable to find the 'CTerrorPlayer::OnPummelEnded' signature, check the file version!");
 		}   
		
	}
	else
	{
		StartPrepSDKCall(SDKCall_Player);
		if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x81\xEC\x2A\x2A\x2A\x2A\x56\x8B\xF1\xE8\x2A\x2A\x2A\x2A\x84\xC0\x0F\x2A\x2A\x2A\x2A\x2A\x8B\x8C\x2A\x2A\x2A\x2A\x2A\x85\xC9\x74", 32))
		{
			PrepSDKCall_SetSignature(SDKLibrary_Server, "_ZN13CTerrorPlayer18OnShovedBySurvivorEPS_RK6Vector", 0);
		} 
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		SdkShove = EndPrepSDKCall();
		if(SdkShove == INVALID_HANDLE)
		{
			PrintToServer("Unable to find the 'shove' signature");
		}		
		SdkFling=INVALID_HANDLE; 
	} 	
}
Fling(victim,  attacker, Float:force  )
{ 
	if(SdkFling==INVALID_HANDLE)return;	  
	decl Float:victimpos[3];
	decl Float:attackerpos[3];
	decl Float:dir[3]; 
	GetClientAbsOrigin(attacker, attackerpos);
	if(victim<=MaxClients)
	{
		GetClientEyePosition(victim, victimpos);	
	}
	else 
	{
		
		GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimpos); 
	}
	SubtractVectors(victimpos, attackerpos,dir);
	NormalizeVector(dir, dir);
	
	ScaleVector(dir, force);
	SDKCall(SdkFling, victim, dir, 96, attacker, 2.0); // 96
}

Shove(victim, attacker, direction=1 )
{
	decl Float:victimpos[3];
	decl Float:attackerpos[3];
	decl Float:dir[3]; 
	GetClientAbsOrigin(attacker, attackerpos);
	GetClientAbsOrigin(victim, victimpos);	
	SubtractVectors(victimpos, attackerpos,dir);
	if(direction<0)ScaleVector(dir, -1.0);
	SDKCall(SdkShove, victim, attacker,  dir);
}
ShoveDir(victim, attacker,   Float:dir[3] )
{ 
	SDKCall(SdkShove, victim, attacker,  dir);
}
Shove2(victim, attacker ,  direction=1)
{ 
	decl Float:dir[3]; 
	GetClientAbsAngles(victim, dir);
	GetAngleVectors(dir,dir, NULL_VECTOR,NULL_VECTOR);
	NormalizeVector(dir,dir);
	if(direction<0)ScaleVector(dir,  -1.0);
	SDKCall(SdkShove, victim, attacker,  dir);
}
  

CreatePointHurt()
{
	new pointHurt=CreateEntityByName("point_hurt");
	if(pointHurt)
	{		
		DispatchKeyValue(pointHurt,"Damage","10");
		if(L4D2Version)	DispatchKeyValue(pointHurt,"DamageType","-2130706430"); 
		DispatchSpawn(pointHurt);
	}
	return pointHurt;
}
new String:N[10];
DoPointHurtForInfected(victim, attacker=0, Float:FireDamage, type)
{
	if(g_PointHurt > 0)
	{
		if(IsValidEdict(g_PointHurt))
		{
			if(victim>0 && IsValidEdict(victim))
			{		
				{
						
						Format(N, 20, "target%d", victim);
						DispatchKeyValue(victim,"targetname", N);
						DispatchKeyValue(g_PointHurt,"DamageTarget", N); 
						
						
						DispatchKeyValueFloat(g_PointHurt,"Damage", FireDamage);
						 
						
						if(L4D2Version)
						{				
							//if(victim<=MaxClients)type=0;
							if(type==0)DispatchKeyValue(g_PointHurt,"DamageType","-2130706430"); 
							else if(type==1)DispatchKeyValue(g_PointHurt,"DamageType"," -2122317758"); 	//explosive
							DispatchKeyValueFloat(g_PointHurt,"Damage", FireDamage); 
						}
						else
						{
							if(victim<=MaxClients)type=0;
							if(type==0)
							{
								new h=GetEntProp(victim, Prop_Data, "m_iHealth"); 
								if(h*1.0<=FireDamage)  DispatchKeyValue(g_PointHurt, "DamageType", "64");
								else  DispatchKeyValue(g_PointHurt, "DamageType", "-1073741822"); 
							}
							else if(type==1)
							{
								DispatchKeyValue(g_PointHurt, "DamageType", "8"); 
							}
							else if(type==2)
							{
								DispatchKeyValue(g_PointHurt, "DamageType", "64"); 
							}
						}
						AcceptEntityInput(g_PointHurt,"Hurt",(attacker>0)?attacker:-1);
						if(victim<MaxClients)
						{
							new h=GetClientHealth(victim);
							if(h*1.0<=FireDamage)
							{
								PrintToChatAll("%N killed %N by kick", attacker, victim);
							}
						}
					}
			}
		}
		else g_PointHurt=CreatePointHurt();
	}
	else g_PointHurt=CreatePointHurt();
}
ThrowEnt(client, ent, Float:force)
{	
	//PrintToChat(client, "throw");

	//return;
	decl String:classname[64];
	GetEdictClassname(ent, classname, 64);		
	//PrintToChatAll("THROWN %s", classname);
	 
	if(StrContains(classname, "prop_")!=-1)
	{
		//SetEntPropEnt(ent, Prop_Data, "m_hPhysicsAttacker", client);
		//SetEntPropFloat(ent, Prop_Data, "m_flLastPhysicsInfluenceTime", GetEngineTime());
		decl Float:vAngles[3];
		decl Float:vOrigin[3];
		decl Float:pos[3];
		GetClientEyePosition(client,vOrigin);
		GetClientEyeAngles(client, vAngles);
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos); 

		decl Float:volicity[3];
		SubtractVectors(pos, vOrigin, volicity);
		NormalizeVector(volicity, volicity);
		ScaleVector(volicity, force);
		TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, volicity);
	}
}