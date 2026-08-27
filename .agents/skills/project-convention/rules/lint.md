# Lint and Analysis

The active source of truth is root `analysis_options.yaml`, currently based on
`flutter_lints`. Read it rather than assuming a different lint package.

Generated output and the `sli_common` submodule follow the exclusions declared
there. Never manually edit generated files.

```bash
derry gen
derry analyze
derry test
derry quality
```

`scripts/format.sh` deliberately excludes `lib/modules/sli_common` because the
submodule is a separate repository with its own gates. New code must not add
errors or warnings; record legacy analyzer debt honestly until it reaches zero.
