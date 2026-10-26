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
      "COMPARE_PREVIOUS_BUILD") echo "${BUILDKITE_PLUGIN_ANNOTATE_GIT_DIFF_COMPARE_PREVIOUS_BUILD:-false}" ;;
      "MAX_BODY_BYTES") echo "${BUILDKITE_PLUGIN_ANNOTATE_GIT_DIFF_MAX_BODY_BYTES:-921600}" ;;
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
  stub mktemp \
    "echo '${BATS_TMPDIR}/diff.md'" \
    "echo '${BATS_TMPDIR}/section.md'"
  touch "${BATS_TMPDIR}/diff.md"  # Create the file so it exists

  stub git \
    "rev-parse current-sha~1 : echo previous-sha" \
    "diff --numstat previous-sha current-sha : echo '1  2  file.txt'" \
    "diff --name-only previous-sha current-sha : echo 'file.txt'" \
    "diff --numstat previous-sha current-sha : echo '1  2  file.txt'" \
    "diff previous-sha current-sha -- file.txt : echo 'diff output for file.txt'"

  stub buildkite-agent "annotate --context '*' --style 'info' --append : echo Annotation created"

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

  stub mktemp \
    "echo '${BATS_TMPDIR}/diff.md'" \
    "echo '${BATS_TMPDIR}/section.md'"
  touch "${BATS_TMPDIR}/diff.md"  # Create the file so it exists

  stub git \
    "fetch origin develop : echo 'Fetching develop'" \
    "rev-parse origin/develop : echo target-branch-sha" \
    "merge-base target-branch-sha current-sha : echo merge-base-sha" \
    "diff --numstat merge-base-sha current-sha : echo '1  2  file.txt'" \
    "diff --name-only merge-base-sha current-sha : echo 'file.txt'" \
    "diff --numstat merge-base-sha current-sha : echo '1  2  file.txt'" \
    "diff merge-base-sha current-sha -- file.txt : echo 'diff output for file.txt'"

  stub buildkite-agent "annotate --context '*' --style 'info' --append : echo Annotation created"

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

  stub mktemp \
    "echo '${BATS_TMPDIR}/diff.md'" \
    "echo '${BATS_TMPDIR}/section.md'"
  touch "${BATS_TMPDIR}/diff.md"  # Create the file so it exists

  stub git \
    "fetch origin develop : echo 'Fetching develop'" \
    "rev-parse origin/develop : echo target-branch-sha" \
    "diff --numstat target-branch-sha current-sha : echo '1  2  file.txt'" \
    "diff --name-only target-branch-sha current-sha : echo 'file.txt'" \
    "diff --numstat target-branch-sha current-sha : echo '1  2  file.txt'" \
    "diff target-branch-sha current-sha -- file.txt : echo 'diff output for file.txt'"

  stub buildkite-agent "annotate --context '*' --style 'info' --append : echo Annotation created"

  run "$PWD"/hooks/pre-command

  assert_success
  assert_output --partial "Fetching develop"
  assert_output --partial "Annotation created"

  unstub git
  unstub buildkite-agent
  unstub mktemp
}

@test "Uses markdown format by default" {
  stub mktemp \
    "echo '${BATS_TMPDIR}/diff.md'" \
    "echo '${BATS_TMPDIR}/section.md'"
  touch "${BATS_TMPDIR}/diff.md"  # Create the file so it exists

  stub git \
    "rev-parse current-sha~1 : echo previous-sha" \
    "diff --numstat previous-sha current-sha : echo '1  2  file.txt'" \
    "diff --name-only previous-sha current-sha : echo 'file.txt'" \
    "diff --numstat previous-sha current-sha : echo '1  2  file.txt'" \
    "diff previous-sha current-sha -- file.txt : echo '+new line'"

  stub buildkite-agent "annotate --context '*' --style 'info' --append : echo Annotation created"

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
  touch "${BATS_TMPDIR}/diff.md"  # Create the file so it exists

  stub git \
    "rev-parse current-sha~1 : echo previous-sha" \
    "diff --numstat previous-sha current-sha : echo '1  2  file.txt'" \
    "diff --color=always previous-sha current-sha : echo 'raw diff output'"

  stub buildkite-agent "annotate --context '*' --style 'info' --append : echo Annotation created"

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

  stub mktemp \
    "echo '${BATS_TMPDIR}/diff.md'" \
    "echo '${BATS_TMPDIR}/section.md'"
  touch "${BATS_TMPDIR}/diff.md"  # Create the file so it exists

  stub git \
    "rev-parse current-sha~1 : echo previous-sha" \
    "diff --numstat --submodule=diff previous-sha current-sha : echo '1  2  src/submodules/mymodule'" \
    "diff --name-only --submodule=diff previous-sha current-sha : echo 'src/submodules/mymodule'" \
    "diff --numstat --submodule=diff previous-sha current-sha : echo '1  2  src/submodules/mymodule'" \
    "diff --submodule=diff previous-sha current-sha -- src/submodules/mymodule : echo 'Submodule src/submodules/mymodule updated 1234abc..5678def'"

  stub buildkite-agent "annotate --context '*' --style 'info' --append : echo Annotation created"

  run "$PWD"/hooks/pre-command

  assert_success
  assert_output --partial "Annotation created"

  unstub git
  unstub buildkite-agent
  unstub mktemp
}

# Tests for the compare_previous_build functionality

@test "Fails when compare_previous_build is true but API token is missing" {
  export BUILDKITE_PLUGIN_ANNOTATE_GIT_DIFF_COMPARE_PREVIOUS_BUILD="true"
  export BUILDKITE_API_TOKEN=""

  run "$PWD"/hooks/pre-command

  assert_failure
  assert_output --partial "Error: BUILDKITE_API_TOKEN is required when compare_previous_build is true"
}

@test "Truncates markdown diff and lists omitted files when over the body size cap" {
  # Chosen so the first file's section fits but the second (large) section won't.
  export BUILDKITE_PLUGIN_ANNOTATE_GIT_DIFF_MAX_BODY_BYTES="500"

  stub mktemp \
    "echo '${BATS_TMPDIR}/diff.md'" \
    "echo '${BATS_TMPDIR}/section.md'"
  touch "${BATS_TMPDIR}/diff.md"

  # The first file's section produces a payload (~160 bytes with details markup)
  # that fits under the 200-byte cap once the header/summary are written.
  # The second file would push us past the cap and must land in the omitted list.
  stub git \
    "rev-parse current-sha~1 : echo previous-sha" \
    "diff --numstat previous-sha current-sha : printf '1\t2\tsmall.txt\n1000\t500\tbig.txt\n'" \
    "diff --name-only previous-sha current-sha : printf 'small.txt\nbig.txt\n'" \
    "diff --numstat previous-sha current-sha : printf '1\t2\tsmall.txt\n1000\t500\tbig.txt\n'" \
    "diff previous-sha current-sha -- small.txt : echo 'tiny'" \
    "diff previous-sha current-sha -- big.txt : head -c 500 /dev/zero | tr '\\\\0' 'X'"

  stub buildkite-agent "annotate --context '*' --style 'info' --append : cat > '${BATS_TMPDIR}/body.out'; echo Annotation created"

  run "$PWD"/hooks/pre-command

  assert_success
  assert_output --partial "Annotation created"

  # The posted body should contain the truncation notice and name the omitted file.
  run cat "${BATS_TMPDIR}/body.out"
  assert_output --partial "Diff truncated"
  assert_output --partial "big.txt"

  unstub git
  unstub buildkite-agent
  unstub mktemp
}

@test "Handles API request failure" {
  function curl() { return 1; }
  export -f curl

  export BUILDKITE_PLUGIN_ANNOTATE_GIT_DIFF_COMPARE_PREVIOUS_BUILD="true"
  export BUILDKITE_API_TOKEN="fake-token"
  export BUILDKITE_ORGANIZATION_SLUG="test-org"
  export BUILDKITE_PIPELINE_SLUG="test-pipeline"

  stub buildkite-agent \
    "annotate * --context * --style 'error' --append : echo 'Failed to fetch build information'"

  run "$PWD"/hooks/pre-command

  assert_failure
  assert_output --partial "Failed to fetch build information"

  unstub buildkite-agent
}
