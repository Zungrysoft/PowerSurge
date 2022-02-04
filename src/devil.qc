/*
==============================================================================
Devil
==============================================================================
*/

// Balancing Parameters
#define DEVIL_MELEE_DAMAGE 90
#define DEVIL_GRENADE_DAMAGE 45
#define DEVIL_FOLLOW_RANGE_MAX 512
#define DEVIL_FOLLOW_RANGE_MIN 256
#define DEVIL_CLOSEST_DIST 64
#define DEVIL_CHECK_ANGLES 16
#define DEVIL_CHECK_DISTANCES 3

#define target_marker trigger_field

$frame stand1 stand2 stand3 stand4 stand5 stand6 stand7 stand8 stand9
$frame stand10 stand11 stand12 stand13 standlo

$frame walk1 walk2 walk3 walk4 walk5 walk6 walk7 walk8 walk9
$frame walk10 walk11 walk12 walk13 walk14 walk15 walk16 walklo

$frame run1 run2 run3 run4 run5 run6 run7 run8 runlo

$frame throw1 throw2 throw3 throw4 throw5 throw6 throw7 throw8 throw9
$frame throw10 throw11 throw12 throw13 throwlo

$frame swing1 swing2 swing3 swing4 swing5 swing6 swing7
$frame swing8 swing9 swing10 swing11 swing12 swing13 swing14

$frame smash1 smash2 smash3 smash4 smash5 smash6 smash7
$frame smash8 smash9 smash10 smash11 smash12 smash13 smash14

$frame pain1 pain2 pain3 pain4 pain5

$frame painb1 painb2 painb3

$frame painc1 painc2 painc3 painc4 painc5 painc6

$frame paind1 paind2 paind3 paind4 paind5 paind6 paind7 paind8 paind9 paind10
$frame paind11 paind12 paind13 paind14 paind15 paind16

$frame paine1 paine2 paine3 paine4 paine5 paine6 paine7 paine8 paine9 paine10
$frame paine11 paine12 paine13 paine14 paine15

$frame death1 death2 death3 death4 death5 death6
$frame death7 death8 death9 death10 death11 death12
$frame death13 death14

$frame bdeath1 bdeath2 bdeath3 bdeath4 bdeath5 bdeath6
$frame bdeath7 bdeath8 bdeath9 bdeath10

//=============================================================================

/*
===============
AI Replacements
===============
*/
void() ai_devil_track = {
	local float ideal_dist;
	local vector angle_try;
	local float distance_try;
	local vector try_loc;
	local float try_dist;
	
	local vector closest_location;
	local float closest_dist;
	
	// Remove old location entity
	if (self.target_marker) {
		remove(self.target_marker);
		self.target_marker = world;
	}
	
	// When infighting, just run straight toward the monster
	if (self.enemy.flags & FL_MONSTER) {
		self.goalentity = self.enemy;
		return;
	}
	
	// Try different locations that are an ideal distance from the player
	// Whichever one is the closest is the one it will go to
	ideal_dist = (DEVIL_FOLLOW_RANGE_MAX + DEVIL_FOLLOW_RANGE_MIN) / 2;
	closest_dist = 9999999;
	distance_try = 0;
	while (distance_try < DEVIL_CHECK_DISTANCES && closest_dist == 9999999) {
		while (angle_try_y < 360) {
			makevectors(angle_try);
			try_loc = ((v_forward * ideal_dist) / (distance_try + 1)) + self.enemy.origin;
			try_dist = vlen(self.origin - try_loc);
			
			if (pointcontents(try_loc) != CONTENT_SOLID && random() < 0.7) {
				if (try_dist < closest_dist && try_dist > DEVIL_CLOSEST_DIST) {
					closest_dist = try_dist;
					closest_location = try_loc;
				}
			}
			
			angle_try_y += 360/DEVIL_CHECK_ANGLES;
		}
		distance_try += 1;
	}
	
	// If none of the locations are valid somehow, just run straight in
	if (closest_dist == 9999999) {
		self.goalentity = self.enemy;
		return;
	}
	
	// Create a goalentity and run to it
	self.target_marker = spawn();
	self.target_marker.classname = "devil_target";
	setorigin(self.target_marker, closest_location);
	self.goalentity = self.target_marker;
}

void(float dist) ai_devil_run = {
	local float player_dist;
	local float target_dist;
	local vector player_delta;
	
	player_delta = self.origin - self.enemy.origin;
	player_delta_z = 0;
	player_dist = vlen(player_delta);
	
	if (self.target_marker) {
		target_dist = vlen(self.origin - self.target_marker.origin);
	}
	else {
		target_dist = 99999;
	}
	
	
	if (player_dist > DEVIL_FOLLOW_RANGE_MAX ||
		player_dist < DEVIL_FOLLOW_RANGE_MIN ||
		target_dist < DEVIL_CLOSEST_DIST) {
		ai_devil_track();
	}
	
	// Run
	ai_run(dist);
};

/*
=============
Grenade Stuff
=============
*/
void() DevilGrenadeExplode =
{
	T_RadiusDamage (self, self.owner, DEVIL_GRENADE_DAMAGE, world, "");
	sound (self, CHAN_VOICE, "weapons/r_exp3.wav", 1, ATTN_NORM);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};

void() DevilGrenadeTouch =
{
	// Devil grenades explode on contact with just about anything
	
	if (other == self.owner)
		return;
	
	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	
	DevilGrenadeExplode();
};

void() DevilFireGrenade =
{
	local entity missile;
	local float v_vertical;
	local float v_horizontal;
	local float dh;
	local float dv;
	local vector delta;
	local float gravity;
	
	// Effects
	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
	
	// Set up the grenade
	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;
	missile.touch = DevilGrenadeTouch;
	
	// Explode automatically after 5 seconds
	missile.nextthink = time + 5;
	missile.think = DevilGrenadeExplode;
	
	// Calculate vertical velocity
	gravity = cvar("sv_gravity");
	dv = self.origin_z - self.enemy.origin_z;
	v_vertical = (400 - (1.6*dv));
	
	// Calculate horizontal velocity
	makevectors (self.angles);
	delta = self.enemy.origin - self.origin;
	delta_z = 0;
	
	dh = vlen(delta);
	v_horizontal = dh/((v_vertical + sqrt((v_vertical*v_vertical) + (2*dv*gravity)))/gravity);
	
	// Write calculated velocity to grenade
	delta = normalize(delta);
	missile.velocity = v_horizontal * delta;
	missile.velocity_z = v_vertical;

	missile.avelocity = '300 300 300';
	missile.angles = vectoangles(missile.velocity);
	
	// Model and origin
	setmodel (missile, "progs/grenade.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, self.origin);
};


//=============================================================================

/*
===========
Melee Stuff
===========
*/
void(float side) devil_ram =
{
	local vector	delta;
	local float 	ldmg;

	if (!self.enemy)
		return;
	if (!CanDamage (self.enemy, self))
		return;

	ai_charge(10);

	delta = self.enemy.origin - self.origin;

	if (vlen(delta) > 100)
		return;
		
	ldmg = (random() + random() + random()) * 4;
	T_Damage (self.enemy, self, self, ldmg);
	
	if (side)
	{
		makevectors (self.angles);
		if (side == 1)
			SpawnMeatSpray (self.origin + v_forward*16, crandom() * 100 * v_right);
		else
			SpawnMeatSpray (self.origin + v_forward*16, side * v_right);
	}
};

void() DevilIdle = {
	if (random() < 0.2)
		sound (self, CHAN_VOICE, "ogre/ogidle.wav", 1, ATTN_IDLE);
}


void() devil_stand1		=[ $stand1,		devil_stand2] {ai_stand();};
void() devil_stand2		=[ $stand2,		devil_stand3] {ai_stand();};
void() devil_stand3		=[ $stand3,		devil_stand4] {ai_stand();};
void() devil_stand4		=[ $stand4,		devil_stand5] {ai_stand();};
void() devil_stand5		=[ $stand5,		devil_stand6] {ai_stand();DevilIdle();};
void() devil_stand6		=[ $stand6,		devil_stand7] {ai_stand();};
void() devil_stand7		=[ $stand7,		devil_stand8] {ai_stand();};
void() devil_stand8		=[ $stand8,		devil_stand9] {ai_stand();};
void() devil_stand9		=[ $stand9,		devil_stand10] {ai_stand();};
void() devil_stand10	=[ $stand10,	devil_stand11] {ai_stand();};
void() devil_stand11	=[ $stand11,	devil_stand12] {ai_stand();};
void() devil_stand12	=[ $stand12,	devil_stand13] {ai_stand();};
void() devil_stand13	=[ $stand13,	devil_stand1] {ai_stand();};

void() devil_walk1	=[ $walk1,	devil_walk2		] {ai_walk(0);};
void() devil_walk2	=[ $walk2,	devil_walk3		] {ai_walk(2);};
void() devil_walk3	=[ $walk3,	devil_walk4		] {ai_walk(5);DevilIdle();};
void() devil_walk4	=[ $walk4,	devil_walk5		] {ai_walk(6);};
void() devil_walk5	=[ $walk5,	devil_walk6		] {ai_walk(5);};
void() devil_walk6	=[ $walk6,	devil_walk7		] {ai_walk(3);};
void() devil_walk7	=[ $walk7,	devil_walk8		] {ai_walk(1);};
void() devil_walk8	=[ $walk8,	devil_walk9		] {ai_walk(1);};
void() devil_walk9	=[ $walk9,	devil_walk10	] {ai_walk(0);};
void() devil_walk10	=[ $walk10,	devil_walk11	] {ai_walk(2);};
void() devil_walk11	=[ $walk11,	devil_walk12	] {ai_walk(5);};
void() devil_walk12	=[ $walk12,	devil_walk13	] {ai_walk(6);};
void() devil_walk13	=[ $walk13,	devil_walk14	] {ai_walk(5);};
void() devil_walk14	=[ $walk14,	devil_walk15	] {ai_walk(3);};
void() devil_walk15	=[ $walk15,	devil_walk16	] {ai_walk(1);};
void() devil_walk16	=[ $walk16,	devil_walk1		] {ai_walk(1);};

void() devil_run1	=[ $run1,	devil_run2	] {ai_devil_run(8);self.nextthink=time+0.05;};
void() devil_run2	=[ $run2,	devil_run3	] {ai_devil_run(15);};
void() devil_run3	=[ $run3,	devil_run4	] {ai_devil_run(30);DevilIdle();};
void() devil_run4	=[ $run4,	devil_run5	] {ai_devil_run(30);};
void() devil_run5	=[ $run5,	devil_run6	] {ai_devil_run(8);self.nextthink=time+0.05;};
void() devil_run6	=[ $run6,	devil_run7	] {ai_devil_run(15);};
void() devil_run7	=[ $run7,	devil_run8	] {ai_devil_run(30);};
void() devil_run8	=[ $run8,	devil_run1	] {ai_devil_run(30);};

void() devil_swing1	=[ $swing1,	devil_swing2	]
{
	ai_charge(11);
	sound (self, CHAN_WEAPON, "ogre/ogsawatk.wav", 1, ATTN_NORM);
};
void() devil_swing2	=[ $swing2,		devil_swing3		] {ai_charge(1);};
void() devil_swing3	=[ $swing3,		devil_swing4		] {ai_charge(4);};
void() devil_swing4	=[ $swing4,		devil_swing5		] {ai_charge(13);};
void() devil_swing5	=[ $swing5,		devil_swing6		] {ai_charge(9);devil_ram(0);self.angles_y=self.angles_y+random()*25;};
void() devil_swing6	=[ $swing6,		devil_swing7		] {devil_ram(200);self.angles_y=self.angles_y+random()*25;};
void() devil_swing7	=[ $swing7,		devil_swing8		] {devil_ram(0);self.angles_y=self.angles_y+random()*25;};
void() devil_swing8	=[ $swing8,		devil_swing9		] {devil_ram(0);self.angles_y=self.angles_y+random()*25;};
void() devil_swing9	=[ $swing9,		devil_swing10	] {devil_ram(0);self.angles_y=self.angles_y+random()*25;};
void() devil_swing10	=[ $swing10,	devil_swing11	] {devil_ram(-200);self.angles_y=self.angles_y+random()*25;};
void() devil_swing11	=[ $swing11,	devil_swing12	] {devil_ram(0);self.angles_y=self.angles_y+random()*25;};
void() devil_swing12	=[ $swing12,	devil_swing13	] {ai_charge(3);};
void() devil_swing13	=[ $swing13,	devil_swing14	] {ai_charge(8);};
void() devil_swing14	=[ $swing14,	devil_run1		] {ai_charge(9);};

void() devil_smash1	=[ $smash1,	devil_smash2	]
{
	ai_charge(6);
	sound (self, CHAN_WEAPON, "ogre/ogsawatk.wav", 1, ATTN_NORM);
};
void() devil_smash2	=[ $smash2,		devil_smash3		] {ai_charge(0);};
void() devil_smash3	=[ $smash3,		devil_smash4		] {ai_charge(0);};
void() devil_smash4	=[ $smash4,		devil_smash5		] {ai_charge(1);};
void() devil_smash5	=[ $smash5,		devil_smash6		] {ai_charge(4);};
void() devil_smash6	=[ $smash6,		devil_smash7		] {ai_charge(4);devil_ram(0);};
void() devil_smash7	=[ $smash7,		devil_smash8		] {ai_charge(4);devil_ram(0);};
void() devil_smash8	=[ $smash8,		devil_smash9		] {ai_charge(10);devil_ram(0);};
void() devil_smash9	=[ $smash9,		devil_smash10	] {ai_charge(13);devil_ram(0);};
void() devil_smash10	=[ $smash10,	devil_smash11	] {devil_ram(1);};
void() devil_smash11	=[ $smash11,	devil_smash12	]
{
	ai_charge(2);
	devil_ram(0);
	// slight variation
	self.nextthink = self.nextthink + random()*0.2;
};
void() devil_smash12	=[ $smash12,	devil_smash13	] {ai_charge(0);};
void() devil_smash13	=[ $smash13,	devil_smash14	] {ai_charge(4);};
void() devil_smash14	=[ $smash14,	devil_run1		] {ai_charge(12);};

void() devil_throw1		=[ $throw1,	devil_throw2	] {};
void() devil_throw2		=[ $throw2,	devil_throw3	] {};
void() devil_throw3		=[ $throw3,	devil_throw4	] {};
void() devil_throw4		=[ $throw4,	devil_throw5	] {};
void() devil_throw5		=[ $throw5,	devil_throw6	] {};
void() devil_throw6		=[ $throw6,	devil_throw7	] {};
void() devil_throw7		=[ $throw7,	devil_throw8	] {DevilFireGrenade();};
void() devil_throw8		=[ $throw8,	devil_throw9	] {};
void() devil_throw9		=[ $throw9,	devil_throw10	] {};
void() devil_throw10	=[ $throw10, devil_throw11	] {};
void() devil_throw11	=[ $throw11, devil_throw12	] {};
void() devil_throw12	=[ $throw12, devil_throw13	] {};
void() devil_throw13	=[ $throw13, devil_run1		] {};

void() devil_pain1	=[ $pain1,	devil_pain2	] {};
void() devil_pain2	=[ $pain2,	devil_pain3	] {};
void() devil_pain3	=[ $pain3,	devil_pain4	] {};
void() devil_pain4	=[ $pain4,	devil_pain5	] {};
void() devil_pain5	=[ $pain5,	devil_run1	] {};


void() devil_painb1	=[ $painb1,	devil_painb2	] {};
void() devil_painb2	=[ $painb2,	devil_painb3	] {};
void() devil_painb3	=[ $painb3,	devil_run1	] {};


void() devil_painc1	=[ $painc1,	devil_painc2	] {};
void() devil_painc2	=[ $painc2,	devil_painc3	] {};
void() devil_painc3	=[ $painc3,	devil_painc4	] {};
void() devil_painc4	=[ $painc4,	devil_painc5	] {};
void() devil_painc5	=[ $painc5,	devil_painc6	] {};
void() devil_painc6	=[ $painc6,	devil_run1	] {};


void() devil_paind1	=[ $paind1,		devil_paind2		] {};
void() devil_paind2	=[ $paind2,		devil_paind3		] {ai_pain(10);};
void() devil_paind3	=[ $paind3,		devil_paind4		] {ai_pain(9);};
void() devil_paind4	=[ $paind4,		devil_paind5		] {ai_pain(4);};
void() devil_paind5	=[ $paind5,		devil_paind6		] {};
void() devil_paind6	=[ $paind6,		devil_paind7		] {};
void() devil_paind7	=[ $paind7,		devil_paind8		] {};
void() devil_paind8	=[ $paind8,		devil_paind9		] {};
void() devil_paind9	=[ $paind9,		devil_paind10	] {};
void() devil_paind10	=[ $paind10,	devil_paind11	] {};
void() devil_paind11	=[ $paind11,	devil_paind12	] {};
void() devil_paind12	=[ $paind12,	devil_paind13	] {};
void() devil_paind13	=[ $paind13,	devil_paind14	] {};
void() devil_paind14	=[ $paind14,	devil_paind15	] {};
void() devil_paind15	=[ $paind15,	devil_paind16	] {};
void() devil_paind16	=[ $paind16,	devil_run1		] {};

void() devil_paine1	=[ $paine1,		devil_paine2		] {};
void() devil_paine2	=[ $paine2,		devil_paine3		] {ai_pain(10);};
void() devil_paine3	=[ $paine3,		devil_paine4		] {ai_pain(9);};
void() devil_paine4	=[ $paine4,		devil_paine5		] {ai_pain(4);};
void() devil_paine5	=[ $paine5,		devil_paine6		] {};
void() devil_paine6	=[ $paine6,		devil_paine7		] {};
void() devil_paine7	=[ $paine7,		devil_paine8		] {};
void() devil_paine8	=[ $paine8,		devil_paine9		] {};
void() devil_paine9	=[ $paine9,		devil_paine10	] {};
void() devil_paine10	=[ $paine10,	devil_paine11	] {};
void() devil_paine11	=[ $paine11,	devil_paine12	] {};
void() devil_paine12	=[ $paine12,	devil_paine13	] {};
void() devil_paine13	=[ $paine13,	devil_paine14	] {};
void() devil_paine14	=[ $paine14,	devil_paine15	] {};
void() devil_paine15	=[ $paine15,	devil_run1		] {};


void(entity attacker, float damage)	devil_pain =
{
	local float	r;

// don't make multiple pain sounds right after each other
	if (self.pain_finished > time)
		return;

	sound (self, CHAN_VOICE, "ogre/ogpain1.wav", 1, ATTN_NORM);		

	r = random();
	
	if (r < 0.25)
	{
		devil_pain1 ();
		self.pain_finished = time + 1;
	}
	else if (r < 0.5)
	{
		devil_painb1 ();
		self.pain_finished = time + 1;
	}
	else if (r < 0.75)
	{
		devil_painc1 ();
		self.pain_finished = time + 1;
	}
	else if (r < 0.88)
	{
		devil_paind1 ();
		self.pain_finished = time + 2;
	}
	else
	{
		devil_paine1 ();
		self.pain_finished = time + 2;
	}
};

void() devil_die1	=[ $death1,	devil_die2	] {};
void() devil_die2	=[ $death2,	devil_die3	] {};
void() devil_die3	=[ $death3,	devil_die4	]
{
	self.solid = SOLID_NOT;
};
void() devil_die4	=[ $death4,		devil_die5	] {};
void() devil_die5	=[ $death5,		devil_die6	] {};
void() devil_die6	=[ $death6,		devil_die7	] {};
void() devil_die7	=[ $death7,		devil_die8	] {};
void() devil_die8	=[ $death8,		devil_die9	] {};
void() devil_die9	=[ $death9,		devil_die10	] {};
void() devil_die10	=[ $death10,	devil_die11	] {};
void() devil_die11	=[ $death11,	devil_die12	] {};
void() devil_die12	=[ $death12,	devil_die13	] {};
void() devil_die13	=[ $death13,	devil_die14	] {};
void() devil_die14	=[ $death14,	devil_die14	] {};

void() devil_bdie1	=[ $bdeath1,	devil_bdie2	] {};
void() devil_bdie2	=[ $bdeath2,	devil_bdie3	] {ai_forward(5);};
void() devil_bdie3	=[ $bdeath3,	devil_bdie4	]
{
	self.solid = SOLID_NOT;
};
void() devil_bdie4	=[ $bdeath4,	devil_bdie5	] {ai_forward(1);};
void() devil_bdie5	=[ $bdeath5,	devil_bdie6	] {ai_forward(3);};
void() devil_bdie6	=[ $bdeath6,	devil_bdie7	] {ai_forward(7);};
void() devil_bdie7	=[ $bdeath7,	devil_bdie8	] {ai_forward(25);};
void() devil_bdie8	=[ $bdeath8,	devil_bdie9	] {};
void() devil_bdie9	=[ $bdeath9,	devil_bdie10	] {};
void() devil_bdie10	=[ $bdeath10,	devil_bdie10	] {};

void() devil_die =
{
// check for gib
	if (self.health < -80)
	{
		sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
		ThrowHead ("progs/h_ogre.mdl", self.health);
		ThrowGib ("progs/gib3.mdl", self.health);
		ThrowGib ("progs/gib3.mdl", self.health);
		ThrowGib ("progs/gib3.mdl", self.health);
		return;
	}

	sound (self, CHAN_VOICE, "ogre/ogdth.wav", 1, ATTN_NORM);
	
	if (random() < 0.5)
		devil_die1 ();
	else
		devil_bdie1 ();
};

void() devil_melee =
{
	if (random() > 0.5)
		devil_smash1 ();
	else
		devil_swing1 ();
};

float(float height) DevilCheckSight = {
	local vector	spot1, spot2;
	local entity	targ;
	local vector	delta;
	
	delta_z = height;
	
	targ = self.enemy;
	
	spot1 = self.origin + self.view_ofs + delta;
	spot2 = targ.origin + targ.view_ofs;
	
	// Make sure the projectile will be able to clear the lip
	if (height > 100) {
		if (vlen(self.origin - self.enemy.origin) > 200) {
			return FALSE;
		}
	}

	traceline (spot1, spot2, FALSE, self);

	if (trace_inopen && trace_inwater)
		return FALSE;			// sight line crossed contents

	if (trace_ent != targ)
	{
		return FALSE;	// don't have a clear shot
	}
	
	return TRUE;
}

float() DevilCheckAttack =
{
	local float		chance;
	
	if (enemy_range == RANGE_MELEE)
	{
		if (CanDamage (self.enemy, self))
		{
			self.attack_state = AS_MELEE;
			return TRUE;
		}
	}

	if (time < self.attack_finished)
		return FALSE;
	
// see if any entities are in the way of the shot
	if ((!DevilCheckSight(0)) && 
		(!DevilCheckSight(64)) &&
		(!DevilCheckSight(128))) {
		return FALSE;
	}
	
// missile attack
	if (time < self.attack_finished)
		return FALSE;
		
	if (enemy_range == RANGE_FAR)
		return FALSE;
		
	else if (enemy_range == RANGE_NEAR)
		chance = 0.10;
	else if (enemy_range == RANGE_MID)
		chance = 0.05;
	else
		chance = 0;

	self.attack_state = AS_MISSILE;
	SUB_AttackFinished (1 + 2*random());
	return TRUE;
};


void() monster_devil =
{
	if (deathmatch)
	{
		remove(self);
		return;
	}
	precache_model ("progs/devil.mdl");
	precache_model ("progs/h_ogre.mdl");
	precache_model ("progs/grenade.mdl");

	precache_sound ("ogre/ogdth.wav");
	precache_sound ("ogre/ogidle.wav");
	precache_sound ("ogre/ogidle2.wav");
	precache_sound ("ogre/ogpain1.wav");
	precache_sound ("ogre/ogsawatk.wav");
	precache_sound ("ogre/ogwake.wav");

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/devil.mdl");

	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.health = 250;

	self.th_stand = devil_stand1;
	self.th_walk = devil_walk1;
	self.th_run = devil_run1;
	self.th_die = devil_die;
	self.th_melee = devil_melee;
	self.th_missile = devil_throw1;
	self.th_pain = devil_pain;
	
	walkmonster_start();
};
