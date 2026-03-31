# Draft: SteamPhone 프로젝트 현황 및 향후 계획

## 프로젝트 개요
Galaxy S20 FE (SM-G780F Exynos 990 / SM-G780G Snapdragon 865)를 SteamOS (Arch Linux ARM 기반)로 변환하는 프로젝트

## 현재 진행 상황 요약

### Kernel Component
- **상태**: 초기 단계 (인프라 준비됨, 핵심 컴포넌트 미비)
- **완료**: Exynos 990 및 Snapdragon 865용 defconfig 파일 존재
- **미완료**: 패치 파일 없음, DTB/DTS 파일 없음, 실제 커널 소스 없음 (빌드 시 다운로드)
- **빌드 스크립트**: 완비 및 기능 동작 확인됨

### Rootfs Component  
- **상태**: 부분 완료
- **완료**: 
  - 빌드 스크립트 완비 (ALARM base + SteamOS overlay)
  - steamphone-init 서비스 (하드웨어 초기화)
  - GPU 드라이버 설정 (Panfrost/Freedreno)
  - 시스템 서비스 (auto-login, session management)
- **미완료**: 
  - packages/ 및 base/ 디렉토리가 비어있음 (플레이스홀더만)
  - Gamescope 컴포지터 설치 로직 누락
  - Steam 클라이언트 설치 로직 없음
  - Box64/Box86 미포함
  - 터치스크린 게임패드 오버레이 미구현

### Gamescope (ARM 포팅)
- **상태**: 초기 단계
- **완료**: ARM 크로스컴파일 빌드 스크립트 존재
- **미완료**: ARM 패치 없음 (업스트림 직접 사용), 테스트/컴파일 미실행

### Steam + Box86/Box64
- **상태**: 부분 준비됨
- **완료**: 
  - Box64/Box86 빌드 스크립트 완비
  - Steam 설치 스크립트 존재 (box64로 Steam 실행)
  - Box64 설정 (Steam 최적화 포함)
- **미완료**: 
  - steam/configs/ 비어있음
  - Steam-Gamescope IPC 통신 미구현

### Drivers (드라이버 지원)
- **상태**: 낮음 (~30% 준비)
- **완료**: 
  - Display: S6E3FC3 AMOLED 패널 문서화 및 DTS 설정
  - GPU: Panfrost (Mali-G77) / Freedreno (Adreno 650) 설정 파일 존재
- **미완료**: 
  - WiFi, Bluetooth, Audio, Touch, Modem, Sensors - 모두 플레이스홀더

### Documentation (문서)
- **상태**: ~20% 완료
- **완료**: 
  - Architecture overview.md
  - Getting-started.md
- **미완료**: 
  - Contributing.md (존재하지 않음)
  - 상세 빌드 가이드 없음
  - Troubleshooting 가이드 부실
  - API/Integration 문서 없음

### CI/CD
- **상태**: 미설정 (.gitkeepのみ)

## 핵심 격차 (Critical Gaps)

1. **오디오 드라이버** - 게임에 필수적
2. **터치/입력 시스템** - 터치스크린 게임패드 오버레이 필수
3. **WiFi/Bluetooth** - Steam 클라이언트 연결에 필수
4. **DTB/DTS 파일** - 커널이 하드웨어를 인식하려면 필수
5. **커널 패치** - Exynos 990용 하드웨어 패치 없음
6. **Steam-Gamescope 통합** - 통신 메커니즘 미구현

## 물리적 디바이스 상태
- 디바이스: Galaxy S20 FE (SM-G780F - Exynos 990)
- Bootloader unlock: ???

## 오픈 질문
1. 사용자가 현재 가장 우선시하는 것이 무엇인가? (첫 부팅? 특정 기능?)
2. 물리적 디바이스에서 이미 어떤 테스트를 진행했는가?
3. Snapdragon 버전에 대한 지원 범위?
4. 테스트 인프라가 있는가?
