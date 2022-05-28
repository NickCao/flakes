&nbsp; &nbsp; &nbsp; &nbsp;曾经我是个不太重视过去的人呢，只愿活在当下与未来（现在也依然是如此。但我还是开始为自己的数字所有物做备份了，~~毕竟btrfs send这么方便~~。虽然我的nvme ssd有1T，完全可以承载大量的snapshot，但本地的备份无法被称之为备份（单点故障真可怕。然而我的vps也只有区区25G存储，更别提15G的Google drive，在每日增量每周全量的备份策略下，完全无法维持。恰好vultr推出了他们的对象存储服务（比S3都贵，真的，我便开始直接将btrfs数据流送入对象存储之中。但我没有理由相信vultr，而备份中也不可避免的包含大量敏感信息，传输前的加密也尤为重要。

&nbsp; &nbsp; &nbsp; &nbsp;openssl与gpg，首先想到的解决方案便是这两个，openssl可以使用AES-NI，而gpg可以省去我保管额外的对称密钥的麻烦。除此之外，openssl还有一个极大的问题：一个非密码学专业者难以决定合理的加密参数，这足以使之变得并不安全。综上，我选择了gpg。初步的尝试便让我发现了问题：校园网的下行速率一般，上传却可以跑满12MiBps，gpg完全成为了传输速率的瓶颈，还占满了我的cpu。一开始我认为这是gpg并不支持AES-NI的的缘故，然而简单的benchmark完全推翻了这一论断。而事实上，是gpg默认使用的gzip造成的问题。我的btrfs使用了透明压缩，但btrfs send过程会解开压缩，因此在gpg前我使用了zstd预压缩。
```bash
$ sudo compsize -x /
Processed 233340 files, 148726 regular extents (151685 refs), 126442 inline.
Type       Perc     Disk Usage   Uncompressed Referenced  
TOTAL       49%      5.3G          10G          11G       
none       100%      1.9G         1.9G         2.0G       
zlib        39%       11M          29M          29M       
zstd        38%      3.3G         8.7G         9.1G
```
&nbsp; &nbsp; &nbsp; &nbsp;从compsize的结果来看，zstd达到了相当高的压缩率，gpg添加的一层gzip自然只是白费功夫。"--compress-algo Uncompressed"，添加了额外参数以关闭压缩后，gpg不论是在cpu占用还是速率上均进入了可以接受的范围。而最后，我也得到了下面的one liner进行全量备份：
```bash
sudo btrfs send $1 | zstd - | gpg --encrypt -r Nick\ Cao \
--compress-algo Uncompressed | mc pipe minio/offsite/$1.zst.gpg
```
&nbsp; &nbsp; &nbsp; &nbsp;再说对象存储，我的个人源也托管在了对象存储之中。然而vultr所使用的对象存储实现似乎在bucket policy的解释上存在问题，对于部分名称中存在需要url encode的对象，无法正确应用。提交工单反映后，vultr方面给出的回应却是设置per object acl（其实vultr的工程师从头到尾都没搞清楚bucket acl与bucket policy的区别。这对我而言显然不可接受，因此我关闭了工单，尝试从我的方面解决问题。我首先做出的尝试是添加一层minio作为api gateway，它很好的达到了目的（但都这样了我为什么不知直接把源放在vps上呢？我的第二次尝试便是cloudflare worker。其实之前我也在源上使用了worker呢，不过功能仅仅是url rewrite，而这次是作为鉴权网关：
```js
import AWS from 'aws-sdk';

var s3 = new AWS.S3({
  endpoint: <the endpoint to send requests to>,
  accessKeyId: <ACCESS_KEY>,
  secretAccessKey: <SECRET_KEY>,
  region: 'us-east-1'
});

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  var path = (new URL(request.url)).pathname.substring(1)
  if (path == "") {
    return new Response(
      "<a short description of the bucket would be nice>"
      , { status: 200 })
  }
  return fetch(s3.getSignedUrl("getObject",
  {
    Bucket: '<the bucket name>',
    Key: path
  }))
}
```
&nbsp; &nbsp; &nbsp; &nbsp;总而言之，对象存储确实是当下存储解决方案中十分特别的一枝，打破了传统的文件系统概念，作为单纯的名称到数据映射覆盖了我的存储需求。（但是坑也好多....号称生产可用的minio碰到需要url encode的对象也会懵逼......（