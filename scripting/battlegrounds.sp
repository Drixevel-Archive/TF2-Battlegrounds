/*
>fixed friendlyfire
>cancel parachute after deploy
>bees in the trees (1 damage per second for 10 seconds then x2 every 5 seconds)
>fix global pickup after discover

>Respawn weapons dropped from picking up other weapons
Possibly spawn different sets of weapons for certain players based on their class
Show updated stats for weapons on hover
Stack Jars
disable normal dropped weapons

flashlights
flashlights as drops
supply drops could give ammo

*/

/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Battlegrounds"
#define PLUGIN_AUTHOR "Drixevel"
#define PLUGIN_DESCRIPTION "PubG/Fortnite/Apex/H1Z1/RR clone in TF2."
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_URL "https://drixevel.dev/"

#define FLASHLIGHT_CLICKSOUND "ui/panel_open.wav"

/*****************************/
//Includes
#include <sourcemod>
#include <misc-sm>
#include <misc-tf>
#include <misc-colors>
#include <sdktools>
#include <sdkhooks>
#include <tf2items>
#include <tf_econ_data>
#include <cbasenpc>
#include <cbasenpc/util>
#include <dhooks>
#include <tf2-items>
#include <tf2attributes>

/*****************************/
//ConVars
ConVar convar_StartTimer;
ConVar convar_RoundTime;

/*****************************/
//Globals
bool g_Late;

ArrayList g_RandomWeapons;
ArrayList g_CrateWeapons;
StringMap g_WeaponWorldModels;
StringMap g_WeaponMags;
StringMap g_WeaponAmmo;

int g_WeaponIndexes[MAX_ENTITY_LIMIT + 1] = {-1, ...};
int g_NearWeapon[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};

int g_WeaponGlow;

bool g_IsGameLive;
bool g_IsForceStart;
bool g_IsPlaying[MAXPLAYERS + 1];
int g_ExtraLives[MAXPLAYERS + 1];

//Round Start
int g_RoundStartTime;
Handle g_Timer_RoundStart;

//Round Timer
float g_RoundTimer;
Handle g_Timer_RoundTimer;
Handle g_Sync_RoundTimer;
bool g_PauseTimer;

//Crates
int g_Crate = INVALID_ENT_REFERENCE;
Handle g_Timer_CratesTimer;
float g_Ground[3];

//Werewolf
CBaseNPC g_Werewolf;
PathFollower g_Pathing;
float g_flLastAttackTime;
int g_Target;
Handle g_Timer_WerewolfTimer;
int g_TickDelay[MAX_ENTITY_LIMIT + 1] = {-1, ...};

//Locust
Handle g_LocustTimer[MAXPLAYERS + 1];
int g_LocustTicks[MAXPLAYERS + 1];
int g_LocustMulti[MAXPLAYERS + 1];
int g_LocustModifier[MAXPLAYERS + 1];

//Flashlight
bool g_bPlayerFlashlight[MAXPLAYERS + 1];

/*****************************/
//Plugin Info
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_Late = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	CSetPrefix("{chartreuse}[Battlegrounds]");
	
	CreateConVar("sm_battlegrounds_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	convar_StartTimer = CreateConVar("sm_battlegrounds_starttimer", "20");
	convar_RoundTime = CreateConVar("sm_battlegrounds_roundtime", "600");
	
	AutoExecConfig(false);

	g_RandomWeapons = new ArrayList();
	g_CrateWeapons = new ArrayList();
	g_WeaponWorldModels = new StringMap();
	g_WeaponMags = new StringMap();
	g_WeaponAmmo = new StringMap();

	g_Sync_RoundTimer = CreateHudSynchronizer();
	
	//Primary
	g_RandomWeapons.Push(56);			//Huntsman
	g_WeaponWorldModels.SetString("56", "models/weapons/c_models/c_bow/c_bow.mdl");
	g_WeaponMags.SetValue("56", 1);
	g_WeaponAmmo.SetValue("56", 14);

	g_RandomWeapons.Push(230);			//The Sydney Sleeper
	g_WeaponWorldModels.SetString("230", "models/workshop/weapons/c_models/c_sydney_sleeper/c_sydney_sleeper.mdl");
	g_WeaponMags.SetValue("230", 12);
	g_WeaponAmmo.SetValue("230", 12);

	g_RandomWeapons.Push(402);			//The Bazaar Bargain
	g_WeaponWorldModels.SetString("402", "models/workshop/weapons/c_models/c_bazaar_sniper/c_bazaar_sniper.mdl");
	g_WeaponMags.SetValue("402", 10);
	g_WeaponAmmo.SetValue("402", 10);

	g_RandomWeapons.Push(1098);			//The Classic
	g_WeaponWorldModels.SetString("1098", "models/weapons/c_models/c_tfc_sniperrifle/c_tfc_sniperrifle.mdl");
	g_WeaponMags.SetValue("1098", 12);
	g_WeaponAmmo.SetValue("1098", 12);

	g_CrateWeapons.Push(1092);			//The Fortified Compound
	g_WeaponWorldModels.SetString("1092", "models/workshop_partner/weapons/c_models/c_bow_thief/c_bow_thief.mdl");
	g_WeaponMags.SetValue("1092", 1);
	g_WeaponAmmo.SetValue("1092", 10);

	g_CrateWeapons.Push(526);			//The Machina
	g_WeaponWorldModels.SetString("526", "models/weapons/c_models/c_tfc_sniperrifle/c_tfc_sniperrifle.mdl");
	g_WeaponMags.SetValue("526", 8);
	g_WeaponAmmo.SetValue("526", 8);

	//Secondary
	g_RandomWeapons.Push(16);			//SMG
	g_WeaponWorldModels.SetString("16", "models/weapons/c_models/c_smg/c_smg.mdl");
	g_WeaponMags.SetValue("16", 25);
	g_WeaponAmmo.SetValue("16", 25);

	g_RandomWeapons.Push(57);			//The Razorback
	g_WeaponWorldModels.SetString("57", "models/player/items/sniper/knife_shield.mdl");

	g_RandomWeapons.Push(58);			//Jarate
	g_WeaponWorldModels.SetString("58", "models/weapons/c_models/urinejar.mdl");

	g_RandomWeapons.Push(231);			//Darwin's Danger Shield
	g_WeaponWorldModels.SetString("231", "models/workshop/player/items/sniper/croc_shield/croc_shield.mdl");

	g_RandomWeapons.Push(642);			//Cozy Camper
	g_WeaponWorldModels.SetString("642", "models/workshop/player/items/sniper/xms_sniper_commandobackpack/xms_sniper_commandobackpack.mdl");

	g_RandomWeapons.Push(751);			//The Cleaner's Carbine
	g_WeaponWorldModels.SetString("751", "models/weapons/c_models/c_smg/c_smg.mdl");
	g_WeaponMags.SetValue("751", 25);
	g_WeaponAmmo.SetValue("751", 25);

	//Melee
	g_RandomWeapons.Push(171);			//The Tribalman's Shiv
	g_WeaponWorldModels.SetString("171", "models/workshop/weapons/c_models/c_wood_machete/c_wood_machete.mdl");
	g_RandomWeapons.Push(232);			//The Bushwacka
	g_WeaponWorldModels.SetString("232", "models/workshop/weapons/c_models/c_croc_knife/c_croc_knife.mdl");
	g_RandomWeapons.Push(401);			//The Shahanshah
	g_WeaponWorldModels.SetString("401", "models/workshop/weapons/c_models/c_scimitar/c_scimitar.mdl");
	
	RegAdminCmd("sm_regenweapons", Command_RegenWeapons, ADMFLAG_ROOT);
	RegAdminCmd("sm_pausetimer", Command_PauseTimer, ADMFLAG_ROOT);

	RegAdminCmd("sm_start", Command_StartMatch, ADMFLAG_ROOT);
	RegAdminCmd("sm_startmatch", Command_StartMatch, ADMFLAG_ROOT);
	RegAdminCmd("sm_force", Command_StartMatch, ADMFLAG_ROOT);
	RegAdminCmd("sm_forcematch", Command_StartMatch, ADMFLAG_ROOT);

	RegAdminCmd("sm_spawnwolf", Command_SpawnWolf, ADMFLAG_ROOT);
	RegAdminCmd("sm_telwolf", Command_TeleportWolf, ADMFLAG_ROOT);
	RegAdminCmd("sm_wolftarget", Command_SetWolfTarget, ADMFLAG_ROOT);
	RegAdminCmd("sm_wolftargetrand", Command_RandomWolfTarget, ADMFLAG_ROOT);

	RegAdminCmd("sm_spawnweapon", Command_SpawnWeapon, ADMFLAG_ROOT);

	CreateTimer(1.0, Timer_Seconds, _, TIMER_REPEAT);
	
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_PreThink, Hook_ClientPreThink);
	
	int entity = -1; char class[64];
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
		if (GetEntityClassname(entity, class, sizeof(class)))
			OnEntityCreated(entity, class);
}

public void OnPluginEnd()
{
	ClearAllWeapons();

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		ClientTurnOffFlashlight(i);
	}

	DeleteCrate();

	if (g_Werewolf != INVALID_NPC && IsValidEntity(g_Werewolf.GetEntity()))
		AcceptEntityInput(g_Werewolf.GetEntity(), "Kill");
}

public Action Timer_Seconds(Handle timer)
{
	int weapon; float origin[3]; int index; char sName[64];
	while ((weapon = FindEntityByClassname(weapon, "prop_dynamic")) != -1)
	{
		if (g_WeaponIndexes[weapon] == -1)
			continue;
		
		GetEntityOrigin(weapon, origin);
		index = g_WeaponIndexes[weapon];

		if (index == 642 || index == 231 || index == 57)
			origin[2] += 40.0;
		
		TE_SetupGlowSprite(origin, g_WeaponGlow, 1.0, 1.0, 255);
		TE_SendToAll();

		TF2_GetWeaponNameFromIndex(index, sName, sizeof(sName));

		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerAlive(i) || IsFakeClient(i))
				continue;
			
			if (GetEntitiesDistance(i, weapon) >= 150.0)
			{
				if (g_NearWeapon[i] == EntIndexToEntRef(weapon))
					g_NearWeapon[i] = INVALID_ENT_REFERENCE;
			}
			else
			{
				g_NearWeapon[i] = EntIndexToEntRef(weapon);
				PrintSilentHint(i, "Weapon Found - [%s]", sName);
			}
		}
	}
}

public void OnMapStart()
{
	PrecacheSound(FLASHLIGHT_CLICKSOUND);
	
	PrecacheModel("models/player/demo.mdl");
	PrecacheModel("models/workshop_partner/player/items/demo/tw_doghat/tw_doghat_demo.mdl");

	PrecacheModel("models/props_urban/urban_crate001.mdl");
	PrecacheModel("models/props_urban/urban_crate002.mdl");
	g_WeaponGlow = PrecacheModel("sprites/light_glow03.vmt");

	PrecacheSound("misc/halloween/spell_bat_cast.wav");
	PrecacheSound("weapons/grappling_hook_impact_flesh.wav");
	PrecacheSound("player/taunt_yeti_standee_speaker_growl.wav");

	char sModel[PLATFORM_MAX_PATH]; char sIndex[16];
	
	for (int i = 0; i < g_RandomWeapons.Length; i++)
	{
		IntToString(g_RandomWeapons.Get(i), sIndex, sizeof(sIndex));
		g_WeaponWorldModels.GetString(sIndex, sModel, sizeof(sModel));

		if (strlen(sModel) > 0)
			PrecacheModel(sModel);
	}
	
	for (int i = 0; i < g_CrateWeapons.Length; i++)
	{
		IntToString(g_CrateWeapons.Get(i), sIndex, sizeof(sIndex));
		g_WeaponWorldModels.GetString(sIndex, sModel, sizeof(sModel));

		if (strlen(sModel) > 0)
			PrecacheModel(sModel);
	}

	PrecacheSound("ui/item_default_pickup.wav");
	PrecacheSound("ui/item_hat_pickup.wav");
	PrecacheSound("items/para_open.wav");
	PrecacheSound("items/para_close.wav");

	PrecacheSound("vo/announcer_attention.mp3");
	PrecacheSound("vo/announcer_begins_10sec.mp3");
	PrecacheSound("vo/announcer_begins_5sec.mp3");
	PrecacheSound("vo/announcer_begins_4sec.mp3");
	PrecacheSound("vo/announcer_begins_3sec.mp3");
	PrecacheSound("vo/announcer_begins_2sec.mp3");
	PrecacheSound("vo/announcer_begins_1sec.mp3");
	PrecacheSound("vo/announcer_am_lastmanalive01.mp3");
	PrecacheSound("vo/announcer_am_lastmanalive04.mp3");

	PrecacheSound("misc/wolf_howl_01.wav");
	PrecacheSound("misc/wolf_howl_02.wav");
	PrecacheSound("misc/wolf_howl_03.wav");
}

public void OnMapEnd()
{
	g_Timer_RoundTimer = null;
}

public void OnConfigsExecuted()
{
	StripConVarFlag(FindConVar("mp_respawnwavetime"), FCVAR_NOTIFY);
	FindConVar("mp_respawnwavetime").FloatValue = 0.0;
	
	FindConVar("mp_friendlyfire").BoolValue = true;
	FindConVar("mp_autoteambalance").BoolValue = false;

	if (g_Late)
	{
		g_Late = false;
		TF2_RespawnAll();
	}
}

public Action Command_RegenWeapons(int client, int args)
{
	CPrintToChat(client, "Regenerating weapons on the map...");
	SpawnRandomWeapons(client);
	return Plugin_Handled;
}

void SpawnRandomWeapons(int client = 0)
{
	ClearAllWeapons();

	int count; int entity = -1; char name[64]; float origin[3]; float angle[3]; int index;
	while ((entity = FindEntityByClassname(entity, "info_target")) != -1)
	{
		ResetVector(origin);
		ResetVector(angle);
		
		index = -1;
		GetEntityName(entity, name, sizeof(name));

		if (!StrEqual(name, "onWeaponSpawn", false))
			continue;
		
		GetEntityOrigin(entity, origin);
		GetEntityAngles(entity, angle);
		index = g_RandomWeapons.Get(GetRandomInt(0, g_RandomWeapons.Length - 1));

		if (index < 1 || GetRandomFloat(0.0, 100.0) >= 50.0)
			continue;

		SpawnWeapon(index, origin, angle);
		count++;
	}

	CPrintToChat(client, "%i Weapons have been regenerated.", count);
}

public Action Command_SpawnWeapon(int client, int args)
{
	int index = GetCmdArgInt(1);

	float origin[3];
	GetClientLookOrigin(client, origin);

	char sWeapon[64];
	TF2_GetWeaponNameFromIndex(index, sWeapon, sizeof(sWeapon));

	SpawnWeapon(index, origin, view_as<float>({0.0, 0.0, 0.0}));
	CPrintToChat(client, "Weapon '%s' with the index '%i' spawned.", sWeapon, index);

	return Plugin_Handled;
}

void SpawnWeapon(int index, float origin[3], float angle[3])
{
	char sIndex[16];
	IntToString(index, sIndex, sizeof(sIndex));

	char sModel[PLATFORM_MAX_PATH];
	g_WeaponWorldModels.GetString(sIndex, sModel, sizeof(sModel));

	if (index == 642 || index == 231)
		origin[2] -= 35.0;
	else if (index == 57)
		origin[2] -= 65.0;
	
	int weapon = -1;
	if ((weapon = CreateProp(sModel, origin, angle, 0, false)) != -1)
		g_WeaponIndexes[weapon] = index;
}

void ClearAllWeapons()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{
		if (g_WeaponIndexes[entity] == -1)
			continue;
		
		g_WeaponIndexes[entity] = -1;
		AcceptEntityInput(entity, "Kill");
	}
}

public Action Command_PauseTimer(int client, int args)
{
	g_PauseTimer = !g_PauseTimer;
	ReplyToCommand(client, "Timer has been %s.", g_PauseTimer ? "paused" : "unpaused");
	return Plugin_Handled;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (IsClassname(entity, "trigger_multiple"))
		SDKHook(entity, SDKHook_SpawnPost, OnTriggerSpawnPost);

	if (IsClassname(entity, "item_currencypack_custom"))
		AcceptEntityInput(entity, "Kill");
}

public void OnTriggerSpawnPost(int entity)
{
	if (IsName(entity, "onLocust"))
	{
		SDKHook(entity, SDKHook_StartTouch, OnLocustTouchStart);
		SDKHook(entity, SDKHook_EndTouch, OnLocustTouchEnd);
	}
}

public Action OnLocustTouchStart(int entity, int other)
{
	if (!IsPlayerIndex(other))
		return;

	if (g_LocustTimer[other] != null)
		return;
	
	ScreenFade(other, 10, 9999999, FFADE_IN, view_as<int>({0, 0, 0, 200}), true);

	SetEntityRenderMode(other, RENDER_TRANSCOLOR);
	SetEntityRenderColor(other, 0, 0, 0, 255);
	
	g_LocustTicks[other] = 0;
	g_LocustMulti[other] = 0;
	g_LocustModifier[other] = 1;
	g_LocustTimer[other] = CreateTimer(0.3, Timer_Locust, other, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Locust(Handle timer, any data)
{
	int client = data;

	if (!IsPlayerIndex(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		g_LocustTimer[client] = null;
		return Plugin_Stop;
	}

	g_LocustTicks[client]++;

	if (g_LocustTicks[client] >= 10)
	{
		g_LocustMulti[client]++;

		if (g_LocustMulti[client] >= 5)
		{
			g_LocustModifier[client]++;
			g_LocustMulti[client] = 0;
		}
	}

	SDKHooks_TakeDamage(client, 0, 0, (1.0 * g_LocustModifier[client]), DMG_BURN);
	EmitSoundToClient(client, "misc/halloween/spell_bat_cast.wav");

	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);
	CreateParticle("hwn_bats01", vecOrigin, 2.0);
	
	return Plugin_Continue;
}

public Action OnLocustTouchEnd(int entity, int other)
{
	if (!IsPlayerIndex(other))
		return;

	if (g_LocustTimer[other] == null)
		return;
	
	g_LocustTicks[other] = 0;
	g_LocustMulti[other] = 0;
	g_LocustModifier[other] = 1;
	StopTimer(g_LocustTimer[other]);

	ScreenFade(other, 1, 1, FFADE_PURGE, view_as<int>({0, 0, 0, 200}), true);

	SetEntityRenderMode(other, RENDER_NORMAL);
	SetEntityRenderColor(other, 255, 255, 255, 255);
}

public void OnEntityDestroyed(int entity)
{
	if (entity > 0)
	{
		g_WeaponIndexes[entity] = -1;
		g_TickDelay[entity] = -1;

		if (entity == g_Werewolf.GetEntity())
		{
			float origin[3];
			GetEntityOrigin(entity, origin);

			float angles[3];
			GetEntityAngles(entity, angles);

			TF2_CreateRagdoll(origin, angles, 4, 2, 0, 30.0);
		}
	}
	
	int owner = -1;
	if (HasClassname(entity, "tf_projectile_jar") && (owner = GetEntityThrower(entity)) != -1)
		TF2_RemoveWeaponSlot(owner, TFWeaponSlot_Secondary);
}

public void TF2_OnRoundActive()
{
	if (GetClientAliveCount() > 1)
		StartMatch();
}

public void TF2_OnRoundEnd(int team, int winreason, int flagcaplimit, bool full_round, float round_time, int losing_team_num_caps, bool was_sudden_death)
{
	EndMatch();
}

public Action Command_StartMatch(int client, int args)
{
	StartMatch(true, true);
	CPrintToChatAll("%N has forced the match to start.", client);
	return Plugin_Handled;
}

void StartMatch(bool respawn_all = false, bool force = false)
{
	if (TF2_IsWaitingForPlayers() || g_IsGameLive)
		return;
	
	g_RoundStartTime = convar_StartTimer.IntValue;

	StopTimer(g_Timer_RoundStart);
	g_Timer_RoundStart = CreateTimer(1.0, Timer_StartRound, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	g_IsGameLive = true;
	g_IsForceStart = force;

	if (respawn_all)
		TF2_RespawnAll();

	FindConVar("mp_disable_respawn_times").IntValue = 0;

	EmitSoundToAll("vo/announcer_attention.mp3");
}

void EndMatch()
{
	g_IsGameLive = false;
	g_IsForceStart = false;

	g_RoundStartTime = g_RoundStartTime = convar_StartTimer.IntValue;
	StopTimer(g_Timer_RoundStart);

	g_RoundTimer = convar_RoundTime.FloatValue;
	StopTimer(g_Timer_RoundTimer);
	ClearSyncHudAll(g_Sync_RoundTimer);

	StopTimer(g_Timer_CratesTimer);
	StopTimer(g_Timer_WerewolfTimer);
	DeleteCrate();

	for (int i = 1; i <= MaxClients; i++)
	{
		g_IsPlaying[i] = false;
		g_ExtraLives[i] = 0;
	}
	
	FindConVar("mp_respawnwavetime").FloatValue = 0.0;
}

public Action Timer_StartRound(Handle timer)
{
	if (GetClientAliveCount() < 1)
	{
		g_IsGameLive = false;
		g_Timer_RoundStart = null;
		return Plugin_Stop;
	}

	if (g_RoundStartTime > 0)
	{
		if (g_RoundStartTime == 10)
			EmitSoundToAll("vo/announcer_begins_10sec.mp3");
		else if (g_RoundStartTime <= 5)
		{
			char sSound[PLATFORM_MAX_PATH];
			FormatEx(sSound, sizeof(sSound), "vo/announcer_begins_%isec.mp3", g_RoundStartTime);
			EmitSoundToAll(sSound);
		}

		if (g_RoundStartTime > 5)
			PrintSilentHintAll("Round Starts: %i", g_RoundStartTime);
		else
			PrintHintTextToAll("Round Starts: %i", g_RoundStartTime);
		
		g_RoundStartTime--;
		return Plugin_Continue;
	}

	FindConVar("mp_respawnwavetime").FloatValue = 99999.0;

	StartGameTimer();
	SpawnRandomWeapons();
	SpawnPlayers();
	StartCratesTimer();
	StartWerewolfTimer();

	if (g_IsGameLive)
		CreateTimer(0.5, Frame_CheckForEnd, _, TIMER_FLAG_NO_MAPCHANGE);

	char sSound[PLATFORM_MAX_PATH];
	FormatEx(sSound, sizeof(sSound), GetRandomFloat(0.0, 100.0) >= 50.0 ? "vo/announcer_am_lastmanalive01.mp3" : "vo/announcer_am_lastmanalive04.mp3");
	EmitSoundToAll(sSound);

	g_Timer_RoundStart = null;
	return Plugin_Stop;
}

void SpawnPlayers()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		TeleportToMap(i);
	}
}

bool g_Jump[MAXPLAYERS + 1];
bool g_StripParachute[MAXPLAYERS + 1];

void TeleportToMap(int client)
{
	float vecOrigin[3];
	GetRandomPostion(vecOrigin, 2000.0, 3500.0);
	TeleportEntity(client, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	g_IsPlaying[client] = true;

	TF2_GiveItem(client, "tf_weapon_parachute", 1101);

	CreateTimer(1.0, Timer_Jump, GetClientUserId(client));
}

public Action Timer_Jump(Handle timer, any data)
{
	int client;

	if ((client = GetClientOfUserId(data)) > 0 && IsClientInGame(client) && IsPlayerAlive(client))
		g_Jump[client] = true;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (g_Jump[client])
	{
		g_Jump[client] = false;
		g_StripParachute[client] = true;
		buttons |= IN_JUMP;
	}

	if (g_StripParachute[client] && (GetEntityFlags(client) & FL_ONGROUND || GetEntityWaterlevel(client) > 0))
	{
		g_StripParachute[client] = false;
		RemovePlayerBack(client);
		TF2_RemoveWeaponSlot(client, 1);
	}
}

public Action TF2_OnCallMedic(int client)
{
	if (g_NearWeapon[client] != INVALID_ENT_REFERENCE)
	{
		int near_weapon = EntRefToEntIndex(g_NearWeapon[client]);

		if (IsValidEntity(near_weapon))
		{
			int index = g_WeaponIndexes[near_weapon];

			char class[64];
			TF2Econ_GetItemClassName(index, class, sizeof(class));

			int slot = TF2Econ_GetItemSlot(index, TF2_GetPlayerClass(client));
			//int current = GetPlayerWeaponSlot(client, slot);

			/*if (IsValidEntity(current))
			{
				float vecOrigin[3];
				GetClientAbsOrigin(client, vecOrigin);

				float vecAngles[3];
				GetClientAbsAngles(client, vecAngles);

				SpawnWeapon(GetWeaponIndex(current), vecOrigin, vecAngles, false);
			}*/

			if (slot == 1)
				RemovePlayerBack(client);
			
			TF2_RemoveWeaponSlot(client, slot);
			
			char sIndex[16];
			IntToString(index, sIndex, sizeof(sIndex));
			
			if (StrContains(class, "tf_wearable") != -1)
			{
				int wearable = TF2Items_EquipWearable(client, class, index);

				if (index == 57)
					g_ExtraLives[client] = 1;
				else if (index == 642)
				{
					TF2Attrib_SetByDefIndex(wearable, 57, 1.0);
					g_ExtraLives[client] = 0;
				}
				else if (index == 231)
				{
					TF2Attrib_SetByDefIndex(wearable, 26, 175.0);
					SetEntityHealth(client, 300);
					g_ExtraLives[client] = 0;
				}
			}
			else
			{
				if (slot == 1)
					g_ExtraLives[client] = 0;
				
				int weapon = TF2_GiveItem(client, class, index);
				
				if (IsValidEntity(weapon))
				{
					EquipWeapon(client, weapon);
					
					int clip;
					if (g_WeaponMags.GetValue(sIndex, clip) && clip > 0)
						SetClip(weapon, clip);
						
					int ammo;
					if (g_WeaponAmmo.GetValue(sIndex, ammo) && ammo > 0)
						SetAmmo(client, weapon, ammo);
				}
			}
			
			EmitSoundToClient(client, GetRandomFloat(0.0, 100.0) >= 50.0 ? "ui/item_default_pickup.wav" : "ui/item_hat_pickup.wav");
			
			AcceptEntityInput(near_weapon, "Kill");
			g_NearWeapon[client] = INVALID_ENT_REFERENCE;
		}
	}

	return Plugin_Stop;
}

void RemovePlayerBack(int client)
{
	int edict = MaxClients+1;
	while((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		char netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			int idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if ((idx == 57 || idx == 133 || idx == 231 || idx == 444 || idx == 642) && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
				AcceptEntityInput(edict, "Kill");
		}
	}
}

int FindEntityByClassname2(int startEnt, const char[] classname)
{
	while (startEnt > -1 && !IsValidEntity(startEnt))
		startEnt--;
	
	return FindEntityByClassname(startEnt, classname);
}

public void OnGameFrame()
{
	if (g_Crate != INVALID_ENT_REFERENCE && IsValidEntity(g_Crate) && !IsModel(g_Crate, "models/props_urban/urban_crate001.mdl"))
	{
		float origin[3];
		GetEntPropVector(g_Crate, Prop_Send, "m_vecOrigin", origin);

		origin[2] -= 1.0;
		TeleportEntity(g_Crate, origin, NULL_VECTOR, NULL_VECTOR);

		if (g_Ground[2] > origin[2])
		{
			EmitGameSoundToAll("Wood_Crate.Break", g_Crate);
			TE_Particle("crate_drop", origin, g_Crate);

			int child = GetEntPropEnt(g_Crate, Prop_Data, "m_hMoveChild");

			if (IsValidEntity(child) && child > 0)
				AcceptEntityInput(child, "Kill");

			SetEntityModel(g_Crate, "models/props_urban/urban_crate001.mdl");
			
			origin[2] += 20.0;
			if (GetRandomFloat(0.0, 100.0) > 75.0)
				TF2_SpawnPickup(origin, PICKUP_TYPE_AMMOBOX, PICKUP_MEDIUM);
			else
			{
				int index = g_CrateWeapons.Get(GetRandomInt(0, g_CrateWeapons.Length - 1));
				SpawnWeapon(index, origin, NULL_VECTOR);
			}
		}
	}
}

public void TF2_OnPlayerSpawn(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	TF2_SetPlayerClass(client, TFClass_Sniper);
	SetEntityHealth(client, 1);
	TF2_RemoveAllWearables(client);
	TF2_RegeneratePlayer(client);
	TF2_RemoveAllWeapons(client);
	
	int kukri = -1;
	if ((kukri = TF2_GiveItem(client, "tf_weapon_club", 3)) != -1)
		EquipWeapon(client, kukri);
	
	if (g_IsGameLive)
	{
		if (g_RoundStartTime < 1)
			TeleportToMap(client);
	}
	else
	{
		if (GetClientAliveCount() < 2 && !g_IsForceStart)
		{
			RequestFrame(Frame_DelayWait, GetClientUserId(client));
		}
		else
			StartMatch();
	}
}

public void Frame_DelayWait(int data)
{
	int client;
	if ((client = GetClientOfUserId(data)) == 0)
		return;
	
	CPrintToChat(client, "Waiting for at least 2 players to start the match.");
	CPrintToChat(client, "Moving to map in 3 seconds...");
	CreateTimer(3.0, Timer_MoveToMap, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_MoveToMap(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && !g_IsGameLive && g_RoundStartTime < 1)
		TeleportEntity(client, view_as<float>({223.92, -143.19, 205.0}), view_as<float>({4.93, -178.75, 0.0}), NULL_VECTOR);
	
	return Plugin_Continue;
}

public void TF2_OnPlayerDeath(int client, int attacker, int assister, int inflictor, int damagebits, int stun_flags, int death_flags, int customkill)
{
	if (g_IsGameLive)
		CreateTimer(0.5, Frame_CheckForEnd, _, TIMER_FLAG_NO_MAPCHANGE);

	if (g_Timer_RoundStart == null && !g_IsGameLive)
		CreateTimer(5.0, Timer_Respawn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	
	TF2Attrib_RemoveByDefIndex(client, 26);
	
	if (inflictor == g_Werewolf.GetEntity())
		RequestFrame(Frame_CreateRagdoll, GetClientUserId(client));
}

public void Frame_CreateRagdoll(any data)
{
	int client;
	if ((client = GetClientOfUserId(data)) > 0)
	{
		TF2_RemoveRagdoll(client);
		TF2_SpawnRagdoll(client, 60.0, RAG_GIBBED);

		EmitSoundToAll("player/taunt_yeti_standee_speaker_growl.wav", client);
	}
}

public Action Frame_CheckForEnd(Handle timer, any data)
{
	int alive = GetClientAliveCount();

	if (g_IsGameLive && g_RoundStartTime < 1)
	{
		if (alive == 2)
			SendDuelRequests();
		else if (alive == 1 && !g_IsForceStart)
		{
			TFTeam team;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || IsClientSourceTV(i) || !IsPlayerAlive(i))
					continue;

				PrintCenterTextAll("%N is the winner! SANDVICH!", i);
				TF2_SetPlayerClass(i, TFClass_Heavy);
				TF2_RemoveAllWearables(i);
				TF2_RemoveAllWeapons(i);
				TF2_RegeneratePlayer(i);
				
				int sandvich = TF2_GiveItem(i, "tf_weapon_lunchbox", 42);
				
				if (IsValidEntity(sandvich))
					EquipWeapon(i, sandvich);
				
				team = TF2_GetClientTeam(i);
			}

			TF2_ForceWin(team);
		}
		else if (alive < 1)
			TF2_ForceWin(TFTeam_Unassigned);
	}
}

public Action Timer_Respawn(Handle timer, any data)
{
	int client;
	if ((client = GetClientOfUserId(data)) > 0 && IsClientInGame(client) && !IsPlayerAlive(client))
		TF2_RespawnPlayer(client);
}

public Action OnClientCommand(int client, int args)
{
	char sCommand[32];
	GetCmdArg(0, sCommand, sizeof(sCommand));

	char sArg1[32];
	GetCmdArg(1, sArg1, sizeof(sArg1));
	
	if (StrEqual(sCommand, "jointeam", false))
	{
		int team = 0;

		if (IsStrNum(sArg1))
			team = GetCmdArgInt(1);
		else if (StrEqual(sArg1, "auto", false))
			team = 0;
		else if (StrEqual(sArg1, "red", false))
			team = 2;
		else if (StrEqual(sArg1, "blue", false))
			team = 3;

		if (g_IsGameLive)
		{
			if (g_IsPlaying[client])
			{
				CPrintToChat(client, "You cannot switch teams during the active match.");
				return Plugin_Stop;
			}
			else if (team > 1)
			{
				CPrintToChat(client, "Please wait for the current match to end.");
				return Plugin_Stop;
			}
		}
		else if (GetClientTeam(client) > 1)
			TF2_RespawnPlayer(client);
	}
	else if (StrEqual(sCommand, "joinclass", false) && !StrEqual(sArg1, "sniper"))
	{
		if (IsPlayerAlive(client))
		{
			CPrintToChat(client, "You aren't allowed to switch your class.");

			if (TF2_GetPlayerClass(client) != TFClass_Sniper && !g_IsGameLive)
			{
				TF2_SetPlayerClass(client, TFClass_Sniper);
				TF2_RegeneratePlayer(client);
			}
		}
		else
			FakeClientCommand(client, "joinclass sniper");

		return Plugin_Stop;
	}

	return Plugin_Continue;
}

#define SF2_FLASHLIGHT_WIDTH 512.0
#define SF2_FLASHLIGHT_LENGTH 1024.0
#define SF2_FLASHLIGHT_BRIGHTNESS 0

static int g_iPlayerFlashlightEnt[MAXPLAYERS + 1] = { INVALID_ENT_REFERENCE, ... };
static int g_iPlayerFlashlightEntAng[MAXPLAYERS + 1] = { INVALID_ENT_REFERENCE, ... };

public Action OnClientCommandKeyValues(int client, KeyValues kv)
{	
	char sName[64];
	kv.GetSectionName(sName, sizeof(sName));

	if (StrContains(sName, "use_action_slot_item_server", false) != -1)
		return Plugin_Stop;
	
	if (StrEqual(sName, "+inspect_server", false))
	{
		if (IsClientUsingFlashlight(client))
			ClientTurnOffFlashlight(client);
		else
			ClientTurnOnFlashlight(client);
		
		EmitSoundToAll(FLASHLIGHT_CLICKSOUND, client, SNDCHAN_STATIC, SNDLEVEL_DRYER);
		
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

bool IsClientUsingFlashlight(int client)
{
	return g_bPlayerFlashlight[client];
}

void ClientTurnOnFlashlight(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	if (IsClientUsingFlashlight(client))
		return;
	
	g_bPlayerFlashlight[client] = true;
	
	float flEyePos[3];
	GetClientEyePosition(client, flEyePos);
	
	int entity = CreateEntityByName("light_dynamic");
	if (entity != -1)
	{
		TeleportEntity(entity, flEyePos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(entity, "targetname", "WUBADUBDUBMOTHERBUCKERS");
		DispatchKeyValue(entity, "rendercolor", "255 255 255");
		SetVariantFloat(SF2_FLASHLIGHT_WIDTH);
		AcceptEntityInput(entity, "spotlight_radius");
		SetVariantFloat(SF2_FLASHLIGHT_LENGTH);
		AcceptEntityInput(entity, "distance");
		SetVariantInt(SF2_FLASHLIGHT_BRIGHTNESS);
		AcceptEntityInput(entity, "brightness");
		
		float cone = 55.0;
		cone *= 0.75;
		
		SetVariantInt(RoundToFloor(cone));
		AcceptEntityInput(entity, "_inner_cone");
		SetVariantInt(RoundToFloor(cone));
		AcceptEntityInput(entity, "_cone");
		DispatchSpawn(entity);
		ActivateEntity(entity);
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client);
		AcceptEntityInput(entity, "TurnOn");
		
		g_iPlayerFlashlightEnt[client] = EntIndexToEntRef(entity);
		
		SDKHook(entity, SDKHook_SetTransmit, Hook_FlashlightSetTransmit);
	}
	
	entity = CreateEntityByName("point_spotlight");
	if (entity != -1)
	{
		TeleportEntity(entity, flEyePos, NULL_VECTOR, NULL_VECTOR);
		
		char sBuffer[256];
		FloatToString(SF2_FLASHLIGHT_LENGTH, sBuffer, sizeof(sBuffer));
		DispatchKeyValue(entity, "spotlightlength", sBuffer);
		FloatToString(SF2_FLASHLIGHT_WIDTH, sBuffer, sizeof(sBuffer));
		DispatchKeyValue(entity, "spotlightwidth", sBuffer);
		DispatchKeyValue(entity, "rendercolor", "255 255 255");
		DispatchSpawn(entity);
		ActivateEntity(entity);
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client);
		AcceptEntityInput(entity, "LightOn");
		
		g_iPlayerFlashlightEntAng[client] = EntIndexToEntRef(entity);
	}
}

public Action Hook_FlashlightSetTransmit(int entity,int other)
{	
	if (EntRefToEntIndex(g_iPlayerFlashlightEnt[other]) != entity)
		return Plugin_Handled;
			
	return Plugin_Continue;
}

void ClientTurnOffFlashlight(int client)
{
	if (!IsClientUsingFlashlight(client))
		return;
	
	g_bPlayerFlashlight[client] = false;
	
	int entity = EntRefToEntIndex(g_iPlayerFlashlightEnt[client]);
	if (entity && entity != INVALID_ENT_REFERENCE) 
	{
		AcceptEntityInput(entity, "TurnOff");
		AcceptEntityInput(entity, "Kill");
	}
	
	entity = EntRefToEntIndex(g_iPlayerFlashlightEntAng[client]);
	if (entity && entity != INVALID_ENT_REFERENCE) 
	{
		AcceptEntityInput(entity, "LightOff");
		CreateTimer(0.1, Timer_KillEntity, g_iPlayerFlashlightEntAng[client], TIMER_FLAG_NO_MAPCHANGE);
	}
	
	g_iPlayerFlashlightEnt[client] = INVALID_ENT_REFERENCE;
	g_iPlayerFlashlightEntAng[client] = INVALID_ENT_REFERENCE;
}

public Action Timer_KillEntity(Handle timer, any entref)
{
	int entity = EntRefToEntIndex(entref);
	
	if (entity == INVALID_ENT_REFERENCE)
		return;
	
	AcceptEntityInput(entity, "Kill");
}

public void OnClientPutInServer(int client)
{
	if (g_IsGameLive)
		TF2_ChangeClientTeam(client, TFTeam_Spectator);
	
	SDKHook(client, SDKHook_PreThink, Hook_ClientPreThink);
}

public void Hook_ClientPreThink(int client)
{
	if (!IsClientInGame(client))
		return;
	
	if (IsPlayerAlive(client))
	{		
		if (IsClientUsingFlashlight(client))
		{
			int fl = EntRefToEntIndex(g_iPlayerFlashlightEnt[client]);
			if (fl && fl != INVALID_ENT_REFERENCE)
				TeleportEntity(fl, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }), NULL_VECTOR);
			
			fl = EntRefToEntIndex(g_iPlayerFlashlightEntAng[client]);
			if (fl && fl != INVALID_ENT_REFERENCE)
			{
				float eyeAng[3];
				GetClientEyeAngles(client, eyeAng);
				
				float ang2[3];
				GetClientAbsAngles(client, ang2);
				
				SubtractVectors(eyeAng, ang2, eyeAng);
				TeleportEntity(fl, NULL_VECTOR, eyeAng, NULL_VECTOR);
			}
		}
	}
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle& hItem)
{
	return Plugin_Continue;
}

public void TF2Items_OnGiveNamedItem_Post(int client, char[] classname, int itemDefinitionIndex, int itemLevel, int itemQuality, int entityIndex)
{
	SetEntProp(entityIndex, Prop_Send, "m_bValidatedAttachedEntity", 1);
}

void StartGameTimer()
{
	g_PauseTimer = false;

	/*int entity = CreateEntityByName("team_round_timer");
	DispatchKeyValue(entity, "timer_length", "180");
	DispatchKeyValue(entity, "max_length", "180");
	DispatchKeyValue(entity, "setup_length", "20");
	DispatchKeyValue(entity, "reset_time", "1");
	DispatchKeyValue(entity, "show_in_hud", "1");
	DispatchKeyValue(entity, "StartDisabled", "0");
	DispatchKeyValue(entity, "auto_countdown", "1");
	DispatchKeyValue(entity, "start_paused", "0");
	DispatchKeyValue(entity, "show_time_remaining", "1");
	DispatchSpawn(entity);
	
	SetVariantInt(convar_RoundTime.IntValue);
	AcceptEntityInput(entity, "SetTime");

	SetVariantInt(1);
	AcceptEntityInput(entity, "ShowInHUD");

	SetVariantInt(1);
	AcceptEntityInput(entity, "AutoCountdown", entity);

	AcceptEntityInput(entity, "Enable");
	AcceptEntityInput(entity, "Resume");

	RequestFrame(Test, entity);*/

	g_RoundTimer = convar_RoundTime.FloatValue;
	ClearSyncHudAll(g_Sync_RoundTimer);
	
	StopTimer(g_Timer_RoundTimer);
	g_Timer_RoundTimer = CreateTimer(1.0, Timer_RoundTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/*public void Test(any data)
{
	AcceptEntityInput(data, "Enable");

	SetVariantInt(1);
	AcceptEntityInput(data, "ShowInHUD");
}*/

public Action Timer_RoundTimer(Handle timer, any data)
{
	if (!g_PauseTimer)
		g_RoundTimer--;

	char sTime[32];
	FormatSeconds(g_RoundTimer, sTime, sizeof(sTime), "%M:%S", false);

	SetHudTextParams(0.15, 0.95, 1.0, 255, 255, 255, 255);
	ShowSyncHudTextAll(g_Sync_RoundTimer, "::%s", sTime);

	if (g_RoundTimer > 0.0)
		return Plugin_Continue;
	
	TF2_ForceWin();

	g_Timer_RoundTimer = null;
	return Plugin_Stop;
}

void StartCratesTimer()
{
	StopTimer(g_Timer_CratesTimer);
	g_Timer_CratesTimer = CreateTimer(GetRandomFloat(60.0, convar_RoundTime.FloatValue), Timer_CratesTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_CratesTimer(Handle timer, any data)
{
	SpawnCrate();
	g_Timer_CratesTimer = null;
	return Plugin_Stop;
}

void SpawnCrate()
{
	DeleteCrate();
	
	int crate = CreateEntityByName("prop_dynamic_override");

	if (!IsValidEntity(crate))
		return;

	float origin[3];
	GetRandomPostion(origin, 2000.0, 3500.0);
	
	DispatchKeyValue(crate, "model", "models/props_urban/urban_crate002.mdl");
	DispatchKeyValueVector(crate, "origin", origin);
	DispatchSpawn(crate);

	GetEntGroundCoordinates(crate, g_Ground);
	TF2_CreateGlow("crate_glow", crate);
	TE_Particle("eyeboss_aura_calm", origin, crate);

	EmitGameSoundToAll("ui/mm_queue.wav");
	g_Crate = EntIndexToEntRef(crate);
}

void DeleteCrate()
{
	if (g_Crate != INVALID_ENT_REFERENCE && IsValidEntity(g_Crate))
	{
		AcceptEntityInput(g_Crate, "Kill");
		g_Crate = INVALID_ENT_REFERENCE;
	}
}

void StartWerewolfTimer()
{
	StopTimer(g_Timer_WerewolfTimer);
	g_Timer_WerewolfTimer = CreateTimer(GetRandomFloat(30.0, convar_RoundTime.FloatValue), Timer_WerewolfTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_WerewolfTimer(Handle timer, any data)
{
	//SpawnWerewolf();
	g_Timer_WerewolfTimer = null;
	return Plugin_Stop;
}

public void OnClientConnected(int client)
{
	ServerCommand("mp_waitingforplayers_cancel 1");
}

public void OnClientDisconnect(int client)
{
	if (g_IsGameLive)
		CreateTimer(0.5, Frame_CheckForEnd, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientDisconnect_Post(int client)
{
	g_IsPlaying[client] = false;

	g_ExtraLives[client] = 0;
}

public Action Command_SpawnWolf(int client, int args)
{
	SpawnWerewolf();
	ReplyToCommand(client, "Werewolf has been spawned.");
	return Plugin_Handled;
}

stock void SpawnWerewolf()
{
	TriggerEntity("onPlayBell");

	int spawn = FindEntityByName("onBossSpawn", "info_target");

	if (!IsValidEntity(spawn))
		return;

	float origin[3];
	origin[0] = 6709.46;
	origin[1] = -3443.10;
	origin[2] = 342.00;
	//GetEntityOrigin(spawn, origin);
	
	g_Werewolf = new CBaseNPC();
	g_Werewolf.Teleport(origin);
	g_Werewolf.SetModel("models/player/demo.mdl");
	g_Werewolf.Spawn();
	g_Werewolf.SetThinkFunction(Hook_NPCThink);

	g_Werewolf.EquipItem("head", "models/workshop_partner/player/items/demo/tw_doghat/tw_doghat_demo.mdl");

	g_Werewolf.flStepSize = 25.0;
	g_Werewolf.flGravity = 800.0;
	g_Werewolf.flAcceleration = 6000.0;
	g_Werewolf.flJumpHeight = 300.0;
	g_Werewolf.flWalkSpeed = 600.0;
	g_Werewolf.flRunSpeed = 600.0;
	g_Werewolf.flDeathDropHeight = 3000.0;

	g_Werewolf.iMaxHealth = 1500;
	g_Werewolf.iHealth = 1500;
	
	g_Werewolf.Run();

	CBaseAnimatingOverlay animationEntity = CBaseAnimatingOverlay(g_Werewolf.GetEntity());
	animationEntity.PlayAnimation("stand_MELEE");

	g_flLastAttackTime = 0.0;
	g_Pathing = PathFollower(_, Path_FilterIgnoreActors, Path_FilterOnlyActors);

	SetRandomWerewolfTarget();
	
	char sSound[PLATFORM_MAX_PATH];
	FormatEx(sSound, sizeof(sSound), "misc/wolf_howl_0%i.wav", GetRandomInt(1, 3));
	EmitSoundToAll(sSound);
}

public Action Command_TeleportWolf(int client, int args)
{
	if (!TheNPCs.IsValidNPC(g_Werewolf))
	{
		ReplyToCommand(client, "Werewolf is not active.");
		return Plugin_Handled;
	}

	float eyePos[3], eyeAng[3], endPos[3];
	GetClientEyePosition(client, eyePos);
	GetClientEyeAngles(client, eyeAng);
	
	Handle hTrace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_NPCSOLID, RayType_Infinite, TraceRayDontHitEntity, client);
	TR_GetEndPosition(endPos, hTrace);
	delete hTrace;
	
	g_Werewolf.Teleport(endPos);

	return Plugin_Handled;
}

public bool TraceRayDontHitEntity(int entity, int mask, any data)
{
	if (entity == data) return false;
	if (entity != 0) return false;
	return true;
}

public Action Command_SetWolfTarget(int client, int args)
{
	if (!TheNPCs.IsValidNPC(g_Werewolf))
	{
		ReplyToCommand(client, "Werewolf is not active.");
		return Plugin_Handled;
	}

	int target = GetCmdArgTarget(client, 1);

	if (target == -1)
	{
		ReplyToCommand(client, "Target not found, please try again.");
		return Plugin_Handled;
	}

	SetWerewolfTarget(target);
	ReplyToCommand(client, "Werewolf has been set on %N.", target);

	return Plugin_Handled;
}

void SetWerewolfTarget(int target)
{
	g_Target = target;
	TF2_AddCondition(g_Target, TFCond_MarkedForDeath, TFCondDuration_Infinite);
}

public Action Command_RandomWolfTarget(int client, int args)
{
	if (!TheNPCs.IsValidNPC(g_Werewolf))
	{
		ReplyToCommand(client, "Werewolf is not active.");
		return Plugin_Handled;
	}

	SetRandomWerewolfTarget();
	ReplyToCommand(client, "Werewolf has been randomly set on %N.", g_Target);

	return Plugin_Handled;
}

void SetRandomWerewolfTarget()
{
	if (GetClientAliveCount() < 1)
		return;
	
	g_Target = GetRandomClient();
	TF2_AddCondition(g_Target, TFCond_MarkedForDeath, TFCondDuration_Infinite);
}

public void Hook_NPCThink(int iEnt)
{
	CBaseNPC npc = TheNPCs.FindNPCByEntIndex(iEnt);

	if (npc == INVALID_NPC)
		return;

	if (!IsPlayerIndex(g_Target) || !IsClientInGame(g_Target) || !IsPlayerAlive(g_Target))
		SetRandomWerewolfTarget();
	
	INextBot bot = npc.GetBot();

	int time = GetTime();
	if (g_TickDelay[iEnt] == -1 || g_TickDelay[iEnt] < time)
	{
		g_TickDelay[iEnt] = time + 1;
		g_Pathing.ComputeToTarget(bot, g_Target);
		g_Pathing.SetMinLookAheadDistance(450.0);
	}
	
	NextBotGroundLocomotion loco = npc.GetLocomotion();

	float vecNPCPos[3];
	bot.GetPosition(vecNPCPos);

	float vecNPCAng[3];
	GetEntPropVector(iEnt, Prop_Data, "m_angAbsRotation", vecNPCAng);

	CBaseAnimatingOverlay animationEntity = CBaseAnimatingOverlay(iEnt);

	float vecTargetPos[3];
	GetClientAbsOrigin(g_Target, vecTargetPos);

	if (GetVectorDistance(vecNPCPos, vecTargetPos) > 200.0)
		g_Pathing.Update(bot);
	else if (g_flLastAttackTime <= GetGameTime())
	{
		int iSequence = animationEntity.LookupSequence("Melee_Swing");
		
		animationEntity.AddGestureSequence(iSequence);
		g_flLastAttackTime = GetGameTime() + 1.0;
		
		loco.FaceTowards(vecTargetPos);

		if (IsPlayerAlive(g_Target))
		{
			SDKHooks_TakeDamage(g_Target, iEnt, iEnt, 85.0, DMG_SLASH);
			EmitSoundToAll("weapons/grappling_hook_impact_flesh.wav", g_Target);

			float vec[3];
			vec[0] = 0.0; vec[1] = 0.0; vec[2] = -5.0;
			SetEntPropVector(g_Target, Prop_Send, "m_vecPunchAngle", vec);

			vecTargetPos[2] += 40.0;
			TE_Particle("env_sawblood", vecTargetPos, g_Target);

			SpeakResponseConcept(g_Target, GetRandomInt(0, 1) == 0 ? "TLK_PLAYER_HELP" : "TLK_PLAYER_PAIN");
		}	
	}

	loco.Run();
	
	int iSequence = GetEntProp(iEnt, Prop_Send, "m_nSequence");
	
	int sequence_idle = -1;
	if (sequence_idle == -1)
		sequence_idle = animationEntity.LookupSequence("stand_MELEE");
	
	int sequence_air_walk = -1;
	if (sequence_air_walk == -1)
		sequence_air_walk = animationEntity.LookupSequence("airwalk_MELEE");
	
	int sequence_run = -1;
	if (sequence_run == -1)
		sequence_run = animationEntity.LookupSequence("run_MELEE");
	
	Address pModelptr = animationEntity.GetModelPtr();
	int iPitch = animationEntity.LookupPoseParameter(pModelptr, "body_pitch");
	int iYaw = animationEntity.LookupPoseParameter(pModelptr, "body_yaw");

	float vecNPCCenter[3];
	animationEntity.WorldSpaceCenter(vecNPCCenter);

	float vecPlayerCenter[3];
	CBaseAnimating(g_Target).WorldSpaceCenter(vecPlayerCenter);

	float vecDir[3];
	SubtractVectors(vecNPCCenter, vecPlayerCenter, vecDir); 
	NormalizeVector(vecDir, vecDir);

	float vecAng[3];
	GetVectorAngles(vecDir, vecAng); 
	
	float flPitch = animationEntity.GetPoseParameter(iPitch);
	float flYaw = animationEntity.GetPoseParameter(iYaw);
	
	vecAng[0] = UTIL_Clamp(UTIL_AngleNormalize(vecAng[0]), -44.0, 89.0);
	animationEntity.SetPoseParameter(pModelptr, iPitch, UTIL_ApproachAngle(vecAng[0], flPitch, 1.0));
	
	vecAng[1] = UTIL_Clamp(-UTIL_AngleNormalize(UTIL_AngleDiff(UTIL_AngleNormalize(vecAng[1]), UTIL_AngleNormalize(vecNPCAng[1] + 180.0))), -44.0,  44.0);
	animationEntity.SetPoseParameter(pModelptr, iYaw, UTIL_ApproachAngle(vecAng[1], flYaw, 1.0));
	
	int iMoveX = animationEntity.LookupPoseParameter(pModelptr, "move_x");
	int iMoveY = animationEntity.LookupPoseParameter(pModelptr, "move_y");
	
	if (iMoveX < 0 || iMoveY < 0)
		return;
	
	if (loco.GetGroundSpeed() != 0.0)
	{
		if (!(GetEntityFlags(iEnt) & FL_ONGROUND))
		{
			if (iSequence != sequence_air_walk)
				animationEntity.ResetSequence(sequence_air_walk);
		}
		else
		{			
			if (iSequence != sequence_run)
				animationEntity.ResetSequence(sequence_run);
		}
		
		float vecForward[3]; float vecRight[3]; float vecUp[3];
		npc.GetVectors(vecForward, vecRight, vecUp);

		float vecMotion[3];
		loco.GetGroundMotionVector(vecMotion);

		float newMoveX = (vecForward[1] * vecMotion[1]) + (vecForward[0] * vecMotion[0]) +  (vecForward[2] * vecMotion[2]);
		float newMoveY = (vecRight[1] * vecMotion[1]) + (vecRight[0] * vecMotion[0]) + (vecRight[2] * vecMotion[2]);
		
		animationEntity.SetPoseParameter(pModelptr, iMoveX, newMoveX);
		animationEntity.SetPoseParameter(pModelptr, iMoveY, newMoveY);
	}
	else
	{
		if (iSequence != sequence_idle)
			animationEntity.ResetSequence(sequence_idle);
	}
}

public void TF2_OnWeaponFirePost(int client, int weapon)
{
	if (GetWeaponSlot(client, weapon) > 1)
		return;
	
	int target = GetClientAimTarget(client, true);
	
	if (IsValidEntity(target) && GetClientTeam(client) == GetClientTeam(target))
		SDKHooks_TakeDamage(target, 0, client, 3.0, DMG_BULLET, weapon);
}

int duelist1;
int duelist2;
int responses;

void SendDuelRequests()
{
	int[] clients = new int[MaxClients];
	int amount;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		clients[amount++] = i;
	}

	if (amount != 2)
		return;
	
	duelist1 = clients[0];
	duelist2 = clients[1];
	responses = 0;
	
	if (IsFakeClient(duelist1))
		responses++;
	else
		SendConfirmationMenu(duelist1, Confirm_Duel, "Would you like to 1v1?", MENU_TIME_FOREVER);

	if (IsFakeClient(duelist2))
		responses++;
	else
		SendConfirmationMenu(duelist2, Confirm_Duel, "Would you like to 1v1?", MENU_TIME_FOREVER);
}

public void Confirm_Duel(int client, ConfirmationResponses response)
{
	if (response != Confirm_Yes)
	{
		if (duelist1 == client)
			duelist1 = 0;
		
		if (duelist2 == client)
			duelist2 = 0;
		
		return;
	}

	responses++;

	if (responses > 1)
	{
		int spawn1 = FindEntityByName("onDuel1", "info_target");
		int spawn2 = FindEntityByName("onDuel2", "info_target");

		if (!IsValidEntity(spawn1) || !IsValidEntity(spawn2))
			return;
		
		float origin1[3];
		GetEntityOrigin(spawn1, origin1);
		TeleportEntity(duelist1, origin1, NULL_VECTOR, NULL_VECTOR);
		LookAtPosition(duelist2, origin1, 100.0);

		float origin2[3];
		GetEntityOrigin(spawn2, origin2);
		TeleportEntity(duelist2, origin2, NULL_VECTOR, NULL_VECTOR);
		LookAtPosition(duelist1, origin2, 100.0);

		TF2_RemoveCondition(duelist1, TFCond_Taunting);
		SetEntityHealth(duelist1, 1);
		TF2_RemoveAllWearables(duelist1);
		TF2_RegeneratePlayer(duelist1);
		TF2_RemoveAllWeapons(duelist1);
		TF2Attrib_SetByDefIndex(duelist1, 26, 375.0);
		SetEntityHealth(duelist1, 500);

		int kukri = -1;
		if ((kukri = TF2_GiveItem(duelist1, "tf_weapon_club", 3)) != -1)
			EquipWeapon(duelist1, kukri);

		TF2_RemoveCondition(duelist2, TFCond_Taunting);
		SetEntityHealth(duelist2, 1);
		TF2_RemoveAllWearables(duelist2);
		TF2_RegeneratePlayer(duelist2);
		TF2_RemoveAllWeapons(duelist2);
		TF2Attrib_SetByDefIndex(duelist2, 26, 375.0);
		SetEntityHealth(duelist2, 500);
		
		kukri = -1;
		if ((kukri = TF2_GiveItem(duelist2, "tf_weapon_club", 3)) != -1)
			EquipWeapon(duelist2, kukri);
		
		FakeClientCommand(duelist1, "taunt");
		FakeClientCommand(duelist2, "taunt");
	}
}

public Action TF2_OnPlayerDamaged(int victim, TFClassType victimclass, int& attacker, TFClassType attackerclass, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom, bool alive)
{
	if (alive && g_ExtraLives[victim] > 0 && damage >= GetClientHealth(victim))
	{
		g_ExtraLives[victim]--;

		if (g_ExtraLives[victim] < 0)
			g_ExtraLives[victim] = 0;
		
		SetEntityHealth(victim, 300);
		RemovePlayerBack(victim);

		damage = 0.0;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}