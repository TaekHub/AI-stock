# AI-stock

아나콘다 프롬프트에서 가상환경을 만들고 

conda activate 가상환경이름
cd %USERPROFILE%\test01\server
입력한후 main.py랑 연동하기위해서

docker desktop설치한 후
redis를 연동하기위해
docker run -d --name redis-server -p 6379:6379 redis
입력하여 docker container에 나오는지 확인해야 합니다.(컴퓨터 재부팅 후 다시 실행할때는 docker desktop에서 삭제하고 다시 docker run ~ 명령줄 입력하셔야 합니다)
아나콘다 프롬프트에서 uvicorn main:app --host 0.0.0.0 --port 8000 --reload 입력하시고 
안드로이드 스튜디오에서 flutter run 하시면 실행됩니다
현재는 usb 디버깅 통해서 테스트 중입니다.

주로 pubspec.yaml 과 server 폴더의 main.py, C:\Users\사용자이름\test01\android\app\src\main 폴더안에 AndroidManifest,
그리고 lib 폴더안에 있는 dart 파일들을 수정해서 사용합니다.
api.dart안에 있는 baseurl은 제 노트북 ip주소이므로 수정하셔야 합니다.

pubspec.yaml 수정 후에는 flutter pub get을 꼭 해주셔야합니다
