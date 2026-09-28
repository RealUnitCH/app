#!/usr/bin/env python3
"""Prepare App Store version 1.2.35 for the build already in TestFlight."""

import json
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request

import jwt

BUNDLE_ID = "swiss.realunit.app"
VERSION = "1.2.35"
BUILD = "10235999"
BASE = "https://api.appstoreconnect.apple.com"
METADATA = "ios/fastlane/metadata/de-DE"


def token():
    key = open(os.environ["KEY_PATH"]).read()
    return jwt.encode(
        {
            "iss": os.environ["ISSUER_ID"],
            "aud": "appstoreconnect-v1",
            "exp": int(time.time()) + 600,
        },
        key,
        algorithm="ES256",
        headers={"kid": os.environ["KEY_ID"], "typ": "JWT"},
    )


TOK = None


def redact(text):
    return re.sub(
        r'("demoAccountPassword"\s*:\s*")[^"]*"',
        r'\1[redacted]"',
        text,
    )


def api(method, path, body=None, tolerate=()):
    global TOK
    if TOK is None:
        TOK = token()
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(BASE + path, data=data, method=method)
    req.add_header("Authorization", "Bearer " + TOK)
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as response:
            raw = response.read().decode()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        detail = redact(error.read().decode("utf-8", "replace"))
        if error.code in tolerate:
            print(f"HTTP {error.code} {method} {path} tolerated")
            return {}
        raise SystemExit(f"HTTP {error.code} {method} {path}\n{detail[:5000]}")


def read_meta(name):
    path = os.path.join(METADATA, name)
    if not os.path.exists(path):
        return ""
    return open(path).read().strip()


REVIEW_KEYS = (
    "contactFirstName",
    "contactLastName",
    "contactPhone",
    "contactEmail",
    "demoAccountName",
    "demoAccountPassword",
    "demoAccountRequired",
    "notes",
)


def copy_review_detail(versions_data, dest_id):
    """Reuse the last approved version's review contact. Never print it."""
    for item in versions_data:
        if item["attributes"].get("versionString") == VERSION:
            continue
        detail = api(
            "GET",
            f"/v1/appStoreVersions/{item['id']}/appStoreReviewDetail",
            tolerate=(404,),
        )
        attrs = (detail.get("data") or {}).get("attributes") or {}
        keep = {}
        for key in REVIEW_KEYS:
            value = attrs.get(key)
            if value is None or value == "":
                continue
            keep[key] = value
        if not keep:
            continue
        api(
            "POST",
            "/v1/appStoreReviewDetails",
            {
                "data": {
                    "type": "appStoreReviewDetails",
                    "attributes": keep,
                    "relationships": {
                        "appStoreVersion": {
                            "data": {"type": "appStoreVersions", "id": dest_id}
                        }
                    },
                }
            },
            tolerate=(409,),
        )
        print("copied review details from", item["attributes"].get("versionString"))
        return item["attributes"].get("copyright") or None
    print("no previous review details to copy")
    return None


def localization_fields(released):
    fields = {
        "description": read_meta("description.txt"),
        "keywords": read_meta("keywords.txt"),
        "supportUrl": read_meta("support_url.txt"),
        "marketingUrl": read_meta("marketing_url.txt") or None,
        "promotionalText": read_meta("promotional_text.txt") or None,
    }
    if released:
        fields["whatsNew"] = read_meta("release_notes.txt")
    return {key: value for key, value in fields.items() if value}


def upsert_localization(version_id, released):
    fields = localization_fields(released)
    existing = api(
        "GET",
        f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations",
    )
    match = next(
        (
            item
            for item in existing.get("data", [])
            if item["attributes"].get("locale") == "de-DE"
        ),
        None,
    )
    if match is None:
        api(
            "POST",
            "/v1/appStoreVersionLocalizations",
            {
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "attributes": {"locale": "de-DE", **fields},
                    "relationships": {
                        "appStoreVersion": {
                            "data": {"type": "appStoreVersions", "id": version_id}
                        }
                    },
                }
            },
        )
        print("added de-DE localization")
        return
    api(
        "PATCH",
        f"/v1/appStoreVersionLocalizations/{match['id']}",
        {
            "data": {
                "type": "appStoreVersionLocalizations",
                "id": match["id"],
                "attributes": fields,
            }
        },
    )
    print("updated de-DE localization")


def ensure_review_detail(versions_data, dest_id):
    current = api(
        "GET",
        f"/v1/appStoreVersions/{dest_id}/appStoreReviewDetail",
        tolerate=(404,),
    )
    if (current.get("data") or {}).get("id"):
        print("review details already present")
        return None
    return copy_review_detail(versions_data, dest_id)


def main():
    apps = api("GET", "/v1/apps?" + urllib.parse.urlencode({"filter[bundleId]": BUNDLE_ID}))
    if not apps.get("data"):
        raise SystemExit("App not found for bundle " + BUNDLE_ID)
    app_id = apps["data"][0]["id"]
    print("app", app_id, apps["data"][0]["attributes"].get("name"))

    versions = api(
        "GET",
        f"/v1/apps/{app_id}/appStoreVersions?filter[platform]=IOS&limit=20",
    )
    print("versions:")
    by_string = {}
    for item in versions.get("data", []):
        attrs = item["attributes"]
        print(" -", item["id"], attrs.get("versionString"), attrs.get("appStoreState"), attrs.get("releaseType"))
        by_string[attrs.get("versionString")] = item

    # Apple refuses a new version while an approved one is waiting for a
    # manual release. Release that version, then 1.2.35 can be created.
    held = [
        item
        for item in versions.get("data", [])
        if item["attributes"].get("appStoreState") == "PENDING_DEVELOPER_RELEASE"
    ]
    for item in held:
        print("releasing held version", item["attributes"].get("versionString"))
        api(
            "POST",
            "/v1/appStoreVersionReleaseRequests",
            {
                "data": {
                    "type": "appStoreVersionReleaseRequests",
                    "relationships": {
                        "appStoreVersion": {
                            "data": {"type": "appStoreVersions", "id": item["id"]}
                        }
                    },
                }
            },
            tolerate=(409,),
        )
    if held:
        cleared = False
        for _ in range(18):
            time.sleep(10)
            versions = api(
                "GET",
                f"/v1/apps/{app_id}/appStoreVersions?filter[platform]=IOS&limit=20",
            )
            by_string = {item["attributes"].get("versionString"): item for item in versions.get("data", [])}
            states = [item["attributes"].get("appStoreState") for item in versions.get("data", [])]
            print("states after release", states)
            if "PENDING_DEVELOPER_RELEASE" not in states:
                cleared = True
                break
        if not cleared:
            raise SystemExit("A version is still pending developer release")

    builds = api(
        "GET",
        "/v1/builds?"
        + urllib.parse.urlencode(
            {
                "filter[app]": app_id,
                "filter[version]": BUILD,
                "limit": "5",
            }
        ),
    )
    if not builds.get("data"):
        raise SystemExit("Build " + BUILD + " not found")
    build = builds["data"][0]
    print(
        "build",
        build["id"],
        build["attributes"].get("processingState"),
        "uploaded",
        build["attributes"].get("uploadedDate"),
    )
    if build["attributes"].get("processingState") != "VALID":
        raise SystemExit("Build is not VALID yet")
    if build["attributes"].get("usesNonExemptEncryption") is None:
        api(
            "PATCH",
            f"/v1/builds/{build['id']}",
            {
                "data": {
                    "type": "builds",
                    "id": build["id"],
                    "attributes": {"usesNonExemptEncryption": False},
                }
            },
        )
        print("set usesNonExemptEncryption false")

    version = by_string.get(VERSION)
    copyright_text = None
    released = any(
        item["attributes"].get("appStoreState") == "READY_FOR_SALE"
        for item in versions.get("data", [])
    )
    if version is None:
        created = api(
            "POST",
            "/v1/appStoreVersions",
            {
                "data": {
                    "type": "appStoreVersions",
                    "attributes": {
                        "platform": "IOS",
                        "versionString": VERSION,
                        "releaseType": "AFTER_APPROVAL",
                    },
                    "relationships": {
                        "app": {"data": {"type": "apps", "id": app_id}}
                    },
                }
            },
        )
        version = created["data"]
        print("created version", version["id"])
    else:
        state = version["attributes"].get("appStoreState")
        print("existing version", version["id"], state)
        if state not in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED"):
            print("version is not editable; nothing to prepare")
            return

    upsert_localization(version["id"], released)
    copyright_text = ensure_review_detail(versions.get("data", []), version["id"])

    api(
        "PATCH",
        f"/v1/appStoreVersions/{version['id']}",
        {
            "data": {
                "type": "appStoreVersions",
                "id": version["id"],
                "attributes": {
                    "releaseType": "AFTER_APPROVAL",
                    **({"copyright": copyright_text} if copyright_text else {}),
                },
                "relationships": {
                    "build": {"data": {"type": "builds", "id": build["id"]}}
                },
            }
        },
    )
    print("attached build and set release after approval")


if __name__ == "__main__":
    main()
