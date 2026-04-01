FROM nvidia/cuda:12.0.1-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/conda/bin:$PATH"
ENV PYTHONPATH="/app"

# System libraries required by vips and snappy
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    libvips \
    libsnappy1v5 \
    libglib2.0-0 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Miniconda (no compiler needed — installs prebuilt binaries)
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-py310_24.1.2-0-Linux-x86_64.sh -O /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -b -p /opt/conda \
    && rm /tmp/miniconda.sh \
    && conda clean -afy

# Conda environment (CUDA 12 cupy/cucim + all inference deps)
COPY environment_inference.yaml /tmp/environment_inference.yaml
RUN conda env create -f /tmp/environment_inference.yaml \
    && conda clean -afy

# Activate environment for all subsequent commands
ENV PATH="/opt/conda/envs/cellvit_env/bin:$PATH"

# PyTorch (not in conda env — install separately with correct CUDA index)
RUN pip install --no-cache-dir \
    torch==2.2.2+cu120 \
    torchvision==0.17.2+cu120 \
    --index-url https://download.pytorch.org/whl/cu120

# Copy source code
COPY . /app
WORKDIR /app
