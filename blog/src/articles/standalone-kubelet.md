&nbsp; &nbsp; &nbsp; &nbsp;如果需要运行单一的容器，毫无疑问the plain old docker run！如果需要运行大量互相依赖的容器，docker-compose似乎也是一个不错的选择，但是在最近我的基础设施迁移过程中，我也发现了docker-compose所带有的众多局限，特别是在security context或是如init container这种方面。之前就发现了podman具有play kube这一子命令，可以直接运行PodSpec，我也对此进行了一番尝试，但结果并不尽如人意，比如在volume上，就只支持hostPath，其他方面想必也有大量暂未实现的Spec。

&nbsp; &nbsp; &nbsp; &nbsp;在困扰了一下午后我意识到，kubelet可以运行Static Pod，直接从文件系统读取yaml，不必依赖api-server。“standalone kubelet”，这一运作方式的称呼似乎是如此，在网路上也能查到一些相关文档，TL;DR：只要在启动kubelet时加上--pod-manifest-path选项，指向PodSpec所在文件夹即可（事实上这一选项已经被废弃，但是¯\\\_(ツ)\_/¯）。

&nbsp; &nbsp; &nbsp; &nbsp;由于需要使用wireguard，我的host system是debian（其实也有轮子能给coreos灌kernel module.......奇怪的轮子变多了！），在运行时上还是选择了docker而非cri-o，毕竟cri-o缺乏cli，会给调试带来诸多不便（别和我说crictl）。从kubic project那里装了kubelet，从debian官方源里安了docker，PodSpec一塞，诶，怎么我的容器挂了（

&nbsp; &nbsp; &nbsp; &nbsp;这里就要说道一个common gotcha了，众所周知，docker存在entrypoint和command的区别，当entrypoint存在时，command会被作为argument，造成了一种十分不一致的行为表现，对podman来说也是如此，但在PodSpec里，只有command和args，开始时我直接使用了podman generate kube所生成的PodSpec，它错误地将command置于了command中，um，是的就是这样。

&nbsp; &nbsp; &nbsp; &nbsp;剩下的篇幅就讲讲关于netns吧，最近折腾wireguard，创建了114514个interface，自然就想把它们塞在netns里，不仅是方便策略路由，还可以利用ns gc的机制快速清理。那netns会在什么情况下被清理呢？When there's no reference to it. 对于一个unnamed netns，就是当所有位于该netns中的进程退出之时，而对于一个named netns，则是在这一条件之外，他所对应位于/var/run/netns/NAME的文件也被删除之时（其实这个是个nsfs mount point，这也是个gotcha.....），故而我当时采用的方法是将/var/run/netns bind mount进了容器之中，却发现尝试在宿主机中ip netns exec时，会遇到setting the network namespace "name of netns" failed: Invalid argument的错误，其原因在于docker的bind propagation默认是rslave，调整为shared即可。或者不bind mount该目录，便可以创建仅在容器中可见的named netns，（它也会在容器退出时被回收）。

&nbsp; &nbsp; &nbsp; &nbsp;不过我还是没有找到在一个在新netns中回到default netns的方法（如果你在原始的pid ns中倒是可以直接进入pid 1所在的ns，但是在容器里没法这样做呢），提前运行ip netns attach default 1或许是一个方案，但是不太漂亮呢.....
