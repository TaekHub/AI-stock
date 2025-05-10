import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense
from sklearn.preprocessing import MinMaxScaler
from data_preprocessing import fetch_data

# 데이터 불러오기
df = fetch_data()
scaler = MinMaxScaler()
df["Close_Scaled"] = scaler.fit_transform(df[["Close"]])

# 시계열 데이터 변환 (LSTM 입력 형식)
def create_sequences(data, seq_length=10):
    sequences, labels = [], []
    for i in range(len(data) - seq_length):
        sequences.append(data[i : i + seq_length])
        labels.append(data[i + seq_length])
    return np.array(sequences), np.array(labels)

seq_length = 10
X, y = create_sequences(df["Close_Scaled"].values, seq_length)

# LSTM 모델 구성
model = Sequential([
    LSTM(50, activation="relu", return_sequences=True, input_shape=(seq_length, 1)),
    LSTM(50, activation="relu"),
    Dense(1)
])

model.compile(optimizer="adam", loss="mse")
model.fit(X, y, epochs=50, batch_size=16)

# 모델 저장
model.save("models/lstm_model.h5")
print("✅ LSTM 모델 저장 완료!")
