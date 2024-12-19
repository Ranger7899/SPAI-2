#include "anf.h"

int anf(int y, int *s, int *a, int *rho, unsigned int* index)
{
    /*
     y in Q15: newly captured sample
     s in Q12: x[3] databuffer - Hint: Reserve a sufficiently number of integer bits such that summing intermediate values does not cause overflow (so no shift is needed after summing numbers)
     a in Q14: the adaptive coefficient
     e in Q15: output signal
     rho in Q15: fixed {rho, rho^2} or variable {rho, rho_inf} pole radius
     index : points to (t-1) sample (t current time index) in s -> circular buffer
     */
        
    int e, k;
    long AC0, AC1;

    // Constants for rho adaptation
    const int lambda = (int)(0.95 * (1 << 15));  // Exponential decay constant (Q15)
    const int rho_inf = (int)(0.8 * (1 << 15));  // Final pole radius (Q15)

    // Circular buffer indices
    k = *index;      // Current index in the state vector
    int k1 = (k + 1) % 3; // Next index
    int k2 = (k + 2) % 3; // Previous index

    // Step 1: Adaptive pole radius (rho)
    AC0 = (long)lambda * (long)rho[0];           // lambda * rho(m-1)
    AC0 += ((1 << 15) - lambda) * (long)rho_inf; // (1 - lambda) * rho(inf)
    rho[0] = (int)(AC0 >> 15);                   // Update rho(m) (Q15)
    rho[1] = (int)(((long)rho[0] * (long)rho[0]) >> 15); // Update rho^2(m) (Q15)

    // Step 2: State vector update
    AC0 = (long)rho[0] * (long)*a * (long)s[k1];   // rho * a * s[k1] (Q15 * Q14 * Q12 = Q41)
    AC0 = AC0 >> 15;                               // Scale back to Q12
    AC0 -= ((long)rho[1] * (long)s[k2]) >> 15;     // Subtract rho^2 * s[k2] (Q15 * Q12 = Q27 -> Q12)
    AC0 += y;                                      // Add current input sample y (Q15 -> Q12)
    s[k] = (int)AC0;                               // Update s[k]

    // Step 3: Error signal calculation
    AC1 = (long)s[k] << 3;                         // Convert s[k] from Q12 to Q15
    AC1 -= ((long)*a * (long)s[k1]) >> 15;         // Subtract a * s[k1]
    AC1 += (long)s[k2] << 3;                       // Add s[k2] (Q12 -> Q15)
    e = (int)AC1;                                  // Store error signal

    // Step 4: Adaptive coefficient update
    AC1 = (long)s[k1] * (long)e;                   // s[k1] * e (Q12 * Q15 = Q27)
    AC1 = (AC1 >> 14) * 2;                         // Scale to Q14 and multiply by 2
    *a += (int)AC1;                                // Update adaptive coefficient

    // Step 5: Constrain adaptive coefficient to |a| < 2 (Q14)
    if (*a > (1 << 14)) {
        *a = (1 << 14) - 1;
    } else if (*a < -(1 << 14)) {
        *a = -(1 << 14);
    }

    // Update circular buffer index
    *index = k1;

    return e;  // Return the filtered output signal
}
