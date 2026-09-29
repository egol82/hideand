# Hide & Smashing — Phase 14

직접 그린 무기로 숨바꼭질하고 반격하는 장난감 게임. 이번 단계는 **재질·Shader 2세대**입니다.

- 비닐 캐릭터/손: 넓은 코팅 반사와 절제된 색 변화.
- 폼 무기: 무광 표면, 작은 기공과 기존 단면/테두리 차이.
- 천: 직조 방향과 미세 표면. 도색 목재: 절제된 결/코팅. 벽/도자기도 구분합니다.
- 메뉴/일시정지 → 그래픽 비교 → C → **재질1세대/2세대**. 조명과 모델을 바꾸지 않고 비교합니다. 미세 표면은 따로 끌 수 있습니다.

`project.godot` → Godot Standard에서 F5 → 게임 또는 무기 공방.
최신 브랜치 `phase14/material-shaders`, 기본 씬 `scenes/phase14.tscn`입니다. 이전 씬과 main은 자동 병합/교체하지 않았습니다.

Phase13의 연결된 몸체/18뼈대, 둥근1인칭 손, 그린 크기와 비례하는 무기/낮은 위치/타격싱크,7개맵/숨바꼭질 도구,모험수첩UI와 저장/조작을 유지합니다. 이 단계는 새로운GI나 애니메이션 제작이 아닙니다.

검사: `GODOT_BIN=/path/to/godot python tools/test_material14.py --matches`.
실제 렌더 검사: 디스플레이/Xvfb에서 `--capture` 추가.
문서: `docs/PHASE14.md`, `docs/PHASE14_TEST_STATUS.md`, `docs/ASTRA_START.md`.

실제 화면과 자동검사로 확인한 범위만 기록합니다. 상용아트 동등성/모든GPU의 성능/사람의 재미·멀미·은신공정성은 별도 검증 대상입니다. 엔진·폰트 파일이나 유료에셋/API는 포함하지 않습니다. LICENSE 보존.
