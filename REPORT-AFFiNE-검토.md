# PolyON-Canvas — AFFiNE 원본 검토 및 목표 투영 리포트

**프로젝트 폴더**: `/Users/cmars/@Dev/PolyON-Module/PolyON-Canvas`  
**원본**: [toeverything/AFFiNE](https://github.com/toeverything/AFFiNE) (canary/stable)  
**타깃 저장소**: https://github.com/jupiter-ai-agent/PolyON-Canvas.git

---

## 1. AFFiNE 원본 요약

| 항목 | 내용 |
|------|------|
| **역할** | Notion + Miro 대안, 지식베이스·화이트보드·문서 통합 (local-first, 오픈소스) |
| **라이선스** | Community Edition: MIT, self-host 무료. Enterprise(SSO 등)는 별도 |
| **배포** | Docker Compose 권장. 이미지: `ghcr.io/toeverything/affine:stable` (또는 beta, canary) |
| **포트** | 3010 (기본) |
| **의존 인프라** | Postgres, Redis, 블롭 저장소(기본: 로컬 fs, 선택: S3/R2) |

---

## 2. 원본 인프라·설정 방식

### 2.1 환경변수 (공식 문서 기준)

- **DB**: `DATABASE_URL` 또는 `DB_USERNAME`, `DB_PASSWORD`, `DB_DATABASE` (Postgres)
- **Redis**: `REDIS_SERVER_HOST`, `REDIS_SERVER_PORT`, `REDIS_SERVER_USERNAME`, `REDIS_SERVER_PASSWORD`, `REDIS_SERVER_DATABASE`
- **이메일**: `MAILER_HOST`, `MAILER_PORT`, `MAILER_USER`, `MAILER_PASSWORD`, `MAILER_SENDER`
- **서버**: `AFFINE_SERVER_HOST`, `AFFINE_SERVER_PORT`, `AFFINE_SERVER_HTTPS`, `AFFINE_SERVER_EXTERNAL_URL`, `AFFINE_PRIVATE_KEY`
- **스토리지**: 기본은 `UPLOAD_LOCATION`(로컬 디렉터리). S3/R2는 **Admin Panel → Storage**에서 JSON 설정 (env 아님)
- **OAuth/OIDC**: **Admin Panel → Settings → OAuth**에서 설정. Google/GitHub/OIDC(issuer 등) — env로 주입되는 공식 방식 없음

### 2.2 Docker Compose 구조 (공식)

- 서비스: `affine`(앱), `affine_migration`(기동 전 마이그레이션), `redis`, `postgres`
- 볼륨: `UPLOAD_LOCATION`, `CONFIG_LOCATION`, `DB_DATA_LOCATION`
- PolyON에서는 Postgres/Redis를 플랫폼 공용으로 쓰고, affine 컨테이너만 우리가 제어하는 형태가 자연스러움

### 2.3 인증·사용자

- 최초 기동 시 **Admin 계정 생성** (자체 사용자 DB)
- OAuth(OIDC 포함)는 Admin Panel에서 설정 후 사용. 계정 연동은 AFFiNE이 관리
- EE에서 SSO 등 확장 예정 — CE는 Admin Panel OIDC로 Keycloak 연동 가능

---

## 3. PolyON 목표 투영

### 3.0 Storage-first (only) — RustFS 필수

AFFiNE은 **local-first**로, 사용자 디스크·로컬 저장소를 전제로 할 수 있으나, PolyON에서는 **Storage-first(only)** 원칙을 적용한다.

- **원칙**: 회사 내부의 데이터는 회사 내부에서 관리한다. 모든 사용자 데이터는 PolyON이 제공하는 **RustFS(S3 호환)** 에만 저장된다.
- **의미**:
  - AFFiNE을 쓰는 **모든 사용자**에게 블롭·업로드·워크스페이스 바이너리 등은 **PolyON Resource RustFS** 한 곳에서만 유지된다.
  - 로컬 fs(`UPLOAD_LOCATION` 디스크)에 사용자 데이터를 두는 구성은 **사용하지 않는다**. 기본값인 fs 스토리지를 쓰지 않고, **기동 시점부터 S3(RustFS)를 유일한 블롭 저장소로 고정**한다.
- **구현 방향**:
  - PRC **objectStorage** claim을 필수로 두고, 해당 버킷(예: `canvas` 또는 `affine`)을 AFFiNE Storage 설정에 **초기 주입**한다.
  - Admin Panel에서 사용자가 Storage를 fs로 바꾸지 못하도록 하거나, 재기동 시 항상 RustFS 설정으로 덮어쓰는 정책을 고려한다 (구현 단계에서 결정).
- **원본 터치 여부**: **터치 불필요.** AFFiNE은 이미 Admin Panel → Storage에서 **aws-s3 호환** 스토리지를 지원한다. RustFS(S3 호환) 엔드포인트·버킷·자격증명을 **설정(초기 주입)** 으로 넣어 주면 되며, 소스 코드 수정 없이 설정만으로 Storage-first(only)를 만족시킬 수 있다.

### 3.1 저장소 운영 (AppEngine/Auto와 동일)

- **원본 소스 미포함**: AFFiNE 코드는 저장소에 두지 않고, **PolyON-Canvas 저장소에는 래퍼만** 둠.
  - Dockerfile: 공식 이미지 `ghcr.io/toeverything/affine` 베이스 + entrypoint·설정 주입
  - polyon-module/, scripts/, README 등만 보관 → 원본 터치 없이 업스트림 갱신 유지

### 3.2 PRC(Platform Resource Claim) 매핑

| PolyON 리소스 | AFFiNE 연동 방식 |
|---------------|------------------|
| **database** | Postgres → `DATABASE_URL` 또는 `DB_*` env로 주입 (직접 매핑 가능) |
| **objectStorage** | **필수.** 모든 사용자 블롭은 RustFS만 사용. AFFiNE이 S3를 Admin Panel JSON으로 받음 → 기동 시 **RustFS(S3) 설정을 반드시 초기 주입**하고, fs 스토리지는 사용하지 않음 |
| **smtp** | `MAILER_*` env로 직접 매핑 가능 |
| **auth** | Keycloak OIDC. AFFiNE은 Admin Panel OAuth 설정 → **env 없음**. n8n처럼 **설정 파일/DB/Admin API** 중 하나로 초기 주입 필요 (문서·코드 추가 확인) |
| **redis** | PolyON Redis 공용 사용 → `REDIS_SERVER_*` env로 매핑 (PRC에 redis 타입이 있으면 claim으로, 없으면 common-config 등) |

### 3.3 계정 정책 (AD·Keycloak)

- **1단계**: Keycloak OIDC로 로그인 가능하게만 해도 목표 충족. AFFiNE 자체 사용자와 병행 가능.
- **2단계**: PolyON Core가 AD 변동 시 AFFiNE 사용자 동기화하는 방식은, AFFiNE이 사용자 API/가져오기를 얼마나 열어두는지에 따라 설계 필요.

### 3.4 기술적 리스크·확인 사항

1. **OIDC 초기 주입**: Admin Panel만 있는지, 설정 파일(예: `CONFIG_LOCATION` 아래)이나 환경변수로 OIDC를 줄 수 있는지 **소스/문서 추가 확인** 필요. 없으면 n8n처럼 기동 후 한 번 API/설정 파일을 채우는 스크립트 검토.
2. **S3(블롭) 초기 주입**: Storage 설정이 Admin Panel JSON인지, 설정 파일로 로드되는지 확인 후, PRC objectStorage → 해당 설정으로 넣는 방법 결정.
3. **Health 엔드포인트**: K8s probe용 `/health` 또는 `/ready` 존재 여부 확인. 없으면 경로 또는 readiness 방식 문서화.
4. **Redis PRC**: 플랫폼에 Redis claim이 있으면 env만 주입하면 됨.

---

## 4. 권장 다음 단계

1. **PolyON-Canvas 래퍼 골격** (AppEngine 스타일)
   - `Dockerfile`: `FROM ghcr.io/toeverything/affine:stable`, entrypoint, polyon-module 복사
   - `entrypoint.sh`: DB/Redis 준비 대기, (가능하면) OIDC/Storage 설정 주입 후 affine 기동
   - `polyon-module/module.yaml`: PRC claims(database, objectStorage, smtp, auth, redis 유무 반영) 및 env 매핑 초안
2. **AFFiNE 소스에서 확인**
   - OIDC/Storage 설정이 파일로 로드되는 경로와 포맷
   - health/readiness 엔드포인트
3. **설정 주입 방식 확정**
   - 가능하면 env만으로, 불가 시 n8n과 유사한 init 스크립트로 설정 파일/DB 초기화

---

## 5. 요약

| 질문 | 결론 |
|------|------|
| 원본 터치 여부 | **터치 안 함** — 저장소는 래퍼만 두고, 공식 이미지 + env/설정 주입으로 PolyON 연동 |
| PRC 매핑 | database, smtp, redis는 env로 직접. objectStorage·auth는 Admin Panel 기반이라 **초기 주입 방식** 추가 조사 필요 |
| 목표 투영 | 1단계: Keycloak OIDC 로그인 + PRC 기반 DB/Redis/SMTP + **Storage-first(only) RustFS**. 2단계: AD 동기화는 AFFiNE 사용자 모델 확인 후 설계 |
| 스토리지 정책 | **Storage-first(only)** — AFFiNE local-first를 쓰지 않고, 모든 사용자 데이터는 PolyON RustFS에만 저장 (회사 내부 데이터 회사 내부 관리) |

이 리포트는 **프로젝트 폴더** `PolyON-Canvas` 에 두고, 이후 `module.yaml` 초안·Dockerfile·entrypoint 설계 시 기준으로 사용하면 됨.
