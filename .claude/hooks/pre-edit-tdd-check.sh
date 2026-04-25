#!/usr/bin/env bash
# PreToolUse(Edit|Write) hook: TDD 가드 — Store/Reducer/Models 레이어에 테스트 없으면 차단

INPUT=$(cat)

# file_path 추출 (JSON에서)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    path = data.get('tool_input', data).get('file_path', '')
    print(path)
except:
    print('')
" 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# TravelCalculator/ 하위 .swift 파일인지 체크
if ! echo "$FILE_PATH" | grep -qE 'TravelCalculator/.*\.swift$'; then
  exit 0
fi

# Tests/ 디렉토리이면 패스
if echo "$FILE_PATH" | grep -qE '/Tests/'; then
  exit 0
fi

# Store/Reducer/Models 레이어만 차단 (View 등 다른 레이어는 패스)
if ! echo "$FILE_PATH" | grep -qE '/(Store|Reducer|Models)/'; then
  exit 0
fi

# 파일 베이스명 추출
BASENAME=$(basename "$FILE_PATH" .swift)
PROJECT_ROOT=$(echo "$FILE_PATH" | sed 's|/TravelCalculator/.*||')

# 대응 테스트 파일 탐색: {Name}Tests.swift
TEST_FILE_FOUND=$(find "${PROJECT_ROOT}" -name "${BASENAME}Tests.swift" 2>/dev/null | head -1)

if [ -z "$TEST_FILE_FOUND" ]; then
  echo "⛔ TDD 차단: $(basename "$FILE_PATH") 에 대응하는 테스트 파일(${BASENAME}Tests.swift)이 없습니다. Red 단계 테스트 먼저 작성하세요."
  exit 2
fi

exit 0
