# Hide & Smashing · Phase 6

**직접 그린 입체 장난감 무기로 숨바꼭질하고 반격하는 1인칭 Godot 게임의 그래픽 개선판입니다.**

최신 작업 브랜치: `phase6/graphics-polish`. 기본 씬: `scenes/phase6.tscn`.

## 이번 변화

대표 거실의 창문·커튼·램프·벽 마감·천장·바닥·러그를 정리하고, 폼/비닐/목재/천 재질의 표면·조명 반응을 구분했습니다. 손·무기의 가장자리와 미리보기 조명, 버튼 표현도 개선했습니다. 이미지 생성 목업을 띄우는 방식이 아니라 실제 엔진 메시·재질·조명입니다.

플레이어 원본 그림과 타격 표본은 그대로입니다. 별도 `GraphicsDirector`가 장면에 그래픽을 적용하며, 기존의 이동/점수/시간/숨기/저장 로직은 변경하지 않습니다.

## 실행

Godot Standard에서 `project.godot` 가져오기 → F5 → **연습장** 또는 **게임 시작**.

- 연습장: 시간·점수 없이 무기를 그리고 직접 이동·타격합니다.
- 경기: 사람 1명 + 봇 3명, 3개 맵, FIELD 현장 교전 / CLASSIC 중앙 결투.
- 포획 후 다음 라운드 무기 준비, 조작키 변경, 한국어/영어 주요 UI, 8개 무기 저장 슬롯과 백업 복구를 유지합니다.
- 기본 WASD 이동, 마우스 조준, 왼쪽 클릭 공격, Shift 대시, E 상호작용, Tab 그림판. 설정에서 변경할 수 있습니다.

## 구조 / 검증

`scenes/graphics/lounge_dressing.tscn`은 편집 가능한 대표 방 장식 배치입니다. `scripts/graphics/`와 `shaders/`가 재질·기하·조명 표현을 담당합니다. 실제 게임은 기존 `scripts/phase4/` 및 `scripts/quality/`를 계속 사용합니다.

`docs/PHASE6.md`, `docs/PHASE6_TEST_STATUS.md`, `docs/ASTRA_START.md`에서 구현 범위와 실제 검사 상태를 확인하세요. 전체 기존 검사와 `python tools/test_graphics.py`를 함께 실행합니다. `--capture`는 실제 화면 7장을 생성합니다. 실행기는 `GODOT_BIN`으로 지정합니다.

**상용 완성 아트·실제 Windows GPU 성능·사람 플레이테스트·온라인·Steam 출시 완료를 의미하지 않습니다.** UV2/조명 베이크와 완전한 손 IK는 아직 없습니다. 한국어에는 OS의 CJK 글꼴이 필요하며 글꼴 파일을 동봉하지 않습니다.

루트 LICENSE는 사용자가 지정한 All Rights Reserved이며 변경하지 않았습니다. 이전 브랜치는 보존되고 자동 병합하지 않습니다.
