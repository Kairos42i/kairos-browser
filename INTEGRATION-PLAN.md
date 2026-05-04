# KAIROS ECOSYSTEM — Plan de Integración Definitivo

## Basado en investigación real de código, docs y benchmarks

---

## 1. Stack Final (verificado en DeepWiki + docs oficiales + código)

```
┌──────────────────────────────────────────────────────────────────┐
│                      KAIROS ECOSYSTEM v2                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  🖥️  UBUNTU SERVER 24.04 LTS (hardened)                          │
│     ├── Proxmox VE (hypervisor) o Docker (app containers)         │
│     ├── UFW, AppArmor, fail2ban, unattended-upgrades              │
│     ├── SSH keys + CIS Level 1 hardening                          │
│     └── Kernel: sysctl hardening, LUKS encryption                 │
│                                                                   │
│  🟢 CHROME 149 CDP (:9222) — browser runtime                     │
│     ├── 150-280MB RAM por instancia                               │
│     ├── Pool de 3-5 browsers pre-warm                             │
│     └── seccomp profile (Jessie Frazelle)                         │
│                                                                   │
│  🟢 OPENCHROME MCP (46 tools) — browser automation core           │
│     ├── CDP directo (sin middleware)                              │
│     ├── 20 sesiones paralelas en 300MB RAM                        │
│     ├── 80% menos LLM calls vs Playwright                         │
│     ├── Cross-session memory                                      │
│     └── Token compression 15x                                     │
│                                                                   │
│  🟢 STEALTH BROWSER MCP (133 tools) — anti-bot + bypass           │
│     ├── Cloudflare Turnstile bypass                               │
│     ├── Fingerprint rotation                                      │
│     ├── reCAPTCHA AI solver                                       │
│     └── Vision-locate                                             │
│                                                                   │
│  🟢 DEEPWIKI MCP (3 tools) — code analysis                        │
│     ├── ask_question: cualquier pregunta sobre cualquier repo     │
│     ├── read_wiki_contents: documentación detallada               │
│     ├── read_wiki_structure: índice de temas                      │
│     └── Gratis, sin auth, Cognition Labs                          │
│                                                                   │
│  🟢 LANGGRAPH (18K★) — orquestador de agentes                     │
│     ├── StateGraph API + Pregel engine                            │
│     ├── 9% token overhead (mejor que CrewAI 18% y AutoGen 31%)    │
│     ├── Checkpointing (PostgreSQL/SQLite)                         │
│     └── Human-in-the-loop nativo                                  │
│                                                                   │
│  🟢 DIFY (55K★) o OPEN WEBUI (132K★) — frontend UI               │
│     ├── Dify: workflows visuales, MCP nativo, RAG, OAuth+PKCE     │
│     └── Open WebUI: más liviano, 1 container, Svelte 5+FastAPI    │
│                                                                   │
│  🟢 ENGRAM MEMORY — persistencia cross-session                    │
│     └── SQLite, 899+ observaciones                                │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

## 2. Virtualización: Proxmox vs Incus vs Docker

| Aspecto | Proxmox VE | Incus | Docker |
|---------|-----------|-------|--------|
| **Tipo** | Hypervisor completo | Container/VM manager | App containers |
| **Overhead** | Medio | Muy bajo (20-50MB) | Casi cero |
| **Web UI** | ✅ Integrada, completa | ❌ CLI-first (UI separada) | ❌ CLI (Portainer opcional) |
| **HA/Clustering** | ✅ Built-in | ✅ Built-in | ❌ Orquestador externo |
| **Backups** | ✅ vzdump integrado | ✅ Snapshots + export | ❌ Scripts manuales |
| **Licencia** | AGPL v3 (suscripción opcional) | Apache 2.0 | Apache 2.0 |
| **Ideal para** | Mixed VM/container farms | Containers-first, CLI pros | Microservicios específicos |

**Recomendación**: Proxmox VE como hypervisor BASE. Dentro de VMs, correr Docker para los servicios específicos (Chrome, MCPs, etc.). Esto da:
- Aislamiento completo entre servicios (cada VM = un kernel)
- Snapshots y backups integrados
- Web UI para gestión
- Live migration si se necesita

## 3. Ubuntu Server Hardening (verificado en CIS Benchmarks + docs oficiales)

```bash
# ===== NIVEL 1: ESENCIAL =====
adduser kairos && usermod -aG sudo kairos         # No root
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
ufw default deny incoming && ufw allow ssh && ufw enable
apt install unattended-upgrades && dpkg-reconfigure --priority=low unattended-upgrades

# ===== NIVEL 2: RECOMENDADO =====
apt install fail2ban apparmor-utils
sysctl -w net.ipv4.tcp_syncookies=1
sysctl -w net.ipv4.conf.all.accept_redirects=0
sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1
systemctl disable snapd avahi-daemon cups bluetooth

# ===== NIVEL 3: PRODUCCIÓN =====
# LUKS full disk encryption
# CIS Level 1 via Ubuntu Security Guide (USG) - ubuntu pro required
# AppArmor profiles personalizados para cada servicio
# Kernel hardening: /etc/sysctl.d/99-hardening.conf
```

## 4. MCP Gateway Unificado (endpoints verificados)

```yaml
# MCP endpoints funcionales ahora mismo:
deepwiki:      https://mcp.deepwiki.com/mcp          # ✅ VIVO, gratis, sin auth
stealth:       local (uvx mcp-stealth-chrome)         # ✅ VIVO, 133 tools
openchrome:    local (npx openchrome)                  # 📝 PENDIENTE INSTALAR
chrome-cdp:    ws://127.0.0.1:9222                     # ✅ VIVO, Chrome 149

# Routing rules (quién hace qué):
anti_bot_required   → stealth-browser (133 tools)
standard_automation → openchrome (46 tools, 80% menos calls)
code_analysis       → deepwiki (ask_question, read_wiki)
fast_interaction    → chrome-cdp direct (CDP)
```

## 5. Lo que CORRE AHORA vs lo que FALTA

```
🔥 CORRIENDO AHORA:
  ✅ Chrome 149 headless → CDP :9222 activo
  ✅ Stealth Browser MCP → 133 tools activo
  ✅ Playwright MCP → 19 tools activo
  ✅ DeepWiki MCP configurado → mcp.deepwiki.com/mcp
  ✅ browseros-cli → instalado v0.2.2
  ✅ Fork GitHub → Kairos42i/kairos-browser

📝 PRÓXIMO (esta sesión):
  ⬜ Instalar OpenChrome MCP (46 tools, CDP directo)
  ⬜ Conectar LangGraph como orquestador
  ⬜ Configurar Dify o Open WebUI como frontend
  ⬜ Docker compose final con todos los servicios
```

## 6. Decisiones clave (basadas en datos, no suposiciones)

| Decisión | Elección | Por qué |
|----------|----------|---------|
| Browser runtime | Chrome 149 stock CDP | Ya corre, actualizado automáticamente |
| Ad blocking | uBlock Origin unpacked (MV2) | BrowserOS patch permite uBlock completo |
| Automation core | OpenChrome MCP (46 tools) | CDP directo, 80% menos calls, cross-session memory |
| Anti-bot | Stealth Browser MCP (133 tools) | Cloudflare bypass, fingerprint, captcha |
| Code analysis | DeepWiki MCP (3 tools) | Gratis, sin auth, Cognition Labs |
| Orchestrator | LangGraph (18K★, MIT) | 9% overhead, checkpointing, human-in-loop |
| Frontend | Dify (55K★, Apache 2) | MCP nativo, OAuth+PKCE, SSRF protection |
| Hypervisor | Proxmox VE (AGPL) | Web UI, HA, backups, clustering |
| OS | Ubuntu 24.04 LTS | Soporte hasta 2029, ESM hasta 2034 |
| Container runtime | Docker (dentro de VMs) | Estándar, liviano, ecosistema enorme |
