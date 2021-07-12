/*
	* Decreases at a rate proportional to it's current value. y=a(1-b)^x

	* A = initial amount
	* B = decay factor
	* x = amount of intervals.
*/
#define EXP_DECAY(A, B, x) (A * (1 - B) ** x)

/// Rotations per minute to radians per second
#define RPM_TO_RADS(R) (R / 60 * 2 * PI)

/// Radians per second to Rotations per minute
#define RADS_TO_RPM(R) ((R * 60) / 2 / PI)
