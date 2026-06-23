# linux-sys-report-cli Health Report

Generated: 2026-06-21 14:30:12

Overall status: **WARNING**

## Summary

| Category | Status |
|---|---|
| System | OK |
| CPU | OK |
| Memory | OK |
| Disk | WARNING |
| Network | OK |
| Services | WARNING |
| Logs | WARNING |
| Docker | OK |

## Details

### System

```text
Hostname: devbox
OS: Ubuntu 24.04.1 LTS
Kernel: 6.8.0-49-generic
Uptime: 5d 3h 12m
```

### CPU

```text
Load average: 0.52 0.61 0.58
CPU cores: 8
Load per core: 0.07
Status: OK

Top processes by CPU:
PID        %CPU   %MEM  COMMAND
1842       12.3    3.1  nginx
2210        8.7    4.5  postgres
958         4.2    1.8  dockerd
1390        2.1    0.9  node
```

### Memory

```text
Used: 6.2 GiB / 16.0 GiB (38.8%)
Swap: 0.0 GiB / 2.0 GiB (0.0%)
Status: OK

Top processes by memory:
PID        %MEM   %CPU  COMMAND
2210        4.5    8.7  postgres
1842        3.1   12.3  nginx
958         1.8    4.2  dockerd
```

### Disk

```text
Filesystem usage:
  /var: 82%
  /: 68%
  /home: 41%

Inode usage:
  /var: 35%
  /: 22%
  /home: 12%
Status: WARNING
```

### Network

```text
Interfaces:
eth0: 192.168.1.42

Default gateway: 192.168.1.1
DNS check (google.com): OK (142.251.218.206)
Internet check (8.8.8.8): OK
HTTP check: n/a
Status: OK

Listening ports:
PROTO  LOCAL ADDRESS          PROCESS
tcp    0.0.0.0:22             sshd
tcp    0.0.0.0:80             nginx
tcp    0.0.0.0:443            nginx
tcp    127.0.0.1:5432         postgres
```

### Services

```text
Failed units: 1
  backup.service

Status: WARNING
```

### Logs

```text
Log source: journalctl
Lookback: 1 hour ago
Matching entries: 4
Critical entries: 0
Status: WARNING

Recent matching entries:
Jun 21 13:58:02 devbox backup.service[2931]: connection refused while uploading snapshot
Jun 21 13:58:02 devbox backup.service[2931]: failed to complete backup job
Jun 21 14:02:11 devbox kernel: [   91.5] eth0: link timeout, renegotiating
Jun 21 14:10:44 devbox sshd[3210]: error: permission denied for user 'deploy'
```

### Docker

```text
Running containers: 3
Stopped containers: 0
Unhealthy containers: 0
Status: OK

Containers with restarts:
  (none)

Resource usage:
nginx: CPU 0.42%, MEM 18.2MiB / 7.654GiB
postgres: CPU 1.10%, MEM 142.5MiB / 7.654GiB
redis: CPU 0.08%, MEM 9.4MiB / 7.654GiB
```

## Recommendations

- Check disk usage under /var.
- Investigate failed systemd unit: backup.service.
- Review recent error logs from the last hour.
