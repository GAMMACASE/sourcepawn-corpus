/////////////////////////////////////////////////////////////////////
//
// �C���N���[�h
//
/////////////////////////////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include "rmf/tf2_codes"
#include "rmf/tf2_events"


/////////////////////////////////////////////////////////////////////
//
// �萔
//
/////////////////////////////////////////////////////////////////////
#define PL_NAME "Fake Death"
#define PL_DESC "Fake Death"
#define PL_VERSION "1.1.2"

// �X�p�C
#define SOUND_EMPTY "misc/talk.wav"
#define SOUND_DISSOLVE "player/pl_impact_flare3.wav"

/////////////////////////////////////////////////////////////////////
//
// MOD���
//
/////////////////////////////////////////////////////////////////////
public Plugin:myinfo = 
{
	name = PL_NAME,
	author = "RIKUSYO",
	description = PL_DESC,
	version = PL_VERSION,
	url = "http://ameblo.jp/rikusyo/"
}


/////////////////////////////////////////////////////////////////////
//
// �O���[�o���ϐ�
//
/////////////////////////////////////////////////////////////////////

new Handle:g_UseCloakMeter = INVALID_HANDLE;				// ConVar�t�F�C�N�f�X�N���[�N���[�^�[�g�p��
new Handle:g_WaitTime = INVALID_HANDLE;						// ConVar�t�F�C�N�f�X���̎��̂��o���܂ł̊Ԋu
new Handle:g_Dissolve = INVALID_HANDLE;						// ConVar�t�F�C�N�f�X�U���̏������邩�ǂ���
new Handle:g_DissolveTime = INVALID_HANDLE;					// ConVar�t�F�C�N�f�X�U���̏����܂ł̎���
new Handle:g_DissolveType = INVALID_HANDLE;					// ConVar�t�F�C�N�f�X�U���̏����^�C�v
new Handle:g_DissolveUncloak = INVALID_HANDLE;				// ConVar�t�F�C�N�f�X���������ŋU���̏������邩�ǂ���

new bool:g_PlayerGib[MAXPLAYERS+1];							// ���E�H
new Handle:g_NextBody[MAXPLAYERS+1] = INVALID_HANDLE;		// ���̎��̂܂ł̃^�C�}�[
new Handle:g_HitClear[MAXPLAYERS+1] = INVALID_HANDLE;   	// �q�b�g�f�[�^�̃^�C�}�[
new Handle:g_DissolveFakeBody[MAXPLAYERS+1] = INVALID_HANDLE;	// �U���̏����܂ł̎���
new g_Ragdoll[MAXPLAYERS+1] = -1;   						// �U����

new String:g_PainVoice[5][32];								// ���Ƀ{�C�X

/////////////////////////////////////////////////////////////////////
//
// �C�x���g����
//
/////////////////////////////////////////////////////////////////////
stock Action:Event_FiredUser(Handle:event, const String:name[], any:client=0)
{
	
	// �v���O�C���J�n
	if(StrEqual(name, EVENT_PLUGIN_START))
	{
		// ����t�@�C���Ǎ�
		LoadTranslations("fakedeath.phrases");

		// �R�}���h�쐬
		CreateConVar("sm_rmf_tf_fakedeath", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_fakedeath","1","Fake Death Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVar�t�b�N
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);
		
		// �X�p�C
		g_UseCloakMeter = CreateConVar("sm_rmf_fake_cloak_use","10","Cloak Meter required for fake death(0-100)");
		g_WaitTime = CreateConVar("sm_rmf_fake_wait","3.0","Time before can show the next body(0.0-10.0)");
		g_Dissolve = CreateConVar("sm_rmf_fake_dissolve","1","Last body dissolve Enable/Disable (0 = disabled | 1 = enabled)");
		g_DissolveTime = CreateConVar("sm_rmf_fake_dissolve_time","8.0","Time before dissolve the last fake body(1.0-50.0)");
		g_DissolveType = CreateConVar("sm_rmf_fake_dissolve_type","1","Fake body dissolve type(0-3)");
		g_DissolveUncloak = CreateConVar("sm_rmf_fake_dissolve_uncloak","1","Last body dissolve when uncloak Enable/Disable (0 = disabled | 1 = enabled)");

		HookConVarChange(g_UseCloakMeter, ConVarChange_UseCloakMeter);
		HookConVarChange(g_WaitTime, ConVarChange_WaitTime);
		HookConVarChange(g_Dissolve, ConVarChange_Dissolve);
		HookConVarChange(g_DissolveTime, ConVarChange_DissolveTime);
		HookConVarChange(g_DissolveType, ConVarChange_DissolveType);
		HookConVarChange(g_DissolveUncloak, ConVarChange_g_DissolveUncloak);

		// �{�C�X
		g_PainVoice[0] = "vo/spy_painsevere01.wav";
		g_PainVoice[1] = "vo/spy_painsevere02.wav";
		g_PainVoice[2] = "vo/spy_painsevere03.wav";
		g_PainVoice[3] = "vo/spy_painsevere04.wav";
		g_PainVoice[4] = "vo/spy_painsevere05.wav";
	}
	

	// �}�b�v�J�n
	if(StrEqual(name, EVENT_MAP_START))
	{
		// ���f���Ǎ�
		PrecacheModel("models/player/hwm/spy.mdl", true);
		
		// �X�p�C
		PrecacheSound(SOUND_EMPTY, true);
		PrecacheSound(SOUND_DISSOLVE, true);
		
		// ���ɐ�
		for (new i = 1; i <= 4; i++)
		{
			PrecacheSound(g_PainVoice[i], true);
		}
	}

	
	// �Q�[���t���[��
	if(StrEqual(name, EVENT_GAME_FRAME))
	{
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			FrameAction(i);
		}
	}
	
	// �v���C���[���Z�b�g
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// �U���̍폜
		DissolveFakeBody(client);

		// �o���o���t���O�N���A
		g_PlayerGib[client] = false;

		// ���̎��̃^�C�}�[�N���A
		if(g_NextBody[client] != INVALID_HANDLE)
		{
			KillTimer(g_NextBody[client]);
			g_NextBody[client] = INVALID_HANDLE;
		}
		
		// �q�b�g�f�[�^�^�C�}�[�N���A
		if(g_HitClear[client] != INVALID_HANDLE)
		{
			KillTimer(g_HitClear[client]);
			g_HitClear[client] = INVALID_HANDLE;
		}
		
		// ���̏����^�C�}�[�N���A
		if(g_DissolveFakeBody[client] != INVALID_HANDLE)
		{
			KillTimer(g_DissolveFakeBody[client]);
			g_DissolveFakeBody[client] = INVALID_HANDLE;
		}
		
		// ������
		if( TF2_GetPlayerClass( client ) == TFClass_Spy)
		{
			Format(g_PlayerHintText[client][0], HintTextMaxSize , "%t", "HOWTO_TEXT_SPY");
			Format(g_PlayerHintText[client][1], HintTextMaxSize , "%t", "TIPS_TEXT_SPY", GetConVarInt(g_UseCloakMeter));
		}
	}
		

	// �_���[�W
	if(StrEqual(name, EVENT_PLAYER_DAMAGE))
	{
		new client_victim = client;
		new client_attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

		new TFClassType:class = TF2_GetPlayerClass(client_victim);
		if (client_attacker > 0 && class == TFClass_Spy)
		{
			new String:classname[64];
			TF2_GetCurrentWeaponClass(client_attacker, classname, 64);

			if( StrEqual(classname, "CTFRocketLauncher") || StrEqual(classname, "CTFGrenadeLauncher") || StrEqual(classname, "CTFPipebombLauncher") )
			{
				g_PlayerGib[client_victim] = true;
								
				if(g_HitClear[client_victim] != INVALID_HANDLE)
				{
					KillTimer(g_HitClear[client_victim]);
					g_HitClear[client_victim] = CreateTimer(0.65, Timer_HitClearTimer, client_victim);
				}
				else
				{
					g_HitClear[client_victim] = CreateTimer(0.65, Timer_HitClearTimer, client_victim);
				}

			}
			else
			{
				g_PlayerGib[client_victim] = false;
			}
		}
	}

	// ���S
	if(StrEqual(name, EVENT_PLAYER_DEATH))
	{
		// ���񂾂�U�̎��̏���
		if( TF2_GetPlayerClass( client ) == TFClass_Spy )
		{
			DissolveFakeBody(client);
		}
	}
	return Plugin_Continue;
}



/////////////////////////////////////////////////////////////////////
//
// �N���[�N���[�^�[�g�p�ʂ̐ݒ�
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_UseCloakMeter(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.0�`100.0�܂�
	if (StringToInt(newValue) < 0 || StringToInt(newValue) > 100)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0 and 100");
	}
}

/////////////////////////////////////////////////////////////////////
//
// ���̎��̂��o����܂ł̑҂����Ԃ̐ݒ�
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_WaitTime(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.0�`10.0�܂�
	if (StringToFloat(newValue) < 0.0 || StringToFloat(newValue) > 10.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0.0 and 10.0");
	}
}
/////////////////////////////////////////////////////////////////////
//
// ���̏�������H
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_Dissolve(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0��1
	if (StringToInt(newValue) != 0 && StringToInt(newValue) != 1)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
		PrintToServer("Warning: Value has to be 0 or 1");
	}
}
/////////////////////////////////////////////////////////////////////
//
// �O�̎��̂������܂ł̎���
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_DissolveTime(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 1.0�`10.0�܂�
	if (StringToFloat(newValue) < 1.0 || StringToFloat(newValue) > 50.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 1.0 and 50.0");
	}
}

/////////////////////////////////////////////////////////////////////
//
// �����^�C�v
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_DissolveType(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0�`3�܂�
	if (StringToInt(newValue) < 0 || StringToInt(newValue) > 3)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0 and 3");
	}
}
/////////////////////////////////////////////////////////////////////
//
// ���������Ŏ��̏�������H
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_g_DissolveUncloak(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0��1
	if (StringToInt(newValue) != 0 && StringToInt(newValue) != 1)
	{
		SetConVarInt(convar, StringToInt(oldValue), false, false);
		PrintToServer("Warning: Value has to be 0 or 1");
	}
}



/////////////////////////////////////////////////////////////////////
//
// �Q�[���t���[��
//
/////////////////////////////////////////////////////////////////////
stock FrameAction(any:client)
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// �X�p�C���t�F�C�N�f�XON
		if( TF2_GetPlayerClass( client ) == TFClass_Spy )
		{
			if( g_PlayerButtonDown[client] == INVALID_HANDLE )
			{
				// �t�F�C�N�f�X
				FakeDeath(client);
			}

			// ���������Ŏ��̏����H
			if(GetConVarBool(g_DissolveUncloak))
			{
				if(!TF2_IsPlayerCloaked(client))
				{
					DissolveFakeBody(client);
				}
			}
		}		
		

	}
		
}

/////////////////////////////////////////////////////////////////////
//
// �t�F�C�N�f�X
//
/////////////////////////////////////////////////////////////////////
public FakeDeath(any:client)
{
	// �������������烊�Z�b�g
	if(!TF2_IsPlayerCloaked(client))
	{
		// ���Ѓ��Z�b�g
		g_PlayerGib[client] = false;
	}
	
	// �A�^�b�N1
	if (GetClientButtons(client) & IN_ATTACK)
	{
		// �A�������h�~�H
		g_PlayerButtonDown[client] = CreateTimer(0.5, Timer_ButtonUp, client);
	
		// �U���̎��̂�������
		SpawnFakeBody(client);
		
		// ���Ѓ��Z�b�g
		g_PlayerGib[client] = false;
	}

}

/////////////////////////////////////////////////////////////////////
//
// �U�̎��̍폜
//
/////////////////////////////////////////////////////////////////////
public DissolveFakeBody(client)
{
	if(!GetConVarBool(g_Dissolve))
		return;
	
	// �ȑO�̋U���̂�����
	if(g_Ragdoll[client] != -1)
	{
		if( IsValidEntity(g_Ragdoll[client]) )
		{
			// ������T�E���h
			EmitSoundToAll(SOUND_DISSOLVE, g_Ragdoll[client], _, _, SND_CHANGEPITCH, 0.6, 80);
			
			new String:dname[32], String:dtype[32];
			Format(dname, sizeof(dname), "dis_%d", client);
			Format(dtype, sizeof(dtype), "%d", GetConVarInt(g_DissolveType));

			new ent = CreateEntityByName("env_entity_dissolver");
			if (ent>0)
			{
				DispatchKeyValue(g_Ragdoll[client], "targetname", dname);
				DispatchKeyValue(ent, "dissolvetype", dtype);
				DispatchKeyValue(ent, "target", dname);
				AcceptEntityInput(ent, "Dissolve");
				AcceptEntityInput(ent, "kill");
			}
			g_Ragdoll[client] = -1;
		}
	}	
}

/////////////////////////////////////////////////////////////////////
//
// �U�̎��̍쐬
//
/////////////////////////////////////////////////////////////////////
public SpawnFakeBody(client)
{
	new Float:PlayerPosition[3];
	//new Float:PlayerForce[3];
		
	if(TF2_IsPlayerCloaked(client))
	{
		// ���[�^�[�g�p��
		new UseMeter = GetConVarInt(g_UseCloakMeter);
		new NowMeter = TF2_GetPlayerCloakMeter(client);
		// ���ɉ�����܂ł̎���
		new Float:WaitTime = GetConVarFloat(g_WaitTime);
	
		if( NowMeter > UseMeter  && g_NextBody[client] == INVALID_HANDLE)
		{
			new FakeBody = CreateEntityByName("tf_ragdoll");

			// �U���̍폜
			DissolveFakeBody(client);
			
			if (DispatchSpawn(FakeBody))
			{
				// �����ʒu
				GetClientAbsOrigin(client, PlayerPosition);
				new offset = FindSendPropOffs("CTFRagdoll", "m_vecRagdollOrigin");
				SetEntDataVector(FakeBody, offset, PlayerPosition);
				
				// ���̂̃N���X�̓X�p�C
				offset = FindSendPropOffs("CTFRagdoll", "m_iClass");
				SetEntData(FakeBody, offset, 8);

				// �R���Ă���
				if(TF2_IsPlayerOnFire(client))
				{
					offset = FindSendPropOffs("CTFRagdoll", "m_bBurning");
					SetEntData(FakeBody, offset, 1);
					
				}
				if(g_PlayerGib[client])
				{
					offset = FindSendPropOffs("CTFRagdoll", "m_bGib");
					SetEntData(FakeBody, offset, 1);
					new gibHead = CreateEntityByName("raggib");
					if(DispatchSpawn(FakeBody))
					{
						new offset2 = FindSendPropOffs("CBaseAnimating", "m_vecOrigin");
						SetEntDataVector(gibHead, offset2, PlayerPosition);
					}
					
				}
				g_PlayerGib[client] = false;

				offset = FindSendPropOffs("CTFRagdoll", "m_iPlayerIndex");
				SetEntData(FakeBody, offset, client);
				
				// ���̂̃`�[���J���[
				new team = GetClientTeam(client);
				offset = FindSendPropOffs("CTFRagdoll", "m_iTeam");
				SetEntData(FakeBody, offset, team);
				
				EmitSoundToAll(g_PainVoice[GetRandomInt(0, 4)], FakeBody, _, _, _, 1.0);
				
				NowMeter = NowMeter - UseMeter;
				TF2_SetPlayerCloakMeter(client,NowMeter);
				g_NextBody[client] = CreateTimer(WaitTime, Timer_NextBodyTimer, client);

				// �������������̂�ۑ�&�����^�C�}�[�ݒ�
				new Float:DissolveTime = GetConVarFloat(g_DissolveTime);

				g_Ragdoll[client] = FakeBody;
				if(g_DissolveFakeBody[client] != INVALID_HANDLE)
				{
					KillTimer(g_DissolveFakeBody[client]);
					g_DissolveFakeBody[client] = INVALID_HANDLE;
				}
				g_DissolveFakeBody[client] = CreateTimer(DissolveTime, Timer_DissolveFakeBodyTimer, client);
				
				return;
			}			
		}
		
		EmitSoundToClient(client, SOUND_EMPTY, _, _, _, _, 0.55);
	}
	

}
/////////////////////////////////////////////////////////////////////
//
// �U���̏����^�C�}�[
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_DissolveFakeBodyTimer(Handle:timer, any:client)
{
	g_DissolveFakeBody[client] = INVALID_HANDLE;
	// �U���̍폜
	DissolveFakeBody(client);
}

/////////////////////////////////////////////////////////////////////
//
// ���̎���
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_NextBodyTimer(Handle:timer, any:client)
{
	g_NextBody[client] = INVALID_HANDLE;
}

/////////////////////////////////////////////////////////////////////
//
// �q�b�g���N���A
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_HitClearTimer(Handle:timer, any:client)
{
	// ���Ѓ��Z�b�g
	g_PlayerGib[client] = false;
	g_HitClear[client] = INVALID_HANDLE;
}


