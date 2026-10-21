# Z890 kernel and AI workstation audit — 2026-10-21

## Direction and authority

The operator's direction is a developer-focused AI workstation distribution:
modern NVIDIA/AMD/Intel GPU planning, local inference, fine-tuning/training
where hardware permits, and user-selected frontier-model API integration.
This informs 1.0 engineering alongside the December 31 ISO target. Z890 alone
supplies release inputs; research and secondary hardware do not establish
canonical capability. Model weights remain excluded from baseline live media;
llama-server remains disabled in generated live media under existing policy.

## Evidence boundary

Retained reports were collected on running Z890 at 18:26:46Z, 18:48:24Z and
18:52:15Z. The first report predates inventory commit ce8b6f6; the provenance
report confirms that commit and no tracked changes, with scripts/boincctl
preserved and untracked. Cached origin/development matches; no independent
remote query was part of these reports. Commands report their failures.

The observations below do not establish frozen inputs, a complete package
ledger, successful training/inference acceptance, or a live/installed ISO gate.

## Kernel and toolchain

- Running release: 6.16.1-sable-gpu-test2.
- Installed /boot configuration and image match the retained build-tree files
  byte for byte. The build tree is /home/pepper/sable-kernel-gpu-test.
- The module build link resolves there; its source link is absent. Generated
  release/compiler headers and Module.symvers exist. No .git entry was found
  at the tree root. Complete source origin/rebuild provenance remains open.
- Installed config SHA256:
  1271404d28cc2eb66f9cf2222c4b2f7406cff4a85f57c3ba4ced8d1d45d22fd5
- Installed kernel image SHA256:
  bc36f8987e137cf913a135d4f4884886d1342c7148d8114787bb5cfa74f7929d
- Installed initramfs SHA256 (privileged read succeeded):
  49e94ff834b6c06c8e535a451a1ada7e62217d9f1f489bd9e74036ee057cf972
- GCC 15.2.0; binutils 2.45; glibc 2.42; Python 3.13.7;
  CMake 3.31.6; Ninja 1.13.1. No blanket toolchain replacement is justified.
- Parsed config: 1,845 y, 44 m, 2,859 explicitly disabled, 118 numeric/string
  assignments. Counts alone do not establish overconfiguration; many booleans
  and dependency selections cannot become modules.

## Configuration requirements to resolve

| Observation | Required investigation |
| --- | --- |
| i915=m and amdgpu=m; both actually bound | Preserve working drivers; qualify new candidates independently |
| HSA_AMD=y | Test actual compute access/runtime; configuration alone is insufficient |
| NOUVEAU=m; no NVIDIA hardware detected | Define matching NVIDIA module/firmware/userspace/CUDA profile and obtain hardware evidence |
| USER_NS=n | Proposed rootless-container path needs user namespaces and appropriate userspace prerequisites |
| MEMCG=n, CFS_BANDWIDTH=n | Define and test workload memory-limit/CPU-quota requirements |
| BPF_SYSCALL=n | Evaluate cgroup-v2 device-control/runtime requirements; CGROUP_DEVICE=y alone is insufficient |
| FUSE_FS=n, VFIO=n | Review selected FUSE workflows and optional device passthrough separately |
| DRM_XE=n | Evaluate intended Intel device coverage; do not displace working i915 speculatively |
| SQUASHFS_XATTR=n | Test metadata through image creation, mounted SquashFS, overlay and installation |

The staging rsync preservation fixture does not establish preservation through
the remaining image/install stages. Kernel SquashFS documentation lists xattr
support and no ACL support. Enabling xattrs does not settle POSIX ACL semantics.
Define separate acceptance and use disposable image/overlay/install fixtures.

## Existing AI runtime

- llama-server service is active. Executable /usr/local/bin/llama-server has
  SHA256 fe51fcb2c29ed2a409b04db6fca0062747299e3209f93bbacbdadd952084bf86.
- Version output reports version 1, short revision 15fa3c4, GNU 15.2.0 build.
  Full source revision, source changes and build options remain to establish.
- The version probe initialized HIP and enumerated gfx1200 with 16,304 MiB
  total VRAM. It was not a generation test. The ggml_cuda_init log prefix
  appears alongside an explicit ROCm device report; it does not imply NVIDIA.
- Running process maps include libggml-hip and ROCm/HIP/rocBLAS libraries from
  /opt/rocm-7.2.2. This identifies loaded components, not executed GPU work.
- HIP tools report 7.2.53211-0; compiler output identifies roc-7.2.2 and AMD
  clang 22.0.0git. Conventional .info/version metadata was not found. Preserve
  this layout; missing conventional metadata alone does not justify repair.
- Service selects /opt/models/DeepSeek-R1-Distill-Qwen-14B-Q4_K_M.gguf and
  requests offload with -ngl 999. Actual offloaded layers, generation behavior,
  model hash/source/license and performance remain unverified.
- System Python has venv/ensurepip and pip 26.0.1. Listed AI frameworks were
  absent from isolated system-Python package metadata; other environments
  were not inspected. uv is in PATH; python3.12/docker/podman/ollama were not.
- Do not downgrade system Python. Qualify independently versioned runtime
  environments; current vLLM documentation has backend-specific Python wheel
  requirements, including Python 3.12 for its documented ROCm wheels.

## Next bounded work

1. Discover the existing server listener and validate health plus one short
   generation without restarting it; retain response/timings and offload logs.
2. Establish full llama.cpp source/build and model provenance using known paths.
3. Establish kernel source provenance and classify proposed configuration
   changes against selected workflows. Preserve GPU Test 2 and test separately.
4. Design the image/overlay/install metadata fixture before fresh capture.
5. Continue package ownership/provenance/functionality audit and input freeze.
   Keep NVIDIA/Intel compatibility claims tied to actual validation evidence.

Primary references consulted on 2026-10-21 (not Sable runtime validation):

- https://docs.docker.com/engine/security/rootless/
- https://docs.kernel.org/admin-guide/cgroup-v2.html
- https://docs.kernel.org/filesystems/squashfs.html
- https://github.com/NVIDIA/open-gpu-kernel-modules
- https://docs.nvidia.com/cuda/cuda-installation-guide-linux/
- https://docs.vllm.ai/en/stable/getting_started/installation/gpu/

## Original report SHA256 values

32b46231dec79e685b6853998b756e72cce8febd2f19210d50fe413a4529bf62  sable-ai-platform-audit-EBivbbdx.txt (retained as platform-audit.txt)
adf0c62d54798da0deeb994f510f5a97a0e521eb91829361453f3ad8d3b599e6  sable-kernel-ai-provenance-a4ynuF0q.txt (retained as kernel-provenance.txt)
cb5e6506e4da20c02d7cf7e07c6a18abb062d8f6c93326f0df2d767294259dd1  sable-ai-runtime-TcabG4Ft.txt (retained as ai-runtime.txt)
