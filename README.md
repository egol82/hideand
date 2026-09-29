# Hide & Smashing — Phase 13

직접 그린 무기로 숨고 반격하는 장난감 게임입니다. 최신 브랜치는 `phase13/skinned-character`, 기본 씬은 `scenes/phase13.tscn`입니다.

## 이번 변경: 캐릭터 모델과 뼈대

몸통·머리·팔·둥근 손·다리·발·귀가 이어지는 단일 몸체에 실제18개 뼈와 스킨 가중치를 넣었습니다. 팔을 움직이면 메시가 변형됩니다. 얼굴은 머리 뼈를 따르고, 기본 대기·A포즈·무기 준비 자세를 확인할 수 있습니다.

네 캐릭터·공방 미리보기·KO 잔상에 적용했습니다. 기존 1인칭 둥근 손, 그린 크기 그대로의 무기, 낮은 대기 자세, 타격 싱크·숨바꼭질 규칙·일곱 맵과 메뉴는 유지합니다.

## 실행

Godot Standard에서 `project.godot` → F5 → 무기 공방 또는 게임 시작.
모델/뼈대만 편집하려면 `assets/character13/buddy_rig.scn`을 여세요.

`docs/PHASE13.md`, `docs/PHASE13_TEST_STATUS.md`, `AGENTS.md`를 먼저 읽습니다. 엔진검사는 `python tools/test_character13.py --matches`입니다.

실제 스킨드 모델이지만 완성된 애니메이션/전신IK/상용 아트 승인 단계는 아닙니다. Phase14 셰이더·Phase15 조명 작업은 이번에 포함하지 않았습니다. 사람의 재미·멀미·Windows GPU/FPS와 온라인/Steam/EXE는 별도 검증 대상입니다. LICENSE·이전 브랜치·main은 보존합니다.
