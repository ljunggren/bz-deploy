#!/bin/bash
#
# Domain reputation check for Boozang infrastructure
# Checks: email (SPF/DMARC/DKIM), DNS, IP blacklists, HTTP security headers, SSL/TLS, web reputation
#

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'
BOLD='\033[1m'

PASS=0
WARN=0
FAIL=0

pass() { echo -e "  ${GREEN}✓${NC} $1"; PASS=$((PASS+1)); }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; WARN=$((WARN+1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; FAIL=$((FAIL+1)); }

DOMAINS=("boozang.com" "ai.boozang.com" "eu.boozang.com")
WEB_DOMAINS=("ai.boozang.com" "eu.boozang.com")

# --- Email Reputation ---

echo -e "\n${BOLD}=== Email Reputation ===${NC}"

# SPF
spf=$(dig +short TXT boozang.com 2>/dev/null | tr -d '"' | grep "v=spf1" || echo "")
if [ -z "$spf" ]; then
  fail "SPF — no record found"
elif echo "$spf" | grep -q "\-all"; then
  pass "SPF — $spf"
elif echo "$spf" | grep -q "~all\|?all"; then
  warn "SPF — soft/neutral policy: $spf"
else
  warn "SPF — no -all directive: $spf"
fi

# DMARC
dmarc=$(dig +short TXT _dmarc.boozang.com 2>/dev/null | tr -d '"' || echo "")
if [ -z "$dmarc" ]; then
  fail "DMARC — no record found"
elif echo "$dmarc" | grep -q "p=reject\|p=quarantine"; then
  pass "DMARC — $dmarc"
elif echo "$dmarc" | grep -q "p=none"; then
  warn "DMARC — monitoring only (p=none)"
else
  warn "DMARC — unexpected policy: $dmarc"
fi

# DKIM
echo -e "  ${BOLD}DKIM selectors:${NC}"
DKIM_SELECTORS=("google" "default" "selector1" "selector2" "mailjet" "mj")
dkim_found=0
for sel in "${DKIM_SELECTORS[@]}"; do
  dkim=$(dig +short TXT "${sel}._domainkey.boozang.com" 2>/dev/null | tr -d '"' || echo "")
  if [ -n "$dkim" ]; then
    pass "DKIM ($sel) — found"
    dkim_found=$((dkim_found+1))
  fi
done
if [ "$dkim_found" -eq 0 ]; then
  warn "DKIM — no selectors found (checked: ${DKIM_SELECTORS[*]})"
fi

# --- DNS Health ---

echo -e "\n${BOLD}=== DNS Health ===${NC}"

for domain in "${DOMAINS[@]}"; do
  a_records=$(dig +short A "$domain" 2>/dev/null || echo "")
  if [ -n "$a_records" ]; then
    ips=$(echo "$a_records" | tr '\n' ', ' | sed 's/,$//')
    pass "$domain A — $ips"
  else
    fail "$domain A — no records"
  fi
done

# stg1bh
a_stg=$(dig +short A stg1bh.boozang.com 2>/dev/null || echo "")
if [ -n "$a_stg" ]; then
  pass "stg1bh.boozang.com A — $a_stg"
else
  fail "stg1bh.boozang.com A — no records"
fi

# MX
mx=$(dig +short MX boozang.com 2>/dev/null || echo "")
if [ -n "$mx" ]; then
  mx_flat=$(echo "$mx" | tr '\n' ', ' | sed 's/,$//')
  pass "boozang.com MX — $mx_flat"
else
  fail "boozang.com MX — no records"
fi

# NS
ns=$(dig +short NS boozang.com 2>/dev/null || echo "")
if [ -n "$ns" ]; then
  ns_flat=$(echo "$ns" | tr '\n' ', ' | sed 's/,$//')
  pass "boozang.com NS — $ns_flat"
else
  fail "boozang.com NS — no records"
fi

# SOA
soa=$(dig +short SOA boozang.com 2>/dev/null || echo "")
if [ -n "$soa" ]; then
  pass "boozang.com SOA — present"
else
  fail "boozang.com SOA — no record"
fi

# DNSSEC
ds=$(dig +short DS boozang.com 2>/dev/null || echo "")
if [ -n "$ds" ]; then
  pass "boozang.com DNSSEC — DS record present"
else
  warn "boozang.com DNSSEC — no DS record (not signed)"
fi

# --- IP Blacklist Checks ---

echo -e "\n${BOLD}=== IP Blacklist Checks ===${NC}"

CHECKED_IPS=""

BLACKLISTS=(
  "zen.spamhaus.org"
  "bl.spamcop.net"
  "b.barracudacentral.org"
  "dnsbl.sorbs.net"
  "dnsbl-1.uceprotect.net"
  "spam.dnsbl.sorbs.net"
)

for domain in "${DOMAINS[@]}"; do
  ips=$(dig +short A "$domain" 2>/dev/null || echo "")
  for ip in $ips; do
    # Skip if already checked
    if echo "$CHECKED_IPS" | grep -q "^${ip}$"; then
      continue
    fi
    CHECKED_IPS="${CHECKED_IPS}
${ip}"

    # Reverse the IP
    reversed=$(echo "$ip" | awk -F. '{print $4"."$3"."$2"."$1}')

    listed=0
    for bl in "${BLACKLISTS[@]}"; do
      result=$(dig +short A "${reversed}.${bl}" 2>/dev/null || echo "")
      if [ -n "$result" ]; then
        fail "$ip listed on $bl (${result})"
        listed=$((listed+1))
      fi
    done
    if [ "$listed" -eq 0 ]; then
      pass "$ip ($domain) — clean on all ${#BLACKLISTS[@]} blacklists"
    fi
  done
done

# --- HTTP Security Headers ---

echo -e "\n${BOLD}=== HTTP Security Headers ===${NC}"

CRITICAL_HEADERS=("Strict-Transport-Security" "X-Content-Type-Options" "X-Frame-Options")
OPTIONAL_HEADERS=("Content-Security-Policy" "X-XSS-Protection" "Referrer-Policy")
HSTS_MIN_AGE=31536000

for domain in "${WEB_DOMAINS[@]}"; do
  echo -e "  ${BOLD}${domain}:${NC}"
  headers=$(curl -sI --max-time 10 "https://$domain" 2>/dev/null || echo "")

  if [ -z "$headers" ]; then
    fail "$domain — could not fetch headers"
    continue
  fi

  for hdr in "${CRITICAL_HEADERS[@]}"; do
    value=$(echo "$headers" | grep -i "^${hdr}:" | sed "s/^[^:]*: //" | tr -d '\r' || echo "")
    if [ -z "$value" ]; then
      fail "$domain $hdr — missing"
    else
      if [ "$hdr" = "Strict-Transport-Security" ]; then
        max_age=$(echo "$value" | sed -n 's/.*max-age=\([0-9]*\).*/\1/p')
        max_age=${max_age:-0}
        if [ "$max_age" -ge "$HSTS_MIN_AGE" ]; then
          pass "$domain $hdr — max-age=$max_age"
        else
          warn "$domain $hdr — max-age=$max_age (< 1 year)"
        fi
      else
        pass "$domain $hdr — $value"
      fi
    fi
  done

  for hdr in "${OPTIONAL_HEADERS[@]}"; do
    value=$(echo "$headers" | grep -i "^${hdr}:" | sed "s/^[^:]*: //" | tr -d '\r' || echo "")
    if [ -z "$value" ]; then
      warn "$domain $hdr — missing"
    else
      pass "$domain $hdr — $value"
    fi
  done
done

# --- SSL/TLS Health ---

echo -e "\n${BOLD}=== SSL/TLS Health ===${NC}"

for domain in "${WEB_DOMAINS[@]}"; do
  echo -e "  ${BOLD}${domain}:${NC}"

  # Certificate expiry
  cert_info=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null || echo "")
  if [ -n "$cert_info" ]; then
    expiry_str=$(echo "$cert_info" | openssl x509 -noout -enddate 2>/dev/null | sed 's/notAfter=//' || echo "")
    if [ -n "$expiry_str" ]; then
      # macOS-compatible date parsing
      expiry_epoch=$(date -j -f "%b %d %T %Y %Z" "$expiry_str" +%s 2>/dev/null || date -j -f "%b  %d %T %Y %Z" "$expiry_str" +%s 2>/dev/null || echo "0")
      now_epoch=$(date +%s)
      days_left=$(( (expiry_epoch - now_epoch) / 86400 ))

      if [ "$expiry_epoch" -eq 0 ]; then
        warn "$domain cert expiry — could not parse date: $expiry_str"
      elif [ "$days_left" -lt 0 ]; then
        fail "$domain cert — EXPIRED ($expiry_str)"
      elif [ "$days_left" -lt 14 ]; then
        fail "$domain cert — expires in ${days_left}d ($expiry_str)"
      elif [ "$days_left" -lt 30 ]; then
        warn "$domain cert — expires in ${days_left}d ($expiry_str)"
      else
        pass "$domain cert — expires in ${days_left}d ($expiry_str)"
      fi
    else
      fail "$domain cert — could not read expiry"
    fi

    # Chain verification
    verify=$(echo "$cert_info" | grep "Verify return code:" | sed 's/.*Verify return code: //' | tr -d '\r' || echo "unknown")
    if echo "$verify" | grep -q "^0 "; then
      pass "$domain chain — verified ($verify)"
    else
      fail "$domain chain — $verify"
    fi
  else
    fail "$domain — TLS connection failed"
    continue
  fi

  # TLS 1.0 should be rejected
  tls10_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 --tlsv1.0 --tls-max 1.0 "https://$domain" 2>/dev/null) || true
  if [ "$tls10_code" = "000" ] || [ -z "$tls10_code" ]; then
    pass "$domain TLS 1.0 — rejected"
  else
    fail "$domain TLS 1.0 — accepted (HTTP $tls10_code)"
  fi

  # TLS 1.1 should be rejected
  tls11_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 --tlsv1.1 --tls-max 1.1 "https://$domain" 2>/dev/null) || true
  if [ "$tls11_code" = "000" ] || [ -z "$tls11_code" ]; then
    pass "$domain TLS 1.1 — rejected"
  else
    fail "$domain TLS 1.1 — accepted (HTTP $tls11_code)"
  fi

  # TLS 1.2 should be accepted
  tls12_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 --tlsv1.2 --tls-max 1.2 "https://$domain" 2>/dev/null) || true
  if [ "$tls12_code" != "000" ] && [ -n "$tls12_code" ]; then
    pass "$domain TLS 1.2 — accepted (HTTP $tls12_code)"
  else
    fail "$domain TLS 1.2 — rejected"
  fi
done

# --- Web Reputation ---

echo -e "\n${BOLD}=== Web Reputation ===${NC}"

# Spamhaus DBL
dbl=$(dig +short A "boozang.com.dbl.spamhaus.org" 2>/dev/null || echo "")
if [ -z "$dbl" ]; then
  pass "Spamhaus DBL — boozang.com not listed"
else
  fail "Spamhaus DBL — boozang.com listed ($dbl)"
fi

# SURBL
surbl=$(dig +short A "boozang.com.multi.surbl.org" 2>/dev/null || echo "")
if [ -z "$surbl" ]; then
  pass "SURBL — boozang.com not listed"
else
  fail "SURBL — boozang.com listed ($surbl)"
fi

# Manual check URLs
echo -e "  ${BOLD}Manual checks:${NC}"
echo -e "  → Google Safe Browsing: https://transparencyreport.google.com/safe-browsing/search?url=boozang.com"
echo -e "  → VirusTotal:           https://www.virustotal.com/gui/domain/boozang.com"

# --- Summary ---

echo -e "\n${BOLD}=== Summary ===${NC}"
echo -e "  ${GREEN}Passed: $PASS${NC}  ${YELLOW}Warnings: $WARN${NC}  ${RED}Failed: $FAIL${NC}"

if [ "$FAIL" -gt 0 ]; then
  exit 1
elif [ "$WARN" -gt 0 ]; then
  exit 0
else
  exit 0
fi
