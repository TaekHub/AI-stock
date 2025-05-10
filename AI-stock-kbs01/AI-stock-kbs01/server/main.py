# 파일명: main.py
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import yfinance as yf
import talib
import pandas as pd
import numpy as np
from fastapi.responses import JSONResponse
import requests
from pykrx import stock
from datetime import datetime, timedelta
import json

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# 한글 종목명을 영어로 변환하기 위한 매핑 테이블
KOREAN_TO_ENGLISH = {
    "삼성전자": "Samsung Electronics",
    "현대차": "Hyundai Motor",
    "LG화학": "LG Chem",
    "SK하이닉스": "SK Hynix",
    "네이버": "Naver",
    "카카오": "Kakao",
    "현대모비스": "Hyundai Mobis",
    "기아": "Kia",
    "LG전자": "LG Electronics",
    "삼성SDI": "Samsung SDI",
}

@app.get("/tickers")
async def get_tickers(market: str = "KR"):
    try:
        if market == "KR":
            kospi_tickers = stock.get_market_ticker_list(market="KOSPI")
            kosdaq_tickers = stock.get_market_ticker_list(market="KOSDAQ")
            tickers = kospi_tickers + kosdaq_tickers
            ticker_names = [
                {"ticker": ticker, "name": stock.get_market_ticker_name(ticker)}
                for ticker in tickers
            ]
            return JSONResponse(content={"tickers": ticker_names}, media_type="application/json; charset=utf-8")
        else:
            # yfinance를 통해 US 시장 티커 목록 가져오기
            popular_us_tickers = [
                {"ticker": "AAPL", "name": "Apple Inc."},
                {"ticker": "MSFT", "name": "Microsoft Corporation"},
                {"ticker": "TSLA", "name": "Tesla Inc."},
                {"ticker": "GOOGL", "name": "Alphabet Inc."},
                {"ticker": "AMZN", "name": "Amazon.com Inc."},
            ]
            return {"tickers": popular_us_tickers}
    except Exception as e:
        print(f"❌ 티커 목록 가져오기 오류: {e}")
        return JSONResponse(status_code=500, content={"error": str(e)})

@app.get("/ticker_info")
async def get_ticker_info(ticker: str, market: str = "US"):
    try:
        if market == "KR":
            name = stock.get_market_ticker_name(ticker)
            return {"ticker": ticker, "name": name or ticker}
        else:
            ticker_obj = yf.Ticker(ticker)
            info = ticker_obj.info
            if not info or "symbol" not in info:
                print(f"Invalid Ticker: {ticker}")
                return JSONResponse(status_code=400, content={"error": f"유효하지 않은 티커: {ticker}"})
            name = info.get("longName", ticker)
            return {"ticker": ticker, "name": name}
    except Exception as e:
        print(f"❌ 티커 정보 가져오기 오류: {e}")
        return JSONResponse(status_code=500, content={"ticker": ticker, "name": ticker})

@app.get("/analyze")
async def analyze(ticker: str, market: str = "US", period: str = "3mo"):
    try:
        if market == "KR":
            end_date = datetime.today().strftime("%Y%m%d")
            start_date = (datetime.today() - timedelta(days=90)).strftime("%Y%m%d")
            df = stock.get_market_ohlcv_by_date(start_date, end_date, ticker)
            df = df.rename(columns={
                "시가": "Open",
                "고가": "High",
                "저가": "Low",
                "종가": "Close",
                "거래량": "Volume"
            })
            df.index.name = "Date"
            df.index = pd.to_datetime(df.index)
            df["Close"] = df["Close"].astype(int)
        else:
            # 티커 유효성 검사
            ticker_obj = yf.Ticker(ticker)
            info = ticker_obj.info
            if not info or "symbol" not in info:
                print(f"Invalid Ticker: {ticker}")
                return JSONResponse(status_code=400, content={"error": f"유효하지 않은 티커: {ticker}"})
            
            # yfinance로 데이터 다운로드
            df = yf.download(ticker, period=period, interval="1d")
            print(f"US Market - Ticker: {ticker}, Data Preview: {df.head()}")
            print(f"US Market - Data Length: {len(df)}")

        if df.empty:
            print(f"US Market - Empty Data for Ticker: {ticker}")
            return JSONResponse(status_code=400, content={"error": f"데이터가 비어 있습니다. 티커 {ticker}를 확인하세요."})

        print(f"US Market - Columns: {df.columns}, Index Type: {type(df.index)}")

        if isinstance(df.index, pd.MultiIndex):
            df = df.reset_index()
            if "Date" in df.columns:
                df["Date"] = pd.to_datetime(df["Date"])
                df = df.set_index("Date")
            else:
                return JSONResponse(status_code=400, content={"error": "Date 컬럼이 없습니다."})

        if isinstance(df.columns, pd.MultiIndex):
            df.columns = df.columns.get_level_values(0)

        if not isinstance(df.index, pd.DatetimeIndex):
            return JSONResponse(status_code=400, content={"error": "인덱스가 DateTimeIndex 형식이 아닙니다."})

        required_columns = ["Close", "High", "Low", "Volume"]
        missing_columns = [col for col in required_columns if col not in df.columns]
        if missing_columns:
            print(f"Missing columns for {ticker}: {missing_columns}")
            return JSONResponse(status_code=400, content={"error": f"필수 컬럼 {missing_columns}이 누락되었습니다."})

        df = df.dropna()
        if df.empty:
            return JSONResponse(status_code=400, content={"error": "NaN 값을 제거한 후 데이터가 비어 있습니다."})

        df.loc[df["Volume"] == 0, "Volume"] = 1e-6
        df["Volume"] = df["Volume"].astype(np.float64)

        print(f"데이터 길이: {len(df)}")
        if len(df) < 50:
            print(f"데이터 길이 부족: {len(df)}일 (최소 50일 권장)")

        closes = df["Close"].values.tolist()
        if market == "KR":
            closes = [int(x) for x in closes]
        volumes = df["Volume"].values.tolist()
        dates = df.index.strftime("%Y-%m-%d").tolist()
        print(f"종가 데이터: {closes}")
        print(f"거래량 데이터: {volumes}")
        print(f"날짜 데이터: {dates}")

        close = np.array(df["Close"].values, dtype=np.float64)
        high = np.array(df["High"].values, dtype=np.float64)
        low = np.array(df["Low"].values, dtype=np.float64)
        volume = df["Volume"].values.astype(np.float64)

        print(f"Close 길이: {len(close)}, High 길이: {len(high)}, Low 길이: {len(low)}, Volume 길이: {len(volume)}")

        for arr, name in [(close, "Close"), (high, "High"), (low, "Low"), (volume, "Volume")]:
            if np.any(np.isnan(arr)) or np.any(np.isinf(arr)):
                return JSONResponse(status_code=400, content={"error": f"{name} 데이터에 NaN 또는 inf 값이 포함되어 있습니다."})

        indicators = {}
        indicators_series = {}

        try:
            rsi = talib.RSI(close, timeperiod=7)
            indicators["RSI"] = float(rsi[-1]) if len(close) >= 7 else None
            indicators_series["RSI"] = [float(x) if not np.isnan(x) else None for x in rsi] if len(close) >= 7 else []
        except Exception as e:
            print(f"RSI 계산 중 오류: {e}")
            indicators["RSI"] = None
            indicators_series["RSI"] = []

        try:
            macd = talib.MACD(close, fastperiod=6, slowperiod=13, signalperiod=5)
            indicators["MACD"] = float(macd[0][-1]) if len(close) >= 13 else None
            indicators["MACD_prev"] = float(macd[0][-2]) if len(close) >= 13 else None
            indicators_series["MACD"] = [float(x) if not np.isnan(x) else None for x in macd[0]] if len(close) >= 13 else []
        except Exception as e:
            print(f"MACD 계산 중 오류: {e}")
            indicators["MACD"] = None
            indicators["MACD_prev"] = None
            indicators_series["MACD"] = []

        try:
            cci = talib.CCI(high, low, close, timeperiod=7)
            indicators["CCI"] = float(cci[-1]) if len(close) >= 7 else None
            indicators_series["CCI"] = [float(x) if not np.isnan(x) else None for x in cci] if len(close) >= 7 else []
        except Exception as e:
            print(f"CCI 계산 중 오류: {e}")
            indicators["CCI"] = None
            indicators_series["CCI"] = []

        try:
            mfi = talib.MFI(high, low, close, volume, timeperiod=14)
            indicators["MFI"] = float(mfi[-1]) if len(close) >= 14 else None
            indicators_series["MFI"] = [float(x) if not np.isnan(x) else None for x in mfi] if len(close) >= 14 else []
        except Exception as e:
            print(f"MFI 계산 중 오류: {e}")
            indicators["MFI"] = None
            indicators_series["MFI"] = []

        try:
            adx = talib.ADX(high, low, close, timeperiod=7)
            indicators["ADX"] = float(adx[-1]) if len(close) >= 7 else None
            indicators_series["ADX"] = [float(x) if not np.isnan(x) else None for x in adx] if len(close) >= 7 else []
        except Exception as e:
            print(f"ADX 계산 중 오류: {e}")
            indicators["ADX"] = None
            indicators_series["ADX"] = []

        try:
            slowk, slowd = talib.STOCH(high, low, close, fastk_period=7, slowk_period=3, slowd_period=3)
            indicators["SlowK"] = float(slowk[-1]) if len(close) >= 7 else None
            indicators["SlowD"] = float(slowd[-1]) if len(close) >= 7 else None
            indicators["SlowK_prev"] = float(slowk[-2]) if len(close) >= 7 else None
            indicators["SlowD_prev"] = float(slowd[-2]) if len(close) >= 7 else None
            indicators_series["SlowK"] = [float(x) if not np.isnan(x) else None for x in slowk] if len(close) >= 7 else []
            indicators_series["SlowD"] = [float(x) if not np.isnan(x) else None for x in slowd] if len(close) >= 7 else []
        except Exception as e:
            print(f"STOCH 계산 중 오류: {e}")
            indicators["SlowK"] = None
            indicators["SlowD"] = None
            indicators["SlowK_prev"] = None
            indicators["SlowD_prev"] = None
            indicators_series["SlowK"] = []
            indicators_series["SlowD"] = []

        try:
            sma10 = talib.SMA(close, timeperiod=10)
            sma50 = talib.SMA(close, timeperiod=50)
            indicators["SMA10"] = float(sma10[-1]) if len(close) >= 10 else None
            indicators["SMA50"] = float(sma50[-1]) if len(close) >= 50 else None
            indicators["SMA10_prev"] = float(sma10[-2]) if len(close) >= 10 else None
            indicators["SMA50_prev"] = float(sma50[-2]) if len(close) >= 50 else None
            indicators_series["SMA10"] = [float(x) if not np.isnan(x) else None for x in sma10] if len(close) >= 10 else []
            indicators_series["SMA50"] = [float(x) if not np.isnan(x) else None for x in sma50] if len(close) >= 50 else []
        except Exception as e:
            print(f"SMA 계산 중 오류: {e}")
            indicators["SMA10"] = None
            indicators["SMA50"] = None
            indicators["SMA10_prev"] = None
            indicators["SMA50_prev"] = None
            indicators_series["SMA10"] = []
            indicators_series["SMA50"] = []

        try:
            ema20 = talib.EMA(close, timeperiod=20)
            ema50 = talib.EMA(close, timeperiod=50)
            indicators["EMA20"] = float(ema20[-1]) if len(close) >= 20 else None
            indicators["EMA50"] = float(ema50[-1]) if len(close) >= 50 else None
            indicators["EMA20_prev"] = float(ema20[-2]) if len(close) >= 20 else None
            indicators["EMA50_prev"] = float(ema50[-2]) if len(close) >= 50 else None
            indicators_series["EMA20"] = [float(x) if not np.isnan(x) else None for x in ema20] if len(close) >= 20 else []
            indicators_series["EMA50"] = [float(x) if not np.isnan(x) else None for x in ema50] if len(close) >= 50 else []
        except Exception as e:
            print(f"EMA 계산 중 오류: {e}")
            indicators["EMA20"] = None
            indicators["EMA50"] = None
            indicators["EMA20_prev"] = None
            indicators["EMA50_prev"] = None
            indicators_series["EMA20"] = []
            indicators_series["EMA50"] = []

        try:
            bb_upper, _, bb_lower = talib.BBANDS(close, timeperiod=14, nbdevup=1.8, nbdevdn=1.8)
            indicators["BB_upper"] = float(bb_upper[-1]) if len(close) >= 14 else None
            indicators["BB_lower"] = float(bb_lower[-1]) if len(close) >= 14 else None
            indicators["BB_upper_prev"] = float(bb_upper[-2]) if len(close) >= 14 else None
            indicators["BB_lower_prev"] = float(bb_lower[-2]) if len(close) >= 14 else None
            indicators_series["BB_upper"] = [float(x) if not np.isnan(x) else None for x in bb_upper] if len(close) >= 14 else []
            indicators_series["BB_lower"] = [float(x) if not np.isnan(x) else None for x in bb_lower] if len(close) >= 14 else []
        except Exception as e:
            print(f"BBANDS 계산 중 오류: {e}")
            indicators["BB_upper"] = None
            indicators["BB_lower"] = None
            indicators["BB_upper_prev"] = None
            indicators["BB_lower_prev"] = None
            indicators_series["BB_upper"] = []
            indicators_series["BB_lower"] = []

        try:
            obv = talib.OBV(close, volume)
            indicators["OBV"] = float(obv[-1]) if len(close) >= 1 else None
            indicators["OBV_prev"] = float(obv[-2]) if len(close) >= 2 else None
        except Exception as e:
            print(f"OBV 계산 중 오류: {e}")
            indicators["OBV"] = None
            indicators["OBV_prev"] = None

        try:
            atr = talib.ATR(high, low, close, timeperiod=14)
            indicators["ATR"] = float(atr[-1]) if len(close) >= 14 else None
        except Exception as e:
            print(f"ATR 계산 중 오류: {e}")
            indicators["ATR"] = None

        indicators["Close"] = int(close[-1]) if len(close) >= 1 and market == "KR" else float(close[-1]) if len(close) >= 1 else None
        indicators["Close_prev"] = int(close[-2]) if len(close) >= 2 and market == "KR" else float(close[-2]) if len(close) >= 2 else None

        indicators = {
            k: round(v, 3) if v is not None and not np.isnan(v) and k not in ["Close", "Close_prev"] else v
            for k, v in indicators.items()
        }

        return {
            "dates": dates,
            "closes": closes,
            "volumes": volumes,
            "indicators": indicators,
            "indicators_series": indicators_series
        }

    except Exception as e:
        print(f"❌ 데이터 분석 중 오류 발생: {e}")
        return JSONResponse(status_code=500, content={"error": str(e)})

@app.get("/news")
async def get_news(ticker: str, market: str = "US"):
    try:
        query = ticker
        if market == "KR":
            korean_name = stock.get_market_ticker_name(ticker) or ticker
            query = f"{korean_name} 뉴스"
            print(f"KR 종목명: {korean_name}, 검색 쿼리: {query}")
        else:
            query = f"{ticker} news"

        url = "https://openapi.naver.com/v1/search/news.json"
        headers = {
            "X-Naver-Client-Id": "hGsBkHMZAIdA274Yf1HM",
            "X-Naver-Client-Secret": "DATh9ARioQ"
        }
        params = {
            "query": query,
            "display": 5,
            "sort": "date"
        }

        response = requests.get(url, headers=headers, params=params)
        if response.status_code != 200:
            print(f"❌ 네이버 뉴스 API 요청 실패: {response.status_code}")
            return {"news": []}

        data = response.json()
        articles = data.get('items', [])

        news_list = [
            {
                "title": article['title'],
                "link": article['link'],
                "pubDate": article['pubDate']
            }
            for article in articles
        ]

        return {"news": news_list}

    except Exception as e:
        print(f"❌ 뉴스 데이터 가져오기 오류: {e}")
        return {"news": []}

@app.get("/compare")
async def compare(ticker: str, market: str = "US"):
    try:
        tickers = [ticker, "^KS11", "^IXIC"]
        changes = {}

        for t in tickers:
            if t == ticker and market == "KR":
                end_date = datetime.today().strftime("%Y%m%d")
                start_date = (datetime.today() - timedelta(days=90)).strftime("%Y%m%d")
                df = stock.get_market_ohlcv_by_date(start_date, end_date, t)
                df = df.rename(columns={"종가": "Close"})
                df["Close"] = df["Close"].astype(int)
            else:
                df = yf.download(t, period="3mo", interval="1d")
            
            if df.empty:
                print(f"Empty data for {t} in compare endpoint")
                changes[t] = 0.0
                continue

            first_close = df["Close"].iloc[0]
            last_close = df["Close"].iloc[-1]
            change = ((last_close - first_close) / first_close) * 100
            changes[t] = round(float(change), 2)

        result = {
            ticker: changes[ticker],
            "KOSPI": changes["^KS11"],
            "NASDAQ": changes["^IXIC"]
        }

        return result

    except Exception as e:
        print(f"❌ 변동률 비교 중 오류 발생: {e}")
        return JSONResponse(status_code=500, content={"error": str(e)})