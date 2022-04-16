stock void AddMessagesToArray(KeyValues kv)
{
	bool bEnabled;
	bEnabled = view_as<bool>(kv.GetNum("enabled", 1));
	if(bEnabled)
	{
		if(SA_CheckDate(kv))
		{
			char sTempMap[256];
			char sBannedMap[512];
			kv.GetString("maps", sTempMap, sizeof(sTempMap), "all");
			kv.GetString("ignore_maps", sBannedMap, sizeof(sBannedMap), "none");
			if(SA_CheckIfMapIsBanned(sMapName, sBannedMap))
			{
				return;
			}
			if(StrEqual(sTempMap, "all") || SA_ContainsMap(sMapName, sTempMap) || SA_ContainsMapPreFix(sMapName, sTempMap))
			{
				SMessageEntry message;
				AddMessagesToEntry(kv, message);
				float time = kv.GetFloat("time", fTime);
				char timeBuf[32];
				FormatEx(timeBuf, sizeof(timeBuf), "%.2f", time);
				SMessageGroup group;

				if (!gMessageGroups.GetArray(timeBuf, group, sizeof(group)))
				{
					group.mMessages = new ArrayList(sizeof(message));
					group.mhTimer = CreateTimer(time, Timer_PrintMessage, time, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
					gMessageGroups.SetArray(timeBuf, group, sizeof(group));
					LogMessage("Created new message group of period '%s'", timeBuf);
				}

				group.mMessages.PushArray(message);
			}
		}
	}
}

stock void AddMessagesToEntry(KeyValues kv, SMessageEntry message)
{
	message.mTextByLanguage = new StringMap();
	char sMessageFlags[16], sTempLanguageName[12], sTempLanguageMessage[512], name[MAX_NAME_LENGTH];
	StringMapSnapshot languages = gLanguages.Snapshot();

	for (int i; i < languages.Length; ++i)
	{
		languages.GetKey(i, sTempLanguageName, sizeof(sTempLanguageName));
		kv.GetString(sTempLanguageName, sTempLanguageMessage, sizeof(sTempLanguageMessage));

		if (sTempLanguageMessage[0] == '\0')
		{
			kv.GetSectionName(name, sizeof(name));
			SetFailState("%s '%s' translation missing in message \"%s\"", SA3, sTempLanguageName, name);
		}
		message.mTextByLanguage.SetString(sTempLanguageName, sTempLanguageMessage);
	}

	delete languages;
	kv.GetString("type", message.mType, sizeof(message.mType), "T");
	kv.GetString("tag", message.mTag, sizeof(message.mTag), sServerName);
	kv.GetString("flags", sMessageFlags, sizeof(sMessageFlags));
	message.mFlags = ReadFlagString(sMessageFlags);
	kv.GetString("ignore", sMessageFlags, sizeof(sMessageFlags));
	message.mIgnoreFlags = ReadFlagString(sMessageFlags);
	bool isHUD = StrEqual(message.mType, "H", false);

	if (isHUD || StrEqual(message.mType, "M", false)) // HUD or top menu message?
	{
		kv.GetColor4("color", message.mColor);
	}

	if (isHUD)
	{
		SHUDParams params;
		params.mChannel = kv.GetNum("channel", -1);
		params.mXPos = kv.GetFloat("posx", -1.0);
		params.mYPos = kv.GetFloat("posy", 0.05);
		kv.GetColor4("color2", params.mEndColor);
		params.mEffect = kv.GetNum("effect");
		params.mHoldTime = kv.GetFloat("holdtime", 5.0);
		params.mFadeIn = kv.GetFloat("fadein", 0.2);
		params.mFadeOut = kv.GetFloat("fadeout", 0.2);
		message.mHUDParams = new ArrayList(sizeof(params));
		message.mHUDParams.PushArray(params);
	}
}

stock void CheckMessageVariables(char[] message, int len)
{
	char sBuffer[256];
	ConVar hConVar;
	char sConVar[64];
	char sSearch[64];
	char sReplace[64];
	int iCustomCvarEnd = -1;
	int iCustomCvarStart = StrContains(message, "{");
	int iCustomCvarNextStart;
	if(iCustomCvarStart != -1)
	{
		while(iCustomCvarStart != -1)
		{
				iCustomCvarEnd = StrContains(message[iCustomCvarStart+1], "}");
				if(iCustomCvarEnd != -1)
				{
					strcopy(sConVar, iCustomCvarEnd+1, message[iCustomCvarStart+1]);
					FormatEx(sSearch, sizeof(sSearch), "{%s}", sConVar);
					hConVar = FindConVar(sConVar);
					if(hConVar)
					{
							hConVar.GetString(sReplace, sizeof(sReplace));
							ReplaceString(message, len, sSearch, sReplace, false);
					}
					iCustomCvarNextStart = StrContains(message[iCustomCvarStart+1], "{");
					if(iCustomCvarNextStart != -1)
					{
						iCustomCvarStart += iCustomCvarNextStart+1;
					}
					else break;
				}
				else break;
		}
	}

	if(StrContains(message , "{CURRENTDATE}") != -1)
	{
		FormatTime(sBuffer, sizeof(sBuffer), "%d-%m-%Y");
		ReplaceString(message, len, "{CURRENTDATE}", sBuffer);
	}

	if(StrContains(message , "{CURRENTDATE_US}") != -1)
	{
		FormatTime(sBuffer, sizeof(sBuffer), "%m-%d-%Y");
		ReplaceString(message, len, "{CURRENTDATE_US}", sBuffer);
	}

	if(StrContains(message , "{NEXTMAP}") != -1)
	{
		GetNextMap(sBuffer, sizeof(sBuffer));
		ReplaceString(message, len, "{NEXTMAP}", sBuffer);
	}

	if(StrContains(message, "{CURRENTMAP}") != -1)
	{
		char sTempMap[256];
		GetCurrentMap(sTempMap, sizeof(sTempMap));
		GetMapDisplayName(sTempMap, sBuffer, sizeof(sBuffer));
		ReplaceString(message, len, "{CURRENTMAP}", sBuffer);
	}

	if(StrContains(message, "{PLAYERCOUNT}") != -1)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%i", CountPlayers());
		ReplaceString(message, len, "{PLAYERCOUNT}", sBuffer);
	}

	if(StrContains(message, "{CURRENTTIME}") != -1)
	{
		FormatTime(sBuffer, sizeof(sBuffer), "%H:%M:%S");
		ReplaceString(message, len, "{CURRENTTIME}", sBuffer);
	}

	if(StrContains(message, "{SERVERIP}") != -1)
	{
		GetServerIP(sBuffer, sizeof(sBuffer));
		ReplaceString(message, len, "{SERVERIP}", sBuffer);
	}

	if(StrContains(message, "{SERVERNAME}") != -1)
	{
		GetConVarString(FindConVar("hostname"), sBuffer,sizeof(sBuffer));
		ReplaceString(message, len, "{SERVERNAME}", sBuffer);
	}

	if(StrContains(message , "{TIMELEFT}") != -1)
	{
		int i_Minutes;
		int i_Seconds;
		int i_Time;
		if(GetMapTimeLeft(i_Time) && i_Time > 0)
		{
		 i_Minutes = i_Time / 60;
		 i_Seconds = i_Time % 60;
		}
		FormatEx(sBuffer, sizeof(sBuffer), "%d:%02d", i_Minutes, i_Seconds);
		ReplaceString(message, len, "{TIMELEFT}", sBuffer);
	}
	
	if(StrContains(message, "{ADMINSONLINE}") != -1)
	{
		char sAdminList[128], separator[3];
		int adminsLen;

		LoopClients(x)
		{
			if(IsValidClient(x) && IsPlayerAdmin(x))
			{
				adminsLen += FormatEx(sAdminList[adminsLen], sizeof(sAdminList) - adminsLen, "%s'%N'", separator, x);
				separator = ", ";
			}
		}
		ReplaceString(message, len, "{ADMINSONLINE}", sAdminList);
	}
	
	if(StrContains(message, "{VIPONLINE}") != -1)
	{
		char sVIPList[128], separator[3];
		int vipsLen;

		LoopClients(x)
		{
			if(IsValidClient(x) && IsPlayerVIP(x))
			{
				vipsLen += FormatEx(sVIPList[vipsLen], sizeof(sVIPList) - vipsLen, "%s'%N'", separator, x);
				separator = ", ";
			}
		}
		ReplaceString(message, len, "{VIPONLINE}", sVIPList);
	}
}

stock void SA_GetClientLanguage(int client, char buffer[3])
{
	char sBuffer[12], sIP[26];
	GetClientCookie(client, g_hSA3CustomLanguage, sBuffer, sizeof(sBuffer));
	bool langExists; // Whether computed language code exists in our local config

	if (!StrEqual(sBuffer, "geoip", false))
	{
		if (StrEqual(sBuffer, "ingame", false) || StrEqual(sDefaultLanguage, "ingame", false)
			&& !gLanguages.GetValue(sBuffer, langExists))
		{
			SA_GetInGameLanguage(client, sBuffer, sizeof(sBuffer));
			gLanguages.GetValue(sBuffer, langExists);
		}

		if (langExists)
		{
			FormatEx(buffer, sizeof(buffer), sBuffer);
			return;
		}
	}

	GetClientIP(client, sIP, sizeof(sIP));
	GeoipCode2(sIP, buffer);
	String_ToLower(buffer, buffer, sizeof(buffer));

	if (!gLanguages.GetValue(buffer, langExists))
	{
		StringMapSnapshot languages = gLanguages.Snapshot();
		languages.GetKey(0, buffer, sizeof(buffer));
		delete languages;
	}
}

stock void CheckMessageClientVariables(int client, char[] message, int len)
{
	char sBuffer[256];
	if(StrContains(message, "{STEAMID}") != -1)
	{
		GetClientAuthId(client, AuthId_Engine, sBuffer, sizeof(sBuffer));
		ReplaceString(message, len, "{STEAMID}", sBuffer);
	}

	if(StrContains(message , "{PLAYERNAME}") != -1)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%N", client);
		ReplaceString(message, len, "{PLAYERNAME}", sBuffer);
	}
}

stock int CountPlayers()
{
	int count = 0;
	LoopClients(i)
	{
		count++;
	}
	return count;
}

stock void GetServerIP(char[] buffer, int len)
{
	int ips[4];
	int ip = GetConVarInt(FindConVar("hostip"));
	int port = GetConVarInt(FindConVar("hostport"));
	ips[0] = (ip >> 24) & 0x000000FF;
	ips[1] = (ip >> 16) & 0x000000FF;
	ips[2] = (ip >> 8) & 0x000000FF;
	ips[3] = ip & 0x000000FF;
	FormatEx(buffer, len, "%d.%d.%d.%d:%d", ips[0], ips[1], ips[2], ips[3], port);
}

stock void PrintMessageEntry(int client, SMessageEntry message)
{
	char sCountryTag[3], sMessage[1024];
	SA_GetClientLanguage(client, sCountryTag);
	message.mTextByLanguage.GetString(sCountryTag, sMessage, sizeof(sMessage));
	TrimString(sMessage);
	ReplaceString(sMessage, sizeof(sMessage), "\\n", "\n");
	CheckMessageVariables(sMessage, sizeof(sMessage));
	CheckMessageClientVariables(client, sMessage, sizeof(sMessage));

	if (StrEqual(message.mType, "T", false))
	{
		CPrintToChat(client, "%s", sMessage);
	}
	else if (StrEqual(message.mType, "C", false))
	{
		PrintCenterText(client, sMessage);
	}
	else if (StrEqual(message.mType, "H", false))
	{
		SHUDParams params;
		message.mHUDParams.GetArray(0, params, sizeof(params));
		SetHudTextParamsEx(params.mXPos, params.mYPos, params.mHoldTime, message.mColor,
			params.mEndColor, params.mEffect, 0.25, params.mFadeIn, params.mFadeOut);
		ShowHudText(client, params.mChannel, sMessage);
	}
	else if (StrEqual(message.mType, "M", false)) // Top menu?
	{
		DisplayTopMenuMessage(client, sMessage, message.mColor);
	}
}

stock void DisplayTopMenuMessage(int client, const char[] message, int color[4])
{
	KeyValues keyValues = new KeyValues("menu", "title", message);
	keyValues.SetNum("level", 1);
	keyValues.SetColor4("color", color);
	CreateDialog(client, keyValues, DialogType_Msg);
	delete keyValues;
}

stock bool SA_DateCompare(int currentdate[3], int availabletill[3])
{
	if(availabletill[0] > currentdate[0])
	{
		return true;
	}
	else if(availabletill[0] == currentdate[0])
	{
		if(availabletill[1] > currentdate[1])
		{
			return true;
		}
		else if(availabletill[1] == currentdate[1])
		{
			if(availabletill[2] >= currentdate[2])
			{
				return true;
			}
		}
	}
	return false;
}

stock bool SA_CheckIfMapIsBanned(const char[] currentmap, const char[] bannedmap)
{
	char sBannedMapExploded[64][256];
	int count = ExplodeString(bannedmap, ";", sBannedMapExploded, sizeof(sBannedMapExploded), sizeof(sBannedMapExploded[]));
	for(int i = 0; i < count; i++)
	{
		if(StrEqual(sBannedMapExploded[i], currentmap) || StrContains(currentmap, sBannedMapExploded[i]) != -1)
		{
			return true;
		}
	}
	return false;
}

stock bool SA_ContainsMapPreFix(const char[] mapname, const char[] prefix)
{
	char sPreFixExploded[32][12];
	int count = ExplodeString(prefix, ";", sPreFixExploded, sizeof(sPreFixExploded), sizeof(sPreFixExploded[]));
	for(int i = 0; i < count; i++)
	{
		if(StrContains(mapname, sPreFixExploded[i]) != -1)
		{
			return true;
		}
	}
	return false;
}

stock bool SA_ContainsMap(const char[] currentmap, const char[] mapname)
{
	char sMapExploded[32][12];
	int count = ExplodeString(mapname, ";", sMapExploded, sizeof(sMapExploded), sizeof(sMapExploded[]));
	for(int i = 0; i < count; i++)
	{
		if(StrEqual(sMapExploded[i], currentmap))
		{
			return true;
		}
	}
	return false;
}

stock void SA_GetInGameLanguage(int client, char[] sLanguage, int len)
{
	GetLanguageInfo(GetClientLanguage(client), sLanguage, len);
}

stock bool SA_CheckDate(KeyValues kv)
{
	char sEnabledTill[32], sEnabledTillEx[3][12], name[MAX_NAME_LENGTH];
	kv.GetString("enabledtill", sEnabledTill, sizeof(sEnabledTill), "");
	if(strlen(sEnabledTill) > 0)
	{
		int iEnabledTill = ExplodeString(sEnabledTill, ".", sEnabledTillEx, sizeof(sEnabledTillEx), sizeof(sEnabledTillEx[]));
		if(iEnabledTill != 3)
		{
			kv.GetSectionName(name, sizeof(name));
			SetFailState("%s (1) Wrong date format in message \"%s\". Use: DD.MM.YYYY", SA3, name);
		}
	}
	else
	{
		return true;
	}
	int iExpDate[3];
	int iCurrentDate[3];
	char sCurrentYear[12];
	char sCurrentYearEx[3][12];
	FormatTime(sCurrentYear, sizeof(sCurrentYear), "%Y.%m.%d");
	ExplodeString(sCurrentYear, ".", sCurrentYearEx, sizeof(sCurrentYearEx), sizeof(sCurrentYearEx[]));

	iCurrentDate[0] = StringToInt(sCurrentYearEx[0]);
	iCurrentDate[1] = StringToInt(sCurrentYearEx[1]);
	iCurrentDate[2] = StringToInt(sCurrentYearEx[2]);

	iExpDate[0] = StringToInt(sEnabledTillEx[2]);
	iExpDate[1] = StringToInt(sEnabledTillEx[1]);
	iExpDate[2] = StringToInt(sEnabledTillEx[0]);

	if(((strlen(sEnabledTillEx[0]) != 2) || (strlen(sEnabledTillEx[1]) != 2) || (strlen(sEnabledTillEx[2]) != 4) || iExpDate[2] > 31 || iExpDate[1] > 12))
	{
		kv.GetSectionName(name, sizeof(name));
		SetFailState("%s (2) Wrong date format in message \"%s\". Use: DD.MM.YYYY", SA3, name);
	}
	else
	{
		if(SA_DateCompare(iCurrentDate, iExpDate))
		{
			return true;
		}
		else
		{
			if(bExpiredMessagesDebug == true)
			{
				kv.GetSectionName(name, sizeof(name));
				LogError("%s Message \"%s\" is not available anymore. The message expired on %s", SA3, name, sEnabledTill);
			}
		}
	}
	return false;
}
