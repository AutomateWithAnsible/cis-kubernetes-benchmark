#
# Copyright 2017, Schuberg Philis B.V.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# author: Kristian Vlaardingerbroek

title '1.1 Master Node: API Server'

only_if do
  processes('kube-apiserver').exists?
end

control 'cis-kubernetes-benchmark-1.1.1' do
  title 'Ensure that the --allow-privileged argument is set to false (Scored)'
  desc 'Do not allow privileged containers.'
  impact 1.0

  tag rationale: "The privileged container has all the system capabilities, and
  it also lifts all the limitations enforced by the device cgroup controller. In
  other words, the container can then do almost everything that the host can do.
  This flag exists to allow special use-cases, like running Docker within Docker
  and hence should be avoided for production workloads."

  tag check: "Run the following command on the master node:

  `$ ps -ef | grep kube-apiserver`

  Verify that the `--allow-privileged` argument is set to `false`."

  tag fix: "Edit the `/etc/kubernetes/config` file on the master node and set the
  `KUBE_ALLOW_PRIV` parameter to \"--allow-privileged=false\":

  `KUBE_ALLOW_PRIV=\"--allow-privileged=false\"`

  Based on your system, restart the `kube-apiserver` service.

  For example: `systemctl restart kube-apiserver.service`"

  tag cis_family: ['5', '6.1']
  tag cis_rid: "1.1.1"
  tag cis_level: 1
  tag nist: ['AC-6', '4']
  # @todo verify/add sub-family NIST mapping

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'security-context', url: 'https://kubernetes.io/docs/user-guide/security-context/'

  # @FIXME refactor: we have found that using ruby commands in the describe statment can cause issues
  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--allow-privileged=false/) }
  end
  # @todo add a check to validate the config file as well
end

control 'cis-kubernetes-benchmark-1.1.2' do
  title 'Ensure that the --anonymous-auth argument is set to false (Scored)'
  desc "Disable anonymous requests to the API server."
  impact 1.0

  tag rationale: "When enabled, requests that are not rejected by other configured authentication methods are treated as anonymous requests. These requests are then served by the API server. You should rely on authentication to authorize access and disallow anonymous requests."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--anonymous-auth argument` is set to `false`."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_API_ARGS` parameter to `\"--anonymous-auth=false\":`

  `KUBE_API_ARGS=\"--anonymous-auth=false\"`

  Based on your system, restart the `kube-apiserver` service. For example,

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['14', '6.1']
  tag cis_rid: "1.1.2"
  tag cis_level: 1
  tag nist: ['AC-6', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'anonymous-requests', url: 'https://kubernetes.io/docs/admin/authentication/#anonymous-requests'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--anonymous-auth=false/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.3' do
  title 'Ensure that the --basic-auth-file argument is not set (Scored)'
  desc "Do not use basic authentication."
  impact 1.0

  tag rationale: "Basic authentication uses plaintext credentials for authentication. Currently, the basic authentication credentials last indefinitely, and the password cannot be changed without restarting API server. The basic authentication is currently supported for convenience. Hence, basic authentication should not be used."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--basic-auth-file` argument does not exist."

  tag fix: "Follow the documentation and configure alternate mechanisms for authentication. Then, edit the `/etc/kubernetes/apiserver` file on the master node and remove the `\"--basic- auth-file=<filename>\"` argument from the `KUBE_API_ARGS` parameter.

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['16.14', '6.1']
  tag cis_rid: "1.1.3"
  tag cis_level: 1
  tag nist: ['AC-2(5)', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'static-password-file', url: 'https://kubernetes.io/docs/admin/authentication/#static-password-file'

  describe processes('kube-apiserver').commands.to_s do
    it { should_not match(/--basic-auth-file/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.4' do
  title 'Ensure that the --insecure-allow-any-token argument is not set (Scored)'
  desc "Do not allow any insecure tokens"
  impact 1.0

  tag rationale: "Accepting insecure tokens would allow any token without actually authenticating anything. User information is parsed from the token and connections are allowed."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--insecure-allow-any-token` argument does not exist."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and remove the `--insecure- allow-any-token` argument from the `KUBE_API_ARGS` parameter.

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['16', '6.1']
  tag cis_rid: "1.1.4"
  tag cis_level: 1
  tag nist: ['AC-2', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'

  describe processes('kube-apiserver').commands.to_s do
    it { should_not match(/--insecure-allow-any-token/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.5' do
  title 'Ensure that the --kubelet-https argument is set to true (Scored)'
  desc "Use https for kubelet connections."
  impact 1.0

  tag rationale: "Connections from apiserver to kubelets could potentially carry sensitive data such as secrets and keys. It is thus important to use in-transit encryption for any communication between the apiserver and kubelets."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--kubelet-https` argument either does not exist or is set to `true`."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and remove the `--kubelet- https` argument from the `KUBE_API_ARGS` parameter.

  Based on your system, restart the kube-apiserver service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['14.2', '6.1']
  tag cis_rid: "1.1.5"
  tag cis_level: 1
  tag nist: ['SC-8', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'kubelet-authentication-authorization', url: 'https://kubernetes.io/docs/admin/kubelet-authentication-authorization/'

  describe.one do
    describe processes('kube-apiserver').commands.to_s do
      it { should match(/--kubelet-https=true/) }
    end
    describe processes('kube-apiserver').commands.to_s do
      it { should_not match(/--kubelet-https/) }
    end
  end
end

control 'cis-kubernetes-benchmark-1.1.6' do
  title 'Ensure that the --insecure-bind-address argument is not set (Scored)'
  desc "Do not bind to non-loopback insecure addresses."
  impact 1.0

  tag rationale: "If you bind the apiserver to an insecure address, basically anyone who could connect to it over the insecure port, would have unauthenticated and unencrypted access to your master node. The apiserver doesn't do any authentication checking for insecure binds and neither the insecure traffic is encrypted. Hence, you should not bind the apiserver to an insecure address."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--insecure-bind-address` argument does not exist or is set to 127.0.0.1."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and remove the `--insecure- bind-address` argument from the `KUBE_API_ADDRESS` parameter.

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['9.1', '6.1']
  tag cis_rid: "1.1.6"
  tag cis_level: 1
  tag nist: ['CM-7(1)', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'

  describe.one do
    describe processes('kube-apiserver').commands.to_s do
      it { should match(/--insecure-bind-address=127\.0\.0\.1/) }
    end
    describe processes('kube-apiserver').commands.to_s do
      it { should_not match(/--insecure-bind-address/) }
    end
  end
end

control 'cis-kubernetes-benchmark-1.1.7' do
  title 'Ensure that the --insecure-port argument is set to 0 (Scored)'
  desc "Do not bind to insecure port."
  impact 1.0

  tag rationale: "Setting up the apiserver to serve on an insecure port would allow unauthenticated and unencrypted access to your master node. It is assumed that firewall rules are set up such that this port is not reachable from outside of the cluster. But, as a defense in depth measure, you should not use an insecure port."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--insecure-port` argument is set to `0`."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and set `--insecure-port=0` in the `KUBE_API_PORT` parameter.

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['9.1', '6.1']
  tag cis_rid: "1.1.7"
  tag cis_level: 1
  tag nist: ['CM-7(1)', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--insecure-port=0/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.8' do
  title 'Ensure that the --secure-port argument is not set to 0 (Scored)'
  desc "Do not disable the secure port."
  impact 1.0

  tag rationale: "The secure port is used to serve https with authentication and authorization. If you disable it, no https traffic is served and all traffic is served unencrypted."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--secure-port` argument is either not set or is set to an integer value between 1 and 65535."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and either remove the `--secure-port` argument from the `KUBE_API_ARGS` parameter or set it to a different desired port.

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['14.2', '6.1']
  tag cis_rid: "1.1.8"
  tag cis_level: 1
  tag nist: ['SC-8', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'

  describe.one do
    describe processes('kube-apiserver').commands.to_s do
      it { should match(/--secure-port=([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])/) }
    end
    describe processes('kube-apiserver').commands.to_s do
      it { should_not match(/--secure-port/) }
    end
  end
end

control 'cis-kubernetes-benchmark-1.1.9' do
  title 'Ensure that the --profiling argument is set to false (Scored)'
  desc "Disable profiling, if not needed."
  impact 1.0

  tag rationale: "Profiling allows for the identification of specific performance bottlenecks. It generates a significant amount of program data that could potentially be exploited to uncover system and program details. If you are not experiencing any bottlenecks and do not need the profiler for troubleshooting purposes, it is recommended to turn it off to reduce the potential attack surface."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--profiling` argument is set to `false`."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_API_ARGS` parameter to `\"--profiling=false\"`:

  `KUBE_API_ARGS=\"--profiling=false\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['14', '6.1']
  tag cis_rid: "1.1.9"
  tag cis_level: 1
  tag nist: ['AC-6', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'profiling.md', url: 'https://github.com/kubernetes/community/blob/master/contributors/devel/profiling.md'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--profiling=false/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.10' do
  title 'Ensure that the --repair-malformed-updates argument is set to false (Scored)'
  desc "Disable fixing of malformed updates."
  impact 1.0

  tag rationale: "The apiserver will potentially attempt to fix the update requests to pass the validation even if the requests are malformed. Malformed requests are one of the potential ways to interact with a service without legitimate information. Such requests could potentially be used to sabotage apiserver responses."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--repair-malformed-updates` argument is set to `false`."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_API_ARGS` parameter to `\"--repair-malformed-updates=false\"`:

  `KUBE_API_ARGS=\"--repair-malformed-updates=false\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['14', '6.1']
  tag cis_rid: "1.1.10"
  tag cis_level: 1
  tag nist: ['AC-6', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'Kubernetes issues 15580', url: 'https://github.com/kubernetes/kubernetes/issues/15580'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--repair-malformed-updates=false/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.11' do
  title 'Ensure that the admission control policy is not set to AlwaysAdmit (Scored)'
  desc "Do not allow all requests."
  impact 1.0

  tag rationale: "Setting admission control policy to `AlwaysAdmit` allows all requests and do not filter any requests."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--admission-control` argument is set to a value that does not include `AlwaysAdmit`."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_ADMISSION_CONTROL` parameter to a value that does not include `AlwaysAdmit`.

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['14', '6.1']
  tag cis_rid: "1.1.11"
  tag cis_level: 1
  tag nist: ['AC-6', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'AlwaysAdmit', url: 'https://kubernetes.io/docs/admin/admission-controllers/#alwaysadmit'

  describe processes('kube-apiserver').commands.to_s do
    it { should_not match(/--admission-control=(?:.)*AlwaysAdmit,*(?:.)*/) }
    it { should match(/--admission-control=/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.12' do
  title 'Ensure that the admission control policy is set to AlwaysPullImages (Scored)'
  desc "Always pull images."
  impact 1.0

  tag rationale: "Setting admission control policy to `AlwaysPullImages` forces every new pod to pull the required images every time. In a multitenant cluster users can be assured that their private images can only be used by those who have the credentials to pull them. Without this admisssion control policy, once an image has been pulled to a node, any pod from any user can use it simply by knowing the image’s name, without any authorization check against the image ownership. When this plug-in is enabled, images are always pulled prior to starting containers, which means valid credentials are required."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--admission-control` argument is set to a value that includes `AlwaysPullImages`."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_ADMISSION_CONTROL` parameter to `\"--admission- control=...,AlwaysPullImages,...\"`:

  `KUBE_ADMISSION_CONTROL=\"--admission-control=...,AlwaysPullImages,...\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['14.4', '6.1']
  tag cis_rid: "1.1.12"
  tag cis_level: 1
  tag nist: ['AC-3(3)', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'AlwaysPullImages', url: 'https://kubernetes.io/docs/admin/admission-controllers/#alwayspullimages'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--admission-control=(?:.)*AlwaysPullImages,*(?:.)*/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.13' do
  title 'Ensure that the admission control policy is set to DenyEscalatingExec (Scored)'
  desc "Deny execution of `exec` and `attach` commands in privileged pods."
  impact 1.0

  tag rationale: "Setting admission control policy to `DenyEscalatingExec` denies `exec` and `attach` commands to pods that run with escalated privileges that allow host access. This includes pods that run as privileged, have access to the host IPC namespace, and have access to the host PID namespace."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--admission-control` argument is set to a value that includes `DenyEscalatingExec`."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_ADMISSION_CONTROL` parameter to `\"--admission- control=...,DenyEscalatingExec,...\"`:

  `KUBE_ADMISSION_CONTROL=\"--admission-control=...,DenyEscalatingExec,...\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['14', '6.1']
  tag cis_rid: "1.1.13"
  tag cis_level: 1
  tag nist: ['AC-6', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'DenyEscalatingExec', url: 'https://kubernetes.io/docs/admin/admission-controllers/#denyescalatingexec'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--admission-control=(?:.)*DenyEscalatingExec,*(?:.)*/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.14' do
  title 'Ensure that the admission control policy is set to SecurityContextDeny (Scored)'
  desc "Restrict pod level SecurityContext customization. Instead of using a customized SecurityContext for your pods, use a Pod Security Policy (PSP), which is a cluster-level resource that controls the actions that a pod can perform and what it has the ability to access."
  impact 1.0

  tag rationale: "Setting admission control policy to `SecurityContextDeny` denies the pod level SecurityContext customization. Any attempts to customize the SecurityContexts that are not explicitly defined in the Pod Security Policy (PSP) are blocked. This ensures that all the pods adhere to the PSP defined by your organization and you have a uniform pod level security posture."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--admission-control` argument is set to a value that includes `SecurityContextDeny`."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_ADMISSION_CONTROL` parameter to `\"--admission- control=...,SecurityContextDeny,...\"`:

  `KUBE_ADMISSION_CONTROL=\"--admission-control=...,SecurityContextDeny,...\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['5.1', '6.1']
  tag cis_rid: "1.1.14"
  tag cis_level: 1
  tag nist: ['AC-6(9)', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'SecurityContextDeny', url: 'https://kubernetes.io/docs/admin/admission-controllers/#securitycontextdeny'
  ref 'Working with rbac', url: 'https://kubernetes.io/docs/user-guide/pod-security-policy/#working-with-rbac'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--admission-control=(?:.)*SecurityContextDeny,*(?:.)*/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.15' do
  title 'Ensure that the admission control policy is set to NamespaceLifecycle (Scored)'
  desc "Reject creating objects in a namespace that is undergoing termination."
  impact 1.0

  tag rationale: "Setting admission control policy to `NamespaceLifecycle` ensures that objects cannot be created in non-existent namespaces, and that namespaces undergoing termination are not used for creating the new objects. This is recommended to enforce the integrity of the namespace termination process and also for the availability of the newer objects."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--admission-control` argument is set to a value that includes `NamespaceLifecycle`."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_ADMISSION_CONTROL` parameter to `\"--admission- control=NamespaceLifecycle,...\"`:

  `KUBE_ADMISSION_CONTROL=\"--admission-control=NamespaceLifecycle,...\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['14', '6.1']
  tag cis_rid: "1.1.15"
  tag cis_level: 1
  tag nist: ['AC-6', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'NamespaceLifecycle', url: 'https://kubernetes.io/docs/admin/admission-controllers/#namespacelifecycle'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--admission-control=(?:.)*NamespaceLifecycle,*(?:.)*/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.16' do
  title 'Ensure that the --audit-log-path argument is set as appropriate (Scored)'
  desc "Enable auditing on kubernetes apiserver and set the desired audit log path as appropriate."
  impact 1.0

  tag rationale: "Auditing Kubernetes apiserver provides a security-relevant chronological set of records documenting the sequence of activities that have affected system by individual users, administrators or other components of the system. Even though currently, Kubernetes provides only basic audit capabilities, it should be enabled. You can enable it by setting an appropriate audit log path."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--audit-log-path` argument is set as appropriate."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_API_ARGS` parameter to `\"--audit-log-path=<filename>\"`:

  `KUBE_API_ARGS=\"--audit-log-path=/var/log/apiserver/audit.log\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['6.2', '6.1']
  tag cis_rid: "1.1.16"
  tag cis_level: 1
  tag nist: ['AU-3', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'cluster-administration', url: 'https://kubernetes.io/docs/concepts/cluster-administration/audit/'
  ref 'Kubernetes issues 22', url: 'https://github.com/kubernetes/features/issues/22'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--audit-log-path=/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.17' do
  title 'Ensure that the --audit-log-maxage argument is set to 30 or as appropriate (Scored)'
  desc "Retain the logs for at least 30 days or as appropriate."
  impact 1.0

  tag rationale: "Retaining logs for at least 30 days ensures that you can go back in time and investigate or correlate any events. Set your audit log retention period to 30 days or as per your business requirements."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--audit-log-maxage` argument is set to `30` or as appropriate."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_API_ARGS` parameter to `\"--audit-log-maxage=30\"`:

  `KUBE_API_ARGS=\"--audit-log-maxage=30\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['6.3', '6.1']
  tag cis_rid: "1.1.17"
  tag cis_level: 1
  tag nist: ['AU-4', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'cluster-administration', url: 'https://kubernetes.io/docs/concepts/cluster-administration/audit/'
  ref 'Kubernetes issues 22', url: 'https://github.com/kubernetes/features/issues/22'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--audit-log-maxage=/) }
  end

  audit_log_maxage = processes('kube-apiserver').commands.to_s.scan(/--audit-log-maxage=(\d+)/)

  unless audit_log_maxage.empty?
    describe audit_log_maxage.last.first.to_i do
      it { should cmp >= 30 }
    end
  end
end

control 'cis-kubernetes-benchmark-1.1.18' do
  title 'Ensure that the --audit-log-maxbackup argument is set to 10 or as appropriate (Scored)'
  desc "Retain 10 or an appropriate number of old log files."
  impact 1.0

  tag rationale: "Kubernetes automatically rotates the log files. Retaining old log files ensures that you would have sufficient log data available for carrying out any investigation or correlation. For example, if you have set file size of 100 MB and the number of old log files to keep as 10, you would approximate have 1 GB of log data that you could potentially use for your analysis."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--audit-log-maxbackup` argument is set to `10` or as appropriate."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_API_ARGS` parameter to `\"--audit-log-maxbackup=10\"`:

  `KUBE_API_ARGS=\"--audit-log-maxbackup=10\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['6.3', '6.1']
  tag cis_rid: "1.1.18"
  tag cis_level: 1
  tag nist: ['AU-4', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'cluster-administration', url: 'https://kubernetes.io/docs/concepts/cluster-administration/audit/'
  ref 'Kubernetes issues 22', url: 'https://github.com/kubernetes/features/issues/22'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--audit-log-maxbackup=/) }
  end

  audit_log_maxbackup = processes('kube-apiserver').commands.to_s.scan(/--audit-log-maxbackup=(\d+)/)

  unless audit_log_maxbackup.empty?
    describe audit_log_maxbackup.last.first.to_i do
      it { should cmp >= 10 }
    end
  end
end

control 'cis-kubernetes-benchmark-1.1.19' do
  title 'Ensure that the --audit-log-maxsize argument is set to 100 or as appropriate (Scored)'
  desc "Rotate log files on reaching 100 MB or as appropriate."
  impact 1.0

  tag rationale: "Kubernetes automatically rotates the log files. Retaining old log files ensures that you would have sufficient log data available for carrying out any investigation or correlation. If you have set file size of 100 MB and the number of old log files to keep as 10, you would approximate have 1 GB of log data that you could potentially use for your analysis."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--audit-log-maxsize` argument is set to `100` or as appropriate."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_API_ARGS` parameter to `\"--audit-log-maxsize=100\"`:

  `KUBE_API_ARGS=\"--audit-log-maxsize=100\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['6.3', '6.1']
  tag cis_rid: "1.1.19"
  tag cis_level: 1
  tag nist: ['AU-4', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'cluster-administration', url: 'https://kubernetes.io/docs/concepts/cluster-administration/audit/'
  ref 'Kubernetes issues 22', url: 'https://github.com/kubernetes/features/issues/22'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--audit-log-maxsize=/) }
  end

  audit_log_maxsize = processes('kube-apiserver').commands.to_s.scan(/--audit-log-maxsize=(\d+)/)

  unless audit_log_maxsize.empty?
    describe audit_log_maxsize.last.first.to_i do
      it { should cmp >= 100 }
    end
  end
end

control 'cis-kubernetes-benchmark-1.1.20' do
  title 'Ensure that the --authorization-mode argument is not set to AlwaysAllow (Scored)'
  desc "Do not always authorize all requests."
  impact 1.0

  tag rationale: "The apiserver, by default, allows all requests. You should restrict this behavior to only allow the authorization modes that you explicitly use in your environment. For example, if you don't use REST APIs in your environment, it is a good security best practice to switch off that capability."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--authorization-mode` argument exists and is not set to `AlwaysAllow`."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_API_ARGS` parameter to values other than `--authorization-mode=AlwaysAllow`. One such example could be as below:

  `KUBE_API_ARGS=\"--authorization-mode=RBAC\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['9.1', '6.1']
  tag cis_rid: "1.1.20"
  tag cis_level: 1
  tag nist: ['CM-7(1)', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'authorization', url: 'https://kubernetes.io/docs/admin/authorization/'

  describe processes('kube-apiserver').commands.to_s do
    it { should_not match(/--authorization-mode=(?:.)*AlwaysAllow,*(?:.)*/) }
    it { should match(/--authorization-mode=/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.21' do
  title 'Ensure that the --token-auth-file parameter is not set (Scored)'
  desc "Do not use token based authentication."
  impact 1.0

  tag rationale: "The token-based authentication utilizes static tokens to authenticate requests to the apiserver. The tokens are stored in clear-text in a file on the apiserver, and cannot be revoked or rotated without restarting the apiserver. Hence, do not use static token-based authentication."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--token-auth-file` argument does not exist."

  tag fix: "Follow the documentation and configure alternate mechanisms for authentication. Then, edit the `/etc/kubernetes/apiserver` file on the master node and remove the `\"--token- auth-file=<filename>\"` argument from the `KUBE_API_ARGS` parameter.

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['16.14', '6.1']
  tag cis_rid: "1.1.21"
  tag cis_level: 1
  tag nist: ['AC-2(5)', '4']

  ref 'static-token-file', url: 'https://kubernetes.io/docs/admin/authentication/#static-token-file'
  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'

  describe processes('kube-apiserver').commands.to_s do
    it { should_not match(/--token-auth-file/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.22' do
  title 'Ensure that the --kubelet-certificate-authority argument is set as appropriate (Scored)'
  desc "Verify kubelet's certificate before establishing connection."
  impact 1.0

  tag rationale: "The connections from the apiserver to the kubelet are used for fetching logs for pods, attaching (through kubectl) to running pods, and using the kubelet’s port-forwarding functionality. These connections terminate at the kubelet’s HTTPS endpoint. By default, the apiserver does not verify the kubelet’s serving certificate, which makes the connection subject to man-in-the-middle attacks, and unsafe to run over untrusted and/or public networks."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--kubelet-certificate-authority` argument exists and is set as appropriate."

  tag fix: "Follow the Kubernetes documentation and setup the TLS connection between the apiserver and kubelets. Then, edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_API_ARGS` parameter to `\"--kubelet-certificate-authority=<ca-string>\"`:

  `KUBE_API_ARGS=\"--kubelet-certificate-authority=<ca-string>\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['3.4', '6.1']
  tag cis_rid: "1.1.22"
  tag cis_level: 1
  tag nist: ['SC-2', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'kubelet-authentication-authorization', url: 'https://kubernetes.io/docs/admin/kubelet-authentication-authorization/'
  ref 'apiserver---kubelet', url: 'https://kubernetes.io/docs/concepts/cluster-administration/master-node-communication/#apiserver---kubelet'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--kubelet-certificate-authority=/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.23' do
  title 'Ensure that the --kubelet-client-certificate and --kubelet-client-key arguments are set as appropriate (Scored)'
  desc "Enable certificate based kubelet authentication."
  impact 1.0

  tag rationale: "The apiserver, by default, does not authenticate itself to the kubelet's HTTPS endpoints. The requests from the apiserver are treated anonymously. You should set up certificate-based kubelet authentication to ensure that the apiserver authenticates itself to kubelets when submitting requests."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--kubelet-client-certificate` and `--kubelet-client-key` arguments exist and they are set as appropriate."

  tag fix: "Follow the Kubernetes documentation and set up the TLS connection between the apiserver and kubelets. Then, edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_API_ARGS` parameter to `\"--kubelet-client- certificate=<path/to/client-certificate-file>\"` and `\"--kubelet-client- key=<path/to/client-key-file>\"`:

  `KUBE_API_ARGS=\"--kubelet-client-certificate=<path/to/client-certificate-file> --kubelet-client-key=<path/to/client-key-file>\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['3.4', '6.1']
  tag cis_rid: "1.1.23"
  tag cis_level: 1
  tag nist: ['SC-2', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'kubelet-authentication-authorization', url: 'https://kubernetes.io/docs/admin/kubelet-authentication-authorization/'
  ref 'apiserver---kubelet', url: 'https://kubernetes.io/docs/concepts/cluster-administration/master-node-communication/#apiserver---kubelet'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--kubelet-client-certificate=/) }
    it { should match(/--kubelet-client-key=/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.24' do
  title 'Ensure that the --service-account-lookup argument is set to true (Scored)'
  desc "Validate service account before validating token."
  impact 1.0

  tag rationale: "By default, the apiserver only verifies that the authentication token is valid. However, it does not validate that the service account token mentioned in the request is actually present in etcd. This allows using a service account token even after the corresponding service account is deleted. This is an example of time of check to time of use security issue."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--service-account-lookup` argument exists and is set to `true`."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_API_ARGS` parameter to `\"--service-account-lookup=true\"`:

  `KUBE_API_ARGS=\"--service-account-lookup=true\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['16', '6.1']
  tag cis_rid: "1.1.24"
  tag cis_level: 1
  tag nist: ['AC-2', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'Kubernetes issues 24167', url: 'https://github.com/kubernetes/kubernetes/issues/24167'
  ref 'Time_of_check_to_time_of_use', url: 'https://en.wikipedia.org/wiki/Time_of_check_to_time_of_use'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--service-account-lookup=true/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.25' do
  title 'Ensure that the admission control policy is set to PodSecurityPolicy (Scored)'
  desc "Reject creating pods that do not match Pod Security Policies."
  impact 1.0

  tag rationale: "A Pod Security Policy is a cluster-level resource that controls the actions that a pod can perform and what it has the ability to access. The `PodSecurityPolicy` objects define a set of conditions that a pod must run with in order to be accepted into the system. Pod Security Policies are comprised of settings and strategies that control the security features a pod has access to and hence this must be used to control pod access permissions."

  tag check: "Run the following command on the master node:

  'ps -ef | grep kube-apiserver'

  Verify that the `--admission-control` argument is set to a value that includes `PodSecurityPolicy`."

  tag fix: "Follow the documentation and create Pod Security Policy objects as per your environment. Then, edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_ADMISSION_CONTROL` parameter to `\"--admission- control=...,PodSecurityPolicy,...\"`:

  `KUBE_ADMISSION_CONTROL=\"--admission-control=...,PodSecurityPolicy,...\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['14', '6.1']
  tag cis_rid: "1.1.25"
  tag cis_level: 1
  tag nist: ['AC-6', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'PodSecurityPolicy', url: 'https://kubernetes.io/docs/admin/admission-controllers/#podsecuritypolicy'
  ref 'Enabling PodSecurityPolicy', url: 'https://kubernetes.io/docs/concepts/policy/pod-security-policy/#enabling-pod-security-policies'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--admission-control=(?:.)*PodSecurityPolicy,*(?:.)*/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.26' do
  title 'Ensure that the --service-account-key-file argument is set as appropriate (Scored)'
  desc "Explicitly set a service account public key file for service accounts on the apiserver."
  impact 1.0

  tag rationale: "By default, if no `--service-account-key-file` is specified to the apiserver, it uses the private key from the TLS serving certificate to verify service account tokens. To ensure that the keys for service account tokens could be rotated as needed, a separate public/private key pair should be used for signing service account tokens. Hence, the public key should be specified to the apiserver with `--service-account-key-file`."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--service-account-key-file` argument exists and is set as appropriate."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_API_ARGS` parameter to `\"--service-account-key-file=<filename>\"`:

  `KUBE_API_ARGS=\"--service-account-key-file=<filename>\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['3', '6.1']
  tag cis_rid: "1.1.26"
  tag cis_level: 1
  tag nist: ['CM-6', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'Kubernetes issues 24167', url: 'https://github.com/kubernetes/kubernetes/issues/24167'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--service-account-key-file=/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.27' do
  title 'Ensure that the --etcd-certfile and --etcd-keyfile arguments are set as appropriate (Scored)'
  desc "etcd should be configured to make use of TLS encryption for client connections."
  impact 1.0

  tag rationale: "etcd is a highly-available key value store used by Kubernetes deployments for persistent storage of all of its REST API objects. These objects are sensitive in nature and should be protected by client authentication. This requires the API server to identify itself to the etcd server using a client certificate and key."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--etcd-certfile` and `--etcd-keyfile` arguments exist and they are set as appropriate."

  tag fix: "Follow the Kubernetes documentation and set up the TLS connection between the apiserver and etcd. Then, edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_API_ARGS` parameter to include `\"--etcd-certfile=<path/to/client- certificate-file>\"` and `\"--etcd-keyfile=<path/to/client-key-file>\"`:

  `KUBE_API_ARGS=\"... --etcd-certfile=<path/to/client-certificate-file> --etcd- keyfile=<path/to/client-key-file> ...\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['9', '6.1']
  tag cis_rid: "1.1.27"
  tag cis_level: 1
  tag nist: ['SC-7', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'security.html', url: 'https://coreos.com/etcd/docs/latest/op-guide/security.html'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--etcd-certfile=/) }
    it { should match(/--etcd-keyfile=/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.28' do
  title 'Ensure that the admission control policy is set to ServiceAccount (Scored)'
  desc "Automate service accounts management."
  impact 1.0

  tag rationale: "When you create a pod, if you do not specify a service account, it is automatically assigned the `default` service account in the same namespace. You should create your own service account and let the API server manage its security tokens."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--admission-control` argument is set to a value that includes `ServiceAccount`."

  tag fix: "Follow the documentation and create ServiceAccount objects as per your environment. Then, edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_ADMISSION_CONTROL` parameter to `\"--admission- control=...,ServiceAccount,...\"`:

  `KUBE_ADMISSION_CONTROL=\"--admission-control=...,ServiceAccount,...\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['16', '6.1']
  tag cis_rid: "1.1.28"
  tag cis_level: 1
  tag nist: ['AC-2', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'ServiceAccount', url: 'https://kubernetes.io/docs/admin/admission-controllers/#serviceaccount'
  ref 'Configure-Service-Account', url: 'https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--admission-control=(?:.)*ServiceAccount,*(?:.)*/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.29' do
  title 'Ensure that the --tls-cert-file and --tls-private-key-file arguments are set as appropriate (Scored)'
  desc "Setup TLS connection on the API server."
  impact 1.0

  tag rationale: "API server communication contains sensitive parameters that should remain encrypted in transit. Configure the API server to serve only HTTPS traffic."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--tls-cert-file` and `--tls-private-key-file` arguments exist and they are set as appropriate."

  tag fix: "Follow the Kubernetes documentation and set up the TLS connection on the apiserver. Then, edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_API_ARGS` parameter to include `\"--tls-cert-file=<path/to/tls-certificate- file>\"` and `\"--tls-private-key-file=<path/to/tls-key-file>\"`:

  `KUBE_API_ARGS=\"--tls-cert-file=<path/to/tls-certificate-file> --tls-private- key-file=<path/to/tls-key-file>\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['14.2', '6.1']
  tag cis_rid: "1.1.29"
  tag cis_level: 1
  tag nist: ['SC-8', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'securing-the-kubernetes-api', url: 'http://rootsquash.com/2016/05/10/securing-the-kubernetes-api/'
  ref 'docker-kubernetes-tls-guide', url: 'https://github.com/kelseyhightower/docker-kubernetes-tls-guide'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--tls-cert-file=/) }
    it { should match(/--tls-private-key-file=/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.30' do
  title 'Ensure that the --client-ca-file argument is set as appropriate (Scored)'
  desc "Setup TLS connection on the API server."
  impact 1.0

  tag rationale: "API server communication contains sensitive parameters that should remain encrypted in transit. Configure the API server to serve only HTTPS traffic. If `--client-ca-file` argument is set, any request presenting a client certificate signed by one of the authorities in the `client-ca-file` is authenticated with an identity corresponding to the CommonName of the client certificate."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--client-ca-file` argument exists and it is set as appropriate."

  tag fix: "Follow the Kubernetes documentation and set up the TLS connection on the apiserver. Then, edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_API_ARGS` parameter to include `\"--client-ca-file=<path/to/client-ca-file>\"`:

  `KUBE_API_ARGS=\"--client-ca-file=<path/to/client-ca-file>\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['14.2', '6.1']
  tag cis_rid: "1.1.30"
  tag cis_level: 1
  tag nist: ['SC-8', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'securing-the-kubernetes-api', url: 'http://rootsquash.com/2016/05/10/securing-the-kubernetes-api/'
  ref 'docker-kubernetes-tls-guide', url: 'https://github.com/kelseyhightower/docker-kubernetes-tls-guide'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--client-ca-file=/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.31' do
  title 'Ensure that the --etcd-cafile argument is set as appropriate (Scored)'
  desc "etcd should be configured to make use of TLS encryption for client connections."
  impact 1.0

  tag rationale: "etcd is a highly-available key value store used by Kubernetes deployments for persistent storage of all of its REST API objects. These objects are sensitive in nature and should be protected by client authentication. This requires the API server to identify itself to the etcd server using a SSL Certificate Authority file."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--etcd-cafile` argument exists and it is set as appropriate."

  tag fix: "Follow the Kubernetes documentation and set up the TLS connection between the apiserver and etcd. Then, edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_API_ARGS` parameter to include `\"--etcd-cafile=<path/to/ca-file>\"`:

  `KUBE_API_ARGS=\"--etcd-cafile=<path/to/ca-file>\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['14.2', '6.1']
  tag cis_rid: "1.1.31"
  tag cis_level: 1
  tag nist: ['SC-8', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'security.html', url: 'https://coreos.com/etcd/docs/latest/op-guide/security.html'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--etcd-cafile/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.32' do
  title 'Ensure that the --authorization-mode argument is set to Node (Scored)'
  desc "Restrict kubelet nodes to reading only objects associated with them."
  impact 1.0

  tag rationale: "The Node authorization mode only allows kubelets to read Secret, ConfigMap, PersistentVolume, and PersistentVolumeClaim objects associated with their nodes."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--authorization-mode` argument exists and is set to a value to include `Node`."

  tag fix: "Edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_API_ARGS` parameter to a value to include `--authorization-mode=Node`. One such example could be as below:

  `KUBE_API_ARGS=\"--authorization-mode=Node,RBAC\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['9.1', '6.1']
  tag cis_rid: "1.1.32"
  tag cis_level: 1
  tag nist: ['CM-7(1)', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'node', url: 'https://kubernetes.io/docs/admin/authorization/node/'
  ref 'kubernetes pull 46076', url: 'https://github.com/kubernetes/kubernetes/pull/46076'
  ref 'kube17-security', url: 'https://acotten.com/post/kube17-security'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--authorization-mode=(?:.)*Node,*(?:.)*/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.33' do
  title 'Ensure that the admission control policy is set to NodeRestriction (Scored)'
  desc "Limit the Node and Pod objects that a kubelet could modify."
  impact 1.0

  tag rationale: "Using the NodeRestriction plug-in ensures that the kubelet is restricted to the Node and Pod objects that it could modify as defined. Such kubelets will only be allowed to modify their own Node API object, and only modify Pod API objects that are bound to their node."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--admission-control` argument is set to a value that includes `NodeRestriction`."

  tag fix: "Follow the Kubernetes documentation and configure `NodeRestriction` plug-in on kubelets. Then, edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_ADMISSION_CONTROL` parameter to `\"--admission- control=...,NodeRestriction,...\"`:

  `KUBE_ADMISSION_CONTROL=\"--admission-control=...,NodeRestriction,...\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['14', '6.1']
  tag cis_rid: "1.1.33"
  tag cis_level: 1
  tag nist: ['AC-6', '4']

  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'NodeRestriction', url: 'https://kubernetes.io/docs/admin/admission-controllers/#noderestriction'
  ref 'node', url: 'https://kubernetes.io/docs/admin/authorization/node/'
  ref 'kube17-security', url: 'https://acotten.com/post/kube17-security'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--admission-control=(?:.)*NodeRestriction,*(?:.)*/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.34' do
  title 'Ensure that the --experimental-encryption-provider-config argument is set as appropriate (Scored)'
  desc "Encrypt etcd key-value store."
  impact 1.0

  tag rationale: "etcd is a highly available key-value store used by Kubernetes deployments for persistent storage of all of its REST API objects. These objects are sensitive in nature and should be encrypted at rest to avoid any disclosures."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Verify that the `--experimental-encryption-provider-config` argument is set to a `EncryptionConfig` file. Additionally, ensure that the `EncryptionConfig` file has all the desired `resources` covered especially any secrets."

  tag fix: "Follow the Kubernetes documentation and configure a `EncryptionConfig` file. Then, edit the `/etc/kubernetes/apiserver` file on the master node and set the `KUBE_API_ARGS` parameter to `\"--experimental-encryption-provider- config=</path/to/EncryptionConfig/File>\"`:

  `KUBE_API_ARGS=\"--experimental-encryption-provider- config=</path/to/EncryptionConfig/File>\"`

  Based on your system, restart the `kube-apiserver` service. For example:

  `systemctl restart kube-apiserver.service`"

  tag cis_family: ['14.5', '6.1']
  tag cis_rid: "1.1.34"
  tag cis_level: 1
  tag nist: ['SC-28', '4']

  ref 'encrypt-data', url: 'https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/'
  ref 'kube17-security', url: 'https://acotten.com/post/kube17-security'
  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'Kubernetes issues 92', url: 'https://github.com/kubernetes/features/issues/92'

  describe processes('kube-apiserver').commands.to_s do
    it { should match(/--experimental-encryption-provider-config=/) }
  end
end

control 'cis-kubernetes-benchmark-1.1.35' do
  title 'Ensure that the encryption provider is set to aescbc (Scored)'
  desc "Use aescbc encryption provider."
  impact 1.0

  tag rationale: "aescbc is currently the strongest encryption provider, It should be preferred over other providers."

  tag check: "Run the following command on the master node:

  `ps -ef | grep kube-apiserver`

  Get the `EncryptionConfig` file set for `--experimental-encryption-provider-config` argument. Verify that the `aescbc` encryption provider is used for all the desired `resources`."

  tag fix: "Follow the Kubernetes documentation and configure a `EncryptionConfig` file. In this file, choose `aescbc` as the encryption provider.

  For example,

  `kind: EncryptionConfig
  apiVersion: v1
  resources:
    - resources:
      - secrets
      providers:
      - aescbc:
        keys:
        - name: key1
          secret: <32-byte base64-encoded secret>`"

  tag cis_family: ['14.5', '6.1']
  tag cis_rid: "1.1.35"
  tag cis_level: 1
  tag nist: ['SC-28', '4']

  ref 'encrypt-data', url: 'https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/'
  ref 'kube17-security', url: 'https://acotten.com/post/kube17-security'
  ref 'kube-apiserver', url: 'https://kubernetes.io/docs/admin/kube-apiserver/'
  ref 'Kubernetes issues 92', url: 'https://github.com/kubernetes/features/issues/92'
  ref 'providers', url: 'https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#providers'

  describe 'cis-kubernetes-benchmark-1.1.35' do
    skip 'Review the `EncryptionConfig` file and verify that `aescbc` is used as the encryption provider.'
  end
end
