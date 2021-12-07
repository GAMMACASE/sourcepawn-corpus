#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

ConVar HealUnstuck;

public Plugin myinfo =
{
    name = "[L4D/L4D2] Heal Fixes",
    author = "MasterMind420",
    description = "",
    version = "1.2",
    url = ""
};

public void OnPluginStart()
{
	HealUnstuck = CreateConVar("l4d_heal_unstuck", "1", "1-Enable Heal Unstuck 0-Disable Heal Unstuck(default healing behavior)", FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d_heal_fixes");
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(IsValidClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		int target = GetEntPropEnt(client, Prop_Send, "m_useActionTarget");

		if(IsValidClient(target))
		{
			//PrintToChat(client, "UseAction %i", GetEntProp(client, Prop_Send, "m_iCurrentUseAction"));

			int aWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

			if(IsValidEntity(aWeapon))
			{
				char sClsName[32];
				GetEntityClassname(aWeapon, sClsName, sizeof(sClsName));

				if(StrContains(sClsName, "first_aid_kit") > -1)
				{
					//REVIVE HEAL BUG FIX
					if(client == target)
					{
						if(GetEntPropEnt(client, Prop_Send, "m_reviveTarget") > 0)
						{
							buttons &= ~1;
							return Plugin_Changed;
						}

						return Plugin_Continue;
					}

					//HEAL OTHER STUCK WORKAROUND
					if(GetConVarInt(HealUnstuck) == 1)
					{
						switch(buttons)
						{
							case 2048:
							{
								switch(GetClientButtons(target))
								{
									case 8, 16, 512, 520, 528, 1024, 1032, 1040,
										9, 17, 513, 521, 529, 1025, 1033, 1041,
										2056, 2064, 2560, 2568, 2576, 3072, 3080, 3088:
									{
										SetEntPropFloat(aWeapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 1.0);

										buttons &= ~2048;
										return Plugin_Changed;
									}
								}
							}
						}
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}