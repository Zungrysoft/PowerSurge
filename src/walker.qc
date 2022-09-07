/*
==============================================================================
Walker
==============================================================================
*/

// Balancing Parameters
#define WALKER_PAIN_THRESHOLD 200
#define WALKER_GRENADE_DAMAGE 30
#define WALKER_MELEE_ANGLE 85

#define melee_direction count

$frame stand1 stand2 stand3 stand4 stand5 stand6 stand7 stand8 stand9 stand10
$frame stand11 stand12 stand13 stand14 stand15 stand16 stand17 stand18 stand19

$frame walk1 walk2 walk3 walk4 walk5 walk6 walk7 walk8 walk9 walk10
$frame walk11 walk12 walk13 walk14 walk15 walk16 walk17 walk18
$frame walklo

$frame shoot1 shoot2 shoot3 shoot4 shoot5 shoot6 shoot7 shoot8 shoot9 shoot10
$frame shoot11 shoot12 shoot13 shoot14

$frame death1 death2 death3 death4 death5 death6 death7 death8 death9 death10
$frame death11 death12 death13

//=============================================================================

/*
================
Projectile Stuff
================
*/

void() WalkerGrenadeShatter = {
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
}

void() WalkerGrenadeExplode = {
	T_RadiusDamage (self, self.owner, WALKER_GRENADE_DAMAGE, world, "");
	WalkerGrenadeShatter();
};

void(vector org, vector vec) LaunchWalkerPlasma = {
	sound (self, CHAN_WEAPON, "enforcer/gunfire.wav", 1, ATTN_NORM);
	
	vec = normalize(vec);
	
	newmis = spawn();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLY;
	newmis.solid = SOLID_BBOX;
	newmis.effects = EF_DIMLIGHT;

	setmodel (newmis, "progs/laser2.mdl");
	newmis.classname = "laser";
	setsize (newmis, '0 0 0', '0 0 0');		

	setorigin (newmis, org);

	newmis.velocity = vec * 1000;
	newmis.angles = vectoangles(newmis.velocity);

	newmis.touch = Plasma_Touch;
	newmis.nextthink = time + .1;
	newmis.think = laser_particle;
};

void() WalkerGrenadeThink = {
	self.nextthink = time + 0.05 + (random() * 0.1);
	self.think = WalkerGrenadeThink;
	
	// Shoot the player
	if (time - self.count > 0.2 && self.enemy.health > 0) {
		LaunchWalkerPlasma(self.origin, self.enemy.origin - self.origin);
	}
	
	// Auto-explode after five seconds
	if (time - self.count > 5) {
		WalkerGrenadeExplode();
	}
	
	// TODO: Add Walker Grenade Stuff
};

void(entity attacker, float damage) WalkerGrenadePain = {}

void() WalkerGrenadeDeath = {
	WalkerGrenadeShatter();
}

void() WalkerGrenadeTouch = {
	// Elastic bouncing
	if (other == world) {
		// Bounce if it hit the floor
		if (pointcontents(self.origin + '0 0 -17') == CONTENT_SOLID) {
			self.velocity_z = -700;
		}
		// Break if it hit a wall or ceiling
		else {
			WalkerGrenadeExplode();
		}
		
		return;
	}
	
	if (other == self.owner)
		return;
	
	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing
	
	// Explode on contact with players
	if (other.takedamage == DAMAGE_AIM) {
		T_Damage(other, self, self.owner, 30);
		WalkerGrenadeExplode();
		return;
	}
	
	// Disappear on contact with sky
	if (pointcontents(self.origin) == CONTENT_SKY) {
		remove(self);
		return;
	}
};

void() WalkerFireGrenade = {
	local entity missile;
	local vector ang;
	local vector shoot_spot;
	
	// Determine where the dynamite source and destination
	shoot_spot = self.origin + '0 0 44';
	
	// Set up the grenade
	missile = spawn ();
	missile.classname = "walker_grenade";
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;
	missile.touch = WalkerGrenadeTouch;
	missile.count = time;
	missile.enemy = self.enemy;
	
	// Animation
	missile.nextthink = time + 0.1;
	missile.think = WalkerGrenadeThink;
	
	// Calculate velocity
	missile.velocity = self.enemy.origin - self.origin;
	missile.velocity_z = 0;
	if (self.enemy.classname != "player") {
		ang = vectoangles(missile.velocity);
		ang_y += WALKER_MELEE_ANGLE * self.melee_direction;
		makevectors(ang);
		missile.velocity = v_forward;
	}
	missile.velocity = normalize(missile.velocity);
	missile.velocity = missile.velocity * 300;
	missile.velocity_z = 200;
	
	// Health and damage
	missile.health = 80;
	missile.takedamage = DAMAGE_YES;
	missile.th_pain = WalkerGrenadePain;
	missile.th_die = WalkerGrenadeDeath;
	
	// Model and origin
	setmodel (missile, "progs/beamball.mdl");
	setsize (missile, '-16 -16 -16', '16 16 16');
	setorigin (missile, shoot_spot);
	
	// Sound effect
	//sound (self, CHAN_WEAPON, "walker/shoot.wav", 1, ATTN_NORM);
};

//=============================================================================

void() ai_face_walker = {
	if (self.enemy.classname != "player") {
		ai_face_side(WALKER_MELEE_ANGLE * self.melee_direction);
	}
	else {
		ai_face();
	}
}

void() WalkerIdle = {
	// TODO: Idle Creaking Sounds
}


void() walker_stand1	=[ $stand1,		walker_stand2] {ai_stand();};
void() walker_stand2	=[ $stand2,		walker_stand3] {ai_stand();};
void() walker_stand3	=[ $stand3,		walker_stand4] {ai_stand();};
void() walker_stand4	=[ $stand4,		walker_stand5] {ai_stand();};
void() walker_stand5	=[ $stand5,		walker_stand6] {ai_stand();WalkerIdle();};
void() walker_stand6	=[ $stand6,		walker_stand7] {ai_stand();};
void() walker_stand7	=[ $stand7,		walker_stand8] {ai_stand();};
void() walker_stand8	=[ $stand8,		walker_stand9] {ai_stand();};
void() walker_stand9	=[ $stand9,		walker_stand10] {ai_stand();};
void() walker_stand10	=[ $stand10,	walker_stand11] {ai_stand();};
void() walker_stand11	=[ $stand11,	walker_stand12] {ai_stand();};
void() walker_stand12	=[ $stand12,	walker_stand13] {ai_stand();};
void() walker_stand13	=[ $stand13,	walker_stand14] {ai_stand();};
void() walker_stand14	=[ $stand14,	walker_stand15] {ai_stand();};
void() walker_stand15	=[ $stand15,	walker_stand16] {ai_stand();};
void() walker_stand16	=[ $stand16,	walker_stand17] {ai_stand();};
void() walker_stand17	=[ $stand17,	walker_stand18] {ai_stand();};
void() walker_stand18	=[ $stand18,	walker_stand19] {ai_stand();};
void() walker_stand19	=[ $stand19,	walker_stand1] {ai_stand();};

void() walker_walk1		=[ $walk1,	walker_walk2	] {ai_walk(1);};
void() walker_walk2		=[ $walk2,	walker_walk3	] {ai_walk(4);};
void() walker_walk3		=[ $walk3,	walker_walk4	] {ai_walk(6);WalkerIdle();};
void() walker_walk4		=[ $walk4,	walker_walk5	] {ai_walk(6);};
void() walker_walk5		=[ $walk5,	walker_walk6	] {ai_walk(6);};
void() walker_walk6		=[ $walk6,	walker_walk7	] {ai_walk(2);};
void() walker_walk7		=[ $walk7,	walker_walk8	] {ai_walk(0);};
void() walker_walk8		=[ $walk8,	walker_walk9	] {ai_walk(0);};
void() walker_walk9		=[ $walk9,	walker_walk10	] {ai_walk(0);};
void() walker_walk10	=[ $walk10,	walker_walk11	] {ai_walk(1);};
void() walker_walk11	=[ $walk11,	walker_walk12	] {ai_walk(4);};
void() walker_walk12	=[ $walk12,	walker_walk13	] {ai_walk(6);};
void() walker_walk13	=[ $walk13,	walker_walk14	] {ai_walk(6);};
void() walker_walk14	=[ $walk14,	walker_walk15	] {ai_walk(6);};
void() walker_walk15	=[ $walk15,	walker_walk16	] {ai_walk(2);};
void() walker_walk16	=[ $walk16,	walker_walk17	] {ai_walk(0);};
void() walker_walk17	=[ $walk17,	walker_walk18	] {ai_walk(0);};
void() walker_walk18	=[ $walk18,	walker_walk1	] {ai_walk(0);};

void() walker_run1		=[ $walk1,	walker_run2		] {ai_run(1);};
void() walker_run2		=[ $walk2,	walker_run3		] {ai_run(4);};
void() walker_run3		=[ $walk3,	walker_run4		] {ai_run(6);WalkerIdle();};
void() walker_run4		=[ $walk4,	walker_run5		] {ai_run(6);};
void() walker_run5		=[ $walk5,	walker_run6		] {ai_run(6);};
void() walker_run6		=[ $walk6,	walker_run7		] {ai_run(2);};
void() walker_run7		=[ $walk7,	walker_run8		] {ai_run(0);};
void() walker_run8		=[ $walk8,	walker_run9		] {ai_run(0);};
void() walker_run9		=[ $walk9,	walker_run10	] {ai_run(0);};
void() walker_run10		=[ $walk10,	walker_run11	] {ai_run(1);};
void() walker_run11		=[ $walk11,	walker_run12	] {ai_run(4);};
void() walker_run12		=[ $walk12,	walker_run13	] {ai_run(6);};
void() walker_run13		=[ $walk13,	walker_run14	] {ai_run(6);};
void() walker_run14		=[ $walk14,	walker_run15	] {ai_run(6);};
void() walker_run15		=[ $walk15,	walker_run16	] {ai_run(2);};
void() walker_run16		=[ $walk16,	walker_run17	] {ai_run(0);};
void() walker_run17		=[ $walk17,	walker_run18	] {ai_run(0);};
void() walker_run18		=[ $walk18,	walker_run1		] {ai_run(0);};

void() walker_shoot1	=[ $shoot1,	walker_shoot2	] {ai_face_walker();};
void() walker_shoot2	=[ $shoot2,	walker_shoot3	] {ai_face_walker();};
void() walker_shoot3	=[ $shoot3,	walker_shoot4	] {ai_face_walker();};
void() walker_shoot4	=[ $shoot4,	walker_shoot5	] {ai_face_walker();self.nextthink=time+0.05;};
void() walker_shoot5	=[ $shoot5,	walker_shoot6	] {ai_face_walker();WalkerFireGrenade();self.nextthink=time+0.05;};
void() walker_shoot6	=[ $shoot6,	walker_shoot7	] {};
void() walker_shoot7	=[ $shoot7,	walker_shoot8	] {};
void() walker_shoot8	=[ $shoot8,	walker_shoot9	] {};
void() walker_shoot9	=[ $shoot9, walker_shoot10	] {};
void() walker_shoot10	=[ $shoot10, walker_shoot11	] {};
void() walker_shoot11	=[ $shoot11, walker_shoot12	] {};
void() walker_shoot12	=[ $shoot12, walker_shoot13	] {};
void() walker_shoot13	=[ $shoot13, walker_shoot14	] {};
void() walker_shoot14	=[ $shoot14, walker_run4	] {};

void(entity attacker, float damage)	walker_pain = {
	// Sound effect
	if (damage > 80) {
		//sound (self, CHAN_VOICE, "walker/pain.wav", 1, ATTN_NORM);		
	}
	else if (damage > 30) {
		//sound (self, CHAN_VOICE, "walker/pain.wav", 1, ATTN_NORM);		
	}
	else {
		//sound (self, CHAN_VOICE, "walker/pain.wav", 1, ATTN_NORM);		
	}
};

#define WALKER_EXPLOSION_HORIZONTAL 120
#define WALKER_EXPLOSION_VERTICAL 110
#define WALKER_EXPLOSION_VERTICAL_OFFSET -20
#define WALKER_EXPLOSION_COUNT 10
void() WalkerExplode = {
	local entity exp;
	local vector origin_point;
	local float c = WALKER_EXPLOSION_COUNT;
	
	// Explosion sound
	sound (self, CHAN_BODY, "painelem/explode.wav", 1, ATTN_NORM);
	
	// Explosions
	while (c > 0) {
		c -= 1;
		
		exp = spawn();
		exp.movetype = MOVETYPE_NONE;
		exp.velocity = '0 0 0';
		exp.touch = SUB_Null;
		setmodel (exp, "progs/s_explod.spr");
		exp.solid = SOLID_NOT;
		exp.nextthink = time;
		exp.think = s_explode1;
		
		// Determine origin
		origin_point = self.origin;
		origin_point_x += (random() * EXPLOSION_HORIZONTAL) - (EXPLOSION_HORIZONTAL/2);
		origin_point_y += (random() * EXPLOSION_HORIZONTAL) - (EXPLOSION_HORIZONTAL/2);
		origin_point_z += (random() * EXPLOSION_VERTICAL) + EXPLOSION_VERTICAL_OFFSET;
		
		setorigin(exp, origin_point);
	}
	
	remove(self);
}

void() walker_death1	=[ $death1,		walker_death2	] {};
void() walker_death2	=[ $death2,		walker_death3	] {};
void() walker_death3	=[ $death3,		walker_death4	] {self.solid = SOLID_NOT;};
void() walker_death4	=[ $death4,		walker_death5	] {};
void() walker_death5	=[ $death5,		walker_death6	] {};
void() walker_death6	=[ $death6,		walker_death7	] {};
void() walker_death7	=[ $death7,		walker_death8	] {};
void() walker_death8	=[ $death8,		walker_death9	] {};
void() walker_death9	=[ $death9,		walker_death10	] {};
void() walker_death10	=[ $death10,	walker_death11	] {};
void() walker_death11	=[ $death11,	walker_death12	] {};
void() walker_death12	=[ $death12,	walker_death13	] {};
void() walker_death13	=[ $death13,	walker_death14	] {};
void() walker_death14	=[ $death13,	walker_death15	] {};
void() walker_death15	=[ $death13,	walker_death16	] {};
void() walker_death16	=[ $death13,	walker_death16	] {WalkerExplode();};

void() walker_die = {
	walker_death1 ();
};

float() WalkerCheckAttack = {
	if (time < self.attack_finished)
		return FALSE;
	
	// Missile attack
	if (time < self.attack_finished)
		return FALSE;
		
	if (enemy_range == RANGE_FAR)
		return FALSE;

	self.attack_state = AS_MISSILE;
	SUB_AttackFinished (3 + 2*random());
	self.melee_direction = 1;
	if (random() < 0.5) {
		self.melee_direction = -1;
	}
	return TRUE;
};


void() monster_walker = {
	if (deathmatch)
	{
		remove(self);
		return;
	}
	precache_model ("progs/walker.mdl");
	precache_model ("progs/beamball.mdl");
	precache_model ("progs/laser2.mdl");
	precache_model ("progs/burst_plasma.spr");
	
	precache_sound ("enforcer/gunfire.wav");
	precache_sound ("enforcer/gunstop.wav");
	precache_sound ("painelem/explode.wav");

	/*precache_sound ("walker/death.wav");
	precache_sound ("walker/idle.wav");
	precache_sound ("walker/pain.wav");
	precache_sound ("walker/ram.wav");
	precache_sound ("walker/sight.wav");
	precache_sound ("walker/shoot.wav");
	precache_sound ("walker/rustle.wav");
	precache_sound ("walker/swipe.wav");*/

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/walker.mdl");

	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.health = 1000;
	self.mass = 3.5;

	self.th_stand = walker_stand1;
	self.th_walk = walker_walk1;
	self.th_run = walker_run1;
	self.th_die = walker_die;
	self.th_melee = walker_shoot1;
	self.th_missile = walker_shoot1;
	self.th_pain = walker_pain;
	
	walkmonster_start();
};
