//Gamemode Settings

//Whether coop is enabled or not
float() cooperative = 
{
#ifdef qw
//QuakeWorld only
	return 0;
#else
//NetQuake only
	return coop;
#endif
}

//Skill 3
float() nightmare = 
{
#ifdef qw
//QuakeWorld only
	return 0;
#else
//NetQuake only
	if (skill == 3 && !(cvar("temp1") & SET_COPPERNIGHTMARE))
		return TRUE;
	else
		return FALSE;
#endif
}

//Skill 3 with copper settings
float() coppernightmare = 
{
#ifdef qw
//QuakeWorld only
	return 0;
#else
//NetQuake only
	if (skill == 3 && cvar("temp1") & SET_COPPERNIGHTMARE)
		return TRUE;
	else
		return FALSE;
#endif
}

//Explosive weapons only mode
float() explomode = 
{
	if (cvar("temp1") & SET_EXPLOMODE)
		return TRUE;
	else
		return FALSE;
}

//For if weapons should stay instead of disappearing once picked up
float() weaponstay =
{
	if (deathmatch)
	{
		if (deathmatch != 1)
		{
			return 1;
		}
	}
	return 0;
};

//Items don't respawn in deathmatch 2
float() itemrespawn =
{
	if (deathmatch && deathmatch != 2)
	{
		return 1;
	}
	else
	{
		return 0;
	}
};

//For deathmatch 1, which uses the old ammo respawn time
float() slowammo =
{
	if (deathmatch == 1)
	{
		return 1;
	}
	else
	{
		return 0;
	}
};

//For deathmatch 4
//Starts each player off with every weapon and infinite ammo
float() supermode =
{
	if (deathmatch == 4)
	{
		return 1;
	}
	else
	{
		return 0;
	}
};

//For deathmatch 5
//Starts each player off with every weapon and a fair amount of ammo
float() supermode2 =
{
	if (deathmatch == 5 || deathmatch == 7)
	{
		return 1;
	}
	else
	{
		return 0;
	}
};

//Disables powerups. Useful for 1v1 modes.
float() powerupdisable =
{
	//In duel and all odd-numbered modes above that, powerups are turned off.
	if (deathmatch == 6 || (deathmatch >= 7 && (deathmatch / 2) != floor(deathmatch / 2)))
	{
		return 1;
	}
	else
	{
		return 0;
	}
};

//Disables all items
float() allitemdisable =
{
	if (deathmatch == 7)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

//Like duel, but the game resets everytime a player dies
float() lastmanstanding =
{
	if (deathmatch == 7 || deathmatch == 8 || deathmatch == 9)
	{
		return 1;
	}
	else
	{
		return 0;
	}
};

//Disables the Rocket Launcher and Lightning Gun
float() mediumweapons =
{
	if (deathmatch == 102 || deathmatch == 103)
	{
		return 1;
	}
	else
	{
		return 0;
	}
};

//Disables all weapons except for the Super Shotgun and Nailgun
float() weakweapons =
{
	if (deathmatch == 104 || deathmatch == 105)
	{
		return 1;
	}
	else
	{
		return 0;
	}
};

//Control flags to win
float() domination =
{
	if (deathmatch == 10 || deathmatch == 11)
	{
		return 1;
	}
	else
	{
		return 0;
	}
};

//Rebalances the weapons to play more like Quake III
float() arenamode =
{
	if (deathmatch == 100 || deathmatch == 101)
	{
		return 1;
	}
	else
	{
		return 0;
	}
};


