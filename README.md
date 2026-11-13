# bz-deploy
Deployment repo for Boozang. Replacing boozang-deploy.

## Jenkins

The release-validation job and pipeline definitions are mirrored in
[`jenkins/`](jenkins/), with `jenkins/sync.sh` to diff them against the live
server. See [jenkins/README.md](jenkins/README.md).
