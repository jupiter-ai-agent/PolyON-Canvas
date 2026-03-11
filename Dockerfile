# PolyON-Canvas (AFFiNE) — 원본 미포함, 래퍼만
FROM ghcr.io/toeverything/affine:stable

WORKDIR /app

# PolyON 모듈 매니페스트 및 문서
COPY polyon-module/ /polyon-module/

# 엔트리포인트 (DB/Redis 대기 후 기동)
COPY --chmod=755 entrypoint.sh /entrypoint.sh

EXPOSE 3010

ENTRYPOINT ["/entrypoint.sh"]
