#!/usr/bin/env bash
# acpp-toolchain_linux-64/build.sh
# Processes activation script templates and installs all files.
# No compilation happens here.
set -euo pipefail

# ── Flags baked in at package-build time via @VARIABLE@ substitution ──────
# These match conda-forge's linux-64 hardened flag defaults.
CHOST="x86_64-conda-linux-gnu"

FINAL_CFLAGS="-march=nocona -mtune=haswell -ftree-vectorize -fPIC \
-fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe"

FINAL_CXXFLAGS="-march=nocona -mtune=haswell -ftree-vectorize -fPIC \
-fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe \
-fvisibility-inlines-hidden -fmessage-length=0"

FINAL_CPPFLAGS="-DNDEBUG -D_FORTIFY_SOURCE=2 -O2"

FINAL_LDFLAGS="-Wl,-O2 -Wl,--sort-common -Wl,--as-needed \
-Wl,-z,relro -Wl,-z,now -Wl,--disable-new-dtags -Wl,--gc-sections \
-Wl,--allow-shlib-undefined"

FINAL_DEBUG_CFLAGS="-march=nocona -mtune=haswell -ftree-vectorize -fPIC \
-fstack-protector-all -fno-plt -Og -g -Wall -Wextra \
-fvar-tracking-assignments -ffunction-sections -pipe"

FINAL_DEBUG_CXXFLAGS="-march=nocona -mtune=haswell -ftree-vectorize -fPIC \
-fstack-protector-all -fno-plt -Og -g -Wall -Wextra \
-fvar-tracking-assignments -ffunction-sections -pipe \
-fvisibility-inlines-hidden -fmessage-length=0"

# ── Create target directories ──────────────────────────────────────────────
mkdir -p "${PREFIX}/etc/conda/activate.d"
mkdir -p "${PREFIX}/etc/conda/deactivate.d"
mkdir -p "${PREFIX}/share/acpp/toolchain"

# ── Copy script templates ──────────────────────────────────────────────────
cp "${RECIPE_DIR}/activate-acpp-linux-64.sh" \
   "${PREFIX}/etc/conda/activate.d/activate-acpp-linux-64.sh"
cp "${RECIPE_DIR}/deactivate-acpp-linux-64.sh" \
   "${PREFIX}/etc/conda/deactivate.d/deactivate-acpp-linux-64.sh"

# ── Substitute @VARIABLE@ placeholders ────────────────────────────────────
# Dynamic paths ($CONDA_PREFIX, $PREFIX) are resolved at activation time.
# Static flags are baked in now.
for script in \
    "${PREFIX}/etc/conda/activate.d/activate-acpp-linux-64.sh" \
    "${PREFIX}/etc/conda/deactivate.d/deactivate-acpp-linux-64.sh"; do

    sed -i "s|@CHOST@|${CHOST}|g"                          "$script"
    sed -i "s|@CFLAGS@|${FINAL_CFLAGS}|g"                  "$script"
    sed -i "s|@CXXFLAGS@|${FINAL_CXXFLAGS}|g"              "$script"
    sed -i "s|@CPPFLAGS@|${FINAL_CPPFLAGS}|g"              "$script"
    sed -i "s|@LDFLAGS@|${FINAL_LDFLAGS}|g"                "$script"
    sed -i "s|@DEBUG_CFLAGS@|${FINAL_DEBUG_CFLAGS}|g"      "$script"
    sed -i "s|@DEBUG_CXXFLAGS@|${FINAL_DEBUG_CXXFLAGS}|g"  "$script"
done

# ── Install CMake toolchain file ───────────────────────────────────────────
cp "${RECIPE_DIR}/acpp-linux-64.cmake" \
   "${PREFIX}/share/acpp/toolchain/acpp-linux-64.cmake"

echo "acpp-toolchain_linux-64: installation complete."
