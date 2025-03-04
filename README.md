# Git Diff Buildkite Plugin

A Buildkite plugin that shows git diff as a build annotation. You can compare against a target branch, a specific number of previous commits, or include submodule changes.

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
