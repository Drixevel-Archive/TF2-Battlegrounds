#if defined _tf2_items_included
  #endinput
#endif
#define _tf2_items_included

//Defines
#define MAX_WEAPON_NAME_LENGTH 32
#define MAX_DESCRIPTION_LENGTH 64
#define MAX_ATTRIBUTE_NAME_LENGTH 64
#define MAX_ATTRIBUTE_DISPLAY_LENGTH 64

//Typedefs
typedef RegisterAttribute_OnAction = function void (int client, int weapon, const char[] attrib, const char[] action, StringMap attributedata);

//Natives
native bool TF2Items_AllowAttributeRegisters();
native bool TF2Items_RegisterAttribute(const char[] attrib, RegisterAttribute_OnAction onaction);
native int TF2Items_GiveWeapon(int client, const char[] name, bool message = false);
native bool TF2Items_IsCustom(int weapon);
native void TF2Items_RefillMag(int weapon);
native void TF2Items_RefillAmmo(int client, int weapon);

native int TF2Items_EquipWearable(int client, const char[] classname, int index, int level = 1, int quality = 1);
native int TF2Items_EquipViewmodel(int client, char[] model = "");

native int TF2Items_GetWeaponKeyInt(const char[] weapon, const char[] key);
native float TF2Items_GetWeaponKeyFloat(const char[] weapon, const char[] key);
native bool TF2Items_GetWeaponKeyString(const char[] weapon, const char[] key, char[] buffer, int size);

//Forwards
forward Action TF2Items_OnRegisterAttributes();
forward void TF2Items_OnRegisterAttributesPost();
forward Action TF2Items_OnRegisterWeaponConfig(const char[] name, const char[] file, KeyValues settings);
forward Action TF2Items_OnRegisterWeaponSetting(const char[] name, const char[] key, any value);
forward Action TF2Items_OnRegisterWeaponSettingStr(const char[] name, const char[] key, const char[] value);
forward void TF2Items_OnRegisterWeaponConfigPost(const char[] name, const char[] file, KeyValues settings);

#if !defined REQUIRE_PLUGIN
public void __pl_tf2_items_SetNTVOptional()
{
	MarkNativeAsOptional("TF2Items_AllowAttributeRegisters");
	MarkNativeAsOptional("TF2Items_RegisterAttribute");
	MarkNativeAsOptional("TF2Items_GiveWeapon");
	MarkNativeAsOptional("TF2Items_IsCustom");
	MarkNativeAsOptional("TF2Items_RefillMag");
	MarkNativeAsOptional("TF2Items_RefillAmmo");
	
	MarkNativeAsOptional("TF2Items_EquipWearable");
	MarkNativeAsOptional("TF2Items_EquipViewmodel");
	
	MarkNativeAsOptional("TF2Items_GetWeaponKeyInt");
	MarkNativeAsOptional("TF2Items_GetWeaponKeyFloat");
	MarkNativeAsOptional("TF2Items_GetWeaponKeyString");
}
#endif

public SharedPlugin __pl_tf2_items =
{
	name = "tf2-items",
	file = "tf2-items.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};
