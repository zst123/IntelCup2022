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


# In[187]:

with open('./keywords.txt') as f:
    keywords_list = f.read().splitlines()

no_of_keywords = len(keywords_list)

D = [] # Dataset
audio_files = glob('./new_data/*.wav')

for audio in audio_files:
    audio_name = audio.split('\\')[-1]

    index = -1
    for id, keyword in enumerate(keywords_list):
        if audio_name.startswith(keyword):
            index = id

    if index == -1:
        index = no_of_keywords
        print("Not tagged", audio_name)
        
    y, sr = librosa.load(audio, sr=16000, duration=1.00)  # Duration is actually 0.75, just to confirm all files are of that length
    ps = librosa.feature.mfcc(y, sr=sr)
    if ps.shape != (20, 24): 
        print(audio_name)
        print(ps.shape)
        continue

    D.append( (ps, index) )


# In[ ]:


len(D)


# In[406]:


dataset = D
random.shuffle(dataset)
train_num = 0.67 *len(dataset)
train = dataset[0:int(train_num)]
test = dataset[int(train_num):]

X_train, y_train = zip(*train)
X_test, y_test = zip(*test)

# Reshape for CNN input
X_train = np.array([x.reshape( (20, 24, 1) ) for x in X_train])
X_test = np.array([x.reshape( (20, 24, 1) ) for x in X_test])

# One-Hot encoding for classes
y_train = np.array(keras.utils.np_utils.to_categorical(y_train, 20))
y_test = np.array(keras.utils.np_utils.to_categorical(y_test, 20))


# In[18]:


model = Sequential()
input_shape=(20, 24, 1)

model.add(Conv2D(24, (3, 3), strides=(1, 1), input_shape=input_shape, padding="same"))
model.add(MaxPooling2D((2, 2), strides=(2, 2)))
model.add(Activation('relu'))

model.add(Conv2D(24, (3, 3), padding="same"))
model.add(MaxPooling2D((2, 2), strides=(2, 2)))
model.add(Activation('relu'))

model.add(Conv2D(24, (3, 3), padding="same"))
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


# In[515]:



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


# In[14]:


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
