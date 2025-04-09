import streamlit as st
import pandas as pd
import numpy as np
import yfinance as yf
import ta
import seaborn as sns
import matplotlib.pyplot as plt
from tqdm import tqdm

# Streamlit UI
st.title("📈 주식 투자 백테스트 통합 플랫폼")

# 사용자 입력
symbols = st.text_input("종목 코드 입력 (쉼표로 구분)", "AAPL, MSFT, GOOGL").split(',')
start_date = st.date_input("시작일", pd.to_datetime("2020-01-01"))
end_date = st.date_input("종료일", pd.to_datetime("2024-12-31"))

# 파라미터 입력
rsi_period = st.slider("RSI 기간", 5, 30, 14)
macd_fast = st.slider("MACD Fast", 5, 30, 12)
macd_slow = st.slider("MACD Slow", 10, 60, 26)
macd_signal = st.slider("MACD Signal", 5, 30, 9)
take_profit = st.number_input("익절 (%)", 1.0, 50.0, 10.0)
stop_loss = st.number_input("손절 (%)", 1.0, 50.0, 5.0)
slippage = st.number_input("슬리피지 (bps)", 0.0, 50.0, 5.0)
fee = st.number_input("수수료 (bps)", 0.0, 50.0, 2.0)

# 데이터 수집 함수
def download_data(symbol, start, end):
    data = yf.download(symbol, start=start, end=end)
    data.dropna(inplace=True)
    return data

# 지표 추가 함수
def add_indicators(df):
    df['RSI'] = ta.momentum.RSIIndicator(df['Close'], window=rsi_period).rsi()
    macd = ta.trend.MACD(df['Close'], window_slow=macd_slow, window_fast=macd_fast, window_sign=macd_signal)
    df['MACD'] = macd.macd()
    df['MACD_signal'] = macd.macd_signal()
    return df

# 백테스트 함수
def backtest(df):
    df = df.copy()
    position = 0
    entry_price = 0
    returns = []

    for i in range(1, len(df)):
        if position == 0:
            if df['RSI'].iloc[i] < 30 and df['MACD'].iloc[i] > df['MACD_signal'].iloc[i]:
                position = 1
                entry_price = df['Close'].iloc[i] * (1 + slippage/10000 + fee/10000)

        elif position == 1:
            price = df['Close'].iloc[i] * (1 - slippage/10000 - fee/10000)
            change = (price - entry_price) / entry_price * 100

            if change >= take_profit or change <= -stop_loss:
                returns.append(change / 100)
                position = 0

    total_return = np.prod([1 + r for r in returns]) - 1 if returns else 0
    return total_return, len(returns), returns

# 메인 실행
if st.button("🚀 백테스트 시작"):
    results = []
    corr_data = pd.DataFrame()

    for symbol in tqdm(symbols):
        symbol = symbol.strip()
        data = download_data(symbol, start_date, end_date)
        data = add_indicators(data)

        total_return, trades, returns = backtest(data)
        results.append({"종목": symbol, "총 수익률": f"{total_return*100:.2f}%", "거래 횟수": trades})

        data['Return'] = data['Close'].pct_change()
        corr_data[symbol] = data['Return']

    st.subheader("📊 백테스트 결과 요약")
    st.write(pd.DataFrame(results))

    st.subheader("🔥 수익률 상관관계 히트맵")
    corr = corr_data.corr()
    fig, ax = plt.subplots(figsize=(8, 6))
    sns.heatmap(corr, annot=True, cmap='coolwarm', ax=ax)
    st.pyplot(fig)

    st.success("완료! 🎉 Streamlit 앱으로 통합했습니다.")
