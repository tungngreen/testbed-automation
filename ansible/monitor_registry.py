import os
import sys
import json
import subprocess
import requests

# Read from CLI
REGISTRY_URL = sys.argv[1]
IMAGES = sys.argv[2:]

METADATA_FILE = ".image_versions.json"
BASH_SCRIPT = "./update_images.sh"

print(f"Registry: {REGISTRY_URL}")
print(f"Monitoring {len(IMAGES)} image(s): {IMAGES}")

def load_metadata():
    if os.path.exists(METADATA_FILE):
        with open(METADATA_FILE, "r") as f:
            return json.load(f)
    return {}

def save_metadata(metadata):
    with open(METADATA_FILE, "w") as f:
        json.dump(metadata, f, indent=4)

def get_image_metadata(repo, tag):
    headers = {"Accept": "application/vnd.docker.distribution.manifest.v2+json"}
    manifest_url = f"http://{REGISTRY_URL}/v2/{repo}/manifests/{tag}"
    manifest_res = requests.get(manifest_url, headers=headers)

    if manifest_res.status_code != 200:
        print(f"❌ Failed to fetch manifest for {repo}:{tag}")
        return None

    manifest = manifest_res.json()
    config_digest = manifest["config"]["digest"]

    config_url = f"http://{REGISTRY_URL}/v2/{repo}/blobs/{config_digest}"
    config_res = requests.get(config_url)

    if config_res.status_code != 200:
        print(f"❌ Failed to fetch config blob for {repo}:{tag}")
        return None

    config = config_res.json()
    created = config.get("created", "unknown")
    size = sum(layer["size"] for layer in manifest.get("layers", []))
    image_id = config_digest.split(":")[1]

    return {
        "digest": config_digest,
        "created": created,
        "image_id": image_id[:12],
        "size": size
    }

def trigger_update_script():
    print("🚀 Triggering update script...")
    subprocess.run(["bash", BASH_SCRIPT])

def check_for_updates():
    metadata = load_metadata()
    updated = False

    for image in IMAGES:
        print(f"🔍 Checking {image}...")

        if ":" not in image:
            print(f"⚠️  Invalid image format: {image} (use repo:tag)")
            continue

        repo, tag = image.split(":")
        new_meta = get_image_metadata(repo, tag)
        if not new_meta:
            continue

        saved_meta = metadata.get(image)
        if not saved_meta or saved_meta.get("digest") != new_meta["digest"]:
            print(f"✅ Image {image} updated.")
            metadata[image] = new_meta
            updated = True

    if updated:
        save_metadata(metadata)
        trigger_update_script()

    return updated

if __name__ == "__main__":
    if check_for_updates():
        print("🎯 Updates detected.")
    else:
        print("✅ No updates detected.")
