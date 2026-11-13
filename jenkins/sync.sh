#!/bin/bash
#
# Keep the Jenkins job definitions under jenkins/jobs/ in sync with the live
# server at jenkins.boozang.com.
#
#   ./jenkins/sync.sh diff            show drift between git and the server
#   ./jenkins/sync.sh pull [job...]   overwrite the files from the server
#   ./jenkins/sync.sh push [job...]   overwrite the server from the files
#   ./jenkins/sync.sh parity          check prod and dev are still the same
#
# With no job arguments every job is processed. Job names may be given either
# as the Jenkins name ("The job - dev") or as the file slug ("the-job-dev").
#
# Credentials come from ~/.config/bz/jenkins.env, which must define
# JENKINS_USER and JENKINS_TOKEN and is expected to be mode 600. Override the
# server with JENKINS_URL.
#
# The project token that the freestyle jobs pass to the runner is a secret and
# is NOT stored here: the committed XML carries the placeholder
# @@BZ_PROJECT_TOKEN@@ instead. On push the real value is read back out of the
# job's own live config, so the token never has to be kept anywhere new. For a
# job that does not exist on the server yet, export BZ_PROJECT_TOKEN.
#
set -euo pipefail

JENKINS="${JENKINS_URL:-https://jenkins.boozang.com}"
HERE="$(cd "$(dirname "$0")" && pwd)"
JOBDIR="$HERE/jobs"
PLACEHOLDER='@@BZ_PROJECT_TOKEN@@'
ENVFILE="${JENKINS_ENV_FILE:-$HOME/.config/bz/jenkins.env}"

ALL_JOBS='The job
The job - dev
The pipeline
The pipeline - dev'

TMP=""
cleanup() { [ -n "$TMP" ] && rm -rf "$TMP"; }
trap cleanup EXIT

die() { echo "error: $*" >&2; exit 1; }

slug_for() {
  case "$1" in
    "The job")            echo the-job ;;
    "The job - dev")      echo the-job-dev ;;
    "The pipeline")       echo the-pipeline ;;
    "The pipeline - dev") echo the-pipeline-dev ;;
    *) return 1 ;;
  esac
}

# Accepts a Jenkins name or a slug, echoes the Jenkins name.
canonical() {
  local want="$1" job
  while IFS= read -r job; do
    [ "$want" = "$job" ] && { echo "$job"; return 0; }
    [ "$want" = "$(slug_for "$job")" ] && { echo "$job"; return 0; }
  done <<EOF
$ALL_JOBS
EOF
  return 1
}

urlenc() { printf '%s' "$1" | sed 's/ /%20/g'; }

load_creds() {
  [ -r "$ENVFILE" ] || die "cannot read $ENVFILE (JENKINS_USER / JENKINS_TOKEN)"
  set -a; . "$ENVFILE"; set +a
  [ -n "${JENKINS_USER:-}" ]  || die "JENKINS_USER not set in $ENVFILE"
  [ -n "${JENKINS_TOKEN:-}" ] || die "JENKINS_TOKEN not set in $ENVFILE"
}

# fetch_config <job name> <outfile>; returns 1 if the job does not exist.
fetch_config() {
  local enc; enc="$(urlenc "$1")"
  curl -sS -f -u "$JENKINS_USER:$JENKINS_TOKEN" \
    "$JENKINS/job/$enc/config.xml" -o "$2"
}

# Replace the project token with the placeholder. Everything else is verbatim.
redact() {
  sed -E "s/TOKEN=&quot;[^&]*&quot;/TOKEN=\&quot;$PLACEHOLDER\&quot;/" "$1"
}

cmd_diff() {
  local job slug live drift=0
  TMP="$(mktemp -d)"
  for job in "$@"; do
    slug="$(slug_for "$job")"
    live="$TMP/$slug.live"
    if ! fetch_config "$job" "$live.raw" 2>/dev/null; then
      echo "MISSING ON SERVER  $job"; drift=1; continue
    fi
    redact "$live.raw" > "$live"
    if [ ! -f "$JOBDIR/$slug.xml" ]; then
      echo "UNTRACKED IN GIT   $job"; drift=1; continue
    fi
    if diff -u "$JOBDIR/$slug.xml" "$live" > "$TMP/$slug.diff"; then
      echo "in sync            $job"
    else
      echo "DRIFT              $job"
      sed 's/^/    /' "$TMP/$slug.diff"
      drift=1
    fi
  done
  return $drift
}

cmd_pull() {
  local job slug
  TMP="$(mktemp -d)"
  mkdir -p "$JOBDIR"
  for job in "$@"; do
    slug="$(slug_for "$job")"
    fetch_config "$job" "$TMP/$slug.raw" || die "$job: not found on $JENKINS"
    redact "$TMP/$slug.raw" > "$JOBDIR/$slug.xml"
    echo "pulled  $job -> jenkins/jobs/$slug.xml"
  done
  echo
  echo "Review with 'git diff' before committing."
}

cmd_push() {
  local job slug src body token enc crumb_field crumb code
  TMP="$(mktemp -d)"; chmod 700 "$TMP"
  load_crumb() {
    local json; json="$TMP/crumb.json"
    curl -sS -f -u "$JENKINS_USER:$JENKINS_TOKEN" \
      "$JENKINS/crumbIssuer/api/json" -o "$json" \
      || die "could not get a CSRF crumb from $JENKINS"
    crumb_field="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["crumbRequestField"])' "$json")"
    crumb="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["crumb"])' "$json")"
  }
  load_crumb

  for job in "$@"; do
    slug="$(slug_for "$job")"
    src="$JOBDIR/$slug.xml"
    [ -f "$src" ] || die "$src does not exist"

    body="$TMP/$slug.body"; : > "$body"; chmod 600 "$body"
    if grep -q "$PLACEHOLDER" "$src"; then
      token=""
      if fetch_config "$job" "$TMP/$slug.live" 2>/dev/null; then
        token="$(sed -nE 's/.*TOKEN=&quot;([^&]*)&quot;.*/\1/p' "$TMP/$slug.live" | head -1)"
      fi
      [ -n "$token" ] || token="${BZ_PROJECT_TOKEN:-}"
      [ -n "$token" ] || die "$job: no project token available (job is new on the server; export BZ_PROJECT_TOKEN)"
      TOKEN_VALUE="$token" python3 - "$src" "$body" "$PLACEHOLDER" <<'PY'
import os,sys
src,dst,ph=sys.argv[1],sys.argv[2],sys.argv[3]
open(dst,"w",encoding="utf-8").write(
    open(src,encoding="utf-8").read().replace(ph,os.environ["TOKEN_VALUE"]))
PY
    else
      cp "$src" "$body"
    fi

    enc="$(urlenc "$job")"
    # The charset matters: without it Jenkins decodes the body as Latin-1 and
    # answers 500 with nothing but a logging id.
    code="$(curl -sS -o "$TMP/$slug.resp" -w '%{http_code}' \
      -X POST -u "$JENKINS_USER:$JENKINS_TOKEN" \
      -H "Content-Type: application/xml; charset=utf-8" \
      -H "$crumb_field: $crumb" \
      --data-binary "@$body" \
      "$JENKINS/job/$enc/config.xml")"
    rm -f "$body"
    case "$code" in
      200) echo "pushed  $job" ;;
      *)   echo "FAILED  $job (HTTP $code)" >&2
           head -20 "$TMP/$slug.resp" >&2
           die "push aborted" ;;
    esac
  done
}

# Prod and dev are meant to differ ONLY by the runner image and the job name.
# This masks those out and diffs the pair, so any further drift is visible.
cmd_parity() {
  local rc=0
  TMP="$(mktemp -d)"
  _mask() {
    sed -e 's/boozang-runner-dev/RUNNER_IMAGE/g' \
        -e 's/boozang-runner/RUNNER_IMAGE/g' \
        -e 's/The job - dev/JOB/g' -e 's/The job/JOB/g' \
        -e 's/The pipeline - dev/PIPELINE/g' -e 's/The pipeline/PIPELINE/g' \
        -e '/<description>/d' \
        "$1"
  }
  for pair in "the-job the-job-dev" "the-pipeline the-pipeline-dev"; do
    set -- $pair
    _mask "$JOBDIR/$1.xml" > "$TMP/$1"
    _mask "$JOBDIR/$2.xml" > "$TMP/$2"
    if diff -u "$TMP/$1" "$TMP/$2" > "$TMP/$1.diff"; then
      echo "at parity          $1 <-> $2"
    else
      echo "DIVERGED           $1 <-> $2"
      sed 's/^/    /' "$TMP/$1.diff"
      rc=1
    fi
  done
  return $rc
}

main() {
  local cmd="${1:-}"; shift || true
  case "$cmd" in
    diff|pull|push) ;;
    parity) cmd_parity; return $? ;;
    *) sed -n '3,23p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
  esac

  local jobs=() arg job
  if [ "$#" -eq 0 ]; then
    while IFS= read -r job; do jobs+=("$job"); done <<EOF
$ALL_JOBS
EOF
  else
    for arg in "$@"; do
      job="$(canonical "$arg")" || die "unknown job: $arg"
      jobs+=("$job")
    done
  fi

  load_creds
  "cmd_$cmd" "${jobs[@]}"
}

main "$@"
