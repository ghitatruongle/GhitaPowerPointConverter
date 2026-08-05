// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Ghita PPT Converter';

  @override
  String get homeTitle => 'Trang Chủ';

  @override
  String get editorTitle => 'Trình Soạn Thảo';

  @override
  String get projectsTitle => 'Dự Án';

  @override
  String get templatesTitle => 'Mẫu Slide';

  @override
  String get aiChatTitle => 'Chat AI';

  @override
  String get settingsTitle => 'Cài Đặt';

  @override
  String get newSlide => 'Slide Mới';

  @override
  String get duplicate => 'Nhân Bản';

  @override
  String get delete => 'Xóa';

  @override
  String get save => 'Lưu';

  @override
  String get export => 'Xuất';

  @override
  String get import => 'Nhập';

  @override
  String get undo => 'Hoàn Tác';

  @override
  String get redo => 'Làm Lại';

  @override
  String get present => 'Trình Chiếu';

  @override
  String get presentation => 'Bài Thuyết Trình';

  @override
  String get slides => 'Slides';

  @override
  String slideCount(int count) {
    return 'Slides ($count)';
  }

  @override
  String get noSlidesYet => 'Chưa có slide nào';

  @override
  String get clickToAddSlide => 'Nhấn + để thêm slide';

  @override
  String get title => 'Tiêu Đề';

  @override
  String get content => 'Nội Dung';

  @override
  String get notes => 'Ghi Chú';

  @override
  String get addSlideTooltip => 'Thêm slide mới';

  @override
  String get deleteSlideTooltip => 'Xóa slide';

  @override
  String get duplicateSlideTooltip => 'Nhân bản slide';

  @override
  String get previewTooltip => 'Xem trước slide';

  @override
  String get editSlide => 'Sửa Slide';

  @override
  String get preview => 'Xem Trước';

  @override
  String get cancel => 'Hủy';

  @override
  String get ok => 'OK';

  @override
  String get apply => 'Áp Dụng';

  @override
  String get close => 'Đóng';

  @override
  String get yes => 'Có';

  @override
  String get no => 'Không';

  @override
  String get loading => 'Đang tải...';

  @override
  String get error => 'Lỗi';

  @override
  String get success => 'Thành Công';

  @override
  String get warning => 'Cảnh Báo';

  @override
  String get info => 'Thông Tin';

  @override
  String get connectionError => 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';

  @override
  String get timeoutError => 'Yêu cầu hết thời gian. Vui lòng thử lại.';

  @override
  String get invalidFile => 'Định dạng file không hợp lệ.';

  @override
  String get fileNotFound => 'Không tìm thấy file.';

  @override
  String get permissionDenied => 'Bị từ chối quyền truy cập.';

  @override
  String get unknownError => 'Đã xảy ra lỗi không xác định.';

  @override
  String get saveSuccess => 'Đã lưu thành công';

  @override
  String get exportSuccess => 'Đã xuất thành công';

  @override
  String get importSuccess => 'Đã nhập thành công';

  @override
  String get deleteSuccess => 'Đã xóa thành công';

  @override
  String get duplicateSuccess => 'Đã nhân bản thành công';

  @override
  String deletedWithUndo(String title) {
    return 'Đã xóa \"$title\"';
  }

  @override
  String get undoAction => 'Hoàn Tác';

  @override
  String get addNewProvider => 'Thêm Mới';

  @override
  String get details => 'Chi Tiết';

  @override
  String apiKeySaved(String name) {
    return 'Đã lưu API Key cho $name';
  }

  @override
  String get apiKeyHint => 'API Key...';

  @override
  String get saveApiKeyTooltip => 'Lưu API Key';

  @override
  String get exportBackup => 'Xuất Cấu Hình (JSON)';

  @override
  String get importBackup => 'Nhập Cấu Hình (JSON)';

  @override
  String get saveBackup => 'Lưu backup';

  @override
  String get restoreSettings => 'Khôi phục cài đặt?';

  @override
  String restoreSettingsMessage(String date, int count) {
    return 'File backup từ $date.\nSố providers: $count\n\nCài đặt hiện tại sẽ bị ghi đè. Tiếp tục?';
  }

  @override
  String get restore => 'Khôi Phục';

  @override
  String backupExported(String filename) {
    return 'Đã xuất backup thành công: $filename';
  }

  @override
  String get settingsRestored => 'Đã khôi phục cài đặt thành công!';

  @override
  String get about => 'Thông Tin';

  @override
  String get appearance => 'Giao Diện';

  @override
  String get interfaceMode => 'Chế Độ Giao Diện';

  @override
  String currentMode(String mode) {
    return 'Hiện tại: $mode';
  }

  @override
  String get lightMode => 'Sáng';

  @override
  String get darkMode => 'Tối';

  @override
  String get autoMode => 'Auto';

  @override
  String get lightModeFull => 'Sáng (Light)';

  @override
  String get darkModeFull => 'Tối (Dark)';

  @override
  String get systemMode => 'Hệ Thống (Auto)';

  @override
  String get themeSettings => 'Cài Đặt Theme';

  @override
  String get customTheme => 'Tùy Chỉnh Theme';

  @override
  String get customThemeSubtitle => 'Màu sắc, font chữ, preset themes';

  @override
  String get presetThemes => 'Preset Themes';

  @override
  String get customColors => 'Màu Tùy Chỉnh';

  @override
  String get primaryColor => 'Màu Chính';

  @override
  String get accentColor => 'Màu Phụ';

  @override
  String get typography => 'Phông Chữ';

  @override
  String get fontFamily => 'Font Chữ';

  @override
  String get exportTheme => 'Xuất theme';

  @override
  String get importTheme => 'Nhập theme';

  @override
  String get resetToDefault => 'Khôi phục mặc định';

  @override
  String get themeResetMessage => 'Đã khôi phục theme về Office Blue';

  @override
  String themeAppliedMessage(String name) {
    return 'Đã áp dụng preset $name';
  }

  @override
  String get themeCopied => 'Đã sao chép theme vào clipboard!';

  @override
  String get themeImported => 'Đã nhập theme thành công!';

  @override
  String get themeImportFailed =>
      'Không thể nhập theme. Định dạng không hợp lệ.';

  @override
  String get clipboardEmpty => 'Clipboard trống';

  @override
  String get pickColor => 'Chọn màu';

  @override
  String get pickColorTooltip => 'Chọn màu';

  @override
  String get officeBlue => 'Office Blue';

  @override
  String get officeBlueDesc => 'Microsoft Office cổ điển';

  @override
  String get darkProfessional => 'Dark Professional';

  @override
  String get darkProfessionalDesc => 'Theme tối thanh lịch';

  @override
  String get lightMinimal => 'Light Minimal';

  @override
  String get lightMinimalDesc => 'Sạch sẽ và tối giản';

  @override
  String get custom => 'Tùy Chỉnh';

  @override
  String get customDesc => 'Theme của bạn';

  @override
  String get version => 'Phiên Bản';

  @override
  String versionInfo(String version, String year) {
    return '$version • Build $year';
  }

  @override
  String get language => 'Ngôn Ngữ';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get aiProvider => 'API Key & AI Provider';

  @override
  String get backupRestore => 'Backup & Restore';

  @override
  String get infoSection => 'Thông Tin';

  @override
  String get addNew => 'Thêm mới';

  @override
  String get recentProjects => 'Dự Án Gần Đây';

  @override
  String get noRecentProjects => 'Chưa có dự án nào';

  @override
  String get openProject => 'Mở Dự Án';

  @override
  String get removeFromList => 'Xóa khỏi danh sách';

  @override
  String get removeAll => 'Xóa Tất Cả';

  @override
  String get confirmRemoveAll => 'Xóa tất cả dự án gần đây?';

  @override
  String get search => 'Tìm Kiếm';

  @override
  String get templates => 'Mẫu Slide';

  @override
  String get noTemplates => 'Chưa có mẫu slide';

  @override
  String get useTemplate => 'Dùng Mẫu Này';

  @override
  String get aiChat => 'Chat AI';

  @override
  String get typeMessage => 'Nhập tin nhắn của bạn...';

  @override
  String get send => 'Gửi';

  @override
  String get regenerate => 'Tạo Lại';

  @override
  String get stop => 'Dừng';

  @override
  String get clearChat => 'Xóa Chat';

  @override
  String get clearChatConfirm => 'Xóa lịch sử chat?';

  @override
  String get selectProvider => 'Chọn AI Provider';

  @override
  String get noProviders => 'Chưa cấu hình AI provider nào';

  @override
  String get addProviderFirst => 'Thêm provider trong Cài đặt trước';

  @override
  String get copy => 'Sao Chép';

  @override
  String get paste => 'Dán';

  @override
  String get cut => 'Cắt';

  @override
  String get selectAll => 'Chọn Tất Cả';

  @override
  String get bold => 'In Đậm';

  @override
  String get italic => 'In Nghiêng';

  @override
  String get underline => 'Gạch Chân';

  @override
  String get strikethrough => 'Gạch Ngang';

  @override
  String get alignLeft => 'Căn Trái';

  @override
  String get alignCenter => 'Căn Giữa';

  @override
  String get alignRight => 'Căn Phải';

  @override
  String get alignJustify => 'Căn Đều';

  @override
  String get bulletList => 'Danh Sách Dấu Đầu Dòng';

  @override
  String get numberedList => 'Danh Sách Đánh Số';

  @override
  String get indent => 'Thụt Lề Vào';

  @override
  String get outdent => 'Thụt Lề Ra';

  @override
  String get link => 'Liên Kết';

  @override
  String get image => 'Hình Ảnh';

  @override
  String get table => 'Bảng';

  @override
  String get code => 'Code';

  @override
  String get format => 'Định Dạng';

  @override
  String get help => 'Trợ Giúp';

  @override
  String get shortcuts => 'Phím Tắt';

  @override
  String get exitPresentation => 'Thoát Trình Chiếu';

  @override
  String get nextSlide => 'Slide Tiếp Theo';

  @override
  String get previousSlide => 'Slide Trước';

  @override
  String get firstSlide => 'Slide Đầu Tiên';

  @override
  String get lastSlide => 'Slide Cuối Cùng';

  @override
  String get aiTools => 'Công Cụ AI';

  @override
  String get improveWriting => 'Cải Thiện Văn Phong';

  @override
  String get fixGrammar => 'Sửa Ngữ Pháp';

  @override
  String get makeShorter => 'Rút Gọn';

  @override
  String get makeLonger => 'Mở Rộng';

  @override
  String translateTo(String language) {
    return 'Dịch sang $language';
  }

  @override
  String get summary => 'Tóm Tắt';

  @override
  String get generateSlides => 'Tạo Slides';

  @override
  String get fromText => 'Từ Văn Bản';

  @override
  String get fromTopic => 'Từ Chủ Đề';

  @override
  String get topic => 'Chủ Đề';

  @override
  String get slideCountQuestion => 'Bao nhiêu slide?';

  @override
  String get style => 'Phong Cách';

  @override
  String get professional => 'Chuyên Nghiệp';

  @override
  String get casual => 'Thân Mật';

  @override
  String get academic => 'Học Thuật';

  @override
  String get creative => 'Sáng Tạo';

  @override
  String get files => 'Tệp';

  @override
  String get addFiles => 'Thêm Tệp';

  @override
  String get noFiles => 'Chưa có tệp nào';

  @override
  String get fileName => 'Tên Tệp';

  @override
  String get fileSize => 'Kích Thước';

  @override
  String get fileType => 'Loại';

  @override
  String get uploadedAt => 'Đã Tải Lên';

  @override
  String get collaboration => 'Cộng Tác';

  @override
  String get startSession => 'Bắt Đầu Phiên';

  @override
  String get joinSession => 'Tham Gia Phiên';

  @override
  String get sessionCode => 'Mã Phiên';

  @override
  String get host => 'Máy Chủ';

  @override
  String get join => 'Tham Gia';

  @override
  String get leave => 'Rời Khỏi';

  @override
  String get audio => 'Âm Thanh';

  @override
  String get startRecording => 'Bắt Đầu Ghi';

  @override
  String get stopRecording => 'Dừng Ghi';

  @override
  String get playRecording => 'Phát Bản Ghi';

  @override
  String get deleteRecording => 'Xóa Bản Ghi';

  @override
  String get audioRecorded => 'Đã ghi âm';

  @override
  String get recordings => 'Bản Ghi';

  @override
  String get noRecordings => 'Chưa có bản ghi nào';

  @override
  String get advancedExport => 'Xuất nâng cao';

  @override
  String get exportFormat => 'Định dạng xuất';

  @override
  String get aspectRatio => 'Tỷ lệ khung hình';

  @override
  String get quality => 'Chất lượng';

  @override
  String get exportOptions => 'Tùy chọn';

  @override
  String get includeSpeakerNotes => 'Kèm ghi chú người thuyết trình';

  @override
  String get includeBackgrounds => 'Kèm nền slide';

  @override
  String get slidesToExport => 'Slide cần xuất';

  @override
  String get allSlides => 'Tất cả slide';

  @override
  String selectedSlides(int count) {
    return 'Đã chọn ($count)';
  }

  @override
  String get exporting => 'Đang xuất...';

  @override
  String exportSuccessful(String summary) {
    return 'Xuất thành công: $summary';
  }

  @override
  String exportFailed(String error) {
    return 'Xuất thất bại: $error';
  }

  @override
  String get chooseAtLeastOneSlide =>
      'Hãy chọn ít nhất một slide hoặc chọn \"Tất cả slide\".';

  @override
  String get chooseTemplate => 'Chọn mẫu';

  @override
  String get htmlPreview => 'Xem trước HTML:';

  @override
  String get useThisTemplate => 'Dùng mẫu này';

  @override
  String get clearAllSlides => 'Xóa toàn bộ slide';

  @override
  String clearAllSlidesMessage(int count) {
    return 'Bạn có chắc muốn xóa toàn bộ $count slide? Thao tác này không thể hoàn tác.';
  }

  @override
  String get deletedAllSlides => 'Đã xóa toàn bộ slide';

  @override
  String get untitledPresentation => 'Bài thuyết trình chưa có tên';

  @override
  String get hideSidebar => 'Ẩn thanh bên';

  @override
  String get showSidebar => 'Hiện thanh bên';

  @override
  String get toggleTheme => 'Đổi giao diện';

  @override
  String get slideEditor => 'Trình soạn slide';

  @override
  String get navigation => 'Điều hướng';

  @override
  String get system => 'Hệ thống';

  @override
  String get noSlides => 'Chưa có slide để trình chiếu.';

  @override
  String get startCollaboration => 'Bắt đầu cộng tác';

  @override
  String get stopCollaboration => 'Dừng cộng tác';

  @override
  String get leaveCollaboration => 'Rời phiên';

  @override
  String get hostCollaboration => 'Tạo phiên cộng tác';

  @override
  String get hostCollaborationDescription =>
      'Chia sẻ bài thuyết trình hiện tại với người tin cậy trong cùng mạng nội bộ.';

  @override
  String get joinCollaboration => 'Tham gia phiên';

  @override
  String get hostOrShareLink => 'IP máy chủ hoặc liên kết chia sẻ';

  @override
  String get port => 'Cổng';

  @override
  String get displayName => 'Tên hiển thị';

  @override
  String get sessionToken => 'Mã bảo mật phiên';

  @override
  String get connect => 'Kết nối';

  @override
  String get collaborationHosting => 'Đang mở phiên được bảo vệ';

  @override
  String get collaborationConnected => 'Đã kết nối và đang đồng bộ';

  @override
  String collaborationRevision(int revision) {
    return 'Bản sửa đổi $revision';
  }

  @override
  String collaborationParticipants(int count) {
    return 'Người tham gia: $count';
  }

  @override
  String get collaborationSecurityNotice =>
      'Chỉ chia sẻ liên kết hoặc mã phiên với người tin cậy trong mạng nội bộ.';

  @override
  String get collaborationStartFailed =>
      'Không thể mở máy chủ nội bộ được bảo vệ. Hãy kiểm tra cổng và tường lửa.';

  @override
  String get collaborationJoinFields =>
      'Hãy nhập máy chủ/liên kết chia sẻ và mã bảo mật phiên.';

  @override
  String get collaborationJoinFailed =>
      'Không thể xác thực hoặc kết nối với phiên này.';

  @override
  String get collaborationJoined => 'Đã kết nối. Các slide đang được đồng bộ.';

  @override
  String get collaborationLinkCopied =>
      'Đã sao chép liên kết chia sẻ được bảo vệ.';

  @override
  String get collaborationConflict =>
      'Phát hiện bản mới hơn. Đã khôi phục phiên bản chính thức từ máy chủ.';

  @override
  String get collaborationAuthFailed => 'Mã cộng tác không còn hợp lệ.';

  @override
  String slideListSemantics(int count) {
    return 'Danh sách slide, $count slide';
  }

  @override
  String slideSemanticLabel(int number, String title) {
    return 'Slide $number: $title';
  }

  @override
  String get slideSemanticHint =>
      'Kích hoạt để chỉnh sửa. Nhấn giữ để xem thêm thao tác.';

  @override
  String get workspaceSemantics =>
      'Không gian làm việc bài thuyết trình GhitaPPT';
}
