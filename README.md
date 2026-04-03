# TravelCalculator — Vibe Coding Experiment

## About

이 레포는 **바이브 코딩(Vibe Coding)으로 생산성을 측정하기 위한 개인 실험 프로젝트**입니다.

Claude Code(Opus 4.6)와 대화하며 기존
[TravelCalculator](https://github.com/Chbee/TravelCalculator/tree/develop)
프로젝트를 포팅하고 완성해 나가는 과정을 기록합니다.

## Goal

- 바이브 코딩만으로 실제 동작하는 iOS 앱을 완성할 수 있는지 실험
- AI와의 협업 과정에서 생산성, 코드 품질, 의사결정 속도를 관찰
- 기존 MVI 아키텍처를 유지하면서 새 프로젝트로 포팅 + 미완성 기능 개발

## Reference

| 항목 | 내용 |
|------|------|
| 원본 프로젝트 | [Chbee/TravelCalculator](https://github.com/Chbee/TravelCalculator) (develop) |
| 원본 진행률 | 14/48 tasks (29%) — 계산기 UI 78% 완료 |

## Tech Stack

| 항목 | 기술 |
|------|------|
| Language | Swift 6.0 |
| Framework | SwiftUI |
| Architecture | MVI (Model-View-Intent) |
| Min iOS | iOS 18 (95%+ market share) |
| Concurrency | Strict Concurrency (MainActor default) |
| AI Tool | Claude Code (Opus 4.6, 1M context) |

## Project Structure

```
TravelCalculator/
├── TravelCalculatorApp.swift        # App entry point
├── ContentView.swift                 # Root view
├── Core/                             # DI, Extensions, Utilities
├── Domain/Models/                    # Currency enum
├── Data/                             # Network, Location, Permission
└── Presentation/
    ├── Calculator/                   # MVI: 계산기 (9 files)
    ├── CurrencySelect/               # MVI: 통화 선택 (4 files)
    ├── Components/                   # 재사용 컴포넌트
    └── Common/Toast/                 # 토스트 알림 시스템
```

## Milestones

| # | Milestone | 상태 | 설명 |
|---|-----------|------|------|
| 1 | Calculator UI | 🔄 포팅 중 | 사칙연산, 숫자 포맷, 통화 선택, 입력 제한 |
| 2 | Exchange Rate | ⏳ 대기 | 한국수출입은행 API 연동, 실시간 변환 |
| 3 | Offline Support | ⏳ 대기 | 캐시, 네트워크 모니터링, 오프라인 UI |
| 4 | Testing | ⏳ 대기 | 유닛 테스트, 엣지 케이스 검증 |

## Vibe Coding Log

> 바이브 코딩 세션별 기록

### Session 1 (2026-04-02)
- 레포 분석 및 설계 플랜 수립
- 기존 TravelCalculator 32개 파일 아키텍처 분석 완료
- iOS 버전 점유율 분석 → 최소 iOS 18 결정
- MVI 포팅 전략 및 iOS 26.2 strict concurrency 적응 사항 정리
- `Infrean20260327` → `TravelCalculator` 리네이밍
- Plan.md 및 README.md 작성
