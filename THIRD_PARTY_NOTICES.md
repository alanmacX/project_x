# FluidGradient

The background renderer in `BackgroundPalette.ets` adapts the radial core, layered compositing and blur design of [Cindori/FluidGradient](https://github.com/Cindori/FluidGradient). The bitmap renderer produces a fixed, blurred light-fold pose shared by the App, FormKit and export. The App displays this bitmap without a separate animated layer. This implementation does not use Apple CoreAnimation.

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

# School timetable adapters

The optional in-app school import bundles the MIT-licensed qingyu_warehouse / shiguang_warehouse adapter snapshot `42474728fd1d6537c6ece020aa16d117c18d2d2d` from https://github.com/Mutx163/qingyu_warehouse . Copyright (c) 2025 星河欲转. The complete MIT text is included at `entry/src/main/resources/rawfile/schools/LICENSE.txt`, with provenance and exclusions in `SOURCE.txt`. Adapter scripts run only after the user selects a school and requests a read in its academic web page. FridgeMemo supplies the ArkWeb host, limited preview bridge and local timetable validation. The catalogue is a bundled snapshot, not a guarantee that every school's current website can be imported.
