/* Plugin Template generated by Pawn Studio */
// Thanks to Damizean for starting this craze!


#include <sourcemod>

#define CVAR_FLAGS FCVAR_PLUGIN
#define PLUGIN_VERSION "0.9"

#define LOOT_DIENUMBER 		0
#define LOOT_DIECOUNT 		1
#define LOOT_KIT_MIN		2
#define LOOT_KIT_MAX		3
#define LOOT_WEAPON_MIN		4
#define LOOT_WEAPON_MAX		5
#define LOOT_PILLS_MIN		6
#define LOOT_PILLS_MAX		7
#define LOOT_MOLLY_MIN		8
#define LOOT_MOLLY_MAX		9
#define LOOT_PIPE_MIN		10
#define LOOT_PIPE_MAX		11
#define LOOT_ITEM_COUNT		12

public Plugin:myinfo = 
{
	name = "[L4D] Infected Loot Drops",
	author = "Thraka",
	description = "Chance to drop items on the death of a special infected.",
	version = PLUGIN_VERSION,
	url = ""
}

new Handle:CVarIsEnabled;
new Handle:CVarDieSides[4];

new Handle:CVarHunterLoot[13];
new Handle:CVarBoomerLoot[13];
new Handle:CVarSmokerLoot[13];
new Handle:CVarTankLoot[13];

new HunterLoot[13];
new BoomerLoot[13];
new SmokerLoot[13];
new TankLoot[13];

new Dice[4];

public OnPluginStart()
{
	CreateConVar("l4d_loot_ver", PLUGIN_VERSION, "Version of the infected loot drops plugins.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	CVarIsEnabled = CreateConVar("l4d_loot_enabled", "1", "Is the plugin enabled.", FCVAR_PLUGIN);
	HookConVarChange(CVarIsEnabled, Loot_EnableDisable);
	
	CVarDieSides[0] = CreateConVar("l4d_loot_dice1_sides", "10", "How many sides die 1 has.", FCVAR_PLUGIN);
	CVarDieSides[1] = CreateConVar("l4d_loot_dice2_sides", "20", "How many sides die 2 has.", FCVAR_PLUGIN);
	CVarDieSides[2] = CreateConVar("l4d_loot_dice3_sides", "30", "How many sides die 3 has.", FCVAR_PLUGIN);
	CVarDieSides[3] = CreateConVar("l4d_loot_dice4_sides", "100", "How many sides die 4 has.", FCVAR_PLUGIN);
		
	CVarHunterLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_hunter_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the hunter", FCVAR_PLUGIN, true, 1.0, true, 4.0);
	CVarHunterLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_hunter_diecount", "1", "How many dice can roll. Each die is added to a total. (If a die rolls 0 it is not thrown)", FCVAR_PLUGIN, true, 1.0, true, 3.0);
	CVarHunterLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_hunter_kit_min", "0", "Min die number for a hunter to drop a kit.", FCVAR_PLUGIN, true, 0.0);
	CVarHunterLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_hunter_kit_max", "0", "Max die number for a hunter to drop a kit.", FCVAR_PLUGIN, true, 0.0);
	CVarHunterLoot[LOOT_WEAPON_MIN] = CreateConVar("l4d_loot_hunter_weapon_min", "0", "Min die number for a hunter to drop a weapon.", FCVAR_PLUGIN, true, 0.0);
	CVarHunterLoot[LOOT_WEAPON_MAX] = CreateConVar("l4d_loot_hunter_weapon_max", "0", "Max die number for a hunter to drop a weapon.", FCVAR_PLUGIN, true, 0.0);
	CVarHunterLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_hunter_pills_min", "1", "Min die number for a hunter to drop pills.", FCVAR_PLUGIN, true, 0.0);
	CVarHunterLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_hunter_pills_max", "1", "Max die number for a hunter to drop pills.", FCVAR_PLUGIN, true, 0.0);
	CVarHunterLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_hunter_molly_min", "2", "Min die number for a hunter to drop a molitov.", FCVAR_PLUGIN, true, 0.0);
	CVarHunterLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_hunter_molly_max", "3", "Max die number for a hunter to drop a molitov.", FCVAR_PLUGIN, true, 0.0);
	CVarHunterLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_hunter_pipe_min", "4", "Min die number for a hunter to drop a pipe bomb.", FCVAR_PLUGIN, true, 0.0);
	CVarHunterLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_hunter_pipe_max", "5", "Max die number for a hunter to drop a pipe bomb.", FCVAR_PLUGIN, true, 0.0);
	CVarHunterLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_hunter_item_count", "1", "Max die number for a hunter to drop a pipe bomb.", FCVAR_PLUGIN, true, 0.0);
	
	CVarBoomerLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_boomer_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the boomer", FCVAR_PLUGIN, true, 1.0, true, 4.0);
	CVarBoomerLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_boomer_diecount", "1", "How many dice can roll for the boomer. Each die is added to a total. (If a die rolls 0 it is not thrown)", FCVAR_PLUGIN, true, 1.0, true, 3.0);
	CVarBoomerLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_boomer_kit_min", "0", "Min die number for a boomer to drop a kit.", FCVAR_PLUGIN, true, 0.0);
	CVarBoomerLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_boomer_kit_max", "0", "Max die number for a boomer to drop a kit.", FCVAR_PLUGIN, true, 0.0);
	CVarBoomerLoot[LOOT_WEAPON_MIN] = CreateConVar("l4d_loot_boomer_weapon_min", "0", "Min die number for a boomer to drop a weapon.", FCVAR_PLUGIN, true, 0.0);
	CVarBoomerLoot[LOOT_WEAPON_MAX] = CreateConVar("l4d_loot_boomer_weapon_max", "0", "Max die number for a boomer to drop a weapon.", FCVAR_PLUGIN, true, 0.0);
	CVarBoomerLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_boomer_pills_min", "1", "Min die number for a boomer to drop pills.", FCVAR_PLUGIN, true, 0.0);
	CVarBoomerLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_boomer_pills_max", "1", "Max die number for a boomer to drop pills.", FCVAR_PLUGIN, true, 0.0);
	CVarBoomerLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_boomer_molly_min", "2", "Min die number for a boomer to drop a molitov.", FCVAR_PLUGIN, true, 0.0);
	CVarBoomerLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_boomer_molly_max", "3", "Max die number for a boomer to drop a molitov.", FCVAR_PLUGIN, true, 0.0);
	CVarBoomerLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_boomer_pipe_min", "4", "Min die number for a boomer to drop a pipe bomb.", FCVAR_PLUGIN, true, 0.0);
	CVarBoomerLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_boomer_pipe_max", "5", "Max die number for a boomer to drop a pipe bomb.", FCVAR_PLUGIN, true, 0.0);
	CVarBoomerLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_boomer_item_count", "1", "Max die number for a boomer to drop a pipe bomb.", FCVAR_PLUGIN, true, 0.0);
	
	CVarSmokerLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_smoker_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the smoker", FCVAR_PLUGIN, true, 1.0, true, 4.0);
	CVarSmokerLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_smoker_diecount", "1", "How many dice can roll for the smoker. Each die is added to a total. (If a die rolls 0 it is not thrown)", FCVAR_PLUGIN, true, 1.0, true, 3.0);
	CVarSmokerLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_smoker_kit_min", "0", "Min die number for a smoker to drop a kit.", FCVAR_PLUGIN, true, 0.0);
	CVarSmokerLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_smoker_kit_max", "0", "Max die number for a smoker to drop a kit.", FCVAR_PLUGIN, true, 0.0);
	CVarSmokerLoot[LOOT_WEAPON_MIN] = CreateConVar("l4d_loot_smoker_weapon_min", "0", "Min die number for a smoker to drop a weapon.", FCVAR_PLUGIN, true, 0.0);
	CVarSmokerLoot[LOOT_WEAPON_MAX] = CreateConVar("l4d_loot_smoker_weapon_max", "0", "Max die number for a smoker to drop a weapon.", FCVAR_PLUGIN, true, 0.0);
	CVarSmokerLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_smoker_pills_min", "1", "Min die number for a smoker to drop pills.", FCVAR_PLUGIN, true, 0.0);
	CVarSmokerLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_smoker_pills_max", "1", "Max die number for a smoker to drop pills.", FCVAR_PLUGIN, true, 0.0);
	CVarSmokerLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_smoker_molly_min", "2", "Min die number for a smoker to drop a molitov.", FCVAR_PLUGIN, true, 0.0);
	CVarSmokerLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_smoker_molly_max", "3", "Max die number for a smoker to drop a molitov.", FCVAR_PLUGIN, true, 0.0);
	CVarSmokerLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_smoker_pipe_min", "4", "Min die number for a smoker to drop a pipe bomb.", FCVAR_PLUGIN, true, 0.0);
	CVarSmokerLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_smoker_pipe_max", "5", "Max die number for a smoker to drop a pipe bomb.", FCVAR_PLUGIN, true, 0.0);
	CVarSmokerLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_smoker_item_count", "1", "Max die number for a smoker to drop a pipe bomb.", FCVAR_PLUGIN, true, 0.0);
	
	CVarTankLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_tank_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the tank", FCVAR_PLUGIN, true, 1.0, true, 4.0);
	CVarTankLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_tank_diecount", "1", "How many dice can roll for the tank. Each die is added to a total. (If a die rolls 0 it is not thrown)", FCVAR_PLUGIN, true, 1.0, true, 3.0);
	CVarTankLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_tank_kit_min", "1", "Min die number for a tank to drop a kit.", FCVAR_PLUGIN, true, 0.0);
	CVarTankLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_tank_kit_max", "3", "Max die number for a tank to drop a kit.", FCVAR_PLUGIN, true, 0.0);
	CVarTankLoot[LOOT_WEAPON_MIN] = CreateConVar("l4d_loot_tank_weapon_min", "4", "Min die number for a tank to drop a weapon.", FCVAR_PLUGIN, true, 0.0);
	CVarTankLoot[LOOT_WEAPON_MAX] = CreateConVar("l4d_loot_tank_weapon_max", "5", "Max die number for a tank to drop a weapon.", FCVAR_PLUGIN, true, 0.0);
	CVarTankLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_tank_pills_min", "6", "Min die number for a tank to drop pills.", FCVAR_PLUGIN, true, 0.0);
	CVarTankLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_tank_pills_max", "8", "Max die number for a tank to drop pills.", FCVAR_PLUGIN, true, 0.0);
	CVarTankLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_tank_molly_min", "9", "Min die number for a tank to drop a molitov.", FCVAR_PLUGIN, true, 0.0);
	CVarTankLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_tank_molly_max", "9", "Max die number for a tank to drop a molitov.", FCVAR_PLUGIN, true, 0.0);
	CVarTankLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_tank_pipe_min", "10", "Min die number for a tank to drop a pipe bomb.", FCVAR_PLUGIN, true, 0.0);
	CVarTankLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_tank_pipe_max", "10", "Max die number for a tank to drop a pipe bomb.", FCVAR_PLUGIN, true, 0.0);
	CVarTankLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_tank_item_count", "2", "Max die number for a tank to drop a pipe bomb.", FCVAR_PLUGIN, true, 0.0);
	
	AutoExecConfig(true, "l4d_loot_drop");
}

public OnConfigsExecuted()
{
    // Change the enabled flag to the one the convar holds.
    if (GetConVarInt(CVarIsEnabled) == 1) 
	{
		HookEvent("player_death", Event_PlayerDeath);
		PullCVarValues();
	}
    else
	{
		UnhookEvent("player_death", Event_PlayerDeath);
	}
}

public Loot_EnableDisable(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
{
    // Change the enabled flag to the one the convar holds.
    if (GetConVarInt(CVarIsEnabled) == 1) 
	{
		HookEvent("player_death", Event_PlayerDeath);
		PullCVarValues();
	}
    else
	{
		UnhookEvent("player_death", Event_PlayerDeath);
	}
}

PullCVarValues()
{
	Dice[0] = GetConVarInt(CVarDieSides[0]);
	Dice[1] = GetConVarInt(CVarDieSides[1]);
	Dice[2] = GetConVarInt(CVarDieSides[2]);
	Dice[3] = GetConVarInt(CVarDieSides[3]);
	
	HunterLoot[LOOT_DIENUMBER] = GetConVarInt(CVarHunterLoot[LOOT_DIENUMBER])
	HunterLoot[LOOT_DIECOUNT] = GetConVarInt(CVarHunterLoot[LOOT_DIECOUNT])
	HunterLoot[LOOT_KIT_MIN] = GetConVarInt(CVarHunterLoot[LOOT_KIT_MIN])
	HunterLoot[LOOT_KIT_MAX] = GetConVarInt(CVarHunterLoot[LOOT_KIT_MAX])
	HunterLoot[LOOT_WEAPON_MIN] = GetConVarInt(CVarHunterLoot[LOOT_WEAPON_MIN])
	HunterLoot[LOOT_WEAPON_MAX] = GetConVarInt(CVarHunterLoot[LOOT_WEAPON_MAX])
	HunterLoot[LOOT_PILLS_MIN] = GetConVarInt(CVarHunterLoot[LOOT_PILLS_MIN])
	HunterLoot[LOOT_PILLS_MAX] = GetConVarInt(CVarHunterLoot[LOOT_PILLS_MAX])
	HunterLoot[LOOT_MOLLY_MIN] = GetConVarInt(CVarHunterLoot[LOOT_MOLLY_MIN])
	HunterLoot[LOOT_MOLLY_MAX] = GetConVarInt(CVarHunterLoot[LOOT_MOLLY_MAX])
	HunterLoot[LOOT_PIPE_MIN] = GetConVarInt(CVarHunterLoot[LOOT_PIPE_MIN])
	HunterLoot[LOOT_PIPE_MAX] = GetConVarInt(CVarHunterLoot[LOOT_PIPE_MAX])
	HunterLoot[LOOT_ITEM_COUNT] = GetConVarInt(CVarHunterLoot[LOOT_ITEM_COUNT])
	
	BoomerLoot[LOOT_DIENUMBER] = GetConVarInt(CVarBoomerLoot[LOOT_DIENUMBER])
	BoomerLoot[LOOT_DIECOUNT] = GetConVarInt(CVarBoomerLoot[LOOT_DIECOUNT])
	BoomerLoot[LOOT_KIT_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_KIT_MIN])
	BoomerLoot[LOOT_KIT_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_KIT_MAX])
	BoomerLoot[LOOT_WEAPON_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_WEAPON_MIN])
	BoomerLoot[LOOT_WEAPON_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_WEAPON_MAX])
	BoomerLoot[LOOT_PILLS_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_PILLS_MIN])
	BoomerLoot[LOOT_PILLS_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_PILLS_MAX])
	BoomerLoot[LOOT_MOLLY_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_MOLLY_MIN])
	BoomerLoot[LOOT_MOLLY_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_MOLLY_MAX])
	BoomerLoot[LOOT_PIPE_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_PIPE_MIN])
	BoomerLoot[LOOT_PIPE_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_PIPE_MAX])
	BoomerLoot[LOOT_ITEM_COUNT] = GetConVarInt(CVarBoomerLoot[LOOT_ITEM_COUNT])
	
	SmokerLoot[LOOT_DIENUMBER] = GetConVarInt(CVarSmokerLoot[LOOT_DIENUMBER])
	SmokerLoot[LOOT_DIECOUNT] = GetConVarInt(CVarSmokerLoot[LOOT_DIECOUNT])
	SmokerLoot[LOOT_KIT_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_KIT_MIN])
	SmokerLoot[LOOT_KIT_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_KIT_MAX])
	SmokerLoot[LOOT_WEAPON_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_WEAPON_MIN])
	SmokerLoot[LOOT_WEAPON_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_WEAPON_MAX])
	SmokerLoot[LOOT_PILLS_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_PILLS_MIN])
	SmokerLoot[LOOT_PILLS_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_PILLS_MAX])
	SmokerLoot[LOOT_MOLLY_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_MOLLY_MIN])
	SmokerLoot[LOOT_MOLLY_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_MOLLY_MAX])
	SmokerLoot[LOOT_PIPE_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_PIPE_MIN])
	SmokerLoot[LOOT_PIPE_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_PIPE_MAX])
	SmokerLoot[LOOT_ITEM_COUNT] = GetConVarInt(CVarSmokerLoot[LOOT_ITEM_COUNT])
	
	TankLoot[LOOT_DIENUMBER] = GetConVarInt(CVarTankLoot[LOOT_DIENUMBER])
	TankLoot[LOOT_DIECOUNT] = GetConVarInt(CVarTankLoot[LOOT_DIECOUNT])
	TankLoot[LOOT_KIT_MIN] = GetConVarInt(CVarTankLoot[LOOT_KIT_MIN])
	TankLoot[LOOT_KIT_MAX] = GetConVarInt(CVarTankLoot[LOOT_KIT_MAX])
	TankLoot[LOOT_WEAPON_MIN] = GetConVarInt(CVarTankLoot[LOOT_WEAPON_MIN])
	TankLoot[LOOT_WEAPON_MAX] = GetConVarInt(CVarTankLoot[LOOT_WEAPON_MAX])
	TankLoot[LOOT_PILLS_MIN] = GetConVarInt(CVarTankLoot[LOOT_PILLS_MIN])
	TankLoot[LOOT_PILLS_MAX] = GetConVarInt(CVarTankLoot[LOOT_PILLS_MAX])
	TankLoot[LOOT_MOLLY_MIN] = GetConVarInt(CVarTankLoot[LOOT_MOLLY_MIN])
	TankLoot[LOOT_MOLLY_MAX] = GetConVarInt(CVarTankLoot[LOOT_MOLLY_MAX])
	TankLoot[LOOT_PIPE_MIN] = GetConVarInt(CVarTankLoot[LOOT_PIPE_MIN])
	TankLoot[LOOT_PIPE_MAX] = GetConVarInt(CVarTankLoot[LOOT_PIPE_MAX])
	TankLoot[LOOT_ITEM_COUNT] = GetConVarInt(CVarTankLoot[LOOT_ITEM_COUNT])
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	decl String:strBuffer[48];
	new ClientId    = 0;
	
	ClientId = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (ClientId == 0) 
		return Plugin_Continue;
    
    // Determine if it's an infected.
	GetEventString(hEvent, "victimname", strBuffer, sizeof(strBuffer));
   
	if (StrEqual("Hunter", strBuffer))
	{

		SpawnItemFromDieResult(ClientId, 
							   HunterLoot,
							   RollDice(HunterLoot[LOOT_DIECOUNT], HunterLoot[LOOT_DIENUMBER]));
							   
	}
	else if (StrEqual(strBuffer, "Smoker"))
	{
		SpawnItemFromDieResult(ClientId, 
							   SmokerLoot,
							   RollDice(SmokerLoot[LOOT_DIECOUNT], SmokerLoot[LOOT_DIENUMBER]));
	}
	else if (StrEqual(strBuffer, "Boomer"))
	{
		SpawnItemFromDieResult(ClientId, 
							   BoomerLoot,
							   RollDice(BoomerLoot[LOOT_DIECOUNT], BoomerLoot[LOOT_DIENUMBER]));
	}
	else if (StrEqual(strBuffer, "Tank"))
	{
		SpawnItemFromDieResult(ClientId, 
							   BoomerLoot,
							   RollDice(TankLoot[LOOT_DIECOUNT], TankLoot[LOOT_DIENUMBER]));
	}
	
	return Plugin_Continue;
}

ExecuteCommand(Client, String:strCommand[], String:strParam1[])
{
	new flags = GetCommandFlags(strCommand);
    
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, flags);
}

Give(Client, String:itemId[])
{
	ExecuteCommand(Client, "give", itemId);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		if (GetClientTeam(i) == 2)
			PrintHintText(i,"Grab 1 autoshotgun, a gift from a killed special infected.");
	} 
	
}

RollDice(dieCount, dieId)
{
	SetRandomSeed(GetSysTickCount());
	
	new dieSides = Dice[dieId - 1];
	new result = 0;
	
	for (new i = 0; i < dieCount; i++)
	{
		new tempResult = GetRandomInt(0, dieSides);
		if (tempResult != 0)
			result += tempResult;
	}
	
	return result;
}

SpawnItemFromDieResult(client, diceSettings[13], dieResult)
{
	if (dieResult != 0 && diceSettings[LOOT_ITEM_COUNT] > 0)
	{
		for (new i = 0; i < diceSettings[LOOT_ITEM_COUNT]; i++)
		{
			if (dieResult >= diceSettings[LOOT_KIT_MIN] && dieResult <= diceSettings[LOOT_KIT_MAX])
				Give(client, "first_aid_kit");
			
			else if (dieResult >= diceSettings[LOOT_PIPE_MIN] && dieResult <= diceSettings[LOOT_PIPE_MAX])
				Give(client, "pipe_bomb");
			
			else if (dieResult >= diceSettings[LOOT_PILLS_MIN] && dieResult <= diceSettings[LOOT_PILLS_MAX])
				Give(client, "pain_pills");
			
			else if (dieResult >= diceSettings[LOOT_MOLLY_MIN] && dieResult <= diceSettings[LOOT_MOLLY_MAX])
				Give(client, "molotov");
			
			else if (dieResult >= diceSettings[LOOT_WEAPON_MIN] && dieResult <= diceSettings[LOOT_WEAPON_MAX])
			{
				new weapon = GetRandomInt(0, 5);
				
				switch(weapon) 
				{
					case 0: { 
						Give(client, "autoshotgun");
					}
					case 1: { 
						Give(client, "autoshotgun");
					}
					case 2: { 
						Give(client, "rifle");
					}
					case 3: { 
						Give(client, "rifle");
					}
					case 4: { 
						Give(client, "hunting_rifle");
					}
					case 5: { 
						Give(client, "hunting_rifle");
					}
				}

			}
		}
	}
}

















