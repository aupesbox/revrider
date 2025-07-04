import numpy as np
from scipy.io.wavfile import write
from pydub import AudioSegment

# Step 1: Parameters
sample_rate = 44100  # 44.1 kHz standard
duration = 3         # 3 seconds
t = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)

# Step 2: Simulate exhaust pulses (like 60 RPM putt-putt)
pulse_wave = 0.5 * np.sin(2 * np.pi * 60 * t) * (np.sin(2 * np.pi * 5 * t) > 0)

# Step 3: Add random combustion "pops" as noise bursts
noise = np.random.randn(len(t)) * (np.sin(2 * np.pi * 4 * t) > 0.98)

# Step 4: Combine pulse + noise, and normalize
exhaust = pulse_wave + 0.3 * noise
exhaust /= np.max(np.abs(exhaust))  # Normalize to -1 to 1 range

# Step 5: Save as temporary WAV
write("exhaust_temp.wav", sample_rate, (exhaust * 32767).astype(np.int16))

# Step 6: Convert WAV to MP3 using pydub + ffmpeg
sound = AudioSegment.from_wav("exhaust_temp.wav")
sound.export("bike_exhaust.mp3", format="mp3")

print("✅ MP3 file 'bike_exhaust.mp3' generated successfully!")
