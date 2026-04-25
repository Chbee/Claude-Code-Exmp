# Figma 작업 참조

> Figma MCP를 통한 디자인 → SwiftUI 변환 시 사용하는 node-id 목록.

## 디자인 파일

https://www.figma.com/design/RHAP7WVgoX220lRhWseaWE/여행가계부

## 주요 node-id

| 영역 | node-id |
|------|---------|
| 계산기 화면 | `298-230` |
| Asset (컬러) | `99-875` |
| Component | `397-230` |
| Icon | `397-231` |

## 사용법

Figma MCP로 디자인 컨텍스트 가져올 때 fileKey + node-id 조합으로 호출.
출력은 React+Tailwind 참조 코드이므로 SwiftUI로 적응 필요 — 프로젝트의 기존 디자인 토큰(`Core/Theme/`)과 컴포넌트를 우선 재사용.
