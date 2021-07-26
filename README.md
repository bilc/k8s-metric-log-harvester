# metric-log
简要说明



## metric采集

promethus采集

## log采集

从cri接口获得日志采集配置，将容器内路径转换为主机路径，写入filebeat配置 

## TODO 

将metric采集和log采集制作成镜像，并封装成chart  

## 开发规范


```
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  annotation:
    prometheus.io/scrape: "true"    // metric: 控制开关，true则开启采集，false关闭采集
    prometheus.io/scheme: "http"    // metric: http或https
    prometheus.io/path: "/metrics"  // metric: 暴露指标的uri
    prometheus.io/port: "8000"      // metric: 暴露指标的端口号
  labels:
    run: test
spec:
  containers:
  - name: nginx
    image: docker.mirrors.ustc.edu.cn/library/nginx:1.14.2
    volumeMounts:
    - name: log-vol
      mountPath: /data/log
    env:
    - name: BILC_LOG               // log
      value:  /data/log/nginx/*     // 这里必须要使用通配符，多个路径用冒号分割
  volumes:
  - name: log-vol
    emptyDir: {}
```

