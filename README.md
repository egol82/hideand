# Hide & Smashing · Phase 1

직접 그린 선을 입체 장난감 무기로 만들어 시험하는 Godot 3D 프로토타입 소스입니다.

현재 상태: SOURCE_READY / ENGINE_VALIDATION_PENDING

GitHub 저장소: egol82/hideand (public). 루트 LICENSE의 All Rights Reserved 고지가 적용됩니다.

## 작성된 기능
- 작은 3D 거실, 조작 캐릭터 1명, 연습 상대 2명
- WASD 이동, 마우스 조준, 휘두르기, 대시, 넉백
- 벡터 그림판, 되돌리기/지우기, 색상, 손잡이, 로컬 저장
- 그린 선을 실제 3D 튜브 메시로 생성
- 무기·캐릭터·소품에 같은 무광 재질 규칙 적용
- 선 기반 타격 샘플과 가구/벽 차단 검사
- 상자 근처 E 키 숨기/나오기 수동 테스트
- 간단한 타격 효과음/파편/히트스톱

## 무기 표현 범위
Phase 1은 입체 튜브 선그림 무기입니다. 원본 선을 다른 기성 무기로 치환하지 않습니다. 닫힌 윤곽 내부 자동 채우기나 의미 기반 완성형 3D 복원은 아직 없습니다.

## 실행 준비
목표 검증 버전은 Godot 4.7.2 Standard (GDScript)입니다.

1. project.godot를 Godot에서 가져옵니다.
2. tools/test.ps1 또는 tools/test.sh를 실행합니다.
3. F5로 프로젝트를 실행합니다.
4. 그림판에서 직접 그리거나 예시를 선택하고 EQUIP & PLAY를 누릅니다.

## 조작
- WASD: 이동
- 마우스: 조준
- 왼쪽 클릭: 휘두르기
- Shift: 대시
- Tab: 그림판
- Esc: 그림판 닫기
- E: 상자 근처 숨기/나오기
- R: 초기화
- F2: 타격 샘플
- F3: 움직이는 연습 상대
- F12: 화면 저장

## 구성
project.godot
scenes/main.tscn
scripts/
tests/
tools/
docs/
reference/

온라인 멀티플레이, Steam 연동, 정식 매치, 자동 술래, 완성형 3D 무기 복원은 Phase 1에 포함되지 않습니다.

Astra는 docs/ASTRA_START.md부터 읽고 실제 Godot 컴파일·실행 검증을 먼저 수행하세요.
