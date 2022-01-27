float(float a1, float a2) angle_between = {
	local float swapper;
	local float delta;

	// Make a2 the larger angle
	if (a1 > a2) {
		swapper = a1;
		a1 = a2;
		a2 = swapper;
	}
	
	delta = a2-a1;
	
	if (delta <= 180) {
		return delta;
	}
	else {
		return (a1+360)-a2;
	}
}

void() update_secrets = {
	WriteByte(MSG_ALL, 3/*SVC_UPDATESTAT*/);
	WriteByte(MSG_ALL, 11/*STAT_TOTALSECRETS*/);
	WriteLong(MSG_ALL, total_secrets);
	
	WriteByte(MSG_ALL, 3/*SVC_UPDATESTAT*/);
	WriteByte(MSG_ALL, 13/*STAT_FOUNDSECRETS*/);
	WriteLong(MSG_ALL, found_secrets);
}

void() update_monsters = {
	WriteByte(MSG_ALL, 3/*SVC_UPDATESTAT*/);
	WriteByte(MSG_ALL, 12/*STAT_TOTALMONSTERS*/);
	WriteLong(MSG_ALL, total_monsters);
	
	WriteByte(MSG_ALL, 3/*SVC_UPDATESTAT*/);
	WriteByte(MSG_ALL, 14/*STAT_KILLEDMONSTERS*/);
	WriteLong(MSG_ALL, killed_monsters);
}
