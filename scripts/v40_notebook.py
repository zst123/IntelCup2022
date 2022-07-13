#!/usr/bin/env python
# coding: utf-8

# In[1]:

import keras
from keras.layers import Activation, Dense, Dropout, Conv2D,                          Flatten, MaxPooling2D
from keras.models import Sequential
import librosa
import librosa.display
import numpy as np
import pandas as pd
import random
from glob import glob  # read a list of audio filess
from keras.utils import np_utils
import warnings
warnings.filterwarnings('ignore')
import matplotlib.pyplot as plt


# In[143]:


D = [] # Dataset
audio_files = glob('./new_data/*.wav')

for audio in audio_files:
    audio_name = audio.split('\\')[-1]
    if audio_name[0] == "b":
        index = 0
    elif audio_name[0] == "c":
        index = 1
    elif audio_name[0] == "d" and audio_name[1] == "e":
        index = 2
    elif audio_name[0] == "d":
        index = 3
    elif audio_name[0] == "g":
        index = 4
    elif audio_name[0] == "h":
        index = 5
    elif audio_name[0] == "k":
        index = 6
    elif audio_name[0] == "l":
        index = 7
    elif audio_name[0] == "m":
        index = 8
    elif audio_name[0] == "o":
        index = 9
    elif audio_name[0] == "p":
        index = 10
    elif audio_name[0] == "t":
        index = 11
    elif audio_name[0] == "w":
        index = 12
    else:
        index = 13
        print("Not tagged", audio_name)
        
    y, sr = librosa.load(audio, sr=16000, duration=1.00)
    ps = librosa.feature.melspectrogram(y=y, sr=sr, n_mels=64,
                                    fmin=0, fmax=8000)
    if ps.shape != (64, 24): 
        print(audio_name)
        print(ps.shape)
        continue
    ps = librosa.amplitude_to_db(ps, ref=np.min)

    D.append( (ps, index) )


# In[151]:


dataset = D
random.shuffle(dataset)
train_num = 0.67 *len(dataset)
train = dataset[0:int(train_num)]
test = dataset[int(train_num):]

X_train, y_train = zip(*train)
X_test, y_test = zip(*test)

# Reshape for CNN input
X_train = np.array([x.reshape( (64, 24, 1) ) for x in X_train])
X_test = np.array([x.reshape( (64, 24, 1) ) for x in X_test])

# One-Hot encoding for classes
y_train = np.array(keras.utils.np_utils.to_categorical(y_train, 20))
y_test = np.array(keras.utils.np_utils.to_categorical(y_test, 20))


# In[159]:


model = Sequential()
input_shape=(64, 24, 1)

model.add(Conv2D(24, (5, 5), strides=(1, 1), input_shape=input_shape, padding="same"))
model.add(MaxPooling2D((4, 2), strides=(4, 2)))
model.add(Activation('relu'))

model.add(Conv2D(48, (5, 5), padding="same"))
model.add(MaxPooling2D((4, 2), strides=(4, 2)))
model.add(Activation('relu'))

model.add(Conv2D(48, (5, 5), padding="same"))
model.add(Activation('relu'))

model.add(Flatten())
model.add(Dropout(rate=0.5))

model.add(Dense(64))
model.add(Activation('relu'))
model.add(Dropout(rate=0.5))

model.add(Dense(20))
model.add(Activation('sigmoid'))

model.compile(
	optimizer="Adam",
	loss="categorical_crossentropy",
	metrics=['accuracy'])


# In[162]:



model.fit(
	x=X_train, 
	y=y_train,
    epochs=12,
    batch_size=128,
    validation_data= (X_test, y_test))

score = model.evaluate(
	x=X_test,
	y=y_test)

print('Test loss:', score[0])
print('Test accuracy:', score[1])


# In[163]:


from keras.models import load_model

# model = load_model('ten_val.h5')
model.save('16kv_2.h5')


# In[ ]:

'''
audio_files = glob('./test/*.wav')

audio = audio_files[6]
y, sr = librosa.load(audio, duration=1.00)
print(y)
print(sr)
print(y.shape)
ps = librosa.feature.melspectrogram(y=y, sr=sr)
ps.shape

from IPython.display import Audio
Audio(audio)
'''

# In[53]:


model.summary()


# The dataset consists of:
# - 1-7467 normal samples.
# - 7468-14934 samples Pitch modulated 2.5 semitones higher.
# - 14935-22401 samples Pitch modeulated 2 semitones higher.
# - 22402-29869 samples Slowed down to 0.81.
# - 29869-37310 samples speed up by 1.07
# 
# Follow the same procedure for the normal data.

# In[88]:


feat.shape

