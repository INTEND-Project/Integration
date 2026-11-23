"""Exercise the chart's rendered Kubernetes contract using Helm, not mocks."""
import json
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


CHART = Path(__file__).resolve().parents[1] / "application"
BACKEND = "sha256:a3573f585834c7be5d184cf2ac7523ae7b38f2c253377f9a59a60f141541cde4"
FRONTEND = "sha256:69afe73c3d0b9f57e075d10e529e0a0fa66b4e30f860d145eeb2aa11cb345f67"


class ChartTests(unittest.TestCase):
    def render(self, values=None, *, valid=True, pinned=True):
        overrides = {}
        if pinned:
            overrides = {"backend": {"image": {"digest": BACKEND}},
                         "frontend": {"image": {"digest": FRONTEND}}}
        def merge(target, source):
            for key, value in source.items():
                if isinstance(value, dict) and isinstance(target.get(key), dict):
                    merge(target[key], value)
                else:
                    target[key] = value
        merge(overrides, values or {})
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "values.json"
            path.write_text(json.dumps(overrides))
            result = subprocess.run(
                ["helm", "template", "insustain", str(CHART), "--namespace",
                 "insustain", "-f", str(path)], capture_output=True, text=True)
        if valid:
            self.assertEqual(result.returncode, 0, result.stderr)
            return result.stdout
        self.assertNotEqual(result.returncode, 0, "invalid settings rendered successfully")
        return result.stderr

    def documents(self, output, kind):
        return [doc for doc in output.split("---")
                if re.search(rf"^kind: {kind}$", doc, re.MULTILINE)]

    def test_default_deploys_published_pair_without_infrastructure(self):
        output = self.render(pinned=False)
        self.assertIn(f'ghcr.io/intend-project/insustain-backend@{BACKEND}', output)
        self.assertIn(f'ghcr.io/intend-project/insustain-frontend@{FRONTEND}', output)
        kinds = re.findall(r"^kind: (.+)$", output, re.MULTILINE)
        self.assertCountEqual(kinds, ["Deployment", "Deployment", "Service", "Service",
                                      "ServiceAccount", "Role", "RoleBinding"])
        self.assertIn('name: ENABLE_TRAINING_SCHEDULER\n              value: "false"', output)
        self.assertNotIn("GRAPHDB_URL", output)

    def test_digests_reject_empty_short_and_nonhex_values(self):
        for component in ("backend", "frontend"):
            for digest in ("", "sha256:abc", "sha256:" + "z" * 64):
                with self.subTest(component=component, digest=digest):
                    self.assertIn("digest", self.render(
                        {component: {"image": {"digest": digest}}}, valid=False))

    def test_default_pod_permissions_are_namespaced(self):
        output = self.render()
        role = self.documents(output, "Role")[0]
        self.assertIn('namespace: "insustain"', role)
        self.assertIn('resources: ["pods"]', role)
        self.assertIn('verbs: ["get", "list", "watch"]', role)
        self.assertNotIn("ClusterRole", output)

    def test_target_namespaces_have_scoped_roles_and_local_subject(self):
        output = self.render({"rbac": {"targetNamespaces": ["workloads", "tools"]}})
        roles = self.documents(output, "Role")
        bindings = self.documents(output, "RoleBinding")
        self.assertEqual(len(roles), 3)
        self.assertEqual(len(bindings), 3)
        for namespace in ("workloads", "tools", "insustain"):
            self.assertTrue(any(f'namespace: "{namespace}"' in role for role in roles))
        for binding in bindings:
            self.assertRegex(binding, r'subjects:\s*- kind: ServiceAccount\s*name: "?insustain-backend"?\s*namespace: "insustain"')
        self.assertNotIn("ClusterRole", output)

    def test_clusterwide_is_explicit_and_conflicts_with_targets(self):
        output = self.render({"rbac": {"clusterWide": True}})
        self.assertEqual(len(self.documents(output, "ClusterRole")), 1)
        self.assertEqual(len(self.documents(output, "Role")), 0)
        self.assertIn("targetNamespaces", self.render(
            {"rbac": {"clusterWide": True, "targetNamespaces": ["workloads"]}}, valid=False))

    def test_external_service_account_is_required_when_rbac_disabled(self):
        self.assertIn("serviceAccount.name", self.render({"rbac": {"create": False}}, valid=False))
        output = self.render({"rbac": {"create": False}, "serviceAccount": {"name": "existing-reader"}})
        self.assertIn('serviceAccountName: "existing-reader"', output)
        self.assertFalse(self.documents(output, "ServiceAccount"))
        self.assertFalse(self.documents(output, "Role"))

    def test_custom_managed_service_account_is_used_by_bindings(self):
        output = self.render({"serviceAccount": {"name": "custom-reader"}})
        self.assertIn('serviceAccountName: "custom-reader"', output)
        self.assertIn('name: "custom-reader"', self.documents(output, "ServiceAccount")[0])
        self.assertIn('name: "custom-reader"', self.documents(output, "RoleBinding")[0])

    def test_external_rbac_rejects_ineffective_scope_settings(self):
        for scope in ({"clusterWide": True}, {"targetNamespaces": ["workloads"]}):
            with self.subTest(scope=scope):
                self.assertIn("rbac.create", self.render({
                    "rbac": {"create": False, **scope},
                    "serviceAccount": {"name": "existing-reader"}}, valid=False))

    def test_generated_python_artifacts_are_ignored_by_git(self):
        result = subprocess.run([
            "git", "check-ignore", "--no-index",
            "k8s-deployments/insustain/tests/__pycache__/test_chart.cpython-312.pyc"],
            cwd=CHART.parents[2], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, "test bytecode could be accidentally staged")

    def test_upstream_tracks_custom_service_port_and_allows_override(self):
        output = self.render({"backend": {"service": {"port": 9089}}})
        self.assertIn('value: "http://insustain-backend:9089"', output)
        output = self.render({"frontend": {"backendUrl": "http://approved-backend:8080"}})
        self.assertIn('value: "http://approved-backend:8080"', output)

    def test_graphdb_is_optional_and_requires_valid_endpoint(self):
        for url in ("", "not-a-url"):
            self.assertIn("graphdb", self.render(
                {"backend": {"graphdb": {"enabled": True, "url": url}}}, valid=False))
        output = self.render({"backend": {"graphdb": {
            "enabled": True, "url": "http://graphdb.graphdb:7200",
            "repository": "integration-reports", "graph": "urn:integration:reports"}}})
        for name, value in (("GRAPHDB_URL", "http://graphdb.graphdb:7200"),
                            ("GRAPHDB_REPOSITORY", "integration-reports"),
                            ("GRAPHDB_GRAPH", "urn:integration:reports")):
            self.assertIn(f'name: {name}\n              value: "{value}"', output)
        self.assertNotIn("kind: Secret", output)

    def test_ingress_requires_host_and_uses_configured_issuer(self):
        self.assertIn("host", self.render({"ingress": {"enabled": True}}, valid=False))
        output = self.render({"ingress": {"enabled": True, "host": "insustain.example.org",
                                         "tlsSecretName": "insustain-tls", "clusterIssuer": "approved-issuer"}})
        ingress = self.documents(output, "Ingress")[0]
        self.assertIn('cert-manager.io/cluster-issuer: "approved-issuer"', ingress)
        self.assertIn('host: "insustain.example.org"', ingress)
        self.assertIn('secretName: "insustain-tls"', ingress)

    def test_secret_references_are_configurable_without_secret_resources(self):
        output = self.render({"imagePullSecrets": {"name": "ghcr-reader"}, "backend": {"mongo": {
            "usernameSecret": {"name": "mongo-reader", "key": "user"},
            "passwordSecret": {"name": "mongo-reader", "key": "pass"}}}})
        self.assertIn('name: "ghcr-reader"', output)
        self.assertIn('name: "mongo-reader"', output)
        self.assertNotIn("kind: Secret", output)


if __name__ == "__main__":
    unittest.main()
