#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# KAIROS Browser — Setup Script
# Uso: bash setup.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "============================================"
echo "  KAIROS Browser — Setup"
echo "============================================"
echo ""

# ── 1. Verificar requisitos ────────────────────────────────
echo "[1/5] Verificando requisitos..."

command -v docker >/dev/null 2>&1 || { echo "ERROR: Docker no instalado. https://docs.docker.com/engine/install/"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "ERROR: curl no instalado"; exit 1; }

echo "  ✅ Docker: $(docker --version)"
echo ""

# ── 2. Configurar seccomp profile ─────────────────────────
echo "[2/5] Configurando perfil seccomp para Chrome..."

SECCOMP_FILE="chrome.json"
if [ ! -f "$SECCOMP_FILE" ]; then
    echo "  Descargando perfil seccomp de Jessie Frazelle..."
    curl -fsSL "https://raw.githubusercontent.com/jfrazelle/dotfiles/master/etc/docker/seccomp/chrome.json" -o "$SECCOMP_FILE"
    echo "  ✅ Perfil seccomp descargado"
else
    echo "  ✅ Perfil seccomp ya existe"
fi
echo ""

# ── 3. Configurar .env ─────────────────────────────────────
echo "[3/5] Configurando variables de entorno..."

if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "  ⚠️  Archivo .env creado desde .env.example"
    echo "  ⚠️  EDITALO para configurar tus API keys:"
    echo "      nano .env"
else
    echo "  ✅ .env ya existe"
fi
echo ""

# ── 4. Verificar Docker image ──────────────────────────────
echo "[4/5] Verificando imagen de Chrome..."

if docker image inspect zenika/alpine-chrome:latest >/dev/null 2>&1; then
    echo "  ✅ Imagen chrome ya descargada"
else
    echo "  Descargando imagen zenika/alpine-chrome..."
    docker pull zenika/alpine-chrome:latest
    echo "  ✅ Imagen descargada"
fi
echo ""

# ── 5. Ready ────────────────────────────────────────────────
echo "[5/5] Setup completado!"
echo ""
echo "============================================"
echo "  PARA ARRANCAR:"
echo "============================================"
echo ""
echo "  1. EDITAR .env con tus API keys:"
echo "     nano .env"
echo ""
echo "  2. Iniciar Chrome + MCP Gateway:"
echo "     docker compose up -d chrome mcp-gateway"
echo ""
echo "  3. Verificar health:"
echo "     docker compose ps"
echo "     curl http://localhost:9222/json/version"
echo "     curl http://localhost:9100/health"
echo ""
echo "  4. (Opcional) Iniciar VPN:"
echo "     docker compose --profile vpn up -d"
echo ""
echo "  5. Ver logs:"
echo "     docker compose logs -f"
echo ""
echo "============================================"
