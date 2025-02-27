# Git Diff Buildkite Plugin

A Buildkite plugin that shows git diff as a build annotation. You can compare against a target branch, a specific number of previous commits, include submodule changes, or compare a build against previous build.

## Example

Add the following to your `pipeline.yml`:

```yaml
steps:
  - command: echo "Running with git diff..."
    plugins:
      - annotate-git-diff#v1.1.0:
          context: "my-diff"           # optional
          format: "markdown"           # optional (markdown|diff)
          compare_branch: "main"       # optional (defaults to comparing against previous commit)
          compare_commits: 3           # optional (compare against 3 commits back, ignored if compare_branch is set)
          include_merge_base: true     # optional (defaults to true)
          include_submodules: false    # optional (defaults to false)
          compare_previous_build: false    # optional (defaults to false)
```

## Configuration

### `context` (optional)
The annotation context. Default: `git-diff`

### `format` (optional)
The output format for the diff. Can be either `markdown` or `diff`. Default: `markdown`

### `compare_branch` (optional)
The branch to compare against. If not set, will compare against previous commits based on `compare_commits`. Default: none

### `compare_commits` (optional)
Number of commits to compare against when no branch is specified. Default: `1`

### `include_merge_base` (optional)
When comparing against a branch:
- `true`: Compares against the common ancestor of the current commit and target branch
- `false`: Compares directly against the HEAD of the target branch
Default: `true`

### `include_submodules` (optional)
Whether to include submodule changes in the diff output.
- `true`: Shows submodule changes in diff and includes them in statistics
- `false`: Excludes submodule changes
Default: `false`

### `compare_previous_build` (optional)
Whether to compare a build to the previous build. You'll need to provide an API access token with `read_builds` permissions to run this check. Only use this chech as a standalone check, make sure to set other checks to false if you want to use the `compare_previous_build` check.
- `true`: Shows changes between the last two successful builds on the pipeline
- `false`: Does not compare a build to the previous build
Default: `false`

## Usage Examples

### Compare against a branch:
```yaml
steps:
  - plugins:
      - annotate-git-diff#v1.1.0:
          compare_branch: "main"
```

### Compare against multiple previous commits:
```yaml
steps:
  - plugins:
      - annotate-git-diff#v1.1.0:
          compare_commits: 3  # Shows changes in last 3 commits
```

### Include submodule changes:
```yaml
steps:
  - plugins:
      - annotate-git-diff#v1.1.0:
          compare_branch: "main"
          include_submodules: true
```

### Compare a build to a previous build:
```yaml
steps:
  - plugins:
      - annotate-git-diff#v1.1.0:
          compare_previous_build: true
          buildkite_api_token: ${BUILDKITE_API_TOKEN} # API access token with `read_builds` permissions. If you are setting the pipeline configuration in the Steps Editor, use `$${BUILDKITE_API_TOKEN}`.
```

### Raw diff format:
```yaml
steps:
  - plugins:
      - annotate-git-diff#v1.1.0:
          format: "diff"
```

## Development

To run the tests:

```bash
docker-compose run --rm tests
```

## License

MIT
