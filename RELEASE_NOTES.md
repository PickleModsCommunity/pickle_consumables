# pickle_consumables v1.0.4

## Fixes

- Validate item transfers, placement, pickup proximity and timed consumption on the server.
- Persist held and dropped items and synchronize late joins.
- Restore items when placement is rejected and check inventory grants.
- Remove client-controlled server entity deletion and improve effect cleanup.

## Upgrade notes

- Thrown props are local cosmetic entities. Verify inventory adapter behavior and item effects on the target server.

## Package and validation

- The ZIP contains one pickle_consumables/ folder with the complete resource, installation files, license and runtime NUI assets where applicable. Unbuilt web/ sources, node_modules/ and Git metadata are excluded.
- Required local NUI scripts and stylesheets were checked before packaging. Prior remediation validation passed targeted mocked regressions and Lua/JavaScript syntax checks; this is not a live FiveM integration test.
- Test the resource with your installed frameworks, inventory, database and other integrations before use. Transactions spanning framework persistence, SQL and local KVP still have crash-recovery boundaries.

Source: [audit remediation PR #6](https://github.com/PickleModsCommunity/pickle_consumables/pull/6), branch `fix/audit-remediation`. This release includes the PR changes without merging the PR.
