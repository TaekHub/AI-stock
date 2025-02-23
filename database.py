import mysql.connector

# MySQL 연결 설정
def connect_db():
    return mysql.connector.connect(
        host="localhost",   # MySQL 서버 주소
        user="root",        # MySQL 사용자 이름
        password="0000",    # MySQL 비밀번호 (사용자에 맞게 수정)
        database="stock_trading"  # 사용할 데이터베이스
    )

# 데이터 삽입 함수
def insert_stock_data(data):
    db = connect_db()
    cursor = db.cursor()

    sql = """
    INSERT INTO stock_data (date, open_price, high_price, low_price, close_price, volume)
    VALUES (%s, %s, %s, %s, %s, %s)
    """
    cursor.executemany(sql, data)
    db.commit()

    cursor.close()
    db.close()

    print(f"✅ {len(data)}개의 데이터 삽입 완료!")
