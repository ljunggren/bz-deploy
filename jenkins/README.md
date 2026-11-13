# Jenkins job definitions

The release-validation jobs on `jenkins.boozang.com` used to exist only inside
Jenkins. Nothing diffed them, so they drifted apart for months without anyone
being able to see it — including a parameter on one job that silently did
nothing, and a whole test stage that prod ran and staging did not. These files
are the record, and `sync.sh` is how you keep them honest.

Git is **not** the live configuration. Jenkins is. These files are a mirror you
have to keep up to date on purpose.

## The jobs

| file | Jenkins job | what it is |
|---|---|---|
| `jobs/the-pipeline.xml` | `The pipeline` | prod orchestrator |
| `jobs/the-pipeline-dev.xml` | `The pipeline - dev` | staging orchestrator |
| `jobs/the-job.xml` | `The job` | prod worker, one stage per build |
| `jobs/the-job-dev.xml` | `The job - dev` | staging worker, one stage per build |

A pipeline does not run tests itself. Each of its stages triggers a separate
downstream build of the matching `The job`, with `TEST` and `FILTER` hardcoded
in the pipeline's groovy. **The pipeline's own `TEST` parameter is ignored by
the stages** — it is there for manual one-off runs only.

Both the prod and the dev job run against `BASE=https://staging-bh.boozang.com`,
project `6515cd7f81bcda470a5ef8db`. The only difference between them is the
runner image: `styrman/boozang-runner` versus `styrman/boozang-runner-dev`.
So "the prod job" validates the prod *container* against the staging app; it
does not touch `ai.boozang.com` or `eu.boozang.com`.

## The stage list

Both pipelines run the same seven stages, in this order:

| # | stage | TEST | FILTER | workers |
|---|---|---|---|---|
| 1 | Setup users | `m115/t2` | `${params.FILTER}` | 4 |
| 2 | Run Smoke tests | `m82/t3` | `${params.FILTER}` | 4 |
| 3 | Run phase 1 tests | `m41/t1` | `modeltests` | 4 |
| 4 | Run form fill tests | `m41/t1` | `formtests` | 4 |
| 5 | Not model-based | `m82/t8` | | 1 |
| 6 | Phase 3 | `m82/t25` | | 4 |
| 7 | Claude | `m82/t28` | | 1 |

Stage 1 is the only one without `catchError`: it provisions the accounts every
later stage signs in with, so if it fails the rest is meaningless. This is also
why **running `The job` on its own always fails at `[m42.t2] Sign in`** — a
standalone build skips stage 1, so there are no users. A single-test build is
not a valid way to retest something.

## Using it

```bash
./jenkins/sync.sh diff      # what differs between git and the server
./jenkins/sync.sh parity    # are prod and dev still the same?
./jenkins/sync.sh pull      # server -> files (then review and commit)
./jenkins/sync.sh push      # files -> server
```

`diff` and `parity` exit non-zero when they find something, so they work as a
check in a hook or a pipeline.

Changed something in the Jenkins UI? `pull`, then commit, so the next person
can see it. Changing it here instead? `push`, then run the staging pipeline
before you trust it.

Credentials come from `~/.config/bz/jenkins.env` (`JENKINS_USER`,
`JENKINS_TOKEN`), which stays outside every repo.

## Parity

Prod and dev are meant to be the same suite on two images. `sync.sh parity`
masks out the image name, the job name and the description, and diffs the pair:
with those masked the two job configs are byte-identical and the two pipelines
differ nowhere. Run it after any change to either side.

## Things that will cost you an afternoon

- **`Content-Type: application/xml` is not enough when POSTing a config.** Without
  `; charset=utf-8` Jenkins decodes the body as Latin-1, mangles any non-ASCII
  character in the build script, and answers `500` with nothing but a logging
  id — no stack trace, no hint that encoding is involved. `sync.sh` always sends
  the charset.
- **`exemode` has to be in the query string, before the `#`.** The IDE parses
  `location.search` only (`cooperation.js`, `_init()`), so an `&exemode=` placed
  after the fragment is invisible and silently falls back to `dynamic`.
- **The job never pulls its image.** Docker will not re-fetch a tag it already
  has, so after releasing a container you must pull it on the build server
  yourself or the run quietly tests a stale image.
- **`EXEMODE=dynamic` randomises the scenario sample**, so two runs of the same
  stage do not cover the same tests. Compare totals and failure signatures
  across runs, never test-for-test.
- **`consoleText` is worker 1 only.** The other workers write
  `out_<build>_<n>.log` into the job workspace, readable at
  `/job/<job>/ws/out_<build>_<n>.log`. The job prunes old ones, so these are
  available for recent builds only — fetch them while the run is fresh.

## The project token

The freestyle jobs pass a project token to the runner. It is a secret, so the
committed XML carries the placeholder `@@BZ_PROJECT_TOKEN@@` instead.

On `push`, `sync.sh` reads the real value back out of the job's own live config
and substitutes it, so the token never has to be stored anywhere new. For a job
that does not exist on the server yet, export `BZ_PROJECT_TOKEN` for the one
call that creates it.

Do not commit a config with the token filled in. `pull` always re-redacts, so
the normal workflow cannot do it by accident.
