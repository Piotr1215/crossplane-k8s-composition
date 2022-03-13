# Introduction to Crossplane

How much Kubernetes do developers need to know? Does shift left mean means ever expanding curriculum of tools and frameworks outside of the main focus point; software development?

Architectures of the past, relied on silos and complex process of handofs between development, ops, security and other stakeholders. Modern devops practices encourage us to "shift left", enbrace "you build it your run it" mentality. As the borders between silos became blurred and handoff points are getting increasingly automated, developers are required to learn and know more than every before to fully support the whole lifecycle of a product they are responsible for.

Development teams became multi-disciplinary "mini companies" which can work for a very small projects, but cannot scale to even moderate size. How can we reconcile between developers taking full ownership of the software they create and other concerns like operations, security and compliance still being properly addressed in a standardized way? The answer are Platform Teams responsible for supporting developers by creating standardized and reusable services that make it easy for everyone to be succesfull with their tasks and increasing demands. The emphasis here is on **reusable services** that the Platform Teams provide in form of tools, APIs, products and contracts.

Let's look how Corssplane Kubernetes Provider can help developers use just enough Kubernetes to be fully in control of their software and build on company standards in the same time.

## Kubernetes Simplified

Production grade Kubernetes resources are often complex chunks of YAML with settings related to security, performance, hardware utilization, observability and the list goes on.

And this is just a single deployment resource, there are many more to worry about. Typically, a containerized app running on Kubernetes will require

- deployment
- service
- service account
- roles and cluster roles
- role bindings
- secret
- config map
- network policies
- HPA (horizontal pod autoscaler)

And those are only stateless workflows, for stateful workloads, very often

- volumes
- persistant volume claim
- storage class configuraiton
- stateful sets

And because Kubernetes almost never funcions in isolation, you will need to inclulde multiple CRDs (custom resource definitions) that come along with additonal products like service meshes, observability tech, security scanners and many many more.

Below you can see an example of a deployment with hardened security settings and other best practices.

![Complex deployment](_media/complex-deployment.png)

Here is a list of Kubernetes resources commonly used to describe workloads. The items marked with * are the ones where developers typally have to interact with.

![K8s Resources](_media/k8s-resources.png)

Now imagine that those resources will need to be multiplied by the number of applications/teams/environments and each is likely to have a slight variation to account for differences in the team governance, tech stack, changes velocity etc.

By utilizing [Kubernetes provider](https://github.com/crossplane-contrib/provider-kubernetes), it's possible to control what Kubernetes resources are being created. It also enables complexity hiding for developers not familiar with [Kubernetes Resource Model](https://github.com/Kubernetes/design-proposals-archive/blob/main/architecture/resource-management.md). In the accompanying Katacoda Scenario and Youtube Video we are deploying a Kubernetes application consisting of:

- deployment
- service
- horizontal pod autoscaler

Instead of exposing the resources directly to developers who might be inexperience with Kubernetes, we will create a simple composition containing only important fields, such as:

- namespace to deploy to
- image with tag

> Definition describes API for creating a composite resource whereas composition defines what managed resources will be created when composite resource is created either directly or by a dedicated claim.

Our composition and definition describes what Kubernetes objects we want to create, but how should developers let us know what should be created? Do they need to open a Jira ticket? 😤... Nah, they just need to create a simple claim, like so

```yaml
apiVersion: acmeplatform.com/v1alpha1
kind: AppClaim
metadata:
  name: platform-demo
  labels:
    app-owner: piotrzan
spec:
  id: acmeplatform
  compositionSelector:
    matchLabels:
      type: frontend
  parameters:
    namespace: devops-team
    image: piotrzan/nginx-demo:green
```

By applying the claim, we are creating multiple Kubernetes resources "under the hood" without needing to know what they are and how they are created. This concern can be moved onto a Platform Team.

There are several resources created based on the composition.

We can easily update the image, just by changing the image name in the paramters section of the AppClaim.

Deleting the application and underlying resources is as simple as executing kubectl command or setting up GitOps and pushing the yaml file to a git repo.

The similicity was possible thanks to Crossplane's composition.

## Tools of Choice

By utilizing Kubernetes provider, it's possible to control what Kubernetes resources are being created. It also enables complexity hiding for developers not familiar with [Kubernetes Resource Model](https://github.com/kubernetes/design-proposals-archive/blob/main/architecture/resource-management.md). In this scenario we will deploy a Kubernetes application consisting of:

> For a more overview of Crossplane, check out this [short presentation](https://slides.com/decoder/crossplane) and very comprehensive [Crossplane Docs](https://crossplane.io/docs/v1.6/)
> as well as my recent blogs, especially [Infrastructure as Code: the next big shift is here](https://itnext.io/infrastructure-as-code-the-next-big-shift-is-here-9215f0bda7ce)

Below diagram explains Crossplane's components and their relations.

![crossplane-components](http://www.plantuml.com/plantuml/proxy?cache=yes&src=https://raw.githubusercontent.com/Piotr1215/crossplane-demo/master/diagrams/crossplane-components.puml&fmt=png)

What makes Crossplane so special? First, it builds on Kubernetes and capitalizes on the fact that the real power of Kubernetes is its powerful API model and control plane logic (control loops). It also moves away from Infrastructure as Code to Infrastructure as Data. The difference is that IaC means writing code to describe how the provisioning should happen, whereas IaD means writing pure data files (in the case of Kubernetes YAML) and submitting them to the control component (in the case of Kubernetes an operator) to encapsulate and execute the provisioning logic.

The best part about Crossplane is that it seamlessly enables collaboration between Application Teams and Platform Teams, by leveraging [Kubernetes Control](https://containerjournal.com/kubeconcnc/kubernetes-true-superpower-is-its-control-plane/) Plane as the convergence point where everyone meets.

Crossplane Kubernetes Provider helps us **shift left** without overloading developers with complex operational concerns. Our goal is to help developers and application teams to focus on reliably and quickly deliver features and fix bugs etc. In the same time, there are security and operational concerns that must be addressed. Those concerns will differ from team to team, from project to project.

DevOps means lowering friction between developers and other functions. It became clear that communication between different stakeholders is the key to efficient collaboration. However, it is very hard to capture the essence of every discussion with all the neuances and extrapolate it as a pattern to other teams. The tooling was simply not there. This changes with Crossplane and the workflow and philosophy it proposes. Now it's possible to capture the nuances and complexity of every scenario and provide a solution where custom and standard parts are well balanced without falling into the trap of the "lowest common denominator".

> Crossplane workflow and philosophy helps us capture and codify necesarry customizations and manage them over time. Now after a meeting between developers and platform team, instead of sending email or meeting notes, we can create a composition that codifies the decisions from a meeting in the form of a contract between developers (claim) and platform team (compositions).

## The Power of Composition

The magic of crossplane really happens in the [composition](https://crossplane.io/docs/v1.6/reference/composition.html). There are 3 main tasks that composition performs

- compose together set of managed resources based on a claim or composed resource
- reference credentials needed for accessing the provider API
- patch/map from values provided in a claim to values in managed resource

Below you can see how composition creates deployment, service and horizontal pod autoscaler in response to creating the AppClaim. The "binding glue" between the composition and actual Kubernetes resource is a composite resource definition (XRD) which you can think of as a kind of API between the developer consuming resources via claim and platform engineer or SRE desgning the composition for underlying resources or infrastructure.

Here are 2 key fields that make the composition so powerful.

### forProvider

Specifies kubernetes resources and settings to be created. In this case we can see how the composition adds livenessProbe and readinessProbe as well as resource limits which might be defined by the Platform Team and thus not exposed to Application Development Teams.

### Patches

Enables mapping between fields provided in the definition (XRD) and fields in the Managed Resource (MR).

> The blow YAMl is abbreviated and the complexity of those files can be substantial. This is by design, there is no magic "remove complexity" button. Instead Crossplane provides facilities for moving the complexity onto the Platfrom Teams and designing simple, custom APIs for other teams.

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
...
spec:
  compositeTypeRef:
    apiVersion: acmeplatform.com/v1alpha1
    kind: App
...
  - name: deployment
    base:
      apiVersion: kubernetes.crossplane.io/v1alpha1
      kind: Object
      spec:
        forProvider:
          manifest:
            apiVersion: apps/v1
            kind: Deployment
            spec:
              template:
                spec:
                  containers:
                  - name: frontend
                    ports:
                    - containerPort: 80
                    livenessProbe:
                      httpGet:
                        path: /
                        port: 80
                    readinessProbe:
                      httpGet:
                        path: /
                        port: 80
                    resources:
                      limits:
                        cpu: 250m
                        memory: 256Mi
                      requests:
                        cpu: 125m
                        memory: 128Mi
    patches:
    - fromFieldPath: spec.id
      toFieldPath: metadata.name
      transforms:
        - type: string
          string:
            fmt: "%s-deployment"
...
  - name: service
    base:
      apiVersion: kubernetes.crossplane.io/v1alpha1
      kind: Object
      spec:
        forProvider:
          manifest:
            apiVersion: v1
            kind: Service
            spec:
              type: ClusterIP
              ports:
              - port: 80
                targetPort: 80
                protocol: TCP
                name: http
    patches:
    - fromFieldPath: spec.id
      toFieldPath: metadata.name
      transforms:
        - type: string
          string:
            fmt: "%s-service"
...
  - name: hpa
    base:
      apiVersion: kubernetes.crossplane.io/v1alpha1
      kind: Object
      spec:
        forProvider:
          manifest:
            apiVersion: autoscaling/v1
            kind: HorizontalPodAutoscaler
            spec:
              minReplicas: 2
              maxReplicas: 6
              scaleTargetRef:
                apiVersion: apps/v1
                kind: Deployment
              targetCPUUtilizationPercentage: 80
    patches:
    - fromFieldPath: spec.id
      toFieldPath: metadata.name
      transforms:
        - type: string
          string:
            fmt: "%s-ingress"
    readinessChecks:
      - type: None
```

## Key Takeways

The power of Crossplane is the ability to compose infrastructure including adjacent services and even applications and expose simple interafce to the consumer while gracefuly handling the complexity behind the scenes.

- Composable Infrastructure
- Self-Service
- Increased Automation
- Standardized collaboration
- Ubiquitous language (K8s API)
- Kubernetes provider can be a more powerull alternative to helm

## Try it yourself

Now that you have learned and experimented with basic Crossplane concepts, head over to [Upbound Cloud](https://www.upbound.io/) where you can create a free account and experiment with provisioning cloud infrastructure yourself!

## Additional Resources

- explore additional providers, such as [helm provider](https://github.com/crossplane-contrib/provider-helm)
- browse [Upbound Registry](https://cloud.upbound.io/browse) where you can discover and try out new providers and advanced compositions
- if you are familiar with terraform, you will [Crossplane vs Terraform](https://blog.crossplane.io/crossplane-vs-terraform/) comparison by Nic Cope very useful
- find out what is the [True Kubernetes Superpower](https://containerjournal.com/kubeconcnc/kubernetes-true-superpower-is-its-control-plane/)
- check out why I believe that Crossplane is [The Next Big Shift](https://itnext.io/infrastructure-as-code-the-next-big-shift-is-here-9215f0bda7ce) in IaC

## Open Community

The open source community around Crossplane is very welcoming and helpful, so if you have any questions regarding Crossplane, join the [slack channel](https://slack.crossplane.io/) and say 👋

