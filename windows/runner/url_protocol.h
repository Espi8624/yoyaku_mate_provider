#include <windows.h>
#include <string>

void RegisterUrlProtocol(const std::wstring& scheme, const std::wstring& app_name) {
    std::wstring scheme_key_path = L"SOFTWARE\\Classes\\" + scheme;
    HKEY scheme_key;
    if (RegCreateKeyExW(HKEY_CURRENT_USER, scheme_key_path.c_str(), 0, NULL, 0, KEY_WRITE, NULL, &scheme_key, NULL) == ERROR_SUCCESS) {
        std::wstring url_protocol_value = L"URL:" + app_name + L" Protocol";
        RegSetValueExW(scheme_key, L"", 0, REG_SZ, (const BYTE*)url_protocol_value.c_str(), DWORD((url_protocol_value.size() + 1) * sizeof(wchar_t)));
        RegSetValueExW(scheme_key, L"URL Protocol", 0, REG_SZ, (const BYTE*)L"", sizeof(L""));

        HKEY command_key;
        std::wstring command_key_path = scheme_key_path + L"\\shell\\open\\command";
        if (RegCreateKeyExW(HKEY_CURRENT_USER, command_key_path.c_str(), 0, NULL, 0, KEY_WRITE, NULL, &command_key, NULL) == ERROR_SUCCESS) {
            wchar_t module_path[MAX_PATH];
            GetModuleFileNameW(NULL, module_path, MAX_PATH);
            std::wstring command_value = L"\"" + std::wstring(module_path) + L"\" \"%1\"";
            RegSetValueExW(command_key, L"", 0, REG_SZ, (const BYTE*)command_value.c_str(), DWORD((command_value.size() + 1) * sizeof(wchar_t)));
            RegCloseKey(command_key);
        }
        RegCloseKey(scheme_key);
    }
}