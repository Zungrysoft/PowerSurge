void() movetarget_f;
void() t_movetarget;
void() knight_walk1;
void(entity etemp, entity stemp, entity stemp, float dmg) T_Damage;
/*

.enemy
Will be world if not currently angry at anyone.

.movetarget
The next path spot to walk toward.  If .enemy, ignore .movetarget.
When an enemy is killed, the monster will try to return to it's path.

.huntt_ime
Set to time + something when the player is in sight, but movement straight for
him is blocked.  This causes the monster to use wall following code for
movement direction instead of sighting on the player.

.ideal_yaw
A yaw angle of the intended direction, which will be turned towards at up
to 45 deg / state.  If the enemy is in view and hunt_time is not active,
this will be the exact line towards the enemy.

.pausetime
A monster will leave it's stand state and head towards it's .movetarget when
time > .pausetime.

walkmove(angle, speed) primitive is all or nothing
*/


//
// globals
//

//
// when a monster becomes angry at a player, that monster will be used
// as the sight target the next frame so that monsters near that one
// will wake up even if they wouldn't have noticed the player
//
entity	sight_entity;
float	sight_entity_time;

float(float v) anglemod =
{
	while (v >= 360)
		v = v - 360;
	while (v < 0)
		v = v + 360;
	return v;
};

/*
==============================================================================

MOVETARGET CODE

The angle of the movetarget effects standing and bowing direction, but has no effect on movement, which allways heads to the next target.

targetname
must be present.  The name of this movetarget.

target
the next spot to move to.  If not present, stop here for good.

pausetime
The number of seconds to spend standing or bowing for path_stand or path_bow

==============================================================================
*/

void() movetarget_f =
{
	if (!self.targetname)
		objerror ("monster_movetarget: no targetname");
		
	self.solid = SOLID_TRIGGER;
	self.touch = t_movetarget;
	setsize (self, '-8 -8 -8', '8 8 8');
	
};

/*QUAKED path_corner (0.5 0.3 0) (-8 -8 -8) (8 8 8)
Monsters will continue walking towards the next target corner.
*/
void() path_corner =
{
	movetarget_f ();
};


/*
=============
t_movetarget

Something has bumped into a movetarget.  If it is a monster
moving towards it, change the next destination and continue.
==============
*/
void() t_movetarget =
{
local entity	temp;

	if (other.movetarget != self)
		return;
	
	if (other.enemy)
		return;		// fighting, not following a path

	temp = self;
	self = other;
	other = temp;

	if (self.classname == "monster_ogre")
		sound (self, CHAN_VOICE, "ogre/ogdrag.wav", 1, ATTN_IDLE);// play chainsaw drag sound

//dprint ("t_movetarget\n");
	self.goalentity = self.movetarget = find (world, targetname, other.target);
	self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
	if (!self.movetarget)
	{
		self.pausetime = time + 999999;
		self.th_stand ();
		return;
	}
};



//============================================================================

/*
=============
range

returns the range catagorization of an entity reletive to self
0	melee range, will become hostile even if back is turned
1	visibility and infront, or visibility and show hostile
2	infront and show hostile
3	only triggered by damage
=============
*/
float(entity targ) range =
{
local vector	spot1, spot2;
local float		r;	
	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;
	
	r = vlen (spot1 - spot2);
	if (r < 120)
		return RANGE_MELEE;
	if (r < 500)
		return RANGE_NEAR;
	if (r < 1000)
		return RANGE_MID;
	return RANGE_FAR;
};

/*
=============
visible

returns 1 if the entity is visible to self, even if not infront ()
=============
*/
float (entity targ) visible =
{
	local vector	spot1, spot2;
	
	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;
	traceline (spot1, spot2, TRUE, self);	// see through other monsters
	
	if (trace_inopen && trace_inwater)
		return FALSE;			// sight line crossed contents

	if (trace_fraction == 1)
		return TRUE;
	return FALSE;
};


/*
=============
infront

returns 1 if the entity is in front (in sight) of self
=============
*/
float(entity targ) infront =
{
	local vector	vec;
	local float		dot;
	
	makevectors (self.angles);
	vec = normalize (targ.origin - self.origin);
	dot = vec * v_forward;
	
	if ( dot > 0.3)
	{
		return TRUE;
	}
	return FALSE;
};


//============================================================================

/*
===========
ChangeYaw

Turns towards self.ideal_yaw at self.yaw_speed
Sets the global variable current_yaw
Called every 0.1 sec by monsters
============
*/
/*

void() ChangeYaw =
{
	local float		ideal, move;

//current_yaw = self.ideal_yaw;
// mod down the current angle
	current_yaw = anglemod( self.angles_y );
	ideal = self.ideal_yaw;
	
	if (current_yaw == ideal)
		return;
	
	move = ideal - current_yaw;
	if (ideal > current_yaw)
	{
		if (move > 180)
			move = move - 360;
	}
	else
	{
		if (move < -180)
			move = move + 360;
	}
		
	if (move > 0)
	{
		if (move > self.yaw_speed)
			move = self.yaw_speed;
	}
	else
	{
		if (move < 0-self.yaw_speed )
			move = 0-self.yaw_speed;
	}

	current_yaw = anglemod (current_yaw + move);

	self.angles_y = current_yaw;
};

*/


//============================================================================

void() HuntTarget =
{
	self.goalentity = self.enemy;
	self.think = self.th_run;
	self.ideal_yaw = vectoyaw(self.enemy.origin - self.origin);
	self.nextthink = time + 0.1;
	SUB_AttackFinished (1);	// wait a while before first attack
};

void() SightSound =
{
local float	rsnd;

	if (self.classname == "monster_ogre")	
		sound (self, CHAN_AUTO, "ogre/ogwake.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_devil")	
		sound (self, CHAN_AUTO, "devil/sight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_knight")
		sound (self, CHAN_AUTO, "knight/ksight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_shambler")
		sound (self, CHAN_AUTO, "shambler/ssight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_demon1")
		sound (self, CHAN_AUTO, "demon/sight2.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_wizard")
		sound (self, CHAN_AUTO, "wizard/wsight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_zombie")
		sound (self, CHAN_AUTO, "zombie/z_idle.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_dog")
		sound (self, CHAN_AUTO, "dog/dsight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_hell_knight")
		sound (self, CHAN_AUTO, "hknight/sight1.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_tarbaby")
		sound (self, CHAN_AUTO, "blob/sight1.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_enforcer")
	{
		rsnd = rint(random() * 3);			
		if (rsnd == 1)
			sound (self, CHAN_AUTO, "enforcer/sight1.wav", 1, ATTN_NORM);
		else if (rsnd == 2)
			sound (self, CHAN_AUTO, "enforcer/sight2.wav", 1, ATTN_NORM);
		else if (rsnd == 0)
			sound (self, CHAN_AUTO, "enforcer/sight3.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_AUTO, "enforcer/sight4.wav", 1, ATTN_NORM);
	}
	else if (self.classname == "monster_army")
		sound (self, CHAN_AUTO, "soldier/sight1.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_shalrath")
		sound (self, CHAN_AUTO, "shalrath/sight.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_lostsoul")
		sound (self, CHAN_AUTO, "lostsoul/idle1.wav", 1, ATTN_NORM);
	else if (self.classname == "monster_pain_elemental")
		sound (self, CHAN_AUTO, "painelem/wake.wav", 1, ATTN_NORM);
};

void() FoundTarget =
{
	if (self.enemy.classname == "player")
	{	// let other monsters see this monster for a while
		sight_entity = self;
		sight_entity_time = time;
	}
	
	self.show_hostile = time + 1;		// wake up other monsters

	SightSound ();
	HuntTarget ();
};


// Separates monster classes into teams
float(entity e) monster_team = {
	if (e.classname == "monster_enforcer") {
		return 1;
	}
	if (e.classname == "monster_army") {
		return 1;
	}
	if (e.classname == "monster_dog") {
		return 1;
	}
	return 0;
}


// Find the next player or monster
entity(entity e) find_enemy_monster = {
	// The entity must be a monster, be on the other team, and be nearby
	// Also has a random chance to deny the monster, so it doesn't always pick the same monster to fight

	for (float i = 0; i < 100; i ++) {
		e = nextent(e);
		if (random() < 0.4) {
			if (e.flags & FL_MONSTER) {
				if (monster_team(e) != monster_team(self)) {
					if (range(e) <= RANGE_MID) {
						break;
					}
				}
			}
		}
	}
	
	return e;
}


/*
===========
FindTarget

Self is currently not attacking anything, so try to find a target

Returns TRUE if an enemy was sighted

When a player fires a missile, the point of impact becomes a fakeplayer so
that monsters that see the impact will respond as if they had seen the
player.

To avoid spending too much time, only a single client (or fakeclient) is
checked each frame.  This means multi player games will have slightly
slower noticing monsters.
============
*/
float() FindTarget =
{
	local entity	client;
	local float		r;
	local float		is_monster;

// if the first spawnflag bit is set, the monster will only wake up on
// really seeing the player, not another monster getting angry

// spawnflags & 3 is a big hack, because zombie crucified used the first
// spawn flag prior to the ambush flag, and I forgot about it, so the second
// spawn flag works as well
	
	if (sight_entity_time >= time - 0.1 && !(self.spawnflags & 3) )
	{
		client = sight_entity;
		if (client.enemy == self.enemy)
			return TRUE;
	}
	else
	{
		// If bad blood is enabled, also search for monsters to attack
		if (bad_blood && (random() < 0.5))
		{
			self.prev_check = find_enemy_monster(self.prev_check);
			client = self.prev_check;
			is_monster = 1;
		}
		else
		{
			client = checkclient ();
		}
		if (!client)
			return FALSE;	// current check entity isn't in PVS
	}
	
	if (client.health <= 0)
		return FALSE;
	
	if (client.classname != "player" && !is_monster)
		if (client.enemy.health <= 0)
			return FALSE;

	if (client == self.enemy)
		return FALSE;
		
	if (client == self)
		return FALSE;

	if (client.flags & FL_NOTARGET)
		return FALSE;
	if (client.items & IT_INVISIBILITY)
		return FALSE;
	if (client.movetype == MOVETYPE_NONE)
		return FALSE;

	r = range (client);
	if (r == RANGE_FAR)
		return FALSE;
		
	if (!visible (client))
		return FALSE;

	if (r == RANGE_NEAR)
	{
		if (client.show_hostile < time && !infront (client))
			return FALSE;
	}
	else if (r == RANGE_MID)
	{
		if ( /* client.show_hostile < time || */ !infront (client))
			return FALSE;
	}
	
//
// got one
//
	self.enemy = client;
	if (self.enemy.classname != "player" && !is_monster)
	{
		self.enemy = self.enemy.enemy;
		if (self.enemy.classname != "player")
		{
			self.enemy = world;
			return FALSE;
		}
	}
	FoundTarget ();

	return TRUE;
};


//=============================================================================

void(float dist) ai_forward =
{
	walkmove (self.angles_y, dist);
};

void(float dist) ai_back =
{
	walkmove ( (self.angles_y+180), dist);
};


/*
=============
ai_pain

stagger back a bit
=============
*/
void(float dist) ai_pain =
{
	ai_back (dist);
/*
	local float	away;
	
	away = anglemod (vectoyaw (self.origin - self.enemy.origin) 
	+ 180*(random()- 0.5) );
	
	walkmove (away, dist);
*/
};

/*
=============
ai_painforward

stagger back a bit
=============
*/
void(float dist) ai_painforward =
{
	walkmove (self.ideal_yaw, dist);
};

/*
=============
ai_walk

The monster is walking it's beat
=============
*/
void(float dist) ai_walk =
{
	movedist = dist;
	// check for noticing a player
	if (FindTarget ())
		return;

	movetogoal (dist);
};


/*
=============
ai_stand

The monster is staying in one place for a while, with slight angle turns
=============
*/
void() ai_stand =
{
	if (FindTarget ())
		return;
	
	if (time > self.pausetime)
	{
		self.th_walk ();
		return;
	}
	
// change angle slightly

};

/*
=============
ai_turn

don't move, but turn towards ideal_yaw
=============
*/
void() ai_turn =
{
	if (FindTarget ())
		return;
	
	ChangeYaw ();
};

//=============================================================================

/*
=============
ChooseTurn
=============
*/
void(vector dest3) ChooseTurn =
{
	local vector	dir, newdir;
	
	dir = self.origin - dest3;

	newdir_x = trace_plane_normal_y;
	newdir_y = 0 - trace_plane_normal_x;
	newdir_z = 0;
	
	if (dir * newdir > 0)
	{
		dir_x = 0 - trace_plane_normal_y;
		dir_y = trace_plane_normal_x;
	}
	else
	{
		dir_x = trace_plane_normal_y;
		dir_y = 0 - trace_plane_normal_x;
	}

	dir_z = 0;
	self.ideal_yaw = vectoyaw(dir);	
};

/*
============
FacingIdeal

============
*/
float() FacingIdeal =
{
	local	float	delta;
	
	delta = anglemod(self.angles_y - self.ideal_yaw);
	if (delta > 45 && delta < 315)
		return FALSE;
	return TRUE;
};


//=============================================================================

float()	WizardCheckAttack;
float()	DogCheckAttack;
float()	SoulCheckAttack;
float()	PainelemCheckAttack;
float()	DevilCheckAttack;
float()	WalkerCheckAttack;

float() CheckAnyAttack =
{
	if (!enemy_vis && self.classname != "monster_devil")
		return FALSE;
	if (self.classname == "monster_army")
		return SoldierCheckAttack ();
	if (self.classname == "monster_ogre")
		return OgreCheckAttack ();
	if (self.classname == "monster_devil")
		return DevilCheckAttack ();
	if (self.classname == "monster_walker")
		return WalkerCheckAttack ();
	if (self.classname == "monster_shambler")
		return ShamCheckAttack ();
	if (self.classname == "monster_demon1")
		return DemonCheckAttack ();
	if (self.classname == "monster_dog")
		return DogCheckAttack ();
	if (self.classname == "monster_wizard")
		return WizardCheckAttack ();
	if (self.classname == "monster_pain_elemental")
		return PainelemCheckAttack ();
	if (self.classname == "monster_lostsoul")
		return SoulCheckAttack ();
	return CheckAttack ();
};


/*
=============
ai_run_melee

Turn and close until within an angle to launch a melee attack
=============
*/
void() ai_run_melee =
{
	self.ideal_yaw = enemy_yaw;
	ChangeYaw ();

	if (FacingIdeal())
	{
		self.th_melee ();
		self.attack_state = AS_STRAIGHT;
	}
};


/*
=============
ai_run_missile

Turn in place until within an angle to launch a missile attack
=============
*/
void() ai_run_missile =
{
	self.ideal_yaw = enemy_yaw;
	ChangeYaw ();
	if (FacingIdeal())
	{
		self.th_missile ();
		self.attack_state = AS_STRAIGHT;
	}
};


/*
=============
ai_run_slide

Strafe sideways, but stay at aproximately the same range
=============
*/
void() ai_run_slide =
{
	local float	ofs;
	
	self.ideal_yaw = enemy_yaw;
	ChangeYaw ();
	if (self.lefty)
		ofs = 90;
	else
		ofs = -90;
	
	if (walkmove (self.ideal_yaw + ofs, movedist))
		return;
		
	self.lefty = 1 - self.lefty;
	
	walkmove (self.ideal_yaw - ofs, movedist);
};


/*
=============
ai_run

The monster has an enemy it is trying to kill
=============
*/
void(float dist) ai_run =
{
	movedist = dist;
// see if the enemy is dead
	if (self.enemy.health <= 0)
	{
		self.enemy = world;
	// FIXME: look all around for other targets
		if (self.oldenemy.health > 0)
		{
			self.enemy = self.oldenemy;
			HuntTarget ();
		}
		else
		{
			if (self.movetarget)
				self.th_walk ();
			else
				self.th_stand ();
			return;
		}
	}

	self.show_hostile = time + 1;		// wake up other monsters

// check knowledge of enemy
	enemy_vis = visible(self.enemy);
	if (enemy_vis)
		self.search_time = time + 5;

// look for other coop players
	if (cooperative() && self.search_time < time)
	{
		if (FindTarget ())
			return;
	}

	enemy_infront = infront(self.enemy);
	enemy_range = range(self.enemy);
	enemy_yaw = vectoyaw(self.enemy.origin - self.origin);
	
	if (self.attack_state == AS_MISSILE)
	{
		ai_run_missile ();
		return;
	}
	if (self.attack_state == AS_MELEE)
	{
		ai_run_melee ();
		return;
	}

	if (CheckAnyAttack ())
		return;					// beginning an attack
		
	if (self.attack_state == AS_SLIDING)
	{
		ai_run_slide ();
		return;
	}
		
// head straight in
	movetogoal (dist);		// done in C code...
};

// Entity that sets the bad_blood global
void() flag_bad_blood =
{
	bad_blood = 1;
}
