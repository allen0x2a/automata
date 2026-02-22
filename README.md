# Automata

A collection of automation scripts, build guides, and system configuration playbooks.

## Contents

| Playbook | Description |
|----------|-------------|
| [`remote-access/ssh/`](remote-access/ssh/) | Ed25519 key generation, deployment, and per-target `~/.ssh/config` management. |
| [`builds/ffmpeg/`](builds/ffmpeg/) | Build FFmpeg from source with custom codec and hardware acceleration support. |
| [`builds/opencv/`](builds/opencv/) | Build OpenCV from source with FFmpeg integration and GPU acceleration. |

## Structure

```
automata/
├── README.md
├── remote-access/
│   └── ssh/
│       ├── README.md
│       └── ssh-key-setup.sh
└── builds/
    ├── ffmpeg/
    │   ├── README.md
    │   └── ...
    └── opencv/
        ├── README.md
        └── ...
```

## Usage

Each directory contains its own README and usage examples.
