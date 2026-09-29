# -*- coding: utf-8 -*-
"""Write the classic capture markdown (curl + response) for ONE request of a newman run,
so a newman-driven test case can feed the same evidence-card renderer as the manual ones."""
import io, json, sys

run_json, request_name, out = sys.argv[1], sys.argv[2], sys.argv[3]
run = json.load(io.open(run_json, encoding="utf-8"))
execs = [e for e in run["run"]["executions"] if e["item"]["name"] == request_name]
if not execs:
    sys.exit("no execution named %r — have: %s" % (request_name, sorted({e["item"]["name"] for e in run["run"]["executions"]})))
ex = execs[-1]

url = ex["request"]["url"]
query = "&".join("%s=%s" % (q["key"], q.get("value") or "") for q in url.get("query") or [] if not q.get("disabled"))
address = "%s://%s%s/%s%s" % (url["protocol"], ".".join(url["host"]),
                             (":" + str(url["port"])) if url.get("port") else "",
                             "/".join(url["path"]), ("?" + query) if query else "")
headers = [h for h in ex["request"]["header"] if not h.get("system") and not h.get("disabled")]
lines = ["curl -X %s '%s' \\" % (ex["request"]["method"], address)]
lines += ["  -H '%s: %s' \\" % (h["key"], h["value"]) for h in headers]
lines.append("  -H 'Authorization: Bearer <token redacted>'")
raw = (ex["request"].get("body") or {}).get("raw")
if raw:
    lines[-1] += " \\"
    lines.append("  -d '%s'" % raw)

body = bytes(ex["response"]["stream"]["data"]).decode("utf-8")
md = u"""### %s

**curl (Request)**

```bash
%s
```

**Response**

- HTTP `%s`
- Duration: `%s ms`

Body:

```json
%s
```
""" % (request_name, "\n".join(lines), ex["response"]["code"], ex["response"]["responseTime"], body)
io.open(out, "w", encoding="utf-8").write(md)
print("%s  HTTP %s  ->  %s" % (request_name, ex["response"]["code"], out))
