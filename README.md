# Uncapped Rancher chart

[Rancher](https://github.com/rancher/rancher)'s official Helm chart with the `kubeVersion`
constraint removed from `Chart.yaml`, so Rancher can be installed and upgraded on Kubernetes
versions newer than the ones the upstream chart officially caps.

## Usage

```bash
helm repo add uncapped-rancher https://cubos-devops.github.io/uncapped-rancher-chart/
helm repo update
helm search repo uncapped-rancher/rancher --versions
helm upgrade --install rancher uncapped-rancher/rancher --version <version> \
  --namespace cattle-system --create-namespace \
  --set hostname=rancher.example.com
```

The repository index is served at
<https://cubos-devops.github.io/uncapped-rancher-chart/index.yaml>.

## How it works

`script.sh` downloads the upstream index from
`https://releases.rancher.com/server-charts/latest`, and for each selected `rancher` chart
version it downloads the package, deletes `kubeVersion` from `Chart.yaml`, repackages it and
updates the index entry (digest included). Versions that were not patched are dropped from the
index. The result is written to `public/`.

The GitHub Actions workflow in [`.github/workflows/pages.yml`](.github/workflows/pages.yml)
runs the script and publishes `public/` to GitHub Pages on every push to `main`, weekly, and on
demand (`workflow_dispatch`).

To change which versions are patched, edit `MIN_VERSION_TO_PATCH` and `SKIP_RC_VERSIONS` at the
top of `script.sh`.

## Disclaimer

This is an **unofficial** repackaging and is not supported by SUSE or Rancher. Removing the
`kubeVersion` cap only stops Helm from refusing the install: Rancher has not necessarily been
tested against the Kubernetes version you run it on. Use at your own risk.

## Attribution and license

The charts published here are built from the official Rancher charts (© SUSE LLC / Rancher
Labs, licensed under the [Apache License 2.0](https://github.com/rancher/rancher/blob/main/LICENSE)).
The only modification is the removal of the `kubeVersion` field from `Chart.yaml`. Rancher is a
trademark of SUSE LLC.
