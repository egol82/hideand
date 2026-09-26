# Phase 2 검증 결과

확인일: 2026-09-27 (한국시간).

## 실제 엔진 검증 완료

검증한 게임/테스트 코드 커밋: `57a1e319161efe856e4e385d1ff29b34ce6c753b`

실행 기록: https://github.com/egol82/hideand/actions/runs/36257887222

| 환경 | 결과 |
|---|---|
| Linux, Godot 4.4.1 | 자동 엔진 검사 성공 |
| Linux, Godot 4.7.2 | 자동 엔진 검사 및 실제 렌더 캡처 성공 |
| Windows Server 2025 CI, Godot 4.7.2 | headless 자동 엔진 검사 성공 |

### 확인한 완료 로그

```text
PHASE1_UNIT_RESULT: 52 checks, 0 failures
PHASE2_UNIT_RESULT: 115 checks, 0 failures
PHASE2_INTERACTION_RESULT: 27 checks, 0 failures
PHASE1_SMOKE_READY: scene and drawing UI initialized
PHASE2_SMOKE_READY: draw/hide/seek/reveal/duel/escape/result initialized
PHASE2_AUTOPLAY_RESULT: {"captures":6,"duels":51,"escapes":45,"hits":281,"rounds":4}
```

고유 검사 항목은 194개다. 별도로 두 씬 초기화와 실제 물리/봇 AI를 사용하는 4라운드 자동 진행을 확인했다. 위 통계는 고정 시드의 회귀검사 1회 결과이며 밸런스나 재미의 성과 지표가 아니다. 현재 규칙·봇에서는 탈출이 많이 발생하므로 사람 플레이테스트로 조정해야 한다.

## 실제 화면 증거

Linux의 Godot Compatibility 렌더러 + Mesa llvmpipe 소프트웨어 OpenGL/Xvfb에서 1280×720 화면 5장을 생성했다.

- `01_drawing.png`: 실제 그림판과 입체 무기 미리보기
- `02_seeking.png`: 실제 거실 탐색 화면
- `03_reveal.png`: 발견과 무기 공개
- `04_duel.png`: 실제 전투 씬의 공격 자세
- `05_result.png`: 라운드 결과 UI

`godot-4.7.2-validation` 워크플로 아티팩트에 캡처, 로그, 정확한 해당 커밋의 `git archive` 소스 ZIP이 들어 있다. `godot-windows-4.7.2-validation`에는 Windows 로그가 있다. 보존 기간은 7일이다. 이후 커밋의 결과는 그 커밋에 연결된 CI를 다시 확인한다.

첫 렌더에서 발견한 과노출과 선택된 체크박스 글자 대비를 수정했고 재캡처를 확인했다. CI 화면 캡처는 오디오 장치가 없는 환경에서 `--audio-driver Dummy`를 사용한다. 이를 실제 음향 출력 검증으로 해석하지 않는다.

## 입력 처리 통합검사의 의미

자동화된 테스트가 실제 그림판의 마우스 입력 처리 함수, 장착, 빈 그림 차단, 일시정지, E 숨기·나오기·검사, 발견, 포획, 재시작, 시간 만료를 호출했다. OS 수준의 사람이 직접 마우스를 움직인 사용성 검사는 아니다. 실행 도중 테스트 호출의 배열 타입 오류를 수정했으며, 테스트가 멈추면 무한 대기하지 않고 실패로 보고하도록 실행 프레임 상한과 완료 마커 검사를 추가했다.

## 아직 검증하지 않았거나 범위 밖인 것

사람이 느끼는 재미·타격감·난이도, 실제 오디오 장치, Windows GPU 렌더링과 FPS, Windows 배포 EXE, 저장 실패·권한·중단 상황 전체, 패드, 한글 UI, 온라인 멀티, Steam 연동, 상용급 아트 완성도는 별도 작업이다. 생성한 콘셉트 원화 수준까지 도달했다고 주장하지 않는다.

오프라인 `verify_project.py`의 92개 정적 검사는 위 엔진 검사와 별개이며, 정적 검사만으로 동작을 입증하지 않는다. 이 문서 업데이트 자체는 검증한 게임 코드를 변경하지 않는다.
