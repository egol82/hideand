# Astra — Phase 7 handoff

`phase7/playful-map-pack`에서 이어서 작업한다. `AGENTS.md`, `docs/PHASE7.md`, `docs/PHASE7_MAP_RESEARCH.md`, `docs/PHASE7_TEST_STATUS.md`를 먼저 읽는다. 기본씬은 `scenes/phase7.tscn`, 컨트롤러는 기존 phase4/quality 컴포넌트다. 게임 전체를 다시 만들지 않는다.

1. 정확한 커밋과 테스트 로그를 확인한다. 실행/그림판/숨기/발견/반격/결과/연습장 흐름을 직접 검증한다.
2. 세 새 맵은 정적 단층 레벨이며 점프·기차 탑승·움직이는 발판이 없다. 뷰·콜라이더·nav·은신처 접근은 공통 plans.gd에서 함께 고친다.
3. 직접 그린 무기·FacingRoot·AttackSpec·점수·시간·저장·입력 불변식을 보존한다. 기존 세 맵의 좌표/콜라이더를 의도 없이 바꾸지 않는다.
4. 시끄러운 바닥과 조용한 우회로는 실제 발걸음에만 반응해야 한다. 숨어 있는 플레이어 위치를 봇이나 지도에 넘기지 않는다.
5. 검사: `python tools/verify_project.py`, `bash tools/test.sh`, `bash tools/test_phase3.sh`, `python tools/test_phase4.py`, `python tools/test_quality.py`, `python tools/test_graphics.py`, `python tools/test_maps.py`. GODOT_BIN 지정. 렌더는 실제 디스플레이나 Xvfb에서 `python tools/test_maps.py --capture --skip-matches`.
6. 다음 가치 있는 검증은 실제 사람의 동선·대시·은신처 재접근·소리 판독이다. 지도별 수색 시간·재발견 빈도·맵 선택 선호를 확인하고 숫자를 수정한다. 봇 수치를 사람 재미의 증거로 쓰지 않는다.
7. 필수 완료마커/오류로그/종료코드·실제 화면을 남긴다. 원본 LICENSE, 이전 브랜치, 공개 설정 보존. 무단 병합·force push 금지.
