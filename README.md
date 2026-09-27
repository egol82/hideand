# Hide & Smashing — Phase 4

직접 그린 입체 폼 장난감으로 숨고, 발견된 현장에서 반격하는 1인칭 오프라인 게임 프로토타입.

**기본 씬: `scenes/phase4.tscn` · 브랜치: `phase4/production-feel`**

첨부 프로덕션 감사의 네 결함을 수정하고 공격/입력/접촉 이벤트, 현장 교전, 대표 거실, 손·캐릭터·재질, 공간 음향과 HUD를 개선했습니다. 상용 아트·밸런스·온라인 완성을 선언하는 버전은 아닙니다.

## 핵심 변경
- 조준 누적 회전 제거. 동일 AttackSpec을 읽는 실제 무기와 1인칭 손, 100ms 입력 버퍼.
- 빠름/균형/무거움의 준비·활성·회복·넉백. 원본 그림 보존, 면적/사거리 예산, 모호한 구멍은 채우지 않음.
- 공격자/피격자/막힘/헛스윙 이벤트 분리. 접근성 설정과 게임 타이머 분리.
- 첫 탈출 +1(라운드당 한 번), 생존 +3, 미발각 생존 +2. 반복 탈출 점수 파밍 방지.
- FIELD 기본 모드: 0.55초 공개와 현장 8초 교전. 다른 생존 참가자는 계속 움직이고 숨습니다.
- CLASSIC 비교 모드: 중앙 5초 결투. 같은 점수·피드백 수정 적용.
- 세 큰 맵을 유지하고 4인용 활성 탐색 구역 선택 추가.
- 새 둥근 메시, 연속형 인형 몸체, 엄지/손목이 있는 손, 대표 거실 소파·쿠션·램프·그림.
- 공간 효과음/걸음·조용한 이동·도발 단서, 별도 편안함 설정, 작은 HUD와 개별 피격 방향.
- 8개 로컬 저장 슬롯, 기본 비활성 로컬 진단 기록, 제한된 효과/음성 풀.

## 실행
Godot Standard에서 `project.godot`를 열고 F5 → 맵/모드 선택 → PLAY. 설치형 EXE가 아닙니다. 사람 1명 + 봇 3명, 총 4라운드입니다.

WASD 이동 / 마우스 시선 / LMB 공격 / Shift 대시 / Ctrl 조용히 이동 / E 숨기·검사 / C 도발 / Esc 설정 / M 지도 / F12 실제 화면 저장.

## 검사
```sh
python tools/verify_project.py
# GODOT_BIN에 실제 Godot Standard 실행 파일 경로 지정
bash tools/test.sh
bash tools/test_phase3.sh
python tools/test_phase4.py
```
Windows에서는 앞의 두 셸 스크립트 대신 같은 이름의 `.ps1`을 사용합니다. Phase 4 Python 검사기는 Linux/Windows 공통입니다. `docs/PHASE4_TEST_STATUS.md`와 해당 커밋 CI를 확인하세요.

## 문서
- `docs/PHASE4.md`: 감사 항목별 구현과 남은 범위
- `docs/PHASE4_TEST_STATUS.md`: 실제 검사 및 한계
- `docs/ASTRA_START.md`: Astra 인계
- `tools/export_toy_room.gd`: 편집 가능한 대표 방 스냅샷. GI 베이크 도구가 아닙니다.

기존 Phase 1/2/3 씬과 코드, LICENSE는 보존했습니다. 온라인/Steam/패드/한글 UI/출시 EXE/프로덕션 수준 아트는 아직 미완료입니다. 이 저장소의 공개 여부와 별개로 기존 LICENSE가 적용됩니다.
