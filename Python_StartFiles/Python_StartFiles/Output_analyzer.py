import numpy as np
import matplotlib.pyplot as plt
import file_parser as fp

# Parameters
fs = 8000  # Sampling frequency in Hz
q_factor = 15  # Q15 format for fixed-point signals

# Read input and output signals
input_signal = fp.reads("input.pcm")  # Input signal from file
output_signal = fp.reads("Output_of_C_Code/out.pcm")  # Output signal from file

# output_signal = fp.reads("Output_of_Assembly_Code/out.pcm")  # Output signal from file

# Convert signals back to floating-point
input_signal_float = input_signal / (2 ** q_factor)
output_signal_float = output_signal / (2 ** q_factor)

# Time-domain plot
plt.figure(figsize=(12, 6))

# Plot input signal
plt.subplot(2, 1, 1)
plt.plot(input_signal_float, label="Input Signal")
plt.title("Time Domain: Input Signal")
plt.xlabel("Sample")
plt.ylabel("Amplitude")
plt.legend()
plt.grid()

# Plot output signal
plt.subplot(2, 1, 2)
plt.plot(output_signal_float, label="Output Signal (Filtered)", color="orange")
plt.title("Time Domain: Output Signal (Filtered)")
plt.xlabel("Sample")
plt.ylabel("Amplitude")
plt.legend()
plt.grid()

plt.tight_layout()
plt.show()

# Frequency-domain plot (FFT)
# Compute FFT of input and output signals
input_fft = np.fft.fft(input_signal_float)
output_fft = np.fft.fft(output_signal_float)

# Compute frequency axis
freqs = np.fft.fftfreq(len(input_signal_float), 1 / fs)

# Only take the positive frequencies for plotting
positive_freqs = freqs[:len(freqs) // 2]
input_fft_magnitude = np.abs(input_fft[:len(input_fft) // 2])
output_fft_magnitude = np.abs(output_fft[:len(output_fft) // 2])

# Plot frequency domain
plt.figure(figsize=(12, 6))

# Plot FFT of input signal
plt.subplot(2, 1, 1)
plt.plot(positive_freqs, input_fft_magnitude, label="Input Signal FFT")
plt.title("Frequency Domain: Input Signal")
plt.xlabel("Frequency (Hz)")
plt.ylabel("Magnitude")
plt.legend()
plt.grid()

# Plot FFT of output signal
plt.subplot(2, 1, 2)
plt.plot(positive_freqs, output_fft_magnitude, label="Output Signal FFT (Filtered)", color="orange")
plt.title("Frequency Domain: Output Signal")
plt.xlabel("Frequency (Hz)")
plt.ylabel("Magnitude")
plt.legend()
plt.grid()

plt.tight_layout()
plt.show()
