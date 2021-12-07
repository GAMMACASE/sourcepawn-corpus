/*
   _________________
 o Since last update
 
 * Fixed an unhandled case when a player throws a Molotov and leaves the server;
 * Fixed a bug introduced in the previous versions that disabled teleports;
 * Made the plugin compatible with other custom knife skins plugins;
   _______
 o Credits go to Exolent for the original HideNSeek mod.
   ______________
 o Special thanks to Ozzie who shared his private request CSS HNS plugin. Thanks to Oshizu for helping Ozzie.
 o Thanks to Ownkruid, TUSKEN1337 and wortexo for testing.
   _________
 o Thanks to Root, Bacardi, FrozDark, TESLA-X4, Doc-Holiday, Vladislav Dolgov and Jannik 'Peace-Maker' Hartung whose code helped me a lot.
 
*/
 
#include <sourcemod>
#include <protobuf>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

// ConVar Defines
#define PLUGIN_VERSION				"1.5.6 (BlockBuilder v2)"
#define HIDENSEEK_ENABLED			 "1"
#define COUNTDOWN_TIME				"10.0"
#define AIR_ACC					   "100"
#define ROUND_POINTS				  "3"
#define BONUS_POINTS				  "2"
#define MAXIMUM_WIN_STREAK			"5"
#define FLASHBANG_CHANCE			  "0.6"
#define MOLOTOV_CHANCE				"0.05"
#define SMOKE_CHANCE				  "0.0"
#define DECOY_CHANCE				  "0.75"
#define HE_CHANCE					 "0.0"
#define FLASHBANG_MAXIMUM_AMOUNT	  "2"
#define MOLOTOV_MAXIMUM_AMOUNT		"1"
#define SMOKE_MAXIMUM_AMOUNT		  "1"
#define DECOY_MAXIMUM_AMOUNT		  "1"
#define HE_MAXIMUM_AMOUNT			 "1"
#define COUNTDOWN_FADE				"1"
#define NO_FLASH_BLIND				"2"
#define BLOCK_JOIN_TEAM			   "1"
#define ATTACK_WHILE_FROZEN		   "0"
#define FROSTNADES					"1"
#define SELF_FREEZE				   "0"
#define FREEZE_GLOW				   "1"
#define FROSTNADES_TRAIL			  "1"
#define FREEZE_DURATION			   "3.0"
#define FREEZE_FADE				   "1"
#define FREEZE_RADIUS				 "175.0"
#define DETONATION_RING			   "1"
#define BLOCK_CONSOLE_KILL			"1"
#define SUICIDE_POINTS_PENALTY		"3"
#define MOLOTOV_FRIENDLY_FIRE		 "0"

// Fade Defines
#define FFADE_IN			   0x0001
#define FFADE_OUT			  0x0002
#define FFADE_MODULATE		 0x0004
#define FFADE_STAYOUT		  0x0008
#define FFADE_PURGE			0x0010
#define COUNTDOWN_COLOR		{0,0,0,232}
#define FROST_COLOR			{20,63,255,255}
#define FREEZE_COLOR		   {20,63,255,167}

// In-game Team Defines
#define JOINTEAM_RND	   0
#define JOINTEAM_SPEC	  1	
#define JOINTEAM_T		 2
#define JOINTEAM_CT		3

// Grenade Defines
#define NADE_FLASHBANG	0
#define NADE_MOLOTOV	  1
#define NADE_SMOKE		2
#define NADE_HE		   3
#define NADE_DECOY		4
#define NADE_INCENDIARY   5

// Freeze Type Defines
#define COUNTDOWN	0
#define FROSTNADE	1

// Sound Defines
#define SOUND_UNFREEZE			 "physics/glass/glass_impact_bullet4.wav"
#define SOUND_FROSTNADE_EXPLODE	"ui/freeze_cam.wav"
#define SOUND_GOGOGO			   "player\vo\fbihrt\radiobotgo01.wav"

public Plugin:myinfo =
{
	name = "HideNSeek",
	author = "ceLoFaN & Oshizu (BlockBuilder Version)",
	description = "CTs with only knives chase the Ts. Blockbuilder version fixes weapon pickups and such",
	version = PLUGIN_VERSION,
	url = "steamcommunity.com/id/celofan"
};
new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hCountdownTime = INVALID_HANDLE;
new Handle:g_hCountdownFade = INVALID_HANDLE;
new Handle:g_hAirAccelerate = INVALID_HANDLE;
new Handle:g_hRoundPoints = INVALID_HANDLE;
new Handle:g_hBonusPointsMultiplier = INVALID_HANDLE;
new Handle:g_hMaximumWinStreak = INVALID_HANDLE;
new Handle:g_hFlashbangChance = INVALID_HANDLE;
new Handle:g_hMolotovChance = INVALID_HANDLE;
new Handle:g_hSmokeGrenadeChance = INVALID_HANDLE;
new Handle:g_hDecoyChance = INVALID_HANDLE;
new Handle:g_hHEGrenadeChance = INVALID_HANDLE;
new Handle:g_hFlashbangMaximumAmount = INVALID_HANDLE;
new Handle:g_hMolotovMaximumAmount = INVALID_HANDLE;
new Handle:g_hSmokeGrenadeMaximumAmount = INVALID_HANDLE;
new Handle:g_hDecoyMaximumAmount = INVALID_HANDLE;
new Handle:g_hHEGrenadeMaximumAmount = INVALID_HANDLE;
new Handle:g_hFlashBlindDisable = INVALID_HANDLE;
new Handle:g_hBlockJoinTeam = INVALID_HANDLE;
new Handle:g_hFrostNades = INVALID_HANDLE;
new Handle:g_hSelfFreeze = INVALID_HANDLE;
new Handle:g_hAttackWhileFrozen = INVALID_HANDLE;
new Handle:g_hFreezeGlow = INVALID_HANDLE;
new Handle:g_hFreezeDuration = INVALID_HANDLE;
new Handle:g_hFreezeFade = INVALID_HANDLE;
new Handle:g_hFrostNadesTrail = INVALID_HANDLE;
new Handle:g_hFreezeRadius = INVALID_HANDLE;
new Handle:g_hFrostNadesDetonationRing = INVALID_HANDLE;
new Handle:g_hBlockConsoleKill = INVALID_HANDLE;
new Handle:g_hSuicidePointsPenalty = INVALID_HANDLE;
new Handle:g_hMolotovFriendlyFire = INVALID_HANDLE;

new bool:g_bEnabled;
new Float:g_fCountdownTime;
new bool:g_bCountdownFade;
new g_iAirAccelerate;
new g_iRoundPoints;
new g_iBonusPointsMultiplier;
new g_iMaximumWinStreak;
new g_iFlashBlindDisable;
new bool:g_bBlockJoinTeam;
new bool:g_bAttackWhileFrozen;
new bool:g_bFrostNades;
new bool:g_bSelfFreeze;
new Float:g_fFreezeDuration;
new bool:g_bFreezeFade;
new bool:g_bFreezeGlow;
new bool:g_bFrostNadesTrail;
new Float:g_fFreezeRadius;
new bool:g_bFrostNadesDetonationRing;
new bool:g_bBlockConsoleKill;
new g_iSuicidePointsPenalty;
new bool:g_bMolotovFriendlyFire;
new Float:g_faGrenadeChance[6] = {0.0, ...};
new g_iaGrenadeMaximumAmounts[6] = {0, ...};

//Roundstart vars	
new Float:g_fRoundStartTime;	// Records the time when the round started
new g_iInitialTerroristsCount;	// Counts the number of Ts at roundstart
new bool:g_bBombFound;			// Records if the bomb has been found
new Float:g_fCountdownOverTime;	// The time when the countdown should be over
new Handle:g_hStartCountdown = INVALID_HANDLE;
new Handle:g_hShowCountdownMessage = INVALID_HANDLE;
new g_iCountdownCount;

//Mapstart vars
new g_iTWinsInARow;	// How many rounds the terrorist won in a row
new g_iConnectedClients;	 // How many clients are currently connected
new g_iGlowSprite;
new g_iBeamSprite;
new g_iHaloSprite;

//Pluginstart vars
new Float:g_fGrenadeSpeedMultiplier;

//Realtime vars
  //frostnades
new Handle:g_haFreezeTimer[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
new bool:g_baFrozen[MAXPLAYERS + 1] = {false, ...};

  //game
new bool:g_baToggleKnife[MAXPLAYERS + 1] = {true, ...};
new g_iaInitialTeamTrack[MAXPLAYERS + 1] = {0, ...};
new g_iTerroristsDeathCount;

//Grenade consts
new const String:g_saGrenadeWeaponNames[][] = {		
	"weapon_flashbang",		
	"weapon_molotov",
	"weapon_smokegrenade",
	"weapon_hegrenade",
	"weapon_decoy",
	"weapon_incgrenade"
};
new const String:g_saGrenadeChatNames[][] = {
	"Flashbang",
	"Molotov",
	"Smoke Grenade",
	"HE Grenade",
	"Decoy Grenade",
	"Incendiary Grenade"
};
new const g_iaGrenadeOffsets[] = {15, 17, 16, 14, 18, 17};

//Add your protected ConVars here!
new const String:g_saProtectedConVars[][] = {
	"sv_airaccelerate",		// use hns_airaccelerate instead
	"mp_limitteams",
	"mp_freezetime",
	"sv_alltalk",
	"mp_playerid",
	"mp_solid_teammates",
	"mp_halftime",
	"mp_playercashawards",
	"mp_teamcashawards",
	"mp_friendlyfire",
	"ammo_grenade_limit_default",
	"ammo_grenade_limit_flashbang",
	"ammo_grenade_limit_total",
	"sv_staminajumpcost",
	"sv_staminalandcost"
};
new g_iaForcedValues[] = {
	120,	  // sv_airaccelerate
	1,		// mp_limitteams
	0,		// mp_freezetime
	1,		// sv_alltalk
	1,		// mp_playerid
	0,		// mp_solid_teammates
	0,		// mp_halftime
	0,		// mp_playercashawards
	0,		// mp_teamcashawards
	0,		// mp_friendlyfire
	9999,	 // ammo_grenade_limit_default
	9999,	 // ammo_grenade_limit_flashbang
	9999,	 // ammo_grenade_limit_total
	0,		// sv_staminajumpcost
	0,		// sv_staminalandcost
};
new Handle:g_haProtectedConvar[sizeof(g_saProtectedConVars)] = {INVALID_HANDLE, ...};

public OnPluginStart()
{
	//ConVars here
	CreateConVar("hidenseek_version", PLUGIN_VERSION, "Version of HideNSeek", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("hns_enabled", HIDENSEEK_ENABLED, "Turns the mod On/Off (0=OFF, 1=ON)", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCountdownTime = CreateConVar("hns_countdown_time", COUNTDOWN_TIME, "The countdown duration during which CTs are frozen", _, true, 0.0, true, 15.0);
	g_hCountdownFade = CreateConVar("hns_countdown_fade", COUNTDOWN_FADE, "Fades the screen for CTs during countdown (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
	g_hAirAccelerate = CreateConVar("hns_airaccelerate", AIR_ACC, "The value at which sv_airaccelerate is being kept. Set to 0 to use sv_airaccelerate instead.", _, true, 12.0);
	g_hRoundPoints = CreateConVar("hns_round_points", ROUND_POINTS, "Round points for every player in the winning team", _, true, 0.0);
	g_hBonusPointsMultiplier = CreateConVar("hns_bonus_points_multiplier", BONUS_POINTS, "Bonus points for kills (CTs) and for surviving (Ts)", _, true, 1.0, true, 3.0);
	g_hMaximumWinStreak = CreateConVar("hns_maximum_win_streak", MAXIMUM_WIN_STREAK, "The number of consecutive rounds won by T before the teams get swapped (0=DSBL)", _, true, 0.0);
	g_hFlashbangChance = CreateConVar("hns_flashbang_chance", FLASHBANG_CHANCE, "The chance of getting a Flashbang as a Terrorist", _, true, 0.0, true, 1.0);
	g_hMolotovChance = CreateConVar("hns_molotov_chance", MOLOTOV_CHANCE, "The chance of getting a Molotov as a Terrorist", _, true, 0.0, true, 1.0);
	g_hSmokeGrenadeChance = CreateConVar("hns_smoke_grenade_chance", SMOKE_CHANCE, "The chance of getting a Smoke Grenade as a Terrorist", _, true, 0.0, true, 1.0);
	g_hDecoyChance = CreateConVar("hns_decoy_chance", DECOY_CHANCE, "The chance of getting a Decoy as a Terrorist", _, true, 0.0, true, 1.0);
	g_hHEGrenadeChance = CreateConVar("hns_he_grenade_chance", HE_CHANCE, "The chance of getting a HE Grenade as a Terrorist", _, true, 0.0, true, 1.0);
	g_hFlashbangMaximumAmount = CreateConVar("hns_flashbang_maximum_amount", FLASHBANG_MAXIMUM_AMOUNT, "The maximum number of Flashbang a T can receive", _, true, 0.0, true, 10.0);
	g_hMolotovMaximumAmount = CreateConVar("hns_molotov_maximum_amount", MOLOTOV_MAXIMUM_AMOUNT, "The maximum number of Molotovs a T can receive", _, true, 0.0, true, 10.0);
	g_hSmokeGrenadeMaximumAmount = CreateConVar("hns_smoke_grenade_maximum_amount", SMOKE_MAXIMUM_AMOUNT, "The maximum number of Smoke Grenades a T can receive", _, true, 0.0, true, 10.0);
	g_hDecoyMaximumAmount = CreateConVar("hns_decoy_maximum_amount", DECOY_MAXIMUM_AMOUNT, "The maximum number of Decoy Grenades a T can receive", _, true, 0.0, true, 10.0);
	g_hHEGrenadeMaximumAmount = CreateConVar("hns_he_grenade_maximum_amount", HE_MAXIMUM_AMOUNT, "The maximum number of HE Grenades a T can receive", _, true, 0.0, true, 10.0);
	g_hFlashBlindDisable = CreateConVar("hns_flash_blind_disable", NO_FLASH_BLIND, "Removes the flashbang blind effect for Ts and Spectators (0=NONE, 1=T, 2=T&SPEC)", _, true, 0.0, true, 2.0);
	g_hBlockJoinTeam = CreateConVar("hns_block_jointeam", BLOCK_JOIN_TEAM, "Blocks the players' ability of changing teams", _, true, 0.0, true, 1.0);
	g_hFrostNades = CreateConVar("hns_frostnades", FROSTNADES, "Turns Decoys into FrostNades (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
	g_hSelfFreeze = CreateConVar("hns_self_freeze", SELF_FREEZE, "Allows players to freeze themselves (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
	g_hFreezeRadius = CreateConVar("hns_freeze_radius", FREEZE_RADIUS, "The radius in which the players can get frozen (units)", _, true, 0.0, true, 500.0);
	g_hAttackWhileFrozen = CreateConVar("hns_attack_while_frozen", ATTACK_WHILE_FROZEN, "Allows frozen players to attack (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
	g_hFreezeDuration = CreateConVar("hns_freeze_duration", FREEZE_DURATION, "Freeze duration caused by FrostNades", _, true, 0.0, true, 15.0);
	g_hFreezeFade = CreateConVar("hns_freeze_fade", FREEZE_FADE, "Fades the screen for frozen player (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
	g_hFreezeGlow = CreateConVar("hns_freeze_glow", FREEZE_GLOW, "Creates a glowing sprite around frozen players (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
	g_hFrostNadesTrail = CreateConVar("hns_frostnades_trail", FROSTNADES_TRAIL, "Leaves a trail on the FrostNades path (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
	g_hFrostNadesDetonationRing = CreateConVar("hns_frostnades_detonation_ring", DETONATION_RING, "Adds a detonation effect to FrostNades (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
	g_hBlockConsoleKill = CreateConVar("hns_block_console_kill", BLOCK_CONSOLE_KILL, "Blocks the kill command (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
	g_hSuicidePointsPenalty = CreateConVar("hns_suicide_points_penalty", SUICIDE_POINTS_PENALTY, "The amount of points players lose when dying by fall without enemy assists", _, true, 0.0);
	g_hMolotovFriendlyFire = CreateConVar("hns_molotov_friendly_fire", MOLOTOV_FRIENDLY_FIRE, "Allows molotov friendly fire (0=DSBL, 1=ENBL)", _, true, 0.0, true, 1.0);
	// Remember to add HOOKS to OnCvarChange and modify OnConfigsExecuted

	//Enforce some server ConVars
	for(new i = 0; i < sizeof(g_saProtectedConVars); i++)
	{
		g_haProtectedConvar[i] = FindConVar(g_saProtectedConVars[i]);
		SetConVarInt(g_haProtectedConvar[i], g_iaForcedValues[i], true);
		HookConVarChange(g_haProtectedConvar[i], OnCvarChange);
	}
	HookConVarChange(g_hAirAccelerate, OnCvarChange);	// hns_airaccelerate -> sv_airaccelerate
	HookConVarChange(g_hEnabled, OnCvarChange);
	HookConVarChange(g_hCountdownTime, OnCvarChange);
	HookConVarChange(g_hCountdownFade, OnCvarChange);
	HookConVarChange(g_hRoundPoints, OnCvarChange);
	HookConVarChange(g_hBonusPointsMultiplier, OnCvarChange);
	HookConVarChange(g_hMaximumWinStreak, OnCvarChange);
	HookConVarChange(g_hFlashbangChance, OnCvarChange);
	HookConVarChange(g_hMolotovChance, OnCvarChange);
	HookConVarChange(g_hSmokeGrenadeChance, OnCvarChange);
	HookConVarChange(g_hDecoyChance, OnCvarChange);
	HookConVarChange(g_hHEGrenadeChance, OnCvarChange);
	HookConVarChange(g_hFlashbangMaximumAmount, OnCvarChange);
	HookConVarChange(g_hMolotovMaximumAmount, OnCvarChange);
	HookConVarChange(g_hSmokeGrenadeMaximumAmount, OnCvarChange);
	HookConVarChange(g_hDecoyMaximumAmount, OnCvarChange);
	HookConVarChange(g_hHEGrenadeMaximumAmount, OnCvarChange);
	HookConVarChange(g_hFlashBlindDisable, OnCvarChange);
	HookConVarChange(g_hBlockJoinTeam, OnCvarChange);
	HookConVarChange(g_hFrostNades, OnCvarChange);
	HookConVarChange(g_hSelfFreeze, OnCvarChange);
	HookConVarChange(g_hAttackWhileFrozen, OnCvarChange);
	HookConVarChange(g_hFreezeDuration, OnCvarChange);
	HookConVarChange(g_hFreezeFade, OnCvarChange);
	HookConVarChange(g_hFreezeGlow, OnCvarChange);
	HookConVarChange(g_hFrostNadesTrail, OnCvarChange);
	HookConVarChange(g_hFreezeRadius, OnCvarChange);
	HookConVarChange(g_hFrostNadesDetonationRing, OnCvarChange);
	HookConVarChange(g_hBlockConsoleKill, OnCvarChange);
	HookConVarChange(g_hSuicidePointsPenalty, OnCvarChange);
	HookConVarChange(g_hMolotovFriendlyFire, OnCvarChange);
	
	//Hooked'em
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("item_pickup", OnItemPickUp);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_blind", OnPlayerFlash, EventHookMode_Pre);
	HookEvent("weapon_fire", OnWeaponFire, EventHookMode_Pre);
	
	AddCommandListener(Command_JoinTeam, "jointeam");
	AddCommandListener(Command_Kill, "kill");
	
	g_fGrenadeSpeedMultiplier = 250.0 / 245.0;
	g_bEnabled = true;
	
	RegConsoleCmd("toggleknife", Command_ToggleKnife);
	AutoExecConfig(true, "hidenseek");
	
	ServerCommand("mp_backup_round_file \"\"");
	ServerCommand("mp_backup_round_file_last \"\"");
	ServerCommand("mp_backup_round_file_pattern \"\"");
	ServerCommand("mp_backup_round_auto 0");
}

public OnConfigsExecuted()
{
	g_bEnabled = GetConVarBool(g_hEnabled);
	g_fCountdownTime = GetConVarFloat(g_hCountdownTime);
	g_bCountdownFade = GetConVarBool(g_hCountdownFade);
	g_iAirAccelerate = GetConVarInt(g_hAirAccelerate);
	if(g_iAirAccelerate) {
		for(new i = 0; i < sizeof(g_saProtectedConVars); i++) {
			if(StrEqual(g_saProtectedConVars[i], "sv_airaccelerate")) {
				g_iaForcedValues[i] = g_iAirAccelerate;
				SetConVarInt(FindConVar("sv_airaccelerate"), g_iAirAccelerate);	//why even try to change
			}
		}
	}
	g_iRoundPoints = GetConVarInt(g_hRoundPoints);
	g_iBonusPointsMultiplier = GetConVarInt(g_hBonusPointsMultiplier);
	g_iMaximumWinStreak = GetConVarInt(g_hMaximumWinStreak);
	
	g_faGrenadeChance[NADE_FLASHBANG] = GetConVarFloat(g_hFlashbangChance);
	g_faGrenadeChance[NADE_MOLOTOV] = GetConVarFloat(g_hMolotovChance);
	g_faGrenadeChance[NADE_SMOKE] = GetConVarFloat(g_hSmokeGrenadeChance);
	g_faGrenadeChance[NADE_DECOY] = GetConVarFloat(g_hDecoyChance);
	g_faGrenadeChance[NADE_HE] = GetConVarFloat(g_hHEGrenadeChance);
	g_iaGrenadeMaximumAmounts[NADE_FLASHBANG] = GetConVarInt(g_hFlashbangMaximumAmount);
	g_iaGrenadeMaximumAmounts[NADE_MOLOTOV] = GetConVarInt(g_hMolotovMaximumAmount);
	g_iaGrenadeMaximumAmounts[NADE_SMOKE] = GetConVarInt(g_hSmokeGrenadeMaximumAmount);
	g_iaGrenadeMaximumAmounts[NADE_DECOY] = GetConVarInt(g_hDecoyMaximumAmount);
	g_iaGrenadeMaximumAmounts[NADE_HE] = GetConVarInt(g_hHEGrenadeMaximumAmount);
	
	g_iFlashBlindDisable = GetConVarInt(g_hFlashBlindDisable);
	g_bBlockJoinTeam = GetConVarBool(g_hBlockJoinTeam);
	g_bFrostNades = GetConVarBool(g_hFrostNades);
	g_bSelfFreeze = GetConVarBool(g_hSelfFreeze);
	g_fFreezeRadius = GetConVarFloat(g_hFreezeRadius);
	g_bAttackWhileFrozen = GetConVarBool(g_hAttackWhileFrozen);
	g_fFreezeDuration = GetConVarFloat(g_hFreezeDuration);
	g_bFreezeFade = GetConVarBool(g_hFreezeFade);
	g_bFreezeGlow = GetConVarBool(g_hFreezeGlow);
	g_bFrostNadesDetonationRing = GetConVarBool(g_hFrostNadesDetonationRing);
	g_bFrostNadesTrail = GetConVarBool(g_hFrostNadesTrail);
	g_bBlockConsoleKill = GetConVarBool(g_hBlockConsoleKill);
	g_iSuicidePointsPenalty = GetConVarInt(g_hSuicidePointsPenalty);
	g_bMolotovFriendlyFire = GetConVarBool(g_hMolotovFriendlyFire);
}

public OnMapStart()
{
	//Precaches
	g_iGlowSprite = PrecacheModel("sprites/blueglow1.vmt");
	g_iBeamSprite = PrecacheModel("materials/sprites/physbeam.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/halo.vmt");
	PrecacheSound(SOUND_UNFREEZE);
	PrecacheSound(SOUND_FROSTNADE_EXPLODE);
	PrecacheSound(SOUND_GOGOGO);
	
	g_fCountdownOverTime = 0.0;
	
	if(g_bEnabled) {
		SetConVarInt(FindConVar("mp_autoteambalance"), 1);	// Not enforced
		SetConVarInt(FindConVar("sv_gravity"), 800);		// Not enforced
	
		g_iTWinsInARow = 0;
		g_iConnectedClients = 0;
	
		CreateHostageRescue();	// Make sure T wins when the time runs out
		RemoveBombsites();
	}
}

public OnMapEnd() 
{
	for(new iClient = 1; iClient <= MaxClients; iClient++) {
		if(g_haFreezeTimer[iClient] != INVALID_HANDLE) {
			KillTimer(g_haFreezeTimer[iClient]);
			g_haFreezeTimer[iClient] = INVALID_HANDLE;
		}
	}
}

public Action:Spawn(entity)
{
	return Plugin_Handled;
}

public Action:OnRoundStart(Handle:hEvent, const String:sName[], bool:dontBroadcast)
{
	if(!g_bEnabled)
		return Plugin_Continue;
		
	g_bBombFound = false;
	
	new Float:fFraction = g_fCountdownTime - RoundToFloor(g_fCountdownTime);
	g_fRoundStartTime = GetGameTime();
	g_fCountdownOverTime = g_fRoundStartTime + g_fCountdownTime + 0.1;
	
	g_iTerroristsDeathCount = 0;
	g_iInitialTerroristsCount = GetTeamClientCount(CS_TEAM_T);

	RemoveHostages();  
	CreateHostageRescue();	// Make sure T wins when the time runs out
	RemoveBombsites();
	
	if(g_fCountdownTime > 0.0 && (g_fCountdownOverTime - GetGameTime() + 0.1) < g_fCountdownTime + 1.0) {
		if(g_hStartCountdown != INVALID_HANDLE)
			KillTimer(g_hStartCountdown);
		g_hStartCountdown = CreateTimer(fFraction, StartCountdown);
	}
//	for(new i = 1; i <= MaxClients; i++)
//	{
//		if(IsClientInGame(i) && IsPlayerAlive(i))
//		{
//			for(new ie = 0; ie < 2; ie++)
//				RemoveWeaponBySlot(i, ie);
//		}
//	}
	return Plugin_Continue;
}

public Action:StartCountdown(Handle:hTimer)
{
	g_hStartCountdown = INVALID_HANDLE;
	for(new iClient = 1; iClient < MaxClients; iClient++) {
		CreateTimer(0.1, FirstCountdownMessage, iClient);
	}
	if(g_hShowCountdownMessage != INVALID_HANDLE) {
		KillTimer(g_hShowCountdownMessage);
		g_iCountdownCount = 0;
	}
	g_iCountdownCount = 0;
	g_hShowCountdownMessage = CreateTimer(1.0, ShowCountdownMessage, _, TIMER_REPEAT);
}

public Action:FirstCountdownMessage(Handle:hTimer, any:iClient)
{
	new iCountdownTimeFloor = RoundToFloor(g_fCountdownTime);
	if(IsClientInGame(iClient))
		PrintHintText(iClient, "\n  The round will start in %d second%s.", iCountdownTimeFloor, (iCountdownTimeFloor == 1) ? "" : "s");
}

public Action:ShowCountdownMessage(Handle:hTimer)
{
	new iCountdownTimeFloor = RoundToFloor(g_fCountdownTime);
	g_iCountdownCount++;
	if(g_iCountdownCount < g_fCountdownTime) {
		for(new iClient = 1; iClient < MaxClients; iClient++) {
			if(IsClientInGame(iClient)) {
				new iTimeDelta = iCountdownTimeFloor - g_iCountdownCount;
				PrintHintText(iClient, "\n  The round will start in %d second%s.", iTimeDelta, (iTimeDelta == 1) ? "" : "s");
			}
		}
		return Plugin_Continue;
	}
	else {
		g_iCountdownCount = 0;
		g_iInitialTerroristsCount = GetTeamClientCount(CS_TEAM_T);
		for(new iClient = 1; iClient < MaxClients; iClient++) {
			if(IsClientInGame(iClient))
				PrintHintText(iClient, "\n  The round has started.");
		}
		//EmitSoundToAll(SOUND_GOGOGO);
		g_hShowCountdownMessage = INVALID_HANDLE;
		return Plugin_Stop;
	}
}

public OnWeaponFire(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iWeapon = GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon"); 
	if(IsValidEntity(iWeapon)) {
		decl String:sWeaponName[64];
		GetEntityClassname(iWeapon, sWeaponName, sizeof(sWeaponName));
		if(IsWeaponGrenade(sWeaponName)) {
			new i;
			for(i = 0; i < sizeof(g_saGrenadeWeaponNames) && !StrEqual(sWeaponName, g_saGrenadeWeaponNames[i]); i++) {}
			new iCount = GetEntProp(iClient, Prop_Send, "m_iAmmo", _, g_iaGrenadeOffsets[i]) - 1;
			new Handle:hPack;
			CreateDataTimer(0.2, SwapToNade, hPack);
			WritePackCell(hPack, iClient);
			WritePackCell(hPack, iWeapon);
			WritePackCell(hPack, iCount);
		}
	}
}

public Action:SwapToNade(Handle:hTimer, Handle:hPack)
{
	ResetPack(hPack);
	new iClient = ReadPackCell(hPack);
	new iWeaponThrown = ReadPackCell(hPack);
	new count = ReadPackCell(hPack);
	if(!IsClientInGame(iClient))
		return Plugin_Continue;
	new iWeaponTemp = -1;
	if(!count) {
		if(IsValidEntity(iWeaponThrown)) {
			RemovePlayerItem(iClient, iWeaponThrown);
			RemoveEdict(iWeaponThrown);
		}
		iWeaponTemp = GetPlayerWeaponSlot(iClient, 3);
	}
	if(iWeaponThrown == iWeaponTemp)
		return Plugin_Continue; //won't even get here but eh, you nevah know
	if(count)
		iWeaponTemp = iWeaponThrown;
	if(!IsValidEntity(iWeaponTemp))
		return Plugin_Continue;
	decl String:weapon_name[64];
	GetEntityClassname(iWeaponTemp, weapon_name, sizeof(weapon_name));
	new i;
	for(i = 0; i < sizeof(g_saGrenadeWeaponNames) && !StrEqual(weapon_name, g_saGrenadeWeaponNames[i]); i++) {}
	SetEntProp(iClient, Prop_Send, "m_iAmmo", GetEntProp(iClient, Prop_Send, "m_iAmmo", _, g_iaGrenadeOffsets[i]) - 1, _, g_iaGrenadeOffsets[i]);
	RemovePlayerItem(iClient, iWeaponTemp);
	RemoveEdict(iWeaponTemp);
	iWeaponTemp = GivePlayerItem(iClient, weapon_name);
	SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeaponTemp);
	SetEntPropFloat(iWeaponTemp, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1.1);
	SetEntPropFloat(iWeaponTemp, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 1.1);
	return Plugin_Continue;
}

public Action:Command_ToggleKnife(iClient, args)
{
	if(iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient)) {
		g_baToggleKnife[iClient] = !g_baToggleKnife[iClient];
		PrintToChat(iClient, "  \x04[HNS] Your knife is now %s.", g_baToggleKnife[iClient] ? "visible" : "invisible");
		
		new iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		if(!IsValidEntity(iWeapon))
			return Plugin_Handled;
		decl String:sWeaponName[64];
		GetEntityClassname(iWeapon, sWeaponName, sizeof(sWeaponName));
		if(IsWeaponKnife(sWeaponName))
			SetViewmodelVisibility(iClient, g_baToggleKnife[iClient]);
	}
	return Plugin_Handled;
}

public SetViewmodelVisibility(iClient, bool:bVisible)
{
	if(bVisible)
		SetEntProp(iClient, Prop_Send, "m_bDrawViewmodel", bVisible);
	else
		SetEntProp(iClient, Prop_Send, "m_bDrawViewmodel", bVisible);

}

public OnEntityCreated(iEntity, const String:sClassName[])
{
	if(g_bEnabled) {	
		if(g_bFrostNades) {
			if(StrEqual(sClassName, "decoy_projectile")) 
			{
				SDKHook(iEntity, SDKHook_StartTouch, StartTouch_Decoy);
				SDKHook(iEntity, SDKHook_SpawnPost, SpawnPost_Decoy);

				if(g_bFrostNadesTrail)
					CreateBeamFollow(iEntity, g_iBeamSprite, FROST_COLOR);
			}
			else if(StrEqual(sClassName, "func_buyzone"))
			{
				SDKHook(iEntity, SDKHook_Spawn, Spawn)
			}
		}
	}
} 

public Action:StartTouch_Decoy(iEntity)
{
	if(!g_bEnabled || !g_bFrostNades)
		return Plugin_Continue;
	SetEntProp(iEntity, Prop_Data, "m_nNextThinkTick", -1);

	new iRef = EntIndexToEntRef(iEntity);
	CreateTimer(1.0, DecoyDetonate, iRef);
	return Plugin_Continue;
}

public Action:SpawnPost_Decoy(iEntity)
{
	if(!g_bEnabled || !g_bFrostNades)
		return Plugin_Continue;
	SetEntProp(iEntity, Prop_Data, "m_nNextThinkTick", -1);
	SetEntityRenderColor(iEntity, 20, 200, 255, 255);
	
	new iRef = EntIndexToEntRef(iEntity);
	CreateTimer(1.5, DecoyDetonate, iRef);
	CreateTimer(0.5, Redo_Tick, iRef);
	CreateTimer(1.0, Redo_Tick, iRef);
	CreateTimer(1.5, Redo_Tick, iRef);
	return Plugin_Continue;
}

public Action:Redo_Tick(Handle:hTimer, any:iRef)
{
	new iEntity = EntRefToEntIndex(iRef);
	if(iEntity != INVALID_ENT_REFERENCE)
		SetEntProp(iEntity, Prop_Data, "m_nNextThinkTick", -1);
}

public Action:DecoyDetonate(Handle:hTimer, any:iRef)
{
	new iEntity = EntRefToEntIndex(iRef);
	if(iEntity != INVALID_ENT_REFERENCE) {
		new Float:faDecoyCoord[3];
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", faDecoyCoord);
		EmitAmbientSound(SOUND_FROSTNADE_EXPLODE, faDecoyCoord, iEntity, SNDLEVEL_NORMAL);
		//faDecoyCoord[2] += 32.0;
		new iThrower = GetEntPropEnt(iEntity, Prop_Send, "m_hThrower");
		AcceptEntityInput(iEntity, "Kill");
		new ThrowerTeam = GetClientTeam(iThrower);
		
		for(new iClient = 1; iClient <= MaxClients; iClient++) {
			if(iThrower && IsClientInGame(iClient)) {
				if(IsPlayerAlive(iClient) && ((GetClientTeam(iClient) != ThrowerTeam) || 
				(g_bSelfFreeze && iClient == iThrower))) {
					new Float:targetCoord[3];
					GetClientAbsOrigin(iClient, targetCoord);
					if (GetVectorDistance(faDecoyCoord, targetCoord) <= g_fFreezeRadius)
						Freeze(iClient, g_fFreezeDuration, FROSTNADE, iThrower);
				}
			}
		}
		if(g_bFrostNadesDetonationRing) {
			TE_SetupBeamRingPoint(faDecoyCoord, 10.0, g_fFreezeRadius * 2, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.3, 8.0, 0.0, FROST_COLOR, 10, 0);
			TE_SendToAll();
		}
	}
}

public OnClientConnected(iClient)
{
	g_iConnectedClients++;
	g_iaInitialTeamTrack[iClient] = 0;
}

public OnClientDisconnect(iClient)
{
	g_iConnectedClients--;
	SDKUnhook(iClient, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	SDKUnhook(iClient, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKUnhook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
	if(g_baFrozen[iClient]) {
		if(g_haFreezeTimer[iClient] != INVALID_HANDLE) {
			KillTimer(g_haFreezeTimer[iClient])
			g_haFreezeTimer[iClient] = INVALID_HANDLE;
		}
		g_baFrozen[iClient] = false;
	}
	g_baToggleKnife[iClient] = true;
}

public Action:OnWeaponCanUse(iClient, iWeapon)
{
	if(!g_bEnabled)
		return Plugin_Continue;
	decl String:sWeaponName[64];
	GetEntityClassname(iWeapon, sWeaponName, sizeof(sWeaponName));
	if(GetClientTeam(iClient) == CS_TEAM_T)
	{
		return Plugin_Continue;
	}
	else if(StrEqual(sWeaponName, "weapon_deagle") || StrEqual(sWeaponName, "weapon_awp"))
	{
		return Plugin_Continue;
	}
	else if(GetClientTeam(iClient) == CS_TEAM_CT && IsWeaponGrenade(sWeaponName))
	{
		return Plugin_Handled;
	} 
	return Plugin_Continue;
}

public OnCvarChange(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
{
	decl String:sConVarName[64];
	GetConVarName(hConVar, sConVarName, sizeof(sConVarName));

	if(StrEqual("hns_enabled", sConVarName))
		g_bEnabled = GetConVarBool(hConVar); else
	if(StrEqual("hns_countdown_time", sConVarName))
		g_fCountdownTime = StringToFloat(sNewValue); else
	if(StrEqual("hns_countdown_fade", sConVarName))
		g_bCountdownFade = GetConVarBool(hConVar); else
	if(StrEqual("hns_round_points", sConVarName))
		g_iRoundPoints = StringToInt(sNewValue); else
	if(StrEqual("hns_bonus_points_multiplier", sConVarName))
		g_iBonusPointsMultiplier = StringToInt(sNewValue); else
	if(StrEqual("hns_maximum_win_streak", sConVarName))
		g_iMaximumWinStreak = StringToInt(sNewValue); else
	if(StrEqual("hns_flashbang_chance", sConVarName))
		g_faGrenadeChance[NADE_FLASHBANG] = StringToFloat(sNewValue); else
	if(StrEqual("hns_molotov_chance", sConVarName))
		g_faGrenadeChance[NADE_MOLOTOV] = StringToFloat(sNewValue); else
	if(StrEqual("hns_smoke_grenade_chance", sConVarName))
		g_faGrenadeChance[NADE_SMOKE] = StringToFloat(sNewValue); else
	if(StrEqual("hns_decoy_chance", sConVarName))
		g_faGrenadeChance[NADE_DECOY] = StringToFloat(sNewValue); else
	if(StrEqual("hns_he_grenade_chance", sConVarName))
		g_faGrenadeChance[NADE_HE] = StringToFloat(sNewValue); else
	if(StrEqual("hns_flashbang_maximum_amount", sConVarName))
		g_iaGrenadeMaximumAmounts[NADE_FLASHBANG] = StringToInt(sNewValue); else
	if(StrEqual("hns_molotov_maximum_amount", sConVarName))
		g_iaGrenadeMaximumAmounts[NADE_MOLOTOV] = StringToInt(sNewValue); else
	if(StrEqual("hns_smoke_grenade_maximum_amount", sConVarName))
		g_iaGrenadeMaximumAmounts[NADE_SMOKE] = StringToInt(sNewValue); else
	if(StrEqual("hns_decoy_maximum_amount", sConVarName))
		g_iaGrenadeMaximumAmounts[NADE_DECOY] = StringToInt(sNewValue); else
	if(StrEqual("hns_he_grenade_maximum_amount", sConVarName))
		g_iaGrenadeMaximumAmounts[NADE_HE] = StringToInt(sNewValue); else
	if(StrEqual("hns_flash_blind_disable", sConVarName))
		g_iFlashBlindDisable = StringToInt(sNewValue); else
	if(StrEqual("hns_attack_while_frozen", sConVarName))
		g_bAttackWhileFrozen = GetConVarBool(hConVar); else
	if(StrEqual("hns_frostnades", sConVarName))
		g_bFrostNades = GetConVarBool(hConVar); else
	if(StrEqual("hns_self_freeze", sConVarName))
		g_bSelfFreeze = GetConVarBool(hConVar); else
	if(StrEqual("hns_freeze_glow", sConVarName))
		g_bFreezeGlow = GetConVarBool(hConVar); else
	if(StrEqual("hns_freeze_duration", sConVarName))
		g_fFreezeDuration = StringToFloat(sNewValue); else
	if(StrEqual("hns_freeze_fade", sConVarName))
		g_bFreezeFade = GetConVarBool(hConVar); else
	if(StrEqual("hns_frostnades_trail", sConVarName))
		g_bFrostNadesTrail = GetConVarBool(hConVar); else
	if(StrEqual("hns_freeze_radius", sConVarName))
		g_fFreezeRadius = StringToFloat(sNewValue); else
	if(StrEqual("hns_frostnades_detonation_ring", sConVarName))
		g_bFrostNadesDetonationRing = GetConVarBool(hConVar); else
	if(StrEqual("hns_block_console_kill", sConVarName))
		g_bBlockConsoleKill = GetConVarBool(g_hBlockConsoleKill); else
	if(StrEqual("hns_suicide_points_penalty", sConVarName))
		g_iSuicidePointsPenalty = StringToInt(sNewValue); else
	if(StrEqual("hns_molotov_friendly_fire", sConVarName))
		g_bMolotovFriendlyFire = GetConVarBool(g_hBlockConsoleKill); else
	if(StrEqual("hns_airaccelerate", sConVarName)) {
		g_iAirAccelerate = StringToInt(sNewValue);
		if(g_iAirAccelerate) {
			for(new i = 0; i < sizeof(g_saProtectedConVars); i++) {
				if(StrEqual(g_saProtectedConVars[i], "sv_airaccelerate")) {
					g_iaForcedValues[i] = g_iAirAccelerate;
					SetConVarInt(FindConVar("sv_airaccelerate"), g_iAirAccelerate);	//why even try to change
				}
			}
		}
	}
	else {
		if(!(StrEqual("sv_airaccelerate", sConVarName) && !g_iAirAccelerate)) {
			for(new i = 0; i < sizeof(g_saProtectedConVars); i++) {
				if(StrEqual(g_saProtectedConVars[i], sConVarName) && StringToInt(sNewValue) != g_iaForcedValues[i]) {
					SetConVarInt(hConVar, g_iaForcedValues[i]);
					PrintToServer("  \x04[HNS] %s is a protected CVAR.", sConVarName);
				}
			}
		}
	}
}

public Action:OnPlayerSpawn(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	if(!g_bEnabled)
		return Plugin_Continue;
	new iId = GetEventInt(hEvent, "userid");

	CreateTimer(0.1, OnPlayerSpawnDelay, iId);
		
	return Plugin_Continue;
}

public Action:OnPlayerSpawnDelay(Handle:hTimer, any:iId)
{
	new iClient = GetClientOfUserId(iId);
	if(iClient == 0 || iClient > MaxClients)
		return Plugin_Continue;
		
	if(IsClientInGame(iClient) && IsPlayerAlive(iClient)) {
		new Float:fDefreezeTime = g_fCountdownOverTime - GetGameTime() + 0.1;

		SetEntProp(iClient, Prop_Send, "m_iAccount", 0);	//Set spawn money to 0$
		RemoveNades(iClient);

		for(new ie = 0; ie < 2; ie++)
			RemoveWeaponBySlot(iClient, ie);
		
		new iEntity = GetPlayerWeaponSlot(iClient, 2);
		if(IsValidEdict(iEntity)) {
			new String:sWeaponName[64]
			GetEntityClassname(iEntity, sWeaponName, sizeof(sWeaponName));
			RemovePlayerItem(iClient, iEntity);
			AcceptEntityInput(iEntity, "Kill");
			GivePlayerItem(iClient, sWeaponName);
		}
		else 
			GivePlayerItem(iClient, "weapon_knife");		//prevents a visual bug
			
		SetViewmodelVisibility(iClient, g_baToggleKnife[iClient]);  //might fix a game bug
				
		if(g_baFrozen[iClient])
			SilentUnfreeze(iClient);
		new iWeapon = GetPlayerWeaponSlot(iClient, 2);
		new iTeam = GetClientTeam(iClient);
		if(iTeam == CS_TEAM_T) {
			GiveGrenades(iClient);
			if(IsValidEntity(iWeapon)) {
				SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 9001.0);	 //change the firerate so we don't have weird clientside animations going on
				SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 9001.0);
			}
		}
		if((iTeam == CS_TEAM_CT)) {
			if(g_fCountdownTime > 0.0 && fDefreezeTime > 0.0 && (fDefreezeTime < g_fCountdownTime + 1.0)) {
				if(g_iConnectedClients > 1)
					Freeze(iClient, fDefreezeTime, COUNTDOWN);
			}
			else if(GetEntityMoveType(iClient) == MOVETYPE_NONE) {
				SetEntityMoveType(iClient, MOVETYPE_WALK);
			}
		}	
	}
	return Plugin_Continue;
}

public OnClientPutInServer(iClient)
{
	SDKHook(iClient, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
	SDKHook(iClient, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:Command_JoinTeam(iClient, const String:sCommand[], iArgCount)
{
	if(!g_bEnabled)
		return Plugin_Continue;
	if(!g_bBlockJoinTeam || iClient == 0 || iClient > MaxClients)
		return Plugin_Continue;
	new iTeam = GetClientTeam(iClient);
	decl String:sChosenTeam[2];
	GetCmdArg(1, sChosenTeam, sizeof(sChosenTeam));
	new iChosenTeam = StringToInt(sChosenTeam);
	
	new iLimitTeams = GetConVarInt(FindConVar("mp_limitteams"));
	new iDelta = GetTeamPlayerCount(CS_TEAM_T) - GetTeamPlayerCount(CS_TEAM_CT);
	if(iTeam == CS_TEAM_T || iTeam == CS_TEAM_CT) {
		if(iChosenTeam == JOINTEAM_T || iChosenTeam == JOINTEAM_CT || iChosenTeam == JOINTEAM_RND) {
			if(IsPlayerAlive(iClient)) {
				PrintToChat(iClient, "  \x04[HNS] You are not allowed to change teams while you're alive.");
				return Plugin_Stop;
			}
			else if(iDelta > iLimitTeams || -iDelta > iLimitTeams) {
				g_iaInitialTeamTrack[iClient] = iChosenTeam;
				return Plugin_Continue;
			}
			else {
				PrintToChat(iClient, "  \x04[HNS] You are not allowed to change teams while they're balanced.");
				return Plugin_Stop;
			}
		}
		else if(iChosenTeam == JOINTEAM_SPEC) {
			if(IsPlayerAlive(iClient)) {
				PrintToConsole(iClient, "  \x04[HNS] You are not allowed to go spectating while you're alive.");
				return Plugin_Stop;
			}
			else {
				g_iaInitialTeamTrack[iClient] = iTeam;
				SilentUnfreeze(iClient);
				return Plugin_Continue;
			}
		}
		else {
			PrintToConsole(iClient, "  \x04[HNS] You are trying to join an invalid team.");
			return Plugin_Stop;
		}
	}
	else if(iTeam == CS_TEAM_SPECTATOR) {
		if(iDelta > iLimitTeams || -iDelta > iLimitTeams) {
			g_iaInitialTeamTrack[iClient] = iChosenTeam;
			return Plugin_Continue;
		}
		else if(g_iaInitialTeamTrack[iClient]) {
			PrintToChat(iClient, "  \x04[HNS] You have been assigned to team %s", (g_iaInitialTeamTrack[iClient] == CS_TEAM_T) ? "T" : "CT");
			CS_SwitchTeam(iClient, g_iaInitialTeamTrack[iClient]);
			return Plugin_Stop;
		}
		else
			return Plugin_Continue;
	}
	SilentUnfreeze(iClient);
	return Plugin_Continue;
}

public Action:Command_Kill(iClient, const String:sCommand[], iArgCount)
{
	if(!g_bEnabled)
		return Plugin_Continue;
	if (!g_bBlockConsoleKill || iClient == 0 || iClient > MaxClients)
		return Plugin_Continue;
	PrintToConsole(iClient, "  \x04[HNS] You are not allowed to use the kill command.");
	return Plugin_Stop;
}

public Action:OnItemPickUp(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if(!g_bEnabled)
		return Plugin_Continue;
	decl String:sItem[64];
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	GetEventString(hEvent, "item", sItem, sizeof(sItem));
	if(!g_bBombFound)
		if(StrEqual(sItem, "weapon_c4", false)) {
			RemovePlayerItem(iClient, GetPlayerWeaponSlot(iClient, 4));	//Remove the bomb
			g_bBombFound = true;
			return Plugin_Continue;
		}
//	for(new i = 0; i < 2; i++)
//		RemoveWeaponBySlot(iClient, i);
	return Plugin_Continue;
}

public OnWeaponSwitchPost(iClient, iWeapon)
{
	if(g_bEnabled) {
		decl String:sWeaponName[64];
		GetEntityClassname(iWeapon, sWeaponName, sizeof(sWeaponName));
		if(IsWeaponGrenade(sWeaponName)) {
			SetClientSpeed(iClient, g_fGrenadeSpeedMultiplier);
			SetViewmodelVisibility(iClient, true);
		}
		else {
			SetClientSpeed(iClient, 1.0);
			if(IsWeaponKnife(sWeaponName))
				SetViewmodelVisibility(iClient, g_baToggleKnife[iClient]); 
		}
		
		new Float:fCurrentTime = GetGameTime();
		if(fCurrentTime < g_fCountdownOverTime) {
			SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", g_fCountdownOverTime);
			SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", g_fCountdownOverTime);
		}
		else if(GetClientTeam(iClient) == CS_TEAM_T && IsWeaponKnife(sWeaponName)) {
			SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", fCurrentTime + 9001.0);
			SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", fCurrentTime + 9001.0);
		}
	}
}

public Action:OnTakeDamage(iVictim, &iAttacker, &iInflictor, &Float:iDamage, &iDamageType)
{
	if(!g_bEnabled)
		return Plugin_Continue;
	if(iVictim == 0)
		return Plugin_Continue;
	else {
		if(!g_bMolotovFriendlyFire)
			if(iDamageType & DMG_BURN) {
				if(!iAttacker || iAttacker > MaxClients)
					return Plugin_Handled;
				if(!IsClientInGame(iAttacker))
					if(GetClientTeam(iVictim) == g_iaInitialTeamTrack[iAttacker])
						return Plugin_Handled;
				if(GetClientTeam(iVictim) == GetClientTeam(iAttacker))
					return Plugin_Handled;
			}
	}
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	if(!g_bEnabled)
		return Plugin_Continue;
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAssister = GetClientOfUserId(GetEventInt(hEvent, "assister"));

	if(iVictim > 0 && iVictim <= MaxClients) {
		if(GetClientTeam(iVictim) == CS_TEAM_T) {
			g_iTerroristsDeathCount++;
			if(iAttacker > 0 && iAttacker <= MaxClients) {
				if(GetClientTeam(iAttacker) == CS_TEAM_CT) {
					SetEntProp(iAttacker, Prop_Send, "m_iAccount", 0);	//Make sure the player doesn't get the money
					CS_SetClientContributionScore(iAttacker, CS_GetClientContributionScore(iAttacker) + g_iBonusPointsMultiplier - 1); 
					decl String:sNickname[MAX_NAME_LENGTH];					
					GetClientName(iVictim, sNickname, sizeof(sNickname));
					PrintToChat(iAttacker, "  \x04[HNS] You got %d points for killing %s.", g_iBonusPointsMultiplier, sNickname);
				}
			}
		}
	}
	if(g_baFrozen[iVictim])
		SilentUnfreeze(iVictim);

	if(iVictim > 0 && iVictim <= MaxClients && iAttacker == 0 && !(iAssister > 0 && iAssister <= MaxClients)) {
		SetClientFrags(iVictim, GetClientFrags(iVictim) + 1);
		if(g_iSuicidePointsPenalty) {
			CS_SetClientContributionScore(iVictim, CS_GetClientContributionScore(iVictim) - g_iSuicidePointsPenalty);
			PrintToChat(iVictim, "  \x04[HNS] You died by fall without an enemy assist. You lose %d points.", g_iSuicidePointsPenalty);
		}
	}
	return Plugin_Continue;
}

public Action:OnPlayerFlash(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	if(!g_bEnabled)
		return Plugin_Continue;
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iTeam = GetClientTeam(iClient);
	
	if(g_iFlashBlindDisable) {
		if(iTeam == CS_TEAM_T)
			SetEntPropFloat(iClient, Prop_Send, "m_flFlashMaxAlpha", 0.5);
		else
			if(g_iFlashBlindDisable == 2 && iTeam == CS_TEAM_SPECTATOR)
				SetEntPropFloat(iClient, Prop_Send, "m_flFlashMaxAlpha", 0.5);
	}
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:faVelocity[3], Float:faAngles[3], &iWeapon)
{
	if(!g_bEnabled)
		return Plugin_Continue;
	
	if(!g_bAttackWhileFrozen && g_baFrozen[iClient]) {
		iButtons &= ~(IN_ATTACK | IN_ATTACK2);
		return Plugin_Changed;
	}
	
	new Float:fCurrentTime = GetGameTime();
	if(GetClientTeam(iClient) == CS_TEAM_T) {
		if (iButtons & (IN_ATTACK | IN_ATTACK2)) {  //this might be unnecessary
			new iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(iActiveWeapon)) {
				decl String:sWeaponName[64];
				GetEntityClassname(iActiveWeapon, sWeaponName, sizeof(sWeaponName));
				if(IsWeaponKnife(sWeaponName)) {
					SetEntPropFloat(iActiveWeapon, Prop_Send, "m_flNextPrimaryAttack", fCurrentTime + 9001.0);
					SetEntPropFloat(iActiveWeapon, Prop_Send, "m_flNextSecondaryAttack", fCurrentTime + 9001.0);
					iButtons &= ~(IN_ATTACK | IN_ATTACK2);	//Block attacks for Ts
					return Plugin_Changed;
				}
				else if(IsWeaponGrenade(sWeaponName) && fCurrentTime < g_fCountdownOverTime) {
					SetEntPropFloat(iActiveWeapon, Prop_Send, "m_flNextPrimaryAttack", g_fCountdownOverTime);
					SetEntPropFloat(iActiveWeapon, Prop_Send, "m_flNextSecondaryAttack", g_fCountdownOverTime);
					iButtons &= ~(IN_ATTACK | IN_ATTACK2);	//Block attacks for Ts
					return Plugin_Changed;
				}
			}
			else
				return Plugin_Continue;
		}
	}
	else if(GetClientTeam(iClient) == CS_TEAM_CT)
		if (iButtons & (IN_ATTACK)) {
			iButtons &= ~(IN_ATTACK);	//Block attack1 for CTs but use attack2 instead
			iButtons |= IN_ATTACK2;
			return Plugin_Changed;
		}
	return Plugin_Continue;
}

public Action:OnRoundEnd(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if(!g_bEnabled)
		return Plugin_Continue;
	new iWinningTeam = GetEventInt(hEvent, "winner");
	new iCTScore = CS_GetTeamScore(CS_TEAM_CT);
	new iPoints;
	
	if(iWinningTeam == CS_TEAM_T) {
		if(!g_iMaximumWinStreak || ++g_iTWinsInARow < g_iMaximumWinStreak)
			PrintToChatAll("  \x04[HNS] Terrorists won.");
		else {
			SwapTeams();
			g_iTWinsInARow = 0;
			//Set the team scores
			CS_SetTeamScore(CS_TEAM_CT, CS_GetTeamScore(CS_TEAM_T) + 1);
			SetTeamScore(CS_TEAM_CT, CS_GetTeamScore(CS_TEAM_T) + 1);
			CS_SetTeamScore(CS_TEAM_T, iCTScore);
			SetTeamScore(CS_TEAM_T, iCTScore);
			if(g_iMaximumWinStreak)
				PrintToChatAll("  \x04[HNS] Ts have won too many rounds in a row. Teams have been swapped.");
		}

		for(new iClient = 1; iClient < MaxClients; iClient++) {
			if(IsClientInGame(iClient))
				if(GetClientTeam(iClient) == CS_TEAM_T) {
					CS_SetClientContributionScore(iClient, CS_GetClientContributionScore(iClient) + g_iRoundPoints);
					if(IsPlayerAlive(iClient) && g_iTerroristsDeathCount) {
						new iDivider = g_iInitialTerroristsCount - g_iTerroristsDeathCount;
						if(iDivider < 1)
							iDivider = 1; //getting the actual number of terrorists would be better
						iPoints = g_iBonusPointsMultiplier * g_iTerroristsDeathCount / iDivider;			
						CS_SetClientContributionScore(iClient, CS_GetClientContributionScore(iClient) + iPoints);
						PrintToChat(iClient, "  \x04[HNS] You got %d points for surviving the round and %d points for winning.", iPoints, g_iRoundPoints);
					}
					else
						PrintToChat(iClient, "  \x04[HNS] You got %d points for winning.", g_iRoundPoints);
				}
		}
	}
	else if(iWinningTeam == CS_TEAM_CT)
	{
		for(new iClient = 1; iClient < MaxClients; iClient++) {
			if(IsClientInGame(iClient))
				if(GetClientTeam(iClient) == CS_TEAM_CT) {
					CS_SetClientContributionScore(iClient, CS_GetClientContributionScore(iClient) + g_iRoundPoints);
					PrintToChat(iClient, "  \x04[HNS] You got %d points for winning.", g_iRoundPoints);
				}
		}
		SwapTeams();
		PrintToChatAll("  \x04[HNS] Counter-Terrorists won. Teams have been swapped.");
		g_iTWinsInARow = 0;
		//Set the team scores
		CS_SetTeamScore(CS_TEAM_CT, CS_GetTeamScore(CS_TEAM_T));
		SetTeamScore(CS_TEAM_CT, CS_GetTeamScore(CS_TEAM_T));
		CS_SetTeamScore(CS_TEAM_T, iCTScore);
		SetTeamScore(CS_TEAM_T, iCTScore);
	}
	return Plugin_Continue;
}

stock RemoveNades(iClient)
{
	while(RemoveWeaponBySlot(iClient, 3)){}
	for(new i = 0; i < 6; i++)
		SetEntProp(iClient, Prop_Send, "m_iAmmo", 0, _, g_iaGrenadeOffsets[i]);
}

stock GiveGrenades(iClient)
{
	new iaReceived[6] = {0, ...};
	new iLastType = -1;
	new iFirstType = -1;
	new bool:bAtLeastTwo = false;
	for(new i = 0; i < sizeof(iaReceived); i++) {
		for(new j = 0; j < g_iaGrenadeMaximumAmounts[i]; j++)
			if(GetRandomFloat(0.0, 1.0) < g_faGrenadeChance[i])
				iaReceived[i]++;
		if(iaReceived[i]) {
			GivePlayerItem(iClient, g_saGrenadeWeaponNames[i]);
			SetEntProp(iClient, Prop_Send, "m_iAmmo", iaReceived[i], _, g_iaGrenadeOffsets[i]);
			if(iLastType != -1)
				bAtLeastTwo = true;
			if(iFirstType == -1)
				iFirstType = i;
			iLastType = i;
		}
	}

	new String:sGrenadeMessage[256];
	for(new i = 0; i < sizeof(iaReceived); i++) {
		if(iaReceived[i]) {
			if(bAtLeastTwo && i != iFirstType) {
				if(i == iLastType)
					StrCat(sGrenadeMessage, sizeof(sGrenadeMessage), " and ");
				else
					StrCat(sGrenadeMessage, sizeof(sGrenadeMessage), ", ");
			}
			decl String:sNumberTemp[5];
			IntToString(iaReceived[i], sNumberTemp, sizeof(sNumberTemp));
			StrCat(sGrenadeMessage, sizeof(sGrenadeMessage), sNumberTemp);
			StrCat(sGrenadeMessage, sizeof(sGrenadeMessage), " ");
			if(i == NADE_DECOY && g_bFrostNades)
				StrCat(sGrenadeMessage, sizeof(sGrenadeMessage), "FrostNade");
			else
				StrCat(sGrenadeMessage, sizeof(sGrenadeMessage), g_saGrenadeChatNames[i]);
			if(iaReceived[i] > 1)
				StrCat(sGrenadeMessage, sizeof(sGrenadeMessage), "s");
		}
	}
	PrintToChat(iClient, "  \x04[HNS] You have received %s.", sGrenadeMessage);

}

stock SwapTeams()
{
	for(new iClient = 1; iClient < MaxClients; iClient++) {
		if(IsClientInGame(iClient)) {
			new team = GetClientTeam(iClient);
			if(team == CS_TEAM_T)
				CS_SwitchTeam(iClient, CS_TEAM_CT);
			else if(team == CS_TEAM_CT)
				CS_SwitchTeam(iClient, CS_TEAM_T);
			if(g_iaInitialTeamTrack[iClient] == CS_TEAM_T)
				g_iaInitialTeamTrack[iClient] = CS_TEAM_CT;
			else if(g_iaInitialTeamTrack[iClient] == CS_TEAM_CT)
				g_iaInitialTeamTrack[iClient] = CS_TEAM_T;
		}
	}
}

stock ScreenFade(iClient, iFlags = FFADE_PURGE, iaColor[4] = {0, 0, 0, 0}, iDuration = 0, iHoldTime = 0)
{
	new Handle:hScreenFade = StartMessageOne("Fade", iClient);
	PbSetInt(hScreenFade, "duration", iDuration * 500);
	PbSetInt(hScreenFade, "hold_time", iHoldTime * 500);
	PbSetInt(hScreenFade, "flags", iFlags);
	PbSetColor(hScreenFade, "clr", iaColor);
	EndMessage();
}

stock bool:RemoveWeaponBySlot(iClient, iSlot)
{
	new iEntity = GetPlayerWeaponSlot(iClient, iSlot);
	if(IsValidEdict(iEntity)) {
		RemovePlayerItem(iClient, iEntity);
		AcceptEntityInput(iEntity, "Kill");
		return true;
	}
	return false;
}

stock CreateHostageRescue()
{
	new iEntity = -1;
	if((iEntity = FindEntityByClassname(iEntity, "func_hostage_rescue")) == -1) {
		new iHostageRescueEnt = CreateEntityByName("func_hostage_rescue");
		DispatchKeyValue(iHostageRescueEnt, "targetname", "fake_hostage_rescue");
		DispatchKeyValue(iHostageRescueEnt, "origin", "-3141 -5926 -5358");
		DispatchSpawn(iHostageRescueEnt);
	}
}

stock RemoveHostages()
{
	new iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "hostage_entity")) != -1)	 //Find hostages
		AcceptEntityInput(iEntity, "kill");
}

stock RemoveBombsites()
{
	new iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "func_bomb_target")) != -1)	//Find bombsites
		AcceptEntityInput(iEntity, "kill");	//Destroy the entity
}

stock bool:IsWeaponKnife(const String:sWeaponName[])
{
	return StrContains(sWeaponName, "knife", false) != -1;
}

stock bool:IsWeaponGrenade(const String:sWeaponName[])
{
	for(new i = 0; i < sizeof(g_saGrenadeWeaponNames); i++)
		if(StrEqual(g_saGrenadeWeaponNames[i], sWeaponName))
			return true;
	return false;
}

stock SetClientSpeed(iClient, Float:speed)
{
	SetEntPropFloat(iClient, Prop_Send, "m_flLaggedMovementValue", speed);
}

stock Freeze(iClient, Float:fDuration, iType, iAttacker = 0)
{
	SetEntityMoveType(iClient, MOVETYPE_NONE);
	if(!g_bAttackWhileFrozen && (GetClientTeam(iClient) == CS_TEAM_CT)) {
		new Float:defreezetime = GetGameTime() + fDuration;
		new knife = GetPlayerWeaponSlot(iClient, 2);
		if(IsValidEntity(knife)) {
			SetEntPropFloat(knife, Prop_Send, "m_flNextPrimaryAttack", defreezetime);
			SetEntPropFloat(knife, Prop_Send, "m_flNextSecondaryAttack", defreezetime);
		}
	}
	if(iType == FROSTNADE && g_bFreezeGlow) {
		new Float:coord[3];
		GetClientEyePosition(iClient, coord);
		coord[2] -= 32.0;
		CreateGlowSprite(g_iGlowSprite, coord, fDuration);
		LightCreate(coord, fDuration);
	}
	if(iAttacker == 0) {
		PrintToChat(iClient, "  \x04[HNS] You are asleep for %.1f seconds.", fDuration);
	}
	else if(iAttacker == iClient) {
		PrintToChat(iClient, "  \x04[HNS] You have frozen yourself for %.1f seconds dummy.", fDuration);
	}
	else if(iAttacker <= MaxClients) {
		if(IsClientInGame(iAttacker)) {
			decl String:sAttackerName[MAX_NAME_LENGTH];
			GetClientName(iAttacker, sAttackerName, sizeof(sAttackerName));
			PrintToChat(iClient, "  \x04[HNS] You have been frozen by %s for %.1f seconds.", sAttackerName, fDuration);
		}
	}
	if(g_baFrozen[iClient]) {
		if(g_haFreezeTimer[iClient] != INVALID_HANDLE) {
			KillTimer(g_haFreezeTimer[iClient]);
			if(iType == FROSTNADE)
				g_haFreezeTimer[iClient] = CreateTimer(fDuration, Unfreeze, iClient);
			else if(iType == COUNTDOWN)
				g_haFreezeTimer[iClient] = CreateTimer(fDuration, UnfreezeCountdown, iClient);
		}
	}
	else {
		g_baFrozen[iClient] = true;
		if(iType == FROSTNADE)
			g_haFreezeTimer[iClient] = CreateTimer(fDuration, Unfreeze, iClient);
		else if(iType == COUNTDOWN)
			g_haFreezeTimer[iClient] = CreateTimer(fDuration, UnfreezeCountdown, iClient);
	}
	if(iType == FROSTNADE && g_bFreezeFade)
		ScreenFade(iClient, FFADE_IN|FFADE_PURGE|FFADE_MODULATE, FREEZE_COLOR, 2, RoundToFloor(fDuration - 0.5));
	else if(iType == COUNTDOWN && g_bCountdownFade)
		ScreenFade(iClient, FFADE_IN|FFADE_PURGE, COUNTDOWN_COLOR, 2, RoundToFloor(fDuration));
}

public Action:Unfreeze(Handle:hTimer, any:iClient)
{
	if(iClient && IsClientInGame(iClient)) {
		if(g_baFrozen[iClient]) {
			SetEntityMoveType(iClient, MOVETYPE_WALK);
			g_baFrozen[iClient] = false;
			g_haFreezeTimer[iClient] = INVALID_HANDLE;
			new Float:faCoord[3];
			GetClientEyePosition(iClient, faCoord);
			EmitAmbientSound(SOUND_UNFREEZE, faCoord, iClient, 55);
			if(IsPlayerAlive(iClient))
				PrintToChat(iClient, "  \x04[HNS] You are free to go now.");
		}
		else
			PrintToServer("Unfreeze attempted on non frozen client %d.", iClient);
	}
	return Plugin_Continue;
}

public Action:UnfreezeCountdown(Handle:hTimer, any:iClient)
{
	if(iClient && IsClientInGame(iClient)) {
		SetEntityMoveType(iClient, MOVETYPE_WALK);
		g_baFrozen[iClient] = false;
		g_haFreezeTimer[iClient] = INVALID_HANDLE;
		if(IsPlayerAlive(iClient))
			PrintToChat(iClient, "  \x04[HNS] The round has started.");
	}
	return Plugin_Continue;
}

stock SilentUnfreeze(iClient)
{
	g_baFrozen[iClient] = false;
	SetEntityMoveType(iClient, MOVETYPE_WALK);
	if(g_haFreezeTimer[iClient] != INVALID_HANDLE) {
		KillTimer(g_haFreezeTimer[iClient]);
		g_haFreezeTimer[iClient] = INVALID_HANDLE;
	}
	ScreenFade(iClient);
}

stock CreateBeamFollow(iEntity, iSprite, iaColor[4] = {0, 0, 0, 255})
{
	TE_SetupBeamFollow(iEntity, iSprite, 0, 1.5, 3.0, 3.0, 2, iaColor);
	TE_SendToAll();
}

stock CreateGlowSprite(iSprite, const Float:faCoord[3], const Float:fDuration)
{
	TE_SetupGlowSprite(faCoord, iSprite, fDuration, 2.2, 180);
	TE_SendToAll();
}

stock LightCreate(Float:faCoord[3], Float:fDuration)   
{  
	new iEntity = CreateEntityByName("light_dynamic");
	DispatchKeyValue(iEntity, "inner_cone", "0");
	DispatchKeyValue(iEntity, "cone", "90");
	DispatchKeyValue(iEntity, "brightness", "1");
	DispatchKeyValueFloat(iEntity, "spotlight_radius", 150.0);
	DispatchKeyValue(iEntity, "pitch", "90");
	DispatchKeyValue(iEntity, "style", "1");
	DispatchKeyValue(iEntity, "_light", "20 63 255 255");
	DispatchKeyValueFloat(iEntity, "distance", 150.0);

	DispatchSpawn(iEntity);
	TeleportEntity(iEntity, faCoord, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iEntity, "TurnOn");
	CreateTimer(fDuration, DeleteEntity, iEntity, TIMER_FLAG_NO_MAPCHANGE);
}

stock SetClientFrags(iClient, iFrags)
{
	SetEntProp(iClient, Prop_Data, "m_iFrags", iFrags);
}

public Action:DeleteEntity(Handle:hTimer, any:iEntity)
{
	if(IsValidEdict(iEntity))
		AcceptEntityInput(iEntity, "kill");
}

stock GetTeamPlayerCount(iTeam)
{
	new iCount = 0;
	for(new iClient = 1; iClient <= MaxClients; iClient++)
		if(IsClientInGame(iClient))
			if(GetClientTeam(iClient) == iTeam)
				iCount++;
	return iCount;
}
