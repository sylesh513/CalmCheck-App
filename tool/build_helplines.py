#!/usr/bin/env python3
"""Builds the bundled helpline dataset.

Two very different kinds of number end up in one file:

* **Emergency services**, for every territory, derived from Google's
  libphonenumber `ShortNumberMetadata.xml` (Apache-2.0). That metadata comes
  from the ITU and national numbering plan administrators, and is the same data
  Android uses for emergency dialling — about as good as an offline source gets.

* **Crisis helplines**, hand-verified against the operator's own publication.
  Only countries actually checked are listed here. A number nobody verified is
  worse than no number, because the screen it appears on is a fire exit: for
  anywhere not covered the app sends people to findahelpline.com, which
  maintains 170+ countries properly.

Re-run after updating ShortNumberMetadata.xml, and re-check the crisis lines
before every release:

    python3 tool/build_helplines.py --metadata <path> --iso <path>
"""

import argparse
import json
import re
import xml.etree.ElementTree as ET
from datetime import date

# --------------------------------------------------------------------------
# Crisis helplines. Every entry was checked against the operator's own page or
# a government publication on the date given. Add a country only after doing
# the same.
# --------------------------------------------------------------------------
CRISIS = {
    "IN": [dict(
        name="Tele-MANAS", numbers=["14416", "1800-891-4416"],
        sub="Government of India mental health helpline. Free, 24 hours, in "
            "English and 20 regional languages.")],
    "US": [dict(
        name="988 Suicide & Crisis Lifeline", numbers=["988"],
        sub="Call or text. Free and open around the clock.")],
    "CA": [dict(
        name="Suicide Crisis Helpline", numbers=["988"],
        sub="Call or text, in English and French, around the clock.")],
    "GB": [dict(
        name="Samaritans", numbers=["116 123"],
        sub="Free to call from any phone, any time of day or night.")],
    "IE": [dict(
        name="Samaritans", numbers=["116 123"],
        sub="Free to call from any phone, any time of day or night.")],
    "AU": [dict(
        name="Lifeline", numbers=["13 11 14"],
        sub="Crisis support and suicide prevention, 24 hours.")],
    "NZ": [dict(
        name="1737 Need to talk?", numbers=["1737"],
        sub="Call or text a trained counsellor, free, 24 hours.")],
    "DE": [dict(
        name="TelefonSeelsorge", numbers=["0800 111 0 111", "116 123"],
        sub="Free, anonymous and open around the clock.")],
    "FR": [dict(
        name="Numéro national de prévention du suicide", numbers=["3114"],
        sub="Free and confidential, 24 hours a day.")],
    "NL": [dict(
        name="113 Zelfmoordpreventie", numbers=["113", "0800 0113"],
        sub="Free and open around the clock.")],
}
CRISIS_VERIFIED_ON = "2026-08-23"

# The number a person in that country would actually reach for. Only where the
# ranking below gets it wrong and the correct answer is well established.
PRIMARY_OVERRIDE = {"PH": "911", "BR": "190"}

# 911 leads across the Americas; almost everywhere else a locally recognised
# three-digit number does, with 112 as the GSM fallback that works regardless.
HEAD_AMERICAS = ["911", "999", "000", "111", "112", "110"]
HEAD_ELSEWHERE = ["999", "000", "111", "112", "911", "110"]

MAX_EMERGENCY = 4

# ISO 3166 uses the long legal form. A person picking their country on a fire
# exit of a screen wants the name they call it.
SHORT_NAMES = {
    "BO": "Bolivia", "BN": "Brunei", "CD": "Congo (DRC)", "CG": "Congo",
    "CI": "Côte d\u2019Ivoire", "CZ": "Czechia", "FK": "Falkland Islands",
    "FM": "Micronesia", "GB": "United Kingdom", "IR": "Iran", "KP": "North Korea",
    "KR": "South Korea", "LA": "Laos", "MD": "Moldova", "MK": "North Macedonia",
    "MM": "Myanmar", "PS": "Palestine", "RU": "Russia", "SY": "Syria",
    "TW": "Taiwan", "TZ": "Tanzania", "US": "United States", "VA": "Vatican City",
    "VE": "Venezuela", "VN": "Vietnam", "VG": "British Virgin Islands",
    "VI": "U.S. Virgin Islands", "SZ": "Eswatini", "TL": "Timor-Leste",
    "NL": "Netherlands", "AE": "United Arab Emirates",
}


def display_name(code: str, official: str) -> str:
    if code in SHORT_NAMES:
        return SHORT_NAMES[code]
    # "Bonaire, Sint Eustatius and Saba" is a name; "Korea, Republic of" is a
    # legal form. Only the trailing legal forms are dropped.
    for suffix in (", Republic of", ", Kingdom of", ", State of",
                   ", United Republic of", ", Federated States of",
                   ", Province of China", ", Islamic Republic of",
                   ", Plurinational State of", ", Bolivarian Republic of"):
        if official.endswith(suffix):
            official = official[: -len(suffix)]
    official = re.sub(r"\s*\((the|.*?)\)\s*$", "", official).strip()
    return official


def literal_numbers(pattern: str) -> list[str]:
    """Expands a short-number pattern into the numbers it actually matches."""
    rx = re.compile("^(?:" + "".join(pattern.split()) + ")$")
    candidates = {f"{n:02d}" for n in range(100)}
    candidates |= {f"{n:03d}" for n in range(1000)}
    candidates |= {str(n) for n in range(1000, 10000)}
    return sorted(c for c in candidates if rx.match(c))


def order(numbers: list[str], americas: bool, override: str | None) -> list[str]:
    head = HEAD_AMERICAS if americas else HEAD_ELSEWHERE
    if override and override in numbers:
        head = [override] + [h for h in head if h != override]

    ranked = [n for n in head if n in numbers]
    rest = sorted((n for n in numbers if n not in ranked), key=lambda n: (len(n), n))
    return (ranked + rest)[:MAX_EMERGENCY]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--metadata", required=True, help="ShortNumberMetadata.xml")
    ap.add_argument("--iso", required=True, help="ISO 3166-1 JSON with names")
    ap.add_argument("--out", default="assets/helplines/helplines.json")
    args = ap.parse_args()

    iso = {c["alpha-2"]: c for c in json.load(open(args.iso))}
    root = ET.parse(args.metadata).getroot()

    countries: dict[str, dict] = {}
    for territory in root.iter("territory"):
        code = territory.get("id")
        emergency = territory.find("emergency")
        if emergency is None or code not in iso:
            continue
        pattern = emergency.find("nationalNumberPattern")
        if pattern is None or not pattern.text:
            continue

        numbers = literal_numbers(pattern.text)
        if not numbers:
            continue

        entry = iso[code]
        countries[code] = {
            "name": display_name(code, entry["name"]),
            "emergency": order(
                numbers,
                americas=entry.get("region") == "Americas",
                override=PRIMARY_OVERRIDE.get(code),
            ),
        }

    for code, lines in CRISIS.items():
        if code not in countries:
            raise SystemExit(f"crisis line for unknown territory {code}")
        countries[code]["crisis"] = [
            {**line, "verified": CRISIS_VERIFIED_ON} for line in lines
        ]

    payload = {
        "schema": 1,
        "generated": date.today().isoformat(),
        "emergencySource":
            "google/libphonenumber ShortNumberMetadata.xml (Apache-2.0), "
            "derived from ITU and national numbering plan administrators",
        "crisisVerifiedOn": CRISIS_VERIFIED_ON,
        "countries": dict(sorted(countries.items())),
    }
    with open(args.out, "w") as f:
        json.dump(payload, f, indent=1, ensure_ascii=False, sort_keys=False)
        f.write("\n")

    with_crisis = sum(1 for c in countries.values() if "crisis" in c)
    print(f"{len(countries)} territories, {with_crisis} with a verified crisis line")


if __name__ == "__main__":
    main()
