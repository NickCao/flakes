> Nix is a tool that takes a unique approach to package management and system configuration

&nbsp; &nbsp; &nbsp; &nbsp;最近从Arch Linux换到了NixOS，一个非FHS的发行版，也借此机会写下本文，表达一些我对Nix的拙见。首先何为Nix：在通常的视角看来他是一个包管理工具，与dpkg、rpm或是pacman并无二致，但是在我看来，他是一个构建工具，更加偏向于GNU Make或者Bazel。Nix中最为关键的一个概念是derivation，也即构建的步骤，等价于Makefile，但是相比于Makefile，derivation有着两个特性，首先，他指定了所有的输入的hash，确保了构建的可复现性，其次，它本身是一个具有确定性的格式，也即对于一个特定的derivation，它有唯一的canonical format。这两个特性的加入使得我们可以计算一个derivation本身的hash，并且（在理想状况下）可以认为对于该derivation，它的每次构建都会得到一致的输出，也即reproducibility。一个简单的derivation如下所示：

```
Derive([("out","/nix/store/k2b4rc8xw8spxpzj89iczj14ixx1ndci-hello","","")],[("/nix/store/wvki5j5v48xmar2gm213aq5pbvf4s536-bash-4.4-p23.drv",["out"])],[],"x86_64-linux","/nix/store/4l7wsi6h6283194r6fqy1731qxlagq62-bash-4.4-p23/bin/bash",[],[("builder","/nix/store/4l7wsi6h6283194r6fqy1731qxlagq62-bash-4.4-p23/bin/bash"),("name","hello"),("out","/nix/store/k2b4rc8xw8spxpzj89iczj14ixx1ndci-hello"),("system","x86_64-linux")])
```

&nbsp; &nbsp; &nbsp; &nbsp;看上去不太可读？那我们就把它解析成json再看看
```json
{
  "/nix/store/9vqffr1gqb0yivf8400vrr3b6d8y15cb-hello.drv": {
    "outputs": {
      "out": {
        "path": "/nix/store/k2b4rc8xw8spxpzj89iczj14ixx1ndci-hello"
      }
    },
    "inputSrcs": [],
    "inputDrvs": {
      "/nix/store/wvki5j5v48xmar2gm213aq5pbvf4s536-bash-4.4-p23.drv": [
        "out"
      ]
    },
    "platform": "x86_64-linux",
    "builder": "/nix/store/4l7wsi6h6283194r6fqy1731qxlagq62-bash-4.4-p23/bin/bash",
    "args": [],
    "env": {
      "builder": "/nix/store/4l7wsi6h6283194r6fqy1731qxlagq62-bash-4.4-p23/bin/bash",
      "name": "hello",
      "out": "/nix/store/k2b4rc8xw8spxpzj89iczj14ixx1ndci-hello",
      "system": "x86_64-linux"
    }
  }
}
```
&nbsp; &nbsp; &nbsp; &nbsp;这里指定的inputDrv，也即输入，或者通常的包管理中所说的依赖，outputs即是编译输出，每个derivation可以有多个编译输出，而其中的builder，便是构建时所执行的命令了，在这里是bash，也即什么都不做。可以注意到在derivation中所引用的路径都为一个特定的格式：`/nix/store/<hex string>-<name>`，其中的hex string部分便是刚才所提到的hash，事实上这一路径中的name部分并无作用，只是为了人类可读。而这样的路径在Nix中我们将其称为store path。到这里不难看出Nix所做的事实则就是把derivation实例化，也即将构建输入转化为构建输出。同时构建输出的路径也可以在构建前知晓，或者被其他derivation引用

&nbsp; &nbsp; &nbsp; &nbsp;但是这样的derivation格式并非人类可写，故而Nix还带来了一个DSL：Nix expression language，一个函数式编程语言，并将其求值为derivation，对于刚才的例子，其所对应的Nix expression如下：

```nix
derivation { name = "hello"; builder = "${pkgs.bash}/bin/bash"; system = builtins.currentSystem; }
```

&nbsp; &nbsp; &nbsp; &nbsp;可以看到其中的`"${pkgs.bash}/bin/bash"`部分是string interpolation，我们可以直接像这样指向其他derivation，将其作为该derivation的依赖，最终串成一张有向无环图，作为构建我们的derivation所需的闭包

&nbsp; &nbsp; &nbsp; &nbsp;那发行版又是什么呢，实则就是一些互相依赖的可执行文件，资源文件，或者是库和配置文件，如果我们将发行版也作为一个derivation的构建输出，即可得到一个具有确定性的，可复现的系统，也即，NixOS

&nbsp; &nbsp; &nbsp; &nbsp;如果这篇文章能勾起你对Nix的一点点兴趣，无论是作为一门语言，一个构建系统，一个包管理器，或者是一个发行版，可以看看[Nix Pills](https://nixos.org/guides/nix-pills/)，从一个不同的视角重新了解你所熟知的事物。
