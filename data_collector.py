import mysql.connector
import yfinance as yf
from datetime import datetime

# MySQL 연결
db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="0000",
    database="stock_trading"
)
cursor = db.cursor()

# 데이터 수집 함수
def fetch_stock_data():
    stock = yf.Ticker("PLTR")
    df = stock.history(period="1d", interval="1h")  # 1시간 간격 데이터

    for index, row in df.iterrows():
        query = """
        INSERT INTO stock_data (date, open_price, high_price, low_price, close_price, volume)
        VALUES (%s, %s, %s, %s, %s, %s)
        """
        values = (index.strftime("%Y-%m-%d %H:%M:%S"), row["Open"], row["High"], row["Low"], row["Close"], row["Volume"])
        cursor.execute(query, values)
        db.commit()

fetch_stock_data()
cursor.close()
db.close()
