/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>
#include <sdktools_functions> 
 
#define SOUND_GRAB		"UI/helpful_event_1.wav"
new g_iVelocity ;
 
new Handle:l4d_pushdrag_versus_survivor;
new Handle:l4d_pushdrag_versus_infected;

new Float:lasttime;
new Float:ShoveTime[MAXPLAYERS+1];
new KeyBuffer[MAXPLAYERS+1];
new KeyState[MAXPLAYERS+1];
new GrabedEnt[MAXPLAYERS+1];
new Float:GrabEnerge[MAXPLAYERS+1];
new Float:KeyTime[MAXPLAYERS+1];
new Float:HoldDistance[MAXPLAYERS+1];
new bool:L4D2Version;
new bool:GameMode;
new bool:gamestart;
new versus_survivor;
new versus_infected;
public Plugin:myinfo = 
{
	name = "Push And Drag",
	author = "Pan Xiaohai",
	description = "<- Description ->",
	version = "1.2",
	url = "<- URL ->"
}
public OnMapStart()
{
	PrecacheSound(SOUND_GRAB, true);
}
public OnPluginStart()
{	
	g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
	l4d_pushdrag_versus_survivor = CreateConVar("l4d_pushdrag_versus_survivor", "3", "0:disable survivor use in versus ,1: survivor grab object, 2:, survivor grab teamate 3: survivor grab all", FCVAR_PLUGIN);
	l4d_pushdrag_versus_infected = CreateConVar("l4d_pushdrag_versus_infected", "2", "0:disable infected use in versus ,1: infected grab object, 2:, infected grab teamate 3: infected grab all", FCVAR_PLUGIN);
	
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
	
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		L4D2Version=true;
	}	
	else
	{
		L4D2Version=false;
	}

	AutoExecConfig(true, "l4d_pushdrag_v12");
		 
	HookEvent("round_end", RoundEnd);
	HookEvent("finale_win", RoundEnd);
	HookEvent("mission_lost", RoundEnd);
	HookEvent("map_transition", RoundEnd);
	HookEvent("tank_spawn", RoundStart);
	
	HookConVarChange(l4d_pushdrag_versus_survivor, CvarChanged);	
	HookConVarChange(l4d_pushdrag_versus_infected, CvarChanged); 	
	Set(false);
}
public CvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Set(true);
}
public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	Set(true);
	
}
public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	gamestart=false;
}
Set(bool:start=false)
{
	gamestart=start;
	if(GameMode==2)
	{
		versus_survivor=GetConVarInt(l4d_pushdrag_versus_survivor);
		versus_infected=GetConVarInt(l4d_pushdrag_versus_infected);
		if(versus_survivor==0 && versus_infected==0)
		{
			gamestart=false;
		}
	}
	else
	{
		versus_survivor=3;
	    versus_infected=GetConVarInt(l4d_pushdrag_versus_infected);
	}
	
	for(new client = 1; client <= MaxClients; client++)
	{
		GrabedEnt[client]=0;
	}
}
public OnGameFrame()
{
	new Float:currenttime=GetEngineTime();
	new Float:duration=currenttime-lasttime;
	if(duration<0.0 || duration>1.0)duration=0.0;
  	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
		{
			new team=GetClientTeam(client);
			if(team==2 && versus_survivor>0)
			{
				Do(client, currenttime, duration);
			}
			if(team==3 && versus_infected>0)
			{
				if(IsPlayerGhost(client))
				{
					GrabedEnt[client]=0;
				}
				else 
				{
					Do(client, currenttime, duration);
				}
			}
		}
		else
		{
			GrabedEnt[client]=0;
		}
		 
	}
	lasttime=currenttime;
}
Do(client , Float:ctime, Float:duration)
{
	
	new button=GetClientButtons(client);
	new bool:startgrab=false;
 	if(KeyState[client]==0)
	{
		if((button & IN_SPEED) && !(KeyBuffer[client] & IN_SPEED))
		{		 
			KeyState[client]=1;
			KeyTime[client]=ctime;
			//PrintToChat(client, "state 1"); 
		}
	} 
	if(KeyState[client]==1)
	{
		if(ctime-KeyTime[client]<0.3)
		{
			if(!(button & IN_SPEED) && (KeyBuffer[client] & IN_SPEED))
			{
				KeyState[client]=2;
				//PrintToChat(client, "state 2");
			}
		}
		else
		{
			KeyState[client]=0;
		}
		 
	} 
	if(KeyState[client]==2)
	{
		if(ctime-KeyTime[client]<0.3)
		{
			if((button & IN_SPEED) && !(KeyBuffer[client] & IN_SPEED))
			{				
				KeyState[client]=3;
				startgrab=true;
			 	//PrintToChat(client, "state 3");
			}
		}
		else
		{
			KeyState[client]=0;
		}
	}
	if(KeyState[client]==3 && !(button & IN_SPEED))
	{
		KeyState[client]=0;
		//PrintToChat(client, "state 0");
	}
	new bool:grabed=false;
	if(GrabedEnt[client]>0 && IsValidEdict(GrabedEnt[client]))grabed=true;
	if(KeyState[client]==1 && grabed )
	{	
		if((button & IN_ATTACK))ThrowEnt(client, GrabedEnt[client], ctime, 2000.0);
		else 
		{
			//ThrowEnt(client, GrabedEnt[client], ctime, 100.0);
		}
		KeyState[client]=0;
		GrabedEnt[client]=0;
		grabed=false;
	}
	 
	KeyBuffer[client]=button;
 
	if (startgrab) 
	{
		GrabedEnt[client]=GetEnt(client, ctime);
		if(GrabedEnt[client]>0)
		{
			grabed=true;
			decl Float:vOrigin[3];
			GetClientEyePosition(client,vOrigin);
			EmitSoundToAll(SOUND_GRAB, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, vOrigin, NULL_VECTOR, false, 0.0);	
		}
	}
	if(grabed)
	{
		new bool:cast=false;
		if(button & IN_ATTACK2)
		{
			cast=true;
		}
		
		if(cast)
		{	
			ThrowEnt(client, GrabedEnt[client], ctime, 200.0);
			GrabedEnt[client]=0;
		}
		else
		{
			GrabEnt(client, GrabedEnt[client], duration);
			if(GrabEnerge[client]<ctime)
			{
				GrabedEnt[client]=0;
			}
		}
	}
	else
	{
		GrabedEnt[client]=0;
	}
 	 
}
GrabEnt(client, ent, Float:duration)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:pos[3];
	decl Float:velocity[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	GetEntDataVector(client, g_iVelocity, velocity);
	
	ScaleVector(velocity, duration*4.0);
	AddVectors(vOrigin, velocity ,vOrigin);

	GetAngleVectors(vAngles, vAngles, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vAngles, vAngles);
	ScaleVector(vAngles, HoldDistance[client]);
	AddVectors(vOrigin, vAngles, vOrigin);
	new Float:dis=GetVectorDistance(vOrigin, pos);
	new Float:force=0.0;		
	if(dis>100.0)dis=100.0;
	force=0.2*dis*dis;
	//PrintToChatAll("%f, %f", dis, force);
	SubtractVectors(vOrigin, pos, velocity);
	NormalizeVector(velocity, velocity);
	ScaleVector(velocity, force);
	TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, velocity);

}
ThrowEnt(client, ent, Float:ctime, Float:force)
{	
	//PrintToChat(client, "throw");
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:pos[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	
	new Float:dis=GetVectorDistance(vOrigin, pos);
	if(dis>1000.0)dis=1000.0;
	force=force*(1000.0-dis)/1000.0+200.0;
	//PrintToChatAll("%f %f",dis, force);
	decl Float:volicity[3];
	SubtractVectors(pos, vOrigin, volicity);
	NormalizeVector(volicity, volicity);
	ScaleVector(volicity, force);
	TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, volicity);
	
	decl String:classname[64];
	GetEdictClassname(ent, classname, 64);		
	if(StrContains(classname, "prop_")!=-1)
	{
		SetEntPropEnt(ent, Prop_Data, "m_hPhysicsAttacker", client);
		SetEntPropFloat(ent, Prop_Data, "m_flLastPhysicsInfluenceTime", ctime);
	}
}
GetEnt(client, Float:ctime)
{
	new ent=0;
	
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:pos[3];

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		ent=TR_GetEntityIndex(trace);
		if(ent>0)
		{
			new Float:dis=GetVectorDistance(vOrigin, pos);
			
			if(dis<120.0)
			{
				decl String:classname[64];
				GetEdictClassname(ent, classname, 64);	
				new grabmode;
				if(GetClientTeam(client)==2)grabmode=versus_survivor;
				else grabmode=versus_infected; //1: infected grab object, 2:, infected grab teamate 3: infected grab all
				if(StrContains(classname, "ladder")!=-1){ent=0;}
				else if(StrContains(classname, "door")!=-1){ent=0;}
				else if(StrContains(classname, "infected")!=-1){ent=0;}
				else 
				{			 
					HoldDistance[client]=100.0;
					GrabEnerge[client]=ctime+10.0;
					if(StrContains(classname, "prop_")!=-1)
					{
						SetEntPropEnt(ent, Prop_Data, "m_hPhysicsAttacker", client);
						SetEntPropFloat(ent, Prop_Data, "m_flLastPhysicsInfluenceTime", ctime);
						//PrintToChatAll("You grabbed a prop");
						HoldDistance[client]=120.0;
						GrabEnerge[client]=ctime+1000.0;						
					}
					if(StrContains(classname, "car")!=-1)
					{
						HoldDistance[client]=250.0;
						GrabEnerge[client]=ctime+1.0;		
						//PrintToChatAll("You grabbed a car");
					}
					if(StrContains(classname, "weapon_")!=-1)
					{
						HoldDistance[client]=50.0;
						GrabEnerge[client]=ctime+1000.0;
						//PrintToChatAll("You grabbed a weapon");
					}
					if(StrContains(classname, "player")!=-1)
					{
						HoldDistance[client]=70.0;
						GrabEnerge[client]=ctime+1000.0;
						//PrintToChatAll("You grabbed a player");
					}

					if(ent<=MaxClients)	
					{
						if(grabmode==2 || grabmode==3)
						{
							if(GetClientTeam(client)==GetClientTeam(ent))
							{
								PrintHintText(client, "You grabbed %N", ent);
								PrintHintText(ent, "%N grabbed you", client);							
							}
							else
							{
								PrintHintText(client, "You can not grab emney!");
								ent=0;
							}
						}
						else
						{
							PrintHintText(client, "Grab player is disabled!");
							ent=0;
						}
					}
					else
					{
						if(grabmode==1 || grabmode==3)
						{
							PrintHintText(client, "You grabbed something!");
						}
						else
						{
							PrintHintText(client, "Grab object is disabled!");
							ent=0;
						}
					}
					
				}
			}
			else
			{
				ent=0;
				PrintHintText(client, "It is too far");
			}
		}
		else
		{
			PrintHintText(client, "You grabbed nothing!");
		}
	}
	CloseHandle(trace)
	
	return ent;
}
bool:IsPlayerGhost (client)
{
	if (GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_isGhost"), 1))
		return true;
	return false;
}
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	return true;
}