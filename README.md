# PolyON-Canvas

**AFFiNE**을 [PolyON Platform](https://github.com/jupiter-ai-agent/PolyON-platform) 모듈로 동작하도록 구성한 저장소입니다.  
업스트림: [toeverything/AFFiNE](https://github.com/toeverything/AFFiNE).

**저장소 운영 방식**: [PolyON-AppEngine](https://github.com/jupiter-ai-agent/PolyON-AppEngine)과 동일하게 **AFFiNE 원본 소스는 포함하지 않습니다.** 공식 이미지를 베이스로 하고, PolyON용 래퍼(Dockerfile, entrypoint, polyon-module)만 두어 원본 터치 없이 업스트림 갱신을 유지합니다.

## Storage-first(only)

모든 사용자 데이터(블롭·업로드)는 **PolyON RustFS** 에만 저장됩니다. AFFiNE의 local-first(로컬 fs)는 사용하지 않고, 설정으로 S3(RustFS)를 유일한 스토리지로 둡니다. (회사 내부 데이터 회사 내부 관리.)

## PolyON 모듈 구성

- **PRC**: database, objectStorage(RustFS 필수), smtp, auth(Keycloak OIDC)
- **env**: `DATABASE_URL`, `REDIS_SERVER_*`, `MAILER_*`, `AFFINE_SERVER_*`, Storage용 `AFFINE_STORAGE_*` (초기 주입 스크립트용)
- **문서**: [polyon-module/module.yaml](polyon-module/module.yaml), [polyon-module/DEV-CHECKLIST.md](polyon-module/DEV-CHECKLIST.md), [REPORT-AFFiNE-검토.md](REPORT-AFFiNE-검토.md)

### 이미지 빌드

```bash
docker build -t polyon-canvas:latest .
```

PolyON Operator가 `module.yaml`과 위 이미지로 배포합니다.
