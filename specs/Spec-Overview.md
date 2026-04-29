# TravelCalculator 기획서 — 기능 명세

> 2차 인터뷰 기반 최종 확정본 | 2026-04-05
> 관련: [화면 설계](Spec-UI.md) | [아키텍처](Spec-Architecture.md) | [데이터 모델](Spec-DataModel.md) | [태스크](Spec-Tasks.md)

---

## 1. 프로젝트 개요

### 1.1 앱 소개
여행지에서 가격/환율 계산을 빠르게 처리하는 iOS 계산기 앱.
사용자가 현지 통화 금액을 입력하면, 실시간 환율을 기반으로 원화(KRW)로 변환된 결과를 즉시 보여준다.

### 1.2 핵심 가치
- **즉시성**: 입력과 동시에 변환 결과 확인
- **직관성**: 기본 계산기 UX를 그대로 유지하면서 환율 기능 추가
- **오프라인 대응**: 네트워크 없이도 캐시된 환율로 사용 가능

### 1.3 타겟 사용자
- 해외 여행 중 현지 가격을 원화로 빠르게 환산하고 싶은 한국인 여행자

### 1.4 기술 요구사항
- iOS 17+ (최소 배포 타겟)
- iPhone 세로(portrait) 전용, iPad 미지원
- Swift 6.0, SwiftUI, @Observable
- 숫자 포맷 로케일 고정: 소수점 `.`, 천단위 `,` (기기 로케일 무시)

---

## 2. 기능 명세

### 2.1 기본 계산기

#### 2.1.1 숫자 입력
- 0~9 숫자 키패드
- 최대 **정수부 10자리**까지 입력 가능 (소수점 이하 2자리는 별도)
- 최대 표시: `9,999,999,999.99`
- 10자리 초과 시 Toast(warning) + 햅틱 피드백

#### 2.1.2 사칙연산
- 지원 연산: `+`, `-`, `×`, `÷`
- 연속 연산 지원 (예: `3 + 5 + 2`)
- `=` 버튼으로 결과 계산

#### 2.1.3 소수점
- `.` 버튼으로 소수점 입력
- display가 `"0"`일 때 `.` 입력 시 `"0."`으로 자동 완성
- 하나의 숫자에 소수점 중복 입력 방지 (두 번째 `.` 무시)
- 최대 소수점 이하 2자리 입력

#### 2.1.4 초기화/삭제

| 버튼 | 동작 | 상태 보존 |
|------|------|----------|
| AC (All Clear) | 전체 계산기 상태 초기화 | 없음 (모두 리셋) |
| C (Clear) | display만 `"0"`으로 초기화 | `previousValue`, `pendingOperator` 유지 |
| ← (Backspace) | 마지막 입력 문자 삭제 | 연산 상태 유지 |

**AC/C 토글 규칙** (iOS 기본 계산기와 동일):
- 전체 상태가 초기화된 상태(`display="0"`, `pendingOperator=nil`) → **AC** 표시
- 숫자 입력이 시작되면 → **C**로 전환
- C를 누르면 display만 `"0"`, 다시 전체 초기화 상태이면 AC로 복귀

**백스페이스 엣지 케이스**:
- `"5"` → `←` → `"0"` (한 자리만 남으면 0으로 복귀)
- `"0."` → `←` → `"0"`
- `"0"` → `←` → 무시 (변화 없음)
- `=` 직후에도 결과를 한 자리씩 삭제 가능

#### 2.1.5 엣지 케이스

| 케이스 | 처리 방식 |
|--------|----------|
| 연산자 연속 입력 (`3 + ×`) | 마지막 연산자로 교체 (`3 ×`) |
| `=` 연속 입력 | 마지막 연산 반복. `3 + 5 = 8`, `=` → `13`, `=` → `18`. `lastOperator` + `lastOperand` 쌍 사용 |
| `=` 후 숫자 입력 | 새 계산 시작 (결과 버리고 새 입력) |
| `=` 후 연산자 입력 | 결과값이 `previousValue`가 됨. `3+5=8` → `×2=` → `16` |
| `=` 단독 입력 (pendingOperator=nil) | 무시 (display 유지) |
| 연산자 후 `=` (피연산자 없이) | display값을 피연산자로 사용. `5 + =` → `5 + 5 = 10` (iOS 동작) |
| 0으로 나누기 | Toast(warning, "0으로 나눌 수 없습니다") + 상태 유지. 연산자 변경으로 복구 가능 |
| 소수점 중복 입력 | 두 번째 `.` 무시 |
| 음수 결과 | display에 `-2` 등 표시 허용. 환율 변환 결과는 **0 처리** + Toast(warning, "음수 금액은 변환할 수 없습니다") |
| 정수부 10자리 초과 상태에서 입력 | 숫자/소수점 추가 입력만 차단. 연산자, 백스페이스, AC/C는 정상 동작 |
| `=` 결과가 정수부 15자리 초과 | Toast(error, "계산 결과가 너무 큽니다") + 이전 display 유지 |

### 2.2 환율 변환

#### 2.2.1 실시간 변환
- 숫자 입력 중에도 변환 결과를 실시간으로 표시
- 디스플레이 상단: 입력 금액 (출발 통화)
- 디스플레이 하단: 변환 금액 (도착 통화)
- display가 `"0"`일 때에도 변환 결과 영역에 `KRW 0` 표시

#### 2.2.2 환율 정보 표시
- `"1 USD = 1,350.00 KRW"` 형태로 현재 적용 환율 표시
- 마지막 업데이트 시간 표시
- 오른쪽에 새로고침 ↻ 버튼 (2.4.6 참조)

#### 2.2.3 변환 방향 전환
- **UI**: display 영역 중앙의 `↓` 화살표 버튼 (탭 가능)
- **동작**: 탭 시 변환 결과값이 새 입력값이 됨
  - 예: `USD 1,000 → KRW 1,350,000` 상태에서 탭 → `KRW 1,350,000 → USD 1,000`
- **상태 리셋**: 방향 전환 시 `previousValue=nil`, `pendingOperator=nil`, `lastOperand=nil`, `lastOperator=nil` 초기화
  - 단, display 숫자(변환 결과값)는 새 입력값으로 이전
- **10자리 초과 허용**: 변환 결과값이 정수부 10자리를 초과해도 display에 이전 허용. 추가 숫자/소수점 입력만 차단
- **기본값**: 온보딩 완료 직후 `.selectedToKRW` (외화 → KRW)
- `conversionDirection`: `.selectedToKRW` | `.krwToSelected`

#### 2.2.4 변환 결과 소수점 (통화별 차등)
| 통화 | 소수점 자릿수 | 표시 예시 |
|------|-------------|----------|
| KRW | 0자리 | ₩1,350,000 |
| JPY | 0자리 | ¥10,000 |
| VND | 0자리 | ₫25,000,000 |
| USD | 2자리 | $1,000.00 |
| CNY | 2자리 | 元7,250.00 |
| EUR | 2자리 | €920.00 |
| TWD | 2자리 | NT$31,500.00 |
| THB | 2자리 | ฿35,400.00 |
| PHP | 2자리 | ₱56,800.00 |

Currency enum에 `fractionDigits: Int` 프로퍼티로 관리.

> 저액면 통화(VND 등) — KRW→VND 변환 결과가 정수부 10자리에 근접할 수 있다(예: 1억 KRW ≈ 18억 VND). Display 폰트 자동 축소(`minimumScaleFactor`)와 변환 결과값의 10자리 초과 허용 정책(§2.2.3 참조)으로 대응.

### 2.3 통화 선택

#### 2.3.1 지원 통화
| 통화 코드 | 기호 | 국기 | 국가명 |
|-----------|------|------|--------|
| KRW | ₩ | 🇰🇷 | 대한민국 |
| USD | $ | 🇺🇸 | 미국 |
| JPY | ¥ | 🇯🇵 | 일본 |
| CNY | 元 | 🇨🇳 | 중국 |
| EUR | € | 🇪🇺 | 유럽연합 |
| TWD | NT$ | 🇹🇼 | 대만 |
| THB | ฿ | 🇹🇭 | 태국 |
| VND | ₫ | 🇻🇳 | 베트남 |
| PHP | ₱ | 🇵🇭 | 필리핀 |

#### 2.3.2 통화 선택 화면
- 전체 화면 모달 (fullScreenCover)
- 통화 목록에서 선택 시 체크마크 표시
- 선택 완료 후 자동 닫힘 또는 X 버튼으로 닫기

#### 2.3.3 통화 변경 시 계산기 리셋
- 통화 변경이 확정되면 CalculatorStore 전체 리셋
  - `display = "0"`, `previousValue = nil`, `pendingOperator = nil`, `lastOperand = nil`, `lastOperator = nil`
  - 이유: display 숫자가 이전/새 통화 중 어느 것인지 모호해지는 상황 방지

#### 2.3.4 위치 기반 자동 선택
- "현재 위치로 자동 설정" 버튼
- 위치 권한 요청 → GPS 좌표 획득 → 역지오코딩 → 국가 코드 매핑
- 국가 코드 매핑(ISO 3166-1 alpha-2):
  - 단일 매핑: `KR→KRW`, `US→USD`, `JP→JPY`, `CN→CNY`, `TW→TWD`, `TH→THB`, `VN→VND`, `PH→PHP`
  - EUR(eurozone 19개국): `DE/FR/IT/ES/NL/BE/AT/PT/IE/FI/GR/LU/SK/SI/EE/LV/LT/MT/CY → EUR`
  - 데이터 소스: `Currency.countryCodes` (Spec-DataModel §5.2)
- 미지원 지역일 경우 Toast(warning) 알림
- `PermissionStatus.denied` 시: iOS 설정 앱으로 안내하는 Toast(info) + 딥링크

### 2.4 환율 API 연동

#### 2.4.1 데이터 소스
- open.er-api.com (USD 기준)
- endpoint: `https://open.er-api.com/v6/latest/USD`
- 인증 불필요, 호출 한도 없음
- **업데이트 주기**: 24시간마다 갱신 (`time_next_update_unix` 제공)
- 응답: `{ "result": "success", "base_code": "USD", "time_last_update_unix": ..., "rates": {"KRW": ..., "TWD": ..., ...} }`
- KRW 환산: `X→KRW = rates["KRW"] / rates["X"]` (API 레이어에서 사전 계산, 은행 반올림 scale 8)

#### 2.4.2 (삭제됨) deal_bas_r 파싱
- open.er-api는 JSON 숫자로 환율을 반환하므로 별도 문자열 파싱 없음

#### 2.4.3 (삭제됨) 주말/공휴일 fallback
- open.er-api는 24h 주기로 매일 갱신 — fallback 불필요
- API 실패 시 stale 캐시 반환, 캐시도 없으면 전체 화면 에러

#### 2.4.4 캐싱 전략
- 캐시 파일: `exchange_rates_cache.json` (Documents 디렉토리)
- 유효성 판단: `Date.now < response.validUntil` — API의 `time_next_update_unix`를 그대로 `validUntil`로 저장
- API 실패 시: `validUntil` 지난 stale 캐시라도 fallback으로 사용
- JSON 파싱 실패 시: 캐시 파일 삭제 후 재요청
- 동시 읽기/쓰기: actor 기반 직렬화 보호

#### 2.4.5 Protocol 추상화
- `ExchangeRateAPIProtocol`: fetch 메서드 정의
- `LocationServiceProtocol`: 위치 조회 메서드 정의
- Store에 의존성 주입 → 마일스톤 4(테스트)에서 Mock으로 대체

#### 2.4.6 새로고침 전략 (searchdate 기반)
| 조건 | 새로고침 버튼 | 동작 |
|------|-------------|------|
| 캐시의 searchdate = 오늘 | **비활성화** | "최신" 표시 |
| 캐시의 searchdate < 오늘 | 활성화 | "N일 전" 표시 + 탭 시 API 호출 |
| 캐시 없음 | — | 앱 시작 시 자동 호출 |

- 별도 throttle 불필요: 같은 날 데이터는 변하지 않으므로 searchdate 기반으로 자연스럽게 제한
- 비정상 환율값(0, 음수) 수신 시 해당 데이터 무시 + fallback

#### 2.4.7 데이터 모델
```swift
ExchangeRate
├── currencyCode: String    // "USD", "TWD"
├── currencyName: String    // "미국 달러"
└── rate: Decimal           // 1 외화 = N 원 (Decimal 타입)

ExchangeRateResponse
├── rates: [ExchangeRate]
├── fetchedAt: Date
├── searchDate: String      // "2026-04-04" (API 조회일)
└── validUntil: Date
```

### 2.5 오프라인 대응

#### 2.5.1 네트워크 모니터링
- NWPathMonitor를 사용한 실시간 네트워크 상태 감지
- `NetworkState` enum: `unknown` / `online` / `offline` (초기값 `unknown` — 첫 콜백 도달 전 "거짓 온라인" 창 제거)
- 콜백 → MainActor 전달 시 `@Sendable` 처리

#### 2.5.2 오프라인 UI
- **Toolbar 인디케이터**: 색 + 아이콘 모양 변경 (● ↔ wifi-off) + VoiceOver `accessibilityLabel`
- **환율 영역 rate row 인라인 캐시 시각 표기** (별도 배너 없음): `Color.appWarning` 톤
  - 상대 시각: `방금` / `N분 전` / `N시간 전` / `N일 전`
  - 절대 시간(`14:00 기준`)은 사용하지 않음 — 오프라인 인라인 표기는 finer-grain 상대 시각 전용
- 새로고침 버튼: 오프라인 시 비활성화 (tap 시 `Toast(info, "오프라인 시 갱신할 수 없어요")`)
- `unknown` 상태: 인디케이터/인라인 표기 비표시, 새로고침 disabled (안전 기본값)

#### 2.5.3 온라인↔오프라인 전환
- **온→오프**: 별도 Toast/배너 없음 — 환율 영역 인라인 캐시 시각 표기로 대체 (grace period 없음)
- **오프→온 복귀**: 환율 영역 pulse 애니메이션 (scale 1.0→1.02→1.0 1회), Toast/햅틱 없음, 인라인 표기는 원래 라벨(`최신` / `N일 전`)로 복귀
- `unknown → offline` 전이는 무시(첫 진입 시 깜빡임 방지), `online → offline` 전이만 인라인 표기 발화

#### 2.5.4 API 실패 + 캐시 없음 (최악의 상태)
- 계산기 임시 비활성화 (키패드 disable)
- 전체 화면 에러 오버레이: 에러 아이콘 + 에러 메시지 + 재시도 버튼
- 재시도 성공 시 오버레이 해제, 계산기 활성화

#### 2.5.5 에러 핸들링
- 에러 분류: 네트워크 / 서버 / 파싱 에러
- Timeout: 10초, 재시도 최대 2회 (간격 2초)
- 사용자 친화적 에러 메시지

### 2.6 Toast 알림 시스템

#### 2.6.1 스타일 및 지속 시간
| 스타일 | 색상 | 지속시간 | 용도 |
|--------|------|---------|------|
| success | 초록 | 1.5s | 통화 변경 완료, 환율 갱신 성공 |
| info | 파랑 | 2.0s | 안내 메시지, 오프라인 전환 알림 |
| warning | 노랑 | 2.5s | 입력 자릿수 초과, 미지원 지역, 0 나누기, 음수 변환 |
| error | 빨강 | 3.0s | API 오류, 위치 감지 실패, 계산 결과 초과 |

#### 2.6.2 동작
- **위치**: 화면 상단, safe area 안쪽
- 스프링 애니메이션으로 등장/퇴장
- 표시 시 햅틱 피드백 (light impact)

### 2.7 온보딩 (첫 실행)

#### 2.7.1 첫 실행 감지
- `UserDefaults`에 `hasCompletedOnboarding` 플래그 저장
- 미완료 시 통화 선택 화면 강제 표시 (계산기 접근 차단)

#### 2.7.2 온보딩 통화 목록
- **KRW 제외** — 여행지 통화만 표시 (USD, TWD)
- 일반 통화 선택 화면(Toolbar에서 접근)에서는 KRW 포함 유지

#### 2.7.3 온보딩 위치 자동 감지
- 위치 버튼 유지 (여행지 도착 후 앱 설치 케이스 대응)
- **한국(KRW) 감지 시**: Toast(info, "현재 위치는 한국입니다. 여행지 통화를 직접 선택해주세요") + 통화 변경 없음
- 지원 여행지(USD, TWD) 감지 시: 정상 자동 선택
- 미지원 지역 감지 시: 기존 Toast(warning) 동작

#### 2.7.4 온보딩 플로우
1. 앱 실행과 동시에 환율 API 호출 시작 (백그라운드)
2. 통화 선택 화면 표시 (API 로딩과 병렬)
3. 사용자가 통화 선택 → `hasCompletedOnboarding = true`
4. 계산기 화면 진입
   - 환율 로딩 완료: 즉시 사용 가능
   - 환율 로딩 중: 로딩 스피너 표시 후 완료 시 활성화
   - 환율 실패 + 캐시 없음: 전체 화면 에러 상태

#### 2.7.5 기본 변환 방향
- 온보딩 완료 직후: `.selectedToKRW` (외화 → KRW)
