#!/bin/sh
PERL5LIB="$(cd "${SOPC_KIT_NIOS2}" 2>/dev/null && pwd 2>/dev/null)/bin" perl "${SH_PL:-$0.pl}" $@

