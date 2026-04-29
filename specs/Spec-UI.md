# TravelCalculator 기획서 — 화면 설계 & 디자인 시스템

> 2차 인터뷰 기반 최종 확정본 | 2026-04-05
> 관련: [개요/Toast/온보딩](Spec-Overview.md) | [계산기/환율 변환](Spec-Calculator.md) | [환율/통화/오프라인](Spec-ExchangeRate.md) | [아키텍처](Spec-Architecture.md) | [데이터 모델](Spec-DataModel.md) | [태스크](Spec-Tasks.md)

---

## 3. 화면 설계

### 3.1 계산기 화면 (메인)

```
┌─────────────────────────────────┐
│  [🇺🇸 USD ▼]    ● 온라인        │  ← Toolbar (카메라/설정 V1 숨김)
├─────────────────────────────────┤
│    1 USD = 1,350.00 KRW · 5분 전  [↻]  │  ← 환율 정보 + 인라인 캐시 시각(오프라인 시) + 새로고침
│                                 │
│        USD  1,000.00           │  ← 입력 금액 (출발 통화)
│              [↓]               │  ← 방향 전환 버튼 (탭 가능)
│        KRW  1,350,000          │  ← 변환 금액 (도착 통화)
│                                 │
├─────────────────────────────────┤
│  [AC/C]  [←]   [ ÷ ]          │  ← 키패드 1행
│   [ 7]   [ 8]  [ 9]  [ × ]    │
│   [ 4]   [ 5]  [ 6]  [ - ]    │
│   [ 1]   [ 2]  [ 3]  [ + ]    │
│   [   0   0  ] [ . ]  [ = ]   │
└─────────────────────────────────┘
```

#### Toolbar 구성
- 통화 선택 버튼 (pill 형태, 국기 + 통화코드)
- 온/오프라인 상태 인디케이터:
  - **Online**: `Circle()` 6×6pt(`Color.appSuccess`) + `"온라인"` 11pt 텍스트(`Color.appTextSub`)
  - **Offline**: `wifi.slash` SF Symbol 11pt semibold(`Color.appWarning`) + `"오프라인"` 11pt 텍스트(`Color.appWarning`)
  - **Unknown**: 빈 placeholder (레이아웃 자리만 유지, 가시 요소 없음)
  - VoiceOver `accessibilityLabel`: 각각 `"온라인"` / `"오프라인"` / 비표시
  - 정의 위치: `CalculatorToolbar.swift networkIndicator`
- 카메라/설정 버튼: **V1에서 숨김** (레이아웃 자리는 유지, opacity=0)

#### Display 영역
- 환율 정보 + 새로고침: `"1 USD = 1,350.00 KRW"` + 우측 ↻ 버튼. 오프라인 시 rate row 우측에 인라인 캐시 시각(`· N분 전` 등) 추가 표기 — Spec-Overview §2.5.2 참조 (별도 오프라인 배너 없음)
- 입력 금액: 통화 기호 + 천단위 콤마 포맷
- 방향 전환 버튼 `↓`: 탭 시 결과값을 새 입력값으로 이전하며 방향 전환
- 변환 금액: 통화 기호 + 천단위 콤마 포맷, 통화별 소수점 자릿수 적용
- 긴 숫자는 폰트 크기 자동 축소 (`minimumScaleFactor: 0.3` — 원본의 30%까지 축소 허용. VND 등 저액면 통화 12자리 결과 대응)

### 3.2 통화 선택 화면

```
┌─────────────────────────────────┐
│           여행 통화 설정      [X] │  ← 타이틀 + 닫기
│     통화 설정을 위해 국가 선택    │  ← 서브타이틀
├─────────────────────────────────┤
│  [📍 현재 위치로 자동 설정]       │  ← 위치 기반 선택
├─────────────────────────────────┤
│  🇰🇷 대한민국                    │
│     KRW                    ✓   │  ← 현재 선택됨
├─────────────────────────────────┤
│  🇺🇸 미국                       │
│     USD                        │
├─────────────────────────────────┤
│  🇹🇼 대만                       │
│     TWD                        │
└─────────────────────────────────┘
```

#### 플로우
1. Toolbar의 통화 버튼 탭 → fullScreenCover 모달 표시
2. 통화 직접 선택 또는 위치 자동 설정
3. 위치 버튼:
   - 권한 `.notDetermined` → 시스템 권한 팝업
   - 권한 `.denied` → Toast(info) + iOS 설정 앱 딥링크 안내
   - 권한 `.granted` → GPS → 역지오코딩 → 통화 자동 선택
4. 결과 Toast 표시 (성공 / 미지원 지역 / 에러)
5. 선택 시 모달 자동 닫힘 + 계산기 리셋

### 3.3 온보딩 화면
- 통화 선택 화면과 동일한 UI 재사용 (CurrencySelectView, `isOnboarding: Bool`)
- X 버튼 비노출 (강제 선택)
- **KRW 제외** — USD, TWD만 표시
- 위치 버튼 유지 (한국 감지 시 Toast 안내, 여행지 감지 시 자동 선택)
- 타이틀: "여행지 통화를 선택해주세요"

### 3.4 환율 미가용 에러 배너
- **트리거**: `currentRate == nil`일 때 (`AppCurrencyStore.unavailableRateError` 활성). API 실패 + stale 캐시도 없는 상태.
- **형태**: 화면 상단 인라인 배너 — `safeAreaInset(edge: .top)`로 CalculatorView 위에 부착 (전체 화면 오버레이 아님)
- **구성**: `exclamationmark.triangle.fill` 아이콘 (`Color.appError`, `.footnote`) + 에러 메시지(`error.errorDescription`, Spec-Overview §2.5.5 표 참조) + `재시도` 버튼 (`Color.appPrimary`, `.semibold`)
- **레이아웃**: `padding(.horizontal: 16, .vertical: 10)`, `frame(maxWidth: .infinity)`, `background(Color.appError.opacity(0.12))`
- **계산기 키패드**: **활성 유지** — 환율 없이도 단순 산술 사용 가능. 변환 결과 영역은 `0`으로 표시(§2.2.1 fallback)
- **재시도 동작**: `loadExchangeRates()` 재호출. 성공 시 배너 자동 사라짐(`unavailableRateError == nil`로 전이).
- 정의 위치: `Presentation/Error/ExchangeRateErrorBanner.swift`, `ContentView.swift:21-27`

---

## 6. 디자인 시스템

### 6.1 컬러 팔레트

**Source of Truth 계층:**
1. **Figma** (canonical — 모든 변경의 출발점): https://www.figma.com/design/RHAP7WVgoX220lRhWseaWE/여행가계부 node-id=99-875
2. **`Design/ColorTokens.swift`** — Figma의 미러. light/dark mode pair(`ColorPair`)로 정의. hex 값은 Figma에서 수동 동기화.
3. **`Design/Color+Semantic.swift`** — 시맨틱 별칭(`Color.appPrimary`, `Color.appWarning` 등) 정의. 뷰에서는 이 계층만 참조.

| 그룹 | 토큰 | 용도 |
|---|---|---|
| `Color.Main` | c100~c900 (9단계) | 브랜드 컬러 — Primary 액션, 강조 |
| `Color.Gray` | c050~c900 (10단계) | 중립 컬러 — 배경/구분선/보조 텍스트 |
| `Color.System` | blue500 / green500 / yellow500 / red500 | 시스템 시맨틱 — info/success/warning/error |
| `Color.Side` | background / card / baseText / subText / accent / check | 화면 구조 — 전역 배경, 카드, 텍스트 톤 |
| `Color.Toast` | successTint / errorTint / warningTint / infoTint / background / messageText | Toast 전용 (§2.6 참조) |

**갱신 절차** (Figma → 코드)
1. 디자이너가 Figma에서 토큰 수정 (node-id=99-875)
2. 변경된 hex 값을 PR/이슈에 명시
3. 개발자가 `ColorTokens.swift`의 해당 hex만 교체 (구조는 변경 없음)
4. 토큰 그룹/단계 자체가 늘거나 줄면 spec 표 동시 갱신 필요

**뷰 접근 규칙**: 뷰 코드에서 원시 토큰(`Color.Main.c500.adaptive` 등) 직접 참조 금지. **시맨틱 별칭(`Color.app*`)만 사용**. (현재 Presentation 코드에서 원시 참조 0건 — 이 상태 유지)

**검증 가능 항목** (결재 에이전트용)
- Figma node-id 99-875의 토큰 그룹·단계 수가 `ColorTokens.swift`와 일치하는지
- Presentation 디렉토리에서 `Color.Main` / `Color.Gray` / `Color.System` / `Color.Side` / `Color.Toast` 직접 참조 grep 결과 0건

### 6.2 아이콘

**Source of Truth 계층** (위에서 아래로 우선)
1. **Figma** (canonical) — 디자이너가 지정한 아이콘이 있으면 그것을 사용 (Asset Catalog 자체 에셋으로 등록)
2. **Figma에 없으면** — 1차로 디자이너에게 추가 요청
3. **추가가 불가능하다고 회신**된 경우에만 — SF Symbol로 대체

#### Asset Catalog (`Image("name")`) — Figma 출처
| 이름 | 사용처 |
|---|---|
| `MapPin` | 통화 선택 화면 "현재 위치로 자동 설정" 버튼 |
| `ToastSuccess` / `ToastInfo` / `ToastWarning` / `ToastError` | Toast 스타일별 아이콘 (§2.6) |

#### SF Symbols (`Image(systemName:)`) — Figma 부재 시 fallback
| 이름 | 사용처 |
|---|---|
| `chevron.down` | Toolbar 통화 선택 버튼 |
| `camera` | Toolbar 카메라 (V1 숨김) |
| `gearshape` | Toolbar 설정 (V1 숨김) |
| `wifi.slash` | 오프라인 인디케이터 (온라인은 `Circle()` — §3.1 참조) |
| `arrow.up.arrow.down` | 방향 전환 버튼 |
| `arrow.clockwise` | 새로고침 버튼 |
| `xmark` | 통화 선택 모달 닫기 |
| `magnifyingglass` | 통화 검색 입력 |
| `xmark.circle.fill` | 검색 입력 클리어 |
| `checkmark` | 통화 선택 표시 |
| `exclamationmark.triangle.fill` | 환율 미가용 에러 배너 (§3.4) |

**검증 가능 항목** (결재 에이전트용)
- 새 아이콘 추가 PR이 SF Symbol로만 시작했다면, Figma 확인 또는 디자이너 회신 흔적이 PR 설명에 있어야 함
- Asset Catalog 항목과 위 표가 일치하는지

### 6.3 햅틱 피드백
| 상황 | 타입 |
|------|------|
| 입력 자릿수 초과 | warning (notification) |
| Toast 표시 | light (impact) |
| 방향 전환 버튼 탭 | medium (impact) |
| 통화 선택 완료 | success (notification) |
| 등호(=) 결과 표시 | light (impact) |
