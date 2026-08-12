#!/usr/bin/env bash
#!/usr/bin/env bash
set -Eeuo pipefail

REMOTE="${REMOTE:-origin}"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
fi

VERSION="$1"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
    echo "Invalid version: $VERSION" >&2
    echo "Example: 1.0.0 or 1.0.0-beta.1" >&2
    exit 1
fi

TAG="v${VERSION}"

git rev-parse --is-inside-work-tree >/dev/null

BRANCH="$(git symbolic-ref --quiet --short HEAD || true)"

if [[ -z "$BRANCH" ]]; then
    echo "Cannot create a release from detached HEAD." >&2
    exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
    echo "There are uncommitted changes. Commit them first." >&2
    git status --short
    exit 1
fi

if git rev-parse --verify --quiet "refs/tags/$TAG" >/dev/null; then
    echo "Local tag $TAG already exists." >&2
    exit 1
fi

if git ls-remote --exit-code --tags "$REMOTE" "refs/tags/$TAG" >/dev/null 2>&1; then
    echo "Tag $TAG already exists on $REMOTE." >&2
    exit 1
fi

git tag -a "$TAG" -m "Release $TAG"

if ! git push --atomic "$REMOTE" "$BRANCH" "refs/tags/$TAG"; then
    echo "Push failed. Local tag $TAG was kept." >&2
    exit 1
fi

echo "Done:"
echo "  Branch:  $BRANCH"
echo "  Version: $VERSION"
echo "  Tag:     $TAG"
echo "  Commit:  $(git rev-parse --short HEAD)"