/*
	Newb Server Freeroam by mick88
	REL 14/11/2010
*/

#include <a_samp>
#undef MAX_PLAYERS

#pragma tabsize 0
#pragma dynamic 5120

#define DEFAULT_ALLOWDM     true
#define DEFAULT_INITMONEY   1000
#define DEFAULT_DELETEVEH   true

#define MAX_LIST_ITEMS      50
#define MAX_CMD 			32
#define MAX_PLAYERS 		64
#define MSG_SIZE 			128
#define MAX_PLAYER_NAME_EX 	(MAX_PLAYER_NAME+6)
#define MAX_NAME            16
#define MAX_WEAPONS 		46

#define COLOR_GREY 0xAFAFAFAA
#define COLOR_GREEN 0x008000FF
#define COLOR_RED 0xAA3333AA
#define COLOR_YELLOW 0xFFFF0066
#define COLOR_WHITE 0xFFFFFFFF
#define COLOR_ORANGE 0xFF9900AA
#define COLOR_STRONGRED 0xFF0000FF

#define LEAVE_TIMEOUT 		0
#define LEAVE_EXIT 			1
#define LEAVE_KICK 			2

#define DIALOG_MAIN 		1
#define DIALOG_GUNS  		2
#define DIALOG_BUYCAR  		3
#define DIALOG_PM			4
#define DIALOG_TUNE     	5
#define DIALOG_PLAYER       6

#define ACTION_GUNS         1
#define ACTION_CARS         2
#define ACTION_AIRP         3
#define ACTION_HELI         4
#define ACTION_BOAT        	5
#define ACTION_JETP         6
#define ACTION_TELE		    7
#define ACTION_BIKE         8
#define ACTION_PM           9
#define ACTION_HEAL         10
#define ACTION_TUNE         11
#define ACTION_REPAIR       12

#define FLAG_CAR            1
#define FLAG_PLANE          2
#define FLAG_HELI           4
#define FLAG_BOAT           8
#define FLAG_BIKE           16

#define VAR_MONEY           "money"
#define VAR_ADMIN           "admin"

#define ICON_CONNECT        200
#define ICON_DISCONNECT     201

#define NAME 				PlayerName(playerid)
#define NAMEX 				PlayerNameEx(playerid)
#define P                   p[playerid]
#define MESSAGE(%1)         SendClientMessage(playerid,%1)
#define COORDS 				new Float:x, Float:y, Float:z
#define GET_MONEY(%1)       GetPVarInt(%1,VAR_MONEY)
#define ADD_MONEY(%1,%2)    SetMoney(%1, GET_MONEY(%1)+%2)
#define PAY(%1) 			(GET_MONEY(playerid)>=%1 && ADD_MONEY(playerid,-%1))
#define CMD(%1) 			if (strcmp(cmd, %1, true, MAX_CMD) == 0)
#define IS_ADMIN(%1)  		(GetPVarInt(%1,VAR_ADMIN) || IsPlayerAdmin(%1))
#define ACMD(%1)            if (IS_ADMIN(playerid) && strcmp(cmd, %1, true, MAX_CMD) == 0)
#define ALIAS(%1,%2)		if (strcmp(cmd, %1, true, MAX_CMD) == 0) cmd = %2
#define MSG                 msg,MSG_SIZE
#define isnull(%1)          (!%1[0] || (%1[0]=='\1' && !%1[1]))

#define ADD_VEHICLE(%1,%2,%3,%4)            \
strcp((%2), vmodel[(%1)][vname]);           \
vmodel[(%1)][vprice] = (%3);                \
vmodel[(%1)][vflags] = (%4)

#define ADD_MENU_ITEM(%1,%2)		format(list, sizeof(list), "%s\n%s",list,(%1));P[dialoglist][n]=(%2);n++

forward MainTimer();

enum PlayerData
{
	pdialogsubject,
	dialoglist[MAX_LIST_ITEMS],
	Float: px,
	Float: py,
	Float: pz,
	Float:pspeed,
	plastsender = INVALID_PLAYER_ID,
	Float:savedx,
	Float:savedy,
	Float:savedz,
	Float:savedr
}

enum VehicleData
{
	vname[MAX_NAME],
	vprice,
	vflags
}

new
	stock bool:FALSE = false,
	Float:p[MAX_PLAYERS][PlayerData],
	Float:vmodel[611][VehicleData],
	VehicleOwner[MAX_VEHICLES],
	WeaponPrice[MAX_WEAPONS],
	allowdm = DEFAULT_ALLOWDM,
	deleteveh = DEFAULT_DELETEVEH,
	initialmoney = DEFAULT_INITMONEY
	;

main()
{
}

stock GetPlayerID(name[])
{
	//checking if name is empty
	new len = strlen(name);
	if (!len) return INVALID_PLAYER_ID;
	//looking up player by name
	for (new playerid; playerid < MAX_PLAYERS; playerid++) if (IsPlayerConnected(playerid) && !strcmp(name, NAME, true, len)) return playerid;
	//checking if string given is a number
	for (new i; name[i]; i++) if (name[i] < '0' || name[i] > '9') return INVALID_PLAYER_ID;
	new playerid = strval(name);
	if (IsPlayerConnected(playerid)) return playerid;
	return INVALID_PLAYER_ID;
}

stock Float:Distance2D(Float:ax, Float:ay, Float:bx,Float:by)
{
	bx -= ax;
	by -= ay;
	return floatsqroot(bx*bx+by*by);
}

stock SetMoney(playerid, amount)
{
	ResetPlayerMoney(playerid);
	SetPVarInt(playerid, VAR_MONEY, amount);
	SetPlayerScore(playerid, floatround(amount/1000));
	return GivePlayerMoney(playerid, amount);
}

stock ShowPlayerTuneDialog(playerid)
{
    new list[512], n;
	ADD_MENU_ITEM("Nitrous", 1010);
	ADD_MENU_ITEM("Hydraulics", 1087);
	ADD_MENU_ITEM("Access wheels", 1098);
    ADD_MENU_ITEM("Virtual wheels", 1097);
    ADD_MENU_ITEM("Ahab wheels", 1096);
    ADD_MENU_ITEM("Atomic wheels", 1085);
    ADD_MENU_ITEM("Trance wheels", 1084);
    ADD_MENU_ITEM("Dollar wheels", 1083);
    ADD_MENU_ITEM("Import wheels", 1082);
    ADD_MENU_ITEM("Grove wheels", 1081);
    ADD_MENU_ITEM("Switch wheels", 1080);
    ADD_MENU_ITEM("Cutter wheels", 1079);
    ADD_MENU_ITEM("Twist wheels", 1078);
    ADD_MENU_ITEM("Classic wheels", 1077);
    ADD_MENU_ITEM("Wires wheels", 1076);
    ADD_MENU_ITEM("Rimshine wheels", 1075);
    ADD_MENU_ITEM("Mega wheels", 1074);
    ADD_MENU_ITEM("Shadow wheels", 1073);
    ADD_MENU_ITEM("Offroad wheels", 1025);
	return ShowPlayerDialog(playerid, DIALOG_TUNE, DIALOG_STYLE_LIST, "Buy tuning components. $500 each.", list, "BUY", "Back");
}

stock ShowPlayerMainMenu(playerid)
{
	new list[512], n;
	if (allowdm)
	{
		ADD_MENU_ITEM("Buy weapon", ACTION_GUNS);
	}
	ADD_MENU_ITEM("Buy bike", ACTION_BIKE);
	ADD_MENU_ITEM("Buy car", ACTION_CARS);
	ADD_MENU_ITEM("Buy airplane", ACTION_AIRP);
	ADD_MENU_ITEM("Buy helicopter", ACTION_HELI);
	ADD_MENU_ITEM("Buy boat", ACTION_BOAT);
	ADD_MENU_ITEM("Buy jetpack\t\t$50,000", ACTION_JETP);
	ADD_MENU_ITEM("Heal\t\t\t$1,000", ACTION_HEAL);
	ADD_MENU_ITEM("Repair vehicle\t\t$1,000", ACTION_REPAIR);
	ADD_MENU_ITEM("Tune vehicle", ACTION_TUNE);
	return ShowPlayerDialog(playerid, DIALOG_MAIN, DIALOG_STYLE_LIST, "Main menu", list, "OK", "Cancel");
}

stock ShowPlayerVehicleDialog(playerid, modelflag)
{
    new list[1024], n;
	for (new model=400; model < 611; model++) if (vmodel[model][vflags] & modelflag)
	{
	    new line[64];
	    format(line, 64, "%25s\t%s", vmodel[model][vname], FormatMoney(vmodel[model][vprice]));
	    ADD_MENU_ITEM(line, model);
	    if (n == MAX_LIST_ITEMS) break;
	}
	return ShowPlayerDialog(playerid, DIALOG_BUYCAR, DIALOG_STYLE_LIST, "Buy vehicle:", list, "Buy", "Back");
}

stock Me(playerid, message[], color=COLOR_WHITE, except=INVALID_PLAYER_ID)
{
	new msg[MSG_SIZE];
	format(msg, MSG_SIZE, "* %s %s", NAME, message);
	print(msg);
	if (except == INVALID_PLAYER_ID) SendClientMessageToAll(color, msg);
	else for(new pid; pid < MAX_PLAYERS; pid++) if (pid != except) SendClientMessage(pid, color, msg);
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

stock PlayerNameEx(playerid)
{
	new name[MAX_PLAYER_NAME_EX];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	format(name, MAX_PLAYER_NAME_EX, "%s (%d)", name, playerid);
	return name;
}

stock SendPM(fromid, toid, message[]="")
{
	if (!IsPlayerConnected(toid) || toid == INVALID_PLAYER_ID) return false;
	if (isnull(message))
	{
 		new txt[64];
		format(txt, 64, "Enter message for %s:", PlayerNameEx(toid), toid);
	    ShowPlayerDialog(fromid, DIALOG_PM, DIALOG_STYLE_INPUT, "Private Message:", txt, "Send", "Cancel");
	    p[fromid][pdialogsubject] = toid;
	    return 1;
	}
	new msg[128];
	format(MSG,">> %s: %s",PlayerNameEx(toid),message);
	SendClientMessage(fromid, COLOR_YELLOW,msg);

	format(msg,sizeof(msg),"** %s: %s",PlayerNameEx(fromid),message);
	SendClientMessage(toid, COLOR_ORANGE,msg);

	PlayerPlaySound(toid,1085,0.0,0.0,0.0);
	p[toid][plastsender] = fromid;
	printf("PM: %s->%s: %s", PlayerNameEx(fromid), PlayerNameEx(toid), message);
	return true;
}

stock PlayerName(playerid)
{
	new name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, MAX_PLAYER_NAME);
	return name;
}

public MainTimer()
{
	for (new playerid; playerid < MAX_PLAYERS; playerid++) if (IsPlayerConnected(playerid))
	{
	    new vehicleid = GetPlayerVehicleID(playerid);
	    COORDS;
	    if (vehicleid)
		{
			GetVehicleVelocity(vehicleid, x, y, z);
			new model = GetVehicleModel(vehicleid);
			if (!(vmodel[model][vflags] & FLAG_HELI || vmodel[model][vflags] & FLAG_PLANE) &&  IsVehicleUpsideDown(vehicleid))
			{
				new Float:face;
				GetVehicleZAngle(vehicleid, face);
				SetVehicleZAngle(vehicleid, face);
			}
		}
		else GetPlayerVelocity(playerid, x, y ,z);
	    P[pspeed] = Distance2D(x, y, 0, 0);
	    if (vehicleid) GetVehiclePos(vehicleid, x, y, z);
	    else GetPlayerPos(playerid, x, y, z);
	    
	    if (P[pspeed])
	    {
			new Float: dist = Distance2D(x, y, P[px], P[py]);
			ADD_MONEY(playerid, floatround(dist)/5);
		}
					
		if (!allowdm) ResetPlayerWeapons(playerid);
	}
	return 1;
}

stock DeletePlayerVehicles(playerid)
{
	if (!deleteveh) return false;
    for (new vehicleid=1; vehicleid < MAX_VEHICLES; vehicleid++) if (VehicleOwner[vehicleid] == playerid)
	{
	    VehicleOwner[vehicleid] = INVALID_PLAYER_ID;
	    DestroyVehicle(vehicleid);
	}
	return true;
}

stock GiveCar(playerid, model)
{
    if (GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
    {
        SetVehicleToRespawn(GetPlayerVehicleID(playerid));
    }
 	COORDS;
    new Float: r;
    GetPlayerPos(playerid, x, y ,z);
    GetPlayerFacingAngle(playerid, r);
    new vehicleid = CreateVehicle(model, x, y ,z, r, 1, 1, 10000);
    VehicleOwner[vehicleid] = playerid;
    
    new col = random(127);
    ChangeVehicleColor(vehicleid, col, col);
    PutPlayerInVehicle(playerid, vehicleid, 0);
    printf("Vehicle %d given to %s", vehicleid, NAMEX);
    return vehicleid;
}

public OnPlayerConnect(playerid)
{
    ADD_MONEY(playerid, initialmoney); //initial money
    AllowPlayerTeleport(playerid, true);
	Me(playerid, "joined server", COLOR_GREY, playerid);
	MESSAGE(COLOR_ORANGE, "Welcome to Newb Server Freeroam!");
	MESSAGE(COLOR_ORANGE, "Type /cmds for list of commands");
	MESSAGE(COLOR_ORANGE, "Type /buy to buy vehicles and weapons");
	SendDeathMessage(INVALID_PLAYER_ID, playerid, ICON_CONNECT);
	return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    printf("%s entered command: %s", NAMEX, cmdtext);
	new cmd[MAX_CMD], idx;
	cmd = strtok(cmdtext, idx);
	ALIAS("/cmd","/cmds");
	ALIAS("/commands","/cmds");
	CMD("/cmds")
	{
	    MESSAGE(COLOR_ORANGE, "/buy /vcolor /pm /r /me /savepos /loadpos /kill /player");
	    if (IS_ADMIN(playerid))
		{
			MESSAGE(COLOR_ORANGE, "Admin cmds: /addcash /v /kick /ban");
			MESSAGE(COLOR_ORANGE, "/makeadmin /initialmoney /allowdm /deleteveh");
		}
	    return 1;
	}
	CMD("/kill") return SetPlayerHealth(playerid, 0.0);
	ALIAS("/m", "/menu");
	ALIAS("/buy", "/menu");
	CMD("/menu") return ShowPlayerMainMenu(playerid);
	ALIAS("/color", "vcolor");
	CMD("/vcolor")
	{
	    if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return MESSAGE(COLOR_RED, "You are not driving");
	    new vehicleid = GetPlayerVehicleID(playerid);
	    new col1 = strval(strtok(cmdtext, idx));
	    new c[128];
	    c = strtok(cmdtext, idx);
	    new col2 = strval(c);
	    if (isnull(c)) col2 = col1;
	    ChangeVehicleColor(vehicleid, col1, col2);
	    return 1;
	}
	CMD("/pm")
	{
	    new pid = GetPlayerID(strtok(cmdtext, idx));
	    if (pid == INVALID_PLAYER_ID) return MESSAGE(COLOR_STRONGRED, "Invalid player id");
	    SendPM(playerid, pid, cmdtext[idx+1]);
	    return 1;
	}
	CMD("/player")
	{
	    new pid = GetPlayerID(strtok(cmdtext, idx));
	    if (pid == INVALID_PLAYER_ID) return MESSAGE(COLOR_STRONGRED, "Invalid player id");
	    OnPlayerClickPlayer(playerid, pid, 0);
	    return 1;
	}
	CMD("/me")
	{
	    new msg[MSG_SIZE];
	    format(MSG, "* %s %s", NAME, cmdtext[idx+1]);
	    SendClientMessageToAll(COLOR_YELLOW, msg);
	    return 1;
	}
	CMD("/admins")
	{
	    MESSAGE(COLOR_ORANGE,"Admins online:");
	    new admins;
	    for (new pid; pid < MAX_PLAYERS; pid++) if (IS_ADMIN(pid))
	    {
		    new msg[MSG_SIZE];
		    format(MSG, "* %s", PlayerNameEx(pid));
		    MESSAGE(COLOR_ORANGE, msg);
		    admins++;
	    }
	    if (!admins) MESSAGE(COLOR_RED, ":: No admins ::");
	    return 1;
	}
	CMD("/savepos")
	{
		GetPlayerPos(playerid, P[savedx], P[savedy], P[savedz]);
		GetPlayerFacingAngle(playerid, P[savedr]);
		MESSAGE(COLOR_YELLOW, "Position saved!");
		return 1;
	}
	CMD("/loadpos")
	{
	    if (!P[savedx] && !P[savedy]) return MESSAGE(COLOR_STRONGRED, "You need to /savepos first!");
	    if (GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
	    {
	        new vehicleid = GetPlayerVehicleID(playerid);
	        SetVehiclePos(vehicleid, P[savedx], P[savedy], P[savedz]);
	        SetVehicleZAngle(vehicleid, P[savedr]);
	    }
	    else
	    {
     		SetPlayerPos(playerid, P[savedx], P[savedy], P[savedz]);
	        SetPlayerFacingAngle(playerid, P[savedr]);
	    }
	    MESSAGE(COLOR_YELLOW, "Position loaded!");
	    return 1;
	}
	CMD("/r")
	{
	    SendPM(playerid, P[plastsender], cmdtext[idx+1]);
	    return 1;
	}
	
	//Admin commands:
	ACMD("/v")
	{
	    new model = strval(strtok(cmdtext, idx));
	    if (!model) model = 411;
	    GiveCar(playerid, model);
	    return 1;
	}
	ACMD("/initialmoney")
	{
	    initialmoney = strval(strtok(cmdtext, idx));
	    new msg[MSG_SIZE];
	    format(MSG, "Initial money set to %s", FormatMoney(initialmoney));
	    MESSAGE(COLOR_WHITE, msg);
	    return 1;
	}
	ACMD("/deleteveh")
	{
	    deleteveh = !deleteveh;
	    if (deleteveh)
		{
			MESSAGE(COLOR_WHITE, "*** Player vehicles will be deleted when player disconnects");
			for (new vehicleid; vehicleid < MAX_VEHICLES; vehicleid++) if (VehicleOwner[vehicleid] != INVALID_PLAYER_ID && !IsPlayerConnected(VehicleOwner[vehicleid]))
			{
			    VehicleOwner[vehicleid] = INVALID_PLAYER_ID;
			    DestroyVehicle(vehicleid);
			}
		}
	    else MESSAGE(COLOR_WHITE, "*** Player vehicles will remain in server when player disconnects");
		return 1;
	}
	ACMD("/allowdm")
	{
	    allowdm = !allowdm;
	    if (allowdm) SendClientMessageToAll(COLOR_ORANGE, "*** Deathmatch has been enabled by admin!");
	    else SendClientMessageToAll(COLOR_ORANGE, "*** Deathmatch has been disabled by admin!");
		return 1;
	}
	ACMD("/addcash")
	{
	    new pid, amount;
	    pid = GetPlayerID(strtok(cmdtext, idx));
	    amount = strval(strtok(cmdtext, idx));
	    if (pid == INVALID_PLAYER_ID) return MESSAGE(COLOR_STRONGRED, "Invalid player id");
	    ADD_MONEY(pid, amount);
	    new msg[MSG_SIZE];
	    format(MSG, "%s money changed to %s (added %s)", PlayerNameEx(pid), FormatMoney(GET_MONEY(pid)), FormatMoney(amount));
	    MESSAGE(COLOR_WHITE, msg);
	    return 1;
	}
	ACMD("/kick")
	{
 		new pid = GetPlayerID(strtok(cmdtext, idx));
	    if (pid == INVALID_PLAYER_ID) return MESSAGE(COLOR_STRONGRED, "Invalid player id");
	    Kick(pid);
		printf("Admin %s kicked %s", NAMEX, PlayerNameEx(pid));
		return 1;
	}
	ACMD("/ban")
	{
 		new pid = GetPlayerID(strtok(cmdtext, idx));
	    if (pid == INVALID_PLAYER_ID) return MESSAGE(COLOR_STRONGRED, "Invalid player id");
	    BanEx(pid, cmdtext[idx+1]);
	    printf("Admin %s banned %s", NAMEX, PlayerNameEx(pid));
	    return 1;
	}
	ACMD("/makeadmin")
	{
	    if (!IsPlayerAdmin(playerid)) return MESSAGE(COLOR_STRONGRED, "Only RCON admin can change admin rank");
		new pid = GetPlayerID(strtok(cmdtext, idx));
	    if (pid == INVALID_PLAYER_ID) return MESSAGE(COLOR_STRONGRED, "Invalid player id");
	    if (!cmdtext[idx]) return MESSAGE(COLOR_STRONGRED, "Usage: /makeadmin [name] [level]");
	    new msg[MSG_SIZE], level = strval(strtok(cmdtext, idx));
    	SetPVarInt(pid, VAR_ADMIN, level);
    	if (level)
    	{
	    	printf("Admin %s gave admin rights to %s", NAMEX, PlayerNameEx(pid));
	    	format(MSG, "You gave %s admin rights", PlayerNameEx(pid));
	    	MESSAGE(COLOR_WHITE, msg);
	    	format(MSG, "*** %s gave you admin rights", NAME);
	    	SendClientMessage(pid, COLOR_WHITE, msg);
    	}
    	else
    	{
    		printf("Admin %s took admin rights from %s", NAMEX, PlayerNameEx(pid));
	    	format(MSG, "%s is no longer an admin", PlayerNameEx(pid));
	    	MESSAGE(COLOR_WHITE, msg);
	    	format(MSG, "*** %s took admin rights from you", NAME);
	    	SendClientMessage(pid, COLOR_WHITE, msg);
    	}
    	return 1;

	}
	return MESSAGE(COLOR_STRONGRED, "Wrong command. Type /cmds for list of available commands!");
}

public OnVehicleDamageStatusUpdate(vehicleid, playerid)
{
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	DeletePlayerVehicles(playerid);
	P[plastsender] = INVALID_PLAYER_ID;
	switch(reason)
	{
		case LEAVE_EXIT: Me(playerid, "left server (exit)", COLOR_GREY, playerid);
		case LEAVE_TIMEOUT: Me(playerid, "left server (timeout)", COLOR_GREY, playerid);
		case LEAVE_KICK: Me(playerid, "left server (kick)", COLOR_GREY, playerid);
	}
	SendDeathMessage(INVALID_PLAYER_ID, playerid, ICON_DISCONNECT);
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch (dialogid)
	{
	    case DIALOG_GUNS:
	    {
	        if (!response) return ShowPlayerMainMenu(playerid);
	        new weapon = P[dialoglist][listitem];
	        new name[20], price=WeaponPrice[weapon];
	        GetWeaponName(weapon, name, 20);
	        new msg[MSG_SIZE];
	        if (PAY(price))
	        {
				GivePlayerWeapon(playerid, weapon, 200);
				format(MSG, "You bought %s for %s", name, FormatMoney(price));
				MESSAGE(COLOR_YELLOW, msg);
				format(MSG, "bought %s", name);
				Me(playerid, msg, COLOR_WHITE, playerid);
	        }
	        else
	        {
	        	format(MSG, "You can't afford %s", name);
	        	MESSAGE(COLOR_RED, msg);
        	}
	    }
	    case DIALOG_MAIN:
	    {
	        if (!response) return false;
	        switch(P[dialoglist][listitem])
	        {
	            case ACTION_GUNS: //Show guns menu
	            {
	                new list[512], n;
	                for (new weapon; weapon < MAX_WEAPONS; weapon++) if (WeaponPrice[weapon])
	                {
	                    new line[64];
	                    GetWeaponName(weapon, line, 64);
	                    if (isnull(line)) continue;
	                    format(line, 64, "%25s\t%s", line, FormatMoney(WeaponPrice[weapon]));
	                    ADD_MENU_ITEM(line, weapon);
	                }
	                return ShowPlayerDialog(playerid, DIALOG_GUNS, DIALOG_STYLE_LIST, "Buy weapon:", list, "Buy", "Back");
	            }
	            case ACTION_REPAIR:
	            {
	                if (PAY(1000))
	                {
	                    new vehicleid = GetPlayerVehicleID(playerid);
	                    if (!vehicleid) return MESSAGE(COLOR_RED, "You need to be in a vehicle");
	                    SetVehicleHealth(vehicleid, 1000);
	                    RepairVehicle(vehicleid);
	                    Me(playerid, "repaired his vehicle", COLOR_WHITE, playerid);
	                    MESSAGE(COLOR_YELLOW, "Vehicle repaired!");
	                }
	                else MESSAGE(COLOR_RED, "You cannot afford repair :(");
	            }
	            case ACTION_HEAL:
	            {
	            	if (PAY(1000))
	                {
	                    SetPlayerHealth(playerid, 1000);
	                    Me(playerid, "healed himself", COLOR_WHITE, playerid);
	                    MESSAGE(COLOR_YELLOW, "You healed yourself");
	                }
	                else MESSAGE(COLOR_RED, "You cannot afford healing :(");
	            }
	            case ACTION_JETP:
	            {
	                if (PAY(50000))
	                {
	                    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
	                    Me(playerid, "bought jetpack", COLOR_WHITE, playerid);
	                    MESSAGE(COLOR_YELLOW, "You bought jetpack");
	                }
	                else MESSAGE(COLOR_RED, "You cannot afford jetpack");
	                
	            }
	            case ACTION_TUNE: ShowPlayerTuneDialog(playerid);
	            case ACTION_CARS: ShowPlayerVehicleDialog(playerid, FLAG_CAR);
				case ACTION_BIKE: ShowPlayerVehicleDialog(playerid, FLAG_BIKE);
				case ACTION_HELI: ShowPlayerVehicleDialog(playerid, FLAG_HELI);
				case ACTION_AIRP: ShowPlayerVehicleDialog(playerid, FLAG_PLANE);
				case ACTION_BOAT: ShowPlayerVehicleDialog(playerid, FLAG_BOAT);
	        }
	    }
	    case DIALOG_TUNE:
	    {
	        if (!response) return ShowPlayerMainMenu(playerid);
	        new vehicleid = GetPlayerVehicleID(playerid);
	        if (!vehicleid) return MESSAGE(COLOR_RED, "You need to be in a vehicle");
	        new component = P[dialoglist][listitem];
	        if (PAY(500))
	        {
	            AddVehicleComponent(vehicleid, component);
	            MESSAGE(COLOR_YELLOW, "Component installed!");
	        }
	        else
			{
				MESSAGE(COLOR_RED, "You can't afford to install any components!");
			}
			ShowPlayerTuneDialog(playerid);
	    }
	    case DIALOG_PLAYER:
	    {
	        if (!response) return false;
	        switch(P[dialoglist][listitem])
	        {
	            case ACTION_TELE:
	            {
	                new vehicleid = GetPlayerVehicleID(P[pdialogsubject]);
	                COORDS;
	                if (vehicleid) PutPlayerInVehicle(playerid, vehicleid, GetPlayerVehicleSeat(P[pdialogsubject])+1);
	                else if (GetPlayerPos(P[pdialogsubject], x, y ,z)) SetPlayerPos(playerid, x+1, y, z);
	                else MESSAGE(COLOR_RED, "Cannot teleport to player!");
	            }
	            case ACTION_PM: return SendPM(playerid, P[pdialogsubject]);
	        }
	    }
	    case DIALOG_PM:
	    {
	        if (!response) return false;
	        return SendPM(playerid, P[pdialogsubject], inputtext);
	    }
	    case DIALOG_BUYCAR:
	    {
	        if (!response) return ShowPlayerMainMenu(playerid);
	        new model = P[dialoglist][listitem];
	        new price = vmodel[model][vprice];
	        if (!price) return MESSAGE(COLOR_RED, "Invalid price!");
	        new msg[MSG_SIZE];
	        if (PAY(price))
	        {
	            GiveCar(playerid, model);
	            format(MSG, "You bought %s", vmodel[model][vname]);
	            MESSAGE(COLOR_YELLOW, msg);
	            printf("%s bought a %s for %s", NAMEX, vmodel[model][vname], FormatMoney(price));
	            
	            format(MSG, "bought %s", vmodel[model][vname]);
	            Me(playerid, msg, COLOR_WHITE, playerid);
	        }
	        else
			{
				format(MSG, "You cannot afford %s!", vmodel[model][vname]);
         		MESSAGE(COLOR_RED, msg);
  			}
	    }
	}
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	SetPlayerPos(playerid,245.3919,-59.0802,1.5776);
	SetPlayerFacingAngle(playerid,134.8186);
	SetPlayerCameraPos(playerid,245.1865,-63.4924,2);
	SetPlayerCameraLookAt(playerid,245.3919,-59.0802,1.5776);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	SendDeathMessage(killerid, playerid, reason);
	if (!allowdm) Kick(killerid);
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	return 1;
}

public OnPlayerSpawn(playerid)
{
	SetCameraBehindPlayer(playerid);
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnGameModeInit()
{
    AddPlayerClass(2,-2171.8225,-231.3405,36.5156,0,0,0,0,0,0,0);
    AddPlayerClass(16,251.6560,-53.7169,1.5776,189.6758,0,0,0,0,0,0);
    AddPlayerClass(123,-65.2176,22.0711,3.1172,280.9359,0,0,0,0,0,0);
    
    AddPlayerClass(26,-2171.8225,-231.3405,36.5156,0,0,0,0,0,0,0);
    AddPlayerClass(50,251.6560,-53.7169,1.5776,189.6758,0,0,0,0,0,0);
    AddPlayerClass(56,-65.2176,22.0711,3.1172,280.9359,0,0,0,0,0,0);
    
    AddStaticVehicle(520,-1428.7991,-950.2964,201.7822,90.9085,1,1); // Hidden hydra
	AddStaticVehicle(411,-48.1314,30.3002,6.2114,340.2334,1,1); // infernus
	AddStaticVehicle(412,-45.1042,8.5053,2.9529,76.1494,1,1); // voodoo
	AddStaticVehicle(400,248.7475,-66.7810,1.5922,90.2545,1,1); // landstalk
	AddStaticVehicle(600,-2167.4612,-218.7921,35.0423,269.4399,1,1); // picador
	AddStaticVehicle(518,-2169.6189,-210.1241,35.0381,272.3559,1,1); // 518
	AddStaticVehicle(445,-2108.4072,-199.9535,35.0429,84.7274,1,1); // car
	AddStaticVehicle(542,-2120.8796,-199.7143,35.0336,89.1797,1,1); // car
	AddStaticVehicle(603,-2108.0698,-206.1693,35.0358,86.5817,1,1); // car
	AddStaticVehicle(575,-2120.6665,-206.6063,35.0346,93.7792,1,1); // car
	AddStaticVehicle(566,259.0569,-66.8767,1.5935,89.8684,1,1); // car
	AddStaticVehicle(576,269.8968,-66.9651,1.5921,89.6229,1,1); // car
	AddStaticVehicle(400,282.3719,-67.0643,1.5921,89.6582,1,1); // car
	AddStaticVehicle(561,299.8982,-67.1964,1.5921,89.7443,1,1); // car
	AddStaticVehicle(474,-82.0115,26.3711,2.8443,64.3736,1,1); // car
	AddStaticVehicle(546,-79.8659,30.9216,2.8443,70.6645,1,1); // car
	AddStaticVehicle(547,-81.0313,37.0888,2.8443,67.7764,1,1); // car
	AddStaticVehicle(478,-66.4904,46.6527,2.8373,345.8279,1,1); // car
	AddStaticVehicle(424,-56.9975,45.7391,2.8373,339.5147,1,1); // car
	AddStaticVehicle(536,-55.1139,37.0969,2.8381,160.4162,1,1); // blade
	AddStaticVehicle(562,-37.0701,22.0295,2.8437,285.7455,1,1); // car
	AddStaticVehicle(466,-52.4592,-3.8276,2.8443,70.9538,1,1); // car
	AddStaticVehicle(585,-34.1480,-10.1411,2.8384,70.9741,1,1); // car
	AddStaticVehicle(553,-1359.5168,-157.6065,15.4839,343.7620,1,1); // plane
	AddStaticVehicle(553,-1357.0902,-220.5655,15.4824,308.3209,1,1); // plane
	AddStaticVehicle(519,-1307.6605,-251.6072,15.0674,311.9366,1,1); // plane
	AddStaticVehicle(487,-1183.0811,28.3879,14.3245,37.4348,1,1); // heli
	AddStaticVehicle(487,-1229.5546,-1.0501,14.3196,45.8350,1,1); // heli
	AddStaticVehicle(487,1563.5983,1628.0626,11.0888,116.8251,1,1); // heli
	AddStaticVehicle(487,1593.2030,1627.5576,11.1229,171.6428,1,1); // heli
	AddStaticVehicle(519,1566.9756,1586.0889,11.7419,83.4322,1,1); // plane
	AddStaticVehicle(519,1560.4854,1413.9384,11.7674,111.7274,1,1); // plane
	AddStaticVehicle(519,1802.6219,-2424.6255,14.4765,178.8768,1,1); // plane
	AddStaticVehicle(487,1883.3986,-2380.8557,13.8674,304.2246,1,1); // heli
	AddStaticVehicle(511,1980.8752,-2425.0864,14.9218,149.3919,1,1); // plane


	
	ADD_VEHICLE(411, "Infernus", 200000, FLAG_CAR);
	ADD_VEHICLE(506, "Super GT", 180000, FLAG_CAR);
	ADD_VEHICLE(429, "Banshee", 160000, FLAG_CAR);
	ADD_VEHICLE(444, "Monster", 100000, FLAG_CAR);
	ADD_VEHICLE(502, "Hotring", 170000, FLAG_CAR);
	ADD_VEHICLE(480, "Comet", 80000, FLAG_CAR);
	ADD_VEHICLE(402, "Buffalo", 150000, FLAG_CAR);
	ADD_VEHICLE(415, "Cheetah", 160000, FLAG_CAR);
	ADD_VEHICLE(534, "Remington", 80000, FLAG_CAR);
	ADD_VEHICLE(434, "Hotknife", 130000, FLAG_CAR);
	ADD_VEHICLE(560, "Sultan", 110000, FLAG_CAR);
	ADD_VEHICLE(412, "Voodoo", 200000, FLAG_CAR);
	ADD_VEHICLE(419, "Esperanto", 100000, FLAG_CAR);
	ADD_VEHICLE(551, "Merit", 120000, FLAG_CAR);
	ADD_VEHICLE(549, "Tampa", 90000, FLAG_CAR);
	ADD_VEHICLE(579, "Huntley", 120000, FLAG_CAR);
	ADD_VEHICLE(600, "Picador", 200000, FLAG_CAR);
	
	ADD_VEHICLE(522, "NRG 500", 60000, FLAG_BIKE);
	ADD_VEHICLE(463, "Freeway", 40000, FLAG_BIKE);
	ADD_VEHICLE(462, "Faggio", 10000, FLAG_BIKE);
	ADD_VEHICLE(468, "Sanchez", 20000, FLAG_BIKE);
	ADD_VEHICLE(586, "Wayfarer", 36000, FLAG_BIKE);
	ADD_VEHICLE(510, "Mountain bike", 5000, FLAG_BIKE);
	
	ADD_VEHICLE(487, "Maverick", 150000, FLAG_HELI);
	ADD_VEHICLE(469, "Sparrow", 140000, FLAG_HELI);
	ADD_VEHICLE(417, "Leviathan", 130000, FLAG_HELI);
	ADD_VEHICLE(425, "Hunter", 450000, FLAG_HELI);
	
	ADD_VEHICLE(520, "Hydra", 500000, FLAG_PLANE);
	ADD_VEHICLE(519, "Shamal", 150000, FLAG_PLANE);
	ADD_VEHICLE(593, "Dodo", 80000, FLAG_PLANE);
	ADD_VEHICLE(513, "Stuntplane", 100000, FLAG_PLANE);
	ADD_VEHICLE(460, "Skimmer", 85000, FLAG_PLANE);
	
	ADD_VEHICLE(493, "Jetmax", 100000, FLAG_BOAT);
	ADD_VEHICLE(484, "Marquis", 800000, FLAG_BOAT);
	ADD_VEHICLE(446, "Squalo", 200000, FLAG_BOAT);
	
	WeaponPrice[4] = 50000;
	WeaponPrice[9] = 50000;
	WeaponPrice[18] = 80000;
	WeaponPrice[24] = 90000;
	WeaponPrice[24] = 110000;
	WeaponPrice[29] = 165000;
	WeaponPrice[31] = 168000;
	WeaponPrice[38] = 1500000;
	WeaponPrice[35] = 1400000;
	
	
	for (new vehicleid=1; vehicleid < MAX_VEHICLES; vehicleid++)
	{
	    VehicleOwner[vehicleid] = INVALID_PLAYER_ID;
	    new col = random(127);
	    ChangeVehicleColor(vehicleid, col, col);
	}
	

    AllowAdminTeleport(1);
	EnableStuntBonusForAll(0);
	UsePlayerPedAnims();
	ShowPlayerMarkers(1);
	
	SendRconCommand("gamemodetext Freeroam");
	SendRconCommand("hostname :: Newb Server Freeroam ::");
	SetTimer("MainTimer", 1000, true);
	print("Newb Server Freeroam loaded!");
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	if (clickedplayerid == playerid) return ShowPlayerMainMenu(playerid);
	P[pdialogsubject] = clickedplayerid;
	new list[512], n;
	ADD_MENU_ITEM("Send Message", ACTION_PM);
	ADD_MENU_ITEM("Teleport to player", ACTION_TELE);
	ShowPlayerDialog(playerid, DIALOG_PLAYER, DIALOG_STYLE_LIST, "Player menu", list, "OK", "Cancel");
	return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

stock FormatMoney(Float:amount, delimiter[2]=",")
{
	#define MAX_MONEY_STRING 16
	new txt[MAX_MONEY_STRING];
	format(txt, MAX_MONEY_STRING, "$%d", floatround(amount));
	new l = strlen(txt);
	if (amount < 0) // -
	{
	    if (l > 5) strins(txt, delimiter, l-3);
		if (l > 8) strins(txt, delimiter, l-6);
		if (l > 11) strins(txt, delimiter, l-9);
	}
	else
	{
		if (l > 4) strins(txt, delimiter, l-3);
		if (l > 7) strins(txt, delimiter, l-6);
		if (l > 10) strins(txt, delimiter, l-9);
	}
	return txt;
}

stock strcp(from[], to[])
{
	for (new i; from[i]; i++) to[i] = from[i];
}

stock IsVehicleUpsideDown(vehicleid)
{
    new Float:quat_w,Float:quat_x,Float:quat_y,Float:quat_z;
    GetVehicleRotationQuat(vehicleid,quat_w,quat_x,quat_y,quat_z);
    new Float:y = atan2(2*((quat_y*quat_z)+(quat_w*quat_x)),(quat_w*quat_w)-(quat_x*quat_x)-(quat_y*quat_y)+(quat_z*quat_z));
    return (y > 90 || y < -90);
}

stock strtok(const string[], &index)
{
	new length = strlen(string);
	while ((index < length) && (string[index] <= ' '))
	{
		index++;
	}

	new offset = index;
	new result[20];
	while ((index < length) && (string[index] > ' ') && ((index - offset) < (sizeof(result) - 1)))
	{
		result[index - offset] = string[index];
		index++;
	}
	result[index - offset] = EOS;
	return result;
}

/*
	Newb Server Freeroam by mick88
	REL 14/11/2010
*/
