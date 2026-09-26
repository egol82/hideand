# 기술 근거와 설계 선택

참고 확인일: 2026-09-27.

Godot 공식 문서는 SurfaceTool/ArrayMesh로 런타임 메시를 만드는 방법을 제공한다. 이 프로젝트는 외부 이미지 생성 API 대신 벡터 입력을 코드로 3D 튜브로 만든다. Geometry2D의 가까운 선분 지점 계산은 손잡이를 그림에 붙이는 데 사용한다.

## 공식 참고 자료
- Godot 4.7.2 배포 페이지: https://godotengine.org/download/archive/4.7.2-stable/
- SurfaceTool API: https://docs.godotengine.org/en/stable/classes/class_surfacetool.html
- Geometry2D API: https://docs.godotengine.org/en/stable/classes/class_geometry2d.html
- Godot 엔진 라이선스: https://godotengine.org/license/

## Phase 1의 단순화
무기를 임의의 닫힌 다각형으로 해석하면 자기 교차, 구멍, 끊어진 선, 삼각분할 오류가 늘어난다. 그래서 먼저 선을 둥근 튜브로 만드는 명확하고 제한된 기하 표현을 선택했다. 덕분에 그린 선 자체가 메시와 판정의 공통 입력이 된다. 반대로 면이 차 있는 3D 무기가 자동 완성되지는 않는다.

타격은 선을 일정 간격으로 샘플링하고, 각 샘플의 이전/현재 위치 사이 구간과 연습 상대 중심 사이 거리를 비교한다. 연습 상대의 실제 캡슐 전체에 대한 정밀한 연속 충돌판정은 아니다. 빠르게 움직이는 상대, 낮은 프레임률, 공중 위치 등에서 실제 테스트와 보완이 필요하다.
