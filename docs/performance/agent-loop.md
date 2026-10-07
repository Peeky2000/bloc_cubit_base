# Performance agent loop

The PM plugs in a device and asks for a performance check. Two agents run the
rest and the PM reads one report at the end.

```text
PM: plug in a device, ask "check performance"
 └─ perf-tester (measure)
      derry perf run → performance/latest/summary.json
      diagnose FAIL targets, inspect code, write handoff
       └─ perf-engineer
            fix one cause, derry quality, self-measure, fill Fix section
             └─ perf-tester (verify)
                  re-measure, fill Verification
                  FAIL → back to perf-engineer (max 3 rounds)
                  PASS → PM report, propose baseline approval
PM: read the report, approve baseline or decide trade-offs
```

## What the PM does

1. Plug in one real Android or iOS device and unlock it. Keep the same device
   for later runs so results stay comparable.
2. Once per machine, give the agents a dedicated test account on `dev` or
   `staging` by setting `PERF_USERNAME` and `PERF_PASSWORD` in the shell.
   Measurements use real backend data, never fake data.
3. Ask the orchestrating agent: "Kiểm tra performance app" or
   "Đo lại màn danh sách đơn hàng".
4. Read the PM report in `docs/performance/` and answer its questions, such as
   approving a baseline or choosing a UX trade-off.

## Handoff template

Save as `docs/performance/handoffs/YYYY-MM-DD-hh-mm-<topic>.md`.

```markdown
# <topic>

Status: OPEN | FIXED | VERIFIED | REJECTED
Round: 1

## Environment
Device, platform, flavor, Flutter version, summary.json path.

## Findings (perf-tester)
### F1 <target id>: <metric> <current> vs <limit or baseline>
- Evidence: numbers from the non-diagnosis run, report path.
- Hotspots: top rows from the diagnosis table.
- Likely cause: file:line and why, marked confirmed or hypothesis.
- Done when: the gated metric passes and improves beyond noise.

## Fix (perf-engineer)
- Cause, change, files, test added, derry quality result.
- Self-measured numbers.

## Verification (perf-tester)
- Re-measured numbers versus the Findings baseline.
- Verdict: PASS or FAIL, and the next step.
```

## PM report template

Save as `docs/performance/YYYY-MM-DD-report.md`. Write it for a non-engineer.

```markdown
# Performance report <date>

Result: PASS | FAIL | NEEDS DECISION
Device: <name>, flavor <flavor>

| Area | Before | After | Status |
|---|---|---|---|
| App start (first frame) | 1840 ms | 1210 ms | Better |
| Orders API (slowest call) | 2300 ms | 2300 ms | Backend, not app |

What changed: one sentence per fix.
Needs your decision: baseline approval, trade-offs, missing device.
Still not measured: areas without scenarios.
```

## Orchestration rules

- The orchestrator spawns `perf-tester` first and passes the handoff path
  between agents. Agents never share numbers except through the handoff.
- Stop after three engineer rounds on the same finding and escalate in the PM
  report.
- Only one agent uses the device at a time.
- Baselines change only after the PM approves in the conversation.
