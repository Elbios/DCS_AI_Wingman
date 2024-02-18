import numpy as np
from scipy.io.wavfile import read, write
from scipy.signal import butter, lfilter

def bandpass_filter(data, lowcut, highcut, fs, order=5):
    nyq = 0.5 * fs
    low = lowcut / nyq
    high = highcut / nyq
    b, a = butter(order, [low, high], btype='band')
    y = lfilter(b, a, data)
    return y

# Load your TTS output
fs, data = read("ATC_sample1_denoised.wav")

# Ensure your data is in float for processing
data = data.astype(np.float32)

# Adjust volume of the noise
noise_level = 0.02  # Adjust the noise level as needed
noise = np.random.normal(0, np.max(data) * noise_level, data.shape)

# Mix data with noise
noisy_data = data + noise

# Apply bandpass filter
filtered_data = bandpass_filter(noisy_data, 300, 3000, fs, order=6)

# Normalize filtered data to prevent clipping and convert back to original dtype
filtered_data = np.int16((filtered_data / np.max(np.abs(filtered_data))) * 32767)

# Write to file
write("processed_tts_output.wav", fs, filtered_data)
