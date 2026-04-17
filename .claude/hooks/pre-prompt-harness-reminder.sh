#!/usr/bin/env bash
# UserPromptSubmit hook: 구현 작업인데 /start-task 없이 시작하면 reminder 출력
# 차단하지 않음 — exit 0 유지

INPUT=$(cat)

# /start-task 로 시작하면 패스
if echo "$INPUT" | grep -qE '^\s*/start-task'; then
  exit 0
fi

# read-only 키워드만 있으면 패스 (확인/분석/알려/보여/읽어)
if echo "$INPUT" | grep -qE '(확인|분석|알려|보여줘|보여|읽어|검토|찾아|조회)'; then
  # 구현 키워드도 함께 없으면 패스
  if ! echo "$INPUT" | grep -qE '(구현|추가해|추가하|만들어|수정해|수정하|작성해|작성하|개발|코딩|변경해|변경하|리팩터|리팩토링|삭제해|삭제하|고쳐|고쳐줘|고쳐주|적용해|적용하)'; then
    exit 0
  fi
fi

# 구현 키워드 체크
if echo "$INPUT" | grep -qE '(구현|추가해|추가하|만들어|수정해|수정하|작성해|작성하|개발|코딩|변경해|변경하|리팩터|리팩토링|삭제해|삭제하|고쳐|고쳐줘|고쳐주|적용해|적용하)'; then
  echo "⚠️ 하네스 규칙: 구현 작업은 /start-task로 시작하세요. Plan Mode 인터뷰 + Codex 검증 후 TDD 진행."
fi

exit 0
