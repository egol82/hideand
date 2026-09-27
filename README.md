# Hide & Smashing — Phase 5

직접 그린 모양을 입체 장난감 무기로 쓰는 1인칭 숨바꼭질·반격 게임의 품질 개선 버전입니다.

**브랜치 `phase5/playability-and-recovery` · 기본 씬 `scenes/phase5.tscn`**

## 이번에 달라진 점

- 시간제한·점수 없는 무기 연습장: 직접 그리기, 실제 이동·대시·명중, 다시 그리기. 안내와 명중/막힘/헛스윙 카운터.
- 포획된 동안 다음 라운드 무기를 그립니다. 현재 경기는 계속되고, 현재 무기/점수/상대의 비공개 위치에는 영향이 없습니다. 마지막 라운드에는 준비 버튼을 표시하지 않습니다.
- 이동/공격/대시/은신/조용한 이동/도발/지도/그림판의 11개 키·마우스 바인딩 변경. 중복과 고정 메뉴 키 거부, 기본값 복원, 실제 키에 맞는 HUD 안내.
- 한국어/영어 주요 메뉴·그림판·연습 안내·설정·결과 화면. OS 시스템 글꼴을 사용하며 폰트 파일은 동봉하지 않습니다. 일부 이전 월드 라벨·디버그/상황 메시지는 영어로 남습니다.
- 무기/설정/키 저장의 크기·내용·무결성 검사, 임시 파일 교체와 이전 정상본 백업. 복구 시 알려주고, 슬롯 덮어쓰기는 두 번째 클릭에서 확정합니다.
- 새 결함 수정: 피격 때 외형이 찌그러지면서 실제 무기 크기도 바뀌던 문제. 외형만 변형하고 판정용 무기는 회전 전용 루트에 분리했습니다.
- 눈 깜박임·공격/피격 표정, 폼/나무/천의 작은 절차적 표면, 공유 메시 캐시와 거실 장식 개선.

## 실행

Godot Standard에서 `project.godot` 열기 → F5 → 연습장 또는 경기. 배포 EXE가 아닙니다.
사람 1명 + 봇 3명, 4라운드, 기존 FIELD/CLASSIC과 3개 맵/활성 구역을 유지합니다.

기본 키: WASD 이동 / 마우스 시선 / LMB 공격 / Shift 대시 / Ctrl 조용한 이동 / E 은신·검사 / C 도발 / M 지도 / Tab 연습 그림판·포획 후 다음 무기 / Esc 메뉴.
Esc·Enter·F11·F12는 메뉴/화면 제어를 위해 고정입니다. 지원하는 재지정 키 범위와 저장 제약은 `docs/PHASE5.md`에 있습니다.

## 실제 검사

```sh
python tools/verify_project.py
# GODOT_BIN에 Godot Standard 실행 파일의 절대 경로 지정
bash tools/test.sh
bash tools/test_phase3.sh
python tools/test_phase4.py
python tools/test_quality.py
# 그래픽 세션에서는
python tools/test_quality.py --capture
```

Windows에서 앞의 두 셸 스크립트는 동명의 .ps1을 사용합니다. 나머지 Python 검사기는 공통입니다.
테스트 로그·완료 마커·실제 캡처는 해당 커밋의 CI 아티팩트와 `docs/PHASE5_TEST_STATUS.md`에서 확인하세요.

## 코드 구조 / 범위

Phase 5는 새로운 상속 단계를 만들지 않고 기존 `scripts/phase4/` 컨트롤러를 개선하고 `scripts/quality/`에 저장·입력·연습·다음 그림·언어 기능을 분리했습니다. 이 브랜치의 `scenes/phase4.tscn`도 개선된 컨트롤러를 사용합니다. 이전 Phase 4의 정확한 스냅샷은 `phase4/production-feel` 브랜치에 유지됩니다. Phase 1~3 소스와 기존 LICENSE는 변경하지 않았습니다.

사람 플레이테스트, 실기기 마우스/오디오/GPU 성능, 온라인 4인, Steam, 패드, 배포 EXE, 베이크 GI/완전한 IK/상용 아트 완성은 아직 검증하거나 구현한 것이 아닙니다.
