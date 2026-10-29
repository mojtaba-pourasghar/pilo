#!/usr/bin/env python3
"""Generates the game's art with Cloudflare Workers AI (FLUX), job by job, from
tools/art/manifest.json. Finished pictures are skipped, so it can run every day on the free
daily allowance and simply continue where it stopped; when an account's allowance is used up
it moves on to the next account, and stops when all are used up. Keys come from the
environment, never from files in the project: CF_KEYS="account:token,account:token,..." or a
single CF_ACCOUNT_ID + CF_API_TOKEN.

    python3 tools/art/cf_generate.py [--only id1,id2] [--limit N]

Output: art_src/<id>.png (raw, kept in git so a day's work is never lost). Transparent
cut-outs are made afterwards by tools/art/postprocess.py.
"""
import argparse, base64, io, json, os, sys, time, urllib.request, urllib.error, uuid

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
MANIFEST = os.path.join(ROOT, "tools", "art", "manifest.json")
OUT = os.path.join(ROOT, "art_src")


class QuotaUsed(Exception):
    pass


def _post(url, data, headers):
    req = urllib.request.Request(url, data=data, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            return r.read(), r.headers.get("Content-Type", "")
    except urllib.error.HTTPError as e:
        body = e.read()
        if b"4006" in body or b"daily free allocation" in body:
            raise QuotaUsed(body[:200])
        raise RuntimeError(f"HTTP {e.code}: {body[:300]!r}")


def _multipart(fields, files):
    boundary = uuid.uuid4().hex
    out = io.BytesIO()
    for k, v in fields.items():
        out.write(f"--{boundary}\r\nContent-Disposition: form-data; name=\"{k}\"\r\n\r\n{v}\r\n".encode())
    for k, path in files.items():
        out.write(f"--{boundary}\r\nContent-Disposition: form-data; name=\"{k}\"; filename=\"{os.path.basename(path)}\"\r\nContent-Type: image/png\r\n\r\n".encode())
        out.write(open(path, "rb").read())
        out.write(b"\r\n")
    out.write(f"--{boundary}--\r\n".encode())
    return out.getvalue(), f"multipart/form-data; boundary={boundary}"


def run_job(job, style, account, token):
    model = job.get("model", "@cf/black-forest-labs/flux-2-klein-9b")
    url = f"https://api.cloudflare.com/client/v4/accounts/{account}/ai/run/{model}"
    prompt = job["prompt"] + ". " + style.get(job.get("style", "default"), "")
    w, h = job.get("size", [1024, 1024])
    auth = {"Authorization": f"Bearer {token}"}
    if "flux-2" in model:
        files = {}
        for i, ref in enumerate(job.get("refs", [])):
            files[f"input_image_{i}"] = os.path.join(OUT, ref + ".png")
        data, ctype = _multipart({"prompt": prompt, "width": w, "height": h}, files)
        raw, rtype = _post(url, data, {**auth, "Content-Type": ctype})
    else:
        body = {"prompt": prompt, "steps": job.get("steps", 8)}
        if "schnell" not in model:
            body.update({"width": w, "height": h})
        raw, rtype = _post(url, json.dumps(body).encode(), {**auth, "Content-Type": "application/json"})
    if rtype.startswith("image/"):
        return raw
    data = json.loads(raw)
    image = (data.get("result") or {}).get("image")
    if not image:
        raise RuntimeError(str(data)[:300])
    return base64.b64decode(image)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--limit", type=int, default=0)
    a = ap.parse_args()
    keys = [tuple(k.split(":", 1)) for k in os.environ.get("CF_KEYS", "").split(",") if ":" in k]
    if not keys and os.environ.get("CF_ACCOUNT_ID") and os.environ.get("CF_API_TOKEN"):
        keys = [(os.environ["CF_ACCOUNT_ID"], os.environ["CF_API_TOKEN"])]
    if not keys:
        sys.exit("CF_KEYS (or CF_ACCOUNT_ID / CF_API_TOKEN) is not set")
    spent = set()   # accounts whose daily allowance is used up (tokens of one account share it)
    manifest = json.load(open(MANIFEST, encoding="utf-8"))
    style = manifest["styles"]
    only = set(filter(None, a.only.split(",")))
    os.makedirs(OUT, exist_ok=True)
    done = made = 0
    for job in manifest["jobs"]:
        path = os.path.join(OUT, job["id"] + ".png")
        if only and job["id"] not in only:
            continue
        if os.path.exists(path):
            done += 1
            continue
        if any(not os.path.exists(os.path.join(OUT, r + ".png")) for r in job.get("refs", [])):
            print("wait  ", job["id"], "(needs", job["refs"], ")")
            continue
        image = None
        failed = False
        for account, token in keys:
            if account in spent:
                continue
            try:
                image = run_job(job, style, account, token)
                break
            except QuotaUsed:
                print("quota used up for account", account[:6] + "…")
                spent.add(account)
            except Exception as e:
                print("fail  ", job["id"], e)
                failed = True
                time.sleep(2)
                break
        if failed:
            continue
        if image is None:
            print("all accounts used up for today")
            break
        from PIL import Image
        Image.open(io.BytesIO(image)).convert("RGB").save(path)
        made += 1
        print("made  ", job["id"])
        if a.limit and made >= a.limit:
            break
    total = len(manifest["jobs"])
    print(f"{made} made now, {done + made}/{total} done")


if __name__ == "__main__":
    main()
