# TPM2, SGX, and SEV — Concepts and Applicability to SableLinux

## TPM2 — yes, absolutely, and it's the most practical

This is fully achievable from userspace right now. `systemd-cryptenroll` can seal a LUKS key into the TPM2 chip bound to PCR (Platform Configuration Register) values — meaning the TPM will only release the key if the boot chain is unmodified. Tamper with the bootloader, kernel, or initramfs and the PCR values change, the TPM refuses, and the drive stays locked. This is real, production-grade, and well-supported. For a security distro this is table stakes.

## Intel SGX — complicated

SGX is userspace-accessible but Intel has been deprecating it on consumer CPUs since 11th gen. It's mainly a server/cloud technology now. More importantly, SGX has had a rough vulnerability history — Spectre variants, Plundervolt, SGAxe — which is awkward for a security-emphasis OS to rely on. You can use it, but you'd want to be deliberate about it rather than foundational.

## AMD SEV — wrong layer

SEV (Secure Encrypted Virtualization) encrypts VM memory from the hypervisor. It's phenomenally useful if SableLinux is going to run as a guest or host VMs — an SEV-encrypted VM is opaque even to a compromised hypervisor. But it doesn't apply to bare-metal userspace key management in the way you're describing.

## Practical Architecture for SableLinux

- **TPM2-backed LUKS** as the foundation, with `clevis` + `tang` as an option for network-bound decryption (key only released if the machine can reach a trusted Tang server — pull the network and the drive won't unlock, which is a beautiful property for a red-team box).
- **SGX** for specific application-level secret protection if needed on supported hardware.
- **SEV** if building VM hosting capabilities into SableLinux.
