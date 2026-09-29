# Astra — Phase13 handoff

`phase13/skinned-character`에서 이어서 작업한다. `AGENTS.md`, `PHASE13.md`, `PHASE13_TEST_STATUS.md`를 읽는다. 기본 씬은 `scenes/phase13.tscn`.

- 현재 작업은 캐릭터 모델/스킨/18뼈대와 기존 움직임의 호환 연결이다. 완전한 애니메이션·IK·새 GI를 이미 구현했다고 해석하지 않는다.
- 네 월드 캐릭터·공방·KO잔상의 모델을 일치시킨다. 기존 1인칭 손과 원본 무기/충돌/스케일/싱크는 그대로다.
- native `assets/character13/buddy_rig.scn`과 생성기를 함께 제공한다. 변경 시 `tools/build_character13.gd`로 재생성하고 테스트한다.
- 저해상도 테스트 화면을 원화와 동일하다고 주장하지 말고, 같은 카메라에서 모델·대기·A포즈·준비·실제 피격을 비교한다. 몸/팔/다리의 극단적 변형은 다음 단계에서 사람이 확인해야 한다.
- 모든 이전 테스트와 `test_character13.py --matches`를 실행한다. 기존94개 접촉 검사는 `--character13`에서 동일한 assertion을 재사용한다.
- 몸체 가중치가 손과 다리 사이에 잘못 섞이지 않게 회귀검사를 유지한다. 뼈대는 authority FacingRoot/weapon_pivot 위에 올리지 않는다.
- 정확한 실행 환경/commit/asset hash/실제 렌더와 미확인 범위를 기록하고 feature branch/PR로 보고한다. 무단 병합/force-push/라이선스 변경 금지.
