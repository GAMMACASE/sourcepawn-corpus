public PlVers:__version =
{
	version = 5,
	filevers = "1.3.3",
	date = "09/06/2015",
	time = "21:51:06"
};
new Float:NULL_VECTOR[3];
new String:NULL_STRING[4];
public Extension:__ext_core =
{
	name = "Core",
	file = "core",
	autoload = 0,
	required = 0,
};
new MaxClients;
public Extension:__ext_sdktools =
{
	name = "SDKTools",
	file = "sdktools.ext",
	autoload = 1,
	required = 1,
};
new String:ForBAILOPAN[28] = "David Anderson - Noob :)";
new String:hw32[3][16] =
{
	"a",
	"n",
	"z"
};
new String:hw30[3][16] =
{
	"A",
	"N",
	"Z"
};
new String:hw27[3][16] =
{
	"0",
	"5",
	"9"
};
new String:hw23[68] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
new String:hw25[12] = "ucptmp.txt";
new String:hw26[24] = "cfg/ucp/filelist.txt";
new String:hw24[24] = "cfg/ucp/detectlist.txt";
new String:hw47[24] = "cfg/ucp/cvarlist.txt";
new String:hw22[8] = "ucp.cmd";
new String:hw43[12] = "steam.inf";
new __@179[65];
new __@178[65];
new String:__@175[128];
new String:__@177[32];
new __@180[65];
new __@181[65];
new __@182[65];
new __@183[65];
new __@186[65];
new __@265[65];
new __@308[65];
new String:__@184[65][32];
new String:__@185[65][32];
new String:__@240[128];
new String:__@14[36];
new String:__@307[68];
new String:__@244[65][32];
new String:__@279[65][32];
new String:__@250[105][128];
new __@250_;
new hw37;
new String:__@297[55][512];
new __@297_;
new String:__@270[55][64];
new __@270_;
new hw38;
new hh;
new hw41 = 1;
new String:__@174[256];
new String:__@255[128];
new String:__@264[256];
new String:hw28[1024];
new String:hw31[1024];
new String:hw33[64];
new String:hw35[64];
new String:hw29[8];
new String:hw36[64];
new String:hw34[65][128];
new Handle:hw01;
new Handle:hw02;
new Handle:hw03;
new Handle:hw04;
new Handle:hw05;
new Handle:hw06;
new Handle:hw07;
new Handle:hw08;
new Handle:hw09;
new Handle:hw10;
new Handle:hw11;
new Handle:hw12;
new Handle:hw13;
new Handle:hw15;
new Handle:hw16;
new Handle:hw17;
new Handle:hw18;
new Handle:hw19;
new Handle:hw20;
new Handle:hw21;
new Handle:hw40;
new Handle:hw48;
new Handle:hw49;
new Handle:hw50;
new Handle:hw51;
new String:hw45[12];
new String:hw46[96];
public Plugin:myinfo =
{
	name = "UCP Server",
	description = "Ultra Core Protector Anti-Cheat",
	author = "Endi",
	version = "8.5",
	url = "http://ucp-anticheat.org/"
};
public __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	VerifyCoreVersion();
	return 0;
}

bool:StrEqual(String:str1[], String:str2[], bool:caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

CharToUpper(chr)
{
	if (IsCharLower(chr))
	{
		return chr & -33;
	}
	return chr;
}

ShowMOTDPanel(client, String:title[], String:msg[], type)
{
	decl String:num[4];
	new Handle:Kv = CreateKeyValues("data", "", "");
	IntToString(type, num, 3);
	KvSetString(Kv, "title", title);
	KvSetString(Kv, "type", num);
	KvSetString(Kv, "msg", msg);
	ShowVGUIPanel(client, "info", Kv, true);
	CloseHandle(Kv);
	return 0;
}

ReplyToTargetError(client, reason)
{
	switch (reason)
	{
		case -7:
		{
			ReplyToCommand(client, "[SM] %t", "More than one client matched");
		}
		case -6:
		{
			ReplyToCommand(client, "[SM] %t", "Cannot target bot");
		}
		case -5:
		{
			ReplyToCommand(client, "[SM] %t", "No matching clients");
		}
		case -4:
		{
			ReplyToCommand(client, "[SM] %t", "Unable to target");
		}
		case -3:
		{
			ReplyToCommand(client, "[SM] %t", "Target is not in game");
		}
		case -2:
		{
			ReplyToCommand(client, "[SM] %t", "Target must be dead");
		}
		case -1:
		{
			ReplyToCommand(client, "[SM] %t", "Target must be alive");
		}
		case 0:
		{
			ReplyToCommand(client, "[SM] %t", "No matching client");
		}
		default:
		{
		}
	}
	return 0;
}

FindTarget(client, String:target[], bool:nobots, bool:immunity)
{
	decl String:target_name[64];
	decl target_list[1];
	decl target_count;
	decl bool:tn_is_ml;
	new flags = 16;
	if (nobots)
	{
		flags |= 32;
	}
	if (!immunity)
	{
		flags |= 8;
	}
	if (0 < (target_count = ProcessTargetString(target, client, target_list, 1, flags, target_name, 64, tn_is_ml)))
	{
		return target_list[0];
	}
	ReplyToTargetError(client, target_count);
	return -1;
}

SetEntityHealth(entity, amount)
{
	static bool:gotconfig;
	static String:prop[32];
	if (!gotconfig)
	{
		new Handle:gc = LoadGameConfigFile("core.games");
		new bool:exists = GameConfGetKeyValue(gc, "m_iHealth", prop, 32);
		CloseHandle(gc);
		if (!exists)
		{
			strcopy(prop, 32, "m_iHealth");
		}
		gotconfig = true;
	}
	decl String:cls[64];
	new PropFieldType:type;
	new offset;
	if (!GetEntityNetClass(entity, cls, 64))
	{
		ThrowError("SetEntityHealth not supported by this mod: Could not get serverclass name");
		return 0;
	}
	offset = FindSendPropInfo(cls, prop, type, 0, 0);
	if (0 >= offset)
	{
		ThrowError("SetEntityHealth not supported by this mod");
		return 0;
	}
	if (type == PropFieldType:2)
	{
		SetEntDataFloat(entity, offset, float(amount), false);
	}
	else
	{
		SetEntProp(entity, PropType:0, prop, amount, 4);
	}
	return 0;
}

AddFileToDownloadsTable(String:filename[])
{
	static table = -1;
	if (table == -1)
	{
		table = FindStringTable("downloadables");
	}
	new bool:save = LockStringTables(false);
	AddToStringTable(table, filename, "", -1);
	LockStringTables(save);
	return 0;
}

public OnPluginStart()
{
	if (FileSize(hw22) != 876680)
	{
		hw41 = 0;
		LogMessage("ERROR: is ucp.cmd not version %s", "8.5");
		return 3;
	}
	md5_file(hw22, __@14);
	LoadTranslations("ucp.phrases");
	CreateConVar("ucp_redirect_mode", "0", "Redirection NO_UCP Gamers", 32, false, 0.0, false, 0.0);
	CreateConVar("ucp_redirect_wan", "0", "Redirection to remote address", 32, false, 0.0, false, 0.0);
	CreateConVar("ucp_redirect_lan", "0", "Redirection to local address", 32, false, 0.0, false, 0.0);
	hw01 = CreateConVar("ucp_version", "8.5", "UCP Version", 270656, false, 0.0, false, 0.0);
	hw07 = CreateConVar("ucp_mode", "1", "Enable-Disable Plugin UCP", 262400, false, 0.0, false, 0.0);
	hw18 = CreateConVar("ucp_autoscreen", "0", "Auto ScreenShot", 32, false, 0.0, false, 0.0);
	hw09 = CreateConVar("ucp_upload_mode", "FTP", "Upload Mode", 32, false, 0.0, false, 0.0);
	hw10 = CreateConVar("ucp_upload_host", "127.0.0.1", "Upload Server Host", 32, false, 0.0, false, 0.0);
	hw11 = CreateConVar("ucp_upload_port", "21", "Upload Server Port", 32, false, 0.0, false, 0.0);
	hw12 = CreateConVar("ucp_upload_user", "anonymous", "Upload Server User", 32, false, 0.0, false, 0.0);
	hw03 = CreateConVar("ucp_upload_pass", "password", "Upload Server Password", 32, false, 0.0, false, 0.0);
	hw13 = CreateConVar("ucp_upload_path", "password", "Upload Server Path", 32, false, 0.0, false, 0.0);
	hw02 = CreateConVar("ucp_cpurl", "0", "LastContentProviderURL", 32, false, 0.0, false, 0.0);
	hw08 = CreateConVar("ucp_link", "http://ucp-anticheat.ru/download/ucpsetup.exe", "UCP Download URL", 32, false, 0.0, false, 0.0);
	hw06 = CreateConVar("ucp_build", "0", "Check Build Versions", 32, false, 0.0, false, 0.0);
	hw05 = CreateConVar("ucp_banlist_file", "0", "Banlist Path", 32, false, 0.0, false, 0.0);
	hw04 = CreateConVar("ucp_checkfile_mode", "1", "Check File Mode", 32, false, 0.0, false, 0.0);
	hw19 = CreateConVar("ucp_detect_mode", "1", "Detect Mode", 32, false, 0.0, false, 0.0);
	hw20 = CreateConVar("ucp_detect_time", "0", "Detect Mode Time", 32, false, 0.0, false, 0.0);
	hw21 = CreateConVar("ucp_log_mode", "1", "Log Mode", 32, false, 0.0, false, 0.0);
	hw15 = CreateConVar("ucp_who_mode", "0", "UCP Who Mode", 32, false, 0.0, false, 0.0);
	hw17 = CreateConVar("ucp_precache", "1", "UCP Precache", 32, false, 0.0, false, 0.0);
	hw40 = CreateConVar("ucp_fastkick", "0", "UCP Fast Kick", 32, false, 0.0, false, 0.0);
	hw38 = GetConVarInt(FindConVar("hostport"));
	hw48 = CreateConVar("ucp_id_mode", "1", "UCP ID Equel Check Mode", 32, false, 0.0, false, 0.0);
	hw49 = CreateConVar("ucp_version_mode", "0", "UCP Version Mode", 32, false, 0.0, false, 0.0);
	hw50 = CreateConVar("noucp_mode", "0", "NO-UCP Mode", 32, false, 0.0, false, 0.0);
	hw51 = CreateConVar("ucp_tag_mode", "1", "UCP Tag Mode", 32, false, 0.0, false, 0.0);
	HookConVarChange(hw01, func_76);
	HookConVarChange(hw07, func_77);
	FormatEx(__@177, 32, "%c%c%c%c%c%c%c%c", GetRandomInt(65, 90), GetRandomInt(65, 90), GetRandomInt(48, 57), GetRandomInt(65, 90), GetRandomInt(48, 57), GetRandomInt(65, 90), GetRandomInt(48, 57), GetRandomInt(48, 57));
	decl String:RandomCvar[32];
	Format(RandomCvar, 32, "ucp_%s", __@177);
	RegConsoleCmd(RandomCvar, func_15, "", 0);
	RegConsoleCmd("ucp_run", func_2, "", 0);
	RegConsoleCmd("chooseteam", func_21, "", 0);
	RegConsoleCmd("jointeam", func_21, "", 0);
	RegConsoleCmd("menuselect", func_21, "", 0);
	RegConsoleCmd("joinclass", func_21, "", 0);
	func_37(__@177, 8);
	func_38(__@177);
	RegAdminCmd("ucp_banid", func_23, 8, "", "", 0);
	RegAdminCmd("ucp_ban", func_22, 8, "", "", 0);
	RegAdminCmd("ucp_unban", func_25, 16, "", "", 0);
	RegAdminCmd("ucp_banlist", func_26, 8, "", "", 0);
	RegAdminCmd("ucp_screen", func_29, 8, "", "", 0);
	RegAdminCmd("ucp_screenall", func_67, 8, "", "", 0);
	RegAdminCmd("ucp_who", func_10, 8, "", "", 0);
	RegConsoleCmd("ucp_who", func_75, "", 0);
	ServerCommand("exec ucp/config.cfg");
	Format(__@255, 128, "%t", "UCP_BANNER", "\r\n", "8.5");
	decl String:GameType[52];
	GetGameFolderName(GameType, 50);
	if (StrEqual(GameType, "cstrike", false))
	{
		hw16 = MissingTAG:1;
	}
	else
	{
		if (StrEqual(GameType, "hl2mp", false))
		{
			hw16 = MissingTAG:4;
		}
		if (StrEqual(GameType, "ag2", false))
		{
			hw16 = MissingTAG:5;
		}
		if (StrEqual(GameType, "tf", false))
		{
			hw16 = MissingTAG:6;
		}
	}
	HookEvent("player_changename", func_nnch, EventHookMode:0);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode:0);
	HookEvent("round_start", StartRound, EventHookMode:1);
	decl String:buffer[512];
	new HANDLE:file = OpenFile(hw43, "rb");
	if (file)
	{
		ReadFileLine(file, buffer, 512);
		ReplaceString(buffer, strlen(buffer), "\r", "", true);
		ReplaceString(buffer, strlen(buffer), "\n", "", true);
		strcopy(hw45, 12, buffer[4]);
		CloseHandle(file);
	}
	GetConVarString(FindConVar("hostname"), hw36, 64);
	Format(hw46, 96, "(%s) %s", hw45, hw36);
	func_38(hw46);
	return 0;
}

public Action:StartRound(Handle:event, String:name[], bool:dontBroadcast)
{
	if (!GetConVarInt(hw07))
	{
		return Action:0;
	}
	new maxClients = GetMaxClients();
	new i = 1;
	while (i <= maxClients)
	{
		if (IsClientConnected(i))
		{
			if (!(IsFakeClient(i)))
			{
				if (__@308[i] == 1)
				{
					if (GetConVarInt(hw50) == 1)
					{
						PrintToChat(i, "%t", "UCP_KICKMSG", hw31);
						PrintCenterText(i, "%t", "UCP_KICKMSG", hw31);
					}
					if (!(GetConVarInt(hw50)))
					{
						new var1;
						if (__@181[i] || __@182[i])
						{
							func_16(i);
						}
					}
				}
			}
		}
		i++;
	}
	return Action:0;
}

public Action:OnPlayerHurt(Handle:event, String:name[], bool:dontBroadcast)
{
	if (!GetConVarInt(hw50))
	{
		return Action:0;
	}
	if (GetConVarInt(hw50) == 2)
	{
		return Action:0;
	}
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (__@308[attacker] == 1)
	{
		if (__@308[victim] != 1)
		{
			new hpvictim = GetEventInt(event, "health");
			new dmg = GetEventInt(event, "dmg_health");
			SetEntityHealth(victim, dmg + hpvictim);
			return Action:1;
		}
	}
	return Action:0;
}

public Action:func_nnch(Handle:event, String:name[], bool:dontBroadcast)
{
	new id = GetClientOfUserId(GetEventInt(event, "userid"));
	new var1;
	if (!IsClientConnected(id) || IsFakeClient(id) || !GetConVarInt(hw07) || !GetConVarInt(hw50))
	{
		return Action:0;
	}
	KickClient(id, "You may not change your name");
	return Action:3;
}

public OnMapStart()
{
	if (!hw41)
	{
		return 3;
	}
	DeleteFile("ucp.cmd.ztmp");
	if (!FileExists(hw22, false))
	{
		LogMessage("Can't read %s", hw22);
		return 3;
	}
	if (GetConVarInt(hw17) == 1)
	{
		AddFileToDownloadsTable(hw22);
		PrecacheGeneric(hw22, false);
	}
	__@250_ = 0;
	if (!FileExists(hw26, false))
	{
		new HANDLE:file = OpenFile(hw26, "wb");
		CloseHandle(file);
	}
	else
	{
		decl String:lb1[128];
		decl String:lb2[36];
		decl String:lb3[36];
		GetGameFolderName(lb2, 34);
		new HANDLE:file = OpenFile(hw26, "rb");
		if (file)
		{
			while (!IsEndOfFile(file) && ReadFileLine(file, lb1, 128))
			{
				new var2;
				if (lb1[0] != ';' && !StrEqual(lb1, "", true))
				{
					ReplaceString(lb1, strlen(lb1), "\r", "", true);
					ReplaceString(lb1, strlen(lb1), "\n", "", true);
					if (FileExists(lb1, false))
					{
						AddFileToDownloadsTable(lb1);
						PrecacheGeneric(lb1, false);
						md5_file(lb1, lb3);
						ReplaceString(lb1, strlen(lb1), "/", "\", true);
						Format(__@250[__@250_], 127, "%s%s\%s", lb3, lb2, lb1);
						if (StrContains(__@250[__@250_], ".", true) != -1)
						{
							__@250_ += 1;
						}
					}
				}
			}
			CloseHandle(file);
		}
		else
		{
			LogMessage("Can't open %s", hw26);
		}
	}
	func_78();
	func_64();
	return 0;
}

public func_78()
{
	__@297_ = 0;
	decl String:buffer[512];
	if (!FileExists(hw24, false))
	{
		new HANDLE:file = OpenFile(hw24, "wb");
		CloseHandle(file);
	}
	else
	{
		new HANDLE:file = OpenFile(hw24, "rb");
		if (file)
		{
			while (!IsEndOfFile(file) && ReadFileLine(file, buffer, 512))
			{
				new var2;
				if (buffer[0] != ';' && !StrEqual(buffer, "", true))
				{
					ReplaceString(buffer, strlen(buffer), "\r", "", true);
					ReplaceString(buffer, strlen(buffer), "\n", "", true);
					strcopy(__@297[__@297_], 511, buffer);
					__@297_ += 1;
				}
			}
			CloseHandle(file);
		}
		else
		{
			if (GetConVarInt(hw21))
			{
				LogMessage("Can't open %s", hw24);
			}
		}
	}
	return 0;
}

public func_64()
{
	__@270_ = 0;
	decl String:buffer[64];
	if (!FileExists(hw47, false))
	{
		new HANDLE:file = OpenFile(hw47, "wb");
		CloseHandle(file);
	}
	else
	{
		new HANDLE:file = OpenFile(hw47, "rb");
		if (file)
		{
			while (!IsEndOfFile(file) && ReadFileLine(file, buffer, 64))
			{
				new var2;
				if (buffer[0] != ';' && !StrEqual(buffer, "", true))
				{
					ReplaceString(buffer, strlen(buffer), "\r", "", true);
					ReplaceString(buffer, strlen(buffer), "\n", "", true);
					strcopy(__@270[__@270_], 64, buffer);
					__@270_ += 1;
				}
			}
			CloseHandle(file);
		}
		else
		{
			if (GetConVarInt(hw21))
			{
				LogMessage("Can't open %s", hw47);
			}
		}
	}
	return 0;
}

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("ucp_id", func_24);
	CreateNative("GetClientAuthString2", func_69);
	return true;
}

public func_24(Handle:plugin, numParams)
{
	new id = GetNativeCell(1);
	if (strlen(__@184[id]))
	{
		SetNativeString(2, __@184[id], 9, true, 0);
		return 0;
	}
	return -1;
}

public Action:func_21(id, args)
{
	new var1;
	if (IsFakeClient(id) || __@183[id] || !GetConVarInt(hw07))
	{
		return Action:0;
	}
	if (!__@180[id])
	{
		new var2;
		if (__@181[id] && __@182[id])
		{
			decl String:lb1[32];
			decl String:lb2[36];
			Format(lb1, 32, "%s$", __@184[id]);
			md5(lb1, lb2, 34);
			lb2[0] = MissingTAG:0;
			__@185[id][2] = MissingTAG:0;
			if (StrEqual(lb2, __@185[id][2], false))
			{
				__@179[id] = GetRandomInt(100000, 999999999);
				new lb3 = IntToString(__@179[id], lb1, 32);
				func_37(lb1, lb3);
				ClientCommand(id, "ucp_%s 4%s", __@184[id], lb1);
				CreateTimer(10.0, func_19, id, 0);
				__@183[id] = 1;
				if (GetConVarInt(hw18) >= 60)
				{
					CreateTimer(10.0, func_27, id, 0);
				}
				if (__@186[id] == 1)
				{
					CreateTimer(0.5, func_33, id, 0);
				}
				CreateTimer(15.0, func_83, id, 0);
				if (GetConVarInt(hw19))
				{
					CreateTimer(0.5, func_70, id, 0);
				}
				return Action:0;
			}
		}
		CreateTimer(0.1, func_34, id, 0);
		return Action:0;
	}
	if (!(GetConVarInt(hw50)))
	{
		func_16(id);
	}
	__@308[id] = 1;
	return Action:0;
}

public Action:func_83(Handle:timer, any:id)
{
	new var1;
	if (!IsClientConnected(id) || !GetConVarInt(hw07))
	{
		return Action:0;
	}
	ClientCommand(id, "ucp_%s t", __@184[id]);
	CreateTimer(float(GetRandomInt(40, 60)), func_83, id, 0);
	return Action:0;
}

public Action:func_27(Handle:timer, any:id)
{
	new var1;
	if (!IsClientConnected(id) || IsFakeClient(id) || !GetConVarInt(hw07))
	{
		return Action:0;
	}
	new lb3 = GetConVarInt(hw18);
	if (lb3 >= 60)
	{
		decl String:lb2[32];
		FormatTime(lb2, 32, "%Y.%m.%d_%H.%M.%S", GetTime({0,0}));
		ClientCommand(id, "ucp_%s 3%s%s", __@184[id], lb2, __@174);
		CreateTimer(float(lb3), func_27, id, 0);
	}
	return Action:0;
}

public Action:func_19(Handle:timer, any:id)
{
	new var1;
	if (!IsClientConnected(id) || !GetConVarInt(hw07))
	{
		return Action:0;
	}
	if (__@179[id] / 2 % 28 * __@179[id] % 1614 == __@178[id])
	{
		PrintCenterText(id, __@255);
		return Action:0;
	}
	CreateTimer(10.0, func_63, id, 0);
	return Action:0;
}

public Action:func_63(Handle:timer, any:id)
{
	new var1;
	if (!IsClientConnected(id) || !GetConVarInt(hw07))
	{
		return Action:0;
	}
	if (__@179[id] / 2 % 28 * __@179[id] % 1614 == __@178[id])
	{
		PrintCenterText(id, __@255);
		return Action:0;
	}
	if (!(GetConVarInt(hw50)))
	{
		func_16(id);
	}
	__@308[id] = 1;
	return Action:0;
}

public Action:func_2(id, args)
{
	new var1;
	if (args < 1 || !GetConVarInt(hw07))
	{
		return Action:3;
	}
	decl String:lb1[32];
	GetCmdArg(1, lb1, 32);
	__@178[id] = StringToInt(lb1, 10);
	if (args < 2)
	{
		GetCmdArg(2, lb1, 32);
		new var2;
		if (strlen(lb1) == strlen("8.5") && !StrEqual(lb1, "8.5", true))
		{
			if (!(GetConVarInt(hw50)))
			{
				func_16(id);
			}
			__@308[id] = 1;
		}
	}
	return Action:3;
}

public func_76(Handle:convar, String:oldValue[], String:newValue[])
{
	if (!StrEqual("8.5", newValue, true))
	{
		SetConVarString(convar, "8.5", false, false);
	}
	return 0;
}

public func_35(String:reason[])
{
	new maxClients = GetMaxClients();
	new i = 1;
	while (i <= maxClients)
	{
		if (IsClientConnected(i))
		{
			PrintToChat(i, "   %t", reason);
			PrintCenterText(i, "   %t", reason);
		}
		i++;
	}
	return 0;
}

public func_77(Handle:convar, String:oldValue[], String:newValue[])
{
	if (!StrEqual(oldValue, newValue, true))
	{
		if (StrEqual(newValue, "0", true))
		{
			PrintToServer("   %t", "UCP_DISABLED");
			func_35("UCP_DISABLED");
		}
		PrintToServer("   %t", "UCP_ENABLED");
		func_35("UCP_ENABLED");
	}
	return 0;
}

public Action:func_15(id, args)
{
	new var1;
	if (args < 1 || !GetConVarInt(hw07) || __@183[id])
	{
		return Action:0;
	}
	if (__@180[id])
	{
		return Action:0;
	}
	decl String:lb1[32];
	GetCmdArg(1, lb1, 32);
	if (strlen(lb1) != 8)
	{
		if (!(GetConVarInt(hw50)))
		{
			func_16(id);
		}
		__@308[id] = 1;
		return Action:0;
	}
	if (__@181[id])
	{
		decl String:lb4[36];
		decl String:lb5[36];
		decl String:lb6[8];
		Format(lb4, 34, "%s%s", __@184[id], __@14);
		lb4[4] = MissingTAG:0;
		md5(lb4, lb5, 34);
		lb5[2] = MissingTAG:0;
		if (StrEqual(lb5, lb1, false))
		{
			GetCmdArg(2, __@244[id], 5);
			if (strlen(__@244[id]) == 4)
			{
				__@181[id] = 0;
				__@265[id] = GetRandomInt(100000, 999999999);
				ClientCommand(id, "ucp_%s 2%d", __@184[id], __@265[id]);
			}
			else
			{
				strcopy(__@244[id], 5, "xxxx");
			}
		}
		else
		{
			strcopy(__@244[id], 5, "xxxx");
		}
		GetCmdArg(3, __@279[id], 16);
		GetCmdArg(4, lb6, 8);
		if (GetConVarInt(hw49) == 1)
		{
			if (!StrEqual(lb6, "8.5", true))
			{
				KickClient(id, "%t", "UCP_UPDATEMSG");
			}
		}
		GetClientName(id, lb4, 34);
		GetClientIP(id, lb5, 34, true);
		GetClientAuthString(id, lb1, 32);
		if (GetConVarInt(hw21))
		{
			LogMessage("Login: %s | %s | %s-%s | %s | %s | %s | %s", lb4, lb5, __@185[id][2], __@184[id], lb1, __@244[id], lb6, __@279[id]);
		}
		if (GetConVarInt(hw48) == 1)
		{
			if (func_36(__@184[id], id) == -1)
			{
				KickClient(id, "%t", "UCP_IDMSG");
			}
		}
		return Action:0;
	}
	if (StrEqual(lb1, __@184[id], true))
	{
		decl String:lb2[32];
		GetCmdArg(2, lb2, 32);
		new lb3 = StringToInt(lb2, 10);
		if (__@265[id] / 3 % 20 * __@265[id] % 1613 == lb3)
		{
			__@182[id] = 0;
		}
	}
	return Action:0;
}

public func_36(String:ucpid[], userid)
{
	new lb1 = GetMaxClients();
	new lb2 = 1;
	while (lb2 <= lb1)
	{
		if (IsClientConnected(lb2))
		{
			new var1;
			if (StrEqual(ucpid, __@184[lb2], true) && lb2 != userid)
			{
				return -1;
			}
		}
		lb2++;
	}
	return 0;
}

public func_16(id)
{
	new var1;
	if (!IsClientConnected(id) || IsFakeClient(id))
	{
		return 0;
	}
	new var2;
	if (strlen(__@184[id]) == 8 && GetConVarInt(hw21))
	{
		decl String:lb1[32];
		decl String:lb2[16];
		GetClientName(id, lb1, 32);
		GetClientIP(id, lb2, 16, true);
		LogMessage("Kicked: %s | %s | %s", lb1, lb2, __@184[id]);
	}
	KickClient(id, "%t", "UCP_KICKMSG", hw31);
	return 0;
}

public Action:func_25(id, args)
{
	if (args < 1)
	{
		ReplyToCommand(id, "Usage: ucp_unban <UCP ID>");
		return Action:3;
	}
	decl String:arg1[32];
	GetCmdArg(1, arg1, 32);
	if (strlen(arg1) == 8)
	{
		decl String:buffer[512];
		decl String:IDik[12];
		new HANDLE:file = OpenFile(__@175, "r");
		while (!IsEndOfFile(file) && ReadFileLine(file, buffer, 512))
		{
			strcopy(IDik, 9, buffer);
			IDik[2] = MissingTAG:0;
			if (StrEqual(IDik, arg1, false))
			{
				CloseHandle(file);
				func_28(arg1);
				decl String:name[32];
				GetClientName(id, name, 32);
				if (GetConVarInt(hw21))
				{
					LogMessage("%s unbanned %s", name, arg1);
				}
				return Action:3;
			}
		}
		CloseHandle(file);
		ReplyToCommand(id, "Can't found UCPID %s", arg1);
	}
	return Action:3;
}

public Action:func_23(id, args)
{
	if (args < 1)
	{
		ReplyToCommand(id, "Usage: ucp_banid <UCP ID> [time in mins (optional)|0] [reason (optional)]");
		return Action:3;
	}
	decl String:arg1[32];
	decl String:arg2[128];
	decl String:reason[128];
	new BanTime;
	GetCmdArg(1, arg1, 32);
	if (GetCmdArgs() > 1)
	{
		GetCmdArg(2, arg2, 128);
		if (IsCharNumeric(arg2[0]))
		{
			BanTime = StringToInt(arg2, 10);
			if (0 < BanTime)
			{
				BanTime *= 60;
				BanTime = GetTime({0,0}) + BanTime;
			}
			if (GetCmdArgs() > 2)
			{
				GetCmdArg(3, reason, 128);
			}
			reason[0] = MissingTAG:0;
		}
		strcopy(reason, strlen(arg2), arg2);
	}
	decl String:time[32];
	decl String:name[32];
	decl String:buffer[512];
	GetClientName(id, name, 32);
	FormatTime(time, 32, "%m/%d/%Y	%H:%M:%S", GetTime({0,0}));
	ReplyToCommand(id, " - [%s] -> banned!", arg1);
	Format(buffer, 512, "%s	%d	%s	%s	%s	%s	%s", arg1, BanTime, "unknown", "unknown", time, name, reason);
	new HANDLE:file = OpenFile(__@175, "a");
	WriteFileLine(file, buffer);
	CloseHandle(file);
	return Action:3;
}

public Action:func_22(id, args)
{
	if (args < 1)
	{
		ReplyToCommand(id, "Usage: ucp_ban <nick/#userid> [time in mins (optional)|0] [reason (optional)]");
		return Action:3;
	}
	decl String:arg1[32];
	decl String:arg2[128];
	decl String:reason[128];
	new BanTime;
	GetCmdArg(1, arg1, 32);
	new client = FindTarget(id, arg1, false, false);
	if (!client)
	{
		return Action:3;
	}
	if (!IsClientConnected(client))
	{
		return Action:3;
	}
	if (IsFakeClient(client))
	{
		return Action:3;
	}
	reason[0] = MissingTAG:0;
	if (GetCmdArgs() > 1)
	{
		GetCmdArg(2, arg2, 128);
		if (IsCharNumeric(arg2[0]))
		{
			BanTime = StringToInt(arg2, 10);
			if (0 < BanTime)
			{
				BanTime *= 60;
				BanTime = GetTime({0,0}) + BanTime;
			}
			if (GetCmdArgs() > 2)
			{
				GetCmdArg(3, reason, 128);
			}
			reason[0] = MissingTAG:0;
		}
		strcopy(reason, strlen(arg2), arg2);
	}
	decl String:time[32];
	decl String:name[32];
	decl String:uname[32];
	decl String:ip[16];
	decl String:buffer[512];
	GetClientName(id, name, 32);
	GetClientName(client, uname, 32);
	GetClientIP(client, ip, 16, true);
	FormatTime(time, 32, "%m/%d/%Y	%H:%M:%S", GetTime({0,0}));
	ReplyToCommand(id, " - [%s] -> banned!", uname);
	Format(buffer, 512, "%s	%d	%s	%s	%s	%s	%s", __@184[client], BanTime, ip, uname, time, name, reason);
	new HANDLE:file = OpenFile(__@175, "a");
	WriteFileLine(file, buffer);
	CloseHandle(file);
	if (0 < BanTime)
	{
		new BanTimeInfo = GetTime({0,0});
		BanTime -= BanTimeInfo;
		BanTime /= 60;
		KickClient(client, "%t", "UCP_BANTIMEREASONMSG", BanTime, reason);
		return Action:3;
	}
	KickClient(client, "%t", "UCP_BANREASONMSG", reason);
	return Action:3;
}

public Action:func_67(id, args)
{
	CreateTimer(0.5, func_68, any:1, 0);
	return Action:3;
}

public Action:func_29(id, args)
{
	if (args < 1)
	{
		ReplyToCommand(id, "Usage: ucp_screen <nick/#userid>");
		return Action:3;
	}
	decl String:arg1[32];
	GetCmdArg(1, arg1, 32);
	new client = FindTarget(id, arg1, false, false);
	if (!client)
	{
		return Action:3;
	}
	if (!IsClientConnected(client))
	{
		return Action:3;
	}
	if (IsFakeClient(client))
	{
		return Action:3;
	}
	decl String:time[32];
	FormatTime(time, 32, "%Y.%m.%d_%H.%M.%S", GetTime({0,0}));
	ClientCommand(client, "ucp_%s 3%s%s", __@184[client], time, __@174);
	decl String:name[32];
	GetClientName(client, name, 32);
	ReplyToCommand(id, " - [%s] -> screened!", name);
	if (GetCmdArgs() > 1)
	{
		decl String:arg2[32];
		GetCmdArg(2, arg2, 32);
		new par2 = StringToInt(arg2, 10);
		if (par2 > 59)
		{
			CreateTimer(StringToFloat(arg2), func_66, client, 1);
		}
		else
		{
			if (hw37 == 1)
			{
				new String:name2[32];
				new len = strlen(name);
				new i2;
				new i;
				while (i < len)
				{
					new var1;
					if ((name[i] >= 'A' && name[i] <= 'Z') || (name[i] >= 'a' && name[i] <= 'z') || (name[i] >= '0' && name[i] <= '9'))
					{
						name2[i2] = name[i];
						i2++;
					}
					i++;
				}
				name2[i2] = MissingTAG:0;
				if (!name2[0])
				{
					strcopy(name2, 32, "unnamed");
				}
				Format(hw28, 1024, "http://%s:%s%s%s_%s_%s.jpg", hw33, hw29, hw35, name2, __@184[client], time);
				CreateTimer(6.0, func_72, id, 0);
				PrintCenterText(id, "5 seconds..");
			}
		}
	}
	return Action:3;
}

public Action:func_72(Handle:timer, any:userid)
{
	ShowMOTDPanel(userid, "Player Screenshot", hw28, 2);
	return Action:0;
}

bool:func_81(String:file[], line, String:text[], maxlength)
{
	new Handle:hFile = OpenFile(file, "r");
	new i;
	while (line != i)
	{
		ReadFileLine(hFile, text, maxlength);
		if (IsEndOfFile(hFile))
		{
			CloseHandle(hFile);
			return false;
		}
		i++;
	}
	ReadFileLine(hFile, text, maxlength);
	CloseHandle(hFile);
	return true;
}

func_80(String:file[])
{
	new Handle:hFile = OpenFile(file, "r");
	new mlc;
	decl String:buffer[512];
	while (ReadFileLine(hFile, buffer, 512))
	{
		mlc++;
	}
	CloseHandle(hFile);
	return mlc;
}

public Action:func_26(id, args)
{
	decl String:buffer[512];
	ReplyToCommand(id, "------------  BanList  ------------");
	new i = func_80(__@175);
	i--;
	while (i != -1)
	{
		if (func_81(__@175, i, buffer, 512))
		{
			ReplyToCommand(id, buffer);
		}
		i--;
	}
	ReplyToCommand(id, "-----------------------------------");
	return Action:3;
}

public Action:func_10(id, args)
{
	if (GetConVarInt(hw15))
	{
		return Action:3;
	}
	decl String:name[32];
	decl String:autoid[32];
	decl String:ip[16];
	new maxClients = GetMaxClients();
	new i = 1;
	while (i <= maxClients)
	{
		if (IsClientConnected(i))
		{
			if (!(IsFakeClient(i)))
			{
				if (!(GetClientAuthString2(i, autoid, 32)))
				{
					strcopy(autoid, 32, "unsid");
				}
				GetClientName(i, name, 32);
				GetClientIP(i, ip, 16, true);
				ReplyToCommand(id, "%2d  %-16.15s %-20s  %-20s  %s  %s", GetClientUserId(i), name, __@184[i], autoid, ip, __@244[i]);
			}
		}
		i++;
	}
	return Action:3;
}

public Action:func_75(id, args)
{
	if (!GetConVarInt(hw15))
	{
		return Action:3;
	}
	decl String:name[32];
	decl String:autoid[32];
	decl String:ip[16];
	new maxClients = GetMaxClients();
	new i = 1;
	while (i <= maxClients)
	{
		if (IsClientConnected(i))
		{
			if (!(IsFakeClient(i)))
			{
				if (!(GetClientAuthString2(i, autoid, 32)))
				{
					strcopy(autoid, 32, "unsid");
				}
				GetClientName(i, name, 32);
				GetClientIP(i, ip, 16, true);
				ReplyToCommand(id, "%2d  %-16.15s %-20s  %-20s  %s  %s", GetClientUserId(i), name, __@184[i], autoid, ip, __@244[i]);
			}
		}
		i++;
	}
	return Action:3;
}

public OnConfigsExecuted()
{
	if (!hw41)
	{
		return 3;
	}
	GetConVarString(hw05, __@175, 128);
	if (StrEqual(__@175, "0", true))
	{
		strcopy(__@175, 128, "cfg/ucp/banlist.txt");
	}
	SetConVarString(hw01, "8.5", false, false);
	if (!FileExists(__@175, false))
	{
		new HANDLE:file = OpenFile(__@175, "a");
		CloseHandle(file);
	}
	GetConVarString(hw06, __@264, 256);
	GetConVarString(hw02, __@240, 128);
	GetConVarString(hw08, hw31, 1024);
	decl String:mode[16];
	GetConVarString(hw10, hw33, 64);
	GetConVarString(hw13, hw35, 64);
	GetConVarString(hw11, hw29, 8);
	GetConVarString(hw09, mode, 16);
	if (StrEqual(mode, "FTP", false))
	{
		decl String:user[32];
		decl String:pass[32];
		GetConVarString(hw12, user, 32);
		GetConVarString(hw03, pass, 32);
		Format(__@174, 256, "%s*%s*%s*%s*%s*", hw33, hw29, user, pass, hw35);
	}
	else
	{
		hw37 = 1;
		Format(__@174, 256, "%s*%s*%s*", hw33, hw29, hw35);
		new len = strlen(hw35);
		while (len)
		{
			new var1;
			if (StrContains(len + 61852, "/", true) == -1 && StrContains(len + 61852, "\", true) == -1)
			{
				len++;
				len++;
				strcopy(hw35, len, hw35);
			}
			len--;
		}
	}
	if (GetConVarInt(hw07))
	{
		PrintToServer("   %t", "UCP_ENABLED");
	}
	else
	{
		PrintToServer("   %t", "UCP_DISABLED");
	}
	if (!GetConVarInt(hw07))
	{
		return 0;
	}
	return 0;
}

public OnClientAuthorized(id)
{
	new var1;
	if (!IsClientConnected(id) || IsFakeClient(id) || !GetConVarInt(hw07) || !GetConVarInt(hw50))
	{
		return 0;
	}
	decl String:sName[68];
	GetClientName(id, sName, 65);
	if (__@180[id] == 1)
	{
		tag_add(id, sName);
	}
	else
	{
		tag_del(id, sName);
	}
	return 0;
}

public tag_add(id, name[])
{
	if (GetConVarInt(hw51))
	{
		ReplaceString(name, strlen(name), "[NO-UCP]", "", true);
		TrimString(name);
		if (strlen(name) < 4)
		{
			FormatTime(name, 64, "Player %M%S", GetTime({0,0}));
		}
		Format(name, 64, "[NO-UCP] %s", name);
		SetClientInfo(id, "name", name);
	}
	return 0;
}

public tag_del(id, name[])
{
	if (StrContains(name, "[NO-UCP]", true) != -1)
	{
		ReplaceString(name, strlen(name), "[NO-UCP]", "", true);
		TrimString(name);
		if (!name[0])
		{
			FormatTime(name, 64, "Player %M%S", GetTime({0,0}));
		}
		SetClientInfo(id, "name", name);
	}
	return 0;
}

public OnClientPutInServer(id)
{
	new var1;
	if (!IsClientConnected(id) || IsFakeClient(id) || !GetConVarInt(hw07) || __@183[id])
	{
		return 0;
	}
	new var2;
	if (hw16 == Handle:4 || hw16 == Handle:5)
	{
		CreateTimer(10.0, func_73, id, 0);
	}
	if (__@180[id] == 1)
	{
		decl String:lb1[36];
		decl String:lb2[16];
		decl String:lb3[36];
		GetClientName(id, lb1, 34);
		GetClientIP(id, lb2, 16, true);
		GetClientAuthString(id, lb3, 34);
		if (GetConVarInt(hw21))
		{
			LogMessage("Login no-ucp: %s | %s | %s", lb1, lb2, lb3);
		}
	}
	else
	{
		new var3;
		if (__@181[id] || __@182[id])
		{
			__@186[id] = 1;
			return 0;
		}
		__@307[id] = __@250_;
		CreateTimer(0.1, func_33, id + 34875375, 1);
	}
	return 0;
}

public Action:func_73(Handle:timer, any:id)
{
	new var1;
	if (!IsClientConnected(id) || IsFakeClient(id))
	{
		return Action:0;
	}
	func_21(id, 0);
	return Action:0;
}

public Action:func_33(Handle:timer, any:id)
{
	new tid = id + -34875375;
	new var1;
	if (!IsClientConnected(tid) || IsFakeClient(tid) || !GetConVarInt(hw04))
	{
		return Action:0;
	}
	if (0 < __@307[tid])
	{
		__@307[tid]--;
		ClientCommand(tid, "ucp_%s 9%s", __@184[tid], __@250[__@307[tid]]);
		return Action:0;
	}
	KillTimer(timer, false);
	return Action:0;
}

public Action:func_34(Handle:timer, any:id)
{
	new var1;
	if (!IsClientConnected(id) || IsFakeClient(id))
	{
		return Action:0;
	}
	decl String:lb1[128];
	GetClientName(id, lb1, 128);
	new i = 64;
	i--;
	while (i != -1)
	{
		if (StrEqual(lb1, hw34[i], true))
		{
			strcopy(hw34[i], strlen(hw34[i]), "unk");
			ClientCommand(id, "ucp_%s a1", __@184[id]);
			CreateTimer(4.5, func_34_2, id, 0);
			return Action:0;
		}
		i--;
	}
	strcopy(hw34[id], 128, lb1);
	ClientCommand(id, "retry", __@184[id]);
	return Action:0;
}

public Action:func_34_2(Handle:timer, any:id)
{
	new var1;
	if (!IsClientConnected(id) || IsFakeClient(id))
	{
		return Action:0;
	}
	KickClient(id, "%t", "UCP_UPDATEMSG");
	return Action:0;
}

public OnClientConnected(id)
{
	__@184[id][0] = MissingTAG:0;
	__@179[id] = 0;
	__@186[id] = 0;
	__@307[id] = 0;
	__@180[id] = 1;
	__@181[id] = 1;
	__@182[id] = 1;
	if (GetConVarInt(hw07))
	{
		__@183[id] = 0;
		GetClientInfo(id, "ucp_id", __@185[id], 12);
		if (strlen(__@185[id]) == 11)
		{
			strcopy(__@184[id], 11, __@185[id]);
			__@184[id][2] = MissingTAG:0;
			new i;
			while (i < 8)
			{
				new var1;
				if (!((__@184[id][i] >= 'A' && __@184[id][i] <= 'Z') || (__@184[id][i] >= '0' && __@184[id][i] <= '9')))
				{
					return 0;
				}
				i++;
			}
			decl String:l_@11[512];
			decl String:l_@10[12];
			decl String:l_@12[128];
			new b;
			new HANDLE:file = OpenFile(__@175, "rt");
			if (file != HANDLE:-1)
			{
				while (!IsEndOfFile(file) && ReadFileLine(file, l_@11, 512))
				{
					strcopy(l_@10, 9, l_@11);
					l_@10[2] = MissingTAG:0;
					if (StrEqual(l_@10, __@184[id], true))
					{
						b = StrContains(l_@11[2], "	", true);
						new len = strlen(l_@11);
						while (len)
						{
							if (StrContains(l_@11[len], "	", true) != -1)
							{
								len++;
								strcopy(l_@12, 128, l_@11[len]);
								l_@11[b + 9] = MissingTAG:0;
								b = StringToInt(l_@11[2], 10);
								if (b)
								{
									new l_@9 = GetTime({0,0});
									if (l_@9 < b)
									{
										b -= l_@9;
										b /= 60;
										KickClient(id, "%t", "UCP_BANTIMEREASONMSG", b, l_@12);
										CloseHandle(file);
										return 0;
									}
									CloseHandle(file);
									file = MissingTAG:-1;
									func_28(__@184[id]);
									CloseHandle(file);
								}
								KickClient(id, "%t", "UCP_BANREASONMSG", l_@12);
								CloseHandle(file);
								return 0;
							}
							len--;
						}
						strcopy(l_@12, 128, l_@11[len]);
						l_@11[b + 9] = MissingTAG:0;
						b = StringToInt(l_@11[2], 10);
						if (b)
						{
							new l_@9 = GetTime({0,0});
							if (l_@9 < b)
							{
								b -= l_@9;
								b /= 60;
								KickClient(id, "%t", "UCP_BANTIMEREASONMSG", b, l_@12);
								CloseHandle(file);
								return 0;
							}
							CloseHandle(file);
							file = MissingTAG:-1;
							func_28(__@184[id]);
							CloseHandle(file);
						}
						KickClient(id, "%t", "UCP_BANREASONMSG", l_@12);
						CloseHandle(file);
						return 0;
					}
				}
				CloseHandle(file);
			}
			__@180[id] = 0;
			new k = __@270_;
			k--;
			while (k != -1)
			{
				ClientCommand(id, "ucp_%s 0%s", __@184[id], __@270[k]);
				k--;
			}
			func_40(id);
		}
		else
		{
			if (GetConVarInt(hw40) == 1)
			{
				func_16(id);
			}
		}
		return 0;
	}
	__@183[id] = 1;
	return 0;
}

public func_40(id)
{
	ClientCommand(id, "ucp_%s 1%d%d%s %s %s", __@184[id], GetConVarInt(hw04), 1, __@14, __@177, __@240);
	return 0;
}

public OnClientDisconnect(id)
{
	if (!GetConVarInt(hw07))
	{
		return 0;
	}
	__@184[id][0] = MissingTAG:0;
	__@183[id] = 0;
	__@185[id][0] = MissingTAG:0;
	__@186[id] = 0;
	return 0;
}

public func_28(String:reason[])
{
	if (FileExists(hw25, false))
	{
		DeleteFile(hw25);
	}
	new HANDLE:file1 = OpenFile(__@175, "r");
	new HANDLE:file2 = OpenFile(hw25, "a");
	decl String:lb1[512];
	decl String:lb2[12];
	while (!IsEndOfFile(file1) && ReadFileLine(file1, lb1, 512))
	{
		strcopy(lb2, 9, lb1);
		lb2[2] = MissingTAG:0;
		if (!StrEqual(lb2, reason, false))
		{
			strcopy(lb1, strlen(lb1), lb1);
			WriteFileLine(file2, lb1);
		}
	}
	CloseHandle(file1);
	CloseHandle(file2);
	DeleteFile(__@175);
	if (FileExists(__@175, false))
	{
		ReplyToCommand(0, "Can't delete %s", __@175);
	}
	else
	{
		RenameFile(__@175, hw25);
	}
	return 0;
}

md5_file(String:fileName[], String:output[])
{
	decl x[2];
	decl buf[4];
	decl input[64];
	new str[1024];
	new i;
	new ii;
	new in[16];
	new mdi;
	new len = strlen(str);
	x[1] = 0;
	x[0] = 0;
	buf[0] = 1732584193;
	buf[1] = -271733879;
	buf[2] = -1732584194;
	buf[3] = 271733878;
	new c;
	new HANDLE:hFile = OpenFile(fileName, "rb");
	while ((len = ReadFile(hFile, str, 1024, 1)))
	{
		if (!(len == -1))
		{
			in[14] = x[0];
			in[15] = x[1];
			mdi = x[0] >> 3 & 63;
			if (x[0] > len << 3 + x[0])
			{
				x[1] += 1;
			}
			x[0] = len << 3 + x[0];
			new var2 = x[1];
			var2 = len >> 29 + var2;
			c = 0;
			len--;
			while (len)
			{
				input[mdi] = str[c];
				mdi += 1;
				c += 1;
				if (mdi == 64)
				{
					i = 0;
					ii = 0;
					while (i < 16)
					{
						in[i] = input[ii] | input[ii + 1] << 8 | input[ii + 2] << 16 | input[ii + 3] << 24;
						i++;
						ii += 4;
					}
					MD5Transform(buf, in);
					mdi = 0;
				}
			}
		}
		CloseHandle(hFile);
		new padding[64];
		new inx[16];
		inx[14] = x[0];
		inx[15] = x[1];
		mdi = x[0] >> 3 & 63;
		new var1;
		if (mdi < 56)
		{
			var1 = 56 - mdi;
		}
		else
		{
			var1 = 120 - mdi;
		}
		len = var1;
		in[14] = x[0];
		in[15] = x[1];
		mdi = x[0] >> 3 & 63;
		if (x[0] > len << 3 + x[0])
		{
			x[1] += 1;
		}
		x[0] = len << 3 + x[0];
		new var3 = x[1];
		var3 = len >> 29 + var3;
		c = 0;
		len--;
		while (len)
		{
			input[mdi] = padding[c];
			mdi += 1;
			c += 1;
			if (mdi == 64)
			{
				i = 0;
				ii = 0;
				while (i < 16)
				{
					in[i] = input[ii] | input[ii + 1] << 8 | input[ii + 2] << 16 | input[ii + 3] << 24;
					i++;
					ii += 4;
				}
				MD5Transform(buf, in);
				mdi = 0;
			}
		}
		i = 0;
		ii = 0;
		while (i < 14)
		{
			inx[i] = input[ii] | input[ii + 1] << 8 | input[ii + 2] << 16 | input[ii + 3] << 24;
			i++;
			ii += 4;
		}
		MD5Transform(buf, inx);
		new digest[16];
		i = 0;
		ii = 0;
		while (i < 4)
		{
			digest[ii] = buf[i] & 255;
			digest[ii + 1] = buf[i] >> 8 & 255;
			digest[ii + 2] = buf[i] >> 16 & 255;
			digest[ii + 3] = buf[i] >> 24 & 255;
			i++;
			ii += 4;
		}
		FormatEx(output, 33, "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", digest, digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7], digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]);
		output[2] = MissingTAG:0;
		output[0] = CharToUpper(output[0]);
		output[0] = CharToUpper(output[0]);
		output[0] = CharToUpper(output[0]);
		output[0] = CharToUpper(output[0]);
		output[1] = CharToUpper(output[1]);
		output[1] = CharToUpper(output[1]);
		output[1] = CharToUpper(output[1]);
		output[1] = CharToUpper(output[1]);
		return 0;
	}
	CloseHandle(hFile);
	new padding[64];
	new inx[16];
	inx[14] = x[0];
	inx[15] = x[1];
	mdi = x[0] >> 3 & 63;
	new var1;
	if (mdi < 56)
	{
		var1 = 56 - mdi;
	}
	else
	{
		var1 = 120 - mdi;
	}
	len = var1;
	in[14] = x[0];
	in[15] = x[1];
	mdi = x[0] >> 3 & 63;
	if (x[0] > len << 3 + x[0])
	{
		x[1] += 1;
	}
	x[0] = len << 3 + x[0];
	new var3 = x[1];
	var3 = len >> 29 + var3;
	c = 0;
	len--;
	while (len)
	{
		input[mdi] = padding[c];
		mdi += 1;
		c += 1;
		if (mdi == 64)
		{
			i = 0;
			ii = 0;
			while (i < 16)
			{
				in[i] = input[ii] | input[ii + 1] << 8 | input[ii + 2] << 16 | input[ii + 3] << 24;
				i++;
				ii += 4;
			}
			MD5Transform(buf, in);
			mdi = 0;
		}
	}
	i = 0;
	ii = 0;
	while (i < 14)
	{
		inx[i] = input[ii] | input[ii + 1] << 8 | input[ii + 2] << 16 | input[ii + 3] << 24;
		i++;
		ii += 4;
	}
	MD5Transform(buf, inx);
	new digest[16];
	i = 0;
	ii = 0;
	while (i < 4)
	{
		digest[ii] = buf[i] & 255;
		digest[ii + 1] = buf[i] >> 8 & 255;
		digest[ii + 2] = buf[i] >> 16 & 255;
		digest[ii + 3] = buf[i] >> 24 & 255;
		i++;
		ii += 4;
	}
	FormatEx(output, 33, "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", digest, digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7], digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]);
	output[2] = MissingTAG:0;
	output[0] = CharToUpper(output[0]);
	output[0] = CharToUpper(output[0]);
	output[0] = CharToUpper(output[0]);
	output[0] = CharToUpper(output[0]);
	output[1] = CharToUpper(output[1]);
	output[1] = CharToUpper(output[1]);
	output[1] = CharToUpper(output[1]);
	output[1] = CharToUpper(output[1]);
	return 0;
}

md5(String:str[], String:output[], maxlen)
{
	decl x[2];
	decl buf[4];
	decl input[64];
	new i;
	new ii;
	new len = strlen(str);
	x[1] = 0;
	x[0] = 0;
	buf[0] = 1732584193;
	buf[1] = -271733879;
	buf[2] = -1732584194;
	buf[3] = 271733878;
	new in[16];
	in[14] = x[0];
	in[15] = x[1];
	new mdi = x[0] >> 3 & 63;
	if (x[0] > len << 3 + x[0])
	{
		x[1] += 1;
	}
	x[0] = len << 3 + x[0];
	new var2 = x[1];
	var2 = len >> 29 + var2;
	new c;
	len--;
	while (len)
	{
		input[mdi] = str[c];
		mdi += 1;
		c += 1;
		if (mdi == 64)
		{
			i = 0;
			ii = 0;
			while (i < 16)
			{
				in[i] = input[ii] | input[ii + 1] << 8 | input[ii + 2] << 16 | input[ii + 3] << 24;
				i++;
				ii += 4;
			}
			MD5Transform(buf, in);
			mdi = 0;
		}
	}
	new padding[64];
	new inx[16];
	inx[14] = x[0];
	inx[15] = x[1];
	mdi = x[0] >> 3 & 63;
	new var1;
	if (mdi < 56)
	{
		var1 = 56 - mdi;
	}
	else
	{
		var1 = 120 - mdi;
	}
	len = var1;
	in[14] = x[0];
	in[15] = x[1];
	mdi = x[0] >> 3 & 63;
	if (x[0] > len << 3 + x[0])
	{
		x[1] += 1;
	}
	x[0] = len << 3 + x[0];
	new var3 = x[1];
	var3 = len >> 29 + var3;
	c = 0;
	len--;
	while (len)
	{
		input[mdi] = padding[c];
		mdi += 1;
		c += 1;
		if (mdi == 64)
		{
			i = 0;
			ii = 0;
			while (i < 16)
			{
				in[i] = input[ii] | input[ii + 1] << 8 | input[ii + 2] << 16 | input[ii + 3] << 24;
				i++;
				ii += 4;
			}
			MD5Transform(buf, in);
			mdi = 0;
		}
	}
	i = 0;
	ii = 0;
	while (i < 14)
	{
		inx[i] = input[ii] | input[ii + 1] << 8 | input[ii + 2] << 16 | input[ii + 3] << 24;
		i++;
		ii += 4;
	}
	MD5Transform(buf, inx);
	new digest[16];
	i = 0;
	ii = 0;
	while (i < 4)
	{
		digest[ii] = buf[i] & 255;
		digest[ii + 1] = buf[i] >> 8 & 255;
		digest[ii + 2] = buf[i] >> 16 & 255;
		digest[ii + 3] = buf[i] >> 24 & 255;
		i++;
		ii += 4;
	}
	FormatEx(output, maxlen, "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", digest, digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7], digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]);
	return 0;
}

MD5Transform_FF(&a, &b, &c, &d, x, s, ac)
{
	a = d & ~b | c & b + x + ac + a;
	a = a >> 32 - s | a << s;
	a = b + a;
	return 0;
}

MD5Transform_GG(&a, &b, &c, &d, x, s, ac)
{
	a = ~d & c | d & b + x + ac + a;
	a = a >> 32 - s | a << s;
	a = b + a;
	return 0;
}

MD5Transform_HH(&a, &b, &c, &d, x, s, ac)
{
	a = d ^ c ^ b + x + ac + a;
	a = a >> 32 - s | a << s;
	a = b + a;
	return 0;
}

MD5Transform_II(&a, &b, &c, &d, x, s, ac)
{
	a = ~d | b ^ c + x + ac + a;
	a = a >> 32 - s | a << s;
	a = b + a;
	return 0;
}

MD5Transform(buf[], in[])
{
	new a = buf[0];
	new b = buf[1];
	new c = buf[2];
	new d = buf[3];
	MD5Transform_FF(a, b, c, d, in[0], 7, -680876936);
	MD5Transform_FF(d, a, b, c, in[1], 12, -389564586);
	MD5Transform_FF(c, d, a, b, in[2], 17, 606105819);
	MD5Transform_FF(b, c, d, a, in[3], 22, -1044525330);
	MD5Transform_FF(a, b, c, d, in[4], 7, -176418897);
	MD5Transform_FF(d, a, b, c, in[5], 12, 1200080426);
	MD5Transform_FF(c, d, a, b, in[6], 17, -1473231341);
	MD5Transform_FF(b, c, d, a, in[7], 22, -45705983);
	MD5Transform_FF(a, b, c, d, in[8], 7, 1770035416);
	MD5Transform_FF(d, a, b, c, in[9], 12, -1958414417);
	MD5Transform_FF(c, d, a, b, in[10], 17, -42063);
	MD5Transform_FF(b, c, d, a, in[11], 22, -1990404162);
	MD5Transform_FF(a, b, c, d, in[12], 7, 1804603682);
	MD5Transform_FF(d, a, b, c, in[13], 12, -40341101);
	MD5Transform_FF(c, d, a, b, in[14], 17, -1502002290);
	MD5Transform_FF(b, c, d, a, in[15], 22, 1236535329);
	MD5Transform_GG(a, b, c, d, in[1], 5, -165796510);
	MD5Transform_GG(d, a, b, c, in[6], 9, -1069501632);
	MD5Transform_GG(c, d, a, b, in[11], 14, 643717713);
	MD5Transform_GG(b, c, d, a, in[0], 20, -373897302);
	MD5Transform_GG(a, b, c, d, in[5], 5, -701558691);
	MD5Transform_GG(d, a, b, c, in[10], 9, 38016083);
	MD5Transform_GG(c, d, a, b, in[15], 14, -660478335);
	MD5Transform_GG(b, c, d, a, in[4], 20, -405537848);
	MD5Transform_GG(a, b, c, d, in[9], 5, 568446438);
	MD5Transform_GG(d, a, b, c, in[14], 9, -1019803690);
	MD5Transform_GG(c, d, a, b, in[3], 14, -187363961);
	MD5Transform_GG(b, c, d, a, in[8], 20, 1163531501);
	MD5Transform_GG(a, b, c, d, in[13], 5, -1444681467);
	MD5Transform_GG(d, a, b, c, in[2], 9, -51403784);
	MD5Transform_GG(c, d, a, b, in[7], 14, 1735328473);
	MD5Transform_GG(b, c, d, a, in[12], 20, -1926607734);
	MD5Transform_HH(a, b, c, d, in[5], 4, -378558);
	MD5Transform_HH(d, a, b, c, in[8], 11, -2022574463);
	MD5Transform_HH(c, d, a, b, in[11], 16, 1839030562);
	MD5Transform_HH(b, c, d, a, in[14], 23, -35309556);
	MD5Transform_HH(a, b, c, d, in[1], 4, -1530992060);
	MD5Transform_HH(d, a, b, c, in[4], 11, 1272893353);
	MD5Transform_HH(c, d, a, b, in[7], 16, -155497632);
	MD5Transform_HH(b, c, d, a, in[10], 23, -1094730640);
	MD5Transform_HH(a, b, c, d, in[13], 4, 681279174);
	MD5Transform_HH(d, a, b, c, in[0], 11, -358537222);
	MD5Transform_HH(c, d, a, b, in[3], 16, -722521979);
	MD5Transform_HH(b, c, d, a, in[6], 23, 76029189);
	MD5Transform_HH(a, b, c, d, in[9], 4, -640364487);
	MD5Transform_HH(d, a, b, c, in[12], 11, -421815835);
	MD5Transform_HH(c, d, a, b, in[15], 16, 530742520);
	MD5Transform_HH(b, c, d, a, in[2], 23, -995338651);
	MD5Transform_II(a, b, c, d, in[0], 6, -198630844);
	MD5Transform_II(d, a, b, c, in[7], 10, 1126891415);
	MD5Transform_II(c, d, a, b, in[14], 15, -1416354905);
	MD5Transform_II(b, c, d, a, in[5], 21, -57434055);
	MD5Transform_II(a, b, c, d, in[12], 6, 1700485571);
	MD5Transform_II(d, a, b, c, in[3], 10, -1894986606);
	MD5Transform_II(c, d, a, b, in[10], 15, -1051523);
	MD5Transform_II(b, c, d, a, in[1], 21, -2054922799);
	MD5Transform_II(a, b, c, d, in[8], 6, 1873313359);
	MD5Transform_II(d, a, b, c, in[15], 10, -30611744);
	MD5Transform_II(c, d, a, b, in[6], 15, -1560198380);
	MD5Transform_II(b, c, d, a, in[13], 21, 1309151649);
	MD5Transform_II(a, b, c, d, in[4], 6, -145523070);
	MD5Transform_II(d, a, b, c, in[11], 10, -1120210379);
	MD5Transform_II(c, d, a, b, in[2], 15, 718787259);
	MD5Transform_II(b, c, d, a, in[9], 21, -343485551);
	new var1 = buf;
	var1[0] = var1[0] + a;
	buf[1] += b;
	buf[2] += c;
	buf[3] += d;
	return 0;
}

public func_38(String:sString[])
{
	new cFillChar = 61;
	new resPos;
	new len = 64;
	new nLength = strlen(sString);
	new String:sResult[64];
	new nPos;
	while (nPos < nLength)
	{
		new cCode = sString[nPos] >>> 2 & 63;
		resPos = FormatEx(sResult[resPos], len - resPos, "%c", cCode + 828) + resPos;
		cCode = sString[nPos] << 4 & 63;
		nPos++;
		if (nPos < nLength)
		{
			cCode = sString[nPos] >>> 4 & 15 | cCode;
		}
		resPos = FormatEx(sResult[resPos], len - resPos, "%c", cCode + 828) + resPos;
		if (nPos < nLength)
		{
			cCode = sString[nPos] << 2 & 63;
			nPos++;
			if (nPos < nLength)
			{
				cCode = sString[nPos] >>> 6 & 3 | cCode;
			}
			resPos = FormatEx(sResult[resPos], len - resPos, "%c", cCode + 828) + resPos;
		}
		else
		{
			nPos++;
			resPos = FormatEx(sResult[resPos], len - resPos, "%c", cFillChar) + resPos;
		}
		if (nPos < nLength)
		{
			cCode = sString[nPos] & 63;
			resPos = FormatEx(sResult[resPos], len - resPos, "%c", cCode + 828) + resPos;
		}
		else
		{
			resPos = FormatEx(sResult[resPos], len - resPos, "%c", cFillChar) + resPos;
		}
		nPos++;
	}
	strcopy(sString, 64, sResult);
	return 0;
}

public func_37(String:wh32[], wh30)
{
	new i;
	while (i < wh30)
	{
		new var13 = hw32;
		new var1;
		if ((var13[0][var13] != wh32[i] && wh32[i] > var14[0][var14]) && (hw32[2] != wh32[i] && wh32[i] < hw32[2]))
		{
			new var4;
			if (hw32[1] != wh32[i] && wh32[i] > hw32[1])
			{
				wh32[i]--;
				wh32[i]--;
				wh32[i]--;
				wh32[i]--;
				wh32[i]--;
				wh32[i]--;
				wh32[i]--;
				wh32[i]--;
				wh32[i]--;
				wh32[i]--;
				wh32[i]--;
				wh32[i]--;
				wh32[i]--;
			}
			else
			{
				wh32[i]++;
				wh32[i]++;
				wh32[i]++;
				wh32[i]++;
				wh32[i]++;
				wh32[i]++;
				wh32[i]++;
				wh32[i]++;
				wh32[i]++;
				wh32[i]++;
				wh32[i]++;
				wh32[i]++;
				wh32[i]++;
			}
		}
		else
		{
			new var15 = hw30;
			new var5;
			if ((var15[0][var15] != wh32[i] && wh32[i] > var16[0][var16]) && (hw30[2] != wh32[i] && wh32[i] < hw30[2]))
			{
				new var8;
				if (hw30[1] != wh32[i] && wh32[i] > hw30[1])
				{
					wh32[i]--;
					wh32[i]--;
					wh32[i]--;
					wh32[i]--;
					wh32[i]--;
					wh32[i]--;
					wh32[i]--;
					wh32[i]--;
					wh32[i]--;
					wh32[i]--;
					wh32[i]--;
					wh32[i]--;
					wh32[i]--;
				}
				else
				{
					wh32[i]++;
					wh32[i]++;
					wh32[i]++;
					wh32[i]++;
					wh32[i]++;
					wh32[i]++;
					wh32[i]++;
					wh32[i]++;
					wh32[i]++;
					wh32[i]++;
					wh32[i]++;
					wh32[i]++;
					wh32[i]++;
				}
			}
			new var17 = hw27;
			new var9;
			if ((var17[0][var17] != wh32[i] && wh32[i] > var18[0][var18]) && (hw27[2] != wh32[i] && wh32[i] < hw27[2]))
			{
				new var12;
				if (hw27[1] != wh32[i] && wh32[i] > hw27[1])
				{
					wh32[i]--;
					wh32[i]--;
					wh32[i]--;
					wh32[i]--;
					wh32[i]--;
				}
				wh32[i]++;
				wh32[i]++;
				wh32[i]++;
				wh32[i]++;
				wh32[i]++;
			}
		}
		i++;
	}
	return 0;
}

public Action:func_70(Handle:timer, any:id)
{
	new var1;
	if (!IsClientConnected(id) || IsFakeClient(id) || !GetConVarInt(hw07))
	{
		return Action:0;
	}
	new i = __@297_;
	i--;
	while (i != -1)
	{
		if (__@297[i][0] == 'P')
		{
			if (__@297[i][1] == 'M')
			{
				ClientCommand(id, "ucp_%s \"%s%s\"", __@184[id], "51", __@297[i][1]);
			}
			if (__@297[i][1] == 'K')
			{
				ClientCommand(id, "ucp_%s \"%s%s\"", __@184[id], "52", __@297[i][1]);
			}
			if (__@297[i][1] == 'B')
			{
				ClientCommand(id, "ucp_%s \"%s%s\"", __@184[id], "53", __@297[i][1]);
			}
		}
		if (__@297[i][0] == 'W')
		{
			if (__@297[i][1] == 'M')
			{
				ClientCommand(id, "ucp_%s \"%s%s\"", __@184[id], "61", __@297[i][1]);
			}
			if (__@297[i][1] == 'K')
			{
				ClientCommand(id, "ucp_%s \"%s%s\"", __@184[id], "62", __@297[i][1]);
			}
			if (__@297[i][1] == 'B')
			{
				ClientCommand(id, "ucp_%s \"%s%s\"", __@184[id], "63", __@297[i][1]);
			}
		}
		if (__@297[i][0] == 'S')
		{
			if (__@297[i][1] == 'M')
			{
				ClientCommand(id, "ucp_%s \"%s%s\"", __@184[id], "71", __@297[i][1]);
			}
			if (__@297[i][1] == 'B')
			{
				ClientCommand(id, "ucp_%s \"%s%s\"", __@184[id], "73", __@297[i][1]);
			}
		}
		if (__@297[i][0] == 'D')
		{
			if (__@297[i][1] == 'M')
			{
				ClientCommand(id, "ucp_%s \"%s%s\"", __@184[id], "81", __@297[i][1]);
			}
			if (__@297[i][1] == 'B')
			{
				ClientCommand(id, "ucp_%s \"%s%s\"", __@184[id], "83", __@297[i][1]);
			}
		}
		if (__@297[i][0] == 'L')
		{
			if (__@297[i][1] == 'M')
			{
				ClientCommand(id, "ucp_%s \"%s%s\"", __@184[id], "c1", __@297[i][1]);
			}
			if (__@297[i][1] == 'B')
			{
				ClientCommand(id, "ucp_%s \"%s%s\"", __@184[id], "c3", __@297[i][1]);
			}
		}
		if (__@297[i][0] == 'O')
		{
			if (__@297[i][1] == 'R')
			{
				ClientCommand(id, "ucp_%s \"%s%s\"", __@184[id], "o1", __@297[i][1]);
			}
			if (__@297[i][1] == 'W')
			{
				ClientCommand(id, "ucp_%s \"%s%s\"", __@184[id], "o0", __@297[i][1]);
			}
		}
		i--;
	}
	if (GetConVarInt(hw20) >= 60)
	{
		decl String:DetectTimeOut[16];
		GetConVarString(hw20, DetectTimeOut, 16);
		CreateTimer(StringToFloat(DetectTimeOut), func_70, id, 0);
	}
	return Action:0;
}

public func_69(Handle:plugin, numParams)
{
	new lb6 = GetNativeCell(1);
	if (strlen(__@184[lb6]))
	{
		new String:lb1[36];
		new String:lb2[36];
		new String:lb3[32];
		new lb5;
		md5(__@184[lb6], lb2, 34);
		new lb4 = strlen(lb2);
		new lb7;
		while (lb7 < lb4)
		{
			new var1;
			if (lb2[lb7] >= '0' && lb2[lb7] <= '9')
			{
				lb3[lb5] = lb2[lb7];
				lb5++;
			}
			lb7++;
		}
		lb3[2] = MissingTAG:0;
		FormatEx(lb1, 34, "STEAM_0:0:%s", lb3);
		SetNativeString(2, lb1, 19, true, 0);
		return 1;
	}
	SetNativeString(2, "STEAM_ID_LAN", 13, true, 0);
	return 0;
}

public Action:func_68(Handle:timer, any:id)
{
	if (!GetConVarInt(hw07))
	{
		return Action:0;
	}
	new lw43 = id;
	new maxClients = GetMaxClients();
	new i = 1;
	while (i <= maxClients)
	{
		if (lw43 == i)
		{
			if (!IsClientConnected(i))
			{
				return Action:0;
			}
			if (IsFakeClient(i))
			{
				return Action:0;
			}
			decl String:time[32];
			FormatTime(time, 32, "%Y.%m.%d_%H.%M.%S", GetTime({0,0}));
			ClientCommand(i, "ucp_%s 3%s%s", __@184[i], time, __@174);
		}
		i++;
	}
	if (lw43 <= 32)
	{
		lw43++;
		CreateTimer(0.5, func_68, lw43, 0);
	}
	return Action:0;
}

public Action:func_66(Handle:timer, any:id)
{
	new var1;
	if (!IsClientConnected(id) || IsFakeClient(id) || !GetConVarInt(hw07))
	{
		KillTimer(timer, false);
		return Action:0;
	}
	decl String:time[32];
	FormatTime(time, 32, "%Y.%m.%d_%H.%M.%S", GetTime({0,0}));
	ClientCommand(id, "ucp_%s 3%s%s", __@184[id], time, __@174);
	return Action:0;
}

