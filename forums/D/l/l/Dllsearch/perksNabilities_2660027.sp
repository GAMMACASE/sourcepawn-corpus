#include <sourcemod>
#include <sdktools>
#include <sdktools_hooks>
#include <timers>
#include <tf2>
#include <tf2_stocks>
#include <adt_array>

public Plugin:myinfo = 
{
	name = "PerksNAbilities",
	author = "Dllsearch",
	description = "Adds abilities & AP, also S T O N K S",
	version = "0.0.6",
	url = "http://ntaddv.space"
} // ������))

enum perkdecks {
	civilian, // ��� �� ��������� ����
	rager, // ������
	runner, // �����
	spamer, // �������
	tank, // �������
	snake, //GAME OVER (Snake. Snake? SNAAAAAKE!!!)
	test,
	user //����������� ���� ������
	// 200MAD // for 200% M A D mode (it costs 200000 dollars to use this ability... for 12 seconds...
}; // ������ ������

float pnd_AbilityPoints[MAXPLAYERS + 1] = {0, ...}; //������, �������� ������� ������ �������
perkdecks pnd_Abilities[MAXPLAYERS + 1] = {0, ...}; //������, �������� ����� ����� ������ �������
float pnd_APMax[MAXPLAYERS + 1] = {0, ...}; //������, �������� ����. ���-�� AP ��������
int pnd_usersPerkDecks[MAXPLAYERS + 1][3]; //������, �������� ���� �������
int pnd_usersPerkDecksC[MAXPLAYERS + 1]; //
//int pnd_usersPerkDecks1[MAXPLAYERS + 1];
//int pnd_usersPerkDecks2[MAXPLAYERS + 1];
//int pnd_usersPerkDecks3[MAXPLAYERS + 1];
ConVar pnd_abl_chrg_k; // ���������� ����������, �����. ������� �����
ConVar pnd_abl_chrg_t; // ���������� ����������, �����. ������� ����� �� �������, ���� �� �����
// ConVar pnd_abl_num;

int perkTFCperks[22] = {
	TFCond_Bonked,
	TFCond_Buffed,
	TFCond_CritCola,
	TFCond_DefenseBuffed,
	TFCond_RegenBuffed,
	TFCond_SpeedBuffAlly,
	TFCond_CritHype,
	TFCond_DefenseBuffNoCritBlock,
	TFCond_UberBulletResist,
	TFCond_UberBlastResist,
	TFCond_UberFireResist,
	TFCond_SmallBulletResist,
	TFCond_SmallBlastResist,
	TFCond_SmallFireResist,
	TFCond_Stealthed,
	TFCond_PreventDeath,
	TFCond_HalloweenGiant,
	TFCond_HalloweenTiny,
	TFCond_HalloweenGhostMode,
	TFCond_Parachute,
	TFCond_SwimmingCurse,
	TFCond_KingAura
}

float perkPrices[22] = {
	1.0,
	2.0,
	3.0,
	4.0,
	5.0,
	6.0,
	7.0,
	8.0,
	9.0,
	10.0,
	11.0,
	12.0,
	13.0,
	14.0,
	15.0,
	16.0,
	17.0,
	18.0,
	19.0,
	20.0,
	21.0,
	22.0	
}

char perkNames[22][] = {
	"TFCond_Bonked",
	"TFCond_Buffed",
	"TFCond_CritCola",
	"TFCond_DefenseBuffed",
	"TFCond_RegenBuffed",
	"TFCond_SpeedBuffAlly",
	"TFCond_CritHype",
	"TFCond_DefenseBuffNoCritBlock",
	"TFCond_UberBulletResist",
	"TFCond_UberBlastResist",
	"TFCond_UberFireResist",
	"TFCond_SmallBulletResist",
	"TFCond_SmallBlastResist",
	"TFCond_SmallFireResist",
	"TFCond_Stealthed",
	"TFCond_PreventDeath",
	"TFCond_HalloweenGiant",
	"TFCond_HalloweenTiny",
	"TFCond_HalloweenGhostMode",
	"TFCond_Parachute",
	"TFCond_SwimmingCurse",
	"TFCond_KingAura"
}



public void OnPluginStart() //��� ������
{
	for (int ses = 0; ses < MAXPLAYERS + 1; ses++)
	{
		pnd_usersPerkDecks[ses] = {0,0,0};
	}
	HookEvent("player_hurt", charger); //������ ������� �� ���
	pnd_abl_chrg_k = CreateConVar("pnd_abl_chrg_k", "1.42", "Coefficient of taking ability points", _, true, 0.00, true, 100.00); //������ � ������� ����������
	pnd_abl_chrg_t = CreateConVar("pnd_abl_chrg_t", "0.42", "Coefficient of taking ability points", _, true, 0.00, true, 100.00); //������ ����������
	// pnd_abl_num = CreateConVar("pnd_abl_num", "0", "Description");
	
	HookConVarChange(pnd_abl_chrg_k, conVarKChanged); // ��������� �� ��������� ����������
	HookConVarChange(pnd_abl_chrg_k, conVarTChanged); // ������
	
	
	RegConsoleCmd("pna_ability_use", useAbility); // ������ �������� ������ ������ � �������
	
	//RegConsoleCmd("pna_ability_new", setAbility);
	
	RegConsoleCmd("perks", perkDeckPanel); // ������ �������� ������� ����� ����� � �������
	
}

public void OnClientPutInServer(int client) //����� ����� ������ �� ������
{
	pnd_AbilityPoints[client] = 0; // ����������� 0 ���� ������ ����� �����
	pnd_Abilities[client] = 0; // � 0� ���� (����, ��� �� �������)
	pnd_APMax[client] = 100.0; // ������ ����� AP � 100.0
	perkDeckPanel(client, 0); // ���� ������ �������������, ���������� ������� ����
	
	pnd_usersPerkDecksC[client] = 0;
	
	CreateTimer (1.0, chargeHUD, client, TIMER_REPEAT );
	///
	CreateTimer (1.0, time_charger, client, TIMER_REPEAT );
}

public OnClientConnected(int client) //����� ���� �������, �� � �� ���� (����)
{
	
}

 public conVarKChanged(ConVar convar, const char[] oldValue, const char[] newValue) // ����������, ���� ConVar ���������� ��������
 {
 	float next = StringToFloat(newValue);
	SetConVarFloat(pnd_abl_chrg_k, next, true, true); // ������ ConVar
 }
 
 public conVarTChanged(ConVar convar, const char[] oldValue, const char[] newValue) // ����������, ���� ConVar ���������� ��������
 {
 	float next = StringToFloat(newValue);
	SetConVarFloat(pnd_abl_chrg_t, next, true, true); // ������ ConVar
 }
 
 public Action chargeHUD (Handle timer, int client)  // ����� ������������ ������ �� �����
 {
	if (IsClientConnected(client) && IsClientInGame(client)) // ���� ����� ������
	{
		
		SetHudTextParams(0.15, 0.07, 0.9, 255, 255, 255, 255, 2, 0.02, 0.01, 0.01); // ���������� ���������, �����, ����, ������, ����� �������� ��� ������
		char ses[5];
		FloatToString(pnd_AbilityPoints[client], ses, 5);
		ShowHudText(client, -1, "PNA %s %%", ses); // ������ �����
	}
 }
 
 /// --- /// --- /// --- ///
 
public int perkDeckPanelHandler(Menu menu, MenuAction action, int client, int ablt) // ������� ��������� ����� ����
{
	if (action == MenuAction_Select)
	{
		if(ablt == 7) 
		{
			Comm_BuildPerkDeck(client, 0);
			pnd_usersPerkDecksC[client] = 0;
		}
		PrintToConsole(client, "You selected perk # %d", ablt);
		pnd_Abilities[client] = ablt;
	}
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", client, ablt);
	}
}
 
public Action perkDeckPanel(int client, int args) // ������ ������� ������ ������� ������
{
	Panel panel = new Panel();
	panel.SetTitle("!perks | Choose your perkdeck. | bind pnd_ability_use to activate");
	panel.DrawItem("rager");
	panel.DrawItem("runner");
	panel.DrawItem("spamer");
	panel.DrawItem("tank");
	panel.DrawItem("snake");
	panel.DrawItem("BDSM");
	panel.DrawItem("Make your OWN perkdeck! (BETA)");
 
	panel.Send(client, perkDeckPanelHandler, MENU_TIME_FOREVER);
 
	delete panel;
 
	return Plugin_Handled;
}

/// --- /// --- /// --- ///

Menu BuildMapMenu()
{
	Menu menu = new Menu(Menu_BuildPerkDeck);
	for (int o = 0; o < sizeof(perkNames); o++)
	{
		menu.AddItem(perkNames[o], perkNames[o]);
	}
	menu.SetTitle("!perks | Choose your perks | bind pnd_ability_use to activate");
	return menu;
}

public int Menu_BuildPerkDeck(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		/*
		char info[32];
		bool found = menu.GetItem(item, info, sizeof(info));
		PrintToConsole(client, "You selected item: %d (found? %d info: %s)", item, found, info);
		ServerCommand("changelevel %s", info); 
		*/
		if (pnd_usersPerkDecksC[client] < 3)
		{
			pnd_usersPerkDecks[client][pnd_usersPerkDecksC[client]] = item;
			pnd_usersPerkDecksC[client]++;
			if (pnd_usersPerkDecksC[client] < 3) Comm_BuildPerkDeck(client, 0);
		}
	}
}

public Action Comm_BuildPerkDeck(int client, int args)
{ 
	Menu menu = BuildMapMenu();
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

/// --- /// --- /// --- ///
public Action useAbility(int client, int args) //���������� ��� pna_use_ability
{
	char arg[128];
	char full[256];
 
	/* GetCmdArgString(full, sizeof(full));
 
	if (client)
	{
		PrintToServer("Command pna_ability_use from client %d", client);
	} else {
		PrintToServer("Command pna_ability_use from... server?");
	}
 
	PrintToServer("Argument string: %s", full);
	PrintToServer("Argument count: %d", args);
	for (int i=1; i<=args; i++)
	{
		GetCmdArg(i, arg, sizeof(arg));
		PrintToServer("Argument %d: %s", i, arg);
	}
	*/
	if ( pnd_AbilityPoints[client] == 100.00 ) // ���� ������ ��������
	{
		// ������� � ����� �����. SWITCH ��� ������ ����, ��� ���, �������� ������ ����� if else
		//pnd_AbilityPoints[client] = 0.00;
		if (pnd_Abilities[client] == 0) 
			{
				perkDeckPanel(client, 0); // ���� ���� 0 (�� �������), �� ���������� �������
				pnd_AbilityPoints[client] = 100.00;
			}
		else if (pnd_Abilities[client] == 1) frager(client); //����� ����
		else if (pnd_Abilities[client] == 2) frunner(client); //same
		else if (pnd_Abilities[client] == 3) fspamer(client);
		else if (pnd_Abilities[client] == 4) ftank(client);
		else if (pnd_Abilities[client] == 5) fsnake(client);
		else if (pnd_Abilities[client] == 6) testin(client);
		else if (pnd_Abilities[client] == 7) 
		{
			//perkDeckPanel(client, 0);
			//Comm_BuildPerkDeck(client, 0);
			float pushittothelimit = pnd_AbilityPoints[client] / ( perkPrices[pnd_usersPerkDecks[client][0]] + perkPrices[pnd_usersPerkDecks[client][1]] + perkPrices[pnd_usersPerkDecks[client][2]] );
			int [] buttsecs = new int[pnd_usersPerkDecksC[client]];
			for (int x = 0; x < pnd_usersPerkDecksC[client]; x++)
			{
				buttsecs[x] = perkTFCperks[pnd_usersPerkDecks[client][x]];
			}
			pna_addcond(buttsecs, client, pushittothelimit, pnd_usersPerkDecksC[client]);
			pnd_AbilityPoints[client] = 0;
		}
		PrintToChat(client, "ABILITY USED"); // ����� � ���, ��� ������ ������������
	}
	else //���� ��� �� ��������, ����� 
	{
		char ses[5];
		FloatToString(pnd_AbilityPoints[client], ses, 5);
		PrintToChat(client, "ABILITY: %s%% charged", ses); //������� ������ � ���
	}
	
	return Plugin_Handled; //��������, ��� ���������
} 

public void userPerkdeckUse (int client) // ��������� ������ �����
{
	//float price = perkPrices[pnd_usersPerkDecks[client][1]] + perkPrices[pnd_usersPerkDecks[client][2]] + perkPrices[pnd_usersPerkDecks[client][3]]; // ���������� ��������� ������ ������ � ����� ���������
	float price = perkPrices[pnd_usersPerkDecks[client][0]] + perkPrices[pnd_usersPerkDecks[client][1]] + perkPrices[pnd_usersPerkDecks[client][2]]; // ���������� ��������� ������ ������ � ����� ���������
	float secks = pnd_AbilityPoints[client]/price; // ����� AP ������ �� ����� ��������� ������, �������� ���-�� ������ ������
	pna_addcond (pnd_usersPerkDecks[client][0], client, secks, 3); // ��������� ��������� ������ ������ �� ���������� �����
}

public void frager(int client) //������� ��������� "Rager"
{
	int conds[4] = {19, 26, 29, 60};
	int limits = sizeof(conds);
	pna_addcond (conds, client, 17.50, limits);
	discharge(client, 56.00);
}

public void frunner(int client) //������� ��������� "Runner"
{
	int conds[3] = {26, 42, 72};
	int limits = sizeof(conds);
	pna_addcond (conds, client, 6.50, limits);
	discharge(client, 22.00);
}

public void fspamer(int client) //������� ��������� "Spammer"
{
	int conds[3] = {16, 72, 91};
	int limits = sizeof(conds);
	pna_addcond (conds, client, 13.33, limits);
	discharge(client, 78.00);
}

public void ftank(int client) //������� ��������� "TAAANK!"
{
	int conds[6] = {26, 42, 61, 62, 63, 73};
	int limits = sizeof(conds);
	//TF2_RegeneratePlayer(client);
	pna_addcond (conds, client, 25.00, limits);
	discharge(client, 100.00);
}

public void fsnake(int client) //������� ��������� "(solid) Snake"
{
	int conds[4] = {32, 66};
	int limits = sizeof(conds);
	pna_addcond (conds, client, 7.00, limits);
	discharge(client, 30.00);
}

public void testin(int client) //test
{
	int conds[4] = {24,25,27};
	int limits = sizeof(conds);
	pna_addcond (conds, client, 3.00, limits);
	discharge(client, 5.00);
}

public charger(Event hEvent, const char[] name, bool dontBroadcast) //�������, ����������, ����� ���-�� ����-�� ����
{
	int attacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	damage_charger(attacker, pnd_abl_chrg_k.FloatValue);
	/*	
	int attacked = GetClientOfUserId(hEvent.GetInt("userid"));
	for(int x = 0; x < 3; x++)
	{
		if(isAttackingPerk[pnd_usersPerkDecks[attacker][y]])
		{
			perkHitCond(attacked, perkTFCperks[pnd_usersPerkDecks[attacker][y]]);
		}
	}
	*/
}

public void damage_charger(int client, float points) //������� �������
{
	// ������ ��� ������� �� ������ ������. ���� ���� ���������� - ���������� ������� ���������� �� ����������� ��� ������
	if (TF2_GetPlayerClass(client) == TFClass_Pyro) points *= 0.39; // ���� ����� ����, �� 42% �� �
	else if (TF2_GetPlayerClass(client) == TFClass_Heavy) points *= 0.74;// ���� ����� ���� 80% �� �
	else if (TF2_GetPlayerClass(client) == TFClass_DemoMan) points *= 0.80; // ���
	else if (TF2_GetPlayerClass(client) == TFClass_Soldier) points *= 0.85;
	else if (TF2_GetPlayerClass(client) == TFClass_Engineer) points *= 1.01;// ���� ����� ���, 101% �� �
	else if (TF2_GetPlayerClass(client) == TFClass_Spy) points *= 1.13;
	else if (TF2_GetPlayerClass(client) == TFClass_Sniper) points *= 1.17;
	else if (TF2_GetPlayerClass(client) == TFClass_Scout) points *= 1.33;
	else if (TF2_GetPlayerClass(client) == TFClass_Medic) points *= 1.57;
	/// --- ///
	pnd_AbilityPoints[client] += points; // ���������� ������
	if (pnd_AbilityPoints[client] > pnd_APMax[client]) pnd_AbilityPoints[client] = pnd_APMax[client];  // ���� ���������� ������ ������, ������ ������ ������
}

public void discharge(int client, float points) //��������
{
	pnd_AbilityPoints[client] -= points; // ������� ������
	if (pnd_AbilityPoints[client] < 0.00) pnd_AbilityPoints[client] = 0.00; //���� <0, ������ 0
}

public Action time_charger(Handle timer, int client) //������� �� �������
{
	if (IsClientInGame(client) && !IsFakeClient(client) && (pnd_AbilityPoints[client] < pnd_APMax[client])) // ���� � ������ ����, �� ��������, � ����� ������ ������
		pnd_AbilityPoints[client] += pnd_abl_chrg_t.FloatValue; // ���������� �
	if (pnd_AbilityPoints[client] > pnd_APMax[client]) pnd_AbilityPoints[client] = pnd_APMax[client];  // ���� ���������� ������ ������, ������ ������ ������
}


// ������ ���������, ����������� addcond
TFCond tfca[128] = {
	TFCond_Slowed,	// 0
	TFCond_Zoomed,
	TFCond_Disguising,
	TFCond_Disguised,
	TFCond_Cloaked,	
	TFCond_Ubercharged, // 5
	TFCond_TeleportedGlow,
	TFCond_Taunting,
	TFCond_UberchargeFading,
	//TFCond_Unknown1,
	TFCond_CloakFlicker, 
	TFCond_Teleporting, // 10
	TFCond_Kritzkrieged,
	//TFCond_Unknown2,
	TFCond_TmpDamageBonus,
	TFCond_DeadRingered,
	TFCond_Bonked,
	TFCond_Dazed, // 15
	TFCond_Buffed,
	TFCond_Charging,
	TFCond_DemoBuff,
	TFCond_CritCola,
	TFCond_InHealRadius, //20
	TFCond_Healing,
	TFCond_OnFire,
	TFCond_Overhealed,
	TFCond_Jarated,
	TFCond_Bleeding, //25
	TFCond_DefenseBuffed,
	TFCond_Milked,
	TFCond_MegaHeal,
	TFCond_RegenBuffed,
	TFCond_MarkedForDeath, //30
	TFCond_NoHealingDamageBuff,
	TFCond_SpeedBuffAlly,
	TFCond_HalloweenCritCandy,
	TFCond_CritCanteen,
	TFCond_CritDemoCharge,
	TFCond_CritHype,
	TFCond_CritOnFirstBlood,
	TFCond_CritOnWin,
	TFCond_CritOnFlagCapture,
	TFCond_CritOnKill, //40
	TFCond_RestrictToMelee,
	TFCond_DefenseBuffNoCritBlock,
	TFCond_Reprogrammed,
	TFCond_CritMmmph,
	TFCond_DefenseBuffMmmph,
	TFCond_FocusBuff,
	TFCond_DisguiseRemoved,
	TFCond_MarkedForDeathSilent,
	TFCond_DisguisedAsDispenser,
	TFCond_Sapped, //50
	TFCond_UberchargedHidden,
	TFCond_UberchargedCanteen,
	TFCond_HalloweenBombHead,
	TFCond_HalloweenThriller,
	TFCond_RadiusHealOnDamage,
	TFCond_CritOnDamage,
	TFCond_UberchargedOnTakeDamage,
	TFCond_UberBulletResist,
	TFCond_UberBlastResist,
	TFCond_UberFireResist, //60
	TFCond_SmallBulletResist,
	TFCond_SmallBlastResist,
	TFCond_SmallFireResist,
	TFCond_Stealthed,
	TFCond_MedigunDebuff,
	TFCond_StealthedUserBuffFade,
	TFCond_BulletImmune,
	TFCond_BlastImmune,
	TFCond_FireImmune,
	TFCond_PreventDeath, //70
	TFCond_MVMBotRadiowave,
	TFCond_HalloweenSpeedBoost,
	TFCond_HalloweenQuickHeal,
	TFCond_HalloweenGiant,
	TFCond_HalloweenTiny,
	TFCond_HalloweenInHell,
	TFCond_HalloweenGhostMode,
	TFCond_MiniCritOnKill,
	TFCond_ObscuredSmoke, //TFCond_DodgeChance,
	TFCond_Parachute, //80
	TFCond_BlastJumping,
	TFCond_HalloweenKart,
	TFCond_HalloweenKartDash,
	TFCond_BalloonHead,
	TFCond_MeleeOnly,
	TFCond_SwimmingCurse,
	TFCond_FreezeInput, //TFCond_HalloweenKartNoTurn,
	TFCond_HalloweenKartCage,
	TFCond_HasRune,
	TFCond_RuneStrength, //90
	TFCond_RuneHaste,
	TFCond_RuneRegen,
	TFCond_RuneResist,
	TFCond_RuneVampire,
	TFCond_RuneWarlock,
	TFCond_RunePrecision,
	TFCond_RuneAgility,
	TFCond_GrapplingHook,
	TFCond_GrapplingHookSafeFall,
	TFCond_GrapplingHookLatched, //100
	TFCond_GrapplingHookBleeding,
	TFCond_AfterburnImmune,
	TFCond_RuneKnockout,
	TFCond_RuneImbalance,
	TFCond_CritRuneTemp,
	TFCond_PasstimeInterception,
	TFCond_SwimmingNoEffects,
	TFCond_EyeaductUnderworld,
	TFCond_KingRune,
	TFCond_PlagueRune, //110
	TFCond_SupernovaRune,
	TFCond_Plague,
	TFCond_KingAura,
	TFCond_SpawnOutline,
	TFCond_KnockedIntoAir,
	TFCond_CompetitiveWinner,
	TFCond_CompetitiveLoser,
	//TFCond_NoTaunting,
	//TFCond_NoTaunting_DEPRECATED,
	TFCond_HealingDebuff,
	TFCond_PasstimePenaltyDebuff,
	TFCond_GrappledToPlayer, // 120
	TFCond_GrappledByPlayer,
	TFCond_ParachuteDeployed,
	TFCond_Gas,
	TFCond_BurningPyro,
	TFCond_RocketPack, // 125
	TFCond_LostFooting,
	TFCond_AirCurrent // 127
}

public pna_addcond (int[] conds, int client, float time, int length) //�������, ����������� ��������, �������� � �������
{
	for (int c=0; c<length; c++)
	{
		TF2_AddCondition(client, tfca[conds[c]], time, 0); // ��������� ��������, ��������� ������ �� �������, ����������� �� ����� ��������
	}
}

public pna_removecond (int[] conds, int client, int length) //������� ��������� �� ��������
{
	int c = 0;
	while (c < length)
	{
		TF2_RemoveCondition(client, tfca[conds[c]]);
		c++;
	}
}

/// --- /// --- /// --- ///

//����� ������ ���� ������� � ����� �� ���������� ������, �� �������������� � ArrayList?
/*bool isAttackingPerk[22] = {
	false,
	false,	
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false
}*/
//ArrayList CondShop = new ArrayList(3, 129); 
// CondShop.Push