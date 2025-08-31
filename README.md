먼저 현재 사용하고 있는 컨퓨터나 노트북의 ip 주소가 필요합니다.

이 ip 주소는 api.dart에 baseUrl 에 본인 노트북의 ip 주소를 변경하시면 됩니다.

아나콘다 프롬프트에서 이 프로젝트 폴더의 main.py 파일이 있는 경로로 설정이 되어야합니다.

제 기준에서 말씀드리면 저는 stock-env 라는 가상환경을 사용하고 있기때문에 먼저 가상환경에서 
> ```
> conda active stock-env
> cd %USERPROFILE%\AndroidStudioProjects\stock_analysis_app\server
> ```

로 이동을 합니다. 현재 실행하기 위해서는 docker desktop을 설치가 필요합니다.

설치하였다면 docker desktop에서 사용되어지고 있는 redis 서버가 있는지 확인하고

redis 서버가 있다면 삭제, 없다면 아까 아나콘다 프롬프트에서 이동한 경로에 

> ```
> docker run -d --name redis-server -p 6379:6379 redis
> ```

를 입력하여 redis server를 켜줍니다.

여기까지 완료하셨다면 

> ```
> uvicorn main:app --host 0.0.0.0 --port 8000 --reload
> ```

입력하시고 아나콘다 프롬프트창에서 연결성공했다고 글이 나오게 되면

안드로이드 스튜디오에서 각자 선택한 기기를 통해 실행하시면 됩니다.

--------------------

현재 제가 겪고 있는 문제는 

```bash
├── stock_analysis_app
│   ├── android
│       ├── app
│           ├── build.gradle.kts
|
|
│       ├── build.gradle.kts
│       ├── settings.gradle.kts


```
firebase와 이 앱을 연결시키기 위한 방법을 진행하다가 
이렇게 3개의 파일에서 각종 오류가 발생한 것 입니다.
