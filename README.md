# Unity PBR Shader Project

A custom Physically Based Rendering (PBR) shader implementation for Unity.

## Features
- Custom PBR shader (MyLit.shader)
- Support for metallic/smoothness workflow
- Example materials and models included
- Sample scene demonstrating shader usage

## Project Structure
```
Assets/
├── Shader/              # Shader source files
│   ├── MyLit.shader     # Main shader file
│   └── MyLitShaderFile.hlsl
├── Materials/           # Example materials
├── Models/              # 3D model assets
└── Scenes/              # Sample scene
```

## Getting Started
1. Clone this repository
2. Open in Unity (2021.3 or later recommended)
3. Open SampleScene.unity to see the shader in action

## Shader Usage
Apply the "MyLit" shader to your materials:
1. Create a new material
2. Select "MyLit" from the shader dropdown
3. Adjust metallic/smoothness parameters as needed

## Requirements
- Unity 2021.3 or later
- Universal Render Pipeline (URP)

## License
MIT
