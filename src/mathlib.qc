/*
mathlib.qc
Created by Frika-C
*/

/*
-----------------------------------------
integer square root

returns a floor()'d integer approximation
good enough for most situations
-----------------------------------------
*/

float(float num) sqrt =
{
	local float bit, guess, f;
	
	bit = 65536;
	
	do
	{
		f = guess | bit;
		if ((f * f) <= num)
			guess = f;
		bit = bit / 2;
	}
	while (bit > 1);

	return guess;
};


/*
-----------------------------------------
sine

-----------------------------------------
*/

float(float num) sin =
{
	local vector ang;
	ang = '0 1 0' * num;
	makevectors(ang);
	return v_forward_y;
};

/*
-----------------------------------------
cosine


-----------------------------------------
*/

float(float num) cos =
{
	local vector ang;
	ang = '0 1 0' * num;
	makevectors(ang);
	return v_forward_x;
};

/*
-----------------------------------------
pow

raise to a power

you ought not use this if the power you're raising to is constant
ie, just use r * r * r for cubing, it's a lot faster
-----------------------------------------
*/

float(float num, float exp) pow =
{
	local float r;
	r = 1;
	if (exp < 0)
	{
		while(exp)
		{
			exp = exp + 1;
			r = r / num;
		}
	}
	else
	{
		while(exp)
		{
			exp = exp - 1;
			r = r  * num;
		}
	}
	return r;
};

/*
-----------------------------------------
Modulus

C's % operator
-----------------------------------------
*/

float(float a, float b) mod =
{
	return a - (floor(a / b) * b);
};

/*
-----------------------------------------
frik_anglemod (part of FrikBot)

faster version of id's anglemod
-----------------------------------------
*/
/*float(float v) frik_anglemod =
{
	return v - floor(v/360) * 360;
};*/

/*
-----------------------------------------
angcomp (part of FrikBot)

subtracts one angle from another
-----------------------------------------
*/

/*float (float y1, float y2) angcomp = 
{
	y1 = frik_anglemod(y1);
	y2 = frik_anglemod(y2);

	local float answer;
	answer = y1 - y2;
	if (answer > 180)
		answer = answer - 360;
	else if (answer < -180)
		answer = answer + 360;
	return answer;
};
*/
