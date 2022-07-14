# 🧩 Bicep Modules

These are the sub-modules used by each of the top level templates/modules, they are grouped by type and provide simple wrappers around one or two Azure resources with sensible defaults.

None of the Bicep files under this directory are intended to be deployed directly.

## 📃 Module Index

```text
├── communication
│   ├── domain.bicep
│   ├── email.bicep
│   └── service.bicep
├── compute
│   ├── linux-vm.bicep
│   └── linux-vmss.bicep
├── containers
│   ├── app-env.bicep
│   ├── app.bicep
│   ├── certificate.bicep
│   ├── instance.bicep
│   └── registry.bicep
├── dns
│   ├── a-record.bicep
│   ├── cname-record.bicep
│   └── txt-record.bicep
├── identity
│   ├── role-assign-rg.bicep
│   ├── role-assign-sub.bicep
│   └── user-managed.bicep
├── kubernetes
│   └── aks.bicep
├── misc
│   ├── keyvault.bicep
│   └── maps.bicep
├── monitoring
│   ├── app-insights.bicep
│   └── log-analytics.bicep
├── network
│   ├── app-gateway.bicep
│   ├── load-balancer.bicep
│   ├── nat-gateway.bicep
│   ├── network-multi.bicep
│   ├── network.bicep
│   ├── nsg.bicep
│   ├── public-ip.bicep
│   └── subnet.bicep
├── storage
│   └── account.bicep
└── web
    ├── function-app-container.bicep
    ├── svc-plan-linux.bicep
    └── webapp-container.bicep
```