// Credits? Look here: http://git.tf/TTT/Plugin/blob/master/CREDITS.md


#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <multicolors>
#include <emitsoundany>
#include <ttt>

#pragma newdecls required

#define SND_TCHAT "buttons/button18.wav"
#define SND_FLASHLIGHT "items/flashlight1.wav"

#define TRAITORS_AMOUNT 0.25
#define DETECTIVES_AMOUNT 0.13

enum eConfig
{
	ConVar:c_shopKEVLAR,
	ConVar:c_shop1KNIFE,
	ConVar:c_shopDNA,
	ConVar:c_shopID,
	ConVar:c_shopFAKEID,
	ConVar:c_shopRadar,
	ConVar:c_shopT,
	ConVar:c_shopD,
	ConVar:c_shopTASER,
	ConVar:c_shopUSP,
	ConVar:c_shopM4A1,
	ConVar:c_shopJIHADBOMB,
	ConVar:c_shopC4,
	ConVar:c_shopHEALTH,
	ConVar:c_requiredPlayersD,
	ConVar:c_requiredPlayers,
	ConVar:c_startKarma,
	ConVar:c_karmaBan,
	ConVar:c_karmaBanLength,
	ConVar:c_maxKarma,
	ConVar:c_spawnHPT,
	ConVar:c_spawnHPD,
	ConVar:c_spawnHPI,
	ConVar:c_karmaII,
	ConVar:c_karmaIT,
	ConVar:c_karmaID,
	ConVar:c_karmaTI,
	ConVar:c_karmaTT,
	ConVar:c_karmaTD,
	ConVar:c_karmaDI,
	ConVar:c_karmaDT,
	ConVar:c_karmaDD,
	ConVar:c_creditsII,
	ConVar:c_creditsIT,
	ConVar:c_creditsID,
	ConVar:c_creditsTI,
	ConVar:c_creditsTT,
	ConVar:c_creditsTD,
	ConVar:c_creditsDI,
	ConVar:c_creditsDT,
	ConVar:c_creditsDD,
	ConVar:c_creditsFoundBody,
	ConVar:c_creditsTaserHurtTraitor,
	ConVar:c_traitorloseAliveNonTraitors,
	ConVar:c_traitorloseDeadNonTraitors,
	ConVar:c_traitorwinAliveTraitors,
	ConVar:c_traitorwinDeadTraitors,
	ConVar:c_showDeathMessage,
	ConVar:c_showKillMessage,
	ConVar:c_showEarnKarmaMessage,
	ConVar:c_showEarnCreditsMessage,
	ConVar:c_showLoseKarmaMessage,
	ConVar:c_showLoseCreditsMessage,
	ConVar:c_messageTypKarma,
	ConVar:c_messageTypCredits,
	ConVar:c_blockSuicide,
	ConVar:c_allowFlash,
	ConVar:c_blockLookAtWeapon,
	ConVar:c_blockGrenadeMessage,
	ConVar:c_blockRadioMessage,
	ConVar:c_enableNoBlock,
	ConVar:c_pluginTag,
	ConVar:c_kadRemover,
	ConVar:c_rulesType,
	ConVar:c_rulesLink,
	ConVar:c_rulesClosePunishment,
	ConVar:c_punishInnoKills,
	ConVar:c_timeToReadRules,
	ConVar:c_timeToReadDetectiveRules
};

int g_iConfig[eConfig];

int g_iCredits[MAXPLAYERS + 1] =  { 800, ... };

bool g_bHasC4[MAXPLAYERS + 1] =  { false, ... };

int g_iRDMAttacker[MAXPLAYERS + 1] =  { -1, ... };
Handle g_hRDMTimer[MAXPLAYERS + 1] =  { null, ... };
bool g_bImmuneRDMManager[MAXPLAYERS + 1] =  { false, ... };
bool g_bHoldingProp[MAXPLAYERS + 1] =  { false, ... };
bool g_bHoldingSilencedWep[MAXPLAYERS + 1] =  { false, ... };

int g_iAccount;

Handle g_hExplosionTimer[MAXPLAYERS + 1] =  { null, ... };
bool g_bHasActiveBomb[MAXPLAYERS + 1] =  { false, ... };
int g_iWire[MAXPLAYERS + 1] =  { -1, ... };
int g_iDefusePlayerIndex[MAXPLAYERS + 1] =  { -1, ... };

int g_iHealthStationCharges[MAXPLAYERS + 1] =  { 0, ... };
int g_iHealthStationHealth[MAXPLAYERS + 1] =  { 0, ... };
bool g_bHasActiveHealthStation[MAXPLAYERS + 1] =  { false, ... };
bool g_bOnHealingCoolDown[MAXPLAYERS + 1] =  { false, ... };
Handle g_hRemoveCoolDownTimer[MAXPLAYERS + 1] =  { null, ... };

bool g_b1Knife[MAXPLAYERS + 1] =  { false, ... };
bool g_bScan[MAXPLAYERS + 1] =  { false, ... };
bool g_bJihadBomb[MAXPLAYERS + 1] =  { false, ... };
bool g_bID[MAXPLAYERS + 1] =  { false, ... };
// bool g_bRadar[MAXPLAYERS + 1] =  { false, ... };
Handle g_hJihadBomb[MAXPLAYERS + 1] =  { null, ... };
int g_iRole[MAXPLAYERS + 1] =  { 0, ... };

int g_iInnoKills[MAXPLAYERS + 1];

Handle g_hGraceTime = null;

Handle g_hStartTimer = null;
Handle g_hPlayerArray = null;

int g_iIcon[MAXPLAYERS + 1] =  { 0, ... };

bool g_bRoundStarted = false;

Handle g_hRoundTimer = null;

bool g_bInactive = false;

int g_iCollisionGroup = -1;

bool g_bKarma[MAXPLAYERS + 1] =  { false, ... };
int g_iKarma[MAXPLAYERS + 1] =  { 0, ... };

Handle g_hRagdollArray = null;

int g_iBeamSprite = -1;
int g_iHaloSprite = -1;

bool g_bFound[MAXPLAYERS + 1] = {false, ...};
bool g_bDetonate[MAXPLAYERS + 1] = {false, ...};

int g_iAlive = -1;
int g_iKills = -1;
int g_iDeaths = -1;
int g_iAssists = -1;

char g_sBadNames[256][MAX_NAME_LENGTH];
int g_iBadNameCount = 0;

Handle g_hDatabase = null;

enum Ragdolls
{
	ent,
	victim,
	attacker,
	String:victimName[32],
	String:attackerName[32],
	bool:scanned,
	Float:gameTime,
	String:weaponused[32],
	bool:found
}

bool g_bReceivingLogs[MAXPLAYERS+1];

Handle g_hLogsArray;

bool g_bReadRules[MAXPLAYERS + 1] =  { false, ... };
bool g_bKnowRules[MAXPLAYERS + 1] =  { false, ... };

bool g_bConfirmDetectiveRules[MAXPLAYERS + 1] =  { false, ... };

char g_sTag[MAX_MESSAGE_LENGTH];


char g_sShopCMDs[][] = {
	"menu",
	"shop"
};

char g_sRadioCMDs[][] = {
	"coverme",
	"takepoint",
	"holdpos",
	"regroup",
	"followme",
	"takingfire",
	"go",
	"fallback",
	"sticktog",
	"getinpos",
	"stormfront",
	"report",
	"roger",
	"enemyspot",
	"needbackup",
	"sectorclear",
	"inposition",
	"reportingin",
	"getout",
	"negative",
	"enemydown",
	"compliment",
	"thanks",
	"cheer"
};

public Plugin myinfo =
{
	name = TTT_PLUGIN_NAME,
	author = TTT_PLUGIN_AUTHOR,
	description = TTT_PLUGIN_DESCRIPTION,
	version = TTT_PLUGIN_VERSION,
	url = TTT_PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("ttt");
	return APLRes_Success;
}

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("Only CS:GO is supported");
		return;
	}
	
	if (!SQL_CheckConfig("ttt"))
	{
		SetFailState("(OnPluginStart) Database failure: Couldn't find Database entry \"ttt\"");
		return;
	}
	else
		SQL_TConnect(SQLConnect, "ttt");
	
	LoadTranslations("ttt.phrases");
	LoadTranslations("common.phrases");
	
	LoadBadNames();
	
	g_hRagdollArray = CreateArray(102);
	g_hPlayerArray = CreateArray();
	g_hLogsArray = CreateArray(512);
	
	g_iCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	

	CreateTimer(0.1, Timer_Adjust, _, TIMER_REPEAT);
	CreateTimer(1.0, healthStationDistanceCheck, _, TIMER_REPEAT);
	CreateTimer(5.0, Timer_5, _, TIMER_REPEAT);
	
	RegAdminCmd("sm_setrole", Command_SetRole, ADMFLAG_ROOT);
	RegAdminCmd("sm_karmareset", Command_KarmaReset, ADMFLAG_ROOT);
	RegAdminCmd("sm_setkarma", Command_SetKarma, ADMFLAG_ROOT);
	RegAdminCmd("sm_setcredits", Command_SetCredits, ADMFLAG_ROOT);
	
	RegConsoleCmd("sm_status", Command_Status);
	RegConsoleCmd("sm_karma", Command_Karma);
	RegConsoleCmd("sm_credits", Command_Credits);
	RegConsoleCmd("sm_boom", Command_Detonate); 
	RegConsoleCmd("sm_jihad_detonate", Command_Detonate); 
	RegConsoleCmd("sm_logs", Command_Logs);
	RegConsoleCmd("sm_log", Command_Logs);
	RegConsoleCmd("sm_id", Command_ID);
	
	for (int i = 0; i < sizeof(g_sShopCMDs); i++)
	{
		char sBuffer[64];
		Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sShopCMDs[i]);
		RegConsoleCmd(sBuffer, Command_Shop);
	}
	
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundStartPre, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEndPre, EventHookMode_Pre);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_changename", Event_ChangeName);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	
	g_hGraceTime = FindConVar("mp_join_grace_time");
	
	AddCommandListener(Command_LAW, "+lookatweapon");
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_SayTeam, "say_team");
	AddCommandListener(Command_InterceptSuicide, "kill");
	AddCommandListener(Command_InterceptSuicide, "explode");
	AddCommandListener(Command_InterceptSuicide, "spectate");
	AddCommandListener(Command_InterceptSuicide, "jointeam");
	AddCommandListener(Command_InterceptSuicide, "joinclass");
	
	for(int i= 0; i < sizeof(g_sRadioCMDs); i++)
	{
		AddCommandListener(Command_RadioCMDs, g_sRadioCMDs[i]);
	}
	
	CreateConVar("ttt2_version", TTT_PLUGIN_VERSION, TTT_PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_iConfig[c_shopKEVLAR] = CreateConVar("ttt_shop_kevlar", "2500");
	g_iConfig[c_shop1KNIFE] = CreateConVar("ttt_shop_1knife", "5000");
	g_iConfig[c_shopDNA] = CreateConVar("ttt_shop_dna_scanner", "5000");
	g_iConfig[c_shopID] = CreateConVar("ttt_shop_id_card", "500");
	// g_iConfig[c_shopRadar] = CreateConVar("ttt_shop_radar", "7000");
	g_iConfig[c_shopFAKEID] = CreateConVar("ttt_shop_fake_id_card", "3000");
	g_iConfig[c_shopT] = CreateConVar("ttt_shop_t", "100000");
	g_iConfig[c_shopD] = CreateConVar("ttt_shop_d", "5000");
	g_iConfig[c_shopTASER] = CreateConVar("ttt_shop_taser", "3000");
	g_iConfig[c_shopUSP] = CreateConVar("ttt_shop_usp", "3000");
	g_iConfig[c_shopM4A1] = CreateConVar("ttt_shop_m4a1", "6000");
	g_iConfig[c_shopJIHADBOMB] = CreateConVar("ttt_shop_jihad_bomb", "6000");
	g_iConfig[c_shopC4] = CreateConVar("ttt_shop_c4", "10000");
	g_iConfig[c_shopHEALTH] = CreateConVar("ttt_shop_health_station", "3000");
	
	g_iConfig[c_requiredPlayersD] = CreateConVar("ttt_required_players_detective", "6");
	g_iConfig[c_requiredPlayers] = CreateConVar("ttt_required_player", "3");
	
	g_iConfig[c_startKarma] = CreateConVar("ttt_start_karma", "100");
	g_iConfig[c_karmaBan] = CreateConVar("ttt_with_karma_ban", "75"); // 0 = disabled
	g_iConfig[c_karmaBanLength] = CreateConVar("ttt_with_karma_ban_length", "10080"); // one week = 10080 minutes
	g_iConfig[c_maxKarma] = CreateConVar("ttt_max_karma", "150");
	
	g_iConfig[c_spawnHPT] = CreateConVar("ttt_spawn_t", "100");
	g_iConfig[c_spawnHPD] = CreateConVar("ttt_spawn_d", "100");
	g_iConfig[c_spawnHPI] = CreateConVar("ttt_spawn_i", "100");
	
	g_iConfig[c_karmaII] = CreateConVar("ttt_karma_killer_innocent_victim_innocent_subtract", "5");
	g_iConfig[c_karmaIT] = CreateConVar("ttt_karma_killer_innocent_victim_traitor_add", "5");
	g_iConfig[c_karmaID] = CreateConVar("ttt_karma_killer_innocent_victim_detective_subtract", "7");
	g_iConfig[c_karmaTI] = CreateConVar("ttt_karma_killer_traitor_victim_innocent_add", "2");
	g_iConfig[c_karmaTT] = CreateConVar("ttt_karma_killer_traitor_victim_traitor_subtract", "5");
	g_iConfig[c_karmaTD] = CreateConVar("ttt_karma_killer_traitor_victim_detective_add", "3");
	g_iConfig[c_karmaDI] = CreateConVar("ttt_karma_killer_detective_victim_innocent_subtract", "3");
	g_iConfig[c_karmaDT] = CreateConVar("ttt_karma_killer_detective_victim_traitor_add", "7");
	g_iConfig[c_karmaDD] = CreateConVar("ttt_karma_killer_detective_victim_detective_subtract", "7");
	
	g_iConfig[c_creditsII] = CreateConVar("ttt_credits_killer_innocent_victim_innocent_subtract", "1500");
	g_iConfig[c_creditsIT] = CreateConVar("ttt_credits_killer_innocent_victim_traitor_add", "3000");
	g_iConfig[c_creditsID] = CreateConVar("ttt_credits_killer_innocent_victim_detective_subtract", "4200");
	g_iConfig[c_creditsTI] = CreateConVar("ttt_credits_killer_traitor_victim_innocent_add", "600");
	g_iConfig[c_creditsTT] = CreateConVar("ttt_credits_killer_traitor_victim_traitor_subtract", "3000");
	g_iConfig[c_creditsTD] = CreateConVar("ttt_credits_killer_traitor_victim_detective_add", "4200");
	g_iConfig[c_creditsDI] = CreateConVar("ttt_credits_killer_detective_victim_innocent_subtract", "300");
	g_iConfig[c_creditsDT] = CreateConVar("ttt_credits_killer_detective_victim_traitor_add", "2100");
	g_iConfig[c_creditsDD] = CreateConVar("ttt_credits_killer_detective_victim_detective_subtract", "300");
	
	g_iConfig[c_traitorloseAliveNonTraitors] = CreateConVar("ttt_credits_roundend_traitorlose_alive_nontraitors", "4800");
	g_iConfig[c_traitorloseDeadNonTraitors] = CreateConVar("ttt_credits_roundend_traitorlose_dead_nontraitors", "1200");
	g_iConfig[c_traitorwinAliveTraitors] = CreateConVar("ttt_credits_roundend_traitorwin_alive_traitors", "4800");
	g_iConfig[c_traitorwinDeadTraitors] = CreateConVar("ttt_credits_roundend_traitorwin_dead_traitors", "1200");
	
	g_iConfig[c_creditsFoundBody] = CreateConVar("ttt_credits_found_body_add", "1200");
	g_iConfig[c_creditsTaserHurtTraitor] = CreateConVar("ttt_hurt_traitor_with_taser", "2000");
	
	g_iConfig[c_showDeathMessage] = CreateConVar("ttt_show_death_message", "1");
	g_iConfig[c_showKillMessage] = CreateConVar("ttt_show_kill_message", "1");
	
	g_iConfig[c_showEarnKarmaMessage] = CreateConVar("ttt_show_message_earn_karma", "1");
	g_iConfig[c_showEarnCreditsMessage] = CreateConVar("ttt_show_message_earn_credits", "1");
	g_iConfig[c_showLoseKarmaMessage] = CreateConVar("ttt_show__message_lose_karmna", "1");
	g_iConfig[c_showLoseCreditsMessage] = CreateConVar("ttt_show_message_lose_credits", "1");
	
	g_iConfig[c_messageTypKarma] = CreateConVar("ttt_message_typ_karma", "1"); // 1 - KeyHint (default), 2 - Chat Message
	g_iConfig[c_messageTypCredits] = CreateConVar("ttt_message_typ_credits", "1"); // 1 - KeyHint (default), 2 - Chat Message
	
	g_iConfig[c_blockSuicide] = CreateConVar("ttt_block_suicide", "0");
	g_iConfig[c_blockGrenadeMessage] = CreateConVar("ttt_block_grenade_message", "1");
	g_iConfig[c_blockRadioMessage] = CreateConVar("ttt_block_radio_message", "1");
	
	g_iConfig[c_allowFlash] = CreateConVar("ttt_allow_flash", "1");
	g_iConfig[c_blockLookAtWeapon] = CreateConVar("ttt_block_look_at_weapon", "1");
	g_iConfig[c_enableNoBlock] = CreateConVar("ttt_enable_noblock", "0");
	g_iConfig[c_kadRemover] = CreateConVar("ttt_kad_remover", "1"); // Kills, Assists and Death remover
	
	g_iConfig[c_pluginTag] = CreateConVar("ttt_plugin_tag", "{orchid}[{green}T{darkred}T{blue}T{orchid}]{lightgreen} %T");
	
	g_iConfig[c_rulesType] = CreateConVar("ttt_rules_type", "0"); // 0 = command, 1 - url/motd
	g_iConfig[c_rulesLink] = CreateConVar("ttt_rules_link", "sm_rules");
	g_iConfig[c_rulesClosePunishment] = CreateConVar("ttt_rules_close_punishment", "0"); // 0 - Kick, 1 - Nothing
	g_iConfig[c_timeToReadDetectiveRules] = CreateConVar("ttt_time_to_read_detective_rules", "10");
	g_iConfig[c_timeToReadRules] = CreateConVar("ttt_time_to_read_rules", "10");
	
	g_iConfig[c_punishInnoKills] = CreateConVar("ttt_punish_ttt_for_rdm_kils", "3");

	AutoExecConfig(true, "ttt");
}

public void OnConfigsExecuted()
{
	if(g_iConfig[c_blockGrenadeMessage].IntValue)
		SetConVarBool(FindConVar("sv_ignoregrenaderadio"), false);
	
	g_iConfig[c_pluginTag].GetString(g_sTag, sizeof(g_sTag));
}

public Action Command_Logs(int client, int args)
{
	if(!IsPlayerAlive(client) || !g_bRoundStarted)
		ShowLogs(client);
	else
		CPrintToChat(client, g_sTag, "you cant see logs", client);
	return Plugin_Handled;
}

stock void ShowLogs(int client)
{
	int sizearray = GetArraySize(g_hLogsArray);
	if(sizearray == 0)
	{
		CPrintToChat(client, g_sTag, "no logs yet", client);
		return;
	}
	if(g_bReceivingLogs[client]) return;
	g_bReceivingLogs[client] = true;
	CPrintToChat(client, g_sTag, "Receiving logs", client);
	PrintToConsole(client, "--------------------------------------");
	PrintToConsole(client, "-------------TTT LOGS---------------");
	char item[512];
	int index = 5;
	bool end = false;
	if(index >= sizearray)
	{
		end = true;
		index = (sizearray -1);
	}
		
	for(int i = 0; i <= index; i++)
	{
		GetArrayString(g_hLogsArray, i, item, sizeof(item));
		PrintToConsole(client, item);
	}
	
	if(end)
	{
		CPrintToChat(client, g_sTag, "See your console", client);
		g_bReceivingLogs[client] = false;
		PrintToConsole(client, "--------------------------------------");
		PrintToConsole(client, "--------------------------------------");
		return;
	}
	Handle pack = CreateDataPack();
	RequestFrame(OnCreate, pack);
	WritePackCell(pack, client);
	WritePackCell(pack, index);
}

public void OnCreate(any pack)
{
	int client;
	int index;
	
	
	ResetPack(pack);
	client = ReadPackCell(pack);
	index = ReadPackCell(pack);
	
	if (IsClientInGame(client))
	{
		int sizearray = GetArraySize(g_hLogsArray);
		int old = (index + 1);
		index += 5;
		bool end = false;
		if(index >= sizearray)
		{
			end = true;
			index = (sizearray -1);
		}
		char item[512];
		
		for(int i = old; i <= index; i++)
		{
			GetArrayString(g_hLogsArray, i, item, sizeof(item));
			PrintToConsole(client, item);
		}
		if(end)
		{
			CPrintToChat(client, g_sTag, "See your console", client);
			g_bReceivingLogs[client] = false;
			PrintToConsole(client, "--------------------------------------");
			PrintToConsole(client, "--------------------------------------");
			return;
		}
		Handle pack2 = CreateDataPack();
		RequestFrame(OnCreate, pack2);
		WritePackCell(pack2, client);
		WritePackCell(pack2, index);
	}
}

public Action Command_InterceptSuicide(int client, const char[] command, int args)
{
	if(g_iConfig[c_blockSuicide].IntValue && IsPlayerAlive(client))
	{
		CPrintToChat(client, g_sTag, "Suicide Blocked", client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_RadioCMDs(int client, const char[] command, int args)
{
	if(g_iConfig[c_blockRadioMessage].IntValue)
		return Plugin_Handled;
	return Plugin_Continue;
}

public void OnMapStart()
{
	for(int i; i < g_iBadNameCount; i++)
		g_sBadNames[i] = "";
	g_iBadNameCount = 0;
	
	LoadBadNames();
	
	g_iBeamSprite = PrecacheModel("materials/sprites/bomb_planted_ring.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/halo.vtf");
	
	PrecacheModel("props/cs_office/microwave.mdl", true);
	PrecacheModel("weapons/w_c4_planted.mdl", true);
	
	PrecacheSoundAny("buttons/blip2.wav", true); 
	PrecacheSoundAny(SND_TCHAT, true);
	PrecacheSoundAny(SND_FLASHLIGHT, true);
	
	PrecacheSoundAny("training/firewerks_burst_02.wav", true);
	PrecacheSoundAny("weapons/c4/c4_beep1.wav", true);
	PrecacheSoundAny("weapons/c4/c4_disarm.wav", true);
	PrecacheSoundAny("ttt/jihad/explosion.mp3", true);
	PrecacheSoundAny("ttt/jihad/jihad.mp3", true);
	PrecacheSoundAny("resource/warning.wav", true);
	PrecacheSoundAny("training/firewerks_burst_02.wav", true);
	PrecacheSoundAny("weapons/c4/c4_beep1.wav", true);
	PrecacheSoundAny("weapons/c4/c4_disarm.wav", true);

	AddFileToDownloadsTable("sound/ttt/jihad/explosion.mp3"); 
	AddFileToDownloadsTable("sound/ttt/jihad/jihad.mp3");
	
	ClearArray(g_hLogsArray);

	AddFileToDownloadsTable("materials/sprites/sg_detective_icon.vmt");
	AddFileToDownloadsTable("materials/sprites/sg_detective_icon.vtf");
	PrecacheModel("materials/sprites/sg_detective_icon.vmt");
	
	AddFileToDownloadsTable("materials/sprites/sg_traitor_icon.vmt");
	AddFileToDownloadsTable("materials/sprites/sg_traitor_icon.vtf");
	PrecacheModel("materials/sprites/sg_traitor_icon.vmt");
	
	AddFileToDownloadsTable("materials/overlays/ttt/innocents_win.vmt");
	AddFileToDownloadsTable("materials/overlays/ttt/innocents_win.vtf");
	PrecacheDecal("overlays/ttt/innocents_win", true);
	
	AddFileToDownloadsTable("materials/overlays/ttt/traitors_win.vmt");
	AddFileToDownloadsTable("materials/overlays/ttt/traitors_win.vtf");
	PrecacheDecal("overlays/ttt/traitors_win", true);
	
	AddFileToDownloadsTable("materials/darkness/ttt/overlayDetective.vmt");
	AddFileToDownloadsTable("materials/darkness/ttt/overlayDetective.vtf");
	PrecacheDecal("darkness/ttt/overlayDetective", true);
	
	AddFileToDownloadsTable("materials/darkness/ttt/overlayTraitor.vmt");
	AddFileToDownloadsTable("materials/darkness/ttt/overlayTraitor.vtf");
	PrecacheDecal("darkness/ttt/overlayTraitor", true);
	
	AddFileToDownloadsTable("materials/darkness/ttt/overlayInnocent.vmt");
	AddFileToDownloadsTable("materials/darkness/ttt/overlayInnocent.vtf");
	PrecacheDecal("darkness/ttt/overlayInnocent", true);
	
 	AddFileToDownloadsTable("materials/overlays/ttt/detectives_win.vmt");
	AddFileToDownloadsTable("materials/overlays/ttt/detectives_win.vtf");
	PrecacheDecal("overlays/ttt/detectives_win", true);
	
	g_iAlive = FindSendPropOffs("CCSPlayerResource", "m_bAlive");
	if (g_iAlive == -1)
		SetFailState("CCSPlayerResource.m_bAlive offset is invalid");
	
	g_iKills = FindSendPropInfo("CCSPlayerResource", "m_iKills");
	if (g_iKills == -1)
		SetFailState("CCSPlayerResource \"m_iKills\" offset is invalid");
	
	g_iDeaths = FindSendPropInfo("CCSPlayerResource", "m_iDeaths");
	if (g_iDeaths == -1)
		SetFailState("CCSPlayerResource \"m_iDeaths\"  offset is invalid");
	
	g_iAssists = FindSendPropInfo("CCSPlayerResource", "m_iAssists");
	if (g_iAssists == -1)
		SetFailState("CCSPlayerResource \"m_iAssists\"  offset is invalid");
	
	
    
	int iPlayerManagerPost = FindEntityByClassname(0, "cs_player_manager"); 
	SDKHook(iPlayerManagerPost, SDKHook_ThinkPost, ThinkPost);
	
	resetPlayers();
}

public void ThinkPost(int entity) 
{
	int isAlive[65];
	
	GetEntDataArray(entity, g_iAlive, isAlive, 65);
	LoopValidClients(i)
	{
		if(IsPlayerAlive(i) || !g_bFound[i])
			isAlive[i] = true;
		else
			isAlive[i] = false;
	}
	SetEntDataArray(entity, g_iAlive, isAlive, 65);
	
	if(g_iConfig[c_kadRemover].IntValue)
	{
		int iZero[MAXPLAYERS + 1] =  { 0, ... };
		
		SetEntDataArray(entity, g_iKills, iZero, MaxClients + 1);
		SetEntDataArray(entity, g_iDeaths, iZero, MaxClients + 1);
		SetEntDataArray(entity, g_iAssists, iZero, MaxClients + 1);
	}
}

public Action Command_Karma(int client, int args)
{
	CPrintToChat(client, g_sTag, "Your karma is", client, g_iKarma[client]);
	
	return Plugin_Handled;
}

public Action Event_RoundStartPre(Event event, const char[] name, bool dontBroadcast)
{
	ClearArray(g_hRagdollArray);
	
	g_bInactive = false;
	LoopValidClients(i)
	{
		g_iRole[i] = TTT_TEAM_UNASSIGNED;
		g_bFound[i] = true;
		g_iInnoKills[i] = 0;
		g_bHasC4[i] = false;
		g_bImmuneRDMManager[i] = false;
		
		CS_SetClientClanTag(i, "");
	}

	if(g_hStartTimer != null)
		KillTimer(g_hStartTimer);
		
	g_hStartTimer = CreateTimer(GetConVarFloat(g_hGraceTime) + 5.0, Timer_Selection);
	
	g_bRoundStarted = false;
	
	if (g_hRoundTimer != null) 
		CloseHandle(g_hRoundTimer);
		
	g_hRoundTimer = CreateTimer(GetConVarFloat(FindConVar("mp_roundtime")) * 60.0, Timer_OnRoundEnd);
	
	ShowOverlayToAll("");
	resetPlayers();
	healthStation_cleanUp();
}

public Action Event_RoundEndPre(Event event, const char[] name, bool dontBroadcast)
{
	LoopValidClients(i)
	{
		g_bFound[i] = true;
		g_iInnoKills[i] = 0;
		g_bImmuneRDMManager[i] = false;
		
		ShowLogs(i);
		TeamTag(i);
	}
		
		
	if (g_hRoundTimer != null) {
		CloseHandle(g_hRoundTimer);
		g_hRoundTimer = null;
	}
	resetPlayers();
	healthStation_cleanUp();
}

public Action Timer_Selection(Handle hTimer)
{
	g_hStartTimer = null;
	
	ClearArray(g_hPlayerArray);
	
	int iCount = 0;
	LoopValidClients(i)
	{
		if(GetClientTeam(i) == CS_TEAM_T || GetClientTeam(i) == CS_TEAM_CT)
		{
			iCount++;
			PushArrayCell(g_hPlayerArray, i);
		}
	}
		
	if(iCount < g_iConfig[c_requiredPlayers].IntValue) 
	{
		g_bInactive = true;
		LoopValidClients(i)
			CPrintToChat(i, g_sTag, "MIN PLAYERS REQUIRED FOR PLAY", i, g_iConfig[c_requiredPlayers].IntValue);
		return;
	}
	int detectives = RoundToNearest(iCount * DETECTIVES_AMOUNT);
	int Traitores = RoundToNearest(iCount * TRAITORS_AMOUNT);
	
	if(detectives == 0)
		detectives = 1;
	if(Traitores == 0)
		Traitores = 1;
	
	if(iCount < g_iConfig[c_requiredPlayersD].IntValue)
		detectives = 0;
	
	int index;
	int player;
	while((index = GetRandomArray()) != -1)
	{
		player = GetArrayCell(g_hPlayerArray, index);
		
		if(detectives > 0 && g_bConfirmDetectiveRules[player])
		{
			g_iRole[player] = TTT_TEAM_DETECTIVE;
			detectives--;
		}
		else if(Traitores > 0)
		{
			g_iRole[player] = TTT_TEAM_TRAITOR;
			Traitores--;
		}
		else
			g_iRole[player] = TTT_TEAM_INNOCENT;
		
		
/* 		int knife = GetPlayerWeaponSlot(player, 2);
		if (knife != -1)
		{
			RemovePlayerItem(player, knife);
			AcceptEntityInput(player, "Kill");
		} */
		while (GetPlayerWeaponSlot(player, CS_SLOT_KNIFE) == -1)
			GivePlayerItem(player, "weapon_knife");
		
		if (GetPlayerWeaponSlot(player, CS_SLOT_SECONDARY) == -1)
			GivePlayerItem(player, "weapon_glock");
		
		TeamInitialize(player);
		
		g_bFound[player] = false;
		
		RemoveFromArray(g_hPlayerArray, index);
	}
	
	int iTraitors = 0;
	
	LoopValidClients(i)
	{
		if (!TTT_IsClientValid(i) || !IsPlayerAlive(i) || g_iRole[i] != TTT_TEAM_TRAITOR)
			continue;
		listTraitors(i);
		iTraitors++;
	}

	LoopValidClients(i)
	{
		CPrintToChat(i, g_sTag, "TEAMS HAS BEEN SELECTED", i);
		
		if(g_iRole[i] != TTT_TEAM_TRAITOR)
			CPrintToChat(i, g_sTag, "TRAITORS HAS BEEN SELECTED", i, iTraitors);
	}
	
	ClearArray(g_hLogsArray);
	g_bRoundStarted = true;
	ApplyIcons();
}

stock int GetRandomArray()
{
	int size = GetArraySize(g_hPlayerArray);
	if(size == 0)
		return -1;
	return Math_GetRandomInt(0, size-1);
}

stock void TeamInitialize(int client)
{
	if(g_iRole[client] == TTT_TEAM_DETECTIVE)
	{
		g_iIcon[client] = CreateIcon(client);
		CS_SetClientClanTag(client, "DETECTIVE");
		
		if(GetClientTeam(client) != CS_TEAM_CT)
			CS_SwitchTeam(client, CS_TEAM_CT);

		if (GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
			GivePlayerItem(client, "weapon_m4a1_silencer");
			
		GivePlayerItem(client, "weapon_taser");
		CPrintToChat(client, g_sTag, "Your Team is DETECTIVES", client);
		SetEntityHealth(client, g_iConfig[c_spawnHPD].IntValue);
	}
	else if(g_iRole[client] == TTT_TEAM_TRAITOR)
	{
		g_iIcon[client] = CreateIcon(client);
		CPrintToChat(client, g_sTag, "Your Team is TRAITORS", client);
		SetEntityHealth(client, g_iConfig[c_spawnHPT].IntValue);
		
		if(GetClientTeam(client) != CS_TEAM_T)
			CS_SwitchTeam(client, CS_TEAM_T);
	}
	else if(g_iRole[client] == TTT_TEAM_INNOCENT)
	{
		CPrintToChat(client, g_sTag, "Your Team is INNOCENTS", client);
		SetEntityHealth(client, g_iConfig[c_spawnHPI].IntValue);
		
		if(GetClientTeam(client) != CS_TEAM_T)
			CS_SwitchTeam(client, CS_TEAM_T);
	}
	
	CS_UpdateClientModel(client);
}

stock void TeamTag(int client)
{
	if (!IsClientInGame(client) || client < 0 || client > MaxClients)
		return;
		
	if(g_iRole[client] == TTT_TEAM_DETECTIVE)
		CS_SetClientClanTag(client, "DETECTIVE");
	else if(g_iRole[client] == TTT_TEAM_TRAITOR)
		CS_SetClientClanTag(client, "TRAITOR");
	else if(g_iRole[client] == TTT_TEAM_INNOCENT)
		CS_SetClientClanTag(client, "INNOCENT");
}

stock void ApplyIcons()
{
	LoopValidClients(i)
		if(IsPlayerAlive(i))
			g_iIcon[i] = CreateIcon(i);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(TTT_IsClientValid(client))
	{
		CS_SetClientClanTag(client, "");
		
		g_iInnoKills[client] = 0;
		
		StripAllWeapons(client);
		
		ClearTimer(g_hJihadBomb[client]);
		g_bDetonate[client] = false;
		
		if(g_bInactive)
		{
			int iCount = 0;
			
			LoopValidClients(i)
				if(IsPlayerAlive(i))
					iCount++;
			
			if(iCount >= 3)
				ServerCommand("mp_restartgame 2");
		}
		else
		{
			CPrintToChat(client, g_sTag, "Your credits is", client, g_iCredits[client]);
			CPrintToChat(client, g_sTag, "Your karma is", client, g_iKarma[client]);
		}
		
		g_b1Knife[client] = false;
		g_bScan[client] = false;
		g_bID[client] = false;
		// g_bRadar[client] = false;
		g_bJihadBomb[client] = false;
		
		if(g_iConfig[c_enableNoBlock].IntValue)
			SetNoBlock(client);
	}
}

public void OnClientPutInServer(int client)
{
	char steamid[64];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	
	g_bImmuneRDMManager[client] = false;
	
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponPostSwitch);
	SDKHook(client, SDKHook_PreThink, OnPreThink);
	
	SetEntData(client, g_iAccount, 16000);
		
	g_iCredits[client] = 800;
}

public Action OnPreThink(int client)
{
	if(TTT_IsClientValid(client))
		CS_SetClientContributionScore(client, g_iKarma[client]);
}

stock void AddStartKarma(int client)
{
	setKarma(client, g_iConfig[c_startKarma].IntValue);
}

stock void BanBadPlayerKarma(int client)
{
	char sReason[512];
	Format(sReason, sizeof(sReason), "%T", "Your Karma is too low", client);
	
	setKarma(client, g_iConfig[c_startKarma].IntValue);
	
	ServerCommand("sm_ban #%d %d \"%s\"", GetClientUserId(client), g_iConfig[c_karmaBanLength].IntValue, sReason);
}

public Action OnTakeDamage(int client, int &iAttacker, int &inflictor, float &damage, int &damagetype)
{
	if(!g_bRoundStarted)
		return Plugin_Handled;
	
	if(!TTT_IsClientValid(iAttacker))
		return Plugin_Continue;
	
	char classname[64];
	GetEdictClassname(inflictor, classname, sizeof(classname));
	char item[512];
	if(StrContains(classname, "_projectile") == -1)
	{
		GetClientWeapon(iAttacker, classname, sizeof(classname));
		if(StrEqual(classname, "weapon_taser"))
		{
			if(g_iRole[client] == TTT_TEAM_TRAITOR)
			{
				Format(item, sizeof(item), "-> [%N tased %N (Traitor)] - TRAITOR DETECTED", iAttacker, client);
				PushArrayString(g_hLogsArray, item);
				CPrintToChat(iAttacker, g_sTag, "You hurt a Traitor", client, client);
				addCredits(iAttacker, g_iConfig[c_creditsTaserHurtTraitor].IntValue);
			}
			else if(g_iRole[client] == TTT_TEAM_DETECTIVE) {
				Format(item, sizeof(item), "-> [%N tased %N (Detective)]", client, iAttacker, client);
				PushArrayString(g_hLogsArray, item);
				CPrintToChat(iAttacker, g_sTag, "You hurt a Detective", client, client);
			}
			else if(g_iRole[client] == TTT_TEAM_INNOCENT) {
				Format(item, sizeof(item), "-> [%N tased %N (Innocent)]", client, iAttacker, client);
				PushArrayString(g_hLogsArray, item);
				CPrintToChat(iAttacker, g_sTag, "You hurt an Innocent", client, client);
			}
			damage = 0.0;
			return Plugin_Changed;
		}
		else if(g_b1Knife[iAttacker] && (StrContains(classname, "knife", false) != -1) || (StrContains(classname, "bayonet", false) != -1))
		{
			Remove1Knife(iAttacker);
			damage = 1000.0;
			return Plugin_Changed;
		}
	}
	
	if(g_iKarma[iAttacker] == 100)
		return Plugin_Continue;
	
	damage = (damage * (g_iKarma[iAttacker] * 0.01));
	
	if(damage < 1.0)
		damage = 1.0;
	
	return Plugin_Changed;
}


public Action Event_PlayerDeathPre(Event event, const char[] menu, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iInnoKills[client] = 0;
	ClearIcon(client);
	
	ClearTimer(g_hJihadBomb[client]);
	if(g_iRole[client] > TTT_TEAM_UNASSIGNED)
	{
		char playermodel[128];
		GetClientModel(client, playermodel, 128);
	
		float origin[3], angles[3], velocity[3];
	
		GetClientAbsOrigin(client, origin);
		GetClientAbsAngles(client, angles);
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocity);
	
		int iEntity = CreateEntityByName("prop_ragdoll");
		DispatchKeyValue(iEntity, "model", playermodel);
		DispatchSpawn(iEntity);
	
		float speed = GetVectorLength(velocity);
		if(speed >= 500) TeleportEntity(iEntity, origin, angles, NULL_VECTOR); 
		else TeleportEntity(iEntity, origin, angles, velocity); 
	
		SetEntData(iEntity, g_iCollisionGroup, 2, 4, true);
	

		int iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		char name[32];
		GetClientName(client, name, sizeof(name));
		int Items[Ragdolls];
		Items[ent] = EntIndexToEntRef(iEntity);
		Items[victim] = client;
		Format(Items[victimName], 32, name);
		Items[scanned] = false;
		GetClientName(iAttacker, name, sizeof(name));
		Items[attacker] = iAttacker;
		Format(Items[attackerName], 32, name);
		Items[gameTime] = GetGameTime();
		GetEventString(event, "weapon", Items[weaponused], sizeof(Items[weaponused]));
	
		PushArrayArray(g_hRagdollArray, Items[0]);
		
		if (client != iAttacker && iAttacker != 0 && !g_bImmuneRDMManager[iAttacker] && !g_bHoldingProp[client] && !g_bHoldingSilencedWep[client])
		{
			if (g_iRole[iAttacker] == TTT_TEAM_TRAITOR && g_iRole[client] == TTT_TEAM_TRAITOR)
			{
				if (g_hRDMTimer[client] != null)
					KillTimer(g_hRDMTimer[client]);
				g_hRDMTimer[client] = CreateTimer(3.0, Timer_RDMTimer, GetClientUserId(client));
				g_iRDMAttacker[client] = iAttacker;
			}
			else if (g_iRole[iAttacker] == TTT_TEAM_DETECTIVE && g_iRole[client] == TTT_TEAM_DETECTIVE)
			{
				if (g_hRDMTimer[client] != null)
					KillTimer(g_hRDMTimer[client]);
				g_hRDMTimer[client] = CreateTimer(3.0, Timer_RDMTimer, GetClientUserId(client));
				g_iRDMAttacker[client] = iAttacker;
			}
			else if (g_iRole[iAttacker] == TTT_TEAM_INNOCENT && g_iRole[client] == TTT_TEAM_DETECTIVE)
			{
				if (g_hRDMTimer[client] != null)
					KillTimer(g_hRDMTimer[client]);
				g_hRDMTimer[client] = CreateTimer(3.0, Timer_RDMTimer, GetClientUserId(client));
				g_iRDMAttacker[client] = iAttacker;
			}
			else if ((g_iRole[iAttacker] == TTT_TEAM_INNOCENT && g_iRole[client] == TTT_TEAM_INNOCENT) || (g_iRole[iAttacker] == TTT_TEAM_DETECTIVE && g_iRole[client] == TTT_TEAM_INNOCENT)) {
				g_iInnoKills[iAttacker]++;
			}

			if (g_iInnoKills[iAttacker] >= g_iConfig[c_punishInnoKills].IntValue)
				ServerCommand("sm_slay #%i 5", GetClientUserId(iAttacker));
		}
	}
	if(!dontBroadcast)
	{	
		dontBroadcast = true;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	nameCheck(client, name);
	
	LoadClientKarma(GetClientUserId(client));
	
	CreateTimer(3.0, Timer_ShowWelcomeMenu, GetClientUserId(client));
}

public Action Timer_ShowWelcomeMenu(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if(TTT_IsClientValid(client))
	{
		char sText[512], sYes[64], sNo[64];
		Format(sText, sizeof(sText), "%T", "Welcome Menu", client, client, TTT_PLUGIN_AUTHOR);
		Format(sYes, sizeof(sYes), "%T", "WM Yes", client);
		Format(sNo, sizeof(sNo), "%T", "WM No", client);
		
		Menu menu = new Menu(Menu_ShowWelcomeMenu);
		menu.SetTitle(sText);
		menu.AddItem("no", sNo);
		menu.AddItem("yes", sYes);
		menu.ExitButton = false;
		menu.ExitBackButton = false;
		menu.Display(client, g_iConfig[c_timeToReadRules].IntValue);
	}
}

public int Menu_ShowWelcomeMenu(Menu menu, MenuAction action, int client, int param) 
{
	if ( action == MenuAction_Select ) 
	{
		char sParam[32];
		GetMenuItem(menu, param, sParam, sizeof(sParam));
		
		if (!StrEqual(sParam, "yes", false))
		{
			char sCommand[64];
			g_iConfig[c_rulesLink].GetString(sCommand, sizeof(sCommand));
			
			if(g_iConfig[c_rulesType].IntValue == 0)
				ClientCommand(client, sCommand);
			else if(g_iConfig[c_rulesType].IntValue == 1)
			{
				char sURL[512];
				Format(sURL, sizeof(sURL), "http://claninspired.com/franug/webshortcuts2.php?web=height=720,width=1280;franug_is_pro;%s", sCommand);
				ShowMOTDPanel(client, "TTT Rules", sURL, MOTDPANEL_TYPE_URL);
				
				g_bKnowRules[client] = false;
				g_bReadRules[client] = true;
			}
		}
		else
		{
			g_bKnowRules[client] = true;
			g_bReadRules[client] = false;
		}
		
		AskClientForMicrophone(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(TTT_IsClientValid(client) && g_iConfig[c_rulesClosePunishment].IntValue == 0)
		{
			char sMessage[128];
			Format(sMessage, sizeof(sMessage), "%T", "WM Kick Message", client);
			KickClient(client, sMessage);
		}
	}
	else if (action == MenuAction_End)
		delete menu;
	
	return 0;
}

stock void AskClientForMicrophone(int client)
{
	char sText[512], sYes[64], sNo[64];
	Format(sText, sizeof(sText), "%T", "AM Question", client);
	Format(sYes, sizeof(sYes), "%T", "AM Yes", client);
	Format(sNo, sizeof(sNo), "%T", "AM No", client);
	
	Menu menu = new Menu(Menu_AskClientForMicrophone);
	menu.SetTitle(sText);
	menu.AddItem("no", sNo);
	menu.AddItem("yes", sYes);
	menu.ExitButton = false;
	menu.ExitBackButton = false;
	menu.Display(client, g_iConfig[c_timeToReadDetectiveRules].IntValue);
}


public int Menu_AskClientForMicrophone(Menu menu, MenuAction action, int client, int param) 
{
	if ( action == MenuAction_Select ) 
	{
		char sParam[32];
		GetMenuItem(menu, param, sParam, sizeof(sParam));
		
		if (!StrEqual(sParam, "yes", false))
			g_bConfirmDetectiveRules[client] = false;
		else
			g_bConfirmDetectiveRules[client] = true;
	}
	else if(action == MenuAction_Cancel)
		g_bConfirmDetectiveRules[client] = false;
	else if (action == MenuAction_End)
		delete menu;
	
	return 0;
}

public void OnClientDisconnect(int client)
{
	if(IsClientInGame(client))
	{
		g_bKarma[client] = false;
		
		ClearTimer(g_hRDMTimer[client]);
		ClearTimer(g_hRemoveCoolDownTimer[client]);
		ClearIcon(client);
		
		ClearTimer(g_hJihadBomb[client]);
		
		g_bReceivingLogs[client] = false;
		g_bImmuneRDMManager[client] = false;
	/* 	int thesize = GetArraySize(g_hRagdollArray);
		
		if(thesize == 0) return;
		
		int Items[Ragdolls];
				
		for(int i = 0;i < GetArraySize(g_hRagdollArray);i++)
		{
			GetArrayArray(g_hRagdollArray, i, Items[0]);
					
			if(client == Items[attacker] || client == Items[victim])
			{
				int entity = EntRefToEntIndex(Items[index]);
				if(entity != INVALID_ENT_REFERENCE) AcceptEntityInput(entity, "kill");
						
				RemoveFromArray(g_hRagdollArray, i);
				break;
			}
		}  */
		
		ClearTimer(g_hExplosionTimer[client]);
	}
}

public Action Event_ChangeName(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsClientInGame(client)) return;
		
	char userName[32];
	GetEventString(event, "newname", userName, sizeof(userName));
	nameCheck(client, userName);
	
 	int thesize = GetArraySize(g_hRagdollArray);
	
	if(thesize == 0)
		return;
	
	int Items[Ragdolls];
			
	for(int i = 0;i < GetArraySize(g_hRagdollArray);i++)
	{
		GetArrayArray(g_hRagdollArray, i, Items[0]);
				
		if(client == Items[attacker])
		{
			Format(Items[attackerName], 32, userName);
			SetArrayArray(g_hRagdollArray, i, Items[0]);
		}
		else if(client == Items[victim])
		{
			Format(Items[victimName], 32, userName);
			SetArrayArray(g_hRagdollArray, i, Items[0]);
		}
	} 
}

public Action Timer_Adjust(Handle timer)
{
	int g_iInnoAlive = 0;
	int g_iTraitorAlive = 0;
	int g_iDetectiveAlive = 0;
	float vec[3];
	LoopValidClients(i)
		if(IsPlayerAlive(i))
		{
			if(g_iRole[i] == TTT_TEAM_TRAITOR)
			{
				GetClientAbsOrigin(i, vec);
		
				vec[2] += 10;
				g_iTraitorAlive++;
				int[] clients = new int[MaxClients];
				int index = 0;
				
				LoopValidClients(j)
					if(IsPlayerAlive(j) && j != i && (g_iRole[j] == TTT_TEAM_TRAITOR))
					{
						clients[index] = j;
						index++;
					}
				
				TE_SetupBeamRingPoint(vec, 50.0, 60.0, g_iBeamSprite, g_iHaloSprite, 0, 15, 0.1, 10.0, 0.0, {0, 0, 255, 255}, 10, 0);
				TE_Send(clients, index);
			}
			else if(g_iRole[i] == TTT_TEAM_INNOCENT)
				g_iInnoAlive++;
			else if(g_iRole[i] == TTT_TEAM_DETECTIVE)
				g_iDetectiveAlive++;

			int money = GetEntData(i, g_iAccount);
			if(money != 16000)
				SetEntData(i, g_iAccount, 16000);
		}
		
	if(g_bRoundStarted)
	{
		if(g_iInnoAlive == 0 && g_iDetectiveAlive == 0)
		{
			g_bRoundStarted = false;
			CS_TerminateRound(7.0, CSRoundEnd_TerroristWin);
		}
		else if(g_iTraitorAlive == 0)
		{		
			g_bRoundStarted = false;
			CS_TerminateRound(7.0, CSRoundEnd_CTWin);
		}
	}
}

public Action Command_Credits(int client, int args)
{
	CPrintToChat(client, g_sTag, "Your credits is", client, g_iCredits[client]);
	
	return Plugin_Handled;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!TTT_IsClientValid(client))
		return;
    
	int iRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (iRagdoll < 0)
		return;

	AcceptEntityInput(iRagdoll, "Kill");
	
	int iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!TTT_IsClientValid(iAttacker) || iAttacker == client)
		return;
	
	int assister = GetClientOfUserId(GetEventInt(event, "assister"));
	if(!TTT_IsClientValid(assister) || assister == client)
		return;
	
	if (g_iConfig[c_showDeathMessage].IntValue)
	{
		if(g_iRole[iAttacker] == TTT_TEAM_TRAITOR)
			CPrintToChat(client, g_sTag, "Your killer is a Traitor", client);
		else if(g_iRole[iAttacker] == TTT_TEAM_DETECTIVE)
			CPrintToChat(client, g_sTag, "Your killer is a Detective", client);
		else if(g_iRole[iAttacker] == TTT_TEAM_INNOCENT)
			CPrintToChat(client, g_sTag, "Your killer is an Innocent", client);
	}
	
	if(g_iConfig[c_showKillMessage].IntValue)
	{
		if(g_iRole[client] == TTT_TEAM_TRAITOR)
			CPrintToChat(iAttacker, g_sTag, "You killed a Traitor", client);
		else if(g_iRole[client] == TTT_TEAM_DETECTIVE)
			CPrintToChat(iAttacker, g_sTag, "You killed a Detective", client);
		else if(g_iRole[client] == TTT_TEAM_INNOCENT)
			CPrintToChat(iAttacker, g_sTag, "You killed an Innocent", client);
	}
	
	char item[512];
	
	if(g_iRole[iAttacker] == TTT_TEAM_INNOCENT && g_iRole[client] == TTT_TEAM_INNOCENT)
	{
		Format(item, sizeof(item), "-> [%N (Innocent) killed %N (Innocent)] - BAD ACTION", iAttacker, client);
		PushArrayString(g_hLogsArray, item);
		
		subtractKarma(iAttacker, g_iConfig[c_karmaII].IntValue, true);
		subtractCredits(iAttacker, g_iConfig[c_creditsII].IntValue, true);
	}
	else if(g_iRole[iAttacker] == TTT_TEAM_INNOCENT && g_iRole[client] == TTT_TEAM_TRAITOR)
	{
		Format(item, sizeof(item), "-> [%N (Innocent) killed %N (Traitor)]", iAttacker, client);
		PushArrayString(g_hLogsArray, item);
		
		addKarma(iAttacker, g_iConfig[c_karmaIT].IntValue, true);
		addCredits(iAttacker, g_iConfig[c_creditsIT].IntValue, true);
	}
	else if(g_iRole[iAttacker] == TTT_TEAM_INNOCENT && g_iRole[client] == TTT_TEAM_DETECTIVE)
	{
		Format(item, sizeof(item), "-> [%N (Innocent) killed %N (Detective)] - BAD ACTION", iAttacker, client);
		PushArrayString(g_hLogsArray, item);
		
		subtractKarma(iAttacker, g_iConfig[c_karmaID].IntValue, true);
		subtractCredits(iAttacker, g_iConfig[c_creditsID].IntValue, true);
	}
	else if(g_iRole[iAttacker] == TTT_TEAM_TRAITOR && g_iRole[client] == TTT_TEAM_INNOCENT)
	{
		Format(item, sizeof(item), "-> [%N (Traitor) killed %N (Innocent)]", iAttacker, client);
		PushArrayString(g_hLogsArray, item);
		
		addKarma(iAttacker, g_iConfig[c_karmaTI].IntValue, true);
		addCredits(iAttacker, g_iConfig[c_creditsTI].IntValue, true);
	}
	else if(g_iRole[iAttacker] == TTT_TEAM_TRAITOR && g_iRole[client] == TTT_TEAM_TRAITOR)
	{
		Format(item, sizeof(item), "-> [%N (Traitor) killed %N (Traitor)] - BAD ACTION", iAttacker, client);
		PushArrayString(g_hLogsArray, item);
		
		subtractKarma(iAttacker, g_iConfig[c_karmaTT].IntValue, true);
		subtractCredits(iAttacker, g_iConfig[c_creditsTT].IntValue, true);
	}
	else if(g_iRole[iAttacker] == TTT_TEAM_TRAITOR && g_iRole[client] == TTT_TEAM_DETECTIVE)
	{
		Format(item, sizeof(item), "-> [%N (Traitor) killed %N (Detective)]", iAttacker, client);
		PushArrayString(g_hLogsArray, item);
		
		addKarma(iAttacker, g_iConfig[c_karmaTD].IntValue, true);
		addCredits(iAttacker, g_iConfig[c_creditsTD].IntValue, true);
	}
	else if(g_iRole[iAttacker] == TTT_TEAM_DETECTIVE && g_iRole[client] == TTT_TEAM_INNOCENT)
	{
		Format(item, sizeof(item), "-> [%N (Detective) killed %N (Innocent)] - BAD ACTION", iAttacker, client);
		PushArrayString(g_hLogsArray, item);
		
		subtractKarma(iAttacker, g_iConfig[c_karmaDI].IntValue, true);
		subtractCredits(iAttacker, g_iConfig[c_creditsDI].IntValue, true);
	}
	else if(g_iRole[iAttacker] == TTT_TEAM_DETECTIVE && g_iRole[client] == TTT_TEAM_TRAITOR)
	{
		Format(item, sizeof(item), "-> [%N (Detective) killed %N (Traitor)]", iAttacker, client);
		PushArrayString(g_hLogsArray, item);
		
		addKarma(iAttacker, g_iConfig[c_karmaDT].IntValue, true);
		addCredits(iAttacker, g_iConfig[c_creditsDT].IntValue, true);
	}
	else if(g_iRole[iAttacker] == TTT_TEAM_DETECTIVE && g_iRole[client] == TTT_TEAM_DETECTIVE)
	{
		Format(item, sizeof(item), "-> [%N (Detective) killed %N (Detective)] - BAD ACTION", iAttacker, client);
		PushArrayString(g_hLogsArray, item);
		
		subtractKarma(iAttacker, g_iConfig[c_karmaDD].IntValue, true);
		subtractCredits(iAttacker, g_iConfig[c_creditsDD].IntValue, true);
	}
}

stock int CreateIcon(int client) {
  
	ClearIcon(client);
	if(g_iRole[client] < TTT_TEAM_TRAITOR || !g_bRoundStarted)
		return 0;
	
	char iTarget[16];
	Format(iTarget, 16, "client%d", client);
	DispatchKeyValue(client, "targetname", iTarget);

	float origin[3];
  
	GetClientAbsOrigin(client, origin);				
	origin[2] = origin[2] + 80.0;

	int Ent = CreateEntityByName("env_sprite");
	if(!Ent) return -1;

	if(g_iRole[client] == TTT_TEAM_DETECTIVE) DispatchKeyValue(Ent, "model", "sprites/sg_detective_icon.vmt");
	else if(g_iRole[client] == TTT_TEAM_TRAITOR) DispatchKeyValue(Ent, "model", "sprites/sg_traitor_icon.vmt");
	DispatchKeyValue(Ent, "classname", "env_sprite");
	DispatchKeyValue(Ent, "spawnflags", "1");
	DispatchKeyValue(Ent, "scale", "0.08");
	DispatchKeyValue(Ent, "rendermode", "1");
	DispatchKeyValue(Ent, "rendercolor", "255 255 255");
	DispatchSpawn(Ent);
	TeleportEntity(Ent, origin, NULL_VECTOR, NULL_VECTOR);
	SetVariantString(iTarget);
	AcceptEntityInput(Ent, "SetParent", Ent, Ent, 0);
 
	if(g_iRole[client] == TTT_TEAM_TRAITOR)
		SDKHook(Ent, SDKHook_SetTransmit, Hook_SetTransmitT); 
	return Ent;
}

public Action Hook_SetTransmitT(int entity, int client) 
{ 
    if (entity != client && g_iRole[client] != TTT_TEAM_TRAITOR && IsPlayerAlive(client)) 
        return Plugin_Handled;
     
    return Plugin_Continue; 
}  

public void OnMapEnd() {
	if (g_hRoundTimer != null) {
		CloseHandle(g_hRoundTimer);
		g_hRoundTimer = null;
	}
	resetPlayers();
	
	
	LoopValidClients(i)
		g_bKarma[i] = false;
}

public Action Timer_OnRoundEnd(Handle timer) 
{
	g_hRoundTimer = null;
	g_bRoundStarted = false;
	CS_TerminateRound(7.0, CSRoundEnd_CTWin);
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	if(g_bRoundStarted)
		return Plugin_Handled;
	
	LoopValidClients(client)
		if(IsPlayerAlive(client))
			ClearIcon(client);
	
	bool bInnoAlive = false;
	
	if(reason == CSRoundEnd_CTWin)
	{
		LoopValidClients(client)
		{
			if(g_iRole[client] != TTT_TEAM_TRAITOR && g_iRole[client] != TTT_TEAM_UNASSIGNED)
			{
				if(IsPlayerAlive(client))
				{
					if(g_iRole[client] == TTT_TEAM_INNOCENT)
						bInnoAlive = true;
					
					addCredits(client, g_iConfig[c_traitorloseAliveNonTraitors].IntValue);
				}
				else
					addCredits(client, g_iConfig[c_traitorloseDeadNonTraitors].IntValue);
			}
		}
	}
	else if(reason == CSRoundEnd_TerroristWin)
	{
		LoopValidClients(client)
		{
			if(g_iRole[client] == TTT_TEAM_TRAITOR)
			{
				if(IsPlayerAlive(client))
					addCredits(client, g_iConfig[c_traitorwinAliveTraitors].IntValue);
				else
					addCredits(client, g_iConfig[c_traitorwinDeadTraitors].IntValue);
			}
		}
	}
	
	if(reason == CSRoundEnd_TerroristWin)
		ShowOverlayToAll("overlays/ttt/traitors_win");
	else if(reason == CSRoundEnd_CTWin && bInnoAlive)
		ShowOverlayToAll("overlays/ttt/innocents_win");
	else if(reason == CSRoundEnd_CTWin && !bInnoAlive)
		ShowOverlayToAll("overlays/ttt/detectives_win");
	
	
	healthStation_cleanUp();
	return Plugin_Continue;
}

stock void ShowOverlayToClient(int client, const char[] overlaypath)
{
	ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath);
}

stock void ShowOverlayToAll(const char[] overlaypath)
{
	LoopValidClients(i)
		if(!IsFakeClient(i))
			ShowOverlayToClient(i, overlaypath);
}

stock void StripAllWeapons(int client)
{
    int iEnt;
    for (int i = 0; i <= 4; i++)
    {
		while ((iEnt = GetPlayerWeaponSlot(client, i)) != -1)
		{
            RemovePlayerItem(client, iEnt);
            AcceptEntityInput(iEnt, "Kill");
		}
    }
}  

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{	
	int iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!iAttacker)
		return;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	
	int damage = GetEventInt(event, "dmg_health");
	char item[512];
	if(g_iRole[iAttacker] == TTT_TEAM_INNOCENT && g_iRole[client] == TTT_TEAM_INNOCENT)
	{
		Format(item, sizeof(item), "-> [%N (Innocent) damaged %N (Innocent) for %i damage] - BAD ACTION", iAttacker, client, damage);
		PushArrayString(g_hLogsArray, item);
	}
	else if(g_iRole[iAttacker] == TTT_TEAM_INNOCENT && g_iRole[client] == TTT_TEAM_TRAITOR)
	{
		Format(item, sizeof(item), "-> [%N (Innocent) damaged %N (Traitor) for %i damage]", iAttacker, client, damage);
		PushArrayString(g_hLogsArray, item);
	}
	else if(g_iRole[iAttacker] == TTT_TEAM_INNOCENT && g_iRole[client] == TTT_TEAM_DETECTIVE)
	{
		Format(item, sizeof(item), "-> [%N (Innocent) damaged %N (Detective) for %i damage] - BAD ACTION", iAttacker, client, damage);
		PushArrayString(g_hLogsArray, item);
	}
	else if(g_iRole[iAttacker] == TTT_TEAM_TRAITOR && g_iRole[client] == TTT_TEAM_INNOCENT)
	{
		Format(item, sizeof(item), "-> [%N (Traitor) damaged %N (Innocent) for %i damage]", iAttacker, client, damage);
		PushArrayString(g_hLogsArray, item);
		
	}
	else if(g_iRole[iAttacker] == TTT_TEAM_TRAITOR && g_iRole[client] == TTT_TEAM_TRAITOR)
	{
		Format(item, sizeof(item), "-> [%N (Traitor) damaged %N (Traitor) for %i damage] - BAD ACTION", iAttacker, client, damage);
		PushArrayString(g_hLogsArray, item);
		
	}
	else if(g_iRole[iAttacker] == TTT_TEAM_TRAITOR && g_iRole[client] == TTT_TEAM_DETECTIVE)
	{
		Format(item, sizeof(item), "-> [%N (Traitor) damaged %N (Detective) for %i damage]", iAttacker, client, damage);
		PushArrayString(g_hLogsArray, item);
	}
	else if(g_iRole[iAttacker] == TTT_TEAM_DETECTIVE && g_iRole[client] == TTT_TEAM_INNOCENT)
	{
		Format(item, sizeof(item), "-> [%N (Detective) damaged %N (Innocent) for %i damage] - BAD ACTION", iAttacker, client, damage);
		PushArrayString(g_hLogsArray, item);
		
	}
	else if(g_iRole[iAttacker] == TTT_TEAM_DETECTIVE && g_iRole[client] == TTT_TEAM_TRAITOR)
	{
		Format(item, sizeof(item), "-> [%N (Detective) damaged %N (Traitor) for %i damage]", iAttacker, client, damage);
		PushArrayString(g_hLogsArray, item);
	}
	else if(g_iRole[iAttacker] == TTT_TEAM_DETECTIVE && g_iRole[client] == TTT_TEAM_DETECTIVE)
	{
		Format(item, sizeof(item), "-> [%N (Detective) damaged %N (Detective) for %i damage] - BAD ACTION", iAttacker, client, damage);
		PushArrayString(g_hLogsArray, item);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if(!IsClientInGame(client)) return Plugin_Continue;
	
	if(buttons & IN_USE)
	{
		g_bHoldingProp[client] = true;
		
		int entidad = GetClientAimTarget(client, false);
		if(entidad > 0)
		{
			float OriginG[3], TargetOriginG[3];
			GetClientEyePosition(client, TargetOriginG);
			GetEntPropVector(entidad, Prop_Data, "m_vecOrigin", OriginG);
			if(GetVectorDistance(TargetOriginG,OriginG, false) > 90.0) return Plugin_Continue;
			
			
		 	int thesize = GetArraySize(g_hRagdollArray);
	
			if(thesize == 0) return Plugin_Continue;
	
			int Items[Ragdolls];
			int entity;
			
			for(int i = 0;i < thesize;i++)
			{
				GetArrayArray(g_hRagdollArray, i, Items[0]);
				entity = EntRefToEntIndex(Items[ent]);
				
				if(entity == entidad)
				{
					MostrarMenu(client, Items[victim], Items[attacker], RoundToNearest(GetGameTime()-Items[gameTime]), Items[weaponused], Items[victimName], Items[attackerName]);
					
					if(!Items[found] && IsPlayerAlive(client))
					{
						Items[found] = true;
						if(IsClientInGame(Items[victim]))
							g_bFound[Items[victim]] = true;
						
						if(g_iRole[Items[victim]] == TTT_TEAM_INNOCENT) 
						{
							LoopValidClients(j)
								CPrintToChat(j, g_sTag, "Found Innocent", j, client, Items[victimName]);
							SetEntityRenderColor(entidad, 0, 255, 0, 255);
						}
						else if(g_iRole[Items[victim]] == TTT_TEAM_DETECTIVE)
						{
							LoopValidClients(j)
								CPrintToChat(j, g_sTag, "Found Detective", j, client, Items[victimName]);
							SetEntityRenderColor(entidad, 0, 0, 255, 255);
						}
						else if(g_iRole[Items[victim]] == TTT_TEAM_TRAITOR) 
						{
							LoopValidClients(j)
								CPrintToChat(j, g_sTag, "Found Traitor", j, client,Items[victimName]);
							SetEntityRenderColor(entidad, 255, 0, 0, 255);
						}
						
						TeamTag(Items[victim]);
						
						
						
						addCredits(client, g_iConfig[c_creditsFoundBody].IntValue);
					}
					
					if(g_bScan[client] && !Items[scanned] && IsPlayerAlive(client))
					{
						Items[scanned] = true;
						if(Items[attacker] > 0 && Items[attacker] != Items[victim])
						{
							LoopValidClients(j)
								CPrintToChat(j, g_sTag, "Detective scan found body", j, client, Items[attackerName], Items[weaponused]);
						}
						else
						{
							LoopValidClients(j)
								CPrintToChat(j, g_sTag, "Detective scan found body suicide", j, client);
						}
						
						
					}
					SetArrayArray(g_hRagdollArray, i, Items[0]);
					
					break;
				}
			} 
		}
	}
	else
		g_bHoldingProp[client] = false;


	if (buttons & IN_RELOAD && g_iDefusePlayerIndex[client] == -1) {
		int target = GetClientAimTarget(client, false);
		if (target > 0) {
			float clientEyes[3], targetOrigin[3];
			GetClientEyePosition(client, clientEyes);
			GetEntPropVector(target, Prop_Data, "m_vecOrigin", targetOrigin);
			if (GetVectorDistance(clientEyes, targetOrigin) > 100.0) return Plugin_Continue;
			int iEnt;
			while ((iEnt = FindEntityByClassname(iEnt, "prop_physics")) != -1) {
				int planter = GetEntProp(target, Prop_Send, "m_hOwnerEntity");
				if (planter < 1 || planter > MaxClients || !IsClientInGame(planter))
					return Plugin_Continue;
				if (target == iEnt) {
					g_iDefusePlayerIndex[client] = planter;
					showDefuseMenu(client);
				}
			}
		}
	}
	if (buttons & IN_ATTACK2 && !g_bHasActiveBomb[client] && g_bHasC4[client]) {
		g_bHasActiveBomb[client] = true;
		int bombEnt = CreateEntityByName("prop_physics");
		if (bombEnt != -1) {
			float clientPos[3];
			GetClientAbsOrigin(client, clientPos);
			SetEntProp(bombEnt, Prop_Data, "m_CollisionGroup", 1);
			SetEntProp(bombEnt, Prop_Send, "m_hOwnerEntity", client);
			DispatchKeyValue(bombEnt, "model", "models/weapons/w_c4_planted.mdl");
			DispatchSpawn(bombEnt);
			TeleportEntity(bombEnt, clientPos, NULL_VECTOR, NULL_VECTOR);
			showPlantMenu(client);
		}
	}
	return Plugin_Continue;
}

public Action Command_ID(int client, int args)
{
	if(g_bID[client] && IsPlayerAlive(client))
	{
		LoopValidClients(i)
			CPrintToChat(i, g_sTag, "Player Is an Innocent", i, client);
	}
	else
		CPrintToChat(client, g_sTag, "You dont have it!", client);
	
	return Plugin_Handled;

}

public Action Command_Say(int client, const char[] command, int argc)
{
	if(!TTT_IsClientValid(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	char sText[MAX_MESSAGE_LENGTH];
	GetCmdArgString(sText, sizeof(sText));
	
	StripQuotes(sText);
	
	if (sText[0] == '@')
		return Plugin_Continue;
	
	for (int i = 0; i < sizeof(g_sShopCMDs); i++)
	{
		char sBuffer[64];
		Format(sBuffer, sizeof(sBuffer), "!%s", g_sShopCMDs[i]);
		
		if (StrEqual(sText, sBuffer, false))
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Command_SayTeam(int client, const char[] command, int argc)
{
	if(!TTT_IsClientValid(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	char sText[MAX_MESSAGE_LENGTH];
	GetCmdArgString(sText, sizeof(sText));
	
	StripQuotes(sText);
	
	if(strlen(sText) < 2)
		return Plugin_Handled;
		
	if (sText[0] == '@')
		return Plugin_Continue;
		
	for (int i = 0; i < sizeof(g_sShopCMDs); i++)
	{
		char sBuffer[64];
		Format(sBuffer, sizeof(sBuffer), "!%s", g_sShopCMDs[i]);
		
		if (StrEqual(sText, sBuffer, false))
			return Plugin_Handled;
	}
	
	if(g_iRole[client] == TTT_TEAM_TRAITOR)
	{
		LoopValidClients(i)
			if(TTT_IsClientValid(i) && (g_iRole[i] == TTT_TEAM_TRAITOR || !IsPlayerAlive(i))) 
			{
				EmitSoundToClient(i, SND_TCHAT);
				CPrintToChat(i, "%T", "T channel", i, client, sText);
			}
			
		return Plugin_Handled;
	}
	else if(g_iRole[client] == TTT_TEAM_DETECTIVE)
	{
		LoopValidClients(i)
			if(TTT_IsClientValid(i) && (g_iRole[i] == TTT_TEAM_DETECTIVE || !IsPlayerAlive(i))) 
			{
				EmitSoundToClient(i, SND_TCHAT);
				CPrintToChat(i, "%T", "D channel", i, client, sText);
			}
			
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_Shop(int client, int args)
{
	int team = g_iRole[client];
	if(team != TTT_TEAM_UNASSIGNED)
	{
		char MenuItem[128];
		Handle menu = CreateMenu(Menu_ShopHandler);
		SetMenuTitle(menu, "%T", "TTT Shop", client);
		
		if(team != TTT_TEAM_INNOCENT)
		{
			// Format(MenuItem, sizeof(MenuItem),"%T", "Buy radar", client, g_iConfig[c_shopRadar].IntValue);
			// AddMenuItem(menu, "radar", MenuItem);
			
			Format(MenuItem, sizeof(MenuItem),"%T", "Kevlar", client, g_iConfig[c_shopKEVLAR].IntValue);
			AddMenuItem(menu, "kevlar", MenuItem);
		}
	
		if(team == TTT_TEAM_TRAITOR)
		{
			Format(MenuItem, sizeof(MenuItem),"%T", "Buy c4", client, g_iConfig[c_shopC4].IntValue);
			AddMenuItem(menu, "C4", MenuItem);
			
			Format(MenuItem, sizeof(MenuItem),"%T", "Buy jihadbomb", client, g_iConfig[c_shopJIHADBOMB].IntValue);
			AddMenuItem(menu, "jbomb", MenuItem);
			
			Format(MenuItem, sizeof(MenuItem),"%T", "1 hit kill knife (only good for 1 shot)", client, g_iConfig[c_shop1KNIFE].IntValue);
			AddMenuItem(menu, "1knife", MenuItem);

			Format(MenuItem, sizeof(MenuItem),"%T", "FAKE ID card (type !id for show your innocence)", client, g_iConfig[c_shopFAKEID].IntValue);
			AddMenuItem(menu, "fakeID", MenuItem);
			
			Format(MenuItem, sizeof(MenuItem),"%T", "M4S", client, g_iConfig[c_shopM4A1].IntValue);
			AddMenuItem(menu, "m4s", MenuItem);
			
			Format(MenuItem, sizeof(MenuItem),"%T", "USPS", client, g_iConfig[c_shopUSP].IntValue);
			AddMenuItem(menu, "usps", MenuItem);
			
		}
		if(team == TTT_TEAM_DETECTIVE)
		{
			Format(MenuItem, sizeof(MenuItem),"%T", "Health Station", client, g_iConfig[c_shopHEALTH].IntValue);
			AddMenuItem(menu, "HealthStation", MenuItem);
			
			Format(MenuItem, sizeof(MenuItem),"%T", "DNA scanner (scan a dead body and show who the killer is)", client, g_iConfig[c_shopDNA].IntValue);
			AddMenuItem(menu, "scan13", MenuItem);
		}
		if(team == TTT_TEAM_INNOCENT)
		{
/*    		Format(MenuItem, sizeof(MenuItem),"%T", "Buy rol Traitor", client, g_iConfig[c_shopT].IntValue);
			AddMenuItem(menu, "buyT", MenuItem);
			
			if(g_bConfirmDetectiveRules[client])
			{
				Format(MenuItem, sizeof(MenuItem),"%T", "Buy rol Detective", client, g_iConfig[c_shopD].IntValue);
				AddMenuItem(menu, "buyD", MenuItem);
			}
*/
			
			Format(MenuItem, sizeof(MenuItem),"%T", "ID card (type !id for show your innocence)", client, g_iConfig[c_shopID].IntValue);
			AddMenuItem(menu, "ID", MenuItem);
		}
		Format(MenuItem, sizeof(MenuItem),"%T", "Taser", client, g_iConfig[c_shopTASER].IntValue);
		AddMenuItem(menu, "taser", MenuItem);
		
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 15);
	
	}
	else
		CPrintToChat(client, g_sTag, "Please wait till your team is assigned", client);
	
	return Plugin_Handled;

}

public int Menu_ShopHandler(Menu menu, MenuAction action, int client, int itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		if(!IsPlayerAlive(client)) return;
		char info[32];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		if ( strcmp(info,"kevlar") == 0 ) 
		{
			if(g_iCredits[client] >= g_iConfig[c_shopKEVLAR].IntValue)
			{
				GivePlayerItem( client, "item_assaultsuit");
				subtractCredits(client, g_iConfig[c_shopKEVLAR].IntValue);
				CPrintToChat(client, g_sTag, "Item bought! Your REAL money is", client, g_iCredits[client]);
			}
			else CPrintToChat(client, g_sTag, "You don't have enough money", client);
		}
		else if ( strcmp(info,"1knife") == 0 )
		{
			if(g_iCredits[client] >= g_iConfig[c_shop1KNIFE].IntValue)
			{
				if (g_iRole[client] != TTT_TEAM_TRAITOR)
					return;
				Set1Knife(client);
				subtractCredits(client, g_iConfig[c_shop1KNIFE].IntValue);
				CPrintToChat(client, g_sTag, "Item bought! Your REAL money is", client, g_iCredits[client]);
			}
			else CPrintToChat(client, g_sTag, "You don't have enough money", client);
		}
		else if ( strcmp(info,"scan13") == 0 )
		{
			if(g_iCredits[client] >= g_iConfig[c_shopDNA].IntValue)
			{
				g_bScan[client] = true;
				subtractCredits(client, g_iConfig[c_shopDNA].IntValue);
				CPrintToChat(client, g_sTag, "Item bought! Your REAL money is", client, g_iCredits[client]);
			}
			else CPrintToChat(client, g_sTag, "You don't have enough money", client);
		}
		else if ( strcmp(info,"ID") == 0 )
		{
			if(g_iCredits[client] >= g_iConfig[c_shopID].IntValue)
			{
				g_bID[client] = true;
				subtractCredits(client, g_iConfig[c_shopID].IntValue);
				CPrintToChat(client, g_sTag, "Item bought! Your REAL money is", client, g_iCredits[client]);
			}
			else CPrintToChat(client, g_sTag, "You don't have enough money", client);
		}
		/* else if ( strcmp(info,"radar") == 0 )
		{
			if(g_iCredits[client] >= g_iConfig[c_shopRadar].IntValue)
			{
				g_bRadar[client] = true;
				subtractCredits(client, g_iConfig[c_shopRadar].IntValue);
				CPrintToChat(client, g_sTag, "Item bought! Your REAL money is", client, g_iCredits[client]);
			}
			else CPrintToChat(client, g_sTag, "You don't have enough money", client);
		} */
		else if ( strcmp(info,"fakeID") == 0 )
		{
			if(g_iCredits[client] >= g_iConfig[c_shopFAKEID].IntValue)
			{
				g_bID[client] = true;
				subtractCredits(client, g_iConfig[c_shopFAKEID].IntValue);
				CPrintToChat(client, g_sTag, "Item bought! Your REAL money is", client, g_iCredits[client]);
			}
			else CPrintToChat(client, g_sTag, "You don't have enough money", client);
		}
		else if ( strcmp(info,"buyT") == 0 )
		{
			if(g_iCredits[client] >= g_iConfig[c_shopT].IntValue)
			{
				g_iRole[client] = TTT_TEAM_TRAITOR;
				TeamInitialize(client);
				subtractCredits(client, g_iConfig[c_shopT].IntValue);
				CPrintToChat(client, g_sTag, "Item bought! Your REAL money is", client, g_iCredits[client]);
			}
			else CPrintToChat(client, g_sTag, "You don't have enough money", client);
		}
		else if ( strcmp(info,"buyD") == 0 )
		{
			if(g_iCredits[client] >= g_iConfig[c_shopD].IntValue)
			{
				g_iRole[client] = TTT_TEAM_DETECTIVE;
				TeamInitialize(client);
				subtractCredits(client, g_iConfig[c_shopD].IntValue);
				CPrintToChat(client, g_sTag, "Item bought! Your REAL money is", client, g_iCredits[client]);
			}
			else CPrintToChat(client, g_sTag, "You don't have enough money", client);
		}
		else if ( strcmp(info,"taser") == 0 )
		{
			if(g_iCredits[client] >= g_iConfig[c_shopTASER].IntValue)
			{
				GivePlayerItem(client, "weapon_taser");
				subtractCredits(client, g_iConfig[c_shopTASER].IntValue);
				CPrintToChat(client, g_sTag, "Item bought! Your REAL money is", client, g_iCredits[client]);
			}
			else CPrintToChat(client, g_sTag, "You don't have enough money", client);
		}
		else if ( strcmp(info,"usps") == 0 )
		{
			if(g_iCredits[client] >= g_iConfig[c_shopUSP].IntValue)
			{
				if (g_iRole[client] != TTT_TEAM_TRAITOR)
					return;
				if (GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != -1)
					SDKHooks_DropWeapon(client, GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY));
				
				GivePlayerItem(client, "weapon_usp_silencer");
				subtractCredits(client, g_iConfig[c_shopUSP].IntValue);
				CPrintToChat(client, g_sTag, "Item bought! Your REAL money is", client, g_iCredits[client]);
			}
			else CPrintToChat(client, g_sTag, "You don't have enough money", client);
		}
		else if ( strcmp(info,"m4s") == 0 )
		{
			if(g_iCredits[client] >= g_iConfig[c_shopM4A1].IntValue)
			{
				if (g_iRole[client] != TTT_TEAM_TRAITOR)
					return;
				
				if (GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1)
					SDKHooks_DropWeapon(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
				
				GivePlayerItem(client, "weapon_m4a1_silencer");
				subtractCredits(client, g_iConfig[c_shopM4A1].IntValue);
				CPrintToChat(client, g_sTag, "Item bought! Your REAL money is", client, g_iCredits[client]);
			}
			else CPrintToChat(client, g_sTag, "You don't have enough money", client);
		}
		else if ( strcmp(info,"jbomb") == 0 )
		{
			if(g_iCredits[client] >= g_iConfig[c_shopJIHADBOMB].IntValue)
			{
				if (g_iRole[client] != TTT_TEAM_TRAITOR)
					return;
				g_bJihadBomb[client] = true;
				ClearTimer(g_hJihadBomb[client]);
				g_hJihadBomb[client] = CreateTimer(60.0, BombaArmada, client);
				subtractCredits(client, g_iConfig[c_shopJIHADBOMB].IntValue);
				CPrintToChat(client, g_sTag, "Item bought! Your REAL money is", client, g_iCredits[client]);
				CPrintToChat(client, g_sTag, "bomb will arm in 60 seconds, double tab F to explode", client);
			}
			else CPrintToChat(client, g_sTag, "You don't have enough money", client);
		}
		else if (strcmp(info, "C4") == 0) {
			if (g_iCredits[client] >= g_iConfig[c_shopC4].IntValue) {
				if (g_iRole[client] != TTT_TEAM_TRAITOR)
					return;
				g_bHasC4[client] = true;
				subtractCredits(client, g_iConfig[c_shopC4].IntValue);
				CPrintToChat(client, g_sTag, "Item bought! Your REAL money is", client, g_iCredits[client]);
				CPrintToChat(client, g_sTag, "Right click to plant the C4", client);
			}
			else CPrintToChat(client, g_sTag, "You don't have enough money", client);
		}
		else if (strcmp(info, "HealthStation") == 0) {
			if (g_iCredits[client] >= g_iConfig[c_shopHEALTH].IntValue) {
				if (g_iRole[client] != TTT_TEAM_DETECTIVE)
					return;
				if (g_bHasActiveHealthStation[client]) {
					CPrintToChat(client, g_sTag, "You already have an active Health Station", client);
					return;
				}
				spawnHealthStation(client);
				subtractCredits(client, g_iConfig[c_shopHEALTH].IntValue);
				CPrintToChat(client, g_sTag, "Item bought! Your REAL money is", client, g_iCredits[client]);
			}
		}
	}
		
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action BombaArmada(Handle timer, any client) 
{ 
	CPrintToChat(client, g_sTag, "Your bomb is now armed.", client);
	EmitAmbientSound("buttons/blip2.wav", NULL_VECTOR, client);
	g_hJihadBomb[client] = null;	
} 

stock void MostrarMenu(int client, int victima2, int atacante2, int tiempo2, const char[] weapon, const char[] victimaname2, const char[] atacantename2)
{
	char team[32];
	if(g_iRole[victima2] == TTT_TEAM_TRAITOR)
		Format(team, sizeof(team), "%T", "Traitors", client);
	else if(g_iRole[victima2] == TTT_TEAM_DETECTIVE)
		Format(team, sizeof(team), "%T", "Detectives", client);
	else if(g_iRole[victima2] == TTT_TEAM_INNOCENT) 
		Format(team, sizeof(team), "%T", "Innocents", client);

	Handle menu = CreateMenu(BodyMenuHandler);
	char Item[128];
	
	SetMenuTitle(menu, "%T", "Inspected body. The extracted data are the following", client);
	
	Format(Item, sizeof(Item), "%T", "Victim name", client, victimaname2);
	AddMenuItem(menu, "", Item);
	
	Format(Item, sizeof(Item), "%T", "Team victim", client, team);
	AddMenuItem(menu, "", Item);
	
	if(g_iRole[client] == TTT_TEAM_DETECTIVE)
	{
		Format(Item, sizeof(Item), "%T", "Elapsed since his death", client, tiempo2);
		AddMenuItem(menu, "", Item);
		
		if(atacante2 > 0 && atacante2 != victima2)
		{
			Format(Item, sizeof(Item), "%T", "The weapon used has been", client, weapon);
			AddMenuItem(menu, "", Item);
		}
		else
		{
			Format(Item, sizeof(Item), "%T", "The weapon used has been: himself (suicide)", client);
			AddMenuItem(menu, "", Item);
		}
	}
	
	if(g_bScan[client])
	{
		if(atacante2 > 0 && atacante2 != victima2) Format(Item, sizeof(Item), "%T", "Killer is Player",client, atacantename2);
		else Format(Item, sizeof(Item), "%T", "Player committed suicide", client);
		
		AddMenuItem(menu, "", Item);
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 15);
	
}

public int BodyMenuHandler(Menu menu, MenuAction action, int client, int itemNum) 
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

stock void Set1Knife(int client)
{
	g_b1Knife[client] = true;
	int iWeapon = GetPlayerWeaponSlot(client, 2);
	if (iWeapon != INVALID_ENT_REFERENCE) 
	{
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "Kill");
	} 
	GivePlayerItem(client, "weapon_knife");
}

stock void Remove1Knife(int client)
{
	g_b1Knife[client] = false;
	int iWeapon = GetPlayerWeaponSlot(client, 2);
	if (iWeapon != INVALID_ENT_REFERENCE) 
	{
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "Kill");
	} 
	GivePlayerItem(client, "weapon_knife");
}

stock void ClearIcon(int client)
{
	if(g_iIcon[client] > 0 && IsValidEdict(g_iIcon[client]))
	{
		if(g_iRole[client] == TTT_TEAM_TRAITOR) SDKUnhook(g_iIcon[client], SDKHook_SetTransmit, Hook_SetTransmitT);
		AcceptEntityInput(g_iIcon[client], "Kill");
	}
	g_iIcon[client] = 0;
	
}

stock void addKarma(int client, int karma, bool message = false)
{
	g_iKarma[client] += karma;
	
	if(g_iKarma[client] > g_iConfig[c_maxKarma].IntValue)
		g_iKarma[client] = g_iConfig[c_maxKarma].IntValue;
	
	if (g_iConfig[c_showEarnKarmaMessage].IntValue && message)
	{
		if(g_iConfig[c_messageTypKarma].IntValue == 1)
	  		PrintHintText(client, "%T", "karma earned", client, karma, g_iKarma[client]);
	  	else
	  		CPrintToChat(client, "%T", "karma earned", client, karma, g_iKarma[client]);	
	}
	
	UpdateKarma(client, g_iKarma[client]);
}

stock void setKarma(int client, int karma)
{
	g_iKarma[client] = karma;
	
	if(g_iKarma[client] > g_iConfig[c_maxKarma].IntValue)
		g_iKarma[client] = g_iConfig[c_maxKarma].IntValue;
	
	UpdateKarma(client, g_iKarma[client]);
}

stock void subtractKarma(int client, int karma, bool message = false)
{
	g_iKarma[client] -= karma;
	
	if (g_iConfig[c_showLoseKarmaMessage].IntValue && message)
	{
		if(g_iConfig[c_messageTypKarma].IntValue == 1)
	  		PrintHintText(client, "%T", "lost karma", client, karma, g_iKarma[client]);
	  	else
	  		CPrintToChat(client, "%T", "lost karma", client, karma, g_iKarma[client]);	
	}
	
	UpdateKarma(client, g_iKarma[client]);
}

stock void UpdateKarma(int client, int karma)
{
	char sCommunityID[64];
		
	if(!GetClientAuthId(client, AuthId_SteamID64, sCommunityID, sizeof(sCommunityID)))
		return;
	
	char sQuery[2048];
	Format(sQuery, sizeof(sQuery), "UPDATE `ttt` SET `karma`=%d WHERE `communityid`=\"%s\";", karma, sCommunityID);
	
	if(g_hDatabase != null)
		SQL_TQuery(g_hDatabase, Callback_Karma, sQuery, GetClientUserId(client));
}

stock void addCredits(int client, int credits, bool message = false)
{
	credits = RoundToNearest((credits) * (g_iKarma[client] * 0.01));
	
	g_iCredits[client] += credits;
	
	if (g_iConfig[c_showEarnCreditsMessage].IntValue && message)
	{
		if(g_iConfig[c_messageTypCredits].IntValue == 1)
		{
			char sBuffer[MAX_MESSAGE_LENGTH];
			Format(sBuffer, sizeof(sBuffer), "%T", "credits earned", client, credits, g_iCredits[client]);
			CFormatColor(sBuffer, sizeof(sBuffer), client);
			PrintHintText(client, sBuffer);
		}
		else
			CPrintToChat(client, "%T", "credits earned", client, credits, g_iCredits[client]);
	}
}

stock void subtractCredits(int client, int credits, bool message = false)
{
	g_iCredits[client] -= credits;
	
	if(g_iCredits[client] < 0)
		g_iCredits[client] = 0;
	
	if (g_iConfig[c_showLoseCreditsMessage].IntValue && message)
	{
		if(g_iConfig[c_messageTypCredits].IntValue == 1)
		{
			char sBuffer[MAX_MESSAGE_LENGTH];
			Format(sBuffer, sizeof(sBuffer), "%T", "lost credits", client, credits, g_iCredits[client]);
			CFormatColor(sBuffer, sizeof(sBuffer), client);
			PrintHintText(client, sBuffer);
		}
		else
			CPrintToChat(client, "%T", "lost credits", client, credits, g_iCredits[client]);
	}
}

stock void setCredits(int client, int credits)
{
	g_iCredits[client] = credits;
	
	if(g_iCredits[client] < 0)
		g_iCredits[client] = 0;
}

stock void ClearTimer(Handle &timer)
{
    if (timer != null)
    {
        KillTimer(timer);
        timer = null;
    }     
} 

stock void Detonate(int client) 
{ 
    int ExplosionIndex = CreateEntityByName("env_explosion"); 
    if (ExplosionIndex != -1) 
    { 
        SetEntProp(ExplosionIndex, Prop_Data, "m_spawnflags", 16384); 
        SetEntProp(ExplosionIndex, Prop_Data, "m_iMagnitude", 1000); 
        SetEntProp(ExplosionIndex, Prop_Data, "m_iRadiusOverride", 600); 

        DispatchSpawn(ExplosionIndex); 
        ActivateEntity(ExplosionIndex); 
         
        float playerEyes[3]; 
        GetClientEyePosition(client, playerEyes); 

        TeleportEntity(ExplosionIndex, playerEyes, NULL_VECTOR, NULL_VECTOR); 
        SetEntPropEnt(ExplosionIndex, Prop_Send, "m_hOwnerEntity", client); 
         
        EmitAmbientSoundAny("ttt/jihad/explosion.mp3", NULL_VECTOR, client, SNDLEVEL_RAIDSIREN); 
         
         
        AcceptEntityInput(ExplosionIndex, "Explode"); 
         
        AcceptEntityInput(ExplosionIndex, "Kill"); 
    } 
    g_bJihadBomb[client] = false;
} 

public Action Command_Detonate(int client, int args) 
{ 
    if (!g_bJihadBomb[client]) 
    { 
		CPrintToChat(client, g_sTag, "You dont have it!", client);
		return Plugin_Handled; 
    } 
	
    if (g_hJihadBomb[client] != null) 
    { 
		CPrintToChat(client, g_sTag, "Your bomb is not armed.", client);
		return Plugin_Handled; 
    } 
     
    EmitAmbientSoundAny("ttt/jihad/jihad.mp3", NULL_VECTOR, client); 
         
    CreateTimer(2.0, TimerCallback_Detonate, client); 
    g_bJihadBomb[client] = false;

    return Plugin_Handled; 
} 

public Action TimerCallback_Detonate(Handle timer, any client) 
{ 
    if(!client || !IsClientInGame(client) || !IsPlayerAlive(client)) 
        return Plugin_Handled;
    
    Detonate(client); 
    return Plugin_Handled; 
} 

public Action Command_LAW(int client, const char[] command, int argc)
{

	if(!TTT_IsClientValid(client))
		return Plugin_Continue;
	
	if(IsPlayerAlive(client) && g_bJihadBomb[client] && g_hJihadBomb[client] == null && g_bDetonate[client])
	{
		EmitAmbientSoundAny("ttt/jihad/jihad.mp3", NULL_VECTOR, client); 
         
		CreateTimer(2.0, TimerCallback_Detonate, client); 
		g_bJihadBomb[client] = false;
		
		return Plugin_Continue;
	}
	else
	{
		g_bDetonate[client] = true;
		CreateTimer(2.0, PasarJ, client);
	}
	
	if(g_iConfig[c_allowFlash].IntValue)
	{
		EmitSoundToAll(SND_FLASHLIGHT, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.6);
		SetEntProp(client, Prop_Send, "m_fEffects", GetEntProp(client, Prop_Send, "m_fEffects") ^ 4);
	}		
	
	if(g_iConfig[c_blockLookAtWeapon].IntValue)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action PasarJ(Handle timer, any client) 
{ 
	if(!client || !IsClientInGame(client)) 
		return Plugin_Handled;
	
	g_bDetonate[client] = false;
	return Plugin_Handled; 
} 

stock void manageRDM(int client)
{
	if (!IsClientInGame(client))
		return;
		
	int iAttacker = g_iRDMAttacker[client];
	if (!IsClientInGame(iAttacker) || iAttacker < 0 || iAttacker > MaxClients)
	{
		CPrintToChat(client, g_sTag, "The player who RDM'd you is no longer available", client);
		return;
	}
	char sAttackerName[MAX_NAME_LENGTH];
	GetClientName(iAttacker, sAttackerName, sizeof(sAttackerName));
	
	char display[256], sForgive[64], sPunish[64];
	Format(display, sizeof(display), "%T", "You were RDM'd", client, sAttackerName);
	Format(sForgive, sizeof(sForgive), "%T", "Forgive", client);
	Format(sPunish, sizeof(sPunish), "%T", "Punish", client);
	
	Handle menuHandle = CreateMenu(manageRDMHandle);
	SetMenuTitle(menuHandle, display);
	AddMenuItem(menuHandle, "Forgive", sForgive);
	AddMenuItem(menuHandle, "Punish", sPunish);
	DisplayMenu(menuHandle, client, 10);
}

public int manageRDMHandle(Menu menu, MenuAction action, int client, int option)
{
	if (1 > client || client > MaxClients || !IsClientInGame(client))
		return;
		
	int iAttacker = g_iRDMAttacker[client];
	if (1 > iAttacker || iAttacker > MaxClients || !IsClientInGame(iAttacker))
		return;
		
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[100];
			GetMenuItem(menu, option, info, sizeof(info));
			if (StrEqual(info, "Forgive", false))
			{
				CPrintToChat(client, g_sTag, "Choose Forgive Victim", client, iAttacker);
				CPrintToChat(iAttacker, g_sTag, "Choose Forgive Attacker", iAttacker, client);
				g_iRDMAttacker[client] = -1;
			}
			if (StrEqual(info, "Punish", false))
			{
				LoopValidClients(i)
					CPrintToChat(i, g_sTag, "Choose Punish", i, client, iAttacker);
				ServerCommand("sm_slay #%i 2", GetClientUserId(iAttacker));
				g_iRDMAttacker[client] = -1;
			}
		}
		case MenuAction_Cancel:
		{
			CPrintToChat(client, g_sTag, "Choose Forgive Victim", client, iAttacker);
			CPrintToChat(iAttacker, g_sTag, "Choose Forgive Attacker", iAttacker, client);
			g_iRDMAttacker[client] = -1;
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
			CPrintToChat(client, g_sTag, "Choose Forgive Victim", client, iAttacker);
			CPrintToChat(iAttacker, g_sTag, "Choose Forgive Attacker", iAttacker, client);
			g_iRDMAttacker[client] = -1;
		}
	}
}

public Action Timer_RDMTimer(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	g_hRDMTimer[client] = null;
	manageRDM(client);
	return Plugin_Stop;
}

public Action Command_SetRole(int client, int args)
{
	if (args < 2 || args > 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_role <#userid|name> <role>");
		ReplyToCommand(client, "[SM] Roles: 1 - Innocent | 2 - Traitor | 3 - Detective");
		return Plugin_Handled;
	}
	char arg1[32];
	char arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	int target = FindTarget(client, arg1);
	
	if (target == -1)
		return Plugin_Handled;

	if (!IsPlayerAlive(target))
	{
		ReplyToCommand(client, "[SM] This command can only be used to alive players!");
		return Plugin_Handled;
	}
	
	int role = StringToInt(arg2);
	if (role < 1 || role > 3)
	{
		ReplyToCommand(client, "[SM] Roles: 1 - Innocent | 2 - Traitor | 3 - Detective");
		return Plugin_Handled;
	}
	else if (role == TTT_TEAM_INNOCENT)
	{
		g_iRole[target] = TTT_TEAM_INNOCENT;
		TeamInitialize(target);
		ClearIcon(target);
		CS_SetClientClanTag(target, "");
		CPrintToChat(client, g_sTag, "Player is Now Innocent", client, target);
		return Plugin_Handled;
	}
	else if (role == TTT_TEAM_TRAITOR)
	{
		g_iRole[target] = TTT_TEAM_TRAITOR;
		TeamInitialize(target);
		ClearIcon(target);
		ApplyIcons();
		CS_SetClientClanTag(target, "");
		CPrintToChat(client, g_sTag, "Player is Now Traitor", client, target);
		return Plugin_Handled;
	}
	else if (role == TTT_TEAM_DETECTIVE && g_bConfirmDetectiveRules[target])
	{
		g_iRole[target] = TTT_TEAM_DETECTIVE;
		TeamInitialize(target);
		ClearIcon(target);
		ApplyIcons();
		CPrintToChat(client, g_sTag, "Player is Now Detective", client, target);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_SetKarma(int client, int args)
{
	if (args < 2 || args > 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setkarma <#userid|name> <karma>");

		return Plugin_Handled;
	}
	char arg1[32];
	char arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	int target = FindTarget(client, arg1);
	
	if (target == -1)
		return Plugin_Handled;

	int karma = StringToInt(arg2);
	
	setKarma(client, karma);
	
	return Plugin_Continue;
}

public Action Command_SetCredits(int client, int args)
{
	if (args < 2 || args > 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setcredits <#userid|name> <credits>");

		return Plugin_Handled;
	}
	char arg1[32];
	char arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	int target = FindTarget(client, arg1);
	
	if (target == -1)
		return Plugin_Handled;

	int credits = StringToInt(arg2);
	
	setCredits(client, credits);
	
	return Plugin_Continue;
}

public Action Command_Status(int client, int args)
{
	if (0 > client || client > MaxClients || !IsClientInGame(client))
		return Plugin_Handled;
		
	if (g_iRole[client] == TTT_TEAM_UNASSIGNED)
		CPrintToChat(client, g_sTag, "You Are Unassigned", client); 
	else if (g_iRole[client] == TTT_TEAM_INNOCENT)
		CPrintToChat(client, g_sTag, "You Are Now Innocent", client);
	else if (g_iRole[client] == TTT_TEAM_DETECTIVE)
		CPrintToChat(client, g_sTag, "You Are Now Detective", client);
	else if (g_iRole[client] == TTT_TEAM_TRAITOR)
		CPrintToChat(client, g_sTag, "You Are Now Traitor", client);
	
	return Plugin_Handled;
}

public Action Timer_5(Handle timer)
{
	LoopValidClients(i)
	{
		if (!IsPlayerAlive(i))
			continue;

		g_iIcon[i] = CreateIcon(i);
		
		if (g_iRole[i] == TTT_TEAM_DETECTIVE)
			ShowOverlayToClient(i, "darkness/ttt/overlayDetective");
		else if (g_iRole[i] == TTT_TEAM_TRAITOR)
			ShowOverlayToClient(i, "darkness/ttt/overlayTraitor");
		else if (g_iRole[i] == TTT_TEAM_INNOCENT)
			ShowOverlayToClient(i, "darkness/ttt/overlayInnocent");
		
		if (g_bHasActiveHealthStation[i] && g_iHealthStationCharges[i] < 9)
			g_iHealthStationCharges[i]++;
			
		if(g_bKarma[i] && g_iConfig[c_karmaBan].IntValue != 0 && g_iKarma[i] <= g_iConfig[c_karmaBan].IntValue)
		{
			BanBadPlayerKarma(i);
		}
	}
	
	if(g_bRoundStarted)
		CheckTeams();
}

public void OnEntityCreated(int entity, const char[] className)
{
	if (StrEqual(className, "func_button"))
	{
		char targetName[128];
		GetEntPropString(entity, Prop_Data, "m_iName", targetName, sizeof(targetName));
		if (StrEqual(targetName, "Destroy_Trigger", false))
			SDKHook(entity, SDKHook_Use, OnUse);
	}
}

public Action OnUse(int entity, int activator, int caller, UseType type, float value)
{
	if (activator < 1 || activator > MaxClients || !IsClientInGame(activator))
		return Plugin_Continue;
		
	if (g_bInactive)
		return Plugin_Handled;
		
	else
	{
		if (g_iRole[activator] == TTT_TEAM_INNOCENT || g_iRole[activator] == TTT_TEAM_DETECTIVE || g_iRole[activator] == TTT_TEAM_UNASSIGNED)
		{
			ServerCommand("sm_slay #%i 2", GetClientUserId(activator));
			
			LoopValidClients(i)
				CPrintToChat(i, g_sTag, "Triggered Falling Building", i, activator);
		}
	}
	return Plugin_Continue;
}

public Action explodeC4(Handle timer, Handle pack)
{
	int clientUserId;
	int bombEnt;
	ResetPack(pack);
	clientUserId = ReadPackCell(pack);
	bombEnt = ReadPackCell(pack);
	int client = GetClientOfUserId(clientUserId);
	float explosionOrigin[3];
	GetEntPropVector(bombEnt, Prop_Send, "m_vecOrigin", explosionOrigin);
	if (TTT_IsClientValid(client))
	{
		g_bHasActiveBomb[client] = false;
		g_hExplosionTimer[client] = null;
		g_bImmuneRDMManager[client] = true;
		CPrintToChat(client, g_sTag, "Bomb Detonated", client);
	}
	else
		return Plugin_Stop;

	int explosionIndex = CreateEntityByName("env_explosion");
	int particleIndex = CreateEntityByName("info_particle_system");
	int shakeIndex = CreateEntityByName("env_shake");
	if (explosionIndex != -1 && particleIndex != -1 && shakeIndex != -1)
	{
		DispatchKeyValue(shakeIndex, "amplitude", "4"); 
		DispatchKeyValue(shakeIndex, "duration", "1"); 
		DispatchKeyValue(shakeIndex, "frequency", "2.5"); 
		DispatchKeyValue(shakeIndex, "radius", "5000");
		DispatchKeyValue(particleIndex, "effect_name", "explosion_c4_500");
		SetEntProp(explosionIndex, Prop_Data, "m_spawnflags", 16384);
		SetEntProp(explosionIndex, Prop_Data, "m_iRadiusOverride", 850);
		SetEntProp(explosionIndex, Prop_Data, "m_iMagnitude", 850);
		SetEntPropEnt(explosionIndex, Prop_Send, "m_hOwnerEntity", client);
		DispatchSpawn(particleIndex);
		DispatchSpawn(explosionIndex);
		DispatchSpawn(shakeIndex);
		ActivateEntity(shakeIndex);
		ActivateEntity(particleIndex);
		ActivateEntity(explosionIndex);
		TeleportEntity(particleIndex, explosionOrigin, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(explosionIndex, explosionOrigin, NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(shakeIndex, explosionOrigin, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(bombEnt, "Kill");
		AcceptEntityInput(explosionIndex, "Explode");
		AcceptEntityInput(particleIndex, "Start");
		AcceptEntityInput(shakeIndex, "StartShake");
		AcceptEntityInput(explosionIndex, "Kill");
		
		LoopValidClients(i)
		{
			if (!IsPlayerAlive(i))
				continue;
				
			float clientOrigin[3];
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", clientOrigin);
			
			if (GetVectorDistance(clientOrigin, explosionOrigin) <= 275.0)
			{
				Handle killEvent = CreateEvent("player_death", true);
				SetEventInt(killEvent, "userid", GetClientUserId(i));
				SetEventInt(killEvent, "attacker", GetClientUserId(client));
				FireEvent(killEvent, false);
				ForcePlayerSuicide(i);
			}
		}
		
		for (int i = 1; i <= 2; i++)
			EmitAmbientSoundAny("training/firewerks_burst_02.wav", explosionOrigin, _, SNDLEVEL_RAIDSIREN);
			
		CreateTimer(2.0, UnImmune, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action UnImmune(Handle timer, any userId)
{
	int client = GetClientOfUserId(userId);
	if (TTT_IsClientValid(client))
		g_bImmuneRDMManager[client] = false;
	return Plugin_Stop;
}

public Action bombBeep(Handle timer, Handle pack)
{
	int bombEnt;
	int beeps;
	ResetPack(pack);
	bombEnt = ReadPackCell(pack);
	beeps = ReadPackCell(pack);
	if (!IsValidEntity(bombEnt))
		return Plugin_Stop;
		
	int owner = GetEntProp(bombEnt, Prop_Send, "m_hOwnerEntity");
	if (!TTT_IsClientValid(owner))
		return Plugin_Stop;
		
	float bombPos[3];
	GetEntPropVector(bombEnt, Prop_Data, "m_vecOrigin", bombPos);
	bool stopBeeping = false;
	if (beeps > 0)
	{
		EmitAmbientSoundAny("weapons/c4/c4_beep1.wav", bombPos);
		beeps--;
		stopBeeping = false;
	}
	else
		stopBeeping = true;
	if (stopBeeping)
		return Plugin_Stop;

	Handle bombBeep2;
	CreateDataTimer(1.0, bombBeep, bombBeep2);
	WritePackCell(bombBeep2, bombEnt);
	WritePackCell(bombBeep2, beeps);
	return Plugin_Stop;
}


stock void showPlantMenu(int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	char sTitle[128];
	char s10[64], s20[64], s30[64], s40[64], s50[64], s60[64];
	
	Format(sTitle, sizeof(sTitle), "%T", "Set C4 Timer", client);
	Format(s10, sizeof(s10), "%T", "Seconds", client, 10);
	Format(s20, sizeof(s20), "%T", "Seconds", client, 20);
	Format(s30, sizeof(s30), "%T", "Seconds", client, 30);
	Format(s40, sizeof(s40), "%T", "Seconds", client, 40);
	Format(s50, sizeof(s50), "%T", "Seconds", client, 50);
	Format(s60, sizeof(s60), "%T", "Seconds", client, 60);
	
	Handle menuHandle = CreateMenu(plantBombMenu);
	SetMenuTitle(menuHandle, sTitle);
	AddMenuItem(menuHandle, "10", s10);
	AddMenuItem(menuHandle, "20", s20);
	AddMenuItem(menuHandle, "30", s30);
	AddMenuItem(menuHandle, "40", s40);
	AddMenuItem(menuHandle, "50", s50);
	AddMenuItem(menuHandle, "60", s60);
	SetMenuPagination(menuHandle, 6);
	DisplayMenu(menuHandle, client, 10);
}

stock void showDefuseMenu(int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	char sTitle[128];
	char sWire1[64], sWire2[64], sWire3[64], sWire4[64];
	
	Format(sTitle, sizeof(sTitle), "%T", "Defuse C4", client);
	Format(sWire1, sizeof(sWire1), "%T", "C4 Wire", client, 1);
	Format(sWire2, sizeof(sWire2), "%T", "C4 Wire", client, 2);
	Format(sWire3, sizeof(sWire3), "%T", "C4 Wire", client, 3);
	Format(sWire4, sizeof(sWire4), "%T", "C4 Wire", client, 4);
	
	Handle menuHandle= CreateMenu(defuseBombMenu);
	SetMenuTitle(menuHandle, sTitle);
	AddMenuItem(menuHandle, "1", sWire1);
	AddMenuItem(menuHandle, "2", sWire2);
	AddMenuItem(menuHandle, "3", sWire3);
	AddMenuItem(menuHandle, "4", sWire4);
	SetMenuPagination(menuHandle, 4);
	DisplayMenu(menuHandle, client, 10);
}

public int plantBombMenu(Menu menu, MenuAction action, int client, int option)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;
		
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[100];
			GetMenuItem(menu, option, info, sizeof(info));
			if (StrEqual(info, "10"))
				plantBomb(client, 10.0);
			else if (StrEqual(info, "20"))
				plantBomb(client, 20.0);
			else if (StrEqual(info, "30"))
				plantBomb(client, 30.0);
			else if (StrEqual(info, "40"))
				plantBomb(client, 40.0);
			else if (StrEqual(info, "50"))
				plantBomb(client, 50.0);
			else if (StrEqual(info, "60"))
				plantBomb(client, 60.0);
			g_bHasC4[client] = false;
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
			g_bHasActiveBomb[client] = false;
			int iEnt;
			
			while ((iEnt = FindEntityByClassname(iEnt, "prop_physics")) != -1)
				if (GetEntProp(iEnt, Prop_Send, "m_hOwnerEntity") == client)
					AcceptEntityInput(iEnt, "Kill");
		}
		case MenuAction_Cancel:
		{
			g_bHasActiveBomb[client] = false;
			int iEnt;
			while ((iEnt = FindEntityByClassname(iEnt, "prop_physics")) != -1)
				if (GetEntProp(iEnt, Prop_Send, "m_hOwnerEntity") == client)
					AcceptEntityInput(iEnt, "Kill");
		}
	}
}

public int defuseBombMenu(Menu menu, MenuAction action, int client, int option)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[100];
			int planter = g_iDefusePlayerIndex[client];	
			g_iDefusePlayerIndex[client] = -1;
			
			if (planter < 1 || planter > MaxClients || !IsClientInGame(planter))
			{
				g_iDefusePlayerIndex[client] = -1;
				return;
			}
			
			int wire;
			int correctWire;
			int planterBombIndex = findBomb(planter);
			float bombPos[3];
			GetEntPropVector(planterBombIndex, Prop_Data, "m_vecOrigin", bombPos);
			correctWire = g_iWire[planter];
			GetMenuItem(menu, option, info, sizeof(info));
			wire = StringToInt(info);
			if (wire == correctWire)
			{
				if (1 <= planter <= MaxClients && IsClientInGame(planter))
				{
					CPrintToChat(client, g_sTag, "You Defused Bomb", client, planter);
					CPrintToChat(planter, g_sTag, "Has Defused Bomb", planter, client);
					EmitAmbientSoundAny("weapons/c4/c4_disarm.wav", bombPos);
					g_bHasActiveBomb[planter] = false;
					ClearTimer(g_hExplosionTimer[planter]);
					SetEntProp(planterBombIndex, Prop_Send, "m_hOwnerEntity", -1);
				}
			}
			else
			{
				CPrintToChat(client, g_sTag, "Failed Defuse", client);
				ForcePlayerSuicide(client);
				g_iDefusePlayerIndex[client] = -1;
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
			g_iDefusePlayerIndex[client] = -1;
		}
		case MenuAction_Cancel:
			g_iDefusePlayerIndex[client] = -1;
	}
}

stock float plantBomb(int client, float time)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
		return;
		
	if (!IsPlayerAlive(client))
	{
		CPrintToChat(client, g_sTag, "Alive to Plant", client);
		return;
	}
	
	CPrintToChat(client, g_sTag, "Will Explode In", client, time);
	
	int bombEnt;
	while ((bombEnt = FindEntityByClassname(bombEnt, "prop_physics")) != -1)
	{
		if (GetEntProp(bombEnt, Prop_Send, "m_hOwnerEntity") == client)
		{
			if (bombEnt != -1)
			{
				Handle explosionPack;
				Handle beepPack;
				if (g_hExplosionTimer[client] != null)
					KillTimer(g_hExplosionTimer[client]);
				g_hExplosionTimer[client] = CreateDataTimer(time, explodeC4, explosionPack);
				CreateDataTimer(1.0, bombBeep, beepPack);
				WritePackCell(explosionPack, GetClientUserId(client));
				WritePackCell(explosionPack, bombEnt);
				WritePackCell(beepPack, bombEnt);
				WritePackCell(beepPack, (time - 1));
				g_bHasActiveBomb[client] = true;
			}
			else
				CPrintToChat(client, g_sTag, "Bomb Was Not Found", client);
		}
	}
	g_iWire[client] = Math_GetRandomInt(1, 4);
	CPrintToChat(client, g_sTag, "Wire Is", client, g_iWire[client]);
}

stock int findBomb(int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
		return -1;
		
	int iEnt;
	while ((iEnt = FindEntityByClassname(iEnt, "prop_physics")) != -1)
	{
		if (GetEntProp(iEnt, Prop_Send, "m_hOwnerEntity") == client)
			return iEnt;
	}
	return -1;
}

stock void resetPlayers()
{
	LoopValidClients(i)
	{
		ClearTimer(g_hExplosionTimer[i]);
		g_bHasActiveBomb[i] = false;
	}
}

stock void listTraitors(int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
		return;
	
	CPrintToChat(client, g_sTag, "Your Traitor Partners", client);
	int iCount = 0;
	
	LoopValidClients(i)
	{
		if (!IsPlayerAlive(i) || client == i || g_iRole[i] != TTT_TEAM_TRAITOR)
			continue;
		CPrintToChat(client, g_sTag, "Traitor List", client, i);
		iCount++;
	}
	
	if(iCount == 0)
		CPrintToChat(client, g_sTag, "No Traitor Partners", client);
}

stock void nameCheck(int client, char name[MAX_NAME_LENGTH])
{
	for(int i; i < g_iBadNameCount; i++)
		if (StrContains(g_sBadNames[i], name, false) != -1)
			KickClient(client, "%T", "Kick Bad Name", client, g_sBadNames[i]);
}

stock void healthStation_cleanUp()
{
	LoopValidClients(i)
	{
		g_iHealthStationCharges[i] = 0;
		g_bHasActiveHealthStation[i] = false;
		g_bOnHealingCoolDown[i] = false;
		
		ClearTimer(g_hRemoveCoolDownTimer[i]);
	}
}

public Action removeCoolDown(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	g_bOnHealingCoolDown[client] = false;
	g_hRemoveCoolDownTimer[client] = null;
	return Plugin_Stop;
}

stock void spawnHealthStation(int client)
{
	if (!IsPlayerAlive(client))
		return;
		
	int healthStationIndex = CreateEntityByName("prop_physics_multiplayer");
	if (healthStationIndex != -1)
	{
		float clientPos[3];
		GetClientAbsOrigin(client, clientPos);
		SetEntProp(healthStationIndex, Prop_Send, "m_hOwnerEntity", client);
		DispatchKeyValue(healthStationIndex, "model", "models/props/cs_office/microwave.mdl");
		DispatchSpawn(healthStationIndex);
		SDKHook(healthStationIndex, SDKHook_OnTakeDamage, OnTakeDamageHealthStation);
		TeleportEntity(healthStationIndex, clientPos, NULL_VECTOR, NULL_VECTOR);
		g_iHealthStationHealth[client] = 10;
		g_bHasActiveHealthStation[client] = true;
		g_iHealthStationCharges[client] = 10;
		CPrintToChat(client, g_sTag, "Health Station Deployed", client);
	}
}

public Action OnTakeDamageHealthStation(int stationIndex, int &iAttacker, int &inflictor, float &damage, int &damagetype)
{
	if (!IsValidEntity(stationIndex) || stationIndex == INVALID_ENT_REFERENCE || stationIndex <= MaxClients || iAttacker < 1 || iAttacker > MaxClients || !IsClientInGame(iAttacker))
		return Plugin_Continue;
	
	int owner = GetEntProp(stationIndex, Prop_Send, "m_hOwnerEntity");
	if (owner < 1 || owner > MaxClients || !IsClientInGame(owner))
		return Plugin_Continue;
		
	g_iHealthStationHealth[owner]--;
	
	if (g_iHealthStationHealth[owner] <= 0)
	{
		AcceptEntityInput(stationIndex, "Kill");
		g_bHasActiveHealthStation[owner] = false;
	}
	return Plugin_Continue;
}

public Action healthStationDistanceCheck(Handle timer)
{
	LoopValidClients(i)
	{
		if (!IsPlayerAlive(i))
			continue;
		
		checkDistanceFromHealthStation(i);
	}
	return Plugin_Continue;
}

stock void checkDistanceFromHealthStation(int client) {
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client)) return;
	float clientPos[3], stationPos[3]; 
	int curHealth, newHealth, iEnt;
	char sModelName[PLATFORM_MAX_PATH];
	while ((iEnt = FindEntityByClassname(iEnt, "prop_physics_multiplayer")) != -1)
	{
		int owner = GetEntProp(iEnt, Prop_Send, "m_hOwnerEntity");
		if (owner < 1 || owner > MaxClients || !IsClientInGame(owner))
			continue;
		
		GetEntPropString(iEnt, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));

		if (StrContains(sModelName, "microwave") == -1)
			continue;
		
		GetClientEyePosition(client, clientPos);
		GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", stationPos);
		
		if (GetVectorDistance(clientPos, stationPos) > 200.0)
			continue;
		
		if (g_bOnHealingCoolDown[client]) continue;
		curHealth = GetClientHealth(client);
		
		if (curHealth >= 125)
			continue;
		
		if (g_iHealthStationCharges[owner] > 0)
		{
			newHealth = (curHealth + 15);
			if (newHealth >= 125)
				SetEntityHealth(client, 125);
			else
				SetEntityHealth(client, newHealth);

			CPrintToChat(client, g_sTag, "Healing From", client, owner);
			EmitSoundToClientAny(client, "resource/warning.wav");
			g_iHealthStationCharges[owner]--;
			g_bOnHealingCoolDown[client] = true;
			g_hRemoveCoolDownTimer[client] = CreateTimer(1.0, removeCoolDown, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			CPrintToChat(client, g_sTag, "Health Station Out Of Charges", client);
			g_bOnHealingCoolDown[client] = true;
			g_hRemoveCoolDownTimer[client] = CreateTimer(1.0, removeCoolDown, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public void OnWeaponPostSwitch(int client, int weapon)
{
	char weaponName[64];
	GetClientWeapon(client, weaponName, sizeof(weaponName));
	if (StrContains(weaponName, "silence") != -1)
		g_bHoldingSilencedWep[client] = true;
	else
		g_bHoldingSilencedWep[client] = false;
}

public Action Command_KarmaReset(int client, int args)
{
	LoopValidClients(i)
		setKarma(g_iKarma[i], 100);
	return Plugin_Handled;
}

// Thanks SMLib ( https://github.com/bcserv/smlib/blob/master/scripting/include/smlib/math.inc#L149 )
stock int Math_GetRandomInt(int min, int max)
{
	int random = GetURandomInt();
	
	if (random == 0) {
		random++;
	}

	return RoundToCeil(float(random) / (float(2147483647) / float(max - min + 1))) + min - 1;
}

stock void CheckTeams()
{
	int iT = 0;
	int iD = 0;
	int iI = 0;
	
	LoopValidClients(i)
	{
		if(IsPlayerAlive(i))
		{
			if(g_iRole[i] == TTT_TEAM_DETECTIVE)
				iD++;
			else if(g_iRole[i] == TTT_TEAM_TRAITOR)
				iT++;
			else if(g_iRole[i] == TTT_TEAM_INNOCENT)
				iI++;
		}
	}
	
	if(iD == 0 && iI == 0)
	{
		g_bRoundStarted = false;
		CS_TerminateRound(7.0, CSRoundEnd_TerroristWin);
	}
	else if(iT == 0)
	{
		g_bRoundStarted = false;
		CS_TerminateRound(7.0, CSRoundEnd_CTWin);
	}
}

stock void SetNoBlock(int client)
{
	SetEntData(client, g_iCollisionGroup, 2, 4, true);
}

stock void LoadBadNames()
{
	char sFile[PLATFORM_MAX_PATH + 1];
	BuildPath(Path_SM, sFile, sizeof(sFile), "configs/ttt/badnames.ini");
	
	Handle hFile = OpenFile(sFile, "rt");
	
	if(hFile == null)
		SetFailState("[TTT] Can't open File: %s", sFile);
	
	char sLine[MAX_NAME_LENGTH];
	
	while(!IsEndOfFile(hFile) && ReadFileLine(hFile, sLine, sizeof(sLine)))
	{
		if(strlen(sLine) > 1)
		{
			strcopy(g_sBadNames[g_iBadNameCount], sizeof(g_sBadNames[]), sLine);
			g_iBadNameCount++;
		}
	}
	
	delete hFile;
}

public void SQLConnect(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == null || strlen(error) > 0)
	{
		SetFailState("(SQLConnect) Connection to database failed!: %s", error);
		return;
	}
	
	char sDriver[16];
	SQL_GetDriverIdent(owner, sDriver, sizeof(sDriver));
	
	if (!StrEqual(sDriver, "mysql", false) && !StrEqual(sDriver, "sqlite", false))
	{
		SetFailState("(SQLConnect) Only mysql/sqlite support!");
		return;
	}

	g_hDatabase = CloneHandle(hndl);
	
	CheckAndCreateTables(sDriver);

	SQL_SetCharset(g_hDatabase, "utf8");
	
	LoadClients();
}

stock void CheckAndCreateTables(const char[] driver)
{
	char sQuery[256];
	if (StrEqual(driver, "mysql", false))
		Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `ttt` ( `id` INT NOT NULL AUTO_INCREMENT , `communityid` VARCHAR(64) NOT NULL , `karma` INT(11) NULL , PRIMARY KEY (`id`), UNIQUE (`communityid`)) ENGINE = InnoDB;");
	else if (StrEqual(driver, "sqlite", false))
		Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `ttt` (`communityid` VARCHAR(64) NOT NULL DEFAULT '', `karma` INT NOT NULL DEFAULT 0, PRIMARY KEY (`communityid`))");

	SQL_TQuery(g_hDatabase, Callback_CheckAndCreateTables, sQuery);
}

public void Callback_CheckAndCreateTables(Handle owner, Handle hndl, const char[] error, any userid)
{
	if(hndl == null || strlen(error) > 0)
	{
		LogError("(SQLCallback_Create) Query failed: %s", error);
		return;
	}
}

public void Callback_Karma(Handle owner, Handle hndl, const char[] error, any userid)
{
	if(hndl == null || strlen(error) > 0)
	{
		LogError("(Callback_Karma) Query failed: %s", error);
		return;
	}
}
public void Callback_InsertPlayer(Handle owner, Handle hndl, const char[] error, any userid)
{
	if(hndl == null || strlen(error) > 0)
	{
		LogError("(Callback_InsertPlayer) Query failed: %s", error);
		return;
	}
}

stock void LoadClients()
{
	LoopValidClients(i)
		OnClientPostAdminCheck(i);
}

stock void LoadClientKarma(int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(TTT_IsClientValid(client) && !IsFakeClient(client))
	{
		char sCommunityID[64];
		
		if(!GetClientAuthId(client, AuthId_SteamID64, sCommunityID, sizeof(sCommunityID)))
			return;
		
		char sQuery[2048];
		Format(sQuery, sizeof(sQuery), "SELECT `karma` FROM `ttt` WHERE `communityid`= \"%s\"", sCommunityID);
		
		if(g_hDatabase != null)
			SQL_TQuery(g_hDatabase, SQL_OnClientPostAdminCheck, sQuery, userid);
	}
}

public void SQL_OnClientPostAdminCheck(Handle owner, Handle hndl, const char[] error, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client || !TTT_IsClientValid(client) || IsFakeClient(client))
		return;
	
	if(hndl == null || strlen(error) > 0)
	{
		LogError("(SQL_OnClientPostAdminCheck) Query failed: %s", error);
		return;
	}
	else
	{
		if (!SQL_FetchRow(hndl))
			InsertPlayer(userid);
		else
		{
			char sCommunityID[64];
			
			if(!GetClientAuthId(client, AuthId_SteamID64, sCommunityID, sizeof(sCommunityID)))
				return;
				
			int karma = SQL_FetchInt(hndl, 0);
				
			g_bKarma[client] = true;
			
			if (karma == 0)
				setKarma(client, g_iConfig[c_startKarma].IntValue);
			else
				setKarma(client, karma);
		}
	}
}

stock void InsertPlayer(int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(TTT_IsClientValid(client) && !IsFakeClient(client))
	{
		int karma = g_iConfig[c_startKarma].IntValue;
		g_iKarma[client] = karma;
		
		char sCommunityID[64];
			
		if(!GetClientAuthId(client, AuthId_SteamID64, sCommunityID, sizeof(sCommunityID)))
			return;
		
		char sQuery[2048];
		Format(sQuery, sizeof(sQuery), "INSERT INTO `ttt` (`communityid`, `karma`) VALUES (\"%s\", %d)", sCommunityID, karma);
		
		if(g_hDatabase != null)
			SQL_TQuery(g_hDatabase, Callback_InsertPlayer, sQuery, userid);
	}
}
