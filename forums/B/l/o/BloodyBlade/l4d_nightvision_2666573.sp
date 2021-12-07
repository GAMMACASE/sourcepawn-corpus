/* Plugin Template generated by Pawn Studio */
#pragma newdecls required
#include <sourcemod>

int IMPULS_FLASHLIGHT 						= 100;
float PressTime[MAXPLAYERS+1];
 
int Mode; 
bool EnableSuvivor; 
bool EnableInfected; 
ConVar l4d_nt_team;

public Plugin myinfo = 
{
	name = "Night Vision",
	author = "Pan Xiaohai & Mr. Zero",
	description = "<- Description ->",
	version = "1.0",
	url = "<- URL ->"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_nightvision", sm_nightvision);
	l4d_nt_team = CreateConVar("l4d_nt_team", "1", "0:disable, 1:enable for survivor and infected, 2:enable for survivor, 3:enable for infected", FCVAR_NONE);	
	AutoExecConfig(true, "l4d_nightvision"); 
	HookConVarChange(l4d_nt_team, ConVarChange);
	GetConVar();
}

public void ConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetConVar(); 
}

void GetConVar()
{
	Mode = GetConVarInt(l4d_nt_team);
	EnableSuvivor = (Mode == 1 || Mode == 2);
	EnableInfected = (Mode == 1 || Mode == 3);
}

public Action sm_nightvision(int client, int args)
{
	if(IsClientInGame(client)) SwitchNightVision(client);
}

//code from "Block Flashlight",
public Action OnPlayerRunCmd(int client, int &buttons, int &impuls, float vel[3], float angles[3], int &weapon)
{
	if(Mode == 0) return;	
	if(impuls == IMPULS_FLASHLIGHT)
	{
		int team = GetClientTeam(client);
		if(team == 2 && EnableSuvivor )
		{		 	
			float time = GetEngineTime();
			if(time - PressTime[client] < 0.3)
			{
				SwitchNightVision(client); 				 
			}
			PressTime[client] = time;
		}	 
		if(team == 3 && EnableInfected)
		{
			float time = GetEngineTime();
			if(time - PressTime[client] > 0.1)
			{
				SwitchNightVision(client); 
			}
			PressTime[client] = time;			 
		}
	}
}

void SwitchNightVision(int client)
{
	int d = GetEntProp(client, Prop_Send, "m_bNightVisionOn");
	if(d == 0)
	{
		SetEntProp(client, Prop_Send, "m_bNightVisionOn",1); 
		PrintHintText(client, "Night Vision On");
		
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_bNightVisionOn",0);
		PrintHintText(client, "Night Vision Off");	
	}
}