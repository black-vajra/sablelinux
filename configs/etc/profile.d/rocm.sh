# SableLinux ROCm environment
# ROCm 7.2.2 is installed under /opt/rocm-7.2.2.

export ROCM_PATH="/opt/rocm-7.2.2"
export HIP_PATH="/opt/rocm-7.2.2"
export HIP_PLATFORM="amd"

case ":$PATH:" in
    *":$ROCM_PATH/bin:"*) ;;
    *) export PATH="$ROCM_PATH/bin:$PATH" ;;
esac

case ":${LD_LIBRARY_PATH:-}:" in
    *":$ROCM_PATH/lib:"*) ;;
    *)
        if [ -n "${LD_LIBRARY_PATH:-}" ]; then
            export LD_LIBRARY_PATH="$ROCM_PATH/lib:$ROCM_PATH/lib64:$LD_LIBRARY_PATH"
        else
            export LD_LIBRARY_PATH="$ROCM_PATH/lib:$ROCM_PATH/lib64"
        fi
        ;;
esac
