# Sub modules for cloud-init

The bulk of the Kubernetes magic is done here, a series of Bicep modules which don't deploy any resources but just prepare a well formatted cloud-init string to be injected into the VMs

Very heavy use of the Bicep `format` and `loadTextContent` functions is used to build up the cloud-init string and dynamically inject deploy-time parameters into the scripts and configuration.

## Scripts and Config Files

All of the scripts, config files and manifests which are loaded to the VMs are contained in the `scripts/` and `other/` sub-folders, you will notice something strange about these files, where all the lines except the first are indented by 6 spaces. This is to workaround an issue with Bicep where there is no way to indent content with either `format` or `loadTextContent`, and the cloud-init is YAML formatted expecting exact indentation.
