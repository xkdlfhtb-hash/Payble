Payble 운영자 수정 기능 안내

이 패키지는 운영자만 사이트 문구와 계산 기준값을 수정할 수 있도록 Decap CMS + Netlify Identity + Git Gateway 구조를 포함합니다.

중요:
1. HTML 안에 비밀번호를 넣는 방식은 안전하지 않습니다.
2. 운영자 전용 수정 기능을 실제로 쓰려면 Netlify Drop이 아니라 GitHub 저장소와 연결한 Netlify 배포가 필요합니다.
3. Netlify에서 Identity를 켜고, Git Gateway를 켠 뒤, 본인 이메일만 초대하면 /admin 접속 시 운영자만 수정할 수 있습니다.

배포 순서:
1. 이 폴더 전체를 GitHub 저장소에 업로드합니다.
2. Netlify에서 GitHub 저장소를 연결해 사이트를 배포합니다.
3. Netlify 대시보드 > Project configuration > Identity에서 Identity를 Enable 합니다.
4. Registration preferences를 Invite only로 설정합니다.
5. Identity > Services > Git Gateway에서 Enable Git Gateway를 선택합니다.
6. Identity Users에서 본인 이메일만 Invite 합니다.
7. 배포된 사이트 주소 뒤에 /admin 을 붙여 접속합니다.
   예: https://your-site.netlify.app/admin
8. 로그인 후 '사이트 문구·계산 데이터 관리'에서 수정하고 Publish 하면 GitHub에 커밋되고 Netlify가 자동 재배포합니다.

운영자가 수정 가능한 항목:
- 사이트명, 상단 문구, 히어로 문구, 하단 문구
- 실질 연봉/기대 연봉 출처 문구
- 나이대 기준 연봉
- 학력 배율
- 경력 배율
- 전국 대비 백분위 구간
- 직종별 기준 연봉
- 회사 규모 기준 연봉
- 실질 연봉 보정 항목과 선택지
- 댓글 주제

주의:
- 실질 연봉 보정 항목의 id는 기존 id를 유지하는 것이 안전합니다.
- 직종 key나 회사규모 value를 바꾸면 기존 저장 데이터와 다르게 보일 수 있으니, 되도록 label과 금액만 수정하세요.
- data/payble-config.json 파일이 없거나 잘못된 JSON이면 사이트는 내장 기본값으로 동작합니다.
