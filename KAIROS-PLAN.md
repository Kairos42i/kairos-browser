# KAIROS Browser — Plan Maestro de Fork y Mantenimiento

**Fork de**: browseros-ai/BrowserOS v0.44.0 (Chromium 146)
**Nuestro repo**: Kairos42i/kairos-browser
**Licencia**: AGPL-3.0

---

## 1. Estado Actual

### VERIFICADO experimentalmente

| Componente | Estado | Detalle |
|-----------|--------|---------|
| BrowserOS headless | Funciona | Chromium 146, CDP en puerto 9000 |
| browseros-cli v0.2.2 | Instalado | 40+ comandos para control |
| Server MCP (Bun) | Pendiente config | Puerto conflict con browser |
| uBlock Origin | Built-in | BrowserOS ya lo incluye con MV2 support |
| Privacidad | Ungoogled patches | BrowserOS usa patches de ungoogled-chromium |
| Fork en GitHub | Creado | Kairos42i/kairos-browser (rama dev) |

### Lo que BrowserOS YA incluye vs Chrome

| Caracteristica | BrowserOS | Chrome | Brave |
|---|---|---|---|
| uBlock Origin built-in | SI | NO | NO |
| Manifest V2 support | SI | NO | SI |
| AI Agent nativo | SI | NO | NO |
| MCP Server | SI | NO | NO |
| Sin telemetria Google | SI | NO | NO |
| Ad blocking 10x mas | SI | NO | SI |
| Vertical Tabs | SI | NO | NO |

---

## 2. Extensiones de Privacidad

### 2.1 uBlock Origin (YA incluido en BrowserOS)

BrowserOS ya incluye uBlock Origin con soporte Manifest V2 — esto es CLAVE porque Chrome lo esta deprecando.

**uBlock Origin** (gorhill/uBlock — 63K estrellas, GPL-3.0):
- Bloqueador de anuncios y trackers ultra eficiente
- Usa EasyList, EasyPrivacy, Peter Lowe Blocklist
- Bajo consumo de CPU/RAM
- Soporta MV2 completamente (BrowserOS NO depreca MV2)
- Alternativa MV3: uBlock Origin Lite (funcionalidad reducida)

### 2.2 Privacy Badger (EFF)

**Privacy Badger** (EFForg/privacybadger — 4K estrellas, GPLv3+):
- Aprende automaticamente a bloquear trackers ocultos
- Envia Global Privacy Control + Do Not Track
- Reemplaza trackers con click-to-activate
- Limpia links de tracking en Facebook/Google

### 2.3 Flags de privacidad (ungoogled-chromium)

```
--disable-webgl
--no-pings
--disable-top-sites
--webrtc-ip-handling-policy=disable_non_proxied_udp
--fingerprinting-canvas-image-data-noise
--fingerprinting-client-rects-noise
--fingerprinting-measuretext-noise
```

---

## 3. Mantenimiento del Fork

### 3.1 Estrategia: Sync automatico semanal

```
Upstream (browseros-ai/BrowserOS)
         |
         v  Weekly sync via GitHub Actions
  Fork (Kairos42i/kairos-browser)
         |
         +-- rama "dev" (nuestros cambios)
         +-- rama "master" (upstream limpio)
```

### 3.2 GitHub Actions para Auto-Sync

Crear `.github/workflows/sync-upstream.yml` con accion `kuma0128/sync-upstream-action`:
- Schedule: semanal (lunes 06:00 UTC)
- Sync upstream BrowserOS rama dev a nuestra rama dev
- Modo PR para revisar antes de mergear
- Crear issue automaticamente si hay conflictos

### 3.3 Sync manual

```bash
git remote add upstream https://github.com/browseros-ai/BrowserOS.git
git fetch upstream
git checkout dev
git merge upstream/dev
git push origin dev
```

### 3.4 Politica de Merge

| Situacion | Accion |
|-----------|--------|
| Sin conflictos | Merge automatico |
| Conflictos en agent-server (Bun) | Resolver manual, testear build |
| Conflictos en Chromium (C++) | Alto riesgo, revisar individualmente |
| Security fix upstream | Sync urgente inmediato |

---

## 4. Seguridad y CVEs

### 4.1 Realidad de Chromium CVEs

Chromium tiene **~20-30 CVEs por mes**. Ejemplos reales de 2026:

| Periodo | CVEs | Criticos | Exploit publico |
|---------|------|----------|-----------------|
| Feb 2026 | 12 | 4 | CVE-2026-2441 (wild) |
| Mar 2026 | 8 | 2 | Ninguno |
| Abr 2026 | 28 | 7 | Ninguno |

**Patrones comunes**:
- Heap buffer overflow (PDFium, Media, WebCodecs)
- Use after free (CSS, Ozone, FedCM, Dawn, PDF)
- Type confusion (V8 engine — RCE potencial)
- Integer overflow (V8, ANGLE, Skia, Fonts)

### 4.2 Mitigaciones por capa

```
CAPA 1: Chromium actualizado
  Sync semanal + security patches de Google

CAPA 2: Sandboxing
  --no-sandbox SOLO para headless/server
  Desktop: sandbox ACTIVADO por defecto
  Container isolation (Docker)

CAPA 3: Site Isolation
  Activado por defecto en Chromium 146+
  Cada sitio en proceso separado
  Mitiga: Spectre, side-channel

CAPA 4: Extensiones de seguridad
  uBlock Origin (bloquea malicious domains)
  Privacy Badger (bloquea trackers)

CAPA 5: Network Isolation
  VPN obligatorio para browsing
  DNS-over-HTTPS (DoH)
  WebRTC leak protection

CAPA 6: Monitoreo
  GitHub Dependabot
  GitHub Security Advisories
  Debian Security Tracker
```

### 4.3 CDP WebSocket: NO EXPONER A INTERNET

ADVERTENCIA: El puerto CDP (9000) es un WebSocket sin autenticacion. Permite control TOTAL del browser.

```
MAL:  browseros:9000 expuesto a Internet
BIEN: browseros:9000 solo en localhost
MEJOR: browseros:9000 detras de WireGuard VPN
```

---

## 5. VPN/VPS y Despliegue

### 5.1 VPS recomendados

| Proveedor | RAM | CPU | Precio |
|-----------|-----|-----|--------|
| Hetzner | 2GB | 1 vCPU | EUR4/mo |
| Netcup | 1GB | 1 vCPU | EUR2.50/mo |
| Contabo | 8GB | 4 vCPU | EUR7/mo |
| Oracle Cloud | 24GB | 4 ARM | GRATIS |

### 5.2 WireGuard VPN

```yaml
# docker-compose.yml (WireGuard)
services:
  wireguard:
    image: weejewel/wg-easy
    environment:
      - WG_HOST=vpn.tudominio.com
      - WG_DEFAULT_ADDRESS=10.8.0.x
      - WG_PORT=51820
    ports:
      - "51820:51820/udp"
      - "51821:51821/tcp"
    volumes:
      - ./data:/etc/wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
```

### 5.3 Hardening VPS

```bash
ufw default deny incoming && ufw default allow outgoing
ufw allow 51820/udp && ufw allow 22/tcp && ufw enable
# SSH: deshabilitar root + password auth
# fail2ban + unattended-upgrades
```

---

## 6. Roadmap de Integracion

### Fase 1: Fundacion (COMPLETADO)
- Fork de BrowserOS creado
- BrowserOS headless corriendo (Chromium 146, CDP activo)
- browseros-cli instalado
- Server MCP (Bun) con dependencias instaladas
- uBlock Origin incluido (built-in en BrowserOS)

### Fase 2: Privacidad (PROXIMO)
- Integrar Privacy Badger como extension built-in
- Configurar flags de privacidad de ungoogled-chromium
- Deshabilitar toda telemetria Google
- Verificar que no hay calls home

### Fase 3: Mantenimiento
- Configurar GitHub Actions para sync semanal
- Configurar Dependabot
- Script de build automatico

### Fase 4: Infraestructura
- Dockerizar BrowserOS completo
- Configurar VPS
- WireGuard VPN
- CI/CD para auto-deploy

### Fase 5: AI Integration
- Conectar BrowserOS MCP con LangGraph
- Integrar Stealth Browser MCP (133 tools anti-bot)
- Memoria Engram cross-session
- Agentes autonomos con SDD pipeline

---

## Apendice A: Comandos Utiles

```bash
# Sync fork
git fetch upstream && git checkout dev && git merge upstream/dev

# Browser headless
./browseros --headless --no-sandbox --remote-debugging-port=9000

# MCP server
cd packages/browseros-agent/apps/server
BROWSEROS_CDP_PORT=9000 BROWSEROS_SERVER_PORT=9100 bun run src/index.ts

# CLI
browseros-cli snap --server http://127.0.0.1:9100
```

## Apendice B: Referencias

| Recurso | URL |
|---------|-----|
| BrowserOS Docs | https://docs.browseros.com |
| uBlock Origin | github.com/gorhill/uBlock |
| Privacy Badger | github.com/EFForg/privacybadger |
| Ungoogled-Chromium | github.com/ungoogled-software/ungoogled-chromium |
| Chromium CVEs | Palo Alto monthly security updates |
| WireGuard WebAdmin | github.com/eduardogsilva/wireguard_webadmin |
| Fork Sync Action | github.com/kuma0128/sync-upstream-action |
