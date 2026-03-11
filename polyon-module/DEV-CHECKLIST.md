# PolyON-Canvas 개발 체크리스트

## 완료

- [x] Odoo 스타일 repo (원본 AFFiNE 소스 미포함)
- [x] Dockerfile: 공식 이미지 `ghcr.io/toeverything/affine:stable` + entrypoint
- [x] entrypoint: Postgres/Redis TCP 대기, DATABASE_URL 조합, `exec "$@"`
- [x] module.yaml: PRC (database, objectStorage, smtp, auth), env 매핑
- [x] Storage-first(only): objectStorage claim 필수, RustFS env 주입 (실제 사용은 Admin Panel 또는 초기 주입)

## 남은 작업

1. **Storage(RustFS) 초기 주입**
   - AFFiNE은 블롭 스토리지를 Admin Panel → Storage JSON으로 설정함. env 없음.
   - 설정 파일 경로(CONFIG_LOCATION 등) 또는 Admin API 확인 후, PRC objectStorage → S3 JSON을 기동 시 주입하는 스크립트 추가 검토.

2. **OIDC(Keycloak) 초기 주입**
   - OAuth/OIDC도 Admin Panel 설정. env 없음.
   - n8n과 유사하게 설정 파일/API로 issuer, clientId, clientSecret 등 주입 방식 확인 후 구현.

3. **Health 엔드포인트**
   - 현재 module.yaml health path: `/`. AFFiNE 공식 health/ready 경로가 있으면 반영.

4. **Redis**
   - 플랫폼에 redis claim 또는 common-config로 호스트/포트 주입되는지 확인 후, 필요 시 module.yaml env 수정.

5. **실제 배포 검증**
   - Operator로 module 설치 → DB/Redis/Ingress 연동 및 브라우저 접속 확인.
