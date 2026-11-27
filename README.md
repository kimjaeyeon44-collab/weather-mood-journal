# 🌤️ 우리 동네 날씨 & 오늘의 기분 기록장

Flutter Web과 Firebase, Open-Meteo 무료 날씨 API를 연동하여 구현한 개인 맞춤형 날씨 및 기분 기록 웹 애플리케이션입니다.

## 🔗 배포 링크
- **GitHub Pages 라이브 링크:** https://github.com/kimjaeyeon44-collab/weather-mood-journal.git

## 📡 사용한 Open API
- **API명:** Open-Meteo Free Weather Forecast API (인증키 불필요)
- **호출 엔드포인트:** `https://api.open-meteo.com/v1/forecast?latitude=위도&longitude=경도&current_weather=true`

## 🔑 테스트용 계정
- **ID (이메일):** `test@example.com`
- **PW (비밀번호):** `123456`

## 📸 실행 화면 캡처

### 1. Firebase 이메일/비밀번호 로그인 화면
![로그인 화면](screenshots/login.png)

### 2. 실시간 날씨 조회 및 Firestore 기분 기록 화면
![메인 화면](screenshots/main.png)