# Codex / Astra — Phase 1 실행·수정·검증 지시서

당신은 Hide & Smashing PC 게임의 구현 담당자다. 이 저장소는 이미 작성된 Godot Phase 1 소스다. 새로 처음부터 생성하지 말고 기존 소스를 읽고 실제 Godot에서 작동하도록 마무리한다.

## 제품 의도
플레이어가 직접 그린 모양이 무기가 되는 귀여운 숨바꼭질 난투 게임이다. 최종 흐름은 그리기 → 숨기 → 발견 → 무기 공개 → 난투다. 이번 Phase 1은 무기 생성과 타격을 검증하는 오프라인 실험실이다.

## 우선 작업
1. AGENTS.md, README.md, docs/ART_BIBLE.md, docs/TEST_STATUS.md를 읽는다.
2. 목표 검증 버전 Godot 4.7.2 Standard에서 임포트·파싱 오류를 수정한다.
3. tests/test_weapon.gd를 실행한다. 테스트를 삭제하거나 약화하지 않는다.
4. --smoke-test로 메인 씬과 그림판 초기화를 확인한다.
5. GUI에서 직접 그리기 → 3D 미리보기 → 장착 → 이동 → 타격 → 넉백 → 재그리기를 검증한다.
6. docs/ACCEPTANCE.md를 실제로 체크하고 artifacts/에 실행 화면을 남긴다.

## 유지 조건
- Godot + GDScript 유지
- 원본 선을 실제 3D 튜브 메시로 사용
- PNG 스티커나 기성 무기로 사용자 그림을 치환하지 않음
- 무기/캐릭터/소품은 같은 무광 장난감 재질과 광원 체계
- 점/획/잉크/최대 길이 제한
- 손잡이는 실제 그림 선 위
- 공격 판정은 무기 모양과 대응
- 공격 1회당 같은 상대 1회 타격
- 벽·가구 너머 공격 금지
- 온라인/Steam/과금/유료 생성 API/계정은 Phase 1에 추가하지 않음

## 실행 예
powershell -ExecutionPolicy Bypass -File .\tools\test.ps1 -Godot "C:\Tools\Godot\Godot.exe"

GODOT_BIN=/absolute/path/to/godot ./tools/test.sh

godot --headless --path . --editor --import
godot --headless --path . --script res://tests/test_weapon.gd
godot --headless --path . -- --smoke-test
godot --path .

reference/ 이미지는 콘셉트이며 실제 실행 증거가 아니다.

실제 컴파일·구동·조작 검증 전에는 구현 완료라고 보고하지 않는다.
