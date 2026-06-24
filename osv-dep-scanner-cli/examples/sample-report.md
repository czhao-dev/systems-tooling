# Dependency Vulnerability Scan

| Manifests scanned | Dependencies checked | Findings | Worst severity |
|---|---|---|---|
| 4 | 5 | 20 | high |

## GHSA-69ch-w2m2-3vjp (high)

golang.org/x/text/language Denial of service via crafted Accept-Language header

Affected:
- `gomod:golang.org/x/text@v0.3.0` (examples/go.mod)

References:
- https://nvd.nist.gov/vuln/detail/CVE-2022-32149
- https://github.com/golang/go/issues/56152
- https://github.com/golang/text/commit/434eadcdbc3b0256971992e8c70027278364c72c
- https://github.com/golang/text
- https://go.dev/cl/442235
- https://go.dev/issue/56152
- https://groups.google.com/g/golang-announce/c/-hjNw559_tE/m/KlGTfid5CAAJ
- https://pkg.go.dev/vuln/GO-2022-1059
- https://security.netapp.com/advisory/ntap-20230203-0006

## GHSA-ppp9-7jff-5vj2 (high)

golang.org/x/text/language Out-of-bounds Read vulnerability

Affected:
- `gomod:golang.org/x/text@v0.3.0` (examples/go.mod)

References:
- https://nvd.nist.gov/vuln/detail/CVE-2021-38561
- https://deps.dev/advisory/OSV/GO-2021-0113
- https://go.dev/cl/340830
- https://go.googlesource.com/text/+/383b2e75a7a4198c42f8f87833eefb772868a56f
- https://groups.google.com/g/golang-announce
- https://pkg.go.dev/golang.org/x/text/language
- https://pkg.go.dev/vuln/GO-2021-0113

## GHSA-m2qf-hxjv-5gpq (high)

Flask vulnerable to possible disclosure of permanent session cookie due to missing Vary: Cookie header

Affected:
- `pypi:flask@2.0.0` (examples/requirements.txt)

References:
- https://github.com/pallets/flask/security/advisories/GHSA-m2qf-hxjv-5gpq
- https://nvd.nist.gov/vuln/detail/CVE-2023-30861
- https://github.com/pallets/flask/commit/70f906c51ce49c485f1d355703e9cc3386b1cc2b
- https://github.com/pallets/flask/commit/afd63b16170b7c047f5758eb910c416511e9c965
- https://github.com/pallets/flask
- https://github.com/pallets/flask/releases/tag/2.2.5
- https://github.com/pallets/flask/releases/tag/2.3.2
- https://github.com/pypa/advisory-database/tree/main/vulns/flask/PYSEC-2023-62.yaml
- https://lists.debian.org/debian-lts-announce/2023/08/msg00024.html
- https://security.netapp.com/advisory/ntap-20230818-0006
- https://www.debian.org/security/2023/dsa-5442

## GHSA-35jh-r3h4-6jhm (high)

Command Injection in lodash

Affected:
- `npm:lodash@4.17.15` (examples/package-lock.json)

References:
- https://nvd.nist.gov/vuln/detail/CVE-2021-23337
- https://github.com/lodash/lodash/commit/3469357cff396a26c363f8c1b5a91dde28ba4b1c
- https://www.oracle.com/security-alerts/cpuoct2021.html
- https://www.oracle.com/security-alerts/cpujul2022.html
- https://www.oracle.com/security-alerts/cpujan2022.html
- https://www.oracle.com//security-alerts/cpujul2021.html
- https://snyk.io/vuln/SNYK-JS-LODASH-1040724
- https://snyk.io/vuln/SNYK-JAVA-ORGWEBJARSNPM-1074929
- https://snyk.io/vuln/SNYK-JAVA-ORGWEBJARSBOWERGITHUBLODASH-1074931
- https://snyk.io/vuln/SNYK-JAVA-ORGWEBJARSBOWER-1074928
- https://snyk.io/vuln/SNYK-JAVA-ORGWEBJARS-1074930
- https://snyk.io/vuln/SNYK-JAVA-ORGFUJIONWEBJARS-1074932
- https://security.netapp.com/advisory/ntap-20210312-0006
- https://github.com/rubysec/ruby-advisory-db/blob/master/gems/lodash-rails/CVE-2021-23337.yml
- https://github.com/lodash/lodash/blob/ddfd9b11a0126db2302cb70ec9973b66baec0975/lodash.js#L14851
- https://github.com/lodash/lodash
- https://cert-portal.siemens.com/productcert/pdf/ssa-637483.pdf

## GHSA-p6mc-m468-83gw (high)

Prototype Pollution in lodash

Affected:
- `npm:lodash@4.17.15` (examples/package-lock.json)

References:
- https://nvd.nist.gov/vuln/detail/CVE-2020-8203
- https://github.com/lodash/lodash/issues/4744
- https://github.com/lodash/lodash/issues/4874
- https://github.com/github/advisory-database/pull/2884
- https://github.com/lodash/lodash/commit/c84fe82760fb2d3e03a63379b297a1cc1a2fce12
- https://hackerone.com/reports/712065
- https://hackerone.com/reports/864701
- https://github.com/lodash/lodash
- https://github.com/lodash/lodash/wiki/Changelog#v41719
- https://github.com/rubysec/ruby-advisory-db/blob/master/gems/lodash-rails/CVE-2020-8203.yml
- https://security.netapp.com/advisory/ntap-20200724-0006
- https://web.archive.org/web/20210914001339/https://github.com/lodash/lodash/issues/4744

## GHSA-r5fr-rjxr-66jc (high)

lodash vulnerable to Code Injection via `_.template` imports key names

Affected:
- `npm:lodash@4.17.15` (examples/package-lock.json)

References:
- https://github.com/lodash/lodash/security/advisories/GHSA-r5fr-rjxr-66jc
- https://nvd.nist.gov/vuln/detail/CVE-2026-4800
- https://github.com/lodash/lodash/commit/3469357cff396a26c363f8c1b5a91dde28ba4b1c
- https://cna.openjsf.org/security-advisories.html
- https://github.com/advisories/GHSA-35jh-r3h4-6jhm
- https://github.com/lodash/lodash

## GHSA-j8r2-6x86-q33q (medium)

Unintended leak of Proxy-Authorization header in requests

Affected:
- `pypi:requests@2.25.0` (examples/requirements.txt)

References:
- https://github.com/psf/requests/security/advisories/GHSA-j8r2-6x86-q33q
- https://nvd.nist.gov/vuln/detail/CVE-2023-32681
- https://github.com/psf/requests/commit/74ea7cf7a6a27a4eeb2ae24e162bcc942a6706d5
- https://github.com/psf/requests
- https://github.com/psf/requests/releases/tag/v2.31.0
- https://github.com/pypa/advisory-database/tree/main/vulns/requests/PYSEC-2023-74.yaml
- https://lists.debian.org/debian-lts-announce/2023/06/msg00018.html
- https://lists.fedoraproject.org/archives/list/package-announce@lists.fedoraproject.org/message/AW7HNFGYP44RT3DUDQXG2QT3OEV2PJ7Y
- https://lists.fedoraproject.org/archives/list/package-announce@lists.fedoraproject.org/message/KOYASTZDGQG2BWLSNBPL3TQRL2G7QYNZ
- https://security.gentoo.org/glsa/202309-08

## GHSA-gc5v-m9x4-r6x2 (medium)

Requests has Insecure Temp File Reuse in its extract_zipped_paths() utility function

Affected:
- `pypi:requests@2.25.0` (examples/requirements.txt)

References:
- https://github.com/psf/requests/security/advisories/GHSA-gc5v-m9x4-r6x2
- https://nvd.nist.gov/vuln/detail/CVE-2026-25645
- https://github.com/psf/requests/commit/66d21cb07bd6255b1280291c4fafb71803cdb3b7
- https://github.com/psf/requests
- https://github.com/psf/requests/releases/tag/v2.33.0

## GHSA-9wx4-h78v-vm56 (medium)

Requests `Session` object does not verify requests after making first request with verify=False

Affected:
- `pypi:requests@2.25.0` (examples/requirements.txt)

References:
- https://github.com/psf/requests/security/advisories/GHSA-9wx4-h78v-vm56
- https://nvd.nist.gov/vuln/detail/CVE-2024-35195
- https://github.com/psf/requests/pull/6655
- https://github.com/psf/requests/commit/a58d7f2ffb4d00b46dca2d70a3932a0b37e22fac
- https://github.com/psf/requests
- https://lists.fedoraproject.org/archives/list/package-announce@lists.fedoraproject.org/message/IYLSNK5TL46Q6XPRVMHVWS63MVJQOK4Q
- https://lists.fedoraproject.org/archives/list/package-announce@lists.fedoraproject.org/message/N7WP6EYDSUOCOJYHDK5NX43PYZ4SNHGZ

## GHSA-9hjg-9r4m-mvj7 (medium)

Requests vulnerable to .netrc credentials leak via malicious URLs

Affected:
- `pypi:requests@2.25.0` (examples/requirements.txt)

References:
- https://github.com/psf/requests/security/advisories/GHSA-9hjg-9r4m-mvj7
- https://nvd.nist.gov/vuln/detail/CVE-2024-47081
- https://github.com/psf/requests/pull/6965
- https://github.com/psf/requests/commit/96ba401c1296ab1dda74a2365ef36d88f7d144ef
- https://github.com/psf/requests
- https://requests.readthedocs.io/en/latest/api/#requests.Session.trust_env
- https://seclists.org/fulldisclosure/2025/Jun/2
- http://seclists.org/fulldisclosure/2025/Jun/2
- http://www.openwall.com/lists/oss-security/2025/06/03/11
- http://www.openwall.com/lists/oss-security/2025/06/03/9
- http://www.openwall.com/lists/oss-security/2025/06/04/1
- http://www.openwall.com/lists/oss-security/2025/06/04/6

## GHSA-xxjr-mmjv-4gpg (medium)

Lodash has Prototype Pollution Vulnerability in `_.unset` and `_.omit` functions

Affected:
- `npm:lodash@4.17.15` (examples/package-lock.json)

References:
- https://github.com/lodash/lodash/security/advisories/GHSA-xxjr-mmjv-4gpg
- https://nvd.nist.gov/vuln/detail/CVE-2025-13465
- https://github.com/lodash/lodash/commit/edadd452146f7e4bad4ea684e955708931d84d81
- https://cert-portal.siemens.com/productcert/html/ssa-253495.html
- https://github.com/lodash/lodash

## GHSA-f23m-r3pf-42rh (medium)

lodash vulnerable to Prototype Pollution via array path bypass in `_.unset` and `_.omit`

Affected:
- `npm:lodash@4.17.15` (examples/package-lock.json)

References:
- https://github.com/lodash/lodash/security/advisories/GHSA-f23m-r3pf-42rh
- https://github.com/lodash/lodash/security/advisories/GHSA-xxjr-mmjv-4gpg
- https://nvd.nist.gov/vuln/detail/CVE-2026-2950
- https://github.com/lodash/lodash

## GHSA-29mw-wpgm-hmr9 (medium)

Regular Expression Denial of Service (ReDoS) in lodash

Affected:
- `npm:lodash@4.17.15` (examples/package-lock.json)

References:
- https://nvd.nist.gov/vuln/detail/CVE-2020-28500
- https://github.com/github/advisory-database/pull/6139
- https://github.com/lodash/lodash/pull/5065
- https://github.com/lodash/lodash/pull/5065/commits/02906b8191d3c100c193fe6f7b27d1c40f200bb7
- https://github.com/lodash/lodash/commit/c4847ebe7d14540bb28a8b932a9ce1b9ecbfee1a
- https://www.oracle.com/security-alerts/cpuoct2021.html
- https://www.oracle.com/security-alerts/cpujul2022.html
- https://www.oracle.com/security-alerts/cpujan2022.html
- https://www.oracle.com//security-alerts/cpujul2021.html
- https://snyk.io/vuln/SNYK-JS-LODASH-1018905
- https://snyk.io/vuln/SNYK-JAVA-ORGWEBJARSNPM-1074893
- https://snyk.io/vuln/SNYK-JAVA-ORGWEBJARSBOWERGITHUBLODASH-1074895
- https://snyk.io/vuln/SNYK-JAVA-ORGWEBJARSBOWER-1074892
- https://snyk.io/vuln/SNYK-JAVA-ORGWEBJARS-1074894
- https://snyk.io/vuln/SNYK-JAVA-ORGFUJIONWEBJARS-1074896
- https://security.netapp.com/advisory/ntap-20210312-0006
- https://github.com/rubysec/ruby-advisory-db/blob/master/gems/lodash-rails/CVE-2020-28500.yml
- https://github.com/lodash/lodash/blob/npm/trimEnd.js%23L8
- https://github.com/lodash/lodash
- https://cert-portal.siemens.com/productcert/pdf/ssa-637483.pdf

## GHSA-5rcv-m4m3-hfh7 (medium)

golang.org/x/text Infinite loop

Affected:
- `gomod:golang.org/x/text@v0.3.0` (examples/go.mod)

References:
- https://nvd.nist.gov/vuln/detail/CVE-2020-14040
- https://github.com/golang/go/issues/39491
- https://github.com/golang/text/commit/23ae387dee1f90d29a23c0e87ee0b46038fbed0e
- https://go-review.googlesource.com/c/text/+/238238
- https://go.dev/cl/238238
- https://go.dev/issue/39491
- https://go.googlesource.com/text/+/23ae387dee1f90d29a23c0e87ee0b46038fbed0e
- https://groups.google.com/forum/#!topic/golang-announce/bXVeAmGOqz0
- https://groups.google.com/g/golang-announce/c/bXVeAmGOqz0
- https://lists.fedoraproject.org/archives/list/package-announce@lists.fedoraproject.org/message/TACQFZDPA7AUR6TRZBCX2RGRFSDYLI7O

## GHSA-68rp-wp8r-4726 (low)

Flask session does not add `Vary: Cookie` header when accessed in some ways

Affected:
- `pypi:flask@2.0.0` (examples/requirements.txt)

References:
- https://github.com/pallets/flask/security/advisories/GHSA-68rp-wp8r-4726
- https://nvd.nist.gov/vuln/detail/CVE-2026-27205
- https://github.com/pallets/flask/commit/089cb86dd22bff589a4eafb7ab8e42dc357623b4
- https://github.com/pallets/flask
- https://github.com/pallets/flask/releases/tag/3.1.3

## PYSEC-2023-62 (unknown)



Affected:
- `pypi:flask@2.0.0` (examples/requirements.txt)

References:
- https://github.com/pallets/flask/commit/70f906c51ce49c485f1d355703e9cc3386b1cc2b
- https://github.com/pallets/flask/releases/tag/2.3.2
- https://github.com/pallets/flask/releases/tag/2.2.5
- https://github.com/pallets/flask/security/advisories/GHSA-m2qf-hxjv-5gpq
- https://github.com/pallets/flask/commit/afd63b16170b7c047f5758eb910c416511e9c965

## GO-2022-1059 (unknown)

Denial of service via crafted Accept-Language header in golang.org/x/text/language

Affected:
- `gomod:golang.org/x/text@v0.3.0` (examples/go.mod)

References:
- https://go.dev/issue/56152
- https://go.dev/cl/442235
- https://groups.google.com/g/golang-announce/c/-hjNw559_tE/m/KlGTfid5CAAJ

## GO-2021-0113 (unknown)

Out-of-bounds read in golang.org/x/text/language

Affected:
- `gomod:golang.org/x/text@v0.3.0` (examples/go.mod)

References:
- https://go.dev/cl/340830
- https://go.googlesource.com/text/+/383b2e75a7a4198c42f8f87833eefb772868a56f

## GO-2020-0015 (unknown)

Infinite loop when decoding some inputs in golang.org/x/text

Affected:
- `gomod:golang.org/x/text@v0.3.0` (examples/go.mod)

References:
- https://go.dev/cl/238238
- https://go.googlesource.com/text/+/23ae387dee1f90d29a23c0e87ee0b46038fbed0e
- https://go.dev/issue/39491
- https://groups.google.com/g/golang-announce/c/bXVeAmGOqz0

## PYSEC-2023-74 (unknown)



Affected:
- `pypi:requests@2.25.0` (examples/requirements.txt)

References:
- https://github.com/psf/requests/security/advisories/GHSA-j8r2-6x86-q33q
- https://github.com/psf/requests/releases/tag/v2.31.0
- https://github.com/psf/requests/commit/74ea7cf7a6a27a4eeb2ae24e162bcc942a6706d5
- https://lists.fedoraproject.org/archives/list/package-announce@lists.fedoraproject.org/message/AW7HNFGYP44RT3DUDQXG2QT3OEV2PJ7Y/

