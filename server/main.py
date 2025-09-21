from fastapi import FastAPI, Request, HTTPException
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
import redis
import logging
from bs4 import BeautifulSoup
from pandas_datareader import data as pdr
import firebase_admin
from firebase_admin import credentials, firestore

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

# Firebase 초기화
try:
    cred = credentials.Certificate('C:/Users/kbs01/AndroidStudioProjects/stock_analysis_app/stock-analysis-623ae-firebase-adminsdk-fbsvc-83459e76aa.json')  # 실제 서비스 계정 키 경로로 변경
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    logger.info("Firebase initialized successfully")
except Exception as e:
    logger.error(f"Failed to initialize Firebase: {e}")

# Redis 클라이언트 설정
try:
    redis_client = redis.Redis(
        host='localhost',
        port=6379,
        db=0,
        decode_responses=True,
        socket_timeout=5,
        socket_connect_timeout=5,
        retry_on_timeout=True
    )
    redis_client.ping()
    logger.info("Successfully connected to Redis")
except redis.ConnectionError as e:
    logger.error(f"Failed to connect to Redis: {e}")
    redis_client = None

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

# ---------- 야후 우회용 세션 ----------
def _make_requests_session(timeout: int = 10) -> requests.Session:
    s = requests.Session()
    s.headers.update({
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                      "AppleWebKit/537.36 (KHTML, like Gecko) "
                      "Chrome/124.0.0.0 Safari/537.36",
        "Accept": "*/*",
        "Accept-Language": "en-US,en;q=0.9",
        "Connection": "keep-alive",
    })
    return s

# ---------- US 주식 OHLC 다운로더 (다단계 폴백) ----------
def fetch_us_ohlc(ticker: str, period: str = "3mo", interval: str = "1d") -> pd.DataFrame:
    """yfinance -> 기간확대 재시도 -> Stooq(pandas-datareader) -> Stooq CSV 순서로 시도"""
    try:
        sess = _make_requests_session()
        df = yf.download(
            ticker,
            period=period,
            interval=interval,
            auto_adjust=True,
            progress=False,
            threads=False,
            session=sess,
            timeout=12,
        )
        if df is not None and not df.empty:
            return df
        df = yf.download(
            ticker,
            period="1y",
            interval=interval,
            auto_adjust=True,
            progress=False,
            threads=False,
            session=sess,
            timeout=12,
        )
        if df is not None and not df.empty:
            return df
    except Exception as e:
        logger.warning(f"yfinance 1차 경로 실패({ticker}): {e}")

    try:
        end_date = datetime.today()
        start_date = end_date - timedelta(days=90 if period == "3mo" else 365)
        df = pdr.get_data_stooq(ticker, start=start_date, end=end_date)
        if df is not None and not df.empty:
            return df
    except Exception as e:
        logger.warning(f"Stooq pandas-datareader 실패({ticker}): {e}")

    try:
        csv_url = f"https://stooq.com/q/d/l/?s={ticker}&i=d"
        df = pd.read_csv(csv_url)
        df["Date"] = pd.to_datetime(df["Date"])
        df.set_index("Date", inplace=True)
        if df is not None and not df.empty:
            return df
    except Exception as e:
        logger.error(f"Stooq CSV 다운로드 실패({ticker}): {e}")

    logger.error(f"모든 경로에서 데이터 가져오기 실패({ticker})")
    return pd.DataFrame()

# ---------- 한국 주식 OHLC 다운로더 (pykrx) ----------
def fetch_kr_ohlc(ticker: str, period: str = "3mo", interval: str = "1d") -> pd.DataFrame:
    try:
        end_date = datetime.today()
        days = 90 if period == "3mo" else 365
        start_date = (end_date - timedelta(days=days)).strftime("%Y%m%d")
        end_date = end_date.strftime("%Y%m%d")
        df = stock.get_market_ohlcv_by_date(start_date, end_date, ticker)
        df = df.rename(columns={"시가": "Open", "고가": "High", "저가": "Low", "종가": "Close", "거래량": "Volume"})
        df.index = pd.to_datetime(df.index)
        df["Close"] = df["Close"].astype(float)
        df["Volume"] = df["Volume"].astype(float)
        return df
    except Exception as e:
        logger.error(f"pykrx 데이터 가져오기 실패({ticker}): {e}")
        return pd.DataFrame()

# ---------- 지표 계산기 ----------
def calculate_indicators(df: pd.DataFrame):
    indicators = {}
    indicators_series = {}
    try:
        if df.empty or len(df) < 14:  # 최소 14일 데이터 필요
            logger.warning("지표 계산을 위한 데이터 부족")
            return indicators, indicators_series

        # RSI
        rsi = talib.RSI(df["Close"], timeperiod=14)
        indicators["RSI"] = float(rsi.iloc[-1]) if not rsi.empty and not np.isnan(rsi.iloc[-1]) else None
        indicators_series["RSI"] = [float(x) if not np.isnan(x) else None for x in rsi.tolist()]

        # MACD
        macd, macd_signal, macd_hist = talib.MACD(df["Close"], fastperiod=12, slowperiod=26, signalperiod=9)
        indicators["MACD"] = float(macd.iloc[-1]) if not macd.empty and not np.isnan(macd.iloc[-1]) else None
        indicators["MACD_prev"] = float(macd.iloc[-2]) if len(macd) > 1 and not np.isnan(macd.iloc[-2]) else None
        indicators_series["MACD"] = [float(x) if not np.isnan(x) else None for x in macd.tolist()]

        # CCI
        cci = talib.CCI(df["High"], df["Low"], df["Close"], timeperiod=14)
        indicators["CCI"] = float(cci.iloc[-1]) if not cci.empty and not np.isnan(cci.iloc[-1]) else None
        indicators_series["CCI"] = [float(x) if not np.isnan(x) else None for x in cci.tolist()]

        # MFI
        mfi = talib.MFI(df["High"], df["Low"], df["Close"], df["Volume"], timeperiod=14)
        indicators["MFI"] = float(mfi.iloc[-1]) if not mfi.empty and not np.isnan(mfi.iloc[-1]) else None
        indicators_series["MFI"] = [float(x) if not np.isnan(x) else None for x in mfi.tolist()]

        # ADX
        adx = talib.ADX(df["High"], df["Low"], df["Close"], timeperiod=14)
        indicators["ADX"] = float(adx.iloc[-1]) if not adx.empty and not np.isnan(adx.iloc[-1]) else None
        indicators_series["ADX"] = [float(x) if not np.isnan(x) else None for x in adx.tolist()]

        # Stochastic
        slowk, slowd = talib.STOCH(df["High"], df["Low"], df["Close"], fastk_period=14, slowk_period=3, slowd_period=3)
        indicators["SlowK"] = float(slowk.iloc[-1]) if not slowk.empty and not np.isnan(slowk.iloc[-1]) else None
        indicators["SlowD"] = float(slowd.iloc[-1]) if not slowd.empty and not np.isnan(slowd.iloc[-1]) else None
        indicators["SlowK_prev"] = float(slowk.iloc[-2]) if len(slowk) > 1 and not np.isnan(slowk.iloc[-2]) else None
        indicators["SlowD_prev"] = float(slowd.iloc[-2]) if len(slowd) > 1 and not np.isnan(slowd.iloc[-2]) else None
        indicators_series["SlowK"] = [float(x) if not np.isnan(x) else None for x in slowk.tolist()]
        indicators_series["SlowD"] = [float(x) if not np.isnan(x) else None for x in slowd.tolist()]

        # SMA
        sma10 = talib.SMA(df["Close"], timeperiod=10)
        sma50 = talib.SMA(df["Close"], timeperiod=50)
        indicators["SMA10"] = float(sma10.iloc[-1]) if not sma10.empty and not np.isnan(sma10.iloc[-1]) else None
        indicators["SMA50"] = float(sma50.iloc[-1]) if not sma50.empty and not np.isnan(sma50.iloc[-1]) else None
        indicators["SMA10_prev"] = float(sma10.iloc[-2]) if len(sma10) > 1 and not np.isnan(sma10.iloc[-2]) else None
        indicators["SMA50_prev"] = float(sma50.iloc[-2]) if len(sma50) > 1 and not np.isnan(sma50.iloc[-2]) else None
        indicators_series["SMA10"] = [float(x) if not np.isnan(x) else None for x in sma10.tolist()]
        indicators_series["SMA50"] = [float(x) if not np.isnan(x) else None for x in sma50.tolist()]

        # EMA
        ema20 = talib.EMA(df["Close"], timeperiod=20)
        ema50 = talib.EMA(df["Close"], timeperiod=50)
        indicators["EMA20"] = float(ema20.iloc[-1]) if not ema20.empty and not np.isnan(ema20.iloc[-1]) else None
        indicators["EMA50"] = float(ema50.iloc[-1]) if not ema50.empty and not np.isnan(ema50.iloc[-1]) else None
        indicators["EMA20_prev"] = float(ema20.iloc[-2]) if len(ema20) > 1 and not np.isnan(ema20.iloc[-2]) else None
        indicators["EMA50_prev"] = float(ema50.iloc[-2]) if len(ema50) > 1 and not np.isnan(ema50.iloc[-2]) else None
        indicators_series["EMA20"] = [float(x) if not np.isnan(x) else None for x in ema20.tolist()]
        indicators_series["EMA50"] = [float(x) if not np.isnan(x) else None for x in ema50.tolist()]

        # Bollinger Bands
        upper, middle, lower = talib.BBANDS(df["Close"], timeperiod=20, nbdevup=2, nbdevdn=2)
        indicators["BB_upper"] = float(upper.iloc[-1]) if not upper.empty and not np.isnan(upper.iloc[-1]) else None
        indicators["BB_lower"] = float(lower.iloc[-1]) if not lower.empty and not np.isnan(lower.iloc[-1]) else None
        indicators["close"] = float(df["Close"].iloc[-1]) if not df["Close"].empty else None
        indicators_series["BB_upper"] = [float(x) if not np.isnan(x) else None for x in upper.tolist()]
        indicators_series["BB_lower"] = [float(x) if not np.isnan(x) else None for x in lower.tolist()]

        logger.info(f"Calculated indicators: {indicators}")
        logger.info(f"Indicators series lengths: { {k: len(v) for k, v in indicators_series.items()} }")

    except Exception as e:
        logger.error(f"지표 계산 오류: {e}")

    return indicators, indicators_series

# ---------- 티커 목록 가져오기 ----------
@app.get("/tickers")
async def get_tickers(market: str = "US"):
    cache_key = f"tickers_{market}"
    if redis_client:
        try:
            cached = redis_client.get(cache_key)
            if cached:
                return json.loads(cached)
        except redis.RedisError as e:
            logger.error(f"Redis error: {e}")

    try:
        if market == "US":
            symbols = ["AAPL", "MSFT", "GOOGL", "AMZN", "TSLA", "NVDA", "META", "JPM", "WMT", "V"]
            tickers = [
                {"ticker": symbol, "name": yf.Ticker(symbol).info.get("longName", symbol)}
                for symbol in symbols
            ]
        else:
            symbols = ["005930", "035720", "000660", "035420", "005380"]
            tickers = [
                {"ticker": symbol, "name": KOREAN_TO_ENGLISH.get(stock.get_market_ticker_name(symbol), symbol)}
                for symbol in symbols
            ]

        if redis_client:
            try:
                redis_client.setex(cache_key, 3600, json.dumps({"tickers": tickers}))
                logger.info(f"Tickers cached for {cache_key}")
            except redis.RedisError as e:
                logger.error(f"Redis error while caching tickers: {e}")

        return {"tickers": tickers}

    except Exception as e:
        logger.error(f"❌ 티커 목록 가져오기 오류: {e}")
        return {"tickers": []}

# ---------- 종목 분석 ----------
@app.get("/analyze")
async def analyze(ticker: str, market: str = "US", period: str = "3mo", interval: str = "1d"):
    cache_key = f"stock_{ticker}_{market}_{period}_{interval}"
    if redis_client:
        try:
            cached = redis_client.get(cache_key)
            if cached:
                return json.loads(cached)
        except redis.RedisError as e:
            logger.error(f"Redis error: {e}")

    try:
        if market == "US":
            df = fetch_us_ohlc(ticker, period, interval)
        else:
            df = fetch_kr_ohlc(ticker, period, interval)

        if df.empty:
            logger.error(f"Empty DataFrame for {ticker} ({market})")
            return {"error": "No data available"}

        dates = df.index.strftime("%Y-%m-%d").tolist()
        closes = df["Close"].tolist()
        volumes = df["Volume"].tolist()

        indicators, indicators_series = calculate_indicators(df)

        result = {
            "dates": dates,
            "closes": closes,
            "volumes": volumes,
            "indicators": {k: v for k, v in indicators.items() if v is not None},
            "indicatorsSeries": {k: v for k, v in indicators_series.items() if v and any(x is not None for x in v)},
        }

        # Firestore에 저장
        try:
            db.collection('stocks').document(f"{market}-{ticker}").set({
                'dates': dates,
                'closes': closes,
                'volumes': volumes,
                'indicators': {k: v for k, v in indicators.items() if v is not None},
                'indicatorsSeries': {k: v for k, v in indicators_series.items() if v and any(x is not None for x in v)},
                'updatedAt': datetime.utcnow().isoformat(),
            })
            logger.info(f"Saved stock data to Firestore for {market}-{ticker}")
        except Exception as e:
            logger.error(f"Failed to save stock data to Firestore for {market}-{ticker}: {e}")

        if redis_client:
            try:
                redis_client.setex(cache_key, 1800, json.dumps(result))
                logger.info(f"Data cached for {cache_key}")
            except redis.RedisError as e:
                logger.error(f"Redis error while caching data: {e}")

        logger.info(f"Analyze result for {ticker} ({market}): indicators={result['indicators']}")
        return result

    except Exception as e:
        logger.error(f"❌ 분석 중 오류 발생: {e}")
        return JSONResponse(status_code=500, content={"error": str(e)})

# ---------- 뉴스 가져오기 ----------
@app.get("/news")
async def get_news(ticker: str, market: str = "US", start: int = 1, display: int = 10):
    cache_key = f"news_{ticker}_{market}_{start}_{display}"
    if redis_client:
        try:
            cached = redis_client.get(cache_key)
            if cached:
                return json.loads(cached)
        except redis.RedisError as e:
            logger.error(f"Redis error: {e}")

    try:
        articles = []
        total = 0
        if market == "KR":
            # 네이버 뉴스 API 사용
            client_id = "hGsBkHMZAIdA274Yf1HM"  # 네이버 개발자 센터에서 발급
            client_secret = "DATh9ARioQ"  # 네이버 개발자 센터에서 발급
            query = KOREAN_TO_ENGLISH.get(stock.get_market_ticker_name(ticker), ticker)
            url = "https://openapi.naver.com/v1/search/news.json"
            headers = {
                "X-Naver-Client-Id": client_id,
                "X-Naver-Client-Secret": client_secret,
            }
            params = {
                "query": query,
                "start": start,
                "display": display,
                "sort": "date",
            }
            response = requests.get(url, headers=headers, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            articles = [
                {
                    "title": item.get("title", "제목 없음").replace('<b>', '').replace('</b>', ''),
                    "url": item.get("link", ""),
                    "pubDate": item.get("pubDate", ""),
                }
                for item in data.get("items", [])
            ]
            total = data.get("total", 0)
            logger.info(f"Naver news API response for {ticker}: {len(articles)} articles, total={total}")
        else:
            # 야후 뉴스 크롤링
            query = yf.Ticker(ticker).info.get("longName", ticker).replace(' ', '+')
            url = f"https://news.search.yahoo.com/search?p={query}&b={start}&pz={display}"
            headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.9",
                "Accept-Encoding": "gzip, deflate, br",
                "Connection": "keep-alive",
                "Upgrade-Insecure-Requests": "1",
            }
            response = requests.get(url, headers=headers, timeout=10)
            response.raise_for_status()
            soup = BeautifulSoup(response.text, 'html.parser')
            news_items = soup.select('div.news-card')[:display]  # 2025년 기준 클래스 확인 필요
            for item in news_items:
                title_elem = item.select_one('h4.s-title > a')
                date_elem = item.select_one('span.s-time')
                title = title_elem.text.strip() if title_elem else "제목 없음"
                url = title_elem['href'] if title_elem and title_elem.get('href') else ""
                date = date_elem.text.strip() if date_elem else "날짜 없음"
                articles.append({
                    "title": title,
                    "url": url,
                    "pubDate": date,
                })
            total = 100  # 추정치, 실제 파싱 필요 시 수정
            logger.info(f"Yahoo news scraped for {ticker}: {len(articles)} articles")

        positive_keywords = ["growth", "surge", "rise", "bullish", "profit", "상승", "성장", "호재"]
        negative_keywords = ["drop", "decline", "bearish", "loss", "crash", "하락", "악재"]
        news_list = [
            {
                "title": article.get("title", "제목 없음"),
                "url": article.get("url", ""),
                "pubDate": article.get("pubDate", ""),
                "sentiment": (
                    "긍정" if any(keyword in article.get('title', '').lower() for keyword in positive_keywords) and
                    not any(keyword in article.get('title', '').lower() for keyword in negative_keywords) else
                    "부정" if any(keyword in article.get('title', '').lower() for keyword in negative_keywords) and
                    not any(keyword in article.get('title', '').lower() for keyword in positive_keywords) else
                    "중립"
                ),
                "color": (
                    "#00FF00" if any(keyword in article.get('title', '').lower() for keyword in positive_keywords) and
                    not any(keyword in article.get('title', '').lower() for keyword in negative_keywords) else
                    "#FF0000" if any(keyword in article.get('title', '').lower() for keyword in negative_keywords) and
                    not any(keyword in article.get('title', '').lower() for keyword in positive_keywords) else
                    "#FFFF00"
                )
            }
            for article in articles
        ]

        if redis_client:
            try:
                redis_client.setex(cache_key, 1800, json.dumps({"news": news_list, "total": total}))
                logger.info(f"Data cached for {cache_key}")
            except redis.RedisError as e:
                logger.error(f"Redis error while caching data: {e}")

        return {"news": news_list, "total": total}

    except Exception as e:
        logger.error(f"❌ 뉴스 데이터 가져오기 오류: {e}")
        return {"news": [], "total": 0}

# ---------- 변동률 비교 ----------
@app.get("/compare")
async def compare(ticker: str, market: str = "US"):
    try:
        tickers = [ticker, "^KS11", "^IXIC"]
        changes = {}

        for t in tickers:
            if t == ticker and market == "KR":
                end_date = datetime.today().strftime("%Y%m%d")
                start_date = (datetime.today() - timedelta(days=90)).strftime("%Y%m%d")
                try:
                    df = stock.get_market_ohlcv_by_date(start_date, end_date, t)
                    df = df.rename(columns={"종가": "Close"})
                    df["Close"] = df["Close"].astype(float)
                except Exception as e:
                    logger.error(f"pykrx 데이터 가져오기 실패 for {t}: {e}")
                    changes[t] = 0.0
                    continue
            else:
                try:
                    df = yf.download(t, period="3mo", interval="1d")
                except Exception as e:
                    logger.error(f"yfinance 데이터 가져오기 실패 for {t}: {e}")
                    changes[t] = 0.0
                    continue

            if df.empty:
                logger.error(f"Empty data for {t} in compare endpoint")
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
        logger.error(f"❌ 변동률 비교 중 오류 발생: {e}")
        return JSONResponse(status_code=500, content={"error": str(e)})

# ---------- 종목 정보 가져오기 ----------
@app.get("/ticker_info")
async def get_ticker_info(ticker: str, market: str = "US"):
    cache_key = f"ticker_info_{ticker}_{market}"
    if redis_client:
        try:
            cached = redis_client.get(cache_key)
            if cached:
                return json.loads(cached)
        except redis.RedisError as e:
            logger.error(f"Redis error: {e}")

    try:
        if market == "US":
            info = yf.Ticker(ticker).info
            name = info.get("longName", ticker)
        else:
            name = KOREAN_TO_ENGLISH.get(stock.get_market_ticker_name(ticker), ticker)

        result = {"name": name}

        if redis_client:
            try:
                redis_client.setex(cache_key, 3600, json.dumps(result))
                logger.info(f"Ticker info cached for {cache_key}")
            except redis.RedisError as e:
                logger.error(f"Redis error while caching ticker info: {e}")

        return result

    except Exception as e:
        logger.error(f"❌ 종목 정보 가져오기 오류: {e}")
        return {"name": ticker}