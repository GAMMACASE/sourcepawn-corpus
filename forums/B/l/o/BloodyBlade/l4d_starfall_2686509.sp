/* Plugin Template generated by Pawn Studio */
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
 
ConVar l4d_star_duration;
 
ConVar l4d_star_damage;
ConVar l4d_star_explode_chance;
ConVar l4d_star_explode_damage;
ConVar l4d_star_explode_radius;
ConVar l4d_star_fall_speed;
 
ConVar l4d_star_dead_tank;
ConVar l4d_star_dead_witch;
ConVar l4d_star_witch_harasser;
 
ConVar l4d_star_mininterval;
ConVar l4d_star_maxinterval;

int g_iVelocity;
bool starfalling = false;

public Plugin myinfo = 
{
	name = "starfall",
	author = "Pan Xiaohai, tornasuk",
	description = "starfall (slay / no message)",
	version = "1.1.1",
	url = "<- URL ->"
}

public void OnPluginStart()
{
	l4d_star_duration = CreateConVar("l4d_star_duration", "15", "starfall duration (s)");

	l4d_star_damage = 	CreateConVar("l4d_star_damage", "20", "direct hit damage of rock");
	l4d_star_explode_chance = CreateConVar("l4d_star_explode_chance", "15", "rock explode chance [0-100]");
	l4d_star_explode_damage = 	CreateConVar("l4d_star_explode_damage", "20", "explode damage of rock");
	l4d_star_explode_radius = CreateConVar("l4d_star_explode_radius", "200", "explosion radius of rock");	
	l4d_star_fall_speed = CreateConVar("l4d_star_fall_speed", "200", "fall speed of rock");	

 	l4d_star_dead_tank =  CreateConVar("l4d_star_dead_tank", "20", "chance of meteor shower when tank die"); 
	l4d_star_dead_witch =  CreateConVar("l4d_star_dead_witch", "10", " chance of meteor shower when witch die"); 	
	l4d_star_witch_harasser =  CreateConVar("l4d_star_witch_harasser", "5", " chance of meteor shower when witch harasser"); 

	l4d_star_mininterval =  CreateConVar("l4d_star_mininterval", "500", "[200, maxinterval]seconds "); 
	l4d_star_maxinterval =  CreateConVar("l4d_star_maxinterval", "800", "[200, 600]seconds "); 	

	AutoExecConfig(true, "l4d_starfall");

	RegConsoleCmd("sm_starfall", sm_starfall);

	HookEvent("tank_killed", tank_killed);
	HookEvent("witch_killed", witch_killed);
	HookEvent("witch_harasser_set", witch_harasser_set);		

	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
	HookEvent("finale_win", RoundEnd);
	HookEvent("mission_lost", RoundEnd);
	HookEvent("map_transition", RoundEnd);

	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
}

int timetick = 0;
int nexttime = 0;
public Action sm_starfall(int client, int args)
{
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{ 
		StartStarFall(client);
	}
}

public Action TimerUpdate(Handle timer)
{
	if(nexttime == 0)
		nexttime = GetRandomInt(GetConVarInt(l4d_star_mininterval), GetConVarInt(l4d_star_maxinterval));

	timetick += 10;
	if(timetick >= nexttime)
	{
		int andidate[MAXPLAYERS + 1];
		int index = 0;
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
			{
				andidate[index++] = client;
			}
		}
		if(index > 0)
		{
			StartStarFall(andidate[GetRandomInt(0, index - 1)]);
		}		
	}
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	starfalling = false;
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	starfalling = false;
}

public Action tank_killed(Event hEvent, const char[] strName, bool DontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(GetRandomFloat(0.0, 100.0) < GetConVarFloat(l4d_star_dead_tank))
		StartStarFall(victim);
}

public Action witch_killed(Event hEvent, const char[] strName, bool DontBroadcast)
{
	int killer = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(GetRandomFloat(0.0, 100.0) < GetConVarFloat(l4d_star_dead_witch) && killer > 0)
		StartStarFall(killer);
}

public Action witch_harasser_set(Event hEvent, const char[] strName, bool DontBroadcast)
{
	int killer = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(GetRandomFloat(0.0, 100.0) < GetConVarFloat(l4d_star_witch_harasser) && killer > 0)
		StartStarFall(killer);
}

void StartStarFall(int client)
{
	//if(starfalling)return;
	float pos[3];

	GetClientEyePosition(client, pos);
	pos[2] += 20.0;

	Handle h = CreateDataPack(); 
	int ent = CreateEntityByName("env_rock_launcher");    
	DispatchSpawn(ent); 
	char damagestr[32];
	GetConVarString(l4d_star_damage,damagestr, 32);
	DispatchKeyValue(ent, "rockdamageoverride", damagestr);	

	WritePackCell(h, client);
	WritePackCell(h, ent);
	WritePackFloat(h, pos[0]);
	WritePackFloat(h, pos[1]);
	WritePackFloat(h, pos[2]);
	WritePackFloat(h, GetEngineTime()); 
	starfalling = true;
	CreateTimer(0.5, UpdateStarFall, h, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	// PrintToChatAll("Star Fall"); // commented by tornasuk
}

public Action UpdateStarFall(Handle timer, any h)
{
	ResetPack(h);
	float pos[3];
	int client = ReadPackCell(h);
 	int ent = ReadPackCell(h);
	pos[0] = ReadPackFloat(h);
	pos[1] = ReadPackFloat(h);
	pos[2] = ReadPackFloat(h);

	float time = ReadPackFloat(h); 
	bool quit = false;
	if(ent > 0 && IsValidEdict(ent))
	{
		float angle[3];
		float hitpos[3];
		angle[0] = 0.0 + GetRandomFloat(-1.0, 1.0);
		angle[1] = 0.0 + GetRandomFloat(-1.0, 1.0);
		angle[2] = 2.0;

		GetVectorAngles(angle, angle);

		GetRayHitPos2(pos, angle, hitpos, client, 0.0);
		float dis = GetVectorDistance(pos, hitpos);
		if(GetVectorDistance(pos, hitpos) > 2000.0)
		{
			dis = 1600.0;
		}

		float t[3];
		MakeVectorFromPoints(pos, hitpos, t);
		NormalizeVector(t,t);
		ScaleVector(t, dis - 40.0);
		AddVectors(pos, t, hitpos);

		if(dis > 600.0)
		{
			if(ent > 0)
			{
				float angle2[3];
				angle2[0] = GetRandomFloat(-1.0, 1.0);
				angle2[1] = GetRandomFloat(-1.0, 1.0);
				angle2[2] = -2.0;
				GetVectorAngles(angle2, angle2);
				TeleportEntity(ent, hitpos, angle2, NULL_VECTOR);
				AcceptEntityInput(ent, "LaunchRock");			 
			}
		}
	}
	else quit = true;

	if(GetEngineTime() - time > GetConVarFloat(l4d_star_duration) || quit)
	{	 
		starfalling = false;
		CloseHandle(h); 
		if(!quit) AcceptEntityInput(ent, "slay");
		return Plugin_Stop;		
	}
	timetick = nexttime = 0;
	return Plugin_Continue;	
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(!starfalling)return;
	if(StrEqual(classname, "tank_rock"))
	{
		
		IgniteEntity(entity, 5.0);
		SetEntityGravity(entity, 0.1);
		CreateTimer(0.1, SetStarVol, entity, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action SetStarVol(Handle timer, any star)
{
	if(star > 0 && IsValidEdict(star))
	{
		float v[3];
		GetEntDataVector(star, g_iVelocity, v);	 
		NormalizeVector(v,v);
		ScaleVector(v, GetConVarFloat(l4d_star_fall_speed));
		TeleportEntity(star, NULL_VECTOR, NULL_VECTOR, v);
	}
}

int GetRayHitPos2(float pos[3], float angle[3], float hitpos[3], int ent = 0, float offset = 0.0)
{
	Handle trace;
	int hit = 0;

	trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelfAndLive, ent);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(hitpos, trace);
		hit = TR_GetEntityIndex(trace);
	}
	CloseHandle(trace);

	if(offset != 0.0)
	{
		float v[3];
		MakeVectorFromPoints(hitpos, pos, v);
		NormalizeVector(v, v);
		ScaleVector(v, offset);
		AddVectors(hitpos, v, hitpos);		
	}
	return hit;
}

public void OnMapStart()
{
	PrecacheModel("models/props_junk/propanecanister001a.mdl", true);
	PrecacheModel("models/props_junk/gascan001a.mdl", true);

	CreateTimer(10.0,TimerUpdate, 0, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);  
} 

void ExplodeStar(int entity)
{
	int ent1 = 0;
	float pos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);	
	pos[2] += 50.0;

	ent1 = CreateEntityByName("prop_physics"); 

	DispatchKeyValue(ent1, "model", "models/props_junk/propanecanister001a.mdl"); 
	DispatchSpawn(ent1); 
	TeleportEntity(ent1, pos, NULL_VECTOR, NULL_VECTOR);
	ActivateEntity(ent1);
	SetEntityRenderMode(ent1, view_as<RenderMode>(3));
	SetEntityRenderColor(ent1, 0, 0, 0, 0);
	AcceptEntityInput(ent1, "Ignite", -1, -1);
	AcceptEntityInput(ent1, "Break", -1, -1);

	float damage = GetConVarFloat(l4d_star_explode_damage);
	float radius = GetConVarFloat(l4d_star_explode_radius);
	float pushforce = 500.0;
	
	int pointHurt = CreateEntityByName("point_hurt");   

	DispatchKeyValueFloat(pointHurt, "Damage", damage);        
	DispatchKeyValueFloat(pointHurt, "DamageRadius", radius);     
	DispatchKeyValue(pointHurt, "DamageDelay", "0.0");   
	DispatchSpawn(pointHurt);
	TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);  
	AcceptEntityInput(pointHurt, "Hurt", -1);    
	CreateTimer(0.1, DeletePointHurt, pointHurt); 

	int push = CreateEntityByName("point_push");         
	DispatchKeyValueFloat (push, "magnitude", pushforce);                     
	DispatchKeyValueFloat (push, "radius", radius*1.0);                     
	SetVariantString("spawnflags 24");                     
	AcceptEntityInput(push, "AddOutput");
	DispatchSpawn(push);
	TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);  
	AcceptEntityInput(push, "Enable", -1, -1);
	CreateTimer(0.5, DeletePushForce, push);	 
}

public void OnEntityDestroyed(int entity)
{
	if(!starfalling)return;
/* tornasuk - 27/11/2013 - Added for checking entity*/
	if (!IsValidEdict(entity)) return;
/* tornasuk - 27/11/2013 - */
	char classname[64];
	GetEdictClassname(entity, classname, sizeof(classname)); 
	if(StrEqual(classname, "tank_rock", true))
	{
		if(GetRandomFloat(0.0, 100.0) < GetConVarFloat(l4d_star_explode_chance))
			ExplodeStar(entity);
	}
}

public void DeleteEntity(any ent, char[] name)
{
	if (IsValidEntity(ent))
	{
		char classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, name, false))
		{
			AcceptEntityInput(ent, "Slay"); 
			RemoveEdict(ent);
		}
	}
}

public Action DeletePushForce(Handle timer, any ent)
{
	if (IsValidEntity(ent))
	{
		char classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, "point_push", false))
		{
			AcceptEntityInput(ent, "Disable");
			AcceptEntityInput(ent, "Slay"); 
			RemoveEdict(ent);
		}
	}
}

public Action DeletePointHurt(Handle timer, any ent)
{
	if (IsValidEntity(ent))
	{
		char classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, "point_hurt", false))
		{
			AcceptEntityInput(ent, "Slay"); 
			RemoveEdict(ent);
		}
	}
}
 
public bool TraceRayDontHitSelfAndSurvivor(int entity, int mask, any data)
{
	if(entity == data)
	{
		return false;
	}
	else if(entity > 0 && entity <= MaxClients)
	{
		if(IsClientInGame(entity) && GetClientTeam(entity) == 2)
		{
			return false;
		}
	}
	return true;
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	if(entity == data) 
	{
		return false; 
	}
	return true;
}

public bool TraceRayDontHitSelfAndLive(int entity, int mask, any data)
{
	if(entity == data) 
	{
		return false; 
	}
	else if(entity > 0 && entity <= MaxClients)
	{
		if(IsClientInGame(entity))
		{
			return false;
		}
	}
	return true;
}