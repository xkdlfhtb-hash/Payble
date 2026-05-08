Payble Survey 업데이트 적용 방법

1. ZIP 압축 해제
2. GitHub 저장소 최상단에 아래 파일을 덮어쓰기
   - index.html
   - survey.html
   - supabase_survey_auth_schema.sql
   - README_SURVEY_AUTH.txt

3. Supabase SQL Editor에서 supabase_survey_auth_schema.sql 전체 실행
   - Dashboard → SQL Editor → New query → 붙여넣기 → Run

4. Supabase Auth 설정 확인
   - Authentication → Providers → Email 활성화
   - 이메일 확인을 쓰는 경우, 사용자가 가입 후 메일 확인 필요
   - Site URL에 Netlify 주소 입력 권장
     예: https://payble-salary.netlify.app

5. GitHub Desktop에서 Commit → Push origin

6. 접속
   - 메인: https://payble-salary.netlify.app
   - 설문 제작: https://payble-salary.netlify.app/survey.html

운영 구조
- 설문 작성자: 로그인 필요, 자기 설문만 관리/응답 조회 가능
- 설문 응답자: 로그인 없이 응답 가능
- 서버 직접 구축 필요 없음: Netlify + Supabase로 동작
