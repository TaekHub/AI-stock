import yfinance as yf
import pandas as pd
from database import insert_stock_data

# 📌 PLTR(팔란티어) 주식 데이터 가져오기
def fetch_stock_data():
    stock = yf.Ticker("PLTR")
    df = stock.history(period="1d", interval="1m")  # 최근 하루 동안 1분 간격 데이터 가져오기

    # 날짜 변환 (Datetime 형식으로)
    df.reset_index(inplace=True)
    df["Datetime"] = df["Datetime"].dt.strftime('%Y-%m-%d %H:%M:%S')

    # 필요한 데이터만 선택
    stock_data = df[["Datetime", "Open", "High", "Low", "Close", "Volume"]].values.tolist()

    return stock_data

# 실행 함수
if __name__ == "__main__":
    data = fetch_stock_data()
    insert_stock_data(data)
