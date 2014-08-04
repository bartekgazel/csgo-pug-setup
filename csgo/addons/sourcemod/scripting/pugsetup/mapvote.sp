#define RANDOM_MAP_VOTE -1 // must be in invalid index for array indexing

/**
 * Map voting functions
 */
public CreateMapVote() {
    GetMapList();
    ShowMapVote();
}

static ShowMapVote() {
    new Handle:menu = CreateMenu(MapVoteHandler);
    SetMenuTitle(menu, "Vote for a map");
    SetMenuExitButton(menu, false);

    AddMenuInt(menu, RANDOM_MAP_VOTE, "Random");
    for (new i = 0; i < GetArraySize(g_MapNames); i++) {
        new String:mapName[PLATFORM_MAX_PATH];
        GetArrayString(g_MapNames, i, mapName, sizeof(mapName));
        AddMenuInt(menu, i, mapName);
    }
    VoteMenuToAll(menu, GetConVarInt(g_hMapVoteTime));
}

public MapVoteHandler(Handle:menu, MenuAction:action, param1, param2) {
    if (action == MenuAction_VoteEnd) {
        new any:winner = GetMenuInt(menu, param1);
        if (winner == RANDOM_MAP_VOTE) {
            g_ChosenMap = GetArrayRandomIndex(g_MapNames);
        } else {
            g_ChosenMap = GetMenuInt(menu, param1);
        }

        ChangeMap();
    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}
