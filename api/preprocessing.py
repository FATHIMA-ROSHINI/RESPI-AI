import numpy as np
import librosa
import scipy.signal
import torch

class AudioPreprocessor:
    def __init__(self, sample_rate=16000, n_mfcc=40, n_fft=2048, hop_length=512, target_length=5.0):
        self.sample_rate = sample_rate
        self.n_mfcc = n_mfcc
        self.n_fft = n_fft
        self.hop_length = hop_length
        self.target_length = target_length  # Target audio length in seconds
        
    def butterworth_bandpass(self, data, lowcut=50, highcut=2500, order=5):
        """
        Apply Butterworth Band-Pass Filter (50Hz - 2500Hz) as per Readme.
        """
        nyq = 0.5 * self.sample_rate
        low = lowcut / nyq
        high = highcut / nyq
        b, a = scipy.signal.butter(order, [low, high], btype='band')
        y = scipy.signal.lfilter(b, a, data)
        return y

    def extract_features(self, file_path_or_array, is_path=True):
        """
        Full pipeline: Load -> Pad/Crop -> Filter -> MFCC -> Normalize
        """
        # 1. Load Audio
        if is_path:
            y, sr = librosa.load(file_path_or_array, sr=self.sample_rate)
        else:
            y = file_path_or_array
            sr = self.sample_rate

        # 2. Pad or Crop to target length (Fixed input size for CNN)
        target_samples = int(self.target_length * self.sample_rate)
        if len(y) > target_samples:
            y = y[:target_samples]
        else:
            padding = target_samples - len(y)
            y = np.pad(y, (0, padding), mode='constant')

        # 3. Butterworth Filter
        y_filtered = self.butterworth_bandpass(y)

        # 4. Generate MFCCs
        # Librosa does: STFT -> Mel -> Log -> DCT -> MFCC
        mfcc = librosa.feature.mfcc(
            y=y_filtered, 
            sr=self.sample_rate, 
            n_mfcc=self.n_mfcc, 
            n_fft=self.n_fft, 
            hop_length=self.hop_length,
            window='hamming' # Readme specifies Hamming
        )

        # 5. Z-Score Normalization (across the time axis for this sample)
        mean = np.mean(mfcc, axis=1, keepdims=True)
        std = np.std(mfcc, axis=1, keepdims=True)
        mfcc_normalized = (mfcc - mean) / (std + 1e-6)

        # Shape: (n_mfcc, time_steps) -> (Channels, Height, Width) for CNN
        # We treat it as a 1-channel image: (1, n_mfcc, time_steps)
        return torch.tensor(mfcc_normalized, dtype=torch.float32).unsqueeze(0)

# Example usage (commented out)
# processor = AudioPreprocessor()
# features = processor.extract_features("path/to/audio.wav")
# print(features.shape)
