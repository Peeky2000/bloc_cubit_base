# Skill routing eval

Checks whether an agent picks the right skill from the `name` and
`description` in each `.agents/skills/<name>/SKILL.md` frontmatter. It tests
routing only, not the quality of the work a skill produces.

Latest results and the description changes are in
[docs/reviews/2026-10-08-skill-routing-eval.md](../../../docs/reviews/2026-10-08-skill-routing-eval.md).

## Files

| File | Content |
|---|---|
| `routing.json` | 90 cases: `{"id", "query", "expected"}` |

`expected` lists every skill the agent should load, primary skill first.
`["none"]` means no skill fits. Ids starting with `holdout-` were written after
the descriptions were tuned on the other 78 cases, so they test whether a fix
generalizes. Keep that split when you add cases.

Id prefixes describe the case: `<skill>-NN` is a plain should-trigger request,
`near-<a>-vs-<b>-NN` shares keywords with skill `b` but belongs to `a`,
`multi-...` needs two skills, `none-NN` needs no skill.

## Rerun

The eval needs a judge model that sees only skill names, descriptions and the
requests. It must not see `expected`, the skill bodies or the repository.

1. Build a blind prompt and an answer key. PyYAML is not installed here, so
   use Ruby, which ships with YAML and JSON:

   ```bash
   mkdir -p /tmp/routing && cd /tmp/routing
   ruby -ryaml -rjson -e '
     skills = ".agents/skills"; repo = ARGV[0]
     cases = JSON.parse(File.read("#{repo}/#{skills}/evals/routing.json"))
     descs = Dir.children("#{repo}/#{skills}").sort.filter_map { |d|
       f = "#{repo}/#{skills}/#{d}/SKILL.md"; next unless File.file?(f)
       fm = YAML.safe_load(File.read(f)[/\A---\n(.*?)\n---/m, 1])
       "- **#{fm["name"]}**: #{fm["description"].strip.gsub(/\s+/, " ")}" }
     order = cases.shuffle(random: Random.new(20261008)); key = {}
     reqs = order.each_with_index.map { |c, i| q = format("q%02d", i + 1); key[q] = c["id"]; "#{q}: #{c["query"]}" }
     File.write("key.json", JSON.pretty_generate(key))
     File.write("prompt.txt", [File.read("#{repo}/#{skills}/evals/README.md")[/<!-- judge -->\n(.*?)<!-- \/judge -->/m, 1],
       "SKILLS:", descs, "", "REQUESTS:", reqs].flatten.join("\n"))
   ' /Users/long/Documents/Personal/bloc_cubit_base
   ```

2. Give `prompt.txt` to at least three judges, for example fresh subagents that
   may read only that file. Use more than one model size (a small model
   exposes weak wording sooner). Save each JSON answer as `run1.json`,
   `run2.json`, and so on.

3. Score:

   ```bash
   ruby -rjson -e '
     cases = JSON.parse(File.read(ARGV.shift)).to_h { |c| [c["id"], c["expected"]] }
     key = JSON.parse(File.read(ARGV.shift))
     ARGV.each do |f|
       pred = JSON.parse(File.read(f)[/\{.*\}/m]); ok = 0
       key.each do |q, id|
         got = Array(pred[q]); got = ["none"] if got.empty?
         if got.sort == cases[id].sort then ok += 1
         else puts "  #{f} #{id}: expected #{cases[id].join("+")}, got #{got.join("+")}" end
       end
       puts "#{f}: exact #{ok}/#{key.size}"
     end
   ' /Users/long/Documents/Personal/bloc_cubit_base/.agents/skills/evals/routing.json key.json run*.json
   ```

   "Exact" means the predicted set equals `expected`. Also look at
   per-skill false positives (an extra skill loaded) and misses.

The judge instructions used for the 2026-10-08 run are below. The step 1
script copies them into the prompt.

<!-- judge -->
You are acting as a skill router for an AI coding agent. Do NOT use any tools and do NOT read any files: answer only from the text below.

Context: the agent works in a Flutter app repository (Clean Architecture, Cubit/BLoC, get_it/injectable, Dio, gen-l10n, a shared UI package called sli_common). The agent can load skills. It decides which skill(s) to load ONLY from the skill names and descriptions below. The repo's instructions already make the agent read `project-convention` before any code change, so list `project-convention` only when the request is mainly about the repo's own conventions/rules.

For each user request, list the skill(s) the agent would load to handle it, most important first. Load a second skill only if the request clearly needs it too. Use ["none"] if no skill fits. Users write in Vietnamese, English, or a mix.

Reply with ONLY one JSON object mapping each request id to an array of skill names, for example {"q01": ["flutter-di"], "q02": ["none"]}. Include every id. No commentary.
<!-- /judge -->

## Add cases

- Write the request the way the PM, PO or developers really ask: Vietnamese,
  English or mixed, short, sometimes without punctuation.
- Use one case per behavior. Prefer near-misses: a request that shares a
  keyword with the wrong skill (for example "scroll" in a test request, "token"
  in a data-source task, "hardcode" in a shared widget).
- Decide `expected` from what the skill body actually covers, not from the
  description you want to test.
- Every skill needs at least two should-trigger cases. Skip `skills`, which is
  a symlink, not a skill.
- Run the eval before you change a description, so you have a baseline.

## Change a description

- Edit only the `description:` field. Keep the folded `>` style and stay under
  1024 characters, with no `<` or `>` inside the text.
- Say what the skill does, when to use it, the phrases users type, and
  "Not for X (use Y)" for each near-miss you saw fail.
- Validate the frontmatter. `skill-creator/scripts/quick_validate.py` needs
  PyYAML, which is not installed, so the Ruby check in the report does the
  same checks.
- Rerun all cases, including `holdout-` cases, and record before and after.
