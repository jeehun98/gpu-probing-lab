# GPU Probing Lab Vision

GPU Probing Lab은 GPU 내부 행동을 실험적으로 드러내는 연구 프로젝트이다.

GPU는 결정론적 시스템이지만 내부 동작은 완전히 공개되지 않는다.

따라서 우리는 GPU를 다음과 같은 방식으로 연구한다.

probe program
→ execution observation
→ behavior inference


이 프로젝트는 GPU를 **black-box hardware system**이 아니라

**experimentally observable computational system**

으로 다루는 접근을 취한다.