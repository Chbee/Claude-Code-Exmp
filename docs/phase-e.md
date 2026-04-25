# Phase E — Offline Support + Tests (오프라인 대응 + 테스트)

> 브랜치: `phase/e-offline-tests`
> 목표: NWPathMonitor 기반 오프라인 감지·UI 피드백·재시도 로직 추가, Reducer/환율 변환 테스트 보강.

---

## 구현 목표

1. 네트워크 상태 감지 (NWPathMonitor, @Sendable)
2. 오프라인 State + 온→오프 전환 알림 (배너 + Toast)
3. 오프라인 UI 피드백 (Toolbar 인디케이터, 환율 영역 위 배너, 새로고침 비활성화)
4. API 에러 핸들링 강화 (재시도 2회, 간격 2초)
5. Reducer 단위 테스트 (Spec-Tasks 4.1)
6. 환율 변환 테스트 (Spec-Tasks 4.2)

---

## 태스크 목록

### Step 1: 네트워크 모니터 + 오프라인 State

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 1.1 | `Core/Network/NetworkMonitor.swift` (신규) | NWPathMonitor 래핑, `@Observable`, `isOffline: Bool`, `@Sendable` 콜백 → MainActor | Spec-Overview §2.5.1 |
| 1.2 | `Core/App/AppStore.swift` | NetworkMonitor 인스턴스 보유 + 환경 주입 | Spec-Architecture §4.3 |
| 1.3 | `Core/App/AppCurrencyStore.swift` | `cachedAt: Date?` exposing (Spec-Tasks 3.1.2), 온→오프 전환 시 Toast(info) | Spec-Overview §2.5.3 |

### Step 2: 오프라인 UI

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 2.1 | `Presentation/Calculator/CalculatorToolbar.swift` | 소형 인디케이터 ● (offline 시 색상 변경) | Spec-UI §1, Spec-Tasks 3.3.1 |
| 2.2 | `Presentation/Common/OfflineBanner.swift` (신규) | 환율 영역 위 배너, `"오프라인 — yyyy-MM-dd HH:mm 기준 데이터"` (절대시간) | Spec-Overview §2.5.2, Spec-Tasks 3.3.2 |
| 2.3 | `Presentation/Calculator/CalculatorView.swift` | OfflineBanner 통합 + 새로고침 버튼 disabled binding | Spec-Tasks 3.3.3 |

### Step 3: 에러 핸들링 + 재시도

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 3.1 | `Domain/Models/ExchangeRateError.swift` | 분류 확인 (network/server/parsing) — 친화적 메시지 컴퓨티드 추가 | Spec-Overview §2.5.5, Spec-Tasks 3.4.1/3.4.2 |
| 3.2 | `Data/Network/ExchangeRateAPI.swift` | `fetchFromAPI` 재시도 로직: 최대 2회, 간격 2초 (timeout 10s) | Spec-Tasks 3.4.3 |

### Step 4: Reducer 단위 테스트

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 4.1 | `TravelCalculatorTests/CalculatorReducerTests.swift` (신규) | 숫자 입력, 사칙연산, 소수점, AC/C/백스페이스, 엣지 케이스(0 나누기, 연산자 교체, =반복, 음수), 10자리 제한 — Spec-Tasks 4.1.1~4.1.6 전부 | Spec-Overview §2.1 |

### Step 5: 환율 변환 테스트

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 5.1 | `TravelCalculatorTests/ExchangeRateConversionTests.swift` (신규) | 통화 변환(Decimal 정밀도, fractionDigits), 소수점 처리, 방향 전환 시 값 이전(10자리 초과 포함), 통화 변경 시 리셋, 음수 → 변환 0 — Spec-Tasks 4.2.1~4.2.5 | Spec-Overview §2.2 |

---

## 완료 기준

- [ ] `xcodebuild build` 성공 (warning 0, error 0)
- [ ] `xcodebuild test` 성공 (4.1, 4.2 신규 테스트 통과)
- [ ] 시뮬레이터 Wi-Fi off → 오프라인 배너 등장 + Toolbar 인디케이터 색상 전환 + 새로고침 버튼 disabled
- [ ] 온→오프 전환 시 Toast(info, "오프라인으로 전환되었습니다") 1회 노출
- [ ] API 일시 실패 시 2초 간격 2회 재시도 후 캐시 fallback 또는 에러 노출
- [ ] 오프라인 배너에 절대 시간(`yyyy-MM-dd HH:mm`) 병기

---

## 파일 구조 (생성/수정 예정)

```
TravelCalculator/
├── Core/
│   ├── App/
│   │   ├── AppStore.swift                           ← MOD
│   │   └── AppCurrencyStore.swift                   ← MOD
│   └── Network/
│       └── NetworkMonitor.swift                     ← NEW
├── Data/
│   └── Network/
│       └── ExchangeRateAPI.swift                    ← MOD (재시도)
├── Domain/
│   └── Models/
│       └── ExchangeRateError.swift                  ← MOD (메시지)
└── Presentation/
    ├── Calculator/
    │   ├── CalculatorView.swift                     ← MOD
    │   └── CalculatorToolbar.swift                  ← MOD
    └── Common/
        └── OfflineBanner.swift                      ← NEW

TravelCalculatorTests/
├── CalculatorReducerTests.swift                     ← NEW
└── ExchangeRateConversionTests.swift                ← NEW
```

---

## 다음 Phase

V1 완료 → 앱스토어 배포 준비 + 통화 확장(JPY, EUR 등) 백로그 처리.
