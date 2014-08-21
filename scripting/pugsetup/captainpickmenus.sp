public void InitialChoiceMenu(int client) {
    g_PickingPlayers = true;
    Handle menu = CreateMenu(InitialChoiceHandler);
    SetMenuTitle(menu, "Which would you prefer:");
    SetMenuExitButton(menu, false);
    AddMenuInt(menu, _:InitialPick_Side, "Pick the starting team");
    AddMenuInt(menu, _:InitialPick_Player, "Pick the first player");
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public InitialChoiceHandler(Handle menu, MenuAction action, param1, param2) {
    if (action == MenuAction_Select) {
        int client = param1;  // should also equal g_capt1
        if (client != g_capt1)
            LogError("[InitialChoiceHandler] only the first captain should have gotten the intial menu!");

        InitialPick choice = InitialPick:GetMenuInt(menu, param2);
        if (choice == InitialPick_Player) {
            PugSetupMessageToAll("{PINK}%N {NORMAL}has elected to get the {GREEN}first player pick.", g_capt1);
            SideMenu(g_capt2);
        } else if (choice == InitialPick_Side) {
            PugSetupMessageToAll("{PINK}%N {NORMAL}has elected to pick the {GREEN}starting side.", g_capt1);
            SideMenu(g_capt1);
        } else {
            LogError("[InitialChoiceHandler] unknown intial choice=%d", choice);
        }
    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}

public void SideMenu(int client) {
    Handle menu = CreateMenu(SideMenuHandler);
    SetMenuTitle(menu, "Which side do you want first");
    SetMenuExitButton(menu, false);
    AddMenuInt(menu, CS_TEAM_CT, "CT");
    AddMenuInt(menu, CS_TEAM_T, "T");
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public SideMenuHandler(Handle menu, MenuAction action, param1, param2) {
    if (action == MenuAction_Select) {
        int client = param1;
        int choice = GetMenuInt(menu, param2);

        int teamPick = -1;
        if (choice == CS_TEAM_CT) {
            PugSetupMessageToAll("{PINK}%N {NORMAL}has picked {GREEN}CT {NORMAL}first.", client);
            teamPick = CS_TEAM_CT;
        } else if (choice == CS_TEAM_T) {
            PugSetupMessageToAll("{PINK}%N {NORMAL}has picked {GREEN}T {NORMAL}first.", client);
            teamPick = CS_TEAM_T;
        } else {
            LogError("[SideMenuHandler] Unknown side pick: %d", choice);
        }

        int otherTeam = (teamPick == CS_TEAM_CT) ? CS_TEAM_T : CS_TEAM_CT;

        g_Teams[client] = teamPick;
        SwitchPlayerTeam(client, teamPick);

        int otherCaptain = OtherCaptain(client);
        g_Teams[otherCaptain] = otherTeam;
        SwitchPlayerTeam(otherCaptain, otherTeam);

        ServerCommand("mp_restartgame 1");
        GivePlayerSelectionMenu(otherCaptain);

    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}

/**
 * Player selection menus.
 */
public GivePlayerSelectionMenu(client) {
    if (IsPickingFinished()) {
        CreateTimer(1.0, FinishPicking);
    } else {
        Handle menu = CreateMenu(PlayerMenuHandler);
        SetMenuTitle(menu, "Pick your players");
        SetMenuExitButton(menu, false);
        AddPlayersToMenu(menu);
        DisplayMenu(menu, client, MENU_TIME_FOREVER);
    }
}

public PlayerMenuHandler(Handle menu, MenuAction action, param1, param2) {
    if (action == MenuAction_Select) {
        int client = param1;
        int selected = GetMenuInt(menu, param2);

        if (selected > 0) {
            g_Teams[selected] = g_Teams[client];
            SwitchPlayerTeam(selected, g_Teams[client]);
            if (client == g_capt1)
                PugSetupMessageToAll("{PINK}%N {NORMAL}has picked {PINK}%N", client, selected);
            else
                PugSetupMessageToAll("{LIGHT_GREEN}%N {NORMAL}has picked {LIGHT_GREEN}%N", client, selected);

            if (!IsPickingFinished()) {
                int nextCapt = OtherCaptain(client);
                MoreMenuPicks(nextCapt);
            } else {
                CreateTimer(1.0, FinishPicking);
            }
        } else {
            MoreMenuPicks(client);
        }

    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}

public void MoreMenuPicks(client) {
    if (IsPickingFinished() || !IsValidClient(client) || !IsClientInGame(client)) {
        CreateTimer(5.0, FinishPicking);
        return;
    }
    GivePlayerSelectionMenu(client);
}

/**
 * Helper functions for the player menus.
 */
static bool IsPickingFinished() {
    int numSelected = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsPlayerPicked(i))
            numSelected++;
    }

    return numSelected >= 2*g_PlayersPerTeam;
}

static bool IsPlayerPicked(client) {
    int team = g_Teams[client];
    return team == CS_TEAM_T || team == CS_TEAM_CT;
}

public int OtherCaptain(captain) {
    if (captain == g_capt1)
        return g_capt2;
    else
        return g_capt1;
}

static int AddPlayersToMenu(Handle menu) {
    char name[MAX_NAME_LENGTH];
    int count = 0;
    for (int client = 1; client <= MaxClients; client++) {
        if (IsValidClient(client) && !IsFakeClient(client) && g_Teams[client] == CS_TEAM_SPECTATOR) {
            GetClientName(client, name, sizeof(name));
            AddMenuInt(menu, client, name);
            count++;
        }
    }
    return count;
}
