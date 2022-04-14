#define SA3 "[SA3]"
#define PLUGIN_NAME "ServerAdvertisements3"
#define PLUGIN_AUTHOR "ESK0"
#define PLUGIN_VERSION "3.2.0"
#define PLUGIN_HASH "$2y$10$MHpA2pP0z8JH5Cfg0rBluuGl0AGJRoY75qvrlTYs2FyyGqljD.kz2"
#define API_KEY "e1b754d2baccaea944dc62419f67d86d90a657ec"

enum struct SMessageGroup
{
	ArrayList mMessages;
	int mNextMsgIndex;
	Handle mhTimer;
}

enum struct SMessageEntry
{
	int mFlags;
	int mIgnoreFlags;
	int mColor[4];
	char mType[3];
	char mTag[64];
	StringMap mTextByLanguage;
	ArrayList mHUDParams;

	bool HasAccess(int client)
	{
		return (CheckCommandAccess(client, "", this.mFlags, true)
			&& (this.mIgnoreFlags < 1 || !CheckCommandAccess(client, "", this.mIgnoreFlags, true)));
	}
}

enum struct SHUDParams
{
	int mChannel;
	int mEndColor[4];
	int mEffect;
	float mXPos;
	float mYPos;
	float mHoldTime;
	float mFadeIn;
	float mFadeOut;
}

char sConfigPath[PLATFORM_MAX_PATH];
char sServerName[64];
char sMapName[128];
float fTime;
bool gRandomize;

StringMap gLanguages, gMessageGroups;

ConVar g_cV_Enabled;
bool g_b_Enabled;

bool bExpiredMessagesDebug;
char sServerType[32];
char sDefaultLanguage[12];

float g_fWM_Delay;
SMessageEntry gWelcomeMessage;

Handle g_hSA3CustomLanguage;
