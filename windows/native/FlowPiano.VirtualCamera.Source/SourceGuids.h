#pragma once

#include <guiddef.h>

// This CLSID must stay aligned with the managed virtual-camera bridge manifest.
DEFINE_GUID(CLSID_FlowPianoVirtualCameraSource,
    0x5f7b1f3a, 0x4fb8, 0x4a35, 0xa1, 0xf5, 0x3b, 0x7e, 0xb4, 0xb0, 0x6e, 0x41);

inline constexpr wchar_t kFlowPianoVirtualCameraFriendlyName[] = L"FlowPiano Virtual Camera";
