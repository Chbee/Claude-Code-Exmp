# TravelCalculator 기획서 — 개요 / Toast / 온보딩

> 2차 인터뷰 기반 최종 확정본 | 2026-04-05
> 관련: [계산기/환율 변환](Spec-Calculator.md) | [환율/통화/오프라인](Spec-ExchangeRate.md) | [화면 설계](Spec-UI.md) | [아키텍처](Spec-Architecture.md) | [데이터 모델](Spec-DataModel.md) | [태스크](Spec-Tasks.md)

---

## 1. 프로젝트 개요

### 1.1 앱 소개
여행지에서 가격/환율 계산을 빠르게 처리하는 iOS 계산기 앱.
사용자가 현지 통화 금액을 입력하면, 실시간 환율을 기반으로 원화(KRW)로 변환된 결과를 즉시 보여준다.

### 1.2 핵심 가치
- **즉시성**: 입력과 동시에 변환 결과 확인
- **직관성**: iOS 기본 계산기 앱(`Calculator.app`)의 키 입력 동작을 기준으로 한다.
  구체적인 호환 항목은 Spec-Calculator §2.1.4(AC/C 토글), §2.1.5(`=` 반복, 연산자 연속, 피연산자 없는 `=`)에 정의.
  환율 기능은 위 동작을 변경하지 않고 디스플레이 영역과 통화 선택만 추가한다.
- **오프라인 대응**: 네트워크 없이도 캐시된 환율로 사용 가능

### 1.3 타겟 사용자
- 해외 여행 중 현지 가격을 원화로 빠르게 환산하고 싶은 한국인 여행자

### 1.4 기술 요구사항
- iOS 17+ (최소 배포 타겟)
- iPhone 세로(portrait) 전용, iPad 미지원
- Swift 6.0, SwiftUI, @Observable
- 숫자 포맷 로케일 고정: 소수점 `.`, 천단위 `,` (기기 로케일 무시)

---

## 2. 기능 명세 (요약 + 링크)

| 영역 | 위치 |
|---|---|
| §2.1 기본 계산기 | [Spec-Calculator §2.1](Spec-Calculator.md#21-기본-계산기) |
| §2.2 환율 변환 | [Spec-Calculator §2.2](Spec-Calculator.md#22-환율-변환) |
| §2.3 통화 선택 | [Spec-ExchangeRate §2.3](Spec-ExchangeRate.md#23-통화-선택) |
| §2.4 환율 API 연동 | [Spec-ExchangeRate §2.4](Spec-ExchangeRate.md#24-환율-api-연동) |
| §2.5 오프라인 대응 | [Spec-ExchangeRate §2.5](Spec-ExchangeRate.md#25-오프라인-대응) |
| §2.6 Toast 알림 | 본 문서 §2.6 ↓ |
| §2.7 온보딩 | 본 문서 §2.7 ↓ |

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
- 스프링 애니메이션으로 등장/퇴장: `Animation.spring(response: 0.45, dampingFraction: 0.86)` (`blendDuration` 기본값 0)
  - 정의 위치: `ToastManager.swift` / `ToastModifier.swift` (코드 중복 — 단일 출처화는 후속 task)
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
   - **환율 로딩 완료(`loaded`)**: 즉시 정상 변환
   - **환율 로딩 중(`loading`)**: rate row 내부에 `ProgressView` 스피너 표시 (`scaleEffect(0.6)`, `tint(.appTextSub)`). 키패드는 활성 — 사용자 입력은 가능하나 환율 미로드 상태이므로 변환 결과는 `0`으로 표시(Spec-Calculator §2.2.1 fallback). 새로고침 버튼은 비활성.
   - **환율 실패(`error`) + stale 캐시 있음**: stale 캐시로 변환 진행, offline 인라인 시각 표기(Spec-ExchangeRate §2.5.2)로 안내
   - **환율 실패(`error`) + 캐시 없음**: Spec-ExchangeRate §2.5.4 환율 미가용 에러 배너 진입
   - "로딩 완료"는 `isLoading=false` 시점을 의미하며 `loaded`와 `error` 모두 포함

#### 2.7.5 기본 변환 방향
- 온보딩 완료 직후: `.selectedToKRW` (외화 → KRW)
