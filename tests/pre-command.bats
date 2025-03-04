#!/usr/bin/env bats

setup() {
  load "${BATS_PLUGIN_PATH}/load.bash"

  # Mock plugin.bash functions
  function plugin_read_config() {
    case "$1" in
      "CONTEXT") echo "${BUILDKITE_PLUGIN_ANNOTATE_GIT_DIFF_CONTEXT:-git-diff}" ;;
      "FORMAT") echo "${BUILDKITE_PLUGIN_ANNOTATE_GIT_DIFF_FORMAT:-markdown}" ;;
      "COMPARE_BRANCH") echo "${BUILDKITE_PLUGIN_ANNOTATE_GIT_DIFF_COMPARE_BRANCH:-}" ;;
      "COMPARE_COMMITS") echo "${BUILDKITE_PLUGIN_ANNOTATE_GIT_DIFF_COMPARE_COMMITS:-1}" ;;
      "INCLUDE_MERGE_BASE") echo "${BUILDKITE_PLUGIN_ANNOTATE_GIT_DIFF_INCLUDE_MERGE_BASE:-true}" ;;
      "INCLUDE_SUBMODULES") echo "${BUILDKITE_PLUGIN_ANNOTATE_GIT_DIFF_INCLUDE_SUBMODULES:-false}" ;;
    esac
  }
  export -f plugin_read_config

  # Common test variables
  export BUILDKITE_COMMIT="current-sha"
  export BUILDKITE_BRANCH="feature-branch"
  export BUILDKITE_BUILD_NUMBER="123"

  # Create and clean up temp directory
  export BATS_TMPDIR="${BATS_TEST_TMPDIR}"
  mkdir -p "${BATS_TMPDIR}"
}

teardown() {
  rm -rf "${BATS_TMPDIR}"
}

@test "Compares against previous commit when no branch specified" {
  stub mktemp "echo '${BATS_TMPDIR}/diff.md'"

  stub git \
    "rev-parse current-sha~1 : echo previous-sha" \
    "diff --numstat previous-sha current-sha : echo '1  2  file.txt'" \
    "diff --color=always previous-sha current-sha : echo 'diff output'" \
    "diff --numstat previous-sha current-sha : echo '1  2  file.txt'"

  stub buildkite-agent "annotate '*' --context '*' --style 'info' --append : echo Annotation created"

  run "$PWD"/hooks/pre-command

  assert_success
  assert_output --partial "Annotation created"

  unstub git
  unstub buildkite-agent
  unstub mktemp
}

@test "Compares against specified branch using merge-base" {
  export BUILDKITE_PLUGIN_ANNOTATE_GIT_DIFF_COMPARE_BRANCH="develop"
  export BUILDKITE_PLUGIN_ANNOTATE_GIT_DIFF_INCLUDE_MERGE_BASE="true"

  stub mktemp "echo '${BATS_TMPDIR}/diff.md'"

  stub git \
    "fetch origin develop : echo 'Fetching develop'" \
    "rev-parse origin/develop : echo target-branch-sha" \
    "merge-base target-branch-sha current-sha : echo merge-base-sha" \
    "diff --numstat merge-base-sha current-sha : echo '1  2  file.txt'" \
    "diff --color=always merge-base-sha current-sha : echo 'diff output'" \
    "diff --numstat merge-base-sha current-sha : echo '1  2  file.txt'"

  stub buildkite-agent "annotate '*' --context '*' --style 'info' --append : echo Annotation created"

  run "$PWD"/hooks/pre-command

  assert_success
  assert_output --partial "Fetching develop"
  assert_output --partial "Annotation created"

  unstub git
  unstub buildkite-agent
  unstub mktemp
}

@test "Compares directly against branch head when merge-base disabled" {
  export BUILDKITE_PLUGIN_ANNOTATE_GIT_DIFF_COMPARE_BRANCH="develop"
  export BUILDKITE_PLUGIN_ANNOTATE_GIT_DIFF_INCLUDE_MERGE_BASE="false"

  stub mktemp "echo '${BATS_TMPDIR}/diff.md'"

  stub git \
    "fetch origin develop : echo 'Fetching develop'" \
    "rev-parse origin/develop : echo target-branch-sha" \
    "diff --numstat target-branch-sha current-sha : echo '1  2  file.txt'" \
    "diff --color=always target-branch-sha current-sha : echo 'diff output'" \
    "diff --numstat target-branch-sha current-sha : echo '1  2  file.txt'"

  stub buildkite-agent "annotate '*' --context '*' --style 'info' --append : echo Annotation created"

  run "$PWD"/hooks/pre-command

  assert_success
  assert_output --partial "Fetching develop"
  assert_output --partial "Annotation created"

  unstub git
  unstub buildkite-agent
  unstub mktemp
}

@test "Uses markdown format by default" {
  stub mktemp "echo '${BATS_TMPDIR}/diff.md'"

  stub git \
    "rev-parse current-sha~1 : echo previous-sha" \
    "diff --numstat previous-sha current-sha : echo '1  2  file.txt'" \
    "diff --color=always previous-sha current-sha : echo '+new line'" \
    "diff --numstat previous-sha current-sha : echo '1  2  file.txt'"

  stub buildkite-agent "annotate '*' --context '*' --style 'info' --append : echo Annotation created"

  run "$PWD"/hooks/pre-command

  assert_success
  assert_output --partial "Annotation created"

  unstub git
  unstub buildkite-agent
  unstub mktemp
}

@test "Respects raw diff format when specified" {
  export BUILDKITE_PLUGIN_ANNOTATE_GIT_DIFF_FORMAT="diff"

  stub mktemp "echo '${BATS_TMPDIR}/diff.md'"

  stub git \
    "rev-parse current-sha~1 : echo previous-sha" \
    "diff --numstat previous-sha current-sha : echo '1  2  file.txt'" \
    "diff --color=always previous-sha current-sha : echo 'raw diff output'"

  stub buildkite-agent "annotate '*' --context '*' --style 'info' --append : echo Annotation created"

  run "$PWD"/hooks/pre-command

  assert_success
  assert_output --partial "Annotation created"

  unstub git
  unstub buildkite-agent
  unstub mktemp
}

@test "Handles empty diff output" {
  stub git \
    "rev-parse current-sha~1 : echo previous-sha" \
    "diff --numstat previous-sha current-sha : echo ''"

  stub buildkite-agent \
    "annotate * --context * --style 'info' --append : echo 'No changes found'"

  run "$PWD"/hooks/pre-command

  assert_success
  assert_output --partial "No changes found"

  unstub git
  unstub buildkite-agent
}

@test "Detects submodule changes when enabled" {
  export BUILDKITE_PLUGIN_ANNOTATE_GIT_DIFF_INCLUDE_SUBMODULES="true"

  stub mktemp "echo '${BATS_TMPDIR}/diff.md'"

  stub git \
    "rev-parse current-sha~1 : echo previous-sha" \
    "diff --numstat --submodule=diff previous-sha current-sha : echo '1  2  src/submodules/mymodule'" \
    "diff --color=always --submodule=diff previous-sha current-sha : echo 'Submodule src/submodules/mymodule updated 1234abc..5678def'" \
    "diff --numstat --submodule=diff previous-sha current-sha : echo '1  2  src/submodules/mymodule'"

  stub buildkite-agent "annotate '*' --context '*' --style 'info' --append : echo Annotation created"

  run "$PWD"/hooks/pre-command

  assert_success
  assert_output --partial "Annotation created"

  unstub git
  unstub buildkite-agent
  unstub mktemp
}
