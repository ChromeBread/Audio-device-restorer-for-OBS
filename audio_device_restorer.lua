--[[
  Audio Device Restorer  -  OBS Studio Lua script  (v1.3.0)
  ------------------------------------------------------------
  EN: Save your audio devices (+ volume / mute) as presets and restore them
      with one click or a hotkey when OBS silently switches devices.
      Also: Video Capture Device audio, preset viewer for a Custom Browser Dock,
      export / import presets to a file (move to another PC).
  JP: 音声デバイス(と音量・ミュート)をプリセット保存し、勝手に変わったら
      ワンクリック/ホットキーで復元します。ビデオキャプチャデバイスの音声、
      カスタムブラウザドックへのプリセット表示、ファイルへの書き出し/読み込みに対応。

  License: MIT
--]]

obs = obslua

local VERSION = "1.3.0"
local BUILD_DATE = "2026-10-19"
local AUTHOR = "BlackDream feat. ChromeBread"

------------------------------------------------------------
-- i18n (EN / JP)
------------------------------------------------------------
local LANGS = {
  { "EN", "EN English" }, { "JP", "JP 日本語" }, { "KR", "KR 한국어" },
  { "ID", "ID Bahasa Indonesia" }, { "FR", "FR Français" }, { "TW", "TW 繁體中文" },
}
local lang = "EN"

local function valid_lang(l)
  for _, x in ipairs(LANGS) do
    if x[1] == l then return true end
  end
  return false
end

local function add_lang_items(list)
  for _, x in ipairs(LANGS) do
    obs.obs_property_list_add_string(list, x[2], x[1])
  end
end

local function X(kr, id, fr, tw) return { KR = kr, ID = id, FR = fr, TW = tw } end

-- English text -> translations (Japanese is passed inline at each tr() call)
local TR6 = {
  ["Filters (VST settings)"] = X("필터 (VST 설정)", "Filter (pengaturan VST)", "Filtres (réglages VST)", "濾鏡 (VST 設定)"),
  ["Export filter settings"] = X("필터 설정 내보내기", "Ekspor pengaturan filter", "Exporter les réglages de filtres", "匯出濾鏡設定"),
  ["Import filter settings"] = X("필터 설정 가져오기", "Impor pengaturan filter", "Importer les réglages de filtres", "匯入濾鏡設定"),
  ["Saves / applies the filter settings (incl. VST plugin settings) of audio sources, matched by source name. The VST plugin itself is NOT included - install it on the target PC."] = X("오디오 소스의 필터 설정(VST 플러그인 설정 포함)을 소스 이름 기준으로 저장/적용합니다. VST 플러그인 자체는 포함되지 않으므로 대상 PC에 설치해야 합니다.", "Menyimpan / menerapkan pengaturan filter (termasuk pengaturan plugin VST) sumber audio berdasarkan nama sumber. Plugin VST itu sendiri TIDAK disertakan - pasang di PC tujuan.", "Enregistre / applique les réglages de filtres (dont les réglages des plugins VST) des sources audio, selon le nom de la source. Le plugin VST lui-même n'est PAS inclus : installez-le sur le PC cible.", "依來源名稱儲存 / 套用音訊來源的濾鏡設定 (含 VST 外掛設定)。不包含 VST 外掛本身，請在目標電腦自行安裝。"),
  ["Show file paths…"] = X("파일 경로 표시…", "Tampilkan path file…", "Afficher les chemins de fichiers…", "顯示檔案路徑…"),
  ["Hide file paths"] = X("파일 경로 숨기기", "Sembunyikan path file", "Masquer les chemins de fichiers", "隱藏檔案路徑"),
  ["Privacy check"] = X("개인정보 확인", "Pemeriksaan privasi", "Vérification de confidentialité", "隱私確認"),
  ["Show folder / file paths? They can reveal personal information (e.g. your user name) if your screen is being shared. Check that you are NOT streaming or recording before you continue."] = X("폴더 / 파일 경로를 표시할까요? 화면을 공유 중이면 사용자 이름 등 개인정보가 노출될 수 있습니다. 방송 중이나 녹화 중이 아닌지 확인한 후 선택하세요.", "Tampilkan path folder / file? Path dapat mengungkap informasi pribadi (mis. nama pengguna Anda) jika layar Anda dibagikan. Pastikan Anda TIDAK sedang siaran atau merekam sebelum melanjutkan.", "Afficher les chemins de dossiers / fichiers ? Ils peuvent révéler des informations personnelles (ex. votre nom d'utilisateur) si votre écran est partagé. Vérifiez que vous ne diffusez PAS et n'enregistrez PAS avant de continuer.", "要顯示資料夾 / 檔案路徑嗎？若正在分享畫面，路徑可能洩漏個人資訊 (例如使用者名稱)。請先確認目前沒有在直播或錄影，再繼續。"),
  ["⚠ Streaming or recording is ACTIVE right now."] = X("⚠ 지금 방송 중이거나 녹화 중입니다.", "⚠ Siaran atau perekaman SEDANG berlangsung.", "⚠ Une diffusion ou un enregistrement est EN COURS.", "⚠ 目前正在直播或錄影中。"),
  ["Yes, show paths"] = X("예, 경로 표시", "Ya, tampilkan path", "Oui, afficher", "是，顯示路徑"),
  ["Show anyway (LIVE)"] = X("그래도 표시 (진행 중)", "Tetap tampilkan (LIVE)", "Afficher quand même (EN DIRECT)", "仍要顯示 (直播中)"),
  ["Cancel"] = X("취소", "Batal", "Annuler", "取消"),
  ["File paths are hidden for privacy. Use \"Show file paths…\" at the top."] = X("개인정보 보호를 위해 파일 경로를 숨겼습니다. 상단의 '파일 경로 표시…'를 사용하세요.", "Path file disembunyikan demi privasi. Gunakan \"Tampilkan path file…\" di bagian atas.", "Les chemins de fichiers sont masqués pour votre vie privée. Utilisez « Afficher les chemins de fichiers… » en haut.", "為保護隱私，檔案路徑已隱藏。請使用上方的「顯示檔案路徑…」。"),
  ["(hidden for privacy)"] = X("(개인정보 보호를 위해 숨김)", "(disembunyikan demi privasi)", "(masqué pour la confidentialité)", "(為保護隱私已隱藏)"),
  ["Presets"] = X("프리셋", "Preset", "Préréglages", "預設組"),
  ["Items to restore"] = X("복원할 항목", "Item yang dipulihkan", "Éléments à restaurer", "還原項目"),
  ["Automation"] = X("자동화", "Otomatisasi", "Automatisation", "自動化"),
  ["Dock"] = X("독", "Dock", "Dock", "Dock"),
  ["Move presets to another PC"] = X("다른 PC로 프리셋 이동", "Pindahkan preset ke PC lain", "Déplacer les préréglages vers un autre PC", "將預設組移至其他電腦"),
  ["Audio device"] = X("오디오 장치", "Perangkat audio", "Périphérique audio", "音訊裝置"),
  ["Balance"] = X("밸런스", "Balance", "Balance", "平衡"),
  ["Monitoring type"] = X("모니터링 유형", "Jenis monitoring", "Type de monitoring", "監聽類型"),
  ["Sync offset"] = X("동기화 오프셋", "Offset sinkron", "Décalage de synchro", "同步位移"),
  ["Export to (.json)"] = X("내보낼 위치 (.json)", "Ekspor ke (.json)", "Exporter vers (.json)", "匯出至 (.json)"),
  ["Import from (.json)"] = X("가져올 파일 (.json)", "Impor dari (.json)", "Importer depuis (.json)", "匯入來源 (.json)"),
  ["Exported filters of %d source(s) to %s"] = X("소스 %d개의 필터를 내보냈습니다: %s", "Filter dari %d sumber diekspor ke %s", "Filtres de %d source(s) exportés vers %s", "已將 %d 個來源的濾鏡匯出至 %s"),
  ["Imported filters into %d source(s) (%d not found)"] = X("소스 %d개에 필터를 가져왔습니다 (찾을 수 없음: %d개)", "Filter diimpor ke %d sumber (%d tidak ditemukan)", "Filtres importés dans %d source(s) (%d introuvable(s))", "已將濾鏡匯入 %d 個來源 (找不到 %d 個)"),
  ["Filter export/import is not supported by this OBS version."] = X("이 OBS 버전은 필터 내보내기/가져오기를 지원하지 않습니다.", "Versi OBS ini tidak mendukung ekspor/impor filter.", "Cette version d'OBS ne prend pas en charge l'export/import des filtres.", "此 OBS 版本不支援濾鏡匯出 / 匯入。"),
  ["Invalid filter file."] = X("올바르지 않은 필터 파일입니다.", "File filter tidak valid.", "Fichier de filtres invalide.", "濾鏡檔案格式不正確。"),
  ["Filters"] = X("필터", "Filter", "Filtres", "濾鏡"),
  ["Help"] = X("도움말", "Bantuan", "Aide", "說明"),
  ["Build date: "] = X("빌드 날짜: ", "Tanggal build: ", "Date de build : ", "建置日期: "),
  ["Author: "] = X("제작: ", "Pembuat: ", "Auteur : ", "製作: "),
  ["Folder: "] = X("폴더: ", "Folder: ", "Dossier : ", "資料夾: "),
  ["Related files (delete these when uninstalling):"] = X("관련 파일 (제거 시 삭제):", "File terkait (hapus saat uninstall):", "Fichiers associés (à supprimer lors de la désinstallation) :", "相關檔案 (解除安裝時請刪除):"),
  ["(script)"] = X("(스크립트)", "(skrip)", "(script)", "(腳本)"),
  ["(presets + auto-save slots, one file)"] = X("(프리셋 + 오토세이브 슬롯, 파일 1개)", "(preset + slot simpan otomatis, satu file)", "(préréglages + sauvegardes auto, un seul fichier)", "(預設組 + 自動存檔欄位，同一個檔案)"),
  ["(dock page, auto-generated)"] = X("(독 페이지, 자동 생성)", "(halaman dock, dibuat otomatis)", "(page du dock, générée automatiquement)", "(Dock 頁面，自動產生)"),
  ["(old presets, only if migrated)"] = X("(이전 프리셋, 이전한 경우에만)", "(preset lama, hanya jika dimigrasikan)", "(anciens préréglages, seulement si migrés)", "(舊預設組，僅在已移轉時存在)"),
  ["Exported .json files: wherever you saved them"] = X("내보낸 .json 파일: 저장한 위치", "File .json hasil ekspor: di lokasi tempat Anda menyimpan", "Fichiers .json exportés : là où vous les avez enregistrés", "匯出的 .json 檔案: 位於您儲存的位置"),
  ["If you added the dock, remove it under Docks > Custom Browser Docks."] = X("독을 추가했다면 독 > 사용자 지정 브라우저 독에서 삭제하세요.", "Jika Anda menambahkan dock, hapus di Docks > Custom Browser Docks.", "Si vous avez ajouté le dock, supprimez-le dans Docks > Docks de navigateur personnalisés.", "若已新增 Dock，請至 Docks > 自訂瀏覽器 Dock 移除。"),
  ["Hotkey and script settings are stored inside OBS and are removed together with the script."] = X("단축키와 스크립트 설정은 OBS 안에 저장되며 스크립트를 제거하면 함께 삭제됩니다.", "Hotkey dan pengaturan skrip tersimpan di dalam OBS dan ikut terhapus bersama skrip.", "Le raccourci et les réglages du script sont stockés dans OBS et supprimés avec le script.", "快速鍵與腳本設定儲存在 OBS 內，移除腳本時會一併刪除。"),
  ["Auto-save slots (latest 9; created before overwrite / delete / import)"] = X("오토세이브 슬롯 (최신 9개, 덮어쓰기 / 삭제 / 가져오기 전에 자동 생성)", "Slot simpan otomatis (9 terbaru; dibuat sebelum timpa / hapus / impor)", "Sauvegardes auto (9 dernières ; créées avant écrasement / suppression / import)", "自動存檔欄位 (最新 9 個；在覆寫 / 刪除 / 匯入前自動建立)"),
  ["Import presets (merge)"] = X("프리셋 가져오기 (병합)", "Impor preset (gabung)", "Importer (fusion)", "匯入預設組 (合併)"),
  ["Export all presets"] = X("모든 프리셋 내보내기", "Ekspor semua preset", "Exporter les préréglages", "匯出所有預設組"),
  ["Dock URL"] = X("독 URL", "URL dock", "URL du dock", "Dock 網址"),
  ["Auto-restore on OBS start"] = X("OBS 시작 시 자동 복원", "Auto-pulih saat OBS mulai", "Restaurer au démarrage", "OBS 啟動時自動還原"),
  ["Auto-restore on change"] = X("변경 감지 시 자동 복원", "Auto-pulih saat berubah", "Restauration auto", "偵測變更時自動還原"),
  ["Check differences"] = X("차이 확인", "Periksa perbedaan", "Vérifier les différences", "檢查差異"),
  ["Recover from auto-save slot"] = X("슬롯에서 복구", "Pulihkan dari slot", "Récupérer depuis le slot", "從欄位復原"),
  ["Delete preset"] = X("프리셋 삭제", "Hapus preset", "Supprimer", "刪除預設組"),
  ["▶ Restore preset"] = X("▶ 프리셋 복원", "▶ Pulihkan preset", "▶ Restaurer", "▶ 還原預設組"),
  ["Preset name"] = X("프리셋 이름", "Nama preset", "Nom du préréglage", "預設組名稱"),
  ["Auto-save slot created: %s"] = X("오토세이브 슬롯을 만들었습니다: %s", "Slot simpan otomatis dibuat: %s", "Emplacement de sauvegarde auto créé : %s", "已建立自動存檔欄位: %s"),
  ["Recovered preset '%s' from auto-save slot"] = X("오토세이브 슬롯에서 프리셋 '%s'을(를) 복구했습니다", "Preset '%s' dipulihkan dari slot simpan otomatis", "Préréglage « %s » récupéré depuis la sauvegarde auto", "已從自動存檔欄位復原預設組「%s」"),
  ["No auto-save slot selected."] = X("오토세이브 슬롯이 선택되지 않았습니다.", "Belum ada slot simpan otomatis yang dipilih.", "Aucun emplacement de sauvegarde auto sélectionné.", "尚未選取自動存檔欄位。"),
  ["Auto-save slots"] = X("오토세이브 슬롯", "Slot simpan otomatis", "Emplacements de sauvegarde auto", "自動存檔欄位"),
  ["Language"] = X("언어", "Bahasa", "Langue", "語言"),
  ["Preset"] = X("프리셋", "Preset", "Préréglage", "預設組"),
  ["Save current state"] = X("현재 상태 저장", "Simpan kondisi saat ini", "Enregistrer l'état actuel", "儲存目前狀態"),
  ["Status"] = X("상태", "Status", "État", "狀態"),
  ["Export file (.json)"] = X("내보낼 파일 (.json)", "File ekspor (.json)", "Fichier d'export (.json)", "匯出檔案 (.json)"),
  ["Import file (.json)"] = X("가져올 파일 (.json)", "File impor (.json)", "Fichier d'import (.json)", "匯入檔案 (.json)"),
  ["Cannot write preset file: "] = X("프리셋 파일을 쓸 수 없습니다: ", "Tidak dapat menulis file preset: ", "Impossible d'écrire le fichier de préréglages : ", "無法寫入預設組檔案: "),
  ["Preset file is broken; starting empty"] = X("프리셋 파일이 손상되어 빈 상태로 시작합니다", "File preset rusak; memulai dari kosong", "Le fichier de préréglages est corrompu ; démarrage à vide", "預設組檔案已損毀，將從空白開始"),
  ["Migrated presets from the old file"] = X("이전 파일에서 프리셋을 이전했습니다", "Preset dimigrasikan dari file lama", "Préréglages migrés depuis l'ancien fichier", "已從舊檔案移轉預設組"),
  ["Preset not found: "] = X("프리셋을 찾을 수 없습니다: ", "Preset tidak ditemukan: ", "Préréglage introuvable : ", "找不到預設組: "),
  ["Source not found (skipped): "] = X("소스를 찾을 수 없습니다 (건너뜀): ", "Sumber tidak ditemukan (dilewati): ", "Source introuvable (ignorée) : ", "找不到來源 (已略過): "),
  ["Restored device of '%s': %s"] = X("'%s'의 장치를 복원했습니다: %s", "Perangkat '%s' dipulihkan: %s", "Périphérique de « %s » restauré : %s", "已還原「%s」的裝置: %s"),
  ["Saved device '%s' for '%s' is not connected"] = X("저장된 장치 '%s'이(가) 연결되어 있지 않습니다 (소스: '%s')", "Perangkat tersimpan '%s' tidak terhubung (sumber: '%s')", "Le périphérique enregistré « %s » n'est pas connecté (source : « %s »)", "已儲存的裝置「%s」未連接 (來源: 「%s」)"),
  ["No preset to restore. Save the current state first."] = X("복원할 프리셋이 없습니다. 먼저 현재 상태를 저장하세요.", "Tidak ada preset untuk dipulihkan. Simpan kondisi saat ini terlebih dahulu.", "Aucun préréglage à restaurer. Enregistrez d'abord l'état actuel.", "沒有可還原的預設組，請先儲存目前狀態。"),
  ["Restored preset '%s' (devices changed: %d / failed: %d)"] = X("프리셋 '%s'을(를) 복원했습니다 (변경된 장치: %d / 실패: %d)", "Preset '%s' dipulihkan (perangkat diubah: %d / gagal: %d)", "Préréglage « %s » restauré (périphériques modifiés : %d / échecs : %d)", "已還原預設組「%s」(變更的裝置: %d / 失敗: %d)"),
  ["Audio In"] = X("오디오 입력", "Input audio", "Entrée audio", "音訊輸入"),
  ["Audio Out"] = X("오디오 출력", "Output audio", "Sortie audio", "音訊輸出"),
  ["Video Device"] = X("비디오 장치", "Perangkat video", "Périphérique vidéo", "視訊裝置"),
  ["No presets saved yet."] = X("저장된 프리셋이 없습니다.", "Belum ada preset tersimpan.", "Aucun préréglage enregistré.", "尚未儲存任何預設組。"),
  ["Source"] = X("소스", "Sumber", "Source", "來源"),
  ["Device"] = X("장치", "Perangkat", "Périphérique", "裝置"),
  ["Volume"] = X("볼륨", "Volume", "Volume", "音量"),
  ["Mute"] = X("음소거", "Bisu", "Muet", "靜音"),
  ["now: "] = X("현재: ", "sekarang: ", "actuel : ", "目前: "),
  ["MUTED"] = X("음소거됨", "BISU", "MUET", "已靜音"),
  ["Preset '%s' (saved: %s / %d sources)"] = X("프리셋 '%s' (저장: %s / 소스 %d개)", "Preset '%s' (disimpan: %s / %d sumber)", "Préréglage « %s » (enregistré : %s / %d sources)", "預設組「%s」(儲存: %s / %d 個來源)"),
  ["→ Current devices match the saved state."] = X("→ 현재 장치가 저장된 상태와 일치합니다.", "→ Perangkat saat ini sesuai dengan kondisi tersimpan.", "→ Les périphériques actuels correspondent à l'état enregistré.", "→ 目前裝置與已儲存狀態相符。"),
  ["x %s : now '%s' -> saved '%s'"] = X("× %s : 현재 '%s' → 저장 '%s'", "× %s : sekarang '%s' → tersimpan '%s'", "× %s : actuel « %s » → enregistré « %s »", "× %s : 目前「%s」→ 已儲存「%s」"),
  ["Device change detected. Restoring automatically."] = X("장치 변경이 감지되었습니다. 자동으로 복원합니다.", "Perubahan perangkat terdeteksi. Memulihkan otomatis.", "Changement de périphérique détecté. Restauration automatique.", "偵測到裝置變更，正在自動還原。"),
  ["Running startup restore"] = X("시작 시 복원을 실행합니다", "Menjalankan pemulihan saat startup", "Exécution de la restauration au démarrage", "正在執行啟動時還原"),
  ["Choose an export file first."] = X("먼저 내보낼 파일을 지정하세요.", "Pilih file ekspor terlebih dahulu.", "Choisissez d'abord un fichier d'export.", "請先指定匯出檔案。"),
  ["Exported %d preset(s) to %s"] = X("프리셋 %d개를 내보냈습니다: %s", "%d preset diekspor ke %s", "%d préréglage(s) exporté(s) vers %s", "已將 %d 個預設組匯出至 %s"),
  ["Export failed: "] = X("내보내기 실패: ", "Ekspor gagal: ", "Échec de l'export : ", "匯出失敗: "),
  [" (try a path without special characters)"] = X(" (특수 문자가 없는 경로를 사용해 보세요)", " (coba path tanpa karakter khusus)", " (essayez un chemin sans caractères spéciaux)", " (請改用不含特殊字元的路徑)"),
  ["Choose a file to import first."] = X("먼저 가져올 파일을 지정하세요.", "Pilih file untuk diimpor terlebih dahulu.", "Choisissez d'abord un fichier à importer.", "請先指定要匯入的檔案。"),
  ["Cannot read file: "] = X("파일을 읽을 수 없습니다: ", "Tidak dapat membaca file: ", "Impossible de lire le fichier : ", "無法讀取檔案: "),
  ["Invalid preset file."] = X("올바르지 않은 프리셋 파일입니다.", "File preset tidak valid.", "Fichier de préréglages invalide.", "預設組檔案格式不正確。"),
  ["Imported %d preset(s). Devices are matched by ID, then by name."] = X("프리셋 %d개를 가져왔습니다. 장치는 ID, 이름 순으로 대조합니다.", "%d preset diimpor. Perangkat dicocokkan berdasarkan ID, lalu nama.", "%d préréglage(s) importé(s). Les périphériques sont appariés par ID, puis par nom.", "已匯入 %d 個預設組。裝置會先依 ID、再依名稱比對。"),
  ["Saved preset '%s' (%d sources)"] = X("프리셋 '%s'을(를) 저장했습니다 (소스 %d개)", "Preset '%s' disimpan (%d sumber)", "Préréglage « %s » enregistré (%d sources)", "已儲存預設組「%s」(%d 個來源)"),
  ["Deleted preset '%s'"] = X("프리셋 '%s'을(를) 삭제했습니다", "Preset '%s' dihapus", "Préréglage « %s » supprimé", "已刪除預設組「%s」"),
  ["Restore audio devices (Audio Device Restorer)"] = X("오디오 장치 복원 (Audio Device Restorer)", "Pulihkan perangkat audio (Audio Device Restorer)", "Restaurer les périphériques audio (Audio Device Restorer)", "還原音訊裝置 (Audio Device Restorer)"),
}

local function tr(en, jp)
  if lang == "EN" then return en end
  if lang == "JP" then return jp end
  local t = TR6[en]
  return (t and t[lang]) or en
end

local function default_lang()
  local ok, loc = pcall(obs.obs_get_locale)
  if ok and type(loc) == "string" then
    loc = loc:lower()
    local p = loc:sub(1, 2)
    if p == "ja" then return "JP" end
    if p == "ko" then return "KR" end
    if p == "id" then return "ID" end
    if p == "fr" then return "FR" end
    if loc:find("^zh") and (loc:find("tw") or loc:find("hk") or loc:find("hant")) then return "TW" end
  end
  return "EN"
end

local LABELS = {
  restore_filters = { "Filters", "フィルター" },
  g_filters = { "Filters (VST settings)", "フィルター(VST設定)" },
  btn_filter_export = { "Export filter settings", "フィルター設定を書き出す" },
  btn_filter_import = { "Import filter settings", "フィルター設定を読み込む" },
  g_paths_confirm = { "Privacy check", "プライバシー確認" },
  btn_paths_yes = { "Yes, show paths", "はい、表示する" },
  btn_paths_no = { "Cancel", "キャンセル" },
  g_presets = { "Presets", "プリセット" },
  g_restore = { "Items to restore", "復元する項目" },
  g_autosave = { "Auto-save slots", "オートセーブスロット" },
  g_auto = { "Automation", "自動化" },
  g_dock = { "Dock", "ドック" },
  g_transfer = { "Move presets to another PC", "別PCへのプリセット移行" },
  restore_device = { "Audio device", "音声デバイス" },
  restore_volume = { "Volume", "音量" },
  restore_mute = { "Mute", "ミュート" },
  restore_balance = { "Balance", "バランス" },
  restore_monitoring = { "Monitoring type", "モニタリング" },
  restore_sync = { "Sync offset", "同期オフセット" },
  filter_export_path = { "Export to (.json)", "書き出し先 (.json)" },
  filter_import_path = { "Import from (.json)", "読み込み元 (.json)" },
  btn_help = { "Help", "ヘルプ" },
  lang            = { "Language", "言語" },
  preset          = { "Preset", "プリセット" },
  btn_restore     = { "▶ Restore preset", "▶ プリセットを復元" },
  new_name        = { "Preset name", "保存名" },
  btn_save        = { "Save current state", "現在の状態を保存" },
  btn_delete      = { "Delete preset", "プリセットを削除" },
  btn_recover     = { "Recover from auto-save slot", "スロットから復元" },
  btn_check       = { "Check differences", "差分を確認" },
  status          = { "Status", "状態" },
  auto_restore    = { "Auto-restore on change", "変更検知で自動復元" },
  restore_on_start= { "Auto-restore on OBS start", "OBS起動時に自動復元" },
  dock_url        = { "Dock URL", "ドックURL" },
  export_path     = { "Export file (.json)", "書き出し先 (.json)" },
  btn_export      = { "Export all presets", "全プリセットを書き出す" },
  import_path     = { "Import file (.json)", "読み込み元 (.json)" },
  btn_import      = { "Import presets (merge)", "プリセットを読み込む" },
}

local function apply_labels(containers)
  for id, t in pairs(LABELS) do
    for _, props in ipairs(containers) do
      local p = obs.obs_properties_get(props, id)
      if p then
        obs.obs_property_set_description(p, tr(t[1], t[2]))
        break
      end
    end
  end
end

------------------------------------------------------------
-- 対象ソースの定義
--   key        : デバイスIDが入る設定キー
--   extra_bool : 一緒に保存/復元する bool 設定
--   extra_int  : 一緒に保存/復元する int 設定
------------------------------------------------------------
local SOURCE_DEFS = {
  wasapi_input_capture     = { key = "device_id", kind = "in" },
  wasapi_output_capture    = { key = "device_id", kind = "out" },
  coreaudio_input_capture  = { key = "device_id", kind = "in" },
  coreaudio_output_capture = { key = "device_id", kind = "out" },
  pulse_input_capture      = { key = "device_id", kind = "in" },
  pulse_output_capture     = { key = "device_id", kind = "out" },
  alsa_input_capture       = { key = "device_id", kind = "in" },
  -- Video Capture Device (DirectShow) の音声
  dshow_input = {
    key = "audio_device_id", kind = "video",
    extra_bool = { "use_custom_audio_device" },
    extra_int = { "audio_output_mode" },
  },
}

local cur_settings = nil
local hotkey_id = obs.OBS_INVALID_HOTKEY_ID
local store = { version = 1, presets = {}, autosaves = {}, last = "" }
local last_auto_restore = 0
local last_dock_html = nil

-- ログ(スクリプトログ画面が配信に映る可能性がある)ではフォルダ部分を伏せる
local function mask_paths(s)
  s = tostring(s)
  s = s:gsub("%a:[/\\][^\n]*[/\\]", "…/")
  s = s:gsub("/Users/[^\n]*/", "…/")
  s = s:gsub("/home/[^\n]*/", "…/")
  return s
end

local function log(level, msg)
  obs.script_log(level, "[AudioDeviceRestorer] " .. mask_paths(msg))
end

local function safe(fn, ...)
  local ok, v = pcall(fn, ...)
  if ok then return v end
  return nil
end

------------------------------------------------------------
-- ファイルI/O (UTF-8パス対応を優先して試す)
------------------------------------------------------------
local function read_file(path)
  if obs.os_quick_read_utf8_file then
    local ok, s = pcall(obs.os_quick_read_utf8_file, path)
    if ok and type(s) == "string" and s ~= "" then return s end
  end
  local f = io.open(path, "rb")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return s
end

local function write_file(path, text)
  if obs.os_quick_write_utf8_file then
    local ok, r = pcall(obs.os_quick_write_utf8_file, path, text, #text, false)
    if ok and r then return true end
  end
  local f, err = io.open(path, "wb")
  if not f then return false, err end
  f:write(text)
  f:close()
  return true
end

------------------------------------------------------------
-- 小さな JSON エンコーダ / デコーダ
------------------------------------------------------------
local function utf8_char(cp)
  if cp < 0x80 then return string.char(cp)
  elseif cp < 0x800 then return string.char(0xC0 + math.floor(cp / 0x40), 0x80 + cp % 0x40)
  elseif cp < 0x10000 then
    return string.char(0xE0 + math.floor(cp / 0x1000), 0x80 + math.floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40)
  else
    return string.char(0xF0 + math.floor(cp / 0x40000), 0x80 + math.floor(cp / 0x1000) % 0x40,
      0x80 + math.floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40)
  end
end

local ESC = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t" }

local function json_encode(v, indent)
  indent = indent or ""
  local t = type(v)
  if t == "nil" then return "null"
  elseif t == "boolean" then return tostring(v)
  elseif t == "number" then
    if v ~= v or v == math.huge or v == -math.huge then return "null" end
    if v == math.floor(v) and math.abs(v) < 1e15 then return string.format("%d", v) end
    return string.format("%.12g", v)
  elseif t == "string" then
    local s = v:gsub('[%c"\\]', function(c) return ESC[c] or string.format("\\u%04x", c:byte()) end)
    return '"' .. s .. '"'
  elseif t == "table" then
    local ni = indent .. "  "
    local n = #v
    local count = 0
    for _ in pairs(v) do count = count + 1 end
    local parts = {}
    if count == 0 or (n > 0 and n == count) then
      for i = 1, n do parts[#parts + 1] = ni .. json_encode(v[i], ni) end
      if #parts == 0 then return "[]" end
      return "[\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "]"
    end
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = tostring(k) end
    table.sort(keys)
    for _, k in ipairs(keys) do
      local val = v[k]
      if val == nil then val = v[tonumber(k)] end
      parts[#parts + 1] = ni .. json_encode(k) .. ": " .. json_encode(val, ni)
    end
    return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
  end
  return "null"
end

local function json_decode(s)
  local pos = 1
  local function skip() pos = s:find("[^ \t\r\n]", pos) or (#s + 1) end
  local parse_value

  local function parse_string()
    pos = pos + 1
    local buf = {}
    while true do
      local c = s:sub(pos, pos)
      if c == "" then error("unterminated string") end
      if c == '"' then pos = pos + 1; break
      elseif c == "\\" then
        local e = s:sub(pos + 1, pos + 1)
        if e == "u" then
          local cp = tonumber(s:sub(pos + 2, pos + 5), 16) or 63
          pos = pos + 6
          if cp >= 0xD800 and cp < 0xDC00 and s:sub(pos, pos + 1) == "\\u" then
            local lo = tonumber(s:sub(pos + 2, pos + 5), 16) or 0xDC00
            pos = pos + 6
            cp = 0x10000 + (cp - 0xD800) * 0x400 + (lo - 0xDC00)
          end
          buf[#buf + 1] = utf8_char(cp)
        else
          local map = { n = "\n", t = "\t", r = "\r", b = "\b", f = "\f" }
          buf[#buf + 1] = map[e] or e
          pos = pos + 2
        end
      else
        local run = s:match('^[^"\\]+', pos)
        buf[#buf + 1] = run
        pos = pos + #run
      end
    end
    return table.concat(buf)
  end

  function parse_value()
    skip()
    local c = s:sub(pos, pos)
    if c == "{" then
      pos = pos + 1
      local obj = {}
      skip()
      if s:sub(pos, pos) == "}" then pos = pos + 1; return obj end
      while true do
        skip()
        if s:sub(pos, pos) ~= '"' then error("object key expected at " .. pos) end
        local k = parse_string()
        skip()
        if s:sub(pos, pos) ~= ":" then error("':' expected at " .. pos) end
        pos = pos + 1
        obj[k] = parse_value()
        skip()
        local d = s:sub(pos, pos)
        pos = pos + 1
        if d == "}" then break end
        if d ~= "," then error("',' or '}' expected at " .. (pos - 1)) end
      end
      return obj
    elseif c == "[" then
      pos = pos + 1
      local arr = {}
      skip()
      if s:sub(pos, pos) == "]" then pos = pos + 1; return arr end
      while true do
        arr[#arr + 1] = parse_value()
        skip()
        local d = s:sub(pos, pos)
        pos = pos + 1
        if d == "]" then break end
        if d ~= "," then error("',' or ']' expected at " .. (pos - 1)) end
      end
      return arr
    elseif c == '"' then
      return parse_string()
    elseif s:sub(pos, pos + 3) == "true" then pos = pos + 4; return true
    elseif s:sub(pos, pos + 4) == "false" then pos = pos + 5; return false
    elseif s:sub(pos, pos + 3) == "null" then pos = pos + 4; return nil
    else
      local num = s:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
      if not num or num == "" then error("unexpected character at " .. pos) end
      pos = pos + #num
      return tonumber(num)
    end
  end

  local v = parse_value()
  return v
end

------------------------------------------------------------
-- プリセット保存 (JSON)
------------------------------------------------------------
local function data_path() return script_path() .. "audio_device_presets.json" end
local function old_data_path() return script_path() .. "audio_device_presets.luadata" end
local function dock_path() return script_path() .. "audio_presets_dock.html" end

local function save_store()
  local ok, err = write_file(data_path(), json_encode(store))
  if not ok then
    log(obs.LOG_ERROR, tr("Cannot write preset file: ", "保存ファイルを書き込めません: ") .. tostring(err))
  end
  return ok
end

local function load_store()
  local text = read_file(data_path())
  if text then
    local ok, data = pcall(json_decode, text)
    if ok and type(data) == "table" then
      store = data
      store.presets = store.presets or {}
      store.last = store.last or ""
      return
    end
    log(obs.LOG_WARNING, tr("Preset file is broken; starting empty", "プリセットファイルが壊れています。空の状態で開始します"))
  end
  -- 旧バージョン(.luadata)からの移行
  local chunk = loadfile(old_data_path())
  if chunk then
    local ok, data = pcall(chunk)
    if ok and type(data) == "table" and data.presets then
      store = data
      store.version = 1
      save_store()
      log(obs.LOG_INFO, tr("Migrated presets from the old file", "旧形式のプリセットを移行しました"))
    end
  end
end

------------------------------------------------------------
-- デバイス一覧
------------------------------------------------------------
local function list_devices(src, key)
  local out = {}
  local props = obs.obs_source_properties(src)
  if props then
    local p = obs.obs_properties_get(props, key)
    if p then
      local n = obs.obs_property_list_item_count(p)
      for i = 0, n - 1 do
        out[#out + 1] = {
          name = obs.obs_property_list_item_name(p, i),
          value = obs.obs_property_list_item_string(p, i),
        }
      end
    end
    obs.obs_properties_destroy(props)
  end
  return out
end

local function device_name_of(src, key, id)
  if id == nil or id == "" then return "" end
  for _, d in ipairs(list_devices(src, key)) do
    if d.value == id then return d.name end
  end
  return id
end

------------------------------------------------------------
-- フィルター(VST含む)のバックアップ/復元 (obs_source_backup_filters を利用)
local function backup_filters(src)
  if not obs.obs_source_backup_filters then return nil, 0 end
  local ok, arr = pcall(obs.obs_source_backup_filters, src)
  if not ok or arr == nil then return nil, 0 end
  local n = obs.obs_data_array_count(arr)
  local root = obs.obs_data_create()
  obs.obs_data_set_array(root, "filters", arr)
  local json = obs.obs_data_get_json(root)
  obs.obs_data_array_release(arr)
  obs.obs_data_release(root)
  return json, n
end

local function restore_filters(src, json)
  if not obs.obs_source_restore_filters or type(json) ~= "string" or json == "" then return false end
  local root = obs.obs_data_create_from_json(json)
  if root == nil then return false end
  local arr = obs.obs_data_get_array(root, "filters")
  local ok = false
  if arr ~= nil then
    ok = pcall(obs.obs_source_restore_filters, src, arr)
    obs.obs_data_array_release(arr)
  end
  obs.obs_data_release(root)
  return ok
end

-- 現在の状態を収集
------------------------------------------------------------
local function collect()
  local list = {}
  local sources = obs.obs_enum_sources()
  if sources then
    for _, src in ipairs(sources) do
      local id = obs.obs_source_get_id(src)
      local def = SOURCE_DEFS[id]
      if def then
        local st = obs.obs_source_get_settings(src)
        local entry = {
          name = obs.obs_source_get_name(src),
          id = id,
          kind = def.kind,
          dev_key = def.key,
          device_id = obs.obs_data_get_string(st, def.key),
          volume = obs.obs_source_get_volume(src),
          muted = obs.obs_source_muted(src),
          balance = safe(obs.obs_source_get_balance_value, src) or 0.5,
          monitoring = safe(obs.obs_source_get_monitoring_type, src) or 0,
          sync = safe(obs.obs_source_get_sync_offset, src) or 0,
        }
        if def.extra_bool or def.extra_int then
          entry.extra = {}
          for _, k in ipairs(def.extra_bool or {}) do entry.extra[k] = obs.obs_data_get_bool(st, k) end
          for _, k in ipairs(def.extra_int or {}) do entry.extra[k] = obs.obs_data_get_int(st, k) end
        end
        obs.obs_data_release(st)
        entry.device_name = device_name_of(src, def.key, entry.device_id)
        entry.filters_json, entry.filter_count = backup_filters(src)
        list[#list + 1] = entry
      end
    end
    obs.source_list_release(sources)
  end
  return list
end

------------------------------------------------------------
-- 差分チェック
------------------------------------------------------------
local function diff_preset(name)
  local p = store.presets[name]
  if not p or not p.sources then return nil end
  local diffs = {}
  for _, e in ipairs(p.sources) do
    local src = obs.obs_get_source_by_name(e.name)
    if src then
      local key = e.dev_key or "device_id"
      local st = obs.obs_source_get_settings(src)
      local cur = obs.obs_data_get_string(st, key)
      local differs = (e.device_id ~= nil and e.device_id ~= "" and cur ~= e.device_id)
      if e.extra then
        for k, v in pairs(e.extra) do
          if type(v) == "boolean" and obs.obs_data_get_bool(st, k) ~= v then differs = true end
          if type(v) == "number" and obs.obs_data_get_int(st, k) ~= v then differs = true end
        end
      end
      obs.obs_data_release(st)
      if differs then
        diffs[#diffs + 1] = {
          name = e.name,
          saved = e.device_name or e.device_id,
          current = device_name_of(src, key, cur),
        }
      end
      obs.obs_source_release(src)
    end
  end
  return diffs
end

------------------------------------------------------------
-- 復元
------------------------------------------------------------
local function get_bool(key, default)
  if cur_settings == nil then return default end
  return obs.obs_data_get_bool(cur_settings, key)
end

local function restore_preset(name)
  local p = store.presets[name]
  if not p or not p.sources then
    log(obs.LOG_WARNING, tr("Preset not found: ", "プリセットがありません: ") .. tostring(name))
    return 0, 0
  end
  local do_dev = get_bool("restore_device", true)
  local do_vol = get_bool("restore_volume", true)
  local do_mute = get_bool("restore_mute", true)
  local do_bal = get_bool("restore_balance", true)
  local do_mon = get_bool("restore_monitoring", true)
  local do_sync = get_bool("restore_sync", true)
  local do_flt = get_bool("restore_filters", false)
  local ok_count, ng_count = 0, 0

  for _, e in ipairs(p.sources) do
    local src = obs.obs_get_source_by_name(e.name)
    if not src then
      log(obs.LOG_WARNING, tr("Source not found (skipped): ", "ソースが見つかりません(スキップ): ") .. e.name)
      ng_count = ng_count + 1
    else
      local key = e.dev_key or "device_id"
      local st = obs.obs_source_get_settings(src)
      local changed = false

      -- 追加設定 (ビデオキャプチャデバイスの「カスタム音声デバイスを使う」等)
      if do_dev and e.extra then
        for k, v in pairs(e.extra) do
          if type(v) == "boolean" and obs.obs_data_get_bool(st, k) ~= v then
            obs.obs_data_set_bool(st, k, v); changed = true
          elseif type(v) == "number" and obs.obs_data_get_int(st, k) ~= v then
            obs.obs_data_set_int(st, k, v); changed = true
          end
        end
      end

      -- デバイス
      if do_dev and e.device_id and e.device_id ~= "" then
        local cur = obs.obs_data_get_string(st, key)
        if cur ~= e.device_id then
          local devs = list_devices(src, key)
          local target = nil
          if e.device_id == "default" then target = "default" end
          if not target then
            for _, d in ipairs(devs) do if d.value == e.device_id then target = d.value break end end
          end
          -- 別PCから移行した場合: IDが違うので表示名で探す
          if not target and e.device_name and e.device_name ~= "" then
            for _, d in ipairs(devs) do if d.name == e.device_name then target = d.value break end end
          end
          if not target and #devs == 0 then target = e.device_id end   -- 一覧が取れない場合はそのまま設定
          if target then
            obs.obs_data_set_string(st, key, target)
            changed = true
            log(obs.LOG_INFO, string.format(tr("Restored device of '%s': %s", "'%s' のデバイスを戻しました: %s"),
              e.name, e.device_name or e.device_id))
            ok_count = ok_count + 1
          else
            log(obs.LOG_WARNING, string.format(
              tr("Saved device '%s' for '%s' is not connected", "保存デバイス『%s』は現在接続されていません (ソース: %s)"),
              e.device_name or e.device_id, e.name))
            ng_count = ng_count + 1
          end
        end
      end

      if changed then obs.obs_source_update(src, st) end
      obs.obs_data_release(st)

      if do_vol and e.volume then safe(obs.obs_source_set_volume, src, e.volume) end
      if do_mute and e.muted ~= nil then safe(obs.obs_source_set_muted, src, e.muted) end
      if do_bal and e.balance then safe(obs.obs_source_set_balance_value, src, e.balance) end
      if do_mon and e.monitoring then safe(obs.obs_source_set_monitoring_type, src, e.monitoring) end
      if do_sync and e.sync then safe(obs.obs_source_set_sync_offset, src, e.sync) end
      if do_flt and e.filters_json then restore_filters(src, e.filters_json) end
      obs.obs_source_release(src)
    end
  end
  return ok_count, ng_count
end

local function current_preset_name()
  local n = ""
  if cur_settings then n = obs.obs_data_get_string(cur_settings, "preset") end
  if n == "" or not store.presets[n] then n = store.last end
  return n
end

local function restore_current()
  local name = current_preset_name()
  if name == "" or not store.presets[name] then
    log(obs.LOG_WARNING, tr("No preset to restore. Save the current state first.",
      "復元できるプリセットがありません。先に「現在の状態を保存」してください"))
    return
  end
  local ok, ng = restore_preset(name)
  log(obs.LOG_INFO, string.format(tr("Restored preset '%s' (devices changed: %d / failed: %d)",
    "プリセット『%s』を復元しました (変更したデバイス: %d / 失敗: %d)"), name, ok, ng))
end

------------------------------------------------------------
-- ドック用HTML (カスタムブラウザドックで file:/// として表示)
------------------------------------------------------------
local function esc(s)
  return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end

local function to_db(v)
  if v == nil then return "-" end
  if v <= 0 then return "-inf dB" end
  return string.format("%.1f dB", 20 * math.log(v) / math.log(10))
end

local function sorted_names()
  local names = {}
  for n in pairs(store.presets) do names[#names + 1] = n end
  table.sort(names)
  return names
end

local function kind_label(k)
  if k == "in" then return tr("Audio In", "音声入力") end
  if k == "out" then return tr("Audio Out", "音声出力") end
  if k == "video" then return tr("Video Device", "ビデオデバイス") end
  return "-"
end

local function build_dock_html()
  local sel = current_preset_name()
  local names = sorted_names()
  local o = {}
  o[#o + 1] = '<!DOCTYPE html><html><head><meta charset="utf-8"><meta http-equiv="refresh" content="3">'
  o[#o + 1] = "<style>body{margin:0;padding:8px;background:#272a36;color:#e6e6e6;font:12px 'Segoe UI','Meiryo','Malgun Gothic','Microsoft JhengHei',sans-serif}"
    .. "h2{font-size:13px;margin:10px 0 4px;padding:4px 6px;background:#31364a;border-radius:4px}"
    .. "h2.sel{background:#2f5d8a}h2 small{font-weight:normal;color:#aab;margin-left:6px}"
    .. "table{border-collapse:collapse;width:100%}th,td{text-align:left;padding:3px 5px;border-bottom:1px solid #3a3f55;vertical-align:top}"
    .. "th{color:#9ab;font-weight:normal}tr.bad td{background:#5a2a2a}.warn{color:#ff9a9a}.mute{color:#ffb86b}"
    .. ".ok{color:#8fd18f}.empty{color:#99a;padding:10px}</style></head><body>"

  if #names == 0 then
    o[#o + 1] = '<p class="empty">' .. esc(tr("No presets saved yet.", "保存されたプリセットはありません。")) .. "</p>"
  end

  for _, name in ipairs(names) do
    local p = store.presets[name]
    local mism = {}
    if name == sel then
      for _, d in ipairs(diff_preset(name) or {}) do mism[d.name] = d.current end
    end
    o[#o + 1] = string.format('<h2 class="%s">%s<small>%s</small></h2>',
      name == sel and "sel" or "", esc(name), esc(p.saved or ""))
    o[#o + 1] = "<table><tr><th>" .. esc(tr("Source", "ソース")) .. "</th><th>" .. esc(tr("Device", "デバイス"))
      .. "</th><th>" .. esc(tr("Volume", "音量")) .. "</th><th>" .. esc(tr("Mute", "ミュート"))
      .. "</th><th>" .. esc(tr("Filters", "フィルター")) .. "</th></tr>"
    for _, e in ipairs(p.sources or {}) do
      local bad = mism[e.name] ~= nil
      local dev = esc(e.device_name or e.device_id or "-")
      if bad then
        dev = dev .. '<br><span class="warn">⚠ ' .. esc(tr("now: ", "現在: ")) .. esc(mism[e.name]) .. "</span>"
      end
      o[#o + 1] = string.format('<tr class="%s"><td>%s<br><small>%s</small></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>',
        bad and "bad" or "", esc(e.name), esc(kind_label(e.kind)), dev, esc(to_db(e.volume)),
        e.muted and ('<span class="mute">' .. esc(tr("MUTED", "ミュート")) .. "</span>") or '<span class="ok">ON</span>', tostring(e.filter_count or 0))
    end
    o[#o + 1] = "</table>"
  end
  if store.autosaves and #store.autosaves > 0 then
    o[#o + 1] = "<h2>" .. esc(tr("Auto-save slots", "オートセーブスロット")) .. "</h2><table>"
    for _, a in ipairs(store.autosaves) do
      o[#o + 1] = "<tr><td>" .. esc(a.title) .. "</td></tr>"
    end
    o[#o + 1] = "</table>"
  end
  o[#o + 1] = "</body></html>"
  return table.concat(o, "\n")
end

local function update_dock()
  local html = build_dock_html()
  if html ~= last_dock_html then
    if write_file(dock_path(), html) then last_dock_html = html end
  end
end

local function file_url(path)
  path = path:gsub("\\", "/")
  local enc = path:gsub("[^%w%-%._~/:]", function(c) return string.format("%%%02X", c:byte()) end)
  if not enc:match("^/") then enc = "/" .. enc end
  return "file://" .. enc
end

------------------------------------------------------------
-- UI ヘルパ
------------------------------------------------------------
local MAX_AUTOSAVE = 9

-- 上書き・削除・読み込みで失われるプリセットを、タイムスタンプ付きで退避する(最新9件)
local function push_autosave(name)
  local p = store.presets[name]
  if not p then return end
  store.autosaves = store.autosaves or {}
  local stamp = os.date("%Y-%m-%d %H:%M:%S")
  local base = stamp .. "  " .. name
  local title, n = base, 1
  local function exists(t)
    for _, a in ipairs(store.autosaves) do if a.title == t then return true end end
    return false
  end
  while exists(title) do
    n = n + 1
    title = base .. " (" .. n .. ")"
  end
  table.insert(store.autosaves, 1, { title = title, name = name, stamp = stamp, preset = p })
  while #store.autosaves > MAX_AUTOSAVE do table.remove(store.autosaves) end
  log(obs.LOG_INFO, string.format(tr("Auto-save slot created: %s", "オートセーブスロットを作成しました: %s"), title))
end

local function fill_autosave_list(list)
  obs.obs_property_list_clear(list)
  for _, a in ipairs(store.autosaves or {}) do
    obs.obs_property_list_add_string(list, a.title, a.title)
  end
end

local function fill_preset_list(list)
  obs.obs_property_list_clear(list)
  for _, n in ipairs(sorted_names()) do
    obs.obs_property_list_add_string(list, n, n)
  end
end

local function set_filter_hint(settings)
  obs.obs_data_set_string(settings, "filter_hint",
    tr("Saves / applies the filter settings (incl. VST plugin settings) of audio sources, matched by source name. The VST plugin itself is NOT included - install it on the target PC.",
       "音声ソースのフィルター設定(VSTプラグインの設定を含む)を、ソース名で照合して保存/適用します。VSTプラグイン本体は含まれません。移行先のPCにインストールしてください。"))
end

local function set_autosave_hint(settings)
  obs.obs_data_set_string(settings, "autosave_hint",
    tr("Auto-save slots (latest 9; created before overwrite / delete / import)",
       "オートセーブスロット (最新9件。上書き・削除・読み込みの直前に自動作成)"))
end

local refs = {}   -- 現在表示中のプロパティ画面の一覧への参照

local function refill_all()
  if refs.preset then fill_preset_list(refs.preset) end
  if refs.autosave then fill_autosave_list(refs.autosave) end
end

local function build_status()
  local name = current_preset_name()
  local p = store.presets[name]
  if not p then return tr("No presets saved yet.", "保存されたプリセットはありません。") end
  local lines = { string.format(tr("Preset '%s' (saved: %s / %d sources)", "プリセット『%s』 (保存: %s / %d 個のソース)"),
    name, p.saved or "?", #(p.sources or {})) }
  local diffs = diff_preset(name) or {}
  if #diffs == 0 then
    lines[#lines + 1] = tr("→ Current devices match the saved state.", "→ 現在のデバイスは保存状態と一致しています。")
  else
    for _, d in ipairs(diffs) do
      lines[#lines + 1] = string.format(tr("x %s : now '%s' -> saved '%s'", "× %s : 現在『%s』 → 保存『%s』"),
        d.name, d.current, d.saved)
    end
  end
  return table.concat(lines, "\n")
end

local function refresh_status(settings)
  local s = build_status()
  obs.obs_data_set_string(settings, "status", s)
  log(obs.LOG_INFO, "\n" .. s)
  update_dock()
end

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

------------------------------------------------------------
-- 自動監視
------------------------------------------------------------
local function watch_tick()
  update_dock()
  if cur_settings == nil or not obs.obs_data_get_bool(cur_settings, "auto_restore") then return end
  local name = current_preset_name()
  if name == "" then return end
  local diffs = diff_preset(name)
  if diffs and #diffs > 0 and os.time() - last_auto_restore >= 5 then
    last_auto_restore = os.time()
    log(obs.LOG_WARNING, tr("Device change detected. Restoring automatically.", "音声デバイスの変更を検知。自動で復元します"))
    restore_current()
  end
end

local function startup_restore()
  obs.timer_remove(startup_restore)
  if cur_settings and obs.obs_data_get_bool(cur_settings, "restore_on_start") then
    log(obs.LOG_INFO, tr("Running startup restore", "起動時の自動復元を実行します"))
    restore_current()
  end
end

local function on_frontend_event(event)
  if event == obs.OBS_FRONTEND_EVENT_FINISHED_LOADING then
    obs.timer_add(startup_restore, 3000)
  end
end

------------------------------------------------------------
-- エクスポート / インポート
------------------------------------------------------------
local function do_export()
  local path = trim(obs.obs_data_get_string(cur_settings, "export_path"))
  if path == "" then
    log(obs.LOG_WARNING, tr("Choose an export file first.", "書き出し先ファイルを指定してください"))
    return
  end
  if not path:lower():match("%.json$") then path = path .. ".json" end
  local ok, err = write_file(path, json_encode(store))
  if ok then
    log(obs.LOG_INFO, string.format(tr("Exported %d preset(s) to %s", "%d 個のプリセットを書き出しました: %s"),
      #sorted_names(), path))
  else
    log(obs.LOG_ERROR, tr("Export failed: ", "書き出しに失敗: ") .. tostring(err)
      .. tr(" (try a path without special characters)", " (日本語などを含まないパスを試してください)"))
  end
end

local function do_import()
  local path = trim(obs.obs_data_get_string(cur_settings, "import_path"))
  if path == "" then
    log(obs.LOG_WARNING, tr("Choose a file to import first.", "読み込むファイルを指定してください"))
    return false
  end
  local text = read_file(path)
  if not text then
    log(obs.LOG_ERROR, tr("Cannot read file: ", "ファイルを読み込めません: ") .. path)
    return false
  end
  local ok, data = pcall(json_decode, text)
  if not ok or type(data) ~= "table" or type(data.presets) ~= "table" then
    log(obs.LOG_ERROR, tr("Invalid preset file.", "プリセットファイルの形式が正しくありません"))
    return false
  end
  local n = 0
  for name, preset in pairs(data.presets) do
    if type(preset) == "table" and type(preset.sources) == "table" then
      if store.presets[name] then push_autosave(name) end
      store.presets[name] = preset
      n = n + 1
      if store.last == "" then store.last = name end
    end
  end
  save_store()
  log(obs.LOG_INFO, string.format(tr("Imported %d preset(s). Devices are matched by ID, then by name.",
    "%d 個のプリセットを読み込みました。デバイスはID→表示名の順で照合します"), n))
  return true
end

------------------------------------------------------------
-- OBS Script API
------------------------------------------------------------
local function is_audio_source(src)
  local id = obs.obs_source_get_id(src)
  if id == "scene" or id == "group" then return false end
  local flags = obs.obs_source_get_output_flags(src)
  return math.floor(flags / obs.OBS_SOURCE_AUDIO) % 2 == 1
end

local function do_filter_export()
  local path = trim(obs.obs_data_get_string(cur_settings, "filter_export_path"))
  if path == "" then
    log(obs.LOG_WARNING, tr("Choose an export file first.", "書き出し先ファイルを指定してください"))
    return
  end
  if not obs.obs_source_backup_filters then
    log(obs.LOG_WARNING, tr("Filter export/import is not supported by this OBS version.", "このOBSのバージョンではフィルターの書き出し/読み込みに対応していません"))
    return
  end
  if not path:lower():match("%.json$") then path = path .. ".json" end
  local list = {}
  local sources = obs.obs_enum_sources()
  if sources then
    for _, src in ipairs(sources) do
      if is_audio_source(src) then
        local json, n = backup_filters(src)
        if json and n > 0 then
          list[#list + 1] = { name = obs.obs_source_get_name(src), id = obs.obs_source_get_id(src),
            count = n, filters_json = json }
        end
      end
    end
    obs.source_list_release(sources)
  end
  local data = { version = 1, kind = "filters", saved = os.date("%Y-%m-%d %H:%M:%S"), sources = list }
  local ok, err = write_file(path, json_encode(data))
  if ok then
    log(obs.LOG_INFO, string.format(tr("Exported filters of %d source(s) to %s", "%d 個のソースのフィルターを書き出しました: %s"), #list, path))
  else
    log(obs.LOG_ERROR, tr("Export failed: ", "書き出しに失敗: ") .. tostring(err))
  end
end

local function do_filter_import()
  local path = trim(obs.obs_data_get_string(cur_settings, "filter_import_path"))
  if path == "" then
    log(obs.LOG_WARNING, tr("Choose a file to import first.", "読み込むファイルを指定してください"))
    return
  end
  if not obs.obs_source_restore_filters then
    log(obs.LOG_WARNING, tr("Filter export/import is not supported by this OBS version.", "このOBSのバージョンではフィルターの書き出し/読み込みに対応していません"))
    return
  end
  local text = read_file(path)
  if not text then
    log(obs.LOG_ERROR, tr("Cannot read file: ", "ファイルを読み込めません: ") .. path)
    return
  end
  local ok, data = pcall(json_decode, text)
  if not ok or type(data) ~= "table" or type(data.sources) ~= "table" then
    log(obs.LOG_ERROR, tr("Invalid filter file.", "フィルターファイルの形式が正しくありません"))
    return
  end
  local done, missing = 0, 0
  for _, e in ipairs(data.sources) do
    local src = obs.obs_get_source_by_name(e.name or "")
    if src then
      if restore_filters(src, e.filters_json) then done = done + 1 end
      obs.obs_source_release(src)
    else
      missing = missing + 1
      log(obs.LOG_WARNING, tr("Source not found (skipped): ", "ソースが見つかりません(スキップ): ") .. tostring(e.name))
    end
  end
  log(obs.LOG_INFO, string.format(tr("Imported filters into %d source(s) (%d not found)", "%d 個のソースにフィルターを読み込みました (見つからない: %d 個)"), done, missing))
end

-- プライバシー: フォルダ/ファイルの場所は、確認を通すまで画面に出さない
local paths_visible = false
local confirm_open = false

local PATH_IDS = { "filter_export_path", "filter_import_path", "export_path", "import_path", "dock_url" }
local HINT_IDS = { "paths_hint_f", "paths_hint_d", "paths_hint_t" }

local function is_live()
  return obs.obs_frontend_streaming_active() or obs.obs_frontend_recording_active()
end

local function find_prop(containers, id)
  for _, c in ipairs(containers) do
    local p = obs.obs_properties_get(c, id)
    if p then return p end
  end
  return nil
end

local function build_help_text()
  local lines = {
    "Audio Device Restorer v" .. VERSION,
    tr("Build date: ", "ビルド日: ") .. BUILD_DATE,
    tr("Author: ", "製作: ") .. AUTHOR,
    tr("Folder: ", "フォルダ: ") .. (paths_visible and script_path() or tr("(hidden for privacy)", "(プライバシー保護のため非表示)")),
    "",
    tr("Related files (delete these when uninstalling):", "関連ファイル (削除時の目印):"),
    "  audio_device_restorer.lua  " .. tr("(script)", "(スクリプト本体)"),
    "  audio_device_presets.json  " .. tr("(presets + auto-save slots, one file)", "(プリセット+オートセーブスロット。1ファイル)"),
    "  audio_presets_dock.html  " .. tr("(dock page, auto-generated)", "(ドック用ページ。自動生成)"),
    "  audio_device_presets.luadata  " .. tr("(old presets, only if migrated)", "(旧形式のプリセット。移行した場合のみ)"),
    "  " .. tr("Exported .json files: wherever you saved them", "書き出した .json: 保存した場所"),
    "",
    tr("If you added the dock, remove it under Docks > Custom Browser Docks.", "ドックを追加した場合は、ドック > カスタムブラウザドック から削除してください"),
    tr("Hotkey and script settings are stored inside OBS and are removed together with the script.", "ホットキーとスクリプト設定はOBS内に保存され、スクリプトの削除と一緒に消えます"),
  }
  return table.concat(lines, "\n")
end

local function set_help_text(settings)
  obs.obs_data_set_string(settings, "help_text", build_help_text())
end

local help_open = false

local function apply_visibility(containers, settings)
  for _, id in ipairs(PATH_IDS) do
    local p = find_prop(containers, id)
    if p then obs.obs_property_set_visible(p, paths_visible) end
  end
  for _, id in ipairs(HINT_IDS) do
    local p = find_prop(containers, id)
    if p then obs.obs_property_set_visible(p, not paths_visible) end
  end
  local g = find_prop(containers, "g_paths_confirm")
  if g then obs.obs_property_set_visible(g, confirm_open) end

  local live = is_live()
  local b = find_prop(containers, "btn_paths")
  if b then
    obs.obs_property_set_description(b, paths_visible
      and tr("Hide file paths", "ファイルの場所を隠す")
      or tr("Show file paths…", "ファイルの場所を表示…"))
  end
  local yes = find_prop(containers, "btn_paths_yes")
  if yes then
    obs.obs_property_set_description(yes, live
      and tr("Show anyway (LIVE)", "それでも表示する (配信/録画中)")
      or tr("Yes, show paths", "はい、表示する"))
  end

  if settings then
    local t = tr("Show folder / file paths? They can reveal personal information (e.g. your user name) if your screen is being shared. Check that you are NOT streaming or recording before you continue.",
                 "フォルダ・ファイルの場所を表示しますか？ 画面を共有していると、ユーザー名などの個人情報が見えてしまう恐れがあります。配信中・録画中ではないことを確認してから選択してください。")
    if live then
      t = tr("⚠ Streaming or recording is ACTIVE right now.", "⚠ 現在、配信中または録画中です。") .. "\n" .. t
    end
    obs.obs_data_set_string(settings, "paths_confirm", t)
    local h = tr("File paths are hidden for privacy. Use \"Show file paths…\" at the top.",
                 "ファイルの場所はプライバシー保護のため非表示です。上の「ファイルの場所を表示…」を使ってください。")
    for _, k in ipairs({ "paths_hint_f", "paths_hint_d", "paths_hint_t" }) do
      obs.obs_data_set_string(settings, k, h)
    end
    set_help_text(settings)
  end
end

function script_description()
  return "<h3>Audio Device Restorer</h3>"
    .. "<p>Save audio devices / volumes as presets and restore them with one click or a hotkey.<br>"
    .. "Language: use the EN / JP / KR / ID / FR / TW selector below.</p>"
    .. "<p><small>Hotkey: Settings &gt; Hotkeys &gt; \"Restore audio devices\"</small></p>"
end

function script_defaults(settings)
  obs.obs_data_set_default_string(settings, "lang", default_lang())
  obs.obs_data_set_default_bool(settings, "restore_device", true)
  obs.obs_data_set_default_bool(settings, "restore_volume", true)
  obs.obs_data_set_default_bool(settings, "restore_mute", true)
  obs.obs_data_set_default_bool(settings, "restore_balance", true)
  obs.obs_data_set_default_bool(settings, "restore_monitoring", true)
  obs.obs_data_set_default_bool(settings, "restore_sync", true)
  obs.obs_data_set_default_bool(settings, "restore_filters", false)
  obs.obs_data_set_default_bool(settings, "auto_restore", false)
  obs.obs_data_set_default_bool(settings, "restore_on_start", false)
  obs.obs_data_set_default_string(settings, "new_name", "default")
end

function script_update(settings)
  cur_settings = settings
  local l = obs.obs_data_get_string(settings, "lang")
  if valid_lang(l) then lang = l end
end

function script_properties()
  local props = obs.obs_properties_create()
  local containers = { props }
  help_open = false
  refs = {}

  -- 言語選択 (グループ化しない)
  local ll = obs.obs_properties_add_list(props, "lang", "Language", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
  add_lang_items(ll)
  obs.obs_property_set_modified_callback(ll, function(_, prop, settings)
    local v = obs.obs_data_get_string(settings, "lang")
    if valid_lang(v) then lang = v end
    apply_labels(containers)
    set_autosave_hint(settings)
    set_filter_hint(settings)
    set_help_text(settings)
    apply_visibility(containers, settings)
    refresh_status(settings)
    return true
  end)

  -- プライバシー: ファイルの場所の表示/非表示
  paths_visible = false
  confirm_open = false
  obs.obs_properties_add_button(props, "btn_paths", "btn_paths", function()
    if paths_visible then
      paths_visible = false
      confirm_open = false
    else
      confirm_open = true
    end
    apply_visibility(containers, cur_settings)
    return true
  end)
  local gp = obs.obs_properties_create()
  containers[#containers + 1] = gp
  obs.obs_properties_add_text(gp, "paths_confirm", "", obs.OBS_TEXT_INFO)
  obs.obs_properties_add_button(gp, "btn_paths_yes", "btn_paths_yes", function()
    paths_visible = true
    confirm_open = false
    apply_visibility(containers, cur_settings)
    return true
  end)
  obs.obs_properties_add_button(gp, "btn_paths_no", "btn_paths_no", function()
    confirm_open = false
    apply_visibility(containers, cur_settings)
    return true
  end)
  obs.obs_properties_add_group(props, "g_paths_confirm", "g_paths_confirm", obs.OBS_GROUP_NORMAL, gp)

  ------------------------------------------------------------
  -- グループ1: プリセット
  ------------------------------------------------------------
  local g1 = obs.obs_properties_create()
  containers[#containers + 1] = g1
  refs.preset = obs.obs_properties_add_list(g1, "preset", "preset", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
  fill_preset_list(refs.preset)

  obs.obs_properties_add_button(g1, "btn_restore", "btn_restore", function()
    restore_current()
    if cur_settings then refresh_status(cur_settings) end
    return true
  end)

  obs.obs_properties_add_text(g1, "new_name", "new_name", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_button(g1, "btn_save", "btn_save", function()
    local name = trim(obs.obs_data_get_string(cur_settings, "new_name"))
    if name == "" then name = obs.obs_data_get_string(cur_settings, "preset") end
    if name == "" then name = "default" end
    if store.presets[name] then push_autosave(name) end
    local sources = collect()
    store.presets[name] = { saved = os.date("%Y-%m-%d %H:%M:%S"), sources = sources }
    store.last = name
    if save_store() then
      log(obs.LOG_INFO, string.format(tr("Saved preset '%s' (%d sources)", "プリセット『%s』を保存しました (%d 個のソース)"), name, #sources))
    end
    obs.obs_data_set_string(cur_settings, "preset", name)
    refill_all()
    refresh_status(cur_settings)
    return true
  end)

  obs.obs_properties_add_button(g1, "btn_delete", "btn_delete", function()
    local name = obs.obs_data_get_string(cur_settings, "preset")
    if name ~= "" and store.presets[name] then
      push_autosave(name)
      store.presets[name] = nil
      if store.last == name then store.last = "" end
      save_store()
      obs.obs_data_set_string(cur_settings, "preset", "")
      log(obs.LOG_INFO, string.format(tr("Deleted preset '%s'", "プリセット『%s』を削除しました"), name))
    end
    refill_all()
    refresh_status(cur_settings)
    return true
  end)

  obs.obs_properties_add_button(g1, "btn_check", "btn_check", function()
    refresh_status(cur_settings)
    return true
  end)
  obs.obs_properties_add_text(g1, "status", "status", obs.OBS_TEXT_INFO)
  obs.obs_properties_add_group(props, "g_presets", "g_presets", obs.OBS_GROUP_NORMAL, g1)

  ------------------------------------------------------------
  -- グループ2: 復元する項目 (明示)
  ------------------------------------------------------------
  local g2 = obs.obs_properties_create()
  containers[#containers + 1] = g2
  obs.obs_properties_add_bool(g2, "restore_device", "restore_device")
  obs.obs_properties_add_bool(g2, "restore_volume", "restore_volume")
  obs.obs_properties_add_bool(g2, "restore_mute", "restore_mute")
  obs.obs_properties_add_bool(g2, "restore_balance", "restore_balance")
  obs.obs_properties_add_bool(g2, "restore_monitoring", "restore_monitoring")
  obs.obs_properties_add_bool(g2, "restore_sync", "restore_sync")
  obs.obs_properties_add_bool(g2, "restore_filters", "restore_filters")
  obs.obs_properties_add_group(props, "g_restore", "g_restore", obs.OBS_GROUP_NORMAL, g2)

  ------------------------------------------------------------
  -- グループ3: オートセーブスロット
  ------------------------------------------------------------
  local g3 = obs.obs_properties_create()
  containers[#containers + 1] = g3
  obs.obs_properties_add_text(g3, "autosave_hint", "", obs.OBS_TEXT_INFO)
  if cur_settings then set_autosave_hint(cur_settings) end
  refs.autosave = obs.obs_properties_add_list(g3, "autosave_slot", "", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
  fill_autosave_list(refs.autosave)
  obs.obs_properties_add_button(g3, "btn_recover", "btn_recover", function()
    local title = obs.obs_data_get_string(cur_settings, "autosave_slot")
    local slot = nil
    for _, a in ipairs(store.autosaves or {}) do
      if a.title == title then slot = a break end
    end
    if not slot then
      log(obs.LOG_WARNING, tr("No auto-save slot selected.", "オートセーブスロットが選択されていません"))
      return false
    end
    local name, preset = slot.name, slot.preset
    if store.presets[name] then push_autosave(name) end   -- 復元自体も元に戻せるように
    store.presets[name] = preset
    store.last = name
    save_store()
    obs.obs_data_set_string(cur_settings, "preset", name)
    log(obs.LOG_INFO, string.format(tr("Recovered preset '%s' from auto-save slot", "オートセーブからプリセット『%s』を復元しました"), name))
    refill_all()
    refresh_status(cur_settings)
    return true
  end)
  obs.obs_properties_add_group(props, "g_autosave", "g_autosave", obs.OBS_GROUP_NORMAL, g3)

  ------------------------------------------------------------
  -- グループ4: 自動化
  ------------------------------------------------------------
  local g4 = obs.obs_properties_create()
  containers[#containers + 1] = g4
  obs.obs_properties_add_bool(g4, "auto_restore", "auto_restore")
  obs.obs_properties_add_bool(g4, "restore_on_start", "restore_on_start")
  obs.obs_properties_add_group(props, "g_auto", "g_auto", obs.OBS_GROUP_NORMAL, g4)

  ------------------------------------------------------------
  -- グループ5: フィルター(VST)のバックアップ
  ------------------------------------------------------------
  local g5 = obs.obs_properties_create()
  containers[#containers + 1] = g5
  obs.obs_properties_add_text(g5, "filter_hint", "", obs.OBS_TEXT_INFO)
  if cur_settings then set_filter_hint(cur_settings) end
  obs.obs_properties_add_text(g5, "paths_hint_f", "", obs.OBS_TEXT_INFO)
  obs.obs_properties_add_path(g5, "filter_export_path", "filter_export_path", obs.OBS_PATH_FILE_SAVE, "JSON (*.json)", nil)
  obs.obs_properties_add_button(g5, "btn_filter_export", "btn_filter_export", function()
    do_filter_export()
    return false
  end)
  obs.obs_properties_add_path(g5, "filter_import_path", "filter_import_path", obs.OBS_PATH_FILE, "JSON (*.json);;All Files (*.*)", nil)
  obs.obs_properties_add_button(g5, "btn_filter_import", "btn_filter_import", function()
    do_filter_import()
    return false
  end)
  obs.obs_properties_add_group(props, "g_filters", "g_filters", obs.OBS_GROUP_NORMAL, g5)

  ------------------------------------------------------------
  -- グループ6: ドック
  ------------------------------------------------------------
  local g6 = obs.obs_properties_create()
  containers[#containers + 1] = g6
  obs.obs_properties_add_text(g6, "paths_hint_d", "", obs.OBS_TEXT_INFO)
  obs.obs_properties_add_text(g6, "dock_url", "dock_url", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_group(props, "g_dock", "g_dock", obs.OBS_GROUP_NORMAL, g6)

  ------------------------------------------------------------
  -- グループ7: 別PCへの移行
  ------------------------------------------------------------
  local g7 = obs.obs_properties_create()
  containers[#containers + 1] = g7
  obs.obs_properties_add_text(g7, "paths_hint_t", "", obs.OBS_TEXT_INFO)
  obs.obs_properties_add_path(g7, "export_path", "export_path", obs.OBS_PATH_FILE_SAVE, "JSON (*.json)", nil)
  obs.obs_properties_add_button(g7, "btn_export", "btn_export", function()
    do_export()
    return false
  end)
  obs.obs_properties_add_path(g7, "import_path", "import_path", obs.OBS_PATH_FILE, "JSON (*.json);;All Files (*.*)", nil)
  obs.obs_properties_add_button(g7, "btn_import", "btn_import", function()
    if do_import() then
      refill_all()
      if cur_settings then refresh_status(cur_settings) end
      return true
    end
    return false
  end)
  obs.obs_properties_add_group(props, "g_transfer", "g_transfer", obs.OBS_GROUP_NORMAL, g7)

  ------------------------------------------------------------
  -- Help (控えめ。押すと情報が展開される)
  ------------------------------------------------------------
  obs.obs_properties_add_button(props, "btn_help", "btn_help", function(p)
    help_open = not help_open
    local hp = obs.obs_properties_get(p, "help_text")
    if hp then obs.obs_property_set_visible(hp, help_open) end
    return true
  end)
  local hp = obs.obs_properties_add_text(props, "help_text", "", obs.OBS_TEXT_INFO)
  obs.obs_property_set_visible(hp, false)
  if cur_settings then set_help_text(cur_settings) end

  apply_labels(containers)
  apply_visibility(containers, cur_settings)
  return props
end

function script_save(settings)
  local arr = obs.obs_hotkey_save(hotkey_id)
  obs.obs_data_set_array(settings, "hotkey_restore", arr)
  obs.obs_data_array_release(arr)
end

function script_load(settings)
  cur_settings = settings
  local l = obs.obs_data_get_string(settings, "lang")
  if valid_lang(l) then lang = l else lang = default_lang() end

  load_store()
  store.autosaves = store.autosaves or {}
  obs.obs_data_set_string(settings, "dock_url", file_url(dock_path()))
  update_dock()

  hotkey_id = obs.obs_hotkey_register_frontend(
    "audio_device_restorer.restore",
    tr("Restore audio devices (Audio Device Restorer)", "音声デバイスを復元 (Audio Device Restorer)"),
    function(pressed)
      if pressed then restore_current() end
    end)
  local arr = obs.obs_data_get_array(settings, "hotkey_restore")
  obs.obs_hotkey_load(hotkey_id, arr)
  obs.obs_data_array_release(arr)

  obs.obs_frontend_add_event_callback(on_frontend_event)
  obs.timer_add(watch_tick, 3000)
  log(obs.LOG_INFO, "v" .. VERSION .. " loaded")
end

function script_unload()
  obs.timer_remove(watch_tick)
  obs.timer_remove(startup_restore)
  obs.obs_frontend_remove_event_callback(on_frontend_event)
end
