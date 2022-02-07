/*
==============================================================================
Devil
==============================================================================
*/

// Balancing Parameters
#define DEVIL_MELEE_DAMAGE 58
#define DEVIL_MELEE_RANGE 70
#define DEVIL_RAM_FORCE 550
#define DEVIL_GRENADE_DAMAGE 45
#define DEVIL_MAX_THROW_VELOCITY 1100
#define DEVIL_PAIN_THRESHOLD 85
#define DEVIL_FOLLOW_RANGE_MAX 512
#define DEVIL_FOLLOW_RANGE_MIN 256
#define DEVIL_CLOSEST_DIST 64
#define DEVIL_CHECK_ANGLES 24
#define DEVIL_CHECK_DISTANCES 3
#define DEVIL_SIM_STEP 0.08
#define DEVIL_SIM_ITER 30
#define DEVIL_SIM_COMPENSATE '0 0 32'

#define target_marker trigger_field
#define super_armor count
#define chosen_angle volume

$frame stand1 stand2 stand3 stand4 stand5 stand6 stand7 stand8 stand9
$frame stand10 stand11 stand12 stand13 standlo

$frame walk1 walk2 walk3 walk4 walk5 walk6 walk7 walk8 walk9
$frame walk10 walk11 walk12 walk13 walk14 walk15 walk16 walklo

$frame run1 run2 run3 run4 run5 run6 run7 run8 runlo

$frame throw1 throw2 throw3 throw4 throw5 throw6 throw7 throw8 throw9
$frame throw10 throw11 throw12 throw13 throw14 throwlo

$frame rama1 rama2 rama3 rama4 rama5 rama6 rama7 rama8 rama9
$frame rama10 rama11 ramalo

$frame ramb1 ramb2 ramb3 ramb4 ramb5 ramb6 ramb7 ramb8 ramb9
$frame ramb10 ramb11 ramblo

$frame pain1 pain2 pain3 pain4 pain5 pain6 painlo

$frame painb1 painb2 painb3 painb4 painb5 painb6 painb7 painblo

$frame painc1 painc2 painc3 painc4 painc5 painc6 painc7 painc8 painc9 painc10
$frame painc11 painc12 painc13 painc14 painc15 painc16 painclo

$frame death1 death2 death3 death4 death5 death6
$frame death7 death8 death9 death10

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
void() DevilGrenadeThink =
{
	self.nextthink = time + 0.05 + (random() * 0.1);
	self.think = DevilGrenadeThink;
	
	self.frame = (self.frame + 1) % 5;
};

void() DevilGrenadeExplode =
{
	T_RadiusDamage (self, self.owner, DEVIL_GRENADE_DAMAGE, world, "");

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

// Calculates the vertical velocity based on height difference
float(vector throw_spot, vector target_spot) DevilCalculateVertical {
	local float gravity;
	local float dv;
	
	gravity = cvar("sv_gravity");
	
	dv = throw_spot_z - target_spot_z;
	return 400 - (1.6*dv);
}

// Calculates horizontal velocity based on vertical velocity
float(vector throw_spot, vector target_spot, float v_vertical) DevilCalculateHorizontal {
	local float gravity;
	local vector delta;
	local float dh;
	local float dv;
	
	makevectors (self.angles);
	gravity = cvar("sv_gravity");
	dv = throw_spot_z - target_spot_z;
	delta = target_spot - throw_spot;
	delta_z = 0;
	
	dh = vlen(delta);
	return dh/((v_vertical + sqrt((v_vertical*v_vertical) + (2*dv*gravity)))/gravity);
}

// Converts from horizontal and vertical velocity into an actual vector
vector(vector throw_spot, vector target_spot, float v_vertical, float v_horizontal) DevilConvertVelocity {
	local vector delta;
	local vector result;
	
	delta = target_spot - throw_spot;
	delta_z = 0;
	delta = normalize(delta);
	
	result = v_horizontal * delta;
	result_z = v_vertical;
	return result;
}

// Simulates a throw for the dynamite to make sure it won't hit geo or another target
// Returns the resulting vertical velocity on target hit
// Returns -1 on target miss
float(float v_extra) DevilSimulateRun = {
	local float counter;
	local float gravity;
	local vector cur;
	local vector next;
	local float v_vertical;
	local float v_horizontal;
	local vector sim_velocity;
	local float checked_ceiling;
	
	local vector throw_spot;
	local vector target_spot;
	
	// Determine where the dynamite source and destination
	// DEVIL_SIM_COMPENSATE Helps the dynamite clear tall walls
	// The sim may clip corners, so this makes the sim test a bit lower
	throw_spot = self.origin + '0 0 16' - DEVIL_SIM_COMPENSATE;
	target_spot = self.enemy.origin + '0 0 -20' - DEVIL_SIM_COMPENSATE;
	
	// Get world gravity value
	gravity = cvar("sv_gravity");

	// Calculate the velocity we're testing here
	v_vertical = v_extra + DevilCalculateVertical(throw_spot, target_spot);
	v_horizontal = DevilCalculateHorizontal(throw_spot, target_spot, v_vertical);
	
	// Calculate starting velocity vector
	sim_velocity = DevilConvertVelocity(throw_spot, target_spot, v_vertical, v_horizontal);
	
	// Make sure the vertical velocity didn't end up negative
	if (sim_velocity_z <= 10) {
		return -1;
	}
	
	// This guy can only throw so far
	if (vlen(sim_velocity) > DEVIL_MAX_THROW_VELOCITY) {
		return -1;
	}
	
	// Step through the simulation
	cur = throw_spot;
	counter = DEVIL_SIM_ITER;
	while (counter > 0) {
		// Step
		next = cur + (sim_velocity * DEVIL_SIM_STEP);
		
		// Debug
		//particle(next, '0 0 0', 250, 9);
		
		// Do the trace
		traceline (cur, next, FALSE, self);
		
		// Check if it hit the target
		if (trace_ent == self.enemy) {
			return v_vertical;
		}
		
		//Check for collision with something else
		if (trace_fraction < 1 && trace_ent != self.enemy) {
			return -1;
		}
		
		// At the apex of the throw, also check up a little bit
		// Prevents slamming into ceilings
		if (!checked_ceiling && sim_velocity_z < 200) {
			checked_ceiling = TRUE;
			traceline (cur, cur + (DEVIL_SIM_COMPENSATE * 1.5), FALSE, self);
			if (trace_fraction < 1 && trace_ent != self.enemy) {
				return -1;
			}
		}
		
		// Acceleration due to gravity
		sim_velocity_z -= gravity * DEVIL_SIM_STEP;
		
		// Increment
		cur = next;
		counter = counter - 1;
	}
	
	// Didn't hit anything
	return v_vertical;
}

// Figures out what angle (if any) the devil should throw its dynamite
// Returns the resulting vertical velocity of the successful throw on target hit
// Returns -1 if it did not find any angle with a target hit
float() DevilSimulateThrow = {
	local float sim_result;
	local float angles_try[10] = {0, 64, 128, 192, 256, 384, 512, -512, -64, -196};
	for (float i = 0; i < 10; i ++) {
		sim_result = DevilSimulateRun(angles_try[i]);
		if (sim_result != -1) {
			return sim_result;
		}
	}
	
	return -1;
}

void() DevilFireGrenade =
{
	local entity missile;
	local float v_vertical;
	local float v_horizontal;
	
	local vector throw_spot;
	local vector target_spot;
	
	// Determine where the dynamite source and destination
	throw_spot = self.origin + '0 0 16';
	target_spot = self.enemy.origin + '0 0 -20';
	
	// Simulate the velocity again since the player has probably moved since we checked
	v_vertical = DevilSimulateThrow();
	
	// If there is no longer a valid throw, exit
	if (v_vertical == -1) {
		return;
	}
	
	// Calculate horizontal
	v_horizontal = DevilCalculateHorizontal(throw_spot, target_spot, v_vertical);
	
	// Set up the grenade
	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;
	missile.touch = DevilGrenadeTouch;
	
	// Animation
	missile.nextthink = time + 0.1;
	missile.think = DevilGrenadeThink;
	
	// Write calculated velocity to grenade
	missile.velocity = DevilConvertVelocity(throw_spot, target_spot, v_vertical, v_horizontal);
	
	missile.avelocity_x = 0;
	missile.avelocity_y = (random() * 400) + 100;
	missile.avelocity_z = (random() * 100) + 600;
	missile.angles = vectoangles(missile.velocity);
	
	// Model and origin
	setmodel (missile, "progs/dynamite.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, throw_spot);
	
	// Sound effect
	sound (self, CHAN_WEAPON, "devil/throw.wav", 1, ATTN_NORM);
};

//=============================================================================

/*
===========
Melee Stuff
===========
*/
float() DevilRamRange = {
	local vector	delta;
	local float		hit_range;
	
	delta = self.enemy.origin - self.origin;
	
	if (self.enemy.classname == "player") {
		hit_range = DEVIL_MELEE_RANGE;
	}
	else {
		hit_range = 100;
	}

	if (vlen(delta) <= hit_range)
		return TRUE;
	return FALSE;
}

void(float side) DevilRam = {
	local vector	dir;
	local float		force_multiplier;

	if (!self.enemy)
		return;
	if (!CanDamage (self.enemy, self))
		return;
	
	if (!DevilRamRange()) {
		return;
	}
	
	if (self.enemy.flags & FL_MONSTER) {
		if (self.enemy.mass) {
			force_multiplier = 1 / self.enemy.mass;
		}
		else {
			force_multiplier = 1;
		}
		
		if (self.enemy.flags & FL_ONGROUND) {
			self.enemy.flags -= FL_ONGROUND;
		}
		dir = self.enemy.origin - (self.absmin + self.absmax) * 0.5;
		dir = normalize(dir);
		
		self.enemy.velocity = self.enemy.velocity + dir*DEVIL_MELEE_DAMAGE*8*force_multiplier;
		self.enemy.velocity_z += DEVIL_RAM_FORCE * force_multiplier;
	}
	else if (self.enemy.classname == "player") {
		self.enemy.velocity_z += DEVIL_RAM_FORCE;
	}
	T_Damage (self.enemy, self, self, DEVIL_MELEE_DAMAGE);
	
	// Sound
	sound (self, CHAN_WEAPON, "devil/ram.wav", 1, ATTN_NORM);
	
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
	if (random() < 0.2) {
		sound (self, CHAN_VOICE, "devil/idle.wav", 1, ATTN_IDLE);
	}
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

void() devil_rama1	=[ $rama1,	devil_rama2	]
{
	self.super_armor = time + 0.8;
	ai_charge(6);
};
void() devil_rama2	=[ $rama2, devil_rama3		] {ai_charge(0);};
void() devil_rama3	=[ $rama3, devil_rama4		] {ai_charge(0);sound (self, CHAN_WEAPON, "painelem/swipe.wav", 1, ATTN_NORM);};
void() devil_rama4	=[ $rama4, devil_rama5		] {ai_charge(0);};
void() devil_rama5	=[ $rama5, devil_rama6		] {ai_charge(8);};
void() devil_rama6	=[ $rama6, devil_rama7		] {ai_charge(9);DevilRam(1);};
void() devil_rama7	=[ $rama7, devil_rama8		] {ai_charge(4);};
void() devil_rama8	=[ $rama8, devil_rama9		] {ai_charge(1);};
void() devil_rama9	=[ $rama9, devil_rama10		] {ai_charge(1);};
void() devil_rama10	=[ $rama10,	devil_rama11	] {ai_charge(1);};
void() devil_rama11	=[ $rama11,	devil_run1		] {ai_charge(2);};

void() devil_ramb1	=[ $ramb1,	devil_ramb2	]
{
	self.super_armor = time + 0.8;
	ai_charge(6);
};
void() devil_ramb2	=[ $ramb2, devil_ramb3		] {ai_charge(0);};
void() devil_ramb3	=[ $ramb3, devil_ramb4		] {ai_charge(0);sound (self, CHAN_WEAPON, "painelem/swipe.wav", 1, ATTN_NORM);};
void() devil_ramb4	=[ $ramb4, devil_ramb5		] {ai_charge(0);};
void() devil_ramb5	=[ $ramb5, devil_ramb6		] {ai_charge(8);};
void() devil_ramb6	=[ $ramb6, devil_ramb7		] {ai_charge(9);DevilRam(1);};
void() devil_ramb7	=[ $ramb7, devil_ramb8		] {ai_charge(4);};
void() devil_ramb8	=[ $ramb8, devil_ramb9		] {ai_charge(1);};
void() devil_ramb9	=[ $ramb9, devil_ramb10		] {ai_charge(1);};
void() devil_ramb10	=[ $ramb10,	devil_ramb11	] {ai_charge(1);};
void() devil_ramb11	=[ $ramb11,	devil_run1		] {ai_charge(2);};

void() devil_throw1		=[ $throw1,	devil_throw2	] {};
void() devil_throw2		=[ $throw2,	devil_throw3	] {};
void() devil_throw3		=[ $throw3,	devil_throw4	] {};
void() devil_throw4		=[ $throw4,	devil_throw5	] {};
void() devil_throw5		=[ $throw5,	devil_throw6	] {sound (self, CHAN_ITEM, "devil/rustle.wav", 1, ATTN_NORM);};
void() devil_throw6		=[ $throw6,	devil_throw7	] {};
void() devil_throw7		=[ $throw7,	devil_throw8	] {};
void() devil_throw8		=[ $throw8,	devil_throw9	] {DevilFireGrenade();};
void() devil_throw9		=[ $throw9,	devil_throw10	] {};
void() devil_throw10	=[ $throw10, devil_throw11	] {};
void() devil_throw11	=[ $throw11, devil_throw12	] {};
void() devil_throw12	=[ $throw12, devil_throw13	] {};
void() devil_throw13	=[ $throw13, devil_throw14	] {};
void() devil_throw14	=[ $throw14, devil_run1		] {};

void() devil_pain1	=[ $pain1,	devil_pain2	] {};
void() devil_pain2	=[ $pain2,	devil_pain3	] {};
void() devil_pain3	=[ $pain3,	devil_pain4	] {};
void() devil_pain4	=[ $pain4,	devil_pain5	] {};
void() devil_pain5	=[ $pain5,	devil_pain6	] {};
void() devil_pain6	=[ $pain6,	devil_run1	] {};


void() devil_painb1	=[ $painb1,	devil_painb2	] {};
void() devil_painb2	=[ $painb2,	devil_painb3	] {ai_back(2);};
void() devil_painb3	=[ $painb3,	devil_painb4	] {ai_back(1);};
void() devil_painb4	=[ $painb4,	devil_painb5	] {};
void() devil_painb5	=[ $painb5,	devil_painb6	] {};
void() devil_painb6	=[ $painb6,	devil_painb7	] {ai_back(-1);};
void() devil_painb7	=[ $painb7,	devil_run1		] {ai_back(-2);};

void() devil_painc1		=[ $painc1,		devil_painc2	] {};
void() devil_painc2		=[ $painc2,		devil_painc3	] {ai_back(9);};
void() devil_painc3		=[ $painc3,		devil_painc4	] {ai_back(7);};
void() devil_painc4		=[ $painc4,		devil_painc5	] {ai_back(1);};
void() devil_painc5		=[ $painc5,		devil_painc6	] {ai_back(2);};
void() devil_painc6		=[ $painc6,		devil_painc7	] {ai_back(2);};
void() devil_painc7		=[ $painc7,		devil_painc8	] {ai_back(3);};
void() devil_painc8		=[ $painc8,		devil_painc9	] {ai_back(6);};
void() devil_painc9		=[ $painc9,		devil_painc10	] {ai_back(6);};
void() devil_painc10	=[ $painc10,	devil_painc11	] {ai_back(3);};
void() devil_painc11	=[ $painc11,	devil_painc12	] {ai_back(0);};
void() devil_painc12	=[ $painc12,	devil_painc13	] {ai_back(-1);};
void() devil_painc13	=[ $painc13,	devil_painc14	] {ai_back(-2);};
void() devil_painc14	=[ $painc14,	devil_painc15	] {ai_back(-3);};
void() devil_painc15	=[ $painc15,	devil_painc16	] {ai_back(-2);};
void() devil_painc16	=[ $painc16,	devil_run1		] {ai_back(-4);};


void(entity attacker, float damage)	devil_pain =
{
	local float	r;

// don't make multiple pain sounds right after each other
	if (self.pain_finished > time)
		return;
	
	// Immune to stun during its ram attack
	if (self.super_armor > time) {
		return;
	}
	
	if (damage < random() * DEVIL_PAIN_THRESHOLD) {
		return;
	}

	sound (self, CHAN_VOICE, "devil/pain.wav", 1, ATTN_NORM);		

	r = random();
	
	if (r < 0.45)
	{
		devil_pain1 ();
		self.pain_finished = time + 1;
	}
	else if (r < 0.88)
	{
		devil_painb1 ();
		self.pain_finished = time + 1;
	}
	else
	{
		devil_painc1 ();
		self.pain_finished = time + 4;
	}
};

void() devil_death1		=[ $death1,		devil_death2	] {};
void() devil_death2		=[ $death2,		devil_death3	] {ai_back(8);};
void() devil_death3		=[ $death3,		devil_death4	] {ai_back(10);self.solid = SOLID_NOT;};
void() devil_death4		=[ $death4,		devil_death5	] {ai_back(9);};
void() devil_death5		=[ $death5,		devil_death6	] {ai_back(13);};
void() devil_death6		=[ $death6,		devil_death7	] {ai_back(17);};
void() devil_death7		=[ $death7,		devil_death8	] {ai_back(8);};
void() devil_death8		=[ $death8,		devil_death9	] {};
void() devil_death9		=[ $death9,		devil_death10	] {};
void() devil_death10	=[ $death10,	devil_death10	] {};

void() devil_die =
{
// check for gib
	if (self.health < -80)
	{
		sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
		ThrowHead ("progs/gib3.mdl", self.health);
		ThrowGib ("progs/gib3.mdl", self.health);
		ThrowGib ("progs/gib3.mdl", self.health);
		ThrowGib ("progs/gib3.mdl", self.health);
		return;
	}

	sound (self, CHAN_VOICE, "devil/death.wav", 1, ATTN_NORM);
	
	if (random() < 0.5)
		devil_death1 ();
	else
		devil_death1 ();
};

void() devil_melee =
{
	if (random() < 0.66)
		devil_rama1 ();
	else
		devil_ramb1 ();
};

float() DevilCheckAttack =
{
	local float		chance;
	local float		sim_result;
	
	if (enemy_range == RANGE_MELEE)
	{
		if (CanDamage (self.enemy, self))
		{
			if (DevilRamRange())
			{
				self.attack_state = AS_MELEE;
				return TRUE;
			}
		}
	}

	if (time < self.attack_finished)
		return FALSE;
	
	// Simulate the throw to see if it will hit the player
	sim_result = DevilSimulateThrow();
	if (sim_result == -1) {
		return FALSE;
	}
	self.chosen_angle = sim_result;
	
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
	//precache_model ("progs/h_devil.mdl");
	precache_model ("progs/dynamite.mdl");

	precache_sound ("devil/death.wav");
	precache_sound ("devil/idle.wav");
	precache_sound ("devil/pain.wav");
	precache_sound ("devil/ram.wav");
	precache_sound ("devil/sight.wav");
	precache_sound ("devil/throw.wav");
	precache_sound ("devil/rustle.wav");
	precache_sound ("painelem/swipe.wav");

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/devil.mdl");

	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.health = 250;
	self.mass = 1.8;

	self.th_stand = devil_stand1;
	self.th_walk = devil_walk1;
	self.th_run = devil_run1;
	self.th_die = devil_die;
	self.th_melee = devil_melee;
	self.th_missile = devil_throw1;
	self.th_pain = devil_pain;
	
	walkmonster_start();
};
