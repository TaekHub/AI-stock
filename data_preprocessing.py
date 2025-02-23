import pandas as pd
import talib
import mysql.connector

# MySQL에서 데이터 불러오기
def fetch_data():
    db = mysql.connector.connect(
        host="localhost", user="root", password="0000", database="stock_trading"
    )
    cursor = db.cursor()

    cursor.execute("SELECT date, open_price, high_price, low_price, close_price, volume FROM stock_data")
    rows = cursor.fetchall()
    db.close()

    df = pd.DataFrame(rows, columns=["Date", "Open", "High", "Low", "Close", "Volume"])
    df["Date"] = pd.to_datetime(df["Date"])
    return df

# 데이터 전처리 (결측치 처리 & 정규화)
def preprocess_data(df):
    df.fillna(method="ffill", inplace=True)  # 결측치 전방 채우기
    df["Close_Norm"] = df["Close"] / df["Close"].max()  # 정규화
    return df

# 기술적 지표 계산 (RSI, MACD, 이동평균선)
def add_technical_indicators(df):
    df["SMA_50"] = talib.SMA(df["Close"], timeperiod=50)  # 50일 이동평균선
    df["RSI"] = talib.RSI(df["Close"], timeperiod=14)  # RSI
    macd, macd_signal, _ = talib.MACD(df["Close"], fastperiod=12, slowperiod=26, signalperiod=9)
    df["MACD"] = macd
    df["MACD_Signal"] = macd_signal
    return df

if __name__ == "__main__":
    df = fetch_data()
    df = preprocess_data(df)
    df = add_technical_indicators(df)
    print(df.tail())  # 데이터 확인
