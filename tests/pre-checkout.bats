#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

run_hook() {
  run sh -c "source $PWD/hooks/pre-checkout && env | (grep BUILDKITE_CLEAN_CHECKOUT || true) | sed 's/^/ENV:/'"
}

@test "does nothing if there's no checkout" {
  export BUILDKITE_REPO=git@github.com:example/example.git
  export BUILDKITE_BUILD_CHECKOUT_PATH="$BATS_TEST_TMPDIR/missing"

  run_hook

  assert_success
  assert_output ''
}

@test "does nothing if there's no .git directory" {
  export BUILDKITE_REPO=git@github.com:example/example.git
  export BUILDKITE_BUILD_CHECKOUT_PATH="$BATS_TEST_TMPDIR"

  run_hook

  assert_success
  assert_output ''
}

@test "runs \`git fsck\` on the git checkout" {
  export BUILDKITE_REPO=git@github.com:example/example.git
  export BUILDKITE_BUILD_CHECKOUT_PATH="$BATS_TEST_TMPDIR"
  mkdir "$BUILDKITE_BUILD_CHECKOUT_PATH/.git"

  stub git 'fsck --no-dangling --connectivity-only : echo Verifying commits in commit graph: 100%'

  run_hook

  unstub git

  assert_success
  assert_output --partial "~~~ Verifying existing git checkout"
  assert_output --partial "Verifying commits in commit graph: 100%"
  refute_output --partial "git checkout is corrupt!"
  refute_output --partial "ENV:BUILDKITE_CLEAN_CHECKOUT"
}

@test "requests a clean checkout if \`git fsck\` fails" {
  export BUILDKITE_REPO=git@github.com:example/example.git
  export BUILDKITE_BUILD_CHECKOUT_PATH="$BATS_TEST_TMPDIR"
  mkdir "$BUILDKITE_BUILD_CHECKOUT_PATH/.git"

  stub git 'fsck --no-dangling --connectivity-only : echo error: refs/remotes/origin/example: invalid sha1 pointer … >&2 && exit 1'

  run_hook

  unstub git

  assert_success
  assert_output --partial "~~~ Verifying existing git checkout"
  assert_output --partial "invalid sha1 pointer"
  assert_output --partial "git checkout is corrupt!"
  assert_output --partial "ENV:BUILDKITE_CLEAN_CHECKOUT=1"
}
