#define MWSPT_NSEC 5

// Implements 2 SOS for a 4th order IIR filter
// Coefficients are stored in Q14


// Numerator coefficients
const short NUM[MWSPT_NSEC][3] ={
    {4096, 0, 0},           // alphaB1 - scaling alpha0
    {1201, -648, 1201},     // A1
    {16384, 0, 0},          // alphaB2 - scaling alpha1
    {16384, -21902, 16384}, // A2
    {262144, 0, 0}          // alphaB3 - scaling alpha2
};

// Denominator coefficients
const short DEN[MWSPT_NSEC][3] = {
    {16384, 0, 0},          // no scaling; 16384 in Q14 = 1
    {16384, -15595, 7198},  // B1
    {16384, 0, 0},
    {16384, -22004, 15443}, // B2
    {16384, 0, 0}
};
