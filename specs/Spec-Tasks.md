# TravelCalculator 기획서 — 태스크 & 백로그

> 2차 인터뷰 기반 최종 확정본 | 2026-04-05
> 관련: [기능 명세](Spec-Overview.md) | [화면 설계](Spec-UI.md) | [아키텍처](Spec-Architecture.md) | [데이터 모델](Spec-DataModel.md)

---

## 8. V1 세부 태스크 목록

### 마일스톤 0: 온보딩

#### 0.1 온보딩 플로우
- [x] 0.1.1 `hasCompletedOnboarding` UserDefaults 플래그
- [ ] 0.1.2 ContentView에서 온보딩/계산기 분기
- [ ] 0.1.3 CurrencySelectView 온보딩 모드 (`isOnboarding: Bool`, KRW 제외)

### 마일스톤 1: 계산기 화면 완성

#### 1.1 계산 로직 완성
- [x] 1.1.1 `Operator` 독립 enum 정의
- [x] 1.1.2 `CalculatorIntent` enum 정의 (의미 단위 분리)
- [x] 1.1.3 equals 연산 구현
- [x] 1.1.4 연속 연산 지원 (3+5+2)
- [x] 1.1.5 `=` 연속 입력 시 마지막 연산 반복 (`lastOperator` + `lastOperand`)
- [x] 1.1.6 `=` 후 연산자 → 결과를 previousValue로
- [x] 1.1.7 연산자 후 `=` (피연산자 없이) → display값 사용 (`5+=` → 10)
- [x] 1.1.8 `=` 단독 (pendingOperator=nil) → 무시
- [x] 1.1.9 AC/C 동작 분리 (C: display만, AC: 전체. iOS 토글 규칙)
- [x] 1.1.10 엣지 케이스 (연산자 교체, 0 나누기 Toast, 소수점 자동완성, 음수→변환 0)
- [x] 1.1.11 백스페이스 엣지 케이스 ("5"→"0", "0."→"0", "0"→무시, = 후 삭제)
- [x] 1.1.12 정수부 10자리 제한 + 초과 시 숫자/소수점만 차단
- [x] 1.1.13 `=` 결과 15자리 초과 시 Toast(error) + display 유지

#### 1.2 디스플레이 영역 개선
- [x] 1.2.1 천단위 콤마 포맷팅 (`Decimal+Format`, 로케일 고정)
- [x] 1.2.2 긴 숫자 처리 (폰트 자동 축소)
- [x] 1.2.3 `CurrencyAmountDisplayModel` 구현

#### 1.3 통화 선택 UI
- [x] 1.3.1 Currency enum 정의 (`fractionDigits` 포함)
- [x] 1.3.2 통화 선택 버튼 UI
- [x] 1.3.3 통화 State 추가
- [x] 1.3.4 통화 선택 Intent 추가
- [x] 1.3.5 통화 변경 시 계산기 리셋 로직

#### 1.4 환율 표시 영역
- [x] 1.4.1 환율 정보 표시 UI ("1 USD = 1,350 KRW")
- [x] 1.4.2 업데이트 시간 표시
- [x] 1.4.3 새로고침 ↻ 버튼 (환율 행 오른쪽)
- [x] 1.4.4 searchdate 기반 버튼 활성화/비활성화

#### 1.5 변환 방향 전환
- [x] 1.5.1 방향 전환 `↓` 버튼 UI
- [x] 1.5.2 방향 전환 시 결과값 → 새 입력값 이전 로직
- [x] 1.5.3 방향 전환 시 계산기 상태 리셋 (previousValue, pendingOperator, lastOperand, lastOperator)
- [x] 1.5.4 10자리 초과 변환값 이전 허용 처리

#### 1.6 변환 결과 표시
- [x] 1.6.1 변환 결과 영역 UI
- [x] 1.6.2 실시간 변환 표시
- [x] 1.6.3 display "0" → KRW 0 표시
- [x] 1.6.4 통화별 소수점 차등 적용 (fractionDigits)
- [x] 1.6.5 음수 결과 → 변환 0 + Toast

#### 1.7 통화 상태 구조 정리
- [x] 1.7.1 AppCurrencyStore + ExchangeRateStatus enum
- [x] 1.7.2 selectedCurrency, conversionDirection UserDefaults 저장
- [x] 1.7.3 Calculator DisplayModel 분리 마무리
- [x] 1.7.4 CurrencySelect 전역 통화 연동 정리

#### 1.8 V1 미지원 버튼 처리
- [x] 1.8.1 카메라/설정 버튼 숨김 처리 (opacity=0, 레이아웃 자리 유지)

### 마일스톤 2: 환율 로직 구현

#### 2.1 통화 모델 확장
- [x] 2.1.1 Currency 상세 정의 (통화코드, 이름, 기호, fractionDigits)
- [x] 2.1.2 지원 통화 필터링

#### 2.2 환율 변환 로직
- [x] 2.2.1 환율 변환 함수 구현 (KRW 기준 양방향, Decimal 사용)
- [x] 2.2.2 소수점 처리 규칙 (통화별 fractionDigits)
- [x] 2.2.3 반올림 규칙 적용 (은행 반올림)

#### 2.3 State/Intent 확장
- [x] 2.3.1 ExchangeRateStatus State
- [x] 2.3.2 환율 Intent 추가
- [x] 2.3.3 환율 Reducer 로직

#### 2.4 Store 비동기 처리
- [x] 2.4.1 ExchangeRateAPIProtocol 정의 + 구현체 (deal_bas_r 쉼표 파싱 포함)
- [x] 2.4.2 주말/공휴일 순차 fallback (최대 7번 호출)
- [x] 2.4.3 앱 시작 시 환율 로드 (온보딩과 병렬)
- [x] 2.4.4 ExchangeRateStatus 로딩 상태 처리
- [x] 2.4.5 API 실패 + 캐시 없음 → 전체화면 에러
- [x] 2.4.6 searchdate 기반 새로고침 전략 구현
- [x] 2.4.7 비정상 환율값(0, 음수) 검증 + 무시

### 마일스톤 3: 오프라인 대응

#### 3.1 캐시 고도화
- [ ] 3.1.1 캐시 상태 확인 로직 (searchDate 비교)
- [ ] 3.1.2 캐시 메타정보 제공 (fetchedAt 절대 시간)
- [ ] 3.1.3 actor 기반 동시 읽기/쓰기 보호

#### 3.2 네트워크 상태 감지
- [ ] 3.2.1 네트워크 모니터 구현 (NWPathMonitor, @Sendable)
- [ ] 3.2.2 오프라인 상태 State
- [ ] 3.2.3 온→오프라인 전환 시 배너 + Toast(info) 알림

#### 3.3 오프라인 UI 피드백
- [ ] 3.3.1 Toolbar 소형 인디케이터
- [ ] 3.3.2 환율 영역 위 오프라인 배너 (절대 시간 병기)
- [ ] 3.3.3 새로고침 버튼 오프라인 시 비활성화

#### 3.4 에러 핸들링
- [ ] 3.4.1 API 에러 분류 (네트워크/서버/파싱)
- [ ] 3.4.2 사용자 친화적 에러 메시지
- [ ] 3.4.3 재시도 로직 (최대 2회, 간격 2초)

### 마일스톤 4: 테스트 코드

#### 4.1 Reducer 단위 테스트
- [ ] 4.1.1 숫자 입력 테스트
- [ ] 4.1.2 사칙연산 테스트
- [ ] 4.1.3 소수점 테스트 (0. 자동 완성 포함)
- [ ] 4.1.4 AC/C/백스페이스 테스트 (C: display만 리셋 확인)
- [ ] 4.1.5 엣지 케이스 테스트 (0 나누기, 연산자 교체, = 반복, = 후 연산자, 연산자 후 =, 음수 결과)
- [ ] 4.1.6 10자리 제한 테스트 (정수부 기준, 초과 시 숫자만 차단)

#### 4.2 환율 변환 테스트
- [ ] 4.2.1 통화 변환 테스트 (Decimal 정밀도, fractionDigits)
- [ ] 4.2.2 소수점 처리 테스트
- [ ] 4.2.3 방향 전환 시 값 이전 테스트 (10자리 초과 포함)
- [ ] 4.2.4 통화 변경 시 리셋 테스트
- [ ] 4.2.5 음수 → 변환 0 테스트

#### 4.3 API 테스트
- [x] 4.3.1 MockExchangeRateAPI 구현 (Protocol 기반)
- [x] 4.3.2 캐시 로직 테스트 (searchDate 기반 새로고침 포함)
- [x] 4.3.3 주말/공휴일 순차 fallback 테스트
- [x] 4.3.4 API 실패 + 캐시 없음 에러 상태 테스트
- [x] 4.3.5 deal_bas_r 쉼표 파싱 테스트
- [x] 4.3.6 비정상 환율값(0, 음수) 검증 테스트

### 태스크 요약

| 마일스톤 | 태스크 수 |
|----------|----------|
| 0. 온보딩 | 3개 |
| 1. 계산기 화면 완성 | 30개 |
| 2. 환율 로직 구현 | 14개 |
| 3. 오프라인 대응 | 10개 |
| 4. 테스트 코드 | 17개 |
| **합계** | **74개** |

---

## 9. 개선 백로그

| 출처 | 항목 | 우선순위 |
|------|------|----------|
| 리뷰 1.2 | 지원 통화 확장 (JPY, EUR, THB, VND, PHP, CNY 등) | High |
| 리뷰 4.2 | 통화 확장 시 검색/필터 기능 추가 | High |
| 리뷰 1.3 | 환율 알림 (목표 환율 푸시) | Medium |
| 리뷰 4.1 | Toast 스와이프 수동 닫기 | Low |
| 리뷰 5.1 | VoiceOver accessibilityLabel/Hint 추가 | Medium |
| 리뷰 5.2 | Dynamic Type 대응 | Low |
| 리뷰 6.5 | API 키 보안 강화 (CI/CD 주입 방식) | Medium |
| 리뷰 6.7 | 키 입력 debounce (성능 최적화) | Low |

---

## 10. V1 이후 계획

- Firebase 연동 (환율 API 프록시 서버)
- 앱스토어 배포 준비
- 추가 통화 지원 확장 (인기 여행지 기준 10~15개)
- 환율 추이 차트 (Swift Charts, iOS 17+)
- 홈 화면/잠금화면 위젯 (WidgetKit)
- 카메라 기능 (가격표 인식)
- 설정 화면 (기본 통화, 테마 등)
- Apple Watch 연동
- 계산 히스토리
- 더치페이/경비 분할
