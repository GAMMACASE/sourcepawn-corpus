/* Plugin Template generated by Pawn Studio */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions> 
static any:g_GameInstructor[MAXPLAYERS + 1];
 

#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6

new GameMode;
new L4D2Version;

public Plugin:myinfo = 
{
	name = "Struggle",
	author = "Pan XiaoHai & $atanic $pirit",
	description = "<- Description ->",
	version = "1.1",
	url = "<- URL ->"
}
new Handle:l4d_struggle_difficulty;
new Handle:l4d_struggle_enable;
new Handle:l4d_struggle_duration;
new Handle:l4d_struggle_mode;
new Handle:l4d_struggle_key;
new Handle:l4d_struggle_delay_ability;

public OnPluginStart()
{
	GameCheck();
	SetupSDKCall();
	l4d_struggle_difficulty = CreateConVar("l4d_struggle_difficulty", "0.0", "struggle difficulty, [easy, hard]  [0.0, 1.0]" );
	l4d_struggle_enable = CreateConVar("l4d_struggle_enable", "1", "0:disable, 1:eanble " );
	l4d_struggle_duration = CreateConVar("l4d_struggle_duration", "3.0", "[short time, long time] [3.0, 8.0]" );
	l4d_struggle_delay_ability = CreateConVar("l4d_struggle_delay_ability", "1.0", "0.0:do not reset infected's ability, [0.0, 5.0]seconds, l4d2 only" );
	l4d_struggle_mode = CreateConVar("l4d_struggle_mode", "3", "1:all, 2:struggle when incapped, 3:struggle when grabbed, pounced,..." );
	l4d_struggle_key = CreateConVar("l4d_struggle_key", "3", "1:space only, 2:movement keys only, 3, mouse only" );

	AutoExecConfig(true, "struggle_l4d");	
 
	HookEvent("round_start", round_start);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition",  round_end);	
	
	HookEvent("player_spawn", player_spawn);
	HookEvent("player_death", player_death);
	
	HookEvent("tongue_grab", tongue_grab);
 
	HookEvent("lunge_pounce", lunge_pounce);

	HookEvent("player_ledge_grab", player_ledge_grab); 
 	
	HookEvent("player_incapacitated", player_incapacitated);
	
	if(L4D2Version)
	{
		HookEvent("jockey_ride", jockey_ride);  
		HookEvent("charger_pummel_start", charger_pummel_start);  
	}	
	
 
	HookEvent("player_bot_replace", player_bot_replace );	  
	HookEvent("bot_player_replace", bot_player_replace ); 	
 
	//RegConsoleCmd("sm_s", sm_s);
}
public Action:sm_s(client,args)
{
	Shove2(client, client);
	CallResetAbility(client, 1.0); 
}
new Float:Energe[MAXPLAYERS+1];    
 
new LastButton[MAXPLAYERS+1]; 
new Float:LastTime[MAXPLAYERS+1] ; 
new Attacker[MAXPLAYERS+1];   
new Float:AttackTime[MAXPLAYERS+1] ; 
    
new Float:KeyPressedTime[MAXPLAYERS+1] ;
  
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
	new mode=GetConVarInt(l4d_struggle_mode);
	new bool:modeAttack=(mode==1 || mode==3);
	if(victim>0 && attacker>0 && modeAttack)
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
	new mode=GetConVarInt(l4d_struggle_mode);
	new bool:modeAttack=(mode==1 || mode==3);
	if(victim>0 && attacker>0 && modeAttack)
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
	new mode=GetConVarInt(l4d_struggle_mode);
	new bool:modeAttack=(mode==1 || mode==3);	
	if(victim>0 && attacker>0 && modeAttack)
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
	new mode=GetConVarInt(l4d_struggle_mode);
	new bool:modeAttack=(mode==1 || mode==3);		
	if(victim>0 && attacker>0 && modeAttack)
	{	
		Energe[victim]=0.0;
		Attacker[victim]=attacker; 
		AttackTime[victim]=GetEngineTime();   
	} 
 
}
public Action:player_ledge_grab(Handle:event, String:event_name[], bool:dontBroadcast)
{ 
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new mode=GetConVarInt(l4d_struggle_mode);
	new bool:modeIncap=(mode==1 || mode==2);
	if(victim>0  &&  modeIncap) 
	{
		if(Attacker[victim]==0)Energe[victim]=0.0;
		if(Attacker[victim]==0)Attacker[victim]=victim; 
		AttackTime[victim]=GetEngineTime(); 
 	}
}


public player_incapacitated (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new mode=GetConVarInt(l4d_struggle_mode);
	new bool:modeIncap=(mode==1 || mode==2);
	if(victim>0  && modeIncap ) 
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
	for(new i=0; i<=MaxClients; i++)
	{
		ResetClientState(i);
	}
} 
ResetClientState(client)
{ 
	KeyPressedTime[client]=0.0;
	Energe[client]=0.0;
	Attacker[client]=0;
	LastTime[client]=0.0;
	LastButton[client]=0;
}
 
new Float:g_MaxEnerge;
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(Attacker[client]==0) return Plugin_Continue;		
	if(GetConVarInt(l4d_struggle_enable)==0) return Plugin_Continue;		
	new attacker=0;
	if((GetClientTeam(client)==2 || GetClientTeam(client)==4) && IsPlayerAlive(client) && !IsFakeClient(client))
	{ 
	
	}
	else 
	{
		ResetClientState(client);
		return Plugin_Continue;	
	}
	new mode=GetConVarInt(l4d_struggle_mode);
	new bool:modeIncap=(mode==1 || mode==2);
	new bool:modeAttack=(mode==1 || mode==3);
	
	new m_pounceAttacker=GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	new m_tongueOwner=GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	new m_isIncapacitated=GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
	new m_isHangingFromLedge=GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1);	
	 
	if(L4D2Version)
	{
		new m_pummelAttacker=GetEntPropEnt(client, Prop_Send, "m_pummelAttacker" );
		new m_jockeyAttacker=GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker" );
		
		if(m_pounceAttacker>0 && modeAttack)attacker=m_pounceAttacker;
		else if(m_tongueOwner>0 && modeAttack)attacker=m_tongueOwner;
		else if(m_pummelAttacker>0 && modeAttack)attacker=m_pummelAttacker;
		else if(m_jockeyAttacker>0 && modeAttack)attacker=m_jockeyAttacker;
		else if(m_isIncapacitated>0 && modeIncap)attacker=client;
		else if(m_isHangingFromLedge>0 && modeIncap)attacker=client;
	 
	}
	else
	{
		if(m_pounceAttacker>0 && modeAttack)attacker=m_pounceAttacker;
		else if(m_tongueOwner>0 && modeAttack)attacker=m_tongueOwner; 
		else if(m_isIncapacitated>0 && modeIncap)attacker=client;
		else if(m_isHangingFromLedge>0 && modeIncap)attacker=client;
	}		
	
	new Float:time=GetEngineTime();  
	new Float:intervual=time-LastTime[client];
	LastTime[client]=time;	
	if(attacker==0)
	{ 
		AttackTime[client]+=intervual;
		
		if(AttackTime[client]>0.5)
		{
			if(L4D2Version)SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
			ResetClientState(client);
			
		}
		return Plugin_Continue;	
	}
	Attacker[client]=attacker;
	g_MaxEnerge=GetConVarFloat(l4d_struggle_duration);
	
	//PrintToChatAll("attackr %d", attacker);
 
	AttackTime[client]=0.0;
	
	new lastButton=LastButton[client]; 
	LastButton[client]=buttons;
	
	if(intervual<0.0)intervual=0.01;
	else if(intervual>1.0)intervual=0.01;
   
  	new Float:lastPressTime=KeyPressedTime[client];
	new bool:press=false;
	// "1:all, 2:space only, 3:movement keys only, 4, mouse only" )
	new keyMode=GetConVarInt(l4d_struggle_key);
	new bool:keyModeSpace=(keyMode==1 );
	new bool:keyModeMovement=(keyMode==2);
	new bool:keyModeMouse=(keyMode==3);
	new Float:factor=0.65;
	 
	if(keyModeSpace )
	{
		if((buttons & IN_JUMP) && !(lastButton & IN_JUMP))press=true; 
		
	} 	
	if(keyModeMovement )
	{
		if((buttons & IN_FORWARD) && !(lastButton & IN_FORWARD))press=true; 
		else if((buttons & IN_BACK) && !(lastButton & IN_BACK))press=true; 
		else if((buttons & IN_MOVELEFT) && !(lastButton & IN_MOVELEFT))press=true;
		else if((buttons & IN_MOVERIGHT) && !(lastButton & IN_MOVERIGHT))press=true;
		factor/=4.0;
	} 	
	if(keyModeMouse )
	{
		if((buttons & IN_ATTACK) && !(lastButton & IN_ATTACK))press=true; 
		else if((buttons & IN_ATTACK2) && !(lastButton & IN_ATTACK2))press=true;  
		factor/=3.0;
	} 	
	if(press)
	{  
		KeyPressedTime[client]=time;
		new Float:diff=GetConVarFloat(l4d_struggle_difficulty);
		if(diff<0.0)diff=0.0;
		else if(diff>1.0)diff=1.0;
		new Float:duration=time-lastPressTime;
		duration*=10.0;
		if(duration<0.8)duration=0.8;
		else if(duration>2.0)duration=2.0;
		duration=(2.0-duration)/(2.0-0.8);
		if(duration>0.0)
		{ 			 
			Energe[client]+= Pow(duration, 2.0+diff*6.0) *factor;  
			//PrintToChatAll("duration %f %f", duration, Pow(duration, 5.0));
		} 
		if(duration>0.5)
		{
			Struggle(client, attacker);
		}
		if(Energe[client]>=g_MaxEnerge)	
		{
			if(IsInfected(attacker))
			{ 
				Energe[client]=0.0;
				StopAttack(client, attacker);
			}
			else if(attacker==client)
			{
				Energe[client]=0.0;
				ReviveClient(client);
			} 
		} 
	}
	else
	{
		new Float:duration=time-lastPressTime;
		if(duration>0.2)Energe[client]-=intervual*2.0;
	}
	
	if(Energe[client]<0.0)Energe[client]=0.0;
	else if(Energe[client]>g_MaxEnerge)Energe[client]=g_MaxEnerge;
	ShowHud(client);
	return Plugin_Continue;
}
Struggle(client, attacker)
{
	if(L4D2Version)
	{
		new attackerClass = GetEntProp(attacker, Prop_Send, "m_zombieClass"); 
		if(attackerClass==ZOMBIECLASS_SMOKER)
		{
			//Shove(client, attacker );
		}
	 
	}
	else
	{
		new attackerClass = GetEntProp(attacker, Prop_Send, "m_zombieClass"); 
		if(attackerClass==ZOMBIECLASS_SMOKER)
		{
			Shove(client, attacker );
		} 
	}	
	//PrintToChatAll("Struggle");
	return;
	
}
StopAttack(client, attacker)
{
	if(L4D2Version || true)
	{ 
		new attackerClass = GetEntProp(attacker, Prop_Send, "m_zombieClass"); 
		new Float:delay=GetConVarFloat(l4d_struggle_delay_ability);
		if(attackerClass==ZOMBIECLASS_CHARGER)
		{
			CallOnPummelEnded(attacker);
			Shove2(attacker, client , -1);  			
			Shove2(client, attacker , -1);
			if(delay>0)CallResetAbility(attacker, delay); 
		}
		else if(attackerClass==ZOMBIECLASS_HUNTER)
		{
			CallOnPounceEnd(attacker);
			Shove3(attacker, client);  
			Shove3(client, attacker); 
			if(delay>0)CallResetAbility(attacker, delay); 
		}	
		else if(attackerClass==ZOMBIECLASS_SMOKER)
		{
			Shove3(attacker, client);  
			Shove3(client, attacker);   
			if(delay>0)CallResetAbility(attacker, delay); 
		}	
		else if(attackerClass==ZOMBIECLASS_JOCKEY)
		{ 
			ExecuteCommand(attacker, "dismount");  
			Shove2(client, attacker );
			Shove2(attacker, client );
			new Float:v[3];
			GetClientEyeAngles(client, v);
			GetAngleVectors(v, v, NULL_VECTOR,NULL_VECTOR);
			v[2]=0.0;
			NormalizeVector(v,v);
			new Float:force=600.0;
			ScaleVector(v, 0.0-force);
			v[2]=force*0.7;
			TeleportEntity(attacker, NULL_VECTOR,NULL_VECTOR, v);	
			if(delay>0)CallResetAbility(attacker, delay); 
		}	
	}
	else
	{
		//new attackerClass = GetEntProp(attacker, Prop_Send, "m_zombieClass"); 
		
		Shove(attacker, client );
		 
		new Float:v[3];
		GetClientEyeAngles(client, v);
		GetAngleVectors(v, v, NULL_VECTOR,NULL_VECTOR);
		v[2]=0.0;
		NormalizeVector(v,v);
		new Float:force=600.0;
		ScaleVector(v, 0.0-force);
		v[2]=force*0.7;
		TeleportEntity(attacker, NULL_VECTOR,NULL_VECTOR, v);
	}
	//PrintToChatAll("StopAttack");
}
ReviveClient(client)
{ 
	//Shove2(client, client );
	new propincapcounter = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
	new count = GetEntData(client, propincapcounter, 1);
	count++;
	if(count>2)count=2;
	CheatCommand(client, "give", "health", "");
	
	SetEntData(client, propincapcounter,count, 1);
	
	new Handle:revivehealth = FindConVar("pain_pills_health_value");  
	new temphpoffset = FindSendPropOffs("CTerrorPlayer","m_healthBuffer");
	SetEntDataFloat(client, temphpoffset, GetConVarFloat(revivehealth), true);
	SetEntityHealth(client, 1);
}
stock CheatCommand(client, String:command[], String:parameter1[], String:parameter2[])
{
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, parameter1, parameter2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}
public Action:ResetMoveType(Handle:timer,any:client)
{
	if(IsInfected(client))
	{
		SetEntityMoveType(client, MOVETYPE_WALK);  
	}
}
bool:IsInfected(client, type=0)
{
	if(client>0 && IsClientInGame(client) && GetClientTeam(client)==3 && IsPlayerAlive(client))
	{
		if(type!=0)
		{
			new class = GetEntProp(client, Prop_Send, "m_zombieClass");
			if(type==class)return true;
		}
		return true;
	}
	return false;	
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
 
		L4D2Version=true;
 
	}	
	else
	{
 
		L4D2Version=false;
 
	}
 
}
 
ShowHud(client)
{	
	if(L4D2Version )
	{
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime()-Energe[client]);
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", g_MaxEnerge);
		if(Energe[client]<=0.0)
		{
			new keyMode=GetConVarInt(l4d_struggle_key);
			if(keyMode==1 )PrintCenterText(client, "Press [Space key] to Struggle");
			if(keyMode==2 )PrintCenterText(client, "Press [Movement Keys] to Struggle");
			if(keyMode==3 )
			{
				QueryClientConVar(client, "gameinstructor_enable", ConVarQueryFinished:GameInstructor, client);
				ClientCommand(client, "gameinstructor_enable 1");
				CreateTimer(0.5, DisplayInstructorHint, client);
			}
			
		}
	}
	else ShowBar(client );
}

public Action:DisplayInstructorHint(Handle:h_Timer, any:i_Client)
{
	decl i_Ent, String:s_TargetName[32], String:s_Message[256], Handle:h_Pack;
	
	i_Ent = CreateEntityByName("env_instructor_hint");
	FormatEx(s_TargetName, sizeof(s_TargetName), "hint%d", i_Client);
	FormatEx(s_Message, sizeof(s_Message), "Rapidly press Left or Right Click to struggle!");
	ReplaceString(s_Message, sizeof(s_Message), "\n", " ");
	DispatchKeyValue(i_Client, "targetname", s_TargetName);
	DispatchKeyValue(i_Ent, "hint_target", s_TargetName);
	DispatchKeyValue(i_Ent, "hint_timeout", "5");
	DispatchKeyValue(i_Ent, "hint_range", "0.01");
	DispatchKeyValue(i_Ent, "hint_icon_onscreen", "icon_alert_red");
	DispatchKeyValue(i_Ent, "hint_caption", s_Message);
	DispatchKeyValue(i_Ent, "hint_color", "255 0 0");
	DispatchSpawn(i_Ent);
	AcceptEntityInput(i_Ent, "ShowHint");
	
	h_Pack = CreateDataPack();
	WritePackCell(h_Pack, i_Client);
	WritePackCell(h_Pack, i_Ent);
	CreateTimer(5.0, RemoveInstructorHint, h_Pack);
}

public Action:RemoveInstructorHint(Handle:h_Timer, Handle:h_Pack)
{
	decl i_Ent, i_Client;
	
	ResetPack(h_Pack, false);
	i_Client = ReadPackCell(h_Pack);
	i_Ent = ReadPackCell(h_Pack);
	CloseHandle(h_Pack);
	
	if (!i_Client || !IsClientInGame(i_Client))
		return Plugin_Handled;
	
	if (IsValidEntity(i_Ent))
		RemoveEdict(i_Ent);
	
	if (!g_GameInstructor[i_Client])
		ClientCommand(i_Client, "gameinstructor_enable 0");
	
	return Plugin_Continue;
}

public GameInstructor(QueryCookie:q_Cookie, i_Client, ConVarQueryResult:c_Result, const String:s_CvarName[], const String:s_CvarValue[])
{
	g_GameInstructor[i_Client] = StringToInt(s_CvarValue);
}

new String:Gauge1[2] = "#";
new String:Gauge2[2] = "="; 
ShowBar(client)	 
{
	
	new Float:pos= Energe[client];
	new Float:max= g_MaxEnerge;
	new i ;
	decl String:ChargeBar[51];
	Format(ChargeBar, sizeof(ChargeBar), "");
 
	new Float:GaugeNum = pos/max*100;
	if(GaugeNum > 100.0)
		GaugeNum = 100.0;
	if(GaugeNum<0.0)
		GaugeNum = 0.0; 
	new p=RoundFloat( GaugeNum*0.5);
	for(i=0; i<p; i++)ChargeBar[i]=Gauge1[0];
	for( ; i<50; i++)ChargeBar[i]=Gauge2[0];
	 
	//if(p>=0 && p<100)ChargeBar[p] = Gauge3[0]; 
 	/* Display gauge */
	
	new keyMode=GetConVarInt(l4d_struggle_key);
	if(keyMode==1 )PrintCenterText(client, "Press [Space key] to struggle %d\n<< %s >>",RoundFloat(GaugeNum),  ChargeBar);
	if(keyMode==2 )PrintCenterText(client, "Press [Movement Keys] to struggle %d\n<< %s >>",RoundFloat(GaugeNum),  ChargeBar);
	if(keyMode==3 )PrintCenterText(client, "Press [Mouse Keys] to struggle %d\n<< %s >>",RoundFloat(GaugeNum),  ChargeBar);
	
}

// SDK call handles
new Handle:gConf = INVALID_HANDLE;
new Handle:SdkShove = INVALID_HANDLE;
new Handle:SdkFling = INVALID_HANDLE;
new Handle:SdkStartActivationTimer=INVALID_HANDLE;
new Handle:SdkOnPummelEnded=INVALID_HANDLE;
new Handle:SdkOnPounceEnd=INVALID_HANDLE;
new Handle:sdkShoveInf = INVALID_HANDLE;
SetupSDKCall()
{
	gConf = LoadGameConfigFile("struggle_l4d");
	
	if(gConf == INVALID_HANDLE)
	{
		ThrowError("Could not load gamedata/struggle_l4d.txt");
	}
	
	if(L4D2Version)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "CTerrorPlayer::OnShovedBySurvivor");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		SdkShove = EndPrepSDKCall();
		if(SdkShove == INVALID_HANDLE)
		{
			PrintToServer("Unable to find the 'CTerrorPlayer::OnShovedBySurvivor' signature");
		}
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SigFling");
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
		PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "CBaseAbility::StartActivationTimer");
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);
		SdkStartActivationTimer = EndPrepSDKCall();
		if(SdkStartActivationTimer == INVALID_HANDLE)
		{
			PrintToServer("Unable to find the 'CBaseAbility::StartActivationTimer' signature, check the file version!");
 		}	
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "CTerrorPlayer::OnPummelEnded");
		PrepSDKCall_AddParameter(SDKType_Bool,SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_CBasePlayer,SDKPass_Pointer,VDECODE_FLAG_ALLOWNULL);
		SdkOnPummelEnded = EndPrepSDKCall();
		if(SdkOnPummelEnded == INVALID_HANDLE)
		{
			PrintToServer("Unable to find the 'CTerrorPlayer::OnPummelEnded' signature, check the file version!");
 		} 
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "CTerrorPlayer::OnPounceEnd");
		SdkOnPounceEnd = EndPrepSDKCall();
		if(SdkOnPounceEnd == INVALID_HANDLE)
		{
			PrintToServer("Unable to find the 'CTerrorPlayer::OnPounceEnd' signature, check the file version!");
 		}
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "CTerrorPlayer_OnStaggered");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		sdkShoveInf = EndPrepSDKCall();
		if(sdkShoveInf == INVALID_HANDLE)
		{
			PrintToServer("BROKEN SIGNATURE \"CTerrorPlayer_OnStaggered\" PLEASE UPDATE GAMEDATA");
		}
	}
	else
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "CTerrorPlayer::OnShovedBySurvivor");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		SdkShove = EndPrepSDKCall();
		if(SdkShove == INVALID_HANDLE)
		{
			PrintToServer("Unable to find the 'CTerrorPlayer::OnShovedBySurvivor' signature");
		}		
		SdkFling=INVALID_HANDLE; 
	} 	
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

Shove2(victim, attacker,  direction=1)
{ 
	decl Float:dir[3]; 
	GetClientAbsAngles(victim, dir);
	GetAngleVectors(dir,dir, NULL_VECTOR,NULL_VECTOR);
	NormalizeVector(dir,dir);
	if(direction<0)ScaleVector(dir,  -1.0);
	SDKCall(SdkShove, victim, attacker,  dir);
}

Shove3(victim, attacker)
{ 
	new Float:vecOrigin[3];
	GetClientAbsOrigin(victim, vecOrigin);
	SDKCall(sdkShoveInf, attacker, victim, vecOrigin);
}

CallOnPummelEnded(client)
{
    if (SdkOnPummelEnded==INVALID_HANDLE)return;
    SDKCall(SdkOnPummelEnded,client,true,-1);
}

CallOnPounceEnd(client)
{
	if (SdkOnPounceEnd==INVALID_HANDLE)return;
	SDKCall(SdkOnPounceEnd,client);
} 

CallResetAbility(client,Float:time)
{ 
	if (SdkStartActivationTimer==INVALID_HANDLE) 	return;
	new AbilityEnt=GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if(AbilityEnt>0)SDKCall(SdkStartActivationTimer, AbilityEnt, time, 0.0);
}

public Action:ResetAbilityDelay(Handle:timer, any:client)
{
	if(IsInfected(client))CallResetAbility(client,0.0);
}  
public Action:ResetDelay(Handle:timer, any:client)
{
	if(IsInfected(client))CallResetAbility(client,0.0);
}

ExecuteCommand(Client, String:strCommand[])
{
	new flags = GetCommandFlags(strCommand);
    
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s", strCommand);
	SetCommandFlags(strCommand, flags);
}