# Fix Checkout Buildkite Plugin

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) to skip reset the checkout when `git fsck` fails. Sometimes a checkout (especially when using git mirrors?) can become corrupt and start failing with errors like this:

```
$ git fetch -v --prune -- origin +refs/heads/*:refs/remotes/origin/* +refs/tags/*:refs/tags/*
…
Receiving objects: 100% …
Resolving deltas: 100% …
fatal: bad object refs/remotes/origin/example
error: github.com:example/example.git did not send all necessary objects
```

This seems to only be an issue on long lived agents for things like container builds.

## Example

```yaml
steps:
  - plugins:
    - ennova/fix-checkout#v1.0.0:
```
