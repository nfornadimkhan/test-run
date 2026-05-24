#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
import shutil
import tarfile
import urllib.parse
import urllib.request
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

BASE = Path("/Users/neon/Documents/Nadim's Brain")
EXT_BASE = BASE / "analysis" / "outputs" / "prediction_yield" / "external_validation"
DRYAD_API = "https://datadryad.org/api/v2"


@dataclass
class Dataset:
    key: str
    doi: str


DATASETS: List[Dataset] = [
    Dataset("dryad_rice", "10.5061/dryad.j9kd51ctd"),
    Dataset("dryad_wheat_sparse", "10.5061/dryad.vx0k6dk3p"),
    Dataset("dryad_maize_met", "10.5061/dryad.9w0vt4bc2"),
]


def fetch_json(url: str) -> Dict:
    with urllib.request.urlopen(url, timeout=60) as resp:
        return json.load(resp)


def download_file(url: str, dest: Path) -> None:
    with urllib.request.urlopen(url, timeout=300) as resp, open(dest, "wb") as out:
        shutil.copyfileobj(resp, out)


def resolve_dryad_version_bundle(doi: str) -> Tuple[str, str]:
    did = urllib.parse.quote(f"doi:{doi}", safe="")
    ds = fetch_json(f"{DRYAD_API}/datasets/{did}")
    version_href = ds.get("_links", {}).get("stash:version", {}).get("href")
    if not version_href:
        raise RuntimeError(f"Could not resolve version href for DOI {doi}")
    version_id = version_href.rstrip("/").split("/")[-1]
    return version_id, f"https://datadryad.org{version_href}/download"


def choose_file(files: List[Path], kind: str) -> Optional[Path]:
    def score(path: Path) -> int:
        n = path.name.lower()
        s = 0
        if kind == "phenotype":
            pats = ["pheno", "phenotype", "blue", "trait", "yield"]
        else:
            pats = ["marker", "geno", "genotype", "snp", "hapmap", ".hmp", "hinv", "grm"]
        for p in pats:
            if p in n:
                s += 3
        if n.endswith(".csv"):
            s += 2
        if n.endswith(".txt") or n.endswith(".tsv") or n.endswith(".hmp"):
            s += 1
        if n.endswith(".rdata") or n.endswith(".rds"):
            s += 1 if kind == "marker" else -2
        if "readme" in n:
            s -= 5
        return s

    ranked = sorted(((score(f), f) for f in files), key=lambda x: (x[0], x[1].name), reverse=True)
    if not ranked or ranked[0][0] <= 0:
        return None
    return ranked[0][1]


def normalize_to_csv(src: Path, dst: Path) -> Tuple[bool, str]:
    lower = src.name.lower()
    if lower.endswith(".csv"):
        shutil.copyfile(src, dst)
        return True, "copied_csv"

    if lower.endswith((".txt", ".tsv", ".hmp")):
        try:
            first = src.read_text(encoding="utf-8", errors="ignore").splitlines()[0]
            delim = "\t" if "\t" in first else ","
            with open(src, "r", encoding="utf-8", errors="ignore", newline="") as fin, open(dst, "w", encoding="utf-8", newline="") as fout:
                reader = csv.reader(fin, delimiter=delim)
                writer = csv.writer(fout)
                for row in reader:
                    writer.writerow(row)
            return True, f"converted_{'tab' if delim == '\t' else 'comma'}"
        except Exception as exc:
            return False, f"convert_failed:{exc}"

    return False, f"unsupported_extension:{src.suffix}"


def run_dataset(ds: Dataset) -> Dict[str, str]:
    ds_dir = EXT_BASE / ds.key
    raw_dir = ds_dir / "raw"
    src_dir = raw_dir / "source_files"
    src_dir.mkdir(parents=True, exist_ok=True)

    version_id, bundle_url = resolve_dryad_version_bundle(ds.doi)
    bundle_zip = src_dir / f"{ds.key}_{version_id}.zip"
    if not bundle_zip.exists():
        download_file(bundle_url, bundle_zip)

    extracted_dir = src_dir / f"{ds.key}_{version_id}_extracted"
    extracted_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(bundle_zip, "r") as zf:
        zf.extractall(extracted_dir)

    # Some Dryad bundles contain nested tar.gz payloads.
    for tgz in extracted_dir.rglob("*.tar.gz"):
        nested_dir = tgz.parent / (tgz.stem + "_extracted")
        nested_dir.mkdir(parents=True, exist_ok=True)
        with tarfile.open(tgz, "r:gz") as tf:
            tf.extractall(nested_dir)

    files = [p for p in extracted_dir.rglob("*") if p.is_file()]
    ph_src = choose_file(files, "phenotype")
    mk_src = choose_file(files, "marker")

    result = {
        "dataset_key": ds.key,
        "doi": ds.doi,
        "downloaded_files": str(len(files)),
        "phenotype_source": str(ph_src) if ph_src else "",
        "marker_source": str(mk_src) if mk_src else "",
        "phenotype_status": "missing",
        "marker_status": "missing",
        "notes": "",
    }

    if ph_src:
        ok, msg = normalize_to_csv(ph_src, raw_dir / "phenotype.csv")
        result["phenotype_status"] = msg if ok else f"failed:{msg}"
    if mk_src:
        ok, msg = normalize_to_csv(mk_src, raw_dir / "markers.csv")
        result["marker_status"] = msg if ok else f"failed:{msg}"

    notes = []
    if not (raw_dir / "phenotype.csv").exists():
        notes.append("phenotype.csv unresolved")
    if not (raw_dir / "markers.csv").exists():
        notes.append("markers.csv unresolved")
    result["notes"] = "; ".join(notes)

    with open(ds_dir / "95_fetch_manifest.json", "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2)

    return result


def main() -> None:
    EXT_BASE.mkdir(parents=True, exist_ok=True)
    rows: List[Dict[str, str]] = []
    for ds in DATASETS:
        try:
            rows.append(run_dataset(ds))
        except Exception as exc:
            rows.append(
                {
                    "dataset_key": ds.key,
                    "doi": ds.doi,
                    "downloaded_files": "0",
                    "phenotype_source": "",
                    "marker_source": "",
                    "phenotype_status": "error",
                    "marker_status": "error",
                    "notes": f"fetch_failed:{exc}",
                }
            )

    out_csv = EXT_BASE / "run_queue" / "95_fetch_summary.csv"
    out_csv.parent.mkdir(parents=True, exist_ok=True)
    cols = [
        "dataset_key",
        "doi",
        "downloaded_files",
        "phenotype_source",
        "marker_source",
        "phenotype_status",
        "marker_status",
        "notes",
    ]
    with open(out_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k, "") for k in cols})

    print(f"Saved: {out_csv}")
    for r in rows:
        print(r)


if __name__ == "__main__":
    main()
