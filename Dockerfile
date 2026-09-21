# syntax=docker/dockerfile:1
# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.10.0-base

# RunPod starts ComfyUI with /opt/venv/bin/python. Tell comfy-cli and uv to
# install custom-node dependencies into that same runtime environment.
ENV VIRTUAL_ENV=/opt/venv

# build-time tokens for gated downloads are read from BuildKit secret
# mounts — they are never written to a layer or to image history.
# pass via: docker buildx build --secret id=hf_token,env=HF_TOKEN .

# install custom nodes into comfyui
RUN comfy node install --exit-on-fail comfyui-impact-pack@8.28.3 --mode remote || (echo "WARN: comfyui-impact-pack@8.28.3 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail comfyui-impact-pack --mode remote)
RUN git clone https://github.com/rgthree/rgthree-comfy /comfyui/custom_nodes/rgthree-comfy && cd /comfyui/custom_nodes/rgthree-comfy && (git checkout 8ff50e4521881eca1fe26aec9615fc9362474931 2>/dev/null || (git fetch origin 8ff50e4521881eca1fe26aec9615fc9362474931 --depth=1 && git checkout 8ff50e4521881eca1fe26aec9615fc9362474931) || echo "WARN: commit 8ff50e4521881eca1fe26aec9615fc9362474931 unreachable in https://github.com/rgthree/rgthree-comfy, falling back to default branch HEAD")
RUN comfy node install --exit-on-fail comfyui-krea2edit@1.2.3 || (echo "WARN: comfyui-krea2edit@1.2.3 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail comfyui-krea2edit)
RUN git clone https://github.com/capitan01R/ComfyUI-Krea2T-Enhancer /comfyui/custom_nodes/ComfyUI-Krea2T-Enhancer && cd /comfyui/custom_nodes/ComfyUI-Krea2T-Enhancer && (git checkout 85baaf0145b532ce3418b016cefca76f90648d6d 2>/dev/null || (git fetch origin 85baaf0145b532ce3418b016cefca76f90648d6d --depth=1 && git checkout 85baaf0145b532ce3418b016cefca76f90648d6d) || echo "WARN: commit 85baaf0145b532ce3418b016cefca76f90648d6d unreachable in https://github.com/capitan01R/ComfyUI-Krea2T-Enhancer, falling back to default branch HEAD")
RUN comfy node install --exit-on-fail comfyui-impact-subpack@1.3.2 || (echo "WARN: comfyui-impact-subpack@1.3.2 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail comfyui-impact-subpack)
RUN git clone https://github.com/MrWeazelHead/ComfyUI-MrWeazPhotoLab /comfyui/custom_nodes/ComfyUI-MrWeazPhotoLab

# download models into comfyui
RUN --mount=type=secret,id=hf_token BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN="$(cat /run/secrets/hf_token 2>/dev/null || true)" comfy model download --url 'https://huggingface.co/Comfy-Org/Krea-2/resolve/main/diffusion_models/krea2_turbo_fp8_scaled.safetensors' --relative-path models/diffusion_models --filename 'krea2_turbo_fp8_scaled.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN --mount=type=secret,id=hf_token BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN="$(cat /run/secrets/hf_token 2>/dev/null || true)" comfy model download --url 'https://huggingface.co/Comfy-Org/Qwen3-VL/resolve/main/text_encoders/qwen3vl_4b_fp8_scaled.safetensors' --relative-path models/text_encoders --filename 'qwen3vl_4b_fp8_scaled.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do comfy model download --url 'https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth' --relative-path models/ultralytics --filename 'sam_vit_b_01ec64.pth' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN --mount=type=secret,id=hf_token BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN="$(cat /run/secrets/hf_token 2>/dev/null || true)" comfy model download --url 'https://huggingface.co/Comfy-Org/Krea-2/resolve/main/vae/qwen_image_vae.safetensors' --relative-path models/vae --filename 'qwen_image_vae.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN --mount=type=secret,id=hf_token BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN="$(cat /run/secrets/hf_token 2>/dev/null || true)" comfy model download --url 'https://huggingface.co/conradlocke/krea2-identity-edit/resolve/main/krea2_identity_edit_v1_2.safetensors' --relative-path models/loras --filename 'krea2_identity_edit_v1_2.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN --mount=type=secret,id=hf_token BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN="$(cat /run/secrets/hf_token 2>/dev/null || true)" comfy model download --url 'https://huggingface.co/gemasai/4x_RealisticRescaler_100000_G/resolve/main/4x_RealisticRescaler_100000_G.pth' --relative-path models/upscale_models --filename '4x_RealisticRescaler_100000_G.pth' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN --mount=type=secret,id=hf_token BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN="$(cat /run/secrets/hf_token 2>/dev/null || true)" comfy model download --url 'https://huggingface.co/Bingsu/adetailer/resolve/main/person_yolov8m-seg.pt' --relative-path models/ultralytics --filename 'segm/person_yolov8m-seg.pt' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done

# copy all input data (like images or videos) into comfyui (uncomment and adjust if needed)
# COPY input/ /comfyui/input/

# user-provided inputs override the auto-generated placeholders above.
RUN wget --progress=dot:giga -O '/comfyui/input/meow47.jpeg' "https://cool-anteater-319.convex.cloud/api/storage/33818398-8fb6-43a7-872d-2e2fffed2a7f"


# Git-cloned nodes bypass comfy-cli's dependency installer. Install every
# custom-node requirements file into the runtime venv and fail the image build
# instead of shipping nodes that ComfyUI cannot import.
RUN set -eux; \
    for requirements in /comfyui/custom_nodes/*/requirements.txt; do \
        [ -f "$requirements" ] || continue; \
        uv pip install --python /opt/venv/bin/python -r "$requirements"; \
    done
