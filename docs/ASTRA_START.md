# Astra — Phase 9 handoff

`phase9/smash-reactions`에서 이어서 작업한다. `AGENTS.md`, `docs/PHASE9.md`, `docs/PHASE9_REFERENCE.md`, `docs/PHASE9_TEST_STATUS.md`부터 읽는다.

기본 실행 씬은 `scenes/phase9.tscn`. 새로운 게임을 다시 만들지 않는다. SmashDirector는 접촉 사실을 받아 별·코믹 문자·인형 외형·짧은 퇴장·효과음을 표현하는 observer다. 원본 무기/손 그립/공격 판정/점수/타이머는 고치지 않는다.

모든 기존 도구와 `python tools/test_smash.py --matches`를 실행한다. 실제 캡처는 디스플레이나 Xvfb에서 `python tools/test_smash.py --capture --video`. 이 캡처는 재현 가능한 접촉 fixture이며 사람 조작 영상이 아니다. 진짜 입력/충돌→연출 경로는 별도 검사한다.

다음 점검은 실제 사람의 연속 타격 피로·중첩 효과 가독성·오디오·벽 가까운 표현·복잡한 무기 접촉이다. 음소거/동작 줄이기로 판정이나 봇 청각이 달라지면 안 된다. 숨은 캐릭터의 좌표를 이펙트가 따라가면 안 된다. 정확한 커밋과 실행 결과만 보고한다. LICENSE/기존 브랜치 보존, 승인 없는 병합·강제 푸시 금지.
