#include <aic3204.h>
#include <usbstk5515.h>
#include <stdio.h>
#include "anf.h"

#define SAMPLES_PER_SECOND 8000
#define GAIN_IN_dB 10

// Declare variables for the filter state and input/output
Int16 left_input, right_input;
int s[3] = {0, 0, 0}; // State vector for the ANF
int a[1] = {0};       // Adaptive coefficient
int rho[2] = {0x7333, 0x0CCD}; // Rho values in Q15 (lambda=0.9, rho_inf=0.1)
unsigned int index = 0;        // Circular buffer index

int main() {
    USBSTK5515_init();         // Initialize the processor
    aic3204_init();            // Initialize the Audio Codec
    set_sampling_frequency_and_gain(SAMPLES_PER_SECOND, GAIN_IN_dB);

    printf("Sampling frequency %d Hz Gain = %d dB\n", SAMPLES_PER_SECOND, GAIN_IN_dB);

    while (1) {
        // Read audio input from the codec
        aic3204_codec_read(&left_input, &right_input);

        // Apply the Adaptive Notch Filter to the left input
        int e = anf(left_input, &s[0], &a[0], &rho[0], &index);

        // Output the processed signal to both left and right channels
        aic3204_codec_write(e, e);

        // Debug print to monitor the input and output signals
        printf("Left Input: %d, Right Input: %d, Output: %d\n", left_input, right_input, e);
    }

    return 0;
}