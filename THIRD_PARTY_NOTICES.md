# Share signature font

The bundled `FridgeSignature.ttf` is a glyph subset of LXGW WenKai TC Regular, containing only `created by 冰箱贴`. Copyright 2024 The LXGW WenKai Project Authors. Licensed under SIL Open Font License 1.1. The complete license is bundled in `entry/src/main/resources/rawfile/fonts/LXGWWenKaiTC-OFL.txt`. Source: https://github.com/google/fonts/tree/main/ofl/lxgwwenkaitc and https://github.com/lxgw/LxgwWenkaiTC.

# FluidGradient

The background renderer in `BackgroundPalette.ets` adapts the radial core, layered compositing and blur design of [Cindori/FluidGradient](https://github.com/Cindori/FluidGradient). The ArkUI compositor implementation in `FluidBackdrop.ets` animates radial layers. The bitmap renderer produces a deterministic pose for FormKit and export. Neither implementation uses Apple CoreAnimation.

MIT License

Copyright (c) 2022 Cindori

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
