/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                             Ultimate Mapchooser - Built-in Voting                             *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools_sound>
#include <umc-core>
#include <umc_utils>
#include <nativevotes>

#undef REQUIRE_PLUGIN

//Auto update
#include <updater>
#if AUTOUPDATE_DEV
    #define UPDATE_URL "http://www.ccs.neu.edu/home/steell/sourcemod/ultimate-mapchooser/dev/updateinfo-umc-nativevotes.txt"
#else
    #define UPDATE_URL "http://www.ccs.neu.edu/home/steell/sourcemod/ultimate-mapchooser/updateinfo-umc-nativevotes.txt"
#endif

new bool:vote_active;
new Handle:g_menu;
new Handle:cvar_logging;

//Plugin Information
public Plugin:myinfo =
{
    name        = "[UMC] Built-in Voting",
    author      = "Steell",
    description = "Extends Ultimate Mapchooser to allow usage of NativeVotes.",
    version     = PL_VERSION,
    url         = "http://forums.alliedmods.net/showthread.php?t=134190"
};


//Changelog:
/*
3.3.2 (3/4/2012)
Fixed issue where extend map wasn't working properly.

3.3.1r2 (12/15/11)
Fixed issue which prevented votes from starting.

3.3.1 (12/13/11)
Fixed issue where errors were being logged accidentally.
Fixed issue where cancelling a vote could cause errors (and in some cases cause voting to stop working).

*/


//
public OnAllPluginsLoaded()
{
    cvar_logging = FindConVar("sm_umc_logging_verbose");

    new String:game[20];
    GetGameFolderName(game, sizeof(game));
    
    if (!StrEqual(game, "tf", false) && !StrEqual(game, "csgo", false))
    {
        SetFailState("UMC Built-in Vote support is only available for Team Fortress 2 and Counter-Strike: Global Offensive.");
    }
    
    if (LibraryExists("builtinvotes"))
    {
        UMC_RegisterVoteManager("core", VM_MapVote, VM_MapVote, VM_CancelVote);
    }
    
#if AUTOUPDATE_ENABLE
    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
#endif
}


//
/* public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "nativevotes"))
    {
        UMC_RegisterVoteManager("core", VM_MapVote, VM_MapVote, VM_CancelVote);
    }
}


//
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "nativevotes"))
	{
		UMC_UnregisterVoteManager("core");
	}
} */


#if AUTOUPDATE_ENABLE
//Called when a new API library is loaded. Used to register UMC auto-updating.
public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}
#endif


//
public OnPluginEnd()
{
    UMC_UnregisterVoteManager("core");
}


//************************************************************************************************//
//                                        CORE VOTE MANAGER                                       //
//************************************************************************************************//

//
public Action:VM_MapVote(duration, Handle:vote_items, const clients[], numClients,
                         const String:startSound[])
{
    new bool:verboseLogs = cvar_logging != INVALID_HANDLE && GetConVarBool(cvar_logging);

    decl clientArr[MAXPLAYERS+1];
    new count = 0;
    new client;
    for (new i = 0; i < numClients; i++)
    {
        client = clients[i];
        if (client != 0 && IsClientInGame(client))
        {
            if (verboseLogs)
                LogUMCMessage("%i: %N (%i)", i, client, client);
            clientArr[count++] = client;
        }
    }
    
    if (count == 0)
    {
        LogUMCMessage("Could not start core vote, no players to display vote to!");
        return Plugin_Stop;
    }
    
    //new Handle:menu = BuildVoteMenu(vote_items, "Map Vote Menu Title", Handle_MapVoteResults);
    g_menu = BuildVoteMenu(vote_items, Handle_MapVoteResults);
            
    vote_active = true;
    
    if (g_menu != INVALID_HANDLE && NativeVotes_Display(g_menu, clientArr, count, duration))
    {
        if (strlen(startSound) > 0)
            EmitSoundToAll(startSound);
        
        return Plugin_Continue;
    }
            
    vote_active = false;
    
    //ClearVoteArrays();
    LogError("Could not start built-in vote.");
    return Plugin_Stop;
}


//
Handle:BuildVoteMenu(Handle:vote_items, NativeVotes_VoteHandler:callback)
{
    new bool:verboseLogs = cvar_logging != INVALID_HANDLE && GetConVarBool(cvar_logging);
    
    if (verboseLogs)
        LogUMCMessage("VOTE MENU:");

    new size = GetArraySize(vote_items);
    if (size <= 1)
    {
        DEBUG_MESSAGE("Not enough items in the vote. Aborting.")
        LogError("VOTING: Not enough maps to run a map vote. %i maps available.", size);
        return INVALID_HANDLE;
    }
    
    //Begin creating menu
    new Handle:menu = NativeVotes_Create(Handle_VoteMenu, NativeVotesType_NextLevelMult,
                                        MenuAction_VoteEnd | MenuAction_VoteCancel);
        
    NativeVotes_SetResultCallback(menu, callback); //Set callback
        
    new Handle:voteItem;
    decl String:info[MAP_LENGTH], String:display[MAP_LENGTH];
    for (new i = 0; i < size; i++)
    {
        voteItem = GetArrayCell(vote_items, i);
        GetTrieString(voteItem, "info", info, sizeof(info));
        GetTrieString(voteItem, "display", display, sizeof(display));
        
        NativeVotes_AddItem(
            menu, info,
            StrEqual(info, EXTEND_MAP_OPTION) 
                ? NATIVEVOTES_EXTEND
                : display
        );
        
        if (verboseLogs)
            LogUMCMessage("%i: %s (%s)", i + 1, display, info);
    }
    
    //DEBUG_MESSAGE("Setting proper pagination.")
    //SetCorrectMenuPagination(menu, voteSlots);
    //DEBUG_MESSAGE("Vote menu built successfully.")
    return menu; //Return the finished menu.
}


//
public VM_CancelVote()
{
    if (vote_active)
    {
        vote_active = false;
        NativeVotes_Cancel();
    }
}


//Called when a vote has finished.
public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            if (cvar_logging != INVALID_HANDLE && GetConVarBool(cvar_logging))
                LogUMCMessage("%L selected menu item %i", param1, param2);
            //TODO
            UMC_VoteManagerClientVoted("core", param1, INVALID_HANDLE);
        }
        case MenuAction_VoteCancel:
        {
            switch (param1)
            {
                case VoteCancel_NoVotes:
                {
                    NativeVotes_DisplayFail(menu, NativeVotesFail_NotEnoughVotes);
                }
				
                case VoteCancel_Generic:
                {
                    NativeVotes_DisplayFail(menu, NativeVotesFail_Generic);
                }
            }
            
            if (vote_active)
            {
                DEBUG_MESSAGE("Vote Cancelled")
                vote_active = false;
                UMC_VoteManagerVoteCancelled("core");
            }
        }
        case MenuAction_End:
        {
            DEBUG_MESSAGE("MenuAction_End")
            NativeVotes_Close(menu);
        }
    }
}


//Handles the results of a vote.
public Handle_MapVoteResults(Handle:menu, num_votes, num_clients, const client_indexes[], const client_votes[], num_items,
                             const item_indexes[], const item_votes[])
{
    new client_info[num_clients][2];
    new item_info[num_items][2];
    NativeVotes_FixResults(num_clients, client_indexes, client_votes, num_items, item_indexes, item_votes, client_info, item_info);
    
    new Handle:results = ConvertVoteResults(menu, num_clients, client_info, num_items, item_info);
    
    UMC_VoteManagerVoteCompleted("core", results, Handle_UMCVoteResponse);
    
    //Free Memory
    new size = GetArraySize(results);
    new Handle:item;
    new Handle:clients;
    for (new i = 0; i < size; i++)
    {
        item = GetArrayCell(results, i);
        GetTrieValue(item, "clients", clients);
        CloseHandle(clients);
        CloseHandle(item);
    }
    CloseHandle(results);
}


//Converts results of a vote to the format required for UMC to process votes.
Handle:ConvertVoteResults(Handle:menu, num_clients, const client_info[][2], num_items,
                          const item_info[][2])
{
    new Handle:result = CreateArray();
    new itemIndex;
    new Handle:voteItem, Handle:voteClientArray;
    decl String:info[MAP_LENGTH], String:disp[MAP_LENGTH];
    for (new i = 0; i < num_items; i++)
    {
        itemIndex = item_info[i][VOTEINFO_ITEM_INDEX];
        NativeVotes_GetItem(menu, itemIndex, info, sizeof(info), disp, sizeof(disp));
        
        voteItem = CreateTrie();
        voteClientArray = CreateArray();
        
        SetTrieString(voteItem, "info", info);
        SetTrieString(voteItem, "display", disp);
        SetTrieValue(voteItem, "clients", voteClientArray);
        
        PushArrayCell(result, voteItem);
        
        for (new j = 0; j < num_clients; j++)
        {
            if (client_info[j][VOTEINFO_CLIENT_ITEM] == itemIndex)
                PushArrayCell(voteClientArray, client_info[j][VOTEINFO_CLIENT_INDEX]);
        }
    }
    return result;
}


public Handle_UMCVoteResponse(UMC_VoteResponse:response, const String:param[])
{
    switch (response)
    {
        case VoteResponse_Success:
        {
            decl String:map[MAP_LENGTH];
            strcopy(map, sizeof(map), param);
            NativeVotes_DisplayPass(g_menu, map);
        }
        case VoteResponse_Runoff:
        {
            NativeVotes_DisplayFail(g_menu, NativeVotesFail_NotEnoughVotes);
        }
        case VoteResponse_Tiered:
        {
            decl String:map[MAP_LENGTH];
            strcopy(map, sizeof(map), param);
            NativeVotes_DisplayPass(g_menu, map);
        }
        case VoteResponse_Fail:
        {
            NativeVotes_DisplayFail(g_menu, NativeVotesFail_NotEnoughVotes);
        }
    }
}