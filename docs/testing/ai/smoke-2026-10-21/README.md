# Canonical local-inference smoke test — 2026-10-21

Z890 test at 19:12:32Z used the existing llama-server service on
http://127.0.0.1:8080. No restart, installation or configuration change occurred.

Health, model listing and native completion returned HTTP 200. The arithmetic
prompt produced a final answer of 4, generated seven tokens, stopped at EOS
and was not truncated. Service PID 761 remained unchanged.

Observed request duration: 0.281 seconds.
Server-reported generation: 208.971 ms, approximately 33.5 tokens/second.
This tiny request is a functional smoke test, not a sustained benchmark.

The executable hash matches the previously inspected llama-server. The server
lists DeepSeek-R1-Distill-Qwen-14B-Q4_K_M.gguf. Model source/hash/license and
full engine build provenance remain open.

No matching model-offload lines were captured from the bounded journal query.
This does not establish absent offload. Prior HIP detection, mapped libraries
and requested GPU layers do not independently prove actual execution placement.

Acceptance: existing local HTTP inference smoke test PASSED.
Not established: GPU placement, sustained performance, training, NVIDIA/Intel
compatibility, or any live-media/installation/reproducibility gate.

Preserve this working stack as the regression baseline while investigating
separate kernel candidates and image/overlay/install metadata preservation.

Reviewed original archive SHA256:
c4e79013ba197aca0b830ddaeacb2ffcb9528f3a641638294edffb7fa3550059
