void() FrozenTouch =
{
	if (other.classname != "player") {
		return;
	}
	
	if (other.health <= 0) {
		return;
	}

	if ((!(other.flags & FL_ONGROUND)) && (other.absmin_z >= self.absmax_z - 2)) {
		other.flags = other.flags + FL_ONGROUND;
	}
};

void(entity targ) UnfreezeMonster = {
	// Monster must be alive
	if (targ.health <= 0) {
		return;
	}
	
	// Must be a monster
	if (!(targ.flags & FL_MONSTER)) {
		return;
	}
	
	// Sound effect
	sound (self, CHAN_AUTO, "ice/unfreeze.wav", 1, ATTN_NORM);
	
	targ.nextthink = time + 0.1;
	targ.takedamage = DAMAGE_AIM;
	targ.movetype = MOVETYPE_STEP;
	targ.touch = targ.freeze_ent.think1;
	
	targ.freeze_ent = 0;
}

void() FreezerThink = {
	local vector particlepos;
	local float r;
	
	// Check if the entity became unfrozen through some other means
	if (self.enemy.freeze_ent != self) {
		remove(self);
		return;
	}
	
	// See if the monster should be unfrozen now.
	if (time > self.count) {
		UnfreezeMonster(self.enemy);
		remove(self);
		return;
	}
	
	// Particle effects
	for (float i = 0; i < 4; i ++) {
		r = random();
		particlepos_x = (self.enemy.absmin_x * r) + (self.enemy.absmax_x * (1-r));
		r = random();
		particlepos_y = (self.enemy.absmin_y * r) + (self.enemy.absmax_y * (1-r));
		r = random();
		particlepos_z = (self.enemy.absmin_z * r) + (self.enemy.absmax_z * (1-r));
		
		particle (particlepos, '0 0 0', 47, 22);
	}
	
	self.nextthink = time + 0.1;
	self.think = FreezerThink;
}

void(entity targ) FreezeMonster = {
	local entity freezer;
	
	// Monster must be alive
	if (targ.health <= 0) {
		return;
	}
	
	// Must be a monster
	if (!(targ.flags & FL_MONSTER)) {
		return;
	}
	
	// Sound effect
	sound (self, CHAN_AUTO, "ice/freeze.wav", 1, ATTN_NORM);
	
	//Freeze them
	targ.nextthink = targ.nextthink + 10;
	targ.takedamage = DAMAGE_NO;
	targ.movetype = MOVETYPE_NONE;
	
	// Create freezer entity
	freezer = spawn();
	
	freezer.enemy = targ;
	freezer.owner = self;
	freezer.count = time + 4;
	setorigin(freezer,targ.origin);
	targ.freeze_ent = freezer;
	
	freezer.think1 = targ.touch;
	targ.touch = FrozenTouch;
	
	freezer.nextthink = time + 0.1;
	freezer.think = FreezerThink;
}

