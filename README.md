# Hide & Smashing — Phase 10 Toy Studio

직접 그린 큰 장난감 무기, 둥근 손, 실제 접촉 타격 싱크를 유지한 Godot 그래픽 개선판입니다.

**최신 브랜치: phase10/toy-studio** · 기본 씬: scenes/phase10.tscn.

project.godot를 Godot Standard에서 열고 F5 → 맵 선택 → 연습장/게임 시작. 메뉴 또는 일시정지 화면의 **그래픽 비교**에서 A 이전 화면 / B 장면 마감+기본 재질 / C 전용 장난감 셰이더를 비교할 수 있습니다. 기본값 C, Compatibility 렌더러 유지.

대표 슈가 마켓: 새 케이크 진열대·아이싱·도색 패널·메뉴 보드·바닥. 공통: 폼/비닐/목재/천/벽/도자기 재질과 조명. 6개 맵과 기존 숨기·타격·키 변경·저장·8슬롯·다음 라운드 제작은 유지합니다. 판정·사거리·체력·점수·시간을 그래픽으로 바꾸지 않습니다.

편집 가능한 진열대 장면을 포함합니다. 별도 내보내기 도구는 정적 맵 메시와 실제 UV2를 생성합니다. LightmapGI 베이크는 별도 에디터 작업이며 기본 게임에 이미 적용됐다고 주장하지 않습니다. 실제 베이크 상태는 docs/PHASE10_TEST_STATUS.md를 확인하세요.

개발: AGENTS.md, docs/PHASE10.md, docs/PHASE10_TEST_STATUS.md, docs/ASTRA_START.md. 검사: GODOT_BIN=/path/to/godot python tools/test_studio.py --export --matches. 화면: --capture, 실제 타격 영상용 프레임: --contacts.

상용 아트/사람 플레이/Windows GPU 성능/온라인/Steam/EXE 완료판은 아닙니다. 글꼴·엔진·유료 에셋·개인 저장은 포함하지 않습니다. 기존 LICENSE와 브랜치 보존; main과 이전 PR은 자동 병합하지 않습니다.
