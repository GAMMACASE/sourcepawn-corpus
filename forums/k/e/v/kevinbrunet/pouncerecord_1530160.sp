/* Plugin Template generated by Pawn Studio */

#include <sourcemod>

#define PLUGIN_VERSION "1.0"
//globals
new Handle:hDb;
new Handle:hMaxPounceDamage;
//hunter position store
new Float:infectedPosition[MAXPLAYERS][3]; //support up to 32 slots on a server

public Plugin:myinfo = 
{
	name = "L4D2 PounceRecord",
	author = "kevinbrunet original n0limit",
	description = "Saves pounces from the game to a central database, and provide extended pounce statistics on players during the game.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	ConnectToDB("PounceDB");
	if(hDb == INVALID_HANDLE)
		return; //Don't setup the system if the DB is non responsive.
	
	CreateConVar("pouncerecord_version",PLUGIN_VERSION,"The current version of the plugin.",FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	
	hMaxPounceDamage = FindConVar("z_hunter_max_pounce_bonus_damage");
	
	HookEvent("lunge_pounce",Event_PlayerPounced);
	HookEvent("ability_use",Event_AbilityUse);
}

public ConnectToDB(const String:configName[])
{
	new String:errorMsg[256];
	
	if(SQL_CheckConfig(configName))
	{ //config section exists
		hDb = SQL_Connect(configName,true,errorMsg,sizeof(errorMsg));
		if(hDb == INVALID_HANDLE)
			LogError("Unable to connect to the specified host for the database configuration named %s.",configName);
	}
	else
		LogError("The database configuration name %s was not present in the databases.cfg file.",configName);
}

public Event_AbilityUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new user = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//Save the location of the player who just used an infected ability
	GetClientAbsOrigin(user,infectedPosition[user]);
}
public Event_PlayerPounced(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Float:pouncePosition[3];
	new attackerId = GetEventInt(event, "userid");
	new victimId = GetEventInt(event, "victim");
	new attackerClient = GetClientOfUserId(attackerId);
	new victimClient = GetClientOfUserId(victimId);
		
	decl String:attackerName[MAX_NAME_LENGTH];
	decl String:safeAttackerName[MAX_NAME_LENGTH * 2 + 1]; //per EscapeString requirements
	decl String:victimName[MAX_NAME_LENGTH];
	decl String:safeVictimName[MAX_NAME_LENGTH * 2 + 1];
	decl String:pounceSqlQuery[256];
	decl String:steamID[64];
	decl String:mapName[MAX_NAME_LENGTH];
	
	//distance supplied isn't the actual 2d vector distance needed for damage calculation. See more about it at
	//http://forums.alliedmods.net/showthread.php?t=93207
	//new eventDistance = GetEventInt(event, "distance");
	
	//get hunter-related pounce cvars
	new max = 1000;
	new min = 300;
	new maxDmg = GetConVarInt(hMaxPounceDamage);
	
	//Get current position while pounced
	GetClientAbsOrigin(attackerClient,pouncePosition);
	
	//Calculate 2d distance between previous position and pounce position
	new distance = RoundToNearest(GetVectorDistance(infectedPosition[attackerClient], pouncePosition));
	
	//Check to see if the pounce produced any pounce damage
	if(distance < min)
		return; //if not, don't add to db.
		
	//Get damage using hunter damage formula
	//damage in this is expressed as a float because my server has competitive hunter pouncing where the decimal counts
	new Float:dmg = (((distance - float(min)) / float(max - min)) * float(maxDmg)) + 1;
	
	GetClientName(attackerClient,attackerName,sizeof(attackerName));
	GetClientName(victimClient,victimName,sizeof(victimName));
	SQL_EscapeString(hDb,victimName,safeVictimName,sizeof(safeVictimName));
	SQL_EscapeString(hDb,attackerName,safeAttackerName,sizeof(safeAttackerName));
	
	GetClientAuthString(attackerClient,steamID,sizeof(steamID));
	GetCurrentMap(mapName,sizeof(mapName));
	
	//Now we have all the data we need, form the SQL statement try to commit it to the database
	Format(pounceSqlQuery,sizeof(pounceSqlQuery),"INSERT INTO pounces (datetime, pouncer, pounced, distance, damage, map,steamid) VALUES (NOW(),'%s','%s','%d','%f','%s','%s')",
	safeAttackerName,safeVictimName,distance,dmg,mapName,steamID);
	SQL_TQuery(hDb,SqlPounceCallback,pounceSqlQuery);
}
public SqlPounceCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
		LogError("The following error occured while inserting a pounce into the database: %s",error);
}