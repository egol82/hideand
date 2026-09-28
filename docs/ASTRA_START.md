# Astra — Phase 8 handoff

`phase8/viewmodel-polish`에서 이어서 작업한다. `AGENTS.md`, `docs/PHASE8.md`, `docs/PHASE8_TEST_STATUS.md`를 먼저 읽는다. 기본 씬은 `scenes/phase8.tscn`이다. 이미 구현된 게임을 다시 만들지 않는다.

1. 이번 코드는 이미지 편집 결과를 PNG로 붙인 것이 아니라 실제 3D 손 메시·그립 배치를 수정한 것이다. 생성 참고안과 엔진 캡처를 구분한다.
2. 손잡이 주변 실제 획을 읽어 주손을 맞춘다. 충분히 긴 연속 축이면 양손, 짧으면 손목 받침이다. 무기 데이터·충돌·게임 규칙은 바꾸지 않는다.
3. 세 신규 맵에서 대기/준비/활성/회복, 긴 선/가로선/구멍/작은 그림과 손잡이 변경을 직접 검수한다. 극단적 그림의 관통은 여전히 사람 확인이 필요하다.
4. 원래 test.sh, test_phase3.sh, test_phase4.py, test_quality.py, test_graphics.py, test_maps.py와 새 test_grip.py를 실행한다. GODOT_BIN 지정. 실제 렌더는 Xvfb 또는 디스플레이에서 `python tools/test_grip.py --capture`.
5. 다음 변경에서도 손 모델은 view-only, 카메라 크기는 cosmetic-only, FacingRoot/AttackSpec/실제 표본은 authority-only 규칙을 지킨다. 화면 표시 모델을 기준으로 공격 범위를 바꾸지 않는다.
6. 정확한 커밋·종료코드·완료마커·실행 로그·실제 화면을 보고한다. 기존 브랜치, 공개 설정, LICENSE 보존. 승인 없는 병합·force push 금지.
