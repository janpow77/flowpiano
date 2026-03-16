#include <windows.h>
#include <unknwn.h>

#include "SourceGuids.h"

// This DLL is intentionally only a native scaffold.
// The next Windows-only step is to replace the placeholder exports and class-factory path
// with a real Media Foundation source implementing IMFMediaSource / IMFMediaEventGenerator.

extern "C" BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID reserved) {
    (void)instance;
    (void)reason;
    (void)reserved;
    return TRUE;
}

extern "C" HRESULT __stdcall DllCanUnloadNow() {
    return S_FALSE;
}

extern "C" HRESULT __stdcall DllGetClassObject(REFCLSID clsid, REFIID iid, void** object) {
    (void)iid;

    if (object == nullptr) {
        return E_POINTER;
    }

    *object = nullptr;

    if (clsid == CLSID_FlowPianoVirtualCameraSource) {
        // A real class factory must be provided here once the Media Foundation source exists.
        return CLASS_E_CLASSNOTAVAILABLE;
    }

    return CLASS_E_CLASSNOTAVAILABLE;
}

extern "C" HRESULT __stdcall DllRegisterServer() {
    return SELFREG_E_CLASS;
}

extern "C" HRESULT __stdcall DllUnregisterServer() {
    return SELFREG_E_CLASS;
}
