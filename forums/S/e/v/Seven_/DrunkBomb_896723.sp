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
//#include "rmf/drug"

/////////////////////////////////////////////////////////////////////
//
// �萔
//
/////////////////////////////////////////////////////////////////////
#define PL_NAME "Drunk Bomb"
#define PL_DESC "Drunk Bomb"
#define PL_VERSION "0.0.0"
#define PL_TRANSLATION "drunkbomb.phrases"

#define SOUND_DEMO_BEEP "items/cart_explode_trigger.wav"
#define SOUND_DEMO_SING "vo/taunts/demoman_taunts01.wav"
#define SOUND_DEMO_EXPLOSION "items/cart_explode.wav"
#define SOUND_DEMO_EXPLOSION_MISS "weapons/explode2.wav"


#define MDL_BIG_BOMB_BLU "models/props_trainyard/bomb_cart.mdl"
#define MDL_BIG_BOMB_RED "models/props_trainyard/bomb_cart_red.mdl"
//#define MDL_BIG_BOMB "models/props_trainyard/cart_bomb_separate.mdl"

#define EFFECT_EXPLODE_EMBERS "cinefx_goldrush_embers"
#define EFFECT_EXPLODE_DEBRIS "cinefx_goldrush_debris"
#define EFFECT_EXPLODE_INITIAL_SMOKE "cinefx_goldrush_initial_smoke"
#define EFFECT_EXPLODE_FLAMES "cinefx_goldrush_flames"
#define EFFECT_EXPLODE_FLASH "cinefx_goldrush_flash"
#define EFFECT_EXPLODE_BURNINGDEBIS "cinefx_goldrush_burningdebris"
#define EFFECT_EXPLODE_SMOKE "cinefx_goldrush_smoke"
#define EFFECT_EXPLODE_HUGEDUSTUP "cinefx_goldrush_hugedustup"

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
new Handle:g_FuseTime = INVALID_HANDLE;						// ConVar���e�^�C�}�[����
new Handle:g_WalkSpeedMag = INVALID_HANDLE;					// ConVar�ړ����x
new Handle:g_DamageRadius = INVALID_HANDLE;					// ConVar�L���͈�
new Handle:g_BaseDamage = INVALID_HANDLE;					// ConVar�x�[�X�_���[�W
new Handle:g_GravityScale = INVALID_HANDLE;					// ConVar�d��

new Handle:g_TauntTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// �����`�F�b�N�^�C�}�[
new Handle:g_FuseEnd[MAXPLAYERS+1] = INVALID_HANDLE;		// �_�b�V���I���^�C�}�[
new Handle:g_TauntChain[MAXPLAYERS+1] = INVALID_HANDLE;		// �����R���{�^�C�}�[
new Handle:g_LoopTimer[MAXPLAYERS+1] = INVALID_HANDLE;		// ���[�v����
new Handle:g_LoopVisualTimer[MAXPLAYERS+1] = INVALID_HANDLE;// ���E�G�t�F�N�g����

new bool:g_FirstTaunt[MAXPLAYERS+1] = false;				// �����R���{�����H
new bool:g_HasBomb[MAXPLAYERS+1] = false;					// �����`���H
new g_AngleDir[MAXPLAYERS+1] = 1;							// ���E�̉�]����
new g_FadeColor[MAXPLAYERS+1][3];							// �J���[


new g_BombModel[MAXPLAYERS+1] = -1;			// ���e���f��

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
		LoadTranslations(PL_TRANSLATION);

		// �R�}���h�쐬
		CreateConVar("sm_rmf_tf_drunkbomb", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
		g_IsPluginOn = CreateConVar("sm_rmf_allow_drunkbomb","1","Drunk Bomb Enable/Disable (0 = disabled | 1 = enabled)");

		// ConVar�t�b�N
		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		g_FuseTime = CreateConVar("sm_rmf_drunkbomb_fuse","5.5","Drunk Bomb fuse time (1.0-10.0)");
		g_WalkSpeedMag = CreateConVar("sm_rmf_drunkbomb_speed_mag","0.8","Drunk Bomb walk speed (0.1-1.0)");
		g_DamageRadius = CreateConVar("sm_rmf_drunkbomb_radius","10.0","Drunk Bomb damage radius (1.0-100.0)");
		g_BaseDamage = CreateConVar("sm_rmf_drunkbomb_base_damage","800.0","Drunk Bomb base damage (0.0-2000.0)");
		g_GravityScale = CreateConVar("sm_rmf_drunkbomb_gravity_scale","2.0","Drunk Bomb gravity scale (0.1-10.0)");
		HookConVarChange(g_FuseTime, ConVarChange_FuseTime);
		HookConVarChange(g_WalkSpeedMag, ConVarChange_WalkSpeed);
		HookConVarChange(g_DamageRadius, ConVarChange_DamageRadius);
		HookConVarChange(g_BaseDamage, ConVarChange_BaseDamage);
		HookConVarChange(g_GravityScale, ConVarChange_GravityScale);


		// �����R�}���h�Q�b�g
		RegConsoleCmd("taunt", Command_Taunt, "Taunt");
		
		// �A�r���e�B�N���X�ݒ�
		CreateConVar("sm_rmf_drunkbomb_class", "4", "Ability class");
	}
	
	// �v���O�C��������
	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
		// ���������K�v�Ȃ���
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			// ���e�폜
			DeleteBigBomb(client)
		}
	}
	// �v���O�C����n��
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
		// ���������K�v�Ȃ���
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			// ���e�폜
			DeleteBigBomb(client)
		}
	}

	// �}�b�v�X�^�[�g
	if(StrEqual(name, EVENT_MAP_START))
	{
		// ���������K�v�Ȃ���
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			// ���e�폜
			DeleteBigBomb(client)
		}

		PrePlayParticle(EFFECT_EXPLODE_EMBERS);
		PrePlayParticle(EFFECT_EXPLODE_DEBRIS);
		PrePlayParticle(EFFECT_EXPLODE_INITIAL_SMOKE);
		PrePlayParticle(EFFECT_EXPLODE_FLAMES);
		PrePlayParticle(EFFECT_EXPLODE_FLASH);
		PrePlayParticle(EFFECT_EXPLODE_BURNINGDEBIS);
		PrePlayParticle(EFFECT_EXPLODE_SMOKE);
		PrePlayParticle(EFFECT_EXPLODE_HUGEDUSTUP);
		
		PrecacheSound(SOUND_DEMO_BEEP, true);
		PrecacheSound(SOUND_DEMO_SING, true);
		PrecacheSound(SOUND_DEMO_EXPLOSION, true);
		PrecacheSound(SOUND_DEMO_EXPLOSION_MISS, true);

		PrecacheModel(MDL_BIG_BOMB_BLU, true);
		PrecacheModel(MDL_BIG_BOMB_RED, true);

	}	
	
	// �v���C���[���Z�b�g
	if(StrEqual(name, EVENT_PLAYER_DATA_RESET))
	{
		// ������
		g_HasBomb[client] = false;
		
		// �^�C�}�[�N���A
		if(g_TauntTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_TauntTimer[client]);
			g_TauntTimer[client] = INVALID_HANDLE;
		}
		
		// �^�C�}�[�N���A
		if(g_FuseEnd[client] != INVALID_HANDLE)
		{
			KillTimer(g_FuseEnd[client]);
			g_FuseEnd[client] = INVALID_HANDLE;
		}
		
		// �^�C�}�[�N���A
		if(g_TauntChain[client] != INVALID_HANDLE)
		{
			KillTimer(g_TauntChain[client]);
			g_TauntChain[client] = INVALID_HANDLE;
		}
		
		// �^�C�}�[�N���A
		if(g_LoopTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_LoopTimer[client]);
			g_LoopTimer[client] = INVALID_HANDLE;
		}
		
		// �^�C�}�[�N���A
		if(g_LoopVisualTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_LoopVisualTimer[client]);
			g_LoopVisualTimer[client] = INVALID_HANDLE;
		}

		// �������������t���O�N���A
		g_FirstTaunt[client] = false;
				
		// �f�t�H���g�X�s�[�h
		TF2_SetPlayerDefaultSpeed(client);
		//SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", TF2_GetPlayerSpeed(client));

		// �d�͖߂�
		SetEntityGravity(client, 1.0);
		
		// �̂Ƃ߂�
		StopSound(client, 0, SOUND_DEMO_SING);
		
		// ���e�̃��f�����폜
		DeleteBigBomb(client);
		
		// ���E�G�t�F�N�g
		g_AngleDir[client] = 1;
		g_FadeColor[client][0] = 255;
		g_FadeColor[client][1] = 255;
		g_FadeColor[client][2] = 255;
		ScreenFade(client, 0, 0, 0, 0, 255, IN);
		
		// ���E�߂��B
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
		
		// ������
		if( TF2_GetPlayerClass( client ) == TFClass_DemoMan)
		{
			Format(g_PlayerHintText[client][0], HintTextMaxSize , "%T", "DESCRIPTION_0_DRUNKBOMB", client);
			Format(g_PlayerHintText[client][1], HintTextMaxSize , "%T", "DESCRIPTION_1_DRUNKBOMB", client, GetConVarFloat(g_FuseTime), RoundFloat(FloatAbs(GetConVarFloat(g_WalkSpeedMag) * 100.0 - 100.0)));
		}
	}
	
	// �ؒf
	if(StrEqual(name, EVENT_PLAYER_DISCONNECT))
	{
		g_BombModel[client] = -1;
	}

	// ���S
	if(StrEqual(name, EVENT_PLAYER_DEATH))
	{
		// ���s�G�t�F�N�g
		if(g_HasBomb[client])
		{
			new Float:pos[3];
			pos[0] = 0.0;
			pos[1] = 0.0;
			pos[2] = 50.0;
			new Float:ang[3];
			ang[0] = -90.0;
			ang[1] = 0.0;
			ang[2] = 0.0;
			EmitSoundToAll(SOUND_DEMO_EXPLOSION_MISS, client, _, _, SND_CHANGEPITCH, 1.0, 80);
			ShowParticleEntity(client, EFFECT_EXPLODE_EMBERS, 1.0, pos, ang);
			ShowParticleEntity(client, EFFECT_EXPLODE_DEBRIS, 1.0, pos, ang);
			ShowParticleEntity(client, EFFECT_EXPLODE_INITIAL_SMOKE, 1.0, pos, ang);
	//		AttachParticle(client, "cinefx_goldrush_flames", 1.0, pos, ang);
			ShowParticleEntity(client, EFFECT_EXPLODE_FLASH, 1.0, pos, ang);
	//		AttachParticle(client, "cinefx_goldrush_burningdebris", 1.0, pos, ang);
	//		AttachParticle(client, "cinefx_goldrush_smoke", 1.0, pos, ang);
	//		AttachParticle(client, "cinefx_goldrush_hugedustup", 1.0, pos, ang);
		
		}
	}

	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// �����R�}���h�擾
//
/////////////////////////////////////////////////////////////////////
public Action:Command_Taunt(client, args)
{
	// MOD��ON�̎�����
	if( !g_IsRunning || client <= 0 )
		return Plugin_Continue;
	
	if(TF2_GetPlayerClass(client) == TFClass_DemoMan && g_AbilityUnlock[client])
	{
		TauntCheck(client);
	}	

	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
//
// ����
//
/////////////////////////////////////////////////////////////////////
public TauntCheck(any:client)
{
	// �t���[�Y���΂��Ă��Ȃ�
	if( g_FuseEnd[client] == INVALID_HANDLE )
	{
		// ���햼�擾
		new String:classname[64];
		TF2_GetCurrentWeaponClass(client, classname, 64);
		
		// �O������
		if(StrEqual(classname, "CTFGrenadeLauncher"))
		{
			if(g_TauntTimer[client] != INVALID_HANDLE)
			{
				KillTimer(g_TauntTimer[client]);
				g_TauntTimer[client] = INVALID_HANDLE;
			}
			g_TauntTimer[client] = CreateTimer(2.0, Timer_TauntEnd, client);
		}
		
		// �{�g���� �R���{���ԓ�
		if(StrEqual(classname, "CTFBottle") && g_FirstTaunt[client])
		{
			if(g_TauntTimer[client] != INVALID_HANDLE)
			{
				KillTimer(g_TauntTimer[client]);
				g_TauntTimer[client] = INVALID_HANDLE;
			}
			g_TauntTimer[client] = CreateTimer(4.3, Timer_TauntEnd, client);
		}
		
	}
}

/////////////////////////////////////////////////////////////////////
//
// �����I���^�C�}�[
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_TauntEnd(Handle:timer, any:client)
{
	g_TauntTimer[client] = INVALID_HANDLE;
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(TF2_IsPlayerTaunt(client))
		{
			// ���햼�擾
			new String:classname[64];
			TF2_GetCurrentWeaponClass(client, classname, 64);
			
			// �O������
			if(StrEqual(classname, "CTFGrenadeLauncher"))
			{
				g_FirstTaunt[client] = true;
				
				// �R���{�^�C�}�[����
				if(g_TauntChain[client] != INVALID_HANDLE)
				{
					KillTimer(g_TauntChain[client]);
					g_TauntChain[client] = INVALID_HANDLE;
				}
				g_TauntChain[client] = CreateTimer(3.0, Timer_TauntChainEnd, client);
				
			}
			else if(StrEqual(classname, "CTFBottle"))
			{
				// �������e�X�^�[�g
				BomTimerStart(client);
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////
//
// �R���{���ԏI��
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_TauntChainEnd(Handle:timer, any:client)
{
	g_TauntChain[client] = INVALID_HANDLE;
	g_FirstTaunt[client] = false;
}


/////////////////////////////////////////////////////////////////////
//
// �������e�X�^�[�g
//
/////////////////////////////////////////////////////////////////////
stock BomTimerStart(any:client)
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// ����
		g_HasBomb[client] = true;
		
		// �t���[�Y����
		if(g_FuseEnd[client] != INVALID_HANDLE)
		{
			KillTimer(g_FuseEnd[client]);
			g_FuseEnd[client] = INVALID_HANDLE;
		}
		g_FuseEnd[client] = CreateTimer(GetConVarFloat(g_FuseTime), Timer_FuseEnd, client);
		//AttachParticleBone(client, "warp_version", "eyes", GetConVarFloat(g_FuseTime));

		
		// �̗͑S��
		SetEntityHealth(client, TF2_GetPlayerMaxHealth(client));
		
		// �����T�E���h(��)
		EmitSoundToAll(SOUND_DEMO_BEEP, client, _, _, SND_CHANGEPITCH, 1.0, 100);
		EmitSoundToAll(SOUND_DEMO_SING, client, _, _, SND_CHANGEPITCH, 1.0, 100);

		// �A�������p�^�C�}�[����
		if(g_LoopTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_LoopTimer[client]);
			g_LoopTimer[client] = INVALID_HANDLE;
		}
		g_LoopTimer[client] = CreateTimer(0.05, Timer_Loop, client, TIMER_REPEAT);

		// �A�������p�^�C�}�[����
		if(g_LoopVisualTimer[client] != INVALID_HANDLE)
		{
			KillTimer(g_LoopVisualTimer[client]);
			g_LoopVisualTimer[client] = INVALID_HANDLE;
		}
		g_LoopVisualTimer[client] = CreateTimer(0.8, Timer_LoopVisual, client, TIMER_REPEAT);

		
		//PrintToChat(client, "%d", GetPlayerWeaponSlot(client, 0));

		// ���E�̂��
		//CreateDrug(client);

		// �w���ɔ��e�w����
		g_BombModel[client] = CreateEntityByName("prop_dynamic");
		if (IsValidEdict(g_BombModel[client]))
		{
			new String:tName[32];
			GetEntPropString(client, Prop_Data, "m_iName", tName, sizeof(tName));
			DispatchKeyValue(g_BombModel[client], "targetname", "back_bomb");
			DispatchKeyValue(g_BombModel[client], "parentname", tName);
			if( TFTeam:GetClientTeam(client) == TFTeam_Red)
			{
				SetEntityModel(g_BombModel[client], MDL_BIG_BOMB_RED);
			}
			else
			{
				SetEntityModel(g_BombModel[client], MDL_BIG_BOMB_BLU);
			}
			DispatchSpawn(g_BombModel[client]);
			SetVariantString("!activator");
			AcceptEntityInput(g_BombModel[client], "SetParent", client, client, 0);
			SetVariantString("flag");
			AcceptEntityInput(g_BombModel[client], "SetParentAttachment", client, client, 0);
			ActivateEntity(g_BombModel[client]);
			new Float:pos[3];
			new Float:ang[3];
			pos[0] = 0.0;
			pos[1] = 15.0;
			pos[2] = 15.0;
			ang[0] = 25.0;
			ang[1] = 90.0;
			ang[2] = -10.0;

			TeleportEntity(g_BombModel[client], pos, ang, NULL_VECTOR);
			//AcceptEntityInput(ent, "start");

	    }	
		g_FadeColor[client][0] = GetRandomInt(100, 180);
		g_FadeColor[client][1] = GetRandomInt(100, 180);
		g_FadeColor[client][2] = GetRandomInt(100, 180);
		ScreenFade(client, g_FadeColor[client][0], g_FadeColor[client][1], g_FadeColor[client][2], 240, 200, OUT);
	}	
}

/////////////////////////////////////////////////////////////////////
//
// ���[�v�^�C�}�[
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_Loop(Handle:timer, any:client)
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client) && g_FuseEnd[client] != INVALID_HANDLE)
	{
		// �̗͏��X�ɉ�
		new nowHealth = GetClientHealth(client);
		nowHealth += 1;
		if( nowHealth > TF2_GetPlayerMaxHealth(client) )
		{
			nowHealth = TF2_GetPlayerMaxHealth(client);
		}
		SetEntityHealth(client, nowHealth);

		// ���̑����_�E��
		TF2_SetPlayerSpeed(client, TF2_GetPlayerSpeed(client) * GetConVarFloat(g_WalkSpeedMag));
		//SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(g_WalkSpeedMag));
		SetEntityGravity(client, GetConVarFloat(g_GravityScale));

		// �ߐڕ���ȊO�폜
		ClientCommand(client, "slot3");
		new weaponIndex;
		for(new i=0;i<3;i++)
		{
			if(i != 2)
			{
				weaponIndex = GetPlayerWeaponSlot(client, i);
				if( weaponIndex != -1)
				{
					RemovePlayerItem(client, weaponIndex);
					RemoveEdict(weaponIndex);
					TF2_RemoveWeaponSlot(client, i);
				}
			}
		}		
		
		
		// ���E���
		new Float:angs[3];
		GetClientEyeAngles(client, angs);
		
		g_AngleDir[client] = GetRandomInt(-1,1);
		
		if( g_AngleDir[client] != 0 )
//THIS IS A QUICK WORK AROUND
//		{
//			angs[0] += GetRandomFloat(0.0,15.0) * g_AngleDir[client];//g_DrugAngles[GetRandomInt(0,100) % 20];
//			angs[1] += GetRandomFloat(0.0,40.0) * g_AngleDir[client];//g_DrugAngles[GetRandomInt(0,100) % 20];
//			angs[2] += GetRandomFloat(0.0,15.0) * g_AngleDir[client];//g_DrugAngles[GetRandomInt(0,100) % 20];
//		}
		TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);
		
		
	}
	else
	{
		KillTimer(g_LoopTimer[client]);
		g_LoopTimer[client] = INVALID_HANDLE;
	}
}

/////////////////////////////////////////////////////////////////////
//
// ���[�v�^�C�}�[
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_LoopVisual(Handle:timer, any:client)
{
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client) && g_FuseEnd[client] != INVALID_HANDLE)
	{
		if(g_FadeColor[client][0] + g_FadeColor[client][1] + g_FadeColor[client][2] == 765)
		{
			g_FadeColor[client][0] = GetRandomInt(100, 180);
			g_FadeColor[client][1] = GetRandomInt(100, 180);
			g_FadeColor[client][2] = GetRandomInt(100, 180);

			ScreenFade(client, g_FadeColor[client][0], g_FadeColor[client][1], g_FadeColor[client][2], 240, 200, OUT);
		}
		else
		{
			ScreenFade(client, g_FadeColor[client][0], g_FadeColor[client][1], g_FadeColor[client][2], 240, 200, IN);
			g_FadeColor[client][0] = 255;
			g_FadeColor[client][1] = 255;
			g_FadeColor[client][2] = 255;
		}
	}
	else
	{
		KillTimer(g_LoopVisualTimer[client]);
		g_LoopVisualTimer[client] = INVALID_HANDLE;
	}
}

/////////////////////////////////////////////////////////////////////
//
// �t���[�Y�I���I���^�C�}�[�[
//
/////////////////////////////////////////////////////////////////////
public Action:Timer_FuseEnd(Handle:timer, any:client)
{
	g_FuseEnd[client] = INVALID_HANDLE;
	// �Q�[���ɓ����Ă���
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// �̂Ƃ߂�
		StopSound(client, 0, SOUND_DEMO_SING);
		
		//ClientCommand(client, "slot3");
		
		// �����G�t�F�N�g
		ExplodeEffect(client);
		
		// �_���[�W�`�F�b�N
		RadiusDamageBuiltObject(client, "obj_dispenser");
		RadiusDamageBuiltObject(client, "obj_sentrygun");
		RadiusDamageBuiltObject(client, "obj_teleporter_entrance");
		RadiusDamageBuiltObject(client, "obj_teleporter_exit");
		RadiusDamage(client);
		
		if( g_BombModel[client] != -1 )
		{
			if( IsValidEntity(g_BombModel[client]) )
			{
				ActivateEntity(g_BombModel[client]);
				RemoveEdict(g_BombModel[client]);
				g_BombModel[client] = -1;
			}	
		}
		
		// ���E�G�t�F�N�g�폜
		//KillDrug(client);
		
		// ��������
		g_HasBomb[client] = false;
		// ����
		FakeClientCommand(client, "explode");
		 
	}
}

/////////////////////////////////////////////////////////////////////
//
// �����G�t�F�N�g
//
/////////////////////////////////////////////////////////////////////
stock ExplodeEffect(any:client)
{
	EmitSoundToAll(SOUND_DEMO_EXPLOSION, client, _, _, SND_CHANGEPITCH, 0.8, 200);
	new Float:ang[3];
	ang[0] = -90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;
	new Float:pos[3];
	pos[0] = 0.0;
	pos[1] = 0.0;
	pos[2] = 50.0;	
	ShowParticleEntity(client, EFFECT_EXPLODE_EMBERS, 1.0, pos, ang);
	ShowParticleEntity(client, EFFECT_EXPLODE_DEBRIS, 1.0, pos, ang);
	ShowParticleEntity(client, EFFECT_EXPLODE_INITIAL_SMOKE, 1.0, pos, ang);
	ShowParticleEntity(client, EFFECT_EXPLODE_FLAMES, 1.0, pos, ang);
	ShowParticleEntity(client, EFFECT_EXPLODE_FLASH, 1.0, pos, ang);
	ShowParticleEntity(client, EFFECT_EXPLODE_BURNINGDEBIS, 1.0, pos, ang);
	ShowParticleEntity(client, EFFECT_EXPLODE_SMOKE, 1.0, pos, ang);
	ShowParticleEntity(client, EFFECT_EXPLODE_HUGEDUSTUP, 1.0, pos, ang);
}

/////////////////////////////////////////////////////////////////////
//
// �l�̂ւ̃_���[�W
//
/////////////////////////////////////////////////////////////////////
stock RadiusDamage(any:client)
{
	new Float:fAttackerPos[3];
	new Float:fVictimPos[3];
	new Float:distance;
	new maxclients = GetMaxClients();

	// ��Q�`�F�b�N
	for (new victim = 1; victim <= maxclients; victim++)
	{
		if( IsClientInGame(victim) && IsPlayerAlive(victim) )
		{
			if( GetClientTeam(victim) != GetClientTeam(client) && victim != client )
			{

				// �f���}���ʒu
				GetClientAbsOrigin(client, fAttackerPos);
				// ��Q�҈ʒu
				GetClientAbsOrigin(victim, fVictimPos);
				// �f���}���Ɣ�Q�҂̈ʒu
				distance = GetVectorDistanceMeter(fAttackerPos, fVictimPos);
				
				/*
				// ����10�ȓ�
				if(distance < GetConVarFloat(g_DamageRadius))
				{
					new String:edictName[64];
					new Handle:TraceEx = INVALID_HANDLE
					new HitEnt = -1;
					
					fAttackerPos[2] += 50.0;
					
					// �g���[�X�`�F�b�N
					g_FilteredEntity = client;
					TraceEx = TR_TraceRayFilterEx(fAttackerPos, fVictimPos, MASK_SOLID, RayType_EndPoint, TraceFilter);
					HitEnt = TR_GetEntityIndex(TraceEx);
					
					
					while( HitEnt > 0 )
					{
						if(HitEnt != victim)
						{
							// ������̓X���[
							GetEdictClassname(HitEnt, edictName, sizeof(edictName)); 
							//PrintToChat(client,"hit = %s", edictName);
							if(	StrEqual(edictName, "player") || 
								StrEqual(edictName, "obj_dispenser") ||
								StrEqual(edictName, "obj_sentrygun") || 
								StrEqual(edictName, "obj_teleporter_entrance") || 
								StrEqual(edictName, "obj_teleporter_exit")  
							)
							{
								GetEntPropVector(HitEnt, Prop_Data, "m_vecOrigin", fAttackerPos);
								if(GetVectorDistanceMeter(fAttackerPos, fVictimPos) > 1.0)
								{
									g_FilteredEntity = HitEnt
									TraceEx = TR_TraceRayFilterEx(fAttackerPos, fVictimPos, MASK_SOLID, RayType_EndPoint, TraceFilter);
									HitEnt = TR_GetEntityIndex(TraceEx);
								}
								else
								{
									HitEnt = victim;
									break;
								}
							}
							else
							{
								break;
							}											
						}
						else
						{
							break;
						}
					}*/
					
				if(CanSeeTarget(g_BombModel[client], fAttackerPos, victim, GetConVarFloat(g_DamageRadius), true, true))
				{
					//GetEdictClassname(HitEnt, edictName, sizeof(edictName)); 
					//PrintToChat(client,"hit = %s", edictName);
					//AttachParticleBone(victim, "conc_stars", "head",1.0);
					
					GetClientAbsOrigin(client, fAttackerPos);
					new Float:fKnockVelocity[3];	// �����̔���
					
					// �����̕����擾
					SubtractVectors(fAttackerPos, fVictimPos, fKnockVelocity);
					NormalizeVector(fKnockVelocity, fKnockVelocity); 

					// ��Q�҂̃x�N�g���������擾
					new Float:fVelocity[3];
					GetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", fVelocity);
					
					
					fVelocity[2] += 400.0;
					
					// �������Z�o
					ScaleVector(fKnockVelocity, -1000.0 * (1.0 / distance)); 
					AddVectors(fVelocity, fKnockVelocity, fVelocity);
					
					// �v���C���[�ւ̔�����ݒ�
					SetEntPropVector(victim, Prop_Data, "m_vecAbsVelocity", fVelocity);
							
					if( !TF2_IsPlayerInvuln(victim) )
					{
						new nowHealth = GetClientHealth(victim);
						nowHealth -= RoundFloat(GetConVarFloat(g_BaseDamage) * (1.5 / distance));
						if(nowHealth < 0)
						{
							FakeClientCommand(victim, "explode");
						}
						else
						{
							//PrintToChat(client, "%d", nowHealth);
							SetEntityHealth(victim, nowHealth);
							//SlapPlayer(victim, RoundFloat(800 * (1.0 / distance))); 
						}
					}						
					
				}
					
					//CloseHandle(TraceEx);					

				//}
				
			}
		}
	}	
	
}

/////////////////////////////////////////////////////////////////////
//
// �͈̓_���[�W���ݕ�
//
/////////////////////////////////////////////////////////////////////
stock RadiusDamageBuiltObject(any:client, const String:objName[])
{
	new Float:fAttackerPos[3];
	new Float:fObjPos[3];
	new Float:distance;

	// �I�u�W�F�N�g����
	new builtObj = -1;
	while ((builtObj = FindEntityByClassname(builtObj, objName)) != -1)
	{
		// ������`�F�b�N
		new iOwner = GetEntPropEnt(builtObj, Prop_Send, "m_hBuilder");
		if(GetClientTeam(iOwner) != GetClientTeam(client))
		{
			// �A�^�b�J�[�̈ʒu
			GetClientAbsOrigin(client, fAttackerPos);
			// �I�u�W�F�N�g�̈ʒu�擾
			GetEntPropVector(builtObj, Prop_Data, "m_vecOrigin", fObjPos);
			// �A�^�b�J�[�Ɣ�Q�҂̈ʒu
			distance = GetVectorDistanceMeter(fAttackerPos, fObjPos);
			
			/*
			// ����10.0m �ȓ�
			if(distance < GetConVarFloat(g_DamageRadius))
			{
				new String:edictName[64];
				new Handle:TraceEx = INVALID_HANDLE;
				new HitEnt = -1;
				
				// �������߂Ń`�F�b�N
				fAttackerPos[2] += 50.0;
				
				// �g���[�X
				g_FilteredEntity = client;
				TraceEx = TR_TraceRayFilterEx(fAttackerPos, fObjPos, MASK_ALL, RayType_EndPoint, TraceFilter);
				HitEnt = TR_GetEntityIndex(TraceEx);
				
				// 
				while( HitEnt > 0 )
				{
					if(HitEnt != builtObj)
					{
						// ������̓X���[
						GetEdictClassname(HitEnt, edictName, sizeof(edictName)); 
						if(	StrEqual(edictName, "player") || 
							StrEqual(edictName, "obj_dispenser") ||
							StrEqual(edictName, "obj_sentrygun") || 
							StrEqual(edictName, "obj_teleporter_entrance") || 
							StrEqual(edictName, "obj_teleporter_exit")  
						)
						{
							GetEntPropVector(HitEnt, Prop_Data, "m_vecOrigin", fAttackerPos);
							if(GetVectorDistanceMeter(fAttackerPos, fObjPos) > 1.0)
							{
								g_FilteredEntity = HitEnt
								TraceEx = TR_TraceRayFilterEx(fAttackerPos, fObjPos, MASK_ALL, RayType_EndPoint, TraceFilter);
								HitEnt = TR_GetEntityIndex(TraceEx);
							}
							else
							{
								HitEnt = builtObj;
								break;
							}
						}
						else
						{
							break;
						}											
					}
					else
					{
						break;
					}
				}
				*/
				
				// �_���[�W��K�p
			if(CanSeeTarget(g_BombModel[client], fAttackerPos, builtObj, GetConVarFloat(g_DamageRadius), true, true))
			{
				new damage = RoundFloat(GetConVarFloat(g_BaseDamage) * (1.0 / distance));
				SetVariantInt(damage);
				AcceptEntityInput(builtObj, "RemoveHealth");
				//PrintToChat(client, "%d", damage);

			}
				//CloseHandle(TraceEx);											
			//}
		}
	}				
}

/////////////////////////////////////////////////////////////////////
//
// �w���̔��e�폜
//
/////////////////////////////////////////////////////////////////////
stock DeleteBigBomb(any:client)
{
	// ���e�̃��f�����폜
	if( g_BombModel[client] != -1 && g_BombModel[client] != 0)
	{
		if( IsValidEntity(g_BombModel[client]) )
		{
			ActivateEntity(g_BombModel[client]);
			RemoveEdict(g_BombModel[client]);
			g_BombModel[client] = -1;
		}	
	}
}

/////////////////////////////////////////////////////////////////////
//
// ���e�^�C�}�[����
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_FuseTime(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 1.0�`10.0�܂�
	if (StringToFloat(newValue) < 1.0 || StringToFloat(newValue) > 10.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 1.0 and 10.0");
	}
}

/////////////////////////////////////////////////////////////////////
//
// �ړ����x
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_WalkSpeed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.1�`1.0�܂�
	if (StringToFloat(newValue) < 0.1 || StringToFloat(newValue) > 1.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0.1 and 1.0");
	}
}
	
/////////////////////////////////////////////////////////////////////
//
// �_���[�W�͈�
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_DamageRadius(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 1.0�`100.0�܂�
	if (StringToFloat(newValue) < 1.0 || StringToFloat(newValue) > 100.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 1.0 and 100.0");
	}
}
	
/////////////////////////////////////////////////////////////////////
//
// �x�[�X�_���[�W
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_BaseDamage(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.0�`2000.0�܂�
	if (StringToFloat(newValue) < 0.0 || StringToFloat(newValue) > 2000.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 1.0 and 2000.0");
	}
}
	
/////////////////////////////////////////////////////////////////////
//
// �d��
//
/////////////////////////////////////////////////////////////////////
public ConVarChange_GravityScale(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// 0.1�`10.0�܂�
	if (StringToFloat(newValue) < 0.1 || StringToFloat(newValue) > 10.0)
	{
		SetConVarFloat(convar, StringToFloat(oldValue), false, false);
		PrintToServer("Warning: Value has to be between 0.1 and 10.0");
	}
}