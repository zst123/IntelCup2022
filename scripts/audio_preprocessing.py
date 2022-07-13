# Lib
import math
import random
from glob import glob  # read a list of audio files
import os
import threading
import time

import librosa
import librosa.display
import soundfile as sf
import numpy as np
import pandas as pd
import torch
import torchaudio
from librosa.util import fix_length

# parameters to define
file_address = '/content/*.wav'
channel_num = 2
sample_rate = 16000  # more suitable than 44100
len_ms = 1000
time_shift_limit = sample_rate / 10  # need to tune this value
strech_limit = 0.1  # need to tune this value

replicate_num = 10  # num of new data file derived from orginal raw data

tsh_factors = [1.0, 0.5, 0] # Not used for now
noise_factors = [0, 0.2]
tst_factors = [0.8, 0.9, 1, 1.1, 1.2]
psh_factors = [-1.5, -0.5, 0, 0.25]

trim_percentile = 50  # top 50% of rms dB
half_size_ms = 750  # in ms


# Copied from https://medium.com/@makcedward/data-augmentation-for-audio-76912b01fdf6
def manipulate(data, noise_factor):
    noise = np.random.randn(len(data))
    augmented_data = data + noise_factor * noise
    # Cast back to same data type
    augmented_data = augmented_data.astype(type(data[0]))
    return augmented_data


# convert mono to stereo/ stereo to mono
def rechannel(wav, channel_num):
    if wav.shape[0] == channel_num:
        return wav
    if channel_num == 1:
        wav_stereo = librosa.to_mono(wav)
    else:
        wav_stereo = torch.cat([wav, wav])
    return wav_stereo


# resize to same length
def resize_length(wav, sr, len_ms):
    original_len = wav.shape[0]
    max_len = math.ceil(sr * (len_ms / 1000))
    if original_len > max_len:
        # truncate
        diff = math.ceil((original_len - max_len) / 2)
        wav_resized = wav[diff: (original_len - diff)]
    elif original_len < max_len:
        # pad
        # pad_begin_len = random.randint(0, max_len - original_len)
        # pad_end_len = max_len - original_len - pad_begin_len
        # pad_begin = torch.zeros((num_rows, pad_begin_len))
        # pad_end = torch.zeros((num_rows, pad_end_len))
        # wav_resized = torch.cat((pad_begin, wav, pad_end), 1)
        wav_resized = librosa.util.fix_length(wav, size=max_len)

    else:
        wav_resized = wav
    return wav_resized


def pad_length(wav, sr, seconds):
    original_len = wav.shape[0]
    max_len = sr // 1000 * len_ms
    if original_len < max_len:
        wav = fix_length(wav, size=seconds * sr)
    return wav


def fix_sr(wav, sr_old, sr_new):
    if sr_old == sr_new:
        return wav
    num_channels = wav.shape[0]
    # Resample first channel
    wav = torchaudio.transforms.Resample(sr_old, sr_new)(sig[:1, :])
    if num_channels > 1:
        # Resample the second channel and merge both channels
        wav_2 = torchaudio.transforms.Resample(sr_old, sr_new)(sig[1:, :])
        wav = torch.cat([wav, wav_2])
    return wav


# trimming from 1 sec to 0.5 sec
def trim_half(wav, trim_percentile, sr, half_size_ms):
    mse = librosa.feature.rms(y=wav, frame_length=2048, hop_length=512) ** 2
    mse_db = librosa.power_to_db(mse.squeeze(), ref=np.max, top_db=80)
    threshold = abs(np.percentile(mse_db, trim_percentile))
    wav_trimmed, index = librosa.effects.trim(wav, top_db=threshold, frame_length=2049, hop_length=512)
    wav_half = resize_length(wav_trimmed, sr, half_size_ms)
    return wav_half


# Time shifting
# shift the wave by a random amount ?
def time_shift(wav, shift_limit, factor):
    shift_time = int(factor * shift_limit)
    wav_time_shift = np.roll(wav, shift_time)
    return wav_time_shift


# Time Streching
# slow the audio by 0.4
def time_strech(wav, strech_factor):
    # strech_factor = random.uniform(0.75, 2)
    #  Modified random.randrange(strech_limit * 10, 10) / 10
    wav_time_strech = librosa.effects.time_stretch(wav, rate=strech_factor)
    return wav_time_strech


# Pitch Shifting
# number of steps between -5 and 5

def pitch_shift(sr, wav, factor):
    # n_steps = random.randrange(-5, 5, 1)
    wav_pitch_shift = librosa.effects.pitch_shift(wav, sr=sr, n_steps=factor)
    return wav_pitch_shift


## Load data

# convert all to mono channel
# standardize sample rate to 48000hz

# def audio_modulation():
#audio_files = glob('./samples/*/*.wav')
audio_files = glob('../flutter_app/samples/*.wav') + glob('../flutter_app/samples/*/*.wav')
# count = 0

if not os.path.isdir("./new_data/"):
    os.mkdir("./new_data/")

def thread_function(args):
    print("Thread starting:", args)
    audio = args
    print(124)
    audio_name = audio.split('\\')[-1]
    sig, sr = torchaudio.load(audio)
    # format the audio file
    sig = rechannel(sig, channel_num)
    # sig = resize_length(sig, sr, len_ms)
    sig = fix_sr(sig, sr, sample_rate)

    f_audio = audio
    torchaudio.save(f_audio, sig, sample_rate)
    # load the formatted audio file
    wav, sr = librosa.load(f_audio, sr=None)

    audio_title = audio_name[:-4]

    wav = trim_half(wav, trim_percentile, sr, half_size_ms)
    wav = librosa.effects.preemphasis(wav)

    duration = librosa.get_duration(y=wav, sr=sample_rate)
    # sf.write('./new_data/wow.wav', wav, sr)
    # exit()
    for i in range(len(noise_factors)):
        wav_tsh = manipulate(wav, noise_factors[i])
        #     wav_tsh = resize_length(wav_tsh, sr, half_size_ms)
        for j in range(len(tst_factors)):
            wav_tsh_tst = time_strech(wav, tst_factors[j])
            wav_tsh_tst = resize_length(wav_tsh_tst, sr, half_size_ms)
            for k in range(len(psh_factors)):
                wav_tsh_tst_psh = pitch_shift(sr, wav_tsh_tst, psh_factors[k])
                wav_tsh_tst_psh = resize_length(wav_tsh_tst_psh, sr, half_size_ms)
                sf.write('./new_data/' + audio_title +
                         '_noise' + str(i) + '_tst' + str(j) + '_psh' + str(k) + '.wav', wav_tsh_tst_psh, sr)

    os.remove(f_audio)
    print("Thread finishing:", args)

threads_list = []
for audio in audio_files:
    th = threading.Thread(target=thread_function, args=(audio,));
    th.start()
    threads_list.append(th)
    # if count > 0:
    #     break
    # count += 1

for th in threads_list:
    th.join()

# if __name__ == '__main__':
