import os

# 필요한 패키지 목록
packages = [
    "yfinance",
    "mysql-connector-python",
    "pandas",
    "numpy",
    "scikit-learn",
    "ta-lib",
    "tensorflow",
    "keras",
    "matplotlib",
    "flask",
    "fastapi",
    "uvicorn"
]

# 패키지 설치
for package in packages:
    os.system(f"pip install {package}")

print("✅ 모든 필수 패키지 설치 완료!")
