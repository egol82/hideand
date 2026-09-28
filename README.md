# Hide & Smashing — 둥근 손·큰 무기·타격 싱크 후속판

최신 브랜치: `phase9/followup-cute-grip-sync`. 기본 씬: `scenes/phase9_followup.tscn`.

- 손가락을 세분화한 손 대신 둥근 장난감 손과 작은 엄지 패드를 사용합니다.
- 1인칭 무기를 크게 표시하지만 원본 그림·실제 사거리·피해는 유지합니다.
- 실제 접촉 표본을 화면 속 무기의 접촉점에 맞추고, 효과·몸짓을 같은 접촉 순간에 시작합니다.
- Phase 9의 6개 맵, FIELD/CLASSIC, 사람 1명+봇 3명, 연습장, 탈락 후 무기 제작, 키 변경, 저장·복구와 주요 한/영 UI를 유지합니다.

## 실행

Godot Standard에서 project.godot → F5 → 연습장 또는 게임 시작.
기존 `scenes/phase9.tscn`은 이전 손·연출 비교용으로 남아 있습니다. main과 이전 PR은 자동 병합하지 않았습니다. LICENSE 보존.

## 구현과 검증

`AGENTS.md`, `docs/CUTE_SYNC.md`, `docs/CUTE_SYNC_TEST_STATUS.md`, `docs/ASTRA_START.md`를 읽으세요.
`GODOT_BIN=/path/to/godot python tools/test_sync.py --matches`가 새 검사 및 12경기를 실행합니다. `--capture --video`는 실제 입력과 충돌로 화면을 만듭니다. 기존 회귀 검사도 유지합니다.

전체 스윙의 완벽한 무관통, 모든 그림의 손 IK, 실제 Windows GPU 성능, 사람의 조작감·재미·멀미, 스피커 지연, 온라인/Steam/배포 EXE는 검증 범위 밖입니다. 글꼴·엔진 바이너리·유료 에셋·사용자 저장 데이터는 소스에 포함하지 않습니다.
