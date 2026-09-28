#!/usr/bin/env python3
"""Prepare App Store version 1.2.35 for the build already in TestFlight."""

import json
import os
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


def api(method, path, body=None):
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
        detail = error.read().decode("utf-8", "replace")
        raise SystemExit(f"HTTP {error.code} {method} {path}\n{detail[:5000]}")


def read_meta(name):
    path = os.path.join(METADATA, name)
    if not os.path.exists(path):
        return ""
    return open(path).read().strip()


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
        print(" -", attrs.get("versionString"), attrs.get("appStoreState"), attrs.get("releaseType"))
        by_string[attrs.get("versionString")] = item

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
        attributes = {
            "locale": "de-DE",
            "description": read_meta("description.txt"),
            "keywords": read_meta("keywords.txt"),
            "supportUrl": read_meta("support_url.txt"),
            "marketingUrl": read_meta("marketing_url.txt") or None,
            "promotionalText": read_meta("promotional_text.txt") or None,
        }
        if released:
            attributes["whatsNew"] = read_meta("release_notes.txt")
        attributes = {key: value for key, value in attributes.items() if value}
        api(
            "POST",
            "/v1/appStoreVersionLocalizations",
            {
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "attributes": attributes,
                    "relationships": {
                        "appStoreVersion": {
                            "data": {"type": "appStoreVersions", "id": version["id"]}
                        }
                    },
                }
            },
        )
        print("added de-DE localization")
    else:
        state = version["attributes"].get("appStoreState")
        print("existing version", version["id"], state)
        if state not in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED"):
            print("version is not editable; nothing to prepare")
            return

    api(
        "PATCH",
        f"/v1/appStoreVersions/{version['id']}",
        {
            "data": {
                "type": "appStoreVersions",
                "id": version["id"],
                "attributes": {"releaseType": "AFTER_APPROVAL"},
                "relationships": {
                    "build": {"data": {"type": "builds", "id": build["id"]}}
                },
            }
        },
    )
    print("attached build and set release after approval")


if __name__ == "__main__":
    main()
