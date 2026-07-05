local otel = (import 'vendor/github.com/grafana/jsonnet-libs/opentelemetry-collector-mixin/mixin.libsonnet') + {
  // https://github.com/grafana/jsonnet-libs/blob/master/opentelemetry-collector-mixin/config.libsonnet
  _config+:: {
    labels: {
      cluster: false,
      namespace: false,
      job: true,
    },
    datasourceName: 'datasource',
  },
};
local argocd = (import 'vendor/github.com/grafana/jsonnet-libs/argocd-mixin/mixin.libsonnet');
local k8s = (import 'vendor/github.com/kubernetes-monitoring/kubernetes-mixin/mixin.libsonnet');
// https://github.com/kubernetes-monitoring/kubernetes-mixin/blob/master/config.libsonnet
//   _config+:: {
//     grafanaK8s: {
//       grafanaTimezone: 'browser',
//     },
//     datasourceName: 'default',
//   },
// };

local d = otel + argocd + k8s;

local files = std.objectFields(d.grafanaDashboards);
{
  ['dashboards/' + filename]: d.grafanaDashboards[filename]
  for filename in files
  // 'kustomization.yaml': std.manifestYamlDoc(kustomization, quote_keys=false),
} + {
  'kustomization.yaml': std.manifestYamlDoc({
    apiVersion: 'kustomize.config.k8s.io/v1beta1',
    kind: 'Kustomization',
    configMapGenerator: [
      {
        name: std.strReplace(filename, '.json', '-dashboard'),
        files: ['dashboards/' + filename],
        options: {
          disableNameSuffixHash: true,
          labels: {
            grafana_dashboard: '1',
          },
        },
      }
      for filename in files
    ],
  }, quote_keys=false),
}
