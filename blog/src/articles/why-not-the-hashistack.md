> Kubernetes is designed as a collection of more than a half-dozen interoperating services which together provide the full functionality. Kubernetes supports running in a highly available configuration but is operationally complex to setup.

> Nomad is architecturally much simpler. Nomad is a single binary, both for clients and servers, and requires no external services for coordination or storage. By default, Nomad is distributed, highly available, and operationally simple.

As advertised by hashicorp, nomad, seems to be the right choice when you are just a one member team but would like to run an orchestration system for your personal services. However, my personal experience is quite the opposite.

What does it REALLY takes to operate a whole hashistack in order to support the tiny strawberry atop the cake, namely nomad?

First of all, vault, which manages the secrets. To run vault in a highly available fashion, you would either need to provide it with a distributed database (which is another layer of complexity), or use the so called: integrated storage, which, needless to say is based on raft[^1]. Then, you have to prepare an self signed CA[^1] in order to establish the root of trust, not to mention the complexity of unsealing the cluster on every restart manually (without the help of cloud KMS).

The next is consul, that provides service discovery. Consul models the connectivity between nodes into two categories, lan and wan, and each lan is a consul datacenter. Consul datacenters federate over the wan to form a logical cluster. However, data is not replicated across datacenters, it's only stores in respective datacenters (with raft[^2]) and requests destined for other datacenters are simply forwarded (requiring full connecitity across all consul servers). For the clustering part, a gossip protocol is used, formaing a lan gossip ring[^1] per datacenter, and a wan gossip ring[^2] per cluster. In order to encrypt connections between consul servers, we need a PSK[^1] for the gossip protocol, and another CA[^2] for rpc and http api. Although the PSK and the CA can be managed by vault, there is no integration provided, you have to template files out of the secrets, and manage all rotations by yourself. And, if you wanna use the consul connect feature (a.k.a. service mesh), another CA[^3] is required.

Finally, we've got to nomad. Luckily, nomad claims to HAVE consul integration, and can automatically bootstrap itself given a consul cluster is beneath it. You would expect (as I do) that nomad can rely on consul for interconnection and cluster membership, but the reality is a bloody **NO**. The so called integration provides nothing more than saving you typing a seed node for cluster bootstrap, and serves no purpose beyond that. Which means, you still have to run a gossip ring[^3] per nomad region (which is like a consul datacenter) and another gossip ring[^4] for cross region federation. And, nomad also stores its state in per region raft[^3] clusters. To secure nomad clusters, another PSK[^2] and CA[^4] is needed.

Let's recap what we have now, given that we run a single vault cluster and 2 nomad regions, each containing 2 consul datacenters: 2 PSKs, 4 CAs, 7 raft clusters, 8 gossip rings. And all the cluster states are scattered across dozens of services, making the backup and recovery process a pain in the ass.

Before you can cheer for you master degree in hashistack, the aformentioned deployment is by no means secure, you still have to configure all the policies and roles (for each of the components). You say that this is a single tenant cluster and you trust yourself, okay, let's move on.

> Modernize Legacy Applications without Rewrite  
> Bring orchestration benefits to existing services. Achieve zero downtime deployments, improved resilience, higher resource utilization, and more without containerization.

Wow that sounds nice, let me grab a random binary and run it with nomad, free lunch, right?

> The task's chroot is populated by linking or copying the data from the host into the chroot. Note that this can take considerable disk space.

How on earth would anyone design a system like this? With modern filesystems such as btrfs or xfs, we do have reflink that makes the chroot essentially free, but for most people, that means copying the entire rootfs for every single task. Well, that is for enterprise level security, I convince myself.

Then we try the shinny consul connect feature, follow the documents to install cni plugins and seemingly everything is in its place. Submit a demo job: 

```
1 unplaced
Constraint missing drivers filtered 1 node
```

Missing driver, what is that? Digging through the evaluated job definition, we can see that sidecar proxies require docker task runner, with no easy way to override other than rewritting the whole sidecar service definition. You said you were legacy friendly, nomad you liar.

Still, this is not the *end* of the story.

### *To hashistack or not to, that is not even a question*