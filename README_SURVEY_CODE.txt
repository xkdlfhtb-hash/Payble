Payble Survey — 관리 코드 방식 설문 플랫폼

이 버전은 회원가입/로그인 없이 설문 작성자가 직접 설정한 관리 코드로 설문을 관리합니다.

구성 파일
- index.html : Payble 메인 페이지
- survey.html : 무료 설문 제작/응답/관리 페이지
- supabase_survey_code_schema.sql : Supabase 설문 테이블과 RPC 함수 생성 SQL
- README_SURVEY_CODE.txt : 적용 안내

적용 순서
1. 이 ZIP의 파일을 GitHub 저장소 최상단에 덮어쓰기
2. GitHub Desktop에서 Commit to main → Push origin
3. Netlify 자동 배포 확인
4. Supabase → SQL Editor → supabase_survey_code_schema.sql 전체 실행
5. https://payble-salary.netlify.app/survey.html 접속 후 테스트

사용 방식
- 설문 작성자는 설문 제목/질문을 만들고 관리 코드를 직접 입력한 뒤 저장합니다.
- 저장 후 생성되는 응답 링크와 설문 ID를 복사해 보관합니다.
- 설문 수정/삭제/응답 확인은 "설문 관리" 탭에서 설문 ID와 관리 코드를 입력해야 가능합니다.
- 응답자는 로그인 없이 응답 링크로 참여할 수 있습니다.

주의사항
- 관리 코드는 Payble에서 복구할 수 없습니다.
- 설문 ID와 관리 코드를 잃어버리면 수정, 삭제, 응답 확인이 어렵습니다.
- 관리 코드가 유출되면 타인이 설문을 수정할 수 있으므로 길고 예측하기 어려운 코드를 사용하세요.
- 이 방식은 로그인보다 간편하지만, 최고 수준의 보안이 필요한 연구/기관 설문에는 회원 로그인 방식이 더 안전합니다.

Supabase
- 기존 댓글용 Supabase 프로젝트를 그대로 사용할 수 있습니다.
- SQL은 한 번만 실행하면 됩니다.
- 기존 Auth 기반 설문 테이블과 별개로 payble_code_surveys / payble_code_survey_responses 테이블을 사용합니다.

PDF 보관증 기능
- 설문 저장 성공 후 "PDF 보관증 저장" 버튼이 표시됩니다.
- 보관증에는 설문 제목, 설명, 설문 ID, 관리 코드, 응답 링크, 질문 구성이 함께 표시됩니다.
- 브라우저 인쇄창에서 "PDF로 저장"을 선택해 파일로 저장할 수 있습니다.
- 관리 탭에서도 설문 ID와 관리 코드를 입력한 뒤 "PDF 보관증" 버튼으로 다시 만들 수 있습니다.
