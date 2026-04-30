#!/usr/bin/env bash
# UserPromptSubmit hook: review 키워드 감지 시 spec-auditor 서브에이전트 자동 호출 reminder
# 차단하지 않음 — exit 0 유지

INPUT=$(cat)

# 1. 이미 /audit, /review, /security-review 슬래시 커맨드로 명시된 경우 패스 (중복 발화 방지)
if echo "$INPUT" | grep -qE '^\s*/(audit|review|security-review)\b'; then
  exit 0
fi

# 2. 과거형/완료형 + 트리거 단어 동시 출현 → 단순 보고/회상으로 간주, 패스
#    예: "리뷰 받았어", "이미 결재됐음", "audit 끝남", "감사 마쳤어"
if echo "$INPUT" | grep -qE '(받았|이미|끝났|완료|했음|했어|했네|됐음|마쳤|끝낸|끝냈)' && \
   echo "$INPUT" | grep -qiE '(리뷰|review|결재|audit|감사|점검|검증)'; then
  exit 0
fi

# 3. 트리거 키워드 매칭 → spec-auditor 호출 reminder
#    한글: 리뷰/결재/감사/점검/검증/PR 올/머지 전/배포 전
#    영문: review/audit (word boundary로 audit log 등 일부 false positive 줄임)
if echo "$INPUT" | grep -qiE '(리뷰|결재|감사|점검|검증|PR 올|머지 전|배포 전|\breview\b|\baudit\b)'; then
  cat <<'EOF'
<system-reminder>
검토(review/리뷰/결재/audit/감사/점검/검증) 키워드가 감지되었습니다. 답변 전에 Agent 도구로 spec-auditor 서브에이전트를 호출하여 spec ↔ 코드 정합성 audit 리포트를 먼저 받고, 결과를 답변에 포함하세요.

호출 인자
- 사용자가 phase를 명시했으면 (예: "phase-c 리뷰") 해당 phase 이름
- 아니면 인자 없음 (전체 audit)

일반 코드 변경 리뷰(/review, /security-review)와는 별도 도구이며, 필요 시 함께 수행 가능합니다. 사용자 요청이 명백히 spec audit과 무관한 경우(예: "PR 리뷰가 끝났다"는 단순 보고)에는 호출 생략하세요.
</system-reminder>
EOF
fi

exit 0
