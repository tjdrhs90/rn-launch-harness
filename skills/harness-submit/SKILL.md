# harness-submit — Phase 9: 스토어 제출

App Store Connect API와 Google Play Developer API를 사용하여 앱을 스토어에 제출한다.

## Trigger

오케스트레이터에서 Phase 9로 호출됨.

## Input

- `docs/harness/config.md` (API 키 설정)
- `docs/harness/handoff/build-result.md` (빌드 결과)
- `docs/harness/store-assets/` (스크린샷 + 메타데이터)

## Process

### Part A: iOS — App Store 제출 (완전 자동)

#### A-1: API 키 확인

`config.md`에서 확인:
- `ios.asc_api_key_id` — Key ID
- `ios.asc_issuer_id` — Issuer ID  
- `ios.asc_private_key_path` — .p8 파일 경로

비어있으면 AskUserQuestion:
```
App Store Connect API Key가 필요합니다.

1. App Store Connect → Users and Access → Integrations → API Keys
2. 새 키 생성 (Admin 권한)
3. 다음 정보를 입력해주세요:

   Key ID: 
   Issuer ID: 
   .p8 파일 경로: 

(이미 EAS에 설정되어 있다면 "eas" 입력)
```

#### A-2: EAS Submit (빌드 업로드)

```bash
eas submit --platform ios --profile production --non-interactive
```

또는 빌드 URL 직접 지정:
```bash
eas submit --platform ios --url [빌드URL] --non-interactive
```

#### A-3: App Store Connect API로 메타데이터 설정

EAS Submit이 빌드 업로드를 처리하므로, 추가 메타데이터는 ASC API로:

1. **앱 정보 확인/생성**
   - Bundle ID가 이미 등록되어 있는지 확인
   - 없으면 API로 Bundle ID 등록 + 앱 레코드 생성

2. **버전 생성**
   - 새 앱 스토어 버전 생성 (1.0.0)

3. **앱 정보 설정**
   - 기본 로케일: `ko` (한국어)
   - primaryCategory 설정
   - 개인정보처리방침 URL (config.md의 developer.privacy_url)

4. **로컬라이제이션 설정**
   - 앱 이름, 설명, 키워드, 부제
   - What's New (신규 출시는 생략 가능)
   - 마케팅 URL (config.md의 developer.homepage_url)
   - 지원 URL (config.md의 developer.privacy_url)

5. **저작권 설정**
   - config.md의 developer.copyright 사용

6. **스크린샷 업로드**
   - 디바이스별 스크린샷 세트 생성
   - 이미지 바이너리 업로드
   - 업로드 커밋
   - **iPad 스크린샷 불필요** (supportsTablet: false)

7. **빌드 연결**
   - 처리 완료된 빌드를 버전에 연결

8. **심사 정보**
   - 연락처: config.md의 ios_review (first_name, last_name, phone)
   - 데모 계정 (필요시)
   - 심사 노트
   - 암호화: No (ITSAppUsesNonExemptEncryption: false)

9. **심사 제출**
   - reviewSubmissions API로 제출

#### A-4: iOS 제출 확인

AskUserQuestion:
```
iOS 앱 심사 제출 완료!
- 앱: [앱이름]
- 버전: 1.0.0
- 상태: Waiting for Review

App Store Connect에서 확인: https://appstoreconnect.apple.com
```

---

### Part B: Android — Google Play 제출 (일부 수동)

#### B-1: Play Console 수동 작업 안내

AskUserQuestion:
```
Google Play는 앱 생성과 일부 설정을 API로 할 수 없어서 
Play Console에서 직접 해야 합니다.

다음 작업을 완료해주세요:

1. https://play.google.com/console 접속

2. 앱 만들기:
   - 앱 이름: [PRD에서 가져온 이름]
   - 기본 언어: 한국어
   - 앱/게임: 앱
   - 무료/유료: 무료
   - 선언 동의

3. 콘텐츠 등급 (IARC):
   - 대시보드 → 앱 콘텐츠 → 콘텐츠 등급
   - 설문 완료

4. 데이터 안전:
   - 대시보드 → 앱 콘텐츠 → 데이터 안전
   - 개인정보 처리 양식 작성

5. 대상 연령 및 광고:
   - 타겟 잠재고객 설정
   - 광고 포함 여부 "예" 선택 (AdMob 사용)

6. 스토어 등록정보:
   - (API로 자동 설정할 예정이므로 기본만 입력해도 됨)

7. Service Account 설정 (처음인 경우):
   - 설정 → API 액세스 → 서비스 계정 만들기
   - JSON 키 파일 다운로드
   - 경로를 입력해주세요

모두 완료되면 Enter, Service Account JSON 경로를 입력해주세요.
(예: /path/to/service-account.json)
```

#### B-2: API 설정

사용자가 입력한 Service Account JSON 경로를 `config.md`에 저장.

#### B-3: EAS Submit (AAB 업로드)

```bash
eas submit --platform android --profile production --non-interactive
```

#### B-4: Google Play API로 스토어 등록정보 설정

1. **스토어 리스팅 업데이트**
   - 제목, 짧은 설명, 전체 설명
   - 로케일별 설정

2. **이미지 업로드**
   - phoneScreenshots: 스크린샷
   - featureGraphic: 대표 이미지 (1024x500)
   - icon: 앱 아이콘 (512x512)

3. **트랙 릴리즈**
   - internal 트랙에 먼저 릴리즈 (테스트)
   - 또는 production 트랙으로 직접 릴리즈

4. **릴리즈 노트**
   - 버전별 변경사항

#### B-5: Android 제출 확인

AskUserQuestion:
```
Android 앱 제출 완료!
- 앱: [앱이름]
- 트랙: [internal/production]
- 상태: [상태]

Play Console에서 확인: https://play.google.com/console
```

---

### Part C: 최종 정리

#### C-1: 제출 리포트 작성

`docs/harness/handoff/submit-result.md`:
```markdown
# Store Submission Report

## iOS — App Store
- Status: [Submitted/Failed]
- Version: 1.0.0
- Build: [빌드번호]
- Submitted: [날짜]
- Notes: [특이사항]

## Android — Google Play
- Status: [Submitted/Failed]
- Track: [internal/production]
- Version: 1.0.0
- Submitted: [날짜]
- Notes: [특이사항]

## AdMob
- iOS Ad Units: [실제/테스트]
- Android Ad Units: [실제/테스트]
- Note: [테스트 ID인 경우 교체 필요 안내]

## Pending Manual Actions
- [ ] [남은 수동 작업 목록]
```

#### C-2: Git 태그

```bash
git tag -a v1.0.0 -m "Release 1.0.0 — Store submission"
git push --tags
```

## State Update

```yaml
status: completed
current_phase: done
```

## HARD GATES

- iOS: EAS 빌드 성공 없이 제출 시도 금지
- Android: Play Console 수동 작업 확인 없이 API 호출 금지
- 스크린샷/메타데이터 없이 제출 금지
- 개인정보처리방침 URL 없이 제출 금지
- 제출 실패 시 에러 분석 후 사용자에게 안내
